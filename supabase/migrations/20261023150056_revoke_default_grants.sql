/*
# Revoke default grants on avances and reporte_avance

## Descripción
Supabase otorga permisos por defecto a los roles `anon` y `authenticated` sobre tablas y vistas nuevas.
Esto revoca explícitamente todos los permisos directos sobre `avances` y `reporte_avance`
para esos roles, dejando el acceso únicamente vía las funciones RPC (para el navegador)
y vía `service_role` para la vista del panel de administración.

## Cambios
- REVOKE ALL en `avances` para `anon` y `authenticated`.
- REVOKE ALL en `reporte_avance` para `anon` y `authenticated`.
- GRANT SELECT en `reporte_avance` solo a `service_role`.
*/

REVOKE ALL PRIVILEGES ON avances FROM anon, authenticated;
REVOKE ALL PRIVILEGES ON reporte_avance FROM anon, authenticated;
GRANT SELECT ON reporte_avance TO service_role;
