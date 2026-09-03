import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Search, Users, UserCheck, UserX, ChevronDown, Loader2, AlertCircle, Eye } from 'lucide-react';
import Navbar from '../../components/Navbar';
import Sidebar from '../../components/Sidebar';
import { useAuth } from '../../../controllers/AuthContext';
import { 
  adminService, 
  AdminUser,
  formatUserName,
  getStatusLabel,
  mapAccountStatus
} from '../../../services/adminService';

type FilterStatus = 'all' | 'active' | 'inactive' | 'suspended';
type FilterRole = 'all' | 'customer' | 'mechanic' | 'administrator';

export default function AdminUsersPage() {
  const { user } = useAuth();
  
  // Estados de datos
  const [users, setUsers] = useState<AdminUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  
  // Estados de filtros
  const [search, setSearch] = useState('');
  const [filterStatus, setFilterStatus] = useState<FilterStatus>('all');
  const [filterRole, setFilterRole] = useState<FilterRole>('all');
  
  // Estado de actualización
  const [updatingStatus, setUpdatingStatus] = useState<number | null>(null);
  
  // Estado para ver detalles de usuario
  const [selectedUser, setSelectedUser] = useState<AdminUser | null>(null);

  // Cargar usuarios
  const loadUsers = async () => {
    try {
      setLoading(true);
      setError(null);
      
      const filters: any = {};
      if (search.trim()) filters.search = search.trim();
      if (filterStatus !== 'all') filters.status = filterStatus;
      if (filterRole !== 'all') filters.role = filterRole;

      const response = await adminService.getUsers(filters);

      if (response.success && response.data) {
        setUsers(response.data.users);
      } else {
        setError(response.error || response.message || 'Error al cargar usuarios');
      }
    } catch (err) {
      console.error('Error loading users:', err);
      setError('Error de conexión. Verifica que el servidor esté funcionando.');
    } finally {
      setLoading(false);
    }
  };

  // Cargar al montar y cuando cambien los filtros
  useEffect(() => {
    const timeoutId = setTimeout(() => {
      loadUsers();
    }, search ? 500 : 0); // Debounce de 500ms para búsqueda

    return () => clearTimeout(timeoutId);
  }, [search, filterStatus, filterRole]);

  // Cambiar estado de usuario
  const handleStatusChange = async (userId: number, newStatus: 'active' | 'inactive' | 'suspended') => {
    try {
      setUpdatingStatus(userId);
      setError(null);

      const response = await adminService.updateUserStatus(userId, newStatus);

      if (response.success) {
        // Recargar usuarios
        loadUsers();
      } else {
        setError(response.error || response.message || 'Error al actualizar estado');
      }
    } catch (err) {
      console.error('Error updating user status:', err);
      setError('Error al actualizar estado del usuario');
    } finally {
      setUpdatingStatus(null);
    }
  };

  // Badge de estado
  const statusBadge = (status: string) => {
    const mappedStatus = mapAccountStatus(status);
    const styles = {
      active: 'bg-green-500/20 text-green-400 border-green-500/30',
      inactive: 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30',
      disabled: 'bg-gray-500/20 text-gray-400 border-gray-500/30',
    };
    return (
      <span className={`px-2.5 py-1 rounded-full text-xs font-medium border ${styles[mappedStatus]}`}>
        {getStatusLabel(status)}
      </span>
    );
  };

  // Estadísticas
  const stats = {
    total: users.length,
    active: users.filter(u => u.account_status === 'active').length,
    inactive: users.filter(u => u.account_status === 'inactive').length,
    suspended: users.filter(u => u.account_status === 'suspended').length,
  };

  return (
    <div className="min-h-screen bg-dark-950">
      <Navbar isAuthenticated userName={user?.name || 'Admin'} hideNavLinks />
      <Sidebar hidden={true} />
      <main className="pt-16 p-4 sm:p-6 md:p-8">
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} className="space-y-6">
          
          {/* Header */}
          <div>
            <h1 className="text-3xl font-bold text-white">Gestión de Usuarios</h1>
            <p className="text-gray-400 text-sm mt-1">Administra las cuentas de usuarios y mecánicos registrados</p>
          </div>

          {/* Error */}
          {error && (
            <div className="flex items-center gap-3 p-4 bg-red-500/10 border border-red-500/30 rounded-xl text-red-400">
              <AlertCircle className="w-5 h-5 flex-shrink-0" />
              <span>{error}</span>
              <button 
                onClick={() => setError(null)}
                className="ml-auto text-red-400 hover:text-red-300"
              >
                ×
              </button>
            </div>
          )}

          {/* Filtros */}
          <div className="flex flex-col sm:flex-row gap-3">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-500" />
              <input 
                value={search} 
                onChange={e => setSearch(e.target.value)}
                placeholder="Buscar por nombre, email o teléfono..."
                className="input-field pl-9 text-sm w-full"
                disabled={loading} 
              />
            </div>
            <div className="flex gap-3">
              <div className="relative">
                <select 
                  value={filterRole} 
                  onChange={e => setFilterRole(e.target.value as FilterRole)}
                  className="input-field pr-8 text-sm appearance-none"
                  disabled={loading}
                >
                  <option value="all">Todos los roles</option>
                  <option value="customer">Usuarios</option>
                  <option value="mechanic">Mecánicos</option>
                  <option value="administrator">Administradores</option>
                </select>
                <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-500 pointer-events-none" />
              </div>
              <div className="relative">
                <select 
                  value={filterStatus} 
                  onChange={e => setFilterStatus(e.target.value as FilterStatus)}
                  className="input-field pr-8 text-sm appearance-none"
                  disabled={loading}
                >
                  <option value="all">Todos los estados</option>
                  <option value="active">Activos</option>
                  <option value="inactive">Inactivos</option>
                  <option value="suspended">Suspendidos</option>
                </select>
                <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-500 pointer-events-none" />
              </div>
            </div>
          </div>

          {/* Estadísticas */}
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
            {[
              { label: 'Total', value: stats.total, color: 'text-white', icon: Users },
              { label: 'Activos', value: stats.active, color: 'text-green-400', icon: UserCheck },
              { label: 'Inactivos', value: stats.inactive, color: 'text-yellow-400', icon: AlertCircle },
              { label: 'Suspendidos', value: stats.suspended, color: 'text-gray-400', icon: UserX },
            ].map(stat => {
              const Icon = stat.icon;
              return (
                <div key={stat.label} className="card p-4">
                  <div className="flex items-center justify-between mb-2">
                    <Icon className={`w-5 h-5 ${stat.color}`} />
                    <p className={`text-2xl font-bold ${stat.color}`}>
                      {loading ? '...' : stat.value}
                    </p>
                  </div>
                  <p className="text-gray-400 text-xs">{stat.label}</p>
                </div>
              );
            })}
          </div>

          {/* Tabla */}
          <div className="card overflow-hidden">
            {loading ? (
              <div className="flex flex-col items-center justify-center py-16">
                <Loader2 className="w-10 h-10 text-gold-400 animate-spin mb-3" />
                <span className="text-gray-400">Cargando usuarios...</span>
              </div>
            ) : users.length === 0 ? (
              <div className="text-center py-16 text-gray-500">
                <UserX className="w-16 h-16 mx-auto mb-4 opacity-50" />
                <p className="text-lg font-medium">No se encontraron usuarios</p>
                <p className="text-sm mt-1">Intenta cambiar los filtros de búsqueda</p>
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-anthracite-700 bg-dark-800/50">
                      <th className="text-left px-4 py-3 text-gray-400 font-semibold">Usuario</th>
                      <th className="text-left px-4 py-3 text-gray-400 font-semibold">Teléfono</th>
                      <th className="text-left px-4 py-3 text-gray-400 font-semibold">Roles</th>
                      <th className="text-left px-4 py-3 text-gray-400 font-semibold">Vehículos</th>
                      <th className="text-left px-4 py-3 text-gray-400 font-semibold">Estado</th>
                      <th className="text-left px-4 py-3 text-gray-400 font-semibold">Último acceso</th>
                      <th className="text-left px-4 py-3 text-gray-400 font-semibold">Acciones</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-anthracite-800">
                    {users.map(u => {
                      const mappedStatus = mapAccountStatus(u.account_status);
                      const isActive = mappedStatus === 'active';
                      const roles = u.roles ? u.roles.split(', ').map(r => r.trim()).filter(r => r) : [];
                      
                      return (
                        <tr key={u.id} className="hover:bg-dark-800/40 transition-colors">
                          <td className="px-4 py-3">
                            <div>
                              <p className="text-white font-medium">{u.first_name || ''} {u.last_name || ''}</p>
                              <p className="text-gray-500 text-xs">{u.email}</p>
                            </div>
                          </td>
                          <td className="px-4 py-3 text-gray-300">{u.phone || '-'}</td>
                          <td className="px-4 py-3">
                            <div className="flex flex-wrap gap-1">
                              {roles.length > 0 ? (
                                roles.map((role, idx) => {
                                  const roleLabel = role === 'customer' ? 'Usuario' : 
                                                  role === 'mechanic' ? 'Mecánico' : 
                                                  role === 'administrator' ? 'Administrador' :
                                                  role === 'admin' ? 'Administrador' : role;
                                  const roleColor = role === 'customer' ? 'bg-blue-500/20 text-blue-400 border-blue-500/30' :
                                                  role === 'mechanic' ? 'bg-purple-500/20 text-purple-400 border-purple-500/30' :
                                                  'bg-red-500/20 text-red-400 border-red-500/30';
                                  return (
                                    <span key={idx} className={`px-2 py-0.5 text-xs rounded-full border ${roleColor}`}>
                                      {roleLabel}
                                    </span>
                                  );
                                })
                              ) : (
                                <span className="text-gray-500 text-xs">Sin rol</span>
                              )}
                            </div>
                          </td>
                          <td className="px-4 py-3 text-center">
                            <span className="inline-flex items-center justify-center w-8 h-8 bg-gray-500/20 text-gray-400 rounded-full text-xs font-bold border border-gray-500/30">
                              {u.vehicle_count}
                            </span>
                          </td>
                          <td className="px-4 py-3">{statusBadge(u.account_status)}</td>
                          <td className="px-4 py-3 text-gray-400 text-xs">
                            {u.last_login_at ? new Date(u.last_login_at).toLocaleString('es-CO', {
                              year: 'numeric',
                              month: '2-digit',
                              day: '2-digit',
                              hour: '2-digit',
                              minute: '2-digit',
                              second: '2-digit',
                              hour12: true
                            }) : 'Nunca'}
                          </td>
                          <td className="px-4 py-3">
                            <div className="flex items-center gap-2">
                              {isActive ? (
                                <button 
                                  onClick={() => handleStatusChange(u.id, 'suspended')}
                                  disabled={updatingStatus === u.id}
                                  className="flex items-center gap-1.5 px-2.5 py-1.5 bg-yellow-500/10 hover:bg-yellow-500/20 text-yellow-400 border border-yellow-500/30 rounded-lg transition-colors disabled:opacity-50 text-xs font-medium" 
                                  title="Suspender usuario"
                                >
                                  {updatingStatus === u.id ? (
                                    <Loader2 className="w-3.5 h-3.5 animate-spin" />
                                  ) : (
                                    <UserX className="w-3.5 h-3.5" />
                                  )}
                                  {!updatingStatus && 'Suspender'}
                                </button>
                              ) : (
                                <button 
                                  onClick={() => handleStatusChange(u.id, 'active')}
                                  disabled={updatingStatus === u.id}
                                  className="flex items-center gap-1.5 px-2.5 py-1.5 bg-green-500/10 hover:bg-green-500/20 text-green-400 border border-green-500/30 rounded-lg transition-colors disabled:opacity-50 text-xs font-medium" 
                                  title="Activar usuario"
                                >
                                  {updatingStatus === u.id ? (
                                    <Loader2 className="w-3.5 h-3.5 animate-spin" />
                                  ) : (
                                    <UserCheck className="w-3.5 h-3.5" />
                                  )}
                                  {!updatingStatus && 'Activar'}
                                </button>
                              )}
                              <button 
                                onClick={() => setSelectedUser(u)}
                                className="flex items-center justify-center p-1.5 hover:bg-dark-700 rounded-lg transition-colors text-gray-400 hover:text-blue-400" 
                                title="Ver detalles"
                              >
                                <Eye className="w-3.5 h-3.5" />
                              </button>
                            </div>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </motion.div>
      </main>

      {/* Modal de detalles del usuario */}
      {selectedUser && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.95 }}
            className="bg-dark-800 rounded-xl border border-anthracite-700 max-w-2xl w-full max-h-[90vh] overflow-y-auto"
          >
            {/* Header */}
            <div className="flex items-center justify-between p-6 border-b border-anthracite-700 sticky top-0 bg-dark-800">
              <h2 className="text-2xl font-bold text-white">Detalles del Usuario</h2>
              <button
                onClick={() => setSelectedUser(null)}
                className="text-gray-400 hover:text-white transition-colors"
              >
                ×
              </button>
            </div>

            {/* Content */}
            <div className="p-6 space-y-6">
              {/* Información Personal */}
              <div>
                <h3 className="text-lg font-semibold text-gold-400 mb-4">Información Personal</h3>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <p className="text-gray-400 text-sm">Nombre</p>
                    <p className="text-white font-medium">{selectedUser.first_name} {selectedUser.last_name}</p>
                  </div>
                  <div>
                    <p className="text-gray-400 text-sm">Email</p>
                    <p className="text-white font-medium break-all">{selectedUser.email}</p>
                  </div>
                  <div>
                    <p className="text-gray-400 text-sm">Teléfono</p>
                    <p className="text-white font-medium">{selectedUser.phone || 'No registrado'}</p>
                  </div>
                  <div>
                    <p className="text-gray-400 text-sm">Estado</p>
                    <p className="text-white font-medium">{getStatusLabel(selectedUser.account_status)}</p>
                  </div>
                </div>
              </div>

              {/* Roles */}
              <div>
                <h3 className="text-lg font-semibold text-gold-400 mb-4">Roles</h3>
                <div className="flex flex-wrap gap-2">
                  {selectedUser.roles && selectedUser.roles.length > 0 ? (
                    selectedUser.roles.split(', ').map((role, idx) => {
                      const roleLabel = role === 'Customer' ? 'Usuario' : 
                                      role === 'Mechanic' ? 'Mecánico' : 
                                      role === 'Administrator' ? 'Administrador' : role;
                      const roleColor = role === 'Customer' ? 'bg-blue-500/20 text-blue-400 border-blue-500/30' :
                                      role === 'Mechanic' ? 'bg-purple-500/20 text-purple-400 border-purple-500/30' :
                                      'bg-red-500/20 text-red-400 border-red-500/30';
                      return (
                        <span key={idx} className={`px-3 py-1.5 text-sm rounded-lg border ${roleColor}`}>
                          {roleLabel}
                        </span>
                      );
                    })
                  ) : (
                    <span className="text-gray-500">Sin roles asignados</span>
                  )}
                </div>
              </div>

              {/* Vehículos */}
              <div>
                <h3 className="text-lg font-semibold text-gold-400 mb-4">Vehículos Registrados</h3>
                {selectedUser.vehicle_count > 0 ? (
                  <div className="bg-dark-900/50 rounded-lg p-4">
                    <p className="text-white font-medium">{selectedUser.vehicle_count} vehículo{selectedUser.vehicle_count !== 1 ? 's' : ''} registrado{selectedUser.vehicle_count !== 1 ? 's' : ''}</p>
                    <p className="text-gray-400 text-sm mt-2">Para ver los detalles completos, consulta la sección de Gestión de Vehículos</p>
                  </div>
                ) : (
                  <div className="bg-dark-900/50 rounded-lg p-4">
                    <p className="text-gray-400">No tiene vehículos registrados</p>
                  </div>
                )}
              </div>

              {/* Fechas */}
              <div>
                <h3 className="text-lg font-semibold text-gold-400 mb-4">Historial</h3>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <p className="text-gray-400 text-sm">Fecha de Registro</p>
                    <p className="text-white font-medium">
                      {selectedUser.created_at ? (() => {
                        try {
                          const date = new Date(selectedUser.created_at);
                          if (isNaN(date.getTime())) throw new Error('Invalid date');
                          return date.toLocaleDateString('es-CO', {
                            year: 'numeric',
                            month: 'long',
                            day: 'numeric',
                            hour: '2-digit',
                            minute: '2-digit'
                          });
                        } catch {
                          return selectedUser.created_at;
                        }
                      })() : 'No disponible'}
                    </p>
                  </div>
                  <div>
                    <p className="text-gray-400 text-sm">Último Acceso</p>
                    <p className="text-white font-medium">
                      {selectedUser.last_login_at ? (() => {
                        try {
                          const date = new Date(selectedUser.last_login_at);
                          if (isNaN(date.getTime())) throw new Error('Invalid date');
                          return date.toLocaleDateString('es-CO', {
                            year: 'numeric',
                            month: 'long',
                            day: 'numeric',
                            hour: '2-digit',
                            minute: '2-digit'
                          });
                        } catch {
                          return selectedUser.last_login_at;
                        }
                      })() : 'Nunca'}
                    </p>
                  </div>
                </div>
              </div>

              {/* Acciones */}
              <div className="border-t border-anthracite-700 pt-6 flex gap-3">
                <button
                  onClick={() => setSelectedUser(null)}
                  className="flex-1 px-4 py-2 bg-dark-700 hover:bg-dark-600 text-white rounded-lg transition-colors"
                >
                  Cerrar
                </button>
              </div>
            </div>
          </motion.div>
        </div>
      )}
    </div>
  );
}
