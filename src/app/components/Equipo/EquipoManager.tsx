import React, { useState } from 'react';
import { Mail, UserPlus, Trash2, Shield, User, Building, PlusCircle } from 'lucide-react';
import { useSupabaseData } from '../../hooks/useSupabaseData';

export const EquipoManager: React.FC<{ token: string }> = ({ token }) => {
  const { 
    equipo, 
    invitaciones, 
    crearInvitacion, 
    eliminarInvitacion,
    crearOrganizacionConInvitacion 
  } = useSupabaseData(token);

  // Estados para invitación a mi organización
  const [email, setEmail] = useState('');
  const [rol, setRol] = useState<'admin' | 'usuario'>('usuario');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  // Estados para crear nueva organización e invitar
  const [newOrgName, setNewOrgName] = useState('');
  const [newOrgEmail, setNewOrgEmail] = useState('');
  const [loadingOrg, setLoadingOrg] = useState(false);
  const [errorOrg, setErrorOrg] = useState('');
  const [successOrg, setSuccessOrg] = useState('');

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

  const handleCrearNuevaOrganizacion = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newOrgName || !newOrgEmail) return;
    setLoadingOrg(true);
    setErrorOrg('');
    setSuccessOrg('');

    try {
      await crearOrganizacionConInvitacion(newOrgName, newOrgEmail);
      setSuccessOrg(`Organización "${newOrgName}" creada con éxito e invitación registrada para ${newOrgEmail} como Propietario.`);
      setNewOrgName('');
      setNewOrgEmail('');
    } catch (err: any) {
      setErrorOrg(err.message || 'Error al crear la organización');
    } finally {
      setLoadingOrg(false);
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
    <div className="space-y-6 max-w-6xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
      <div>
        <h1 className="text-2xl font-bold text-white">Equipo y Accesos</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Invita miembros a tu organización actual o crea nuevas organizaciones desde cero para nuevos clientes/usuarios.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Formulario 1: Invitar a mi organización */}
        <div className="bg-white/[0.03] shadow rounded-lg overflow-hidden border border-white/[0.06] p-5 flex flex-col justify-between">
          <div>
            <h3 className="text-lg leading-6 font-medium text-white flex items-center gap-2">
              <UserPlus className="h-5 w-5 text-accent-blue" />
              Invitar Miembro a Mi Organización
            </h3>
            <p className="mt-2 text-sm text-muted-foreground">
              Envía una invitación para que se unan a tu organización actual. Compartirán cotizaciones, clientes e inventario.
            </p>

            {error && (
              <div className="mt-4 bg-accent-red/10 text-accent-red p-3 rounded-md text-sm border border-accent-red/20">
                {error}
              </div>
            )}

            {success && (
              <div className="mt-4 bg-accent-green/10 text-accent-green p-3 rounded-md text-sm border border-accent-green/20">
                {success}
              </div>
            )}

            <form onSubmit={handleInvitar} className="mt-5 space-y-4">
              <div>
                <label className="block text-xs font-medium text-muted-foreground uppercase tracking-wider mb-1">
                  Correo Electrónico
                </label>
                <div className="relative rounded-md shadow-sm">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <Mail className="h-4 w-4 text-muted-foreground" />
                  </div>
                  <input
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="block w-full pl-9 sm:text-sm rounded-md py-2 px-3 border border-white/10 bg-white/[0.04] text-white placeholder:text-muted-foreground focus:ring-accent-blue focus:border-accent-blue focus:outline-none"
                    placeholder="correo@ejemplo.com"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-medium text-muted-foreground uppercase tracking-wider mb-1">
                  Rol del Usuario
                </label>
                <select
                  value={rol}
                  onChange={(e) => setRol(e.target.value as 'admin' | 'usuario')}
                  className="block w-full pl-3 pr-10 py-2 text-base sm:text-sm rounded-md border border-white/10 bg-white/[0.04] text-white focus:outline-none focus:ring-accent-blue focus:border-accent-blue"
                >
                  <option value="usuario">Usuario Regular</option>
                  <option value="admin">Administrador</option>
                </select>
              </div>

              <button
                type="submit"
                disabled={loading}
                className="w-full inline-flex items-center justify-center px-4 py-2 border border-transparent shadow-sm font-medium rounded-md text-white bg-accent-blue hover:bg-accent-blue/80 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-accent-blue text-sm disabled:opacity-50 transition-colors mt-2"
              >
                <UserPlus className="-ml-1 mr-2 h-4 w-4" />
                {loading ? 'Enviando...' : 'Invitar a mi Organización'}
              </button>
            </form>
          </div>
        </div>

        {/* Formulario 2: Crear nueva organización e invitar */}
        <div className="bg-white/[0.03] shadow rounded-lg overflow-hidden border border-white/[0.06] p-5 flex flex-col justify-between">
          <div>
            <h3 className="text-lg leading-6 font-medium text-white flex items-center gap-2">
              <Building className="h-5 w-5 text-accent-blue" />
              Crear Nueva Organización e Invitar
            </h3>
            <p className="mt-2 text-sm text-muted-foreground">
              Crea una nueva organización limpia e invita a un nuevo propietario. Iniciará desde cero con bases de datos vacías.
            </p>

            {errorOrg && (
              <div className="mt-4 bg-accent-red/10 text-accent-red p-3 rounded-md text-sm border border-accent-red/20">
                {errorOrg}
              </div>
            )}

            {successOrg && (
              <div className="mt-4 bg-accent-green/10 text-accent-green p-3 rounded-md text-sm border border-accent-green/20">
                {successOrg}
              </div>
            )}

            <form onSubmit={handleCrearNuevaOrganizacion} className="mt-5 space-y-4">
              <div>
                <label className="block text-xs font-medium text-muted-foreground uppercase tracking-wider mb-1">
                  Nombre de la Nueva Organización
                </label>
                <div className="relative rounded-md shadow-sm">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <Building className="h-4 w-4 text-muted-foreground" />
                  </div>
                  <input
                    type="text"
                    required
                    value={newOrgName}
                    onChange={(e) => setNewOrgName(e.target.value)}
                    className="block w-full pl-9 sm:text-sm rounded-md py-2 px-3 border border-white/10 bg-white/[0.04] text-white placeholder:text-muted-foreground focus:ring-accent-blue focus:border-accent-blue focus:outline-none"
                    placeholder="Ej. Empresa Cliente S.A."
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-medium text-muted-foreground uppercase tracking-wider mb-1">
                  Correo Electrónico del Nuevo Propietario
                </label>
                <div className="relative rounded-md shadow-sm">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <Mail className="h-4 w-4 text-muted-foreground" />
                  </div>
                  <input
                    type="email"
                    required
                    value={newOrgEmail}
                    onChange={(e) => setNewOrgEmail(e.target.value)}
                    className="block w-full pl-9 sm:text-sm rounded-md py-2 px-3 border border-white/10 bg-white/[0.04] text-white placeholder:text-muted-foreground focus:ring-accent-blue focus:border-accent-blue focus:outline-none"
                    placeholder="propietario@cliente.com"
                  />
                </div>
              </div>

              <button
                type="submit"
                disabled={loadingOrg}
                className="w-full inline-flex items-center justify-center px-4 py-2 border border-transparent shadow-sm font-medium rounded-md text-white bg-accent-blue hover:bg-accent-blue/80 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-accent-blue text-sm disabled:opacity-50 transition-colors mt-2"
              >
                <PlusCircle className="-ml-1 mr-2 h-4 w-4" />
                {loadingOrg ? 'Creando...' : 'Crear Organización e Invitar'}
              </button>
            </form>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        {/* Miembros Activos (de mi organización) */}
        <div className="bg-white/[0.03] shadow rounded-lg border border-white/[0.06] overflow-hidden">
          <div className="px-4 py-5 border-b border-white/[0.06] sm:px-6 flex justify-between items-center bg-white/[0.02]">
            <h3 className="text-lg leading-6 font-medium text-white">Miembros Activos (Mi Org)</h3>
            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-accent-green/20 text-accent-green">
              {equipo.length}
            </span>
          </div>
          <ul className="divide-y divide-white/[0.06]">
            {equipo.length === 0 ? (
              <li className="p-4 text-sm text-muted-foreground text-center">No hay miembros registrados</li>
            ) : (
              equipo.map((miembro) => (
                <li key={miembro.id} className="p-4 hover:bg-white/[0.04] transition-colors">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center">
                      <div className="flex-shrink-0">
                        <div className="h-10 w-10 rounded-full bg-accent-blue/20 flex items-center justify-center text-accent-blue font-bold">
                          {miembro.email?.charAt(0).toUpperCase() || 'U'}
                        </div>
                      </div>
                      <div className="ml-4">
                        <p className="text-sm font-medium text-white">{miembro.email}</p>
                        <div className="flex items-center mt-1">
                          {miembro.rol === 'propietario' || miembro.rol === 'admin' ? (
                            <Shield className="flex-shrink-0 mr-1.5 h-4 w-4 text-accent-blue" />
                          ) : (
                            <User className="flex-shrink-0 mr-1.5 h-4 w-4 text-muted-foreground" />
                          )}
                          <p className="text-xs text-muted-foreground capitalize">{miembro.rol}</p>
                        </div>
                      </div>
                    </div>
                  </div>
                </li>
              ))
            )}
          </ul>
        </div>

        {/* Invitaciones Pendientes (de mi organización) */}
        <div className="bg-white/[0.03] shadow rounded-lg border border-white/[0.06] overflow-hidden">
          <div className="px-4 py-5 border-b border-white/[0.06] sm:px-6 flex justify-between items-center bg-white/[0.02]">
            <h3 className="text-lg leading-6 font-medium text-white">Invitaciones Pendientes (Mi Org)</h3>
            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-orange-400/20 text-orange-400">
              {invitaciones.length}
            </span>
          </div>
          <ul className="divide-y divide-white/[0.06]">
            {invitaciones.length === 0 ? (
              <li className="p-4 text-sm text-muted-foreground text-center">No hay invitaciones pendientes en esta organización</li>
            ) : (
              invitaciones.map((inv) => (
                <li key={inv.id} className="p-4 hover:bg-white/[0.04] transition-colors">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm font-medium text-white">{inv.email}</p>
                      <p className="text-xs text-muted-foreground mt-1 capitalize flex items-center">
                        {inv.rol === 'admin' ? <Shield className="h-3 w-3 mr-1 text-accent-blue"/> : <User className="h-3 w-3 mr-1"/>}
                        {inv.rol}
                      </p>
                    </div>
                    <button
                      onClick={() => handleEliminarInvitacion(inv.id)}
                      className="text-accent-red hover:text-accent-red/80 p-2 rounded-full hover:bg-accent-red/10 transition-colors"
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
