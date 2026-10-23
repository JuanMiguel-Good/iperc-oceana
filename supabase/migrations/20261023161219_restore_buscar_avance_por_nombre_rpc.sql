/*
# Restaurar funcion RPC: buscar_avance_por_nombre

## Descripcion
Se vuelve a crear la funcion buscar_avance_por_nombre que fue eliminada
en la migracion anterior. Esta funcion busca un avance guardado por nombre
(ignorando mayusculas/minusculas y espacios extra). Permite detectar cuando
alguien ingresa un DNI distinto al que registro originalmente, para mostrar
un mensaje de error simple en lugar de empezar desde cero.

## 1. Nueva funcion
- `buscar_avance_por_nombre(p_nombre text)` — devuelve json con el registro
  cuyo nombre coincida de forma flexible (lowercase + trim de espacios internos),
  o null si no hay coincidencia.

## 2. Seguridad
- SECURITY DEFINER, search_path = public.
- Se revoca EXECUTE de PUBLIC y anon, se concede a anon + authenticated.
- No expone datos de otras personas: devuelve solo el registro del nombre buscado.
*/

CREATE OR REPLACE FUNCTION buscar_avance_por_nombre(p_nombre text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  resultado json;
  nombre_limpio text;
BEGIN
  IF p_nombre IS NULL OR btrim(p_nombre) = '' THEN
    RETURN NULL;
  END IF;

  nombre_limpio := lower(regexp_replace(btrim(p_nombre), '\s+', ' ', 'g'));

  SELECT to_jsonb(t) INTO resultado
  FROM (
    SELECT dni, nombre, estado, puntos, puesto, completado, iniciado_en, actualizado_en, completado_en
    FROM avances
    WHERE lower(regexp_replace(btrim(nombre), '\s+', ' ', 'g')) = nombre_limpio
    ORDER BY actualizado_en DESC
    LIMIT 1
  ) t;

  RETURN resultado;
END;
$$;

REVOKE EXECUTE ON FUNCTION buscar_avance_por_nombre(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION buscar_avance_por_nombre(text) TO anon, authenticated;
