/*
# Agregar edición y eliminación de participantes

## Descripción
Añade las operaciones que necesita el panel de administración para modificar el
nombre de una persona registrada o retirar su autorización de ingreso.

## 1. Cambios de datos
- No se crean tablas ni columnas nuevas.
- `participantes.dni` sigue siendo el identificador único del registro.
- El registro correspondiente en `avances` no se elimina al retirar un participante,
  para conservar el historial y permitir recuperarlo si se vuelve a registrar.

## 2. Nuevas funciones RPC
- `editar_participante(p_dni text, p_nombre text)` — valida el DNI y el nombre,
  actualiza el nombre del participante y devuelve su DNI.
- `eliminar_participante(p_dni text)` — valida el DNI, elimina el registro de
  `participantes` y devuelve su DNI.

## 3. Seguridad
- Ambas funciones son `SECURITY DEFINER` y fijan `search_path = public`, igual
  que las operaciones existentes del panel.
- Se revoca el permiso de ejecución público y se concede a `anon` y
  `authenticated`, porque este juego no tiene una pantalla de inicio de sesión y
  el panel actual funciona mediante su control de administrador en la interfaz.
- La tabla `participantes` continúa sin acceso directo desde el navegador; las
  operaciones pasan por funciones RPC.

## 4. Integridad y errores
- Se rechazan DNIs ausentes o que no tengan exactamente 8 números.
- Se rechazan nombres vacíos.
- Se informa cuando el participante que se quiere editar o eliminar no existe.
*/

CREATE OR REPLACE FUNCTION editar_participante(p_dni text, p_nombre text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_dni IS NULL OR p_dni !~ '^[0-9]{8}$' THEN
    RAISE EXCEPTION 'DNI invalido';
  END IF;
  IF p_nombre IS NULL OR btrim(p_nombre) = '' THEN
    RAISE EXCEPTION 'Nombre invalido';
  END IF;

  UPDATE participantes
  SET nombre = btrim(p_nombre)
  WHERE dni = p_dni;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Participante no encontrado';
  END IF;

  RETURN p_dni;
END;
$$;

CREATE OR REPLACE FUNCTION eliminar_participante(p_dni text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_dni IS NULL OR p_dni !~ '^[0-9]{8}$' THEN
    RAISE EXCEPTION 'DNI invalido';
  END IF;

  DELETE FROM participantes
  WHERE dni = p_dni;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Participante no encontrado';
  END IF;

  RETURN p_dni;
END;
$$;

REVOKE EXECUTE ON FUNCTION editar_participante(text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION editar_participante(text, text) TO anon, authenticated;

REVOKE EXECUTE ON FUNCTION eliminar_participante(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION eliminar_participante(text) TO anon, authenticated;