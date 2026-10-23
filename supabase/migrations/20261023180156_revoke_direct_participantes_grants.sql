/*
# Restringir el acceso directo a participantes

## Descripción
La aplicación consulta y modifica participantes mediante funciones RPC. Esta
migración revoca los permisos directos que los roles del navegador conservaban
sobre la tabla, evitando que puedan saltarse las validaciones de esas funciones.

## 1. Cambios de datos
- No se crean tablas ni columnas.
- No se modifican ni eliminan registros existentes.

## 2. Seguridad
- Se revocan SELECT, INSERT, UPDATE y DELETE sobre `participantes` para `anon`.
- Se revocan SELECT, INSERT, UPDATE y DELETE sobre `participantes` para
  `authenticated`.
- Las funciones RPC existentes y las nuevas funciones de edición y eliminación
  mantienen el acceso necesario para la aplicación.
*/

REVOKE SELECT, INSERT, UPDATE, DELETE ON participantes FROM anon, authenticated;