import { motion } from 'framer-motion';
import { useState } from 'react';
import { Menu, X, Users, Wrench, FileText, DollarSign } from 'lucide-react';
import Navbar from '../components/Navbar';
import Sidebar from '../components/Sidebar';
import { useAuth } from '../../controllers/AuthContext';

export default function DashboardPage() {
  const { user } = useAuth();
  const [sidebarOpen, setSidebarOpen] = useState(true);

  // Tarjetas de acceso rápido a secciones
  const quickAccessCards = [
    {
      title: 'Usuarios',
      description: 'Gestiona usuarios del sistema',
      icon: Users,
      color: 'from-blue-500 to-blue-600',
      path: '/admin/users',
    },
    {
      title: 'Mecánicos',
      description: 'Administra mecánicos certificados',
      icon: Wrench,
      color: 'from-purple-500 to-purple-600',
      path: '/admin/mechanics',
    },
    {
      title: 'Servicios',
      description: 'Ver servicios registrados',
      icon: FileText,
      color: 'from-green-500 to-green-600',
      path: '/admin/services/users',
    },
    {
      title: 'Pagos',
      description: 'Historial de transacciones',
      icon: DollarSign,
      color: 'from-yellow-500 to-yellow-600',
      path: '/admin/payments',
    },
  ];

  return (
    <div className="min-h-screen bg-dark-950">
      <Navbar isAuthenticated userName={user?.name || 'Administrador'} hideNavLinks />
      <Sidebar isOpen={sidebarOpen} />

      {/* Overlay para móvil cuando el sidebar está abierto */}
      {sidebarOpen && (
        <div 
          className="fixed inset-0 top-16 bg-black/50 z-30 md:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Main content con padding dinámico según tamaño de pantalla */}
      <main className="pt-16 p-4 sm:p-6 md:p-8 md:ml-64 transition-all">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="space-y-6"
        >
          {/* Header con botón hamburguesa para móvil */}
          <div className="flex items-center justify-between">
            <div className="flex-1">
              <h1 className="text-2xl sm:text-3xl font-bold text-white mb-2">Dashboard</h1>
              <p className="text-gray-400 text-sm sm:text-base">Bienvenido de vuelta, Juan Gustavo</p>
            </div>
            <button 
              onClick={() => setSidebarOpen(!sidebarOpen)}
              className="md:hidden p-2 bg-dark-800 rounded-lg hover:bg-dark-700 transition-colors ml-4"
            >
              {sidebarOpen ? (
                <X className="w-6 h-6 text-gray-400" />
              ) : (
                <Menu className="w-6 h-6 text-gray-400" />
              )}
            </button>
          </div>

          {/* Stats Grid - responsivo */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6">
            {quickAccessCards.map((card, index) => {
              const Icon = card.icon;
              return (
                <motion.a
                  key={index}
                  href={card.path}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: index * 0.1 }}
                  className="card p-4 sm:p-6 hover:ring-2 hover:ring-gold-500 transition-all cursor-pointer group"
                >
                  <div className={`w-12 h-12 sm:w-14 sm:h-14 bg-gradient-to-br ${card.color} rounded-lg flex items-center justify-center mb-4 group-hover:scale-110 transition-transform`}>
                    <Icon className="w-6 h-6 sm:w-7 sm:h-7 text-white" />
                  </div>
                  <h3 className="text-lg sm:text-xl font-bold text-white mb-1">{card.title}</h3>
                  <p className="text-sm text-gray-400">{card.description}</p>
                  <div className="mt-4 flex items-center text-gold-400 text-sm font-medium group-hover:translate-x-1 transition-transform">
                    Ir →
                  </div>
                </motion.a>
              );
            })}
          </div>
        </motion.div>
      </main>
    </div>
  );
}
