<?php

namespace App\Controllers\Auth;

use App\Core\Controller;
use App\Core\Request;
use App\Core\Response;
use App\Core\Database;
use App\Core\DomainException;
use App\Models\Auth\AuthService;
use App\Models\Auth\SessionManager;
use App\Models\Auth\PasswordHasher;
use App\Models\Auth\RoleValidator;
use App\Models\Mail\GmailMailService;
use App\Views\RequestValidator;
use App\Views\ResponseFormatter;
use App\Views\RateLimiter;
use App\Views\IPValidator;
use App\Views\ErrorHandler;
use App\Models\Auth\AuthenticationException;

/**
 * Authentication Controller
 * 
 * Handles HTTP requests for authentication operations including
 * registration, login, logout, and current user retrieval.
 * 
 * Requirements: Design API Endpoints 1-4
 */
class AuthController extends Controller
{
    private AuthService $authService;
    private SessionManager $sessionManager;
    private PasswordHasher $passwordHasher;
    private RoleValidator $roleValidator;

    public function __construct()
    {
        $this->passwordHasher = new PasswordHasher();
        $this->sessionManager = new SessionManager();
        $this->authService = new AuthService($this->passwordHasher, $this->sessionManager);
        $this->roleValidator = new RoleValidator();
    }

    /**
     * Register new user
     * 
     * POST /api/auth/register
     * 
     * Requirements: 1.1-1.8, Design API Endpoint 1
     * 
     * @param Request $request HTTP request
     * @return Response HTTP response
     */
    public function register(Request $request): Response
    {
        try {
            // Requirement 20.1, 20.2: obtener IP del cliente para limitar tasa
            $ipAddress = IPValidator::getClientIP($request);

            // Limitar tasa de registros por IP para evitar creación masiva de cuentas
            $rateLimitCheck = RateLimiter::check('register', $ipAddress);

            if (!$rateLimitCheck['allowed']) {
                $retryAfter = $rateLimitCheck['reset_at'] - time();
                return ResponseFormatter::rateLimitExceeded($retryAfter);
            }

            // Validate Content-Type
            $contentTypeValidation = RequestValidator::validateContentType($request, 'POST');
            if (!$contentTypeValidation['valid']) {
                return ResponseFormatter::error(
                    $contentTypeValidation['error'],
                    null,
                    $contentTypeValidation['statusCode']
                );
            }

            // Parse JSON body
            $jsonValidation = RequestValidator::parseJsonBody($request);
            if (!$jsonValidation['valid']) {
                return ResponseFormatter::error(
                    $jsonValidation['error'],
                    null,
                    $jsonValidation['statusCode']
                );
            }

            // Validate registration request
            $validation = RequestValidator::validateRegistrationRequest($request);
            if (!$validation['valid']) {
                return ResponseFormatter::validationError($validation['errors']);
            }

            // Extract and sanitize input
            $email = RequestValidator::sanitizeString($request->input('email'));
            $password = $request->input('password');
            $firstName = RequestValidator::sanitizeString($request->input('first_name'));
            $lastName = RequestValidator::sanitizeString($request->input('last_name'));
            $phone = $request->input('phone') ? RequestValidator::sanitizeString($request->input('phone')) : null;
            
            // Datos adicionales opcionales
            $idNumber = $request->input('id_number') ? RequestValidator::sanitizeString($request->input('id_number')) : null;
            $driverLicenseNumber = $request->input('driver_license_number') ? RequestValidator::sanitizeString($request->input('driver_license_number')) : null;
            
            // Datos del vehículo (opcionales)
            $vehicleData = null;
            if ($request->input('vehicle_brand') || $request->input('vehicle_plate')) {
                $vehicleData = [
                    'make' => $request->input('vehicle_brand') ? RequestValidator::sanitizeString($request->input('vehicle_brand')) : null,
                    'model' => $request->input('vehicle_model') ? RequestValidator::sanitizeString($request->input('vehicle_model')) : null,
                    'license_plate' => $request->input('vehicle_plate') ? RequestValidator::sanitizeString($request->input('vehicle_plate')) : null,
                    'year' => $request->input('vehicle_year') ? (int)$request->input('vehicle_year') : null,
                    'color' => $request->input('vehicle_color') ? RequestValidator::sanitizeString($request->input('vehicle_color')) : null,
                    'soat_number' => $request->input('soat_number') ? RequestValidator::sanitizeString($request->input('soat_number')) : null,
                    'tecnomecanica_number' => $request->input('tecnomecanica_number') ? RequestValidator::sanitizeString($request->input('tecnomecanica_number')) : null,
                ];
            }

            // Rol solicitado para el auto-registro (validado por RequestValidator: solo
            // 'customer' o 'mechanic' — nunca administrator/super_admin vía este endpoint)
            $requestedRole = $request->input('role') ?? 'customer';

            // Check if email already exists
            if ($this->authService->emailExists($email)) {
                RateLimiter::recordAttempt('register', $ipAddress);
                return ResponseFormatter::conflict('Email already exists');
            }

            // Hash password
            $passwordHash = $this->passwordHasher->hash($password);

            // Crear usuario, asignar rol y crear sesión (transacción única en AuthService)
            $authResult = $this->authService->register(
                $email,
                $passwordHash,
                $firstName,
                $lastName,
                $phone,
                $requestedRole,
                IPValidator::getClientIP($request),
                $request->userAgent(),
                $idNumber,
                $driverLicenseNumber,
                $vehicleData
            );

            // Contar el registro exitoso para el límite de tasa (evita creación masiva)
            RateLimiter::recordAttempt('register', $ipAddress);

            // Prepare response data — mismo perfil completo que devuelve GET /api/auth/me
            $responseData = [
                'user' => $this->buildUserProfile($authResult->userId),
                'session' => [
                    'id' => $authResult->sessionId,
                    'expiresAt' => time() + 7200 // 2 hours
                ]
            ];

            // Set session cookie
            $response = ResponseFormatter::success(
                $responseData,
                'Registration successful',
                201
            );

            ResponseFormatter::setSessionCookie($response, $authResult->sessionId, false);

            return $response;

        } catch (AuthenticationException $e) {
            return ErrorHandler::handleException($e);

        } catch (\Exception $e) {
            return ErrorHandler::handleException($e);
        }
    }

    /**
     * Login user
     * 
     * POST /api/auth/login
     * 
     * Requirements: 1.1-1.8, 19.1-19.7, Design API Endpoint 2
     * 
     * @param Request $request HTTP request
     * @return Response HTTP response
     */
    public function login(Request $request): Response
    {
        try {
            // Requirement 20.1, 20.2: Get client IP address using IPValidator
            $ipAddress = IPValidator::getClientIP($request);

            // Requirement 6.1, 6.2, 6.3: Check rate limit before authentication
            $rateLimitCheck = RateLimiter::check('login', $ipAddress);
            
            if (!$rateLimitCheck['allowed']) {
                // Requirement 6.4: Return 429 with Retry-After header
                $retryAfter = $rateLimitCheck['reset_at'] - time();
                return ResponseFormatter::rateLimitExceeded($retryAfter);
            }

            // Validate Content-Type
            $contentTypeValidation = RequestValidator::validateContentType($request, 'POST');
            if (!$contentTypeValidation['valid']) {
                return ResponseFormatter::error(
                    $contentTypeValidation['error'],
                    null,
                    $contentTypeValidation['statusCode']
                );
            }

            // Parse JSON body
            $jsonValidation = RequestValidator::parseJsonBody($request);
            if (!$jsonValidation['valid']) {
                return ResponseFormatter::error(
                    $jsonValidation['error'],
                    null,
                    $jsonValidation['statusCode']
                );
            }

            // Validate login request
            $validation = RequestValidator::validateLoginRequest($request);
            if (!$validation['valid']) {
                return ResponseFormatter::validationError($validation['errors']);
            }

            // Extract input
            $email = RequestValidator::sanitizeString($request->input('email'));
            $password = $request->input('password');
            $remember = $request->input('remember', false);

            // Normalize remember to boolean
            if (!is_bool($remember)) {
                $remember = filter_var($remember, FILTER_VALIDATE_BOOLEAN);
            }

            // Requirement 20.2: Authenticate via AuthService with IP address and user agent
            $userAgent = $request->userAgent();
            $authResult = $this->authService->authenticate($email, $password, $remember, $ipAddress, $userAgent);

            // Check authentication result
            if (!$authResult->success) {
                // Record failed attempt for rate limiting
                RateLimiter::recordAttempt('login', $ipAddress);
                
                // Return 401 with generic error message (prevent user enumeration)
                return ResponseFormatter::unauthorized($authResult->message);
            }

            // Requirement 6.5: Reset rate limit on successful login
            RateLimiter::reset('login', $ipAddress);

            // Calculate session expiration
            $expiresAt = $remember
                ? time() + (30 * 24 * 60 * 60) // 30 days
                : time() + 7200; // 2 hours

            // Prepare response data — mismo perfil completo que devuelve GET /api/auth/me
            // (incluye phone, createdAt y driverLicense) para que el frontend no dependa
            // de un refresh posterior para ver esos campos.
            $responseData = [
                'user' => $this->buildUserProfile($authResult->userId),
                'session' => [
                    'id' => $authResult->sessionId,
                    'expiresAt' => $expiresAt
                ]
            ];

            // Set session cookie
            $response = ResponseFormatter::success(
                $responseData,
                'Login successful',
                200
            );

            ResponseFormatter::setSessionCookie($response, $authResult->sessionId, $remember);

            return $response;

        } catch (AuthenticationException $e) {
            // Record failed attempt for rate limiting
            RateLimiter::recordAttempt('login', $ipAddress);
            
            return ErrorHandler::handleException($e);

        } catch (\Exception $e) {
            return ErrorHandler::handleException($e);
        }
    }

    /**
     * Logout user
     * 
     * POST /api/auth/logout
     * 
     * Requirements: 2.1-2.7, Design API Endpoint 3
     * 
     * @param Request $request HTTP request
     * @return Response HTTP response
     */
    public function logout(Request $request): Response
    {
        try {
            // Extract session ID from cookie
            $sessionId = $request->cookie(ResponseFormatter::getSessionCookieName());

            // If no session cookie, return success anyway (idempotent)
            if ($sessionId === null || empty($sessionId)) {
                $response = ResponseFormatter::success(null, 'Logout successful', 200);
                ResponseFormatter::clearSessionCookie($response);
                return $response;
            }

            // Destroy session via AuthService
            $this->authService->logout($sessionId);

            // Clear session cookie
            $response = ResponseFormatter::success(null, 'Logout successful', 200);
            ResponseFormatter::clearSessionCookie($response);

            return $response;

        } catch (\Exception $e) {
            return ErrorHandler::handleException($e);
        }
    }

    /**
     * Obtener usuario autenticado actual
     *
     * GET /api/auth/me
     *
     * Retorna el perfil completo del usuario incluyendo datos de licencia de conducción.
     *
     * @param Request $request HTTP request
     * @return Response HTTP response
     */
    public function me(Request $request): Response
    {
        try {
            // Obtener usuario desde los atributos del request (establecido por AuthMiddleware)
            $user = $request->getAttribute('user');

            if ($user === null) {
                return ResponseFormatter::unauthorized('Autenticación requerida');
            }

            $responseData = $this->buildUserProfile((int)$user['id']);

            if ($responseData === null) {
                return ResponseFormatter::unauthorized('Usuario no encontrado');
            }

            return ResponseFormatter::success($responseData, 'Usuario obtenido correctamente', 200);

        } catch (\Exception $e) {
            return ErrorHandler::handleException($e);
        }
    }

    /**
     * Construye el perfil completo de un usuario (mismos campos que GET /api/auth/me).
     *
     * Usado por register(), login() y me() para que los tres endpoints devuelvan
     * exactamente la misma forma de objeto `user` — antes cada uno armaba su propio
     * arreglo a mano y quedaban desincronizados (login/register nunca incluían
     * `phone`, `createdAt` ni `driverLicense`, rompiendo cualquier UI que dependiera
     * de esos campos justo después de iniciar sesión, antes de un refresh manual).
     *
     * @param int $userId ID del usuario
     * @return array|null Perfil completo, o null si el usuario no existe
     */
    private function buildUserProfile(int $userId): ?array
    {
        $userData = $this->authService->getUserProfileData($userId);

        if ($userData === null) {
            return null;
        }

        $roles = $this->roleValidator->getUserRoles($userId);

        // Construir objeto de licencia de conducción (null si no se ha registrado)
        $driverLicense = null;
        if ($userData['driver_license_status'] !== 'not_set' || $userData['driver_license_number'] !== null) {
            $driverLicense = [
                'number'         => $userData['driver_license_number'],
                'expirationDate' => $userData['driver_license_expiration_date'],
                'documentUrl'    => $userData['driver_license_document_url'],
                'status'         => $userData['driver_license_status'] ?? 'not_set',
                'uploadedAt'     => $userData['driver_license_uploaded_at'],
            ];
        }
        
        // Obtener vehículo primario del usuario
        $vehicle = null;
        $vehicleData = \App\Core\Database::fetchOne(
            'SELECT * FROM vehicles WHERE user_id = ? AND deleted_at IS NULL ORDER BY is_primary DESC, created_at DESC LIMIT 1',
            [$userId]
        );
        
        if ($vehicleData !== null) {
            $vehicle = [
                'id'                      => (int)$vehicleData['id'],
                'make'                    => $vehicleData['make'],
                'model'                   => $vehicleData['model'],
                'licensePlate'            => $vehicleData['license_plate'],
                'year'                    => (int)$vehicleData['year'],
                'color'                   => $vehicleData['color'],
                'vehicleType'             => $vehicleData['vehicle_type'] ?? 'car',
                'soatNumber'              => $vehicleData['soat_number'],
                'soatUploadedAt'          => $vehicleData['soat_uploaded_at'],
                'tecnomecanicaNumber'     => $vehicleData['tecnomecanica_number'],
                'tecnomecanicaUploadedAt' => $vehicleData['tecnomecanica_uploaded_at'],
                'isPrimary'               => (bool)$vehicleData['is_primary'],
                'status'                  => $vehicleData['status'],
                'createdAt'               => $vehicleData['created_at'],
            ];
        }

        return [
            'id'            => $userId,
            'email'         => $userData['email'],
            'firstName'     => $userData['first_name'],
            'lastName'      => $userData['last_name'],
            'phone'         => $userData['phone'],
            'accountStatus' => $userData['account_status'],
            'createdAt'     => $userData['created_at'],
            'lastLoginAt'   => $userData['last_login_at'],
            'roles'         => $roles,
            'driverLicense' => $driverLicense,
            'vehicle'       => $vehicle,
        ];
    }

