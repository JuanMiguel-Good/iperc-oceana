/*
# Eliminar funcion RPC buscar_avance_por_nombre

## Descripción
Se elimina la funcion buscar_avance_por_nombre porque la validacion de DNI
ahora se hace en el frontend: si el DNI existe pero el nombre no coincide,
se muestra un mensaje de error simple. Ya no se necesita buscar por nombre.

## 1. Cambios
- DROP FUNCTION buscar_avance_por_nombre(text)
*/

DROP FUNCTION IF EXISTS buscar_avance_por_nombre(text);
