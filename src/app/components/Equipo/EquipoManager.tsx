import React, { useState } from 'react';
import { Mail, UserPlus, Trash2, Shield, User } from 'lucide-react';
import { useSupabaseData } from '../../hooks/useSupabaseData';
import { InvitacionEquipo, PerfilOrganizacion } from '../../types';

export const EquipoManager: React.FC<{ token: string }> = ({ token }) => {
  const { equipo, invitaciones, crearInvitacion, eliminarInvitacion } = useSupabaseData(token);
  const [email, setEmail] = useState('');
  const [rol, setRol] = useState<'admin' | 'usuario'>('usuario');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const handleInvitar = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email) return;
    setLoading(true);
    setError('');
    setSuccess('');
    
    try {
      await crearInvitacion(email, rol);
      setSuccess(`Invitación enviada a ${email}`);
      setEmail('');
      setRol('usuario');
    } catch (err: any) {
      setError(err.message || 'Error al enviar invitación');
    } finally {
      setLoading(false);
    }
  };

  const handleEliminarInvitacion = async (id: string) => {
    if (!confirm('¿Estás seguro de eliminar esta invitación?')) return;
    try {
      await eliminarInvitacion(id);
    } catch (err: any) {
      setError(err.message || 'Error al eliminar invitación');
    }
  };

  return (
    <div className="space-y-6 max-w-4xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Equipo y Accesos</h1>
        <p className="mt-1 text-sm text-gray-500">
          Gestiona los miembros de tu equipo y envía invitaciones.
        </p>
      </div>

      {error && (
        <div className="bg-red-50 text-red-700 p-4 rounded-md text-sm border border-red-200">
          {error}
        </div>
      )}

      {success && (
        <div className="bg-green-50 text-green-700 p-4 rounded-md text-sm border border-green-200">
          {success}
        </div>
      )}

      <div className="bg-white shadow rounded-lg overflow-hidden border border-gray-200">
        <div className="px-4 py-5 sm:p-6">
          <h3 className="text-lg leading-6 font-medium text-gray-900">Invitar Nuevo Miembro</h3>
          <div className="mt-2 max-w-xl text-sm text-gray-500">
            <p>Envía una invitación para que se unan a tu organización. El usuario deberá registrarse con ese mismo correo electrónico.</p>
          </div>
          <form onSubmit={handleInvitar} className="mt-5 sm:flex sm:items-center">
            <div className="w-full sm:max-w-xs relative rounded-md shadow-sm">
              <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <Mail className="h-5 w-5 text-gray-400" />
              </div>
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="focus:ring-indigo-500 focus:border-indigo-500 block w-full pl-10 sm:text-sm border-gray-300 rounded-md py-2 px-3 border"
                placeholder="correo@ejemplo.com"
              />
            </div>
            
            <div className="mt-3 sm:mt-0 sm:ml-3">
              <select
                value={rol}
                onChange={(e) => setRol(e.target.value as 'admin' | 'usuario')}
                className="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md border"
              >
                <option value="usuario">Usuario Regular</option>
                <option value="admin">Administrador</option>
              </select>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="mt-3 w-full inline-flex items-center justify-center px-4 py-2 border border-transparent shadow-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm disabled:opacity-50 transition-colors"
            >
              <UserPlus className="-ml-1 mr-2 h-5 w-5" />
              {loading ? 'Enviando...' : 'Invitar'}
            </button>
          </form>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        {/* Miembros Activos */}
        <div className="bg-white shadow rounded-lg border border-gray-200 overflow-hidden">
          <div className="px-4 py-5 border-b border-gray-200 sm:px-6 flex justify-between items-center bg-gray-50">
            <h3 className="text-lg leading-6 font-medium text-gray-900">Miembros Activos</h3>
            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
              {equipo.length}
            </span>
          </div>
          <ul className="divide-y divide-gray-200">
            {equipo.length === 0 ? (
              <li className="p-4 text-sm text-gray-500 text-center">No hay miembros registrados</li>
            ) : (
              equipo.map((miembro) => (
                <li key={miembro.id} className="p-4 hover:bg-gray-50 transition-colors">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center">
                      <div className="flex-shrink-0">
                        <div className="h-10 w-10 rounded-full bg-indigo-100 flex items-center justify-center text-indigo-700 font-bold">
                          {miembro.email?.charAt(0).toUpperCase() || 'U'}
                        </div>
                      </div>
                      <div className="ml-4">
                        <p className="text-sm font-medium text-gray-900">{miembro.email}</p>
                        <div className="flex items-center mt-1">
                          {miembro.rol === 'propietario' || miembro.rol === 'admin' ? (
                            <Shield className="flex-shrink-0 mr-1.5 h-4 w-4 text-indigo-500" />
                          ) : (
                            <User className="flex-shrink-0 mr-1.5 h-4 w-4 text-gray-400" />
                          )}
                          <p className="text-xs text-gray-500 capitalize">{miembro.rol}</p>
                        </div>
                      </div>
                    </div>
                  </div>
                </li>
              ))
            )}
          </ul>
        </div>

        {/* Invitaciones Pendientes */}
        <div className="bg-white shadow rounded-lg border border-gray-200 overflow-hidden">
          <div className="px-4 py-5 border-b border-gray-200 sm:px-6 flex justify-between items-center bg-gray-50">
            <h3 className="text-lg leading-6 font-medium text-gray-900">Invitaciones Pendientes</h3>
            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-amber-100 text-amber-800">
              {invitaciones.length}
            </span>
          </div>
          <ul className="divide-y divide-gray-200">
            {invitaciones.length === 0 ? (
              <li className="p-4 text-sm text-gray-500 text-center">No hay invitaciones pendientes</li>
            ) : (
              invitaciones.map((inv) => (
                <li key={inv.id} className="p-4 hover:bg-gray-50 transition-colors">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm font-medium text-gray-900">{inv.email}</p>
                      <p className="text-xs text-gray-500 mt-1 capitalize flex items-center">
                        {inv.rol === 'admin' ? <Shield className="h-3 w-3 mr-1 text-indigo-500"/> : <User className="h-3 w-3 mr-1"/>}
                        {inv.rol}
                      </p>
                    </div>
                    <button
                      onClick={() => handleEliminarInvitacion(inv.id)}
                      className="text-red-600 hover:text-red-900 p-2 rounded-full hover:bg-red-50 transition-colors"
                      title="Cancelar invitación"
                    >
                      <Trash2 className="h-5 w-5" />
                    </button>
                  </div>
                </li>
              ))
            )}
          </ul>
        </div>
      </div>
    </div>
  );
};
