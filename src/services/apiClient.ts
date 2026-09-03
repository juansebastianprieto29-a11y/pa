import { API_CONFIG } from '@/config/api';

export interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  message?: string;
  error?: string;
  errors?: Record<string, string[]>;
}

class ApiClient {
  private baseURL: string;

  constructor() {
    this.baseURL = API_CONFIG.API_URL;
  }

  private async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<ApiResponse<T>> {
    const url = `${this.baseURL}${endpoint}`;
    
    // No establecer Content-Type si el body es FormData (el navegador lo hace automáticamente)
    const headers: Record<string, string> = {
      Accept: 'application/json',
      ...(options.headers as Record<string, string>),
    };

    // Solo agregar Content-Type: application/json si NO es FormData
    if (!(options.body instanceof FormData)) {
      headers['Content-Type'] = 'application/json';
    }

    const config: RequestInit = {
      ...options,
      credentials: 'include', // necesario para enviar/recibir la cookie de sesión PHP
      headers,
    };

    try {
      const response = await fetch(url, config);
      const text = await response.text();
      
      // Intentar parsear como JSON
      try {
        const data = JSON.parse(text);
        return data as ApiResponse<T>;
      } catch (jsonError) {
        // Si no es JSON válido, devolver el texto como error
        console.error('❌ Respuesta no es JSON válido:', text);
        return {
          success: false,
          error: `Respuesta inválida del servidor: ${text.substring(0, 200)}`,
        };
      }
    } catch (err) {
      console.error('❌ Error de red:', err);
      return {
        success: false,
        error: 'Error de red. Verifica tu conexión o que el servidor PHP esté corriendo.',
      };
    }
  }

  async get<T>(endpoint: string): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, { method: 'GET' });
  }

  async post<T>(endpoint: string, body?: unknown): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, {
      method: 'POST',
      body: body instanceof FormData ? body : (body ? JSON.stringify(body) : undefined),
    });
  }

  async put<T>(endpoint: string, body?: unknown): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, {
      method: 'PUT',
      body: body instanceof FormData ? body : (body ? JSON.stringify(body) : undefined),
    });
  }

  async delete<T>(endpoint: string): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, { method: 'DELETE' });
  }

  async patch<T>(endpoint: string, body?: unknown): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, {
      method: 'PATCH',
      body: body instanceof FormData ? body : (body ? JSON.stringify(body) : undefined),
    });
  }
}

export const apiClient = new ApiClient();
