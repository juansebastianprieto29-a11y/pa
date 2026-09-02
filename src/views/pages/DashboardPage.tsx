import { motion } from 'framer-motion';
import { useState } from 'react';
import { BarChart, Bar, LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { Calendar, Wrench, Star, Menu, X } from 'lucide-react';
import Navbar from '../components/Navbar';
import Sidebar from '../components/Sidebar';
import { useAuth } from '../../controllers/AuthContext';

export default function DashboardPage() {
  const { user } = useAuth();
  const [sidebarOpen, setSidebarOpen] = useState(true);
  // Mock data for charts
  const monthlyData = [
    { month: 'ENE', services: 80 },
    { month: 'FEB', services: 95 },
    { month: 'MAR', services: 110 },
    { month: 'ABR', services: 90 },
    { month: 'MAY', services: 105 },
    { month: 'JUN', services: 120 },
    { month: 'JUL', services: 135 },
    { month: 'AGO', services: 115 },
    { month: 'SEP', services: 125 },
    { month: 'OCT', services: 140 },
    { month: 'NOV', services: 130 },
    { month: 'DIC', services: 125 },
  ];

  const comparisonData = [
    { year: '2023', value: 200 },
    { year: '2024', value: 250 },
    { year: '2025', value: 300 },
  ];

  const calendarDays = Array.from({ length: 31 }, (_, i) => i + 1);

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
            {/* Monthly Services */}
            <div className="card p-4 sm:p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-gray-400 text-xs sm:text-sm font-medium">Servicios Último Mes</h3>
                <Calendar className="w-5 h-5 text-primary-500 flex-shrink-0" />
              </div>
              <div className="space-y-2">
                <p className="text-3xl sm:text-4xl font-bold text-white">125</p>
                <p className="text-xs sm:text-sm text-gray-500">SERVICIOS ULTIMO MES</p>
              </div>
            </div>

            {/* User Recommendation */}
            <div className="card p-4 sm:p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-gray-400 text-xs sm:text-sm font-medium">Recomendación</h3>
                <Star className="w-5 h-5 text-yellow-500 flex-shrink-0" />
              </div>
              <div className="flex items-center justify-center h-24">
                <div className="relative">
                  <svg className="w-20 h-20 sm:w-24 sm:h-24 transform -rotate-90">
                    <circle
                      cx="48"
                      cy="48"
                      r="40"
                      stroke="currentColor"
                      strokeWidth="8"
                      fill="none"
                      className="text-dark-800"
                    />
                    <circle
                      cx="48"
                      cy="48"
                      r="40"
                      stroke="currentColor"
                      strokeWidth="8"
                      fill="none"
                      strokeDasharray={`${2 * Math.PI * 40}`}
                      strokeDashoffset={`${2 * Math.PI * 40 * (1 - 0.98)}`}
                      className="text-green-500"
                    />
                  </svg>
                  <div className="absolute inset-0 flex items-center justify-center">
                    <span className="text-lg sm:text-2xl font-bold text-white">98%</span>
                  </div>
                </div>
              </div>
              <p className="text-xs sm:text-sm text-gray-500 text-center mt-2">Recomendado por los usuarios</p>
            </div>

            {/* Active Mechanics */}
            <div className="card p-4 sm:p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-gray-400 text-xs sm:text-sm font-medium">Mecánicos Activos</h3>
                <Wrench className="w-5 h-5 text-purple-500 flex-shrink-0" />
              </div>
              <div className="flex items-center gap-3 sm:gap-4">
                <div className="w-14 h-14 sm:w-16 sm:h-16 bg-gradient-to-br from-purple-500 to-purple-600 rounded-full flex items-center justify-center flex-shrink-0">
                  <Wrench className="w-7 h-7 text-white" />
                </div>
                <div>
                  <p className="text-3xl sm:text-4xl font-bold text-white">423</p>
                  <p className="text-xs sm:text-sm text-gray-500">ACTIVOS</p>
                </div>
              </div>
            </div>

            {/* Rating */}
            <div className="card p-4 sm:p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-gray-400 text-xs sm:text-sm font-medium">Calificación</h3>
                <Star className="w-5 h-5 text-yellow-500 flex-shrink-0" />
              </div>
              <div className="text-center">
                <p className="text-4xl sm:text-5xl font-bold text-white mb-2">4.8</p>
                <div className="flex justify-center gap-1 mb-2">
                  {[...Array(5)].map((_, i) => (
                    <Star
                      key={i}
                      className={`w-4 h-4 sm:w-5 sm:h-5 ${
                        i < 4 ? 'text-yellow-500 fill-yellow-500' : 'text-gray-600'
                      }`}
                    />
                  ))}
                </div>
                <p className="text-xs sm:text-sm text-gray-500">CALIFICACIÓN PROMEDIO</p>
              </div>
            </div>
          </div>

          {/* Charts Row - stack en móvil */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 sm:gap-6">
            {/* Monthly History Chart */}
            <div className="card p-4 sm:p-6">
              <h3 className="text-lg sm:text-xl font-bold text-white mb-4">HISTORIAL MESES</h3>
              <div className="w-full h-60 sm:h-80 lg:h-96 -mx-2 sm:mx-0">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={monthlyData} margin={{ top: 20, right: 10, left: -30, bottom: 60 }}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
                    <XAxis 
                      dataKey="month" 
                      stroke="#9ca3af" 
                      tick={{ fontSize: 12 }}
                      angle={-45}
                      textAnchor="end"
                      height={80}
                    />
                    <YAxis stroke="#9ca3af" tick={{ fontSize: 12 }} />
                    <Tooltip
                      contentStyle={{
                        backgroundColor: '#1f2937',
                        border: '1px solid #374151',
                        borderRadius: '8px',
                      }}
                      cursor={{ fill: 'rgba(255, 255, 255, 0.1)' }}
                    />
                    <Bar dataKey="services" fill="url(#colorGradient)" radius={[8, 8, 0, 0]} />
                    <defs>
                      <linearGradient id="colorGradient" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stopColor="#0ea5e9" />
                        <stop offset="100%" stopColor="#a855f7" />
                      </linearGradient>
                    </defs>
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>

            {/* Calendar */}
            <div className="card p-4 sm:p-6 overflow-x-auto">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg sm:text-xl font-bold text-white">ENERO</h3>
                <div className="flex gap-2">
                  <button className="p-2 hover:bg-dark-800 rounded-lg transition-colors text-xs sm:text-base">
                    <span className="text-gray-400">&lt;</span>
                  </button>
                  <button className="p-2 hover:bg-dark-800 rounded-lg transition-colors text-xs sm:text-base">
                    <span className="text-gray-400">&gt;</span>
                  </button>
                </div>
              </div>
              <div className="grid grid-cols-7 gap-1 sm:gap-2">
                {['D', 'L', 'M', 'M', 'J', 'V', 'S'].map((day) => (
                  <div key={day} className="text-center text-gray-500 text-xs sm:text-sm font-medium">
                    {day}
                  </div>
                ))}
                {calendarDays.map((day) => (
                  <div
                    key={day}
                    className="aspect-square flex items-center justify-center text-xs sm:text-sm text-gray-400 hover:bg-dark-800 rounded-lg cursor-pointer transition-colors"
                  >
                    {day}
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Comparison Chart */}
          <div className="card p-4 sm:p-6">
            <h3 className="text-lg sm:text-xl font-bold text-white mb-4">COMPARACIONES</h3>
            <div className="w-full h-60 sm:h-80 lg:h-96 -mx-2 sm:mx-0">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={comparisonData} margin={{ top: 20, right: 10, left: -30, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
                  <XAxis dataKey="year" stroke="#9ca3af" tick={{ fontSize: 12 }} />
                  <YAxis stroke="#9ca3af" tick={{ fontSize: 12 }} />
                  <Tooltip
                    contentStyle={{
                      backgroundColor: '#1f2937',
                      border: '1px solid #374151',
                      borderRadius: '8px',
                    }}
                    cursor={{ fill: 'rgba(255, 255, 255, 0.1)' }}
                  />
                  <Line
                    type="monotone"
                    dataKey="value"
                    stroke="#0ea5e9"
                    strokeWidth={3}
                    dot={{ fill: '#0ea5e9', r: 6 }}
                  />
                </LineChart>
              </ResponsiveContainer>
            </div>
            <div className="mt-4 text-center">
              <p className="text-3xl sm:text-4xl font-bold text-white">2025</p>
              <p className="text-gray-400 text-sm sm:text-base">Más servicios</p>
            </div>
          </div>
        </motion.div>
      </main>
    </div>
  );
}
