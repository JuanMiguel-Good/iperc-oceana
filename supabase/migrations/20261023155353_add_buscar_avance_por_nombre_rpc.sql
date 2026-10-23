/*
# Función RPC: buscar_avance_por_nombre

## Descripción
Añade una función SECURITY DEFINER que busca un avance guardado por nombre
(ignorando mayúsculas/minúsculas y espacios extra). Esto permite detectar
cuando una persona ingresa un DNI equivocado pero su nombre ya tiene progreso
guardado, evitando que el juego reinicie silenciosamente.

## 1. Nueva función
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

  -- Normalizar: lowercase, colapsar espacios internos, quitar bordes
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

-- Revocar EXECUTE por defecto y conceder a anon + authenticated
REVOKE EXECUTE ON FUNCTION buscar_avance_por_nombre(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION buscar_avance_por_nombre(text) TO anon, authenticated;