    /**
     * Actualizar perfil del usuario autenticado
     *
     * PUT /api/auth/profile
     *
     * Permite actualizar datos personales, información del vehículo y licencia de conducción.
     * Acepta FormData (con o sin archivo de foto de perfil).
     *
     * @param Request $request HTTP request
     * @return Response HTTP response
     */
    public function profile(Request $request): Response
    {
        // Agregar logging temprano
        error_log('=== PROFILE METHOD CALLED ===');
        error_log('Request Method: ' . $request->method());
        error_log('Content-Type: ' . ($request->header('Content-Type') ?? 'NOT SET'));
        error_log('POST keys: ' . implode(', ', array_keys($_POST)));
        error_log('FILES keys: ' . implode(', ', array_keys($_FILES)));

        try {
            // Obtener usuario desde los atributos del request (establecido por AuthMiddleware)
            $user = $request->getAttribute('user');

            error_log('User from request: ' . json_encode($user));

            if ($user === null) {
                return ResponseFormatter::unauthorized('Autenticación requerida');
            }

            $userId = (int)$user['id'];
            error_log('Processing for userId: ' . $userId);

            // El método PUT /api/auth/profile SIEMPRE recibe FormData
            // (incluso si no hay archivo, enviamos FormData para consistencia)
            // No intentamos parsear JSON en este endpoint

            // Recopilar campos permitidos para actualización
            $updates = [];
            $now     = date('Y-m-d H:i:s');

            // ════════════════════════════════════════════════════════════════════════════════
            // DATOS PERSONALES
            // ════════════════════════════════════════════════════════════════════════════════

            $firstName = $request->input('first_name');
            error_log('first_name input: ' . ($firstName ?? 'NULL'));
            if ($firstName !== null) {
                $updates['first_name'] = RequestValidator::sanitizeString($firstName);
            }

            $lastName = $request->input('last_name');
            error_log('last_name input: ' . ($lastName ?? 'NULL'));
            if ($lastName !== null) {
                $updates['last_name'] = RequestValidator::sanitizeString($lastName);
            }

            $phone = $request->input('phone');
            if ($phone !== null) {
                $updates['phone'] = RequestValidator::sanitizeString($phone);
            }

            $idNumber = $request->input('id_number');
            if ($idNumber !== null) {
                $updates['id_number'] = RequestValidator::sanitizeString($idNumber);
            }

            error_log('After personal data, updates: ' . json_encode($updates));

            // Foto de perfil (FormData)
            if (isset($_FILES['profile_picture'])) {
                error_log('Processing profile picture...');
                $file = $_FILES['profile_picture'];
                
                // Verificar que no hay error en la carga del archivo
                if ($file['error'] !== UPLOAD_ERR_OK) {
                    $errorMessages = [
                        UPLOAD_ERR_INI_SIZE => 'Archivo excede el tamaño máximo configurado en php.ini',
                        UPLOAD_ERR_FORM_SIZE => 'Archivo excede el tamaño máximo del formulario',
                        UPLOAD_ERR_PARTIAL => 'La carga del archivo fue interrumpida',
                        UPLOAD_ERR_NO_FILE => 'No se cargó ningún archivo',
                        UPLOAD_ERR_NO_TMP_DIR => 'Carpeta temporal no disponible',
                        UPLOAD_ERR_CANT_WRITE => 'No se puede escribir en el disco',
                        UPLOAD_ERR_EXTENSION => 'Extensión PHP impidió la carga',
                    ];
                    error_log('File upload error: ' . ($errorMessages[$file['error']] ?? 'Unknown'));
                    return ResponseFormatter::validationError([
                        'profile_picture' => $errorMessages[$file['error']] ?? 'Error desconocido en la carga'
                    ]);
                }
                
                // Validar tipo MIME
                $allowedMimeTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
                $fileMimeType = mime_content_type($file['tmp_name']);
                
                if (!in_array($fileMimeType, $allowedMimeTypes)) {
                    error_log('Invalid MIME type: ' . $fileMimeType);
                    return ResponseFormatter::validationError([
                        'profile_picture' => 'Tipo de archivo no permitido. Use JPEG, PNG, GIF o WebP'
                    ]);
                }

                // Validar tamaño (máx 5MB)
                if ($file['size'] > 5 * 1024 * 1024) {
                    error_log('File too large: ' . $file['size']);
                    return ResponseFormatter::validationError([
                        'profile_picture' => 'El archivo es demasiado grande. Máximo 5MB'
                    ]);
                }

                // Guardar archivo en directorio public
                $uploadsDir = __DIR__ . '/../../public/uploads/profiles';
                if (!is_dir($uploadsDir)) {
                    mkdir($uploadsDir, 0755, true);
                }

                $filename = 'user_' . $userId . '_' . time() . '.' . pathinfo($file['name'], PATHINFO_EXTENSION);
                $filepath = $uploadsDir . '/' . $filename;
                
                if (move_uploaded_file($file['tmp_name'], $filepath)) {
                    $updates['profile_picture_url'] = '/uploads/profiles/' . $filename;
                    error_log('Profile picture saved: ' . $updates['profile_picture_url']);
                } else {
                    error_log('Failed to save profile picture');
                    return ResponseFormatter::error('Error al guardar la foto de perfil', null, 500);
                }
            }

            // ════════════════════════════════════════════════════════════════════════════════
            // DATOS DEL VEHÍCULO
            // ════════════════════════════════════════════════════════════════════════════════

            $hasVehicleData = false;
            $vehicleUpdates = [];

            $vehicleBrand = $request->input('vehicle_brand');
            if ($vehicleBrand !== null) {
                $vehicleUpdates['make'] = RequestValidator::sanitizeString($vehicleBrand);
                $hasVehicleData = true;
            }

            $vehicleModel = $request->input('vehicle_model');
            if ($vehicleModel !== null) {
                $vehicleUpdates['model'] = RequestValidator::sanitizeString($vehicleModel);
                $hasVehicleData = true;
            }

            $vehiclePlate = $request->input('vehicle_plate');
            if ($vehiclePlate !== null) {
                $vehicleUpdates['license_plate'] = RequestValidator::sanitizeString($vehiclePlate);
                $hasVehicleData = true;
            }

            $vehicleYear = $request->input('vehicle_year');
            if ($vehicleYear !== null) {
                $vehicleUpdates['year'] = (int)$vehicleYear;
                $hasVehicleData = true;
            }

            $vehicleColor = $request->input('vehicle_color');
            if ($vehicleColor !== null) {
                $vehicleUpdates['color'] = RequestValidator::sanitizeString($vehicleColor);
                $hasVehicleData = true;
            }

            // Si hay datos del vehículo, actualizar o crear el vehículo primario
            if ($hasVehicleData) {
                error_log('Processing vehicle data...');
                $primaryVehicle = Database::fetchOne(
                    'SELECT id FROM vehicles WHERE user_id = ? AND deleted_at IS NULL ORDER BY is_primary DESC, created_at DESC LIMIT 1',
                    [$userId]
                );

                if ($primaryVehicle) {
                    // Actualizar vehículo existente
                    $vehicleUpdates['updated_at'] = $now;
                    Database::update('vehicles', $vehicleUpdates, 'id = ?', [$primaryVehicle['id']]);
                    error_log('Vehicle updated');
                } else {
                    // Crear nuevo vehículo primario
                    if (!isset($vehicleUpdates['make']) || !isset($vehicleUpdates['license_plate'])) {
                        error_log('Missing required vehicle data');
                        return ResponseFormatter::validationError([
                            'vehicle_brand' => 'Marca del vehículo es requerida',
                            'vehicle_plate' => 'Placa del vehículo es requerida'
                        ]);
                    }

                    $vehicleUpdates['user_id'] = $userId;
                    $vehicleUpdates['vehicle_type'] = $vehicleUpdates['vehicle_type'] ?? 'car';
                    $vehicleUpdates['is_primary'] = true;
                    $vehicleUpdates['status'] = 'active';
                    $vehicleUpdates['created_at'] = $now;
                    $vehicleUpdates['updated_at'] = $now;

                    Database::insert('vehicles', $vehicleUpdates);
                    error_log('Vehicle created');
                }
            }

            // ════════════════════════════════════════════════════════════════════════════════
            // DATOS DE LICENCIA DE CONDUCCIÓN
            // ════════════════════════════════════════════════════════════════════════════════

            $licenseNumber = $request->input('driver_license_number');
            if ($licenseNumber !== null) {
                $updates['driver_license_number'] = RequestValidator::sanitizeString($licenseNumber);
                $updates['driver_license_uploaded_at'] = $now;
            }

            $expirationDate = $request->input('driver_license_expiration_date');
            if ($expirationDate !== null) {
                // Validar formato YYYY-MM-DD
                if (!\DateTime::createFromFormat('Y-m-d', $expirationDate)) {
                    error_log('Invalid date format: ' . $expirationDate);
                    return ResponseFormatter::validationError([
                        'driver_license_expiration_date' => 'El formato debe ser YYYY-MM-DD'
                    ]);
                }

                $updates['driver_license_expiration_date'] = $expirationDate;

                // Calcular estado según la fecha de vencimiento
                $today      = new \DateTime('today');
                $expiry     = new \DateTime($expirationDate);
                $daysToExpiry = (int)$today->diff($expiry)->days;
                $isPast     = $expiry < $today;

                if ($isPast) {
                    $updates['driver_license_status'] = 'expired';
                } elseif ($daysToExpiry <= 30) {
                    $updates['driver_license_status'] = 'expiring_soon';
                } else {
                    $updates['driver_license_status'] = 'valid';
                }

                $updates['driver_license_uploaded_at'] = $now;
            }

            $documentUrl = $request->input('driver_license_document_url');
            if ($documentUrl !== null) {
                $updates['driver_license_document_url'] = RequestValidator::sanitizeString($documentUrl);
            }

            // Si no hay nada que actualizar, retornar el perfil actual
            if (empty($updates) && !$hasVehicleData) {
                error_log('No updates, returning current profile');
                return $this->me($request);
            }

            // Aplicar actualización de datos del usuario
            if (!empty($updates)) {
                error_log('Saving updates: ' . json_encode($updates));
                $updates['updated_at'] = $now;
                $this->authService->updateProfile($userId, $updates);
                error_log('Updates saved');
            }

            // Retornar perfil actualizado
            error_log('Returning updated profile');
            return $this->me($request);

        } catch (\Exception $e) {
            error_log('Exception in profile method: ' . $e->getMessage());
            error_log('Exception file: ' . $e->getFile());
            error_log('Exception line: ' . $e->getLine());
            return ErrorHandler::handleException($e);
        }
    }

    /**
     * Cambiar la contraseña del usuario autenticado
     *
     * PUT /api/auth/password
     *
     * Requiere la contraseña actual. Al cambiarla exitosamente, se cierran todas
     * las sesiones existentes (incluida la actual) y se emite una nueva sesión
     * para el dispositivo que hizo la solicitud, forzando el cierre de sesión en
     * cualquier otro dispositivo — comportamiento estándar tras un cambio de contraseña.
     *
     * @param Request $request Solicitud HTTP
     * @return Response Respuesta HTTP
     */
    public function changePassword(Request $request): Response
    {
        try {
            $user = $request->getAttribute('user');
            if ($user === null) {
                return ResponseFormatter::unauthorized('Autenticación requerida');
            }
            $userId = (int)$user['id'];

            $ipAddress = IPValidator::getClientIP($request);

            // Limitar tasa por IP para evitar fuerza bruta sobre la contraseña actual
            $rateLimitCheck = RateLimiter::check('change-password', $ipAddress);
            if (!$rateLimitCheck['allowed']) {
                $retryAfter = $rateLimitCheck['reset_at'] - time();
                return ResponseFormatter::rateLimitExceeded($retryAfter);
            }

            $jsonValidation = RequestValidator::parseJsonBody($request);
            if (!$jsonValidation['valid']) {
                return ResponseFormatter::error(
                    $jsonValidation['error'],
                    null,
                    $jsonValidation['statusCode']
                );
            }

            $validation = RequestValidator::validateChangePasswordRequest($request);
            if (!$validation['valid']) {
                return ResponseFormatter::validationError($validation['errors']);
            }

            $currentPassword = $request->input('current_password');
            $newPassword     = $request->input('new_password');

            if (!$this->authService->verifyCurrentPassword($userId, $currentPassword)) {
                RateLimiter::recordAttempt('change-password', $ipAddress);
                throw new DomainException('La contraseña actual es incorrecta', 400);
            }

            RateLimiter::reset('change-password', $ipAddress);

            $newHash = $this->passwordHasher->hash($newPassword);
            $this->authService->updatePassword($userId, $newHash);

            // Cerrar todas las sesiones existentes y emitir una nueva para este dispositivo
            $this->sessionManager->destroyAllUserSessions($userId);
            $sessionId = $this->sessionManager->create($userId, [
                'ip_address' => $ipAddress,
                'user_agent' => $request->userAgent(),
                'remember'   => false
            ]);

            $response = ResponseFormatter::success(
                null,
                'Contraseña actualizada correctamente. Se cerró la sesión en tus otros dispositivos.',
                200
            );

            ResponseFormatter::setSessionCookie($response, $sessionId, false);

            return $response;

        } catch (\Exception $e) {
            return ErrorHandler::handleException($e);
        }
    }

    /**
     * Health check endpoint
     *
     * GET /api/auth/health
     *
     * Requirements: 14.1-14.7
     *
     * @param Request $request HTTP request
     * @return Response HTTP response
     */
    public function health(Request $request): Response
    {
        $startTime = microtime(true);

        try {
            // Test database connectivity
            if (!$this->authService->checkDatabaseHealth()) {
                throw new \Exception('Database health check failed');
            }

            // Calculate response time in milliseconds
            $responseTime = round((microtime(true) - $startTime) * 1000, 2);

            // Prepare response data
            $responseData = [
                'status' => 'healthy',
                'version' => '1.0.0',
                'timestamp' => date('Y-m-d H:i:s'),
                'responseTime' => $responseTime
            ];

            return ResponseFormatter::success($responseData, 'Service is healthy', 200);

        } catch (\Exception $e) {
            // Calculate response time even on failure
            $responseTime = round((microtime(true) - $startTime) * 1000, 2);

            // Prepare unhealthy response data
            $responseData = [
                'status' => 'unhealthy',
                'version' => '1.0.0',
                'timestamp' => date('Y-m-d H:i:s'),
                'responseTime' => $responseTime
            ];

            // Log exception via ErrorHandler
            ErrorHandler::logException($e);

            return ResponseFormatter::error(
                'Service is unhealthy',
                $responseData,
                503
            );
        }
    }

    /**
     * Solicitar recuperación de contraseña
     * POST /api/auth/forgot-password
     * 
     * Genera un token de recuperación para que el usuario pueda resetear su contraseña.
     * Por seguridad, siempre responde de forma genérica sin revelar si el email existe.
     */
    public function forgotPassword(Request $request): Response
    {
        try {
            $ipAddress = IPValidator::getClientIP($request);

            // Rate limiting para prevenir spam y ataques de fuerza bruta
            $rateLimitCheck = RateLimiter::check('forgot-password', $ipAddress);
            if (!$rateLimitCheck['allowed']) {
                $retryAfter = $rateLimitCheck['reset_at'] - time();
                return ResponseFormatter::rateLimitExceeded($retryAfter);
            }

            // Validar que el cuerpo sea JSON válido
            $jsonValidation = RequestValidator::parseJsonBody($request);
            if (!$jsonValidation['valid']) {
                return ResponseFormatter::error(
                    $jsonValidation['error'],
                    null,
                    $jsonValidation['statusCode']
                );
            }

            // Obtener y validar email
            $rawEmail = $request->input('email');
            if (empty($rawEmail)) {
                return ResponseFormatter::validationError([
                    'email' => 'El email es requerido y debe ser válido'
                ]);
            }
            $email = RequestValidator::sanitizeString($rawEmail);
            if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
                return ResponseFormatter::validationError([
                    'email' => 'El email es requerido y debe ser válido'
                ]);
            }

            // Buscar usuario activo por email
            $user = Database::fetchOne(
                'SELECT id, email, first_name, last_name FROM users WHERE email = ? AND account_status = "active"',
                [$email]
            );

            // Respuesta genérica por seguridad (no revelar si el email existe)
            $genericMessage = 'Si el correo existe en nuestro sistema, recibirás un enlace de recuperación';

            if (!$user) {
                return ResponseFormatter::success(
                    null,
                    $genericMessage,
                    200
                );
            }

            // Generar token aleatorio seguro (32 bytes = 64 caracteres hexadecimales)
            $token = bin2hex(random_bytes(32));
            $expiresAt = date('Y-m-d H:i:s', time() + (24 * 60 * 60)); // Válido por 24 horas

            // Guardar token en BD
            Database::insert('password_reset_tokens', [
                'user_id' => (int)$user['id'],
                'token' => $token,
                'expires_at' => $expiresAt,
            ]);

            // Enviar correo con enlace de recuperación
            try {
                $mailService = new GmailMailService();
                $firstName = $user['first_name'] ?? 'Usuario';
                $mailService->sendPasswordResetEmail($email, $firstName, $token);
            } catch (\Exception $e) {
                // Log del error pero no fallar la solicitud
                error_log("Error enviando correo de recuperación: " . $e->getMessage());
            }

            // En desarrollo/demostración, devolver el token para acceso rápido
            // En producción, no devolver el token
            $responseData = null;
            if ($_ENV['APP_ENV'] === 'local') {
                $responseData = ['token' => $token];
            }

            return ResponseFormatter::success(
                $responseData,
                $genericMessage,
                200
            );

        } catch (\Exception $e) {
            return ErrorHandler::handleException($e);
        }
    }

    /**
     * Resetear contraseña con token válido
     * POST /api/auth/reset-password
     * 
     * Valida el token y actualiza la contraseña del usuario.
     * Invalida todas las sesiones activas del usuario para seguridad.
     */
    public function resetPassword(Request $request): Response
    {
        try {
            $ipAddress = IPValidator::getClientIP($request);

            // Rate limiting para prevenir ataques de fuerza bruta
            $rateLimitCheck = RateLimiter::check('reset-password', $ipAddress);
            if (!$rateLimitCheck['allowed']) {
                $retryAfter = $rateLimitCheck['reset_at'] - time();
                return ResponseFormatter::rateLimitExceeded($retryAfter);
            }

            // Validar JSON
            $jsonValidation = RequestValidator::parseJsonBody($request);
            if (!$jsonValidation['valid']) {
                return ResponseFormatter::error(
                    $jsonValidation['error'],
                    null,
                    $jsonValidation['statusCode']
                );
            }

            // Obtener inputs
            $token = RequestValidator::sanitizeString($request->input('token', ''));
            $password = $request->input('password', '');
            $passwordConfirmation = $request->input('password_confirmation', '');

            // Validaciones
            $errors = [];
            if (empty($token)) {
                $errors['token'] = 'El token es requerido';
            }
            if (empty($password)) {
                $errors['password'] = 'La contraseña es requerida';
            } elseif (strlen($password) < 8) {
                $errors['password'] = 'La contraseña debe tener al menos 8 caracteres';
            }
            if ($password !== $passwordConfirmation) {
                $errors['password_confirmation'] = 'Las contraseñas no coinciden';
            }

            if (!empty($errors)) {
                return ResponseFormatter::validationError($errors);
            }

            // Validar que el token exista y sea válido
            $tokenRecord = Database::fetchOne(
                'SELECT id, user_id, expires_at, used_at 
                 FROM password_reset_tokens 
                 WHERE token = ?',
                [$token]
            );

            // Token no existe
            if (!$tokenRecord) {
                RateLimiter::recordAttempt('reset-password', $ipAddress);
                throw new DomainException('Token inválido o expirado', 400);
            }

            // Token ya fue usado
            if ($tokenRecord['used_at']) {
                RateLimiter::recordAttempt('reset-password', $ipAddress);
                throw new DomainException('Token ya fue utilizado', 400);
            }

            // Token expirado
            if (strtotime($tokenRecord['expires_at']) < time()) {
                RateLimiter::recordAttempt('reset-password', $ipAddress);
                throw new DomainException('Token expirado', 400);
            }

            $userId = (int)$tokenRecord['user_id'];

            // Hashear la nueva contraseña
            $passwordHash = password_hash($password, PASSWORD_ARGON2ID);

            // Actualizar contraseña del usuario
            Database::update(
                'users',
                [
                    'password_hash' => $passwordHash,
                    'updated_at' => date('Y-m-d H:i:s')
                ],
                'id = ?',
                [$userId]
            );

            // Marcar el token como usado
            Database::update(
                'password_reset_tokens',
                ['used_at' => date('Y-m-d H:i:s')],
                'token = ?',
                [$token]
            );

            // Invalidar todas las sesiones activas del usuario por seguridad
            Database::query(
                'DELETE FROM sessions WHERE user_id = ?',
                [$userId]
            );

            // Rate limit reset
            RateLimiter::reset('reset-password', $ipAddress);

            return ResponseFormatter::success(
                null,
                'Contraseña actualizada correctamente. Por favor, inicia sesión con tu nueva contraseña',
                200
            );

        } catch (DomainException $e) {
            return ResponseFormatter::error($e->getMessage(), null, (int)$e->getCode());
        } catch (\Exception $e) {
            return ErrorHandler::handleException($e);
        }
    }
}
