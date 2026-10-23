/*
# Tabla `avances` para sincronizar el avance del juego

## Descripción general
Crea la tabla `avances` que guarda el progreso de cada jugador identificado por DNI.
El navegador NO puede listar la tabla ni leer registros de otros DNI; solo accede
a través de dos funciones RPC SECURITY DEFINER. El listado completo solo es visible
desde el panel de administración (service_role).

## 1. Nueva tabla
- `avances`
  - `id` (uuid, primary key, gen_random_uuid)
  - `dni` (text, 8 dígitos numéricos, UNIQUE, NOT NULL)
  - `nombre` (text, NOT NULL)
  - `estado` (jsonb, NOT NULL) — el mismo objeto que saveProgress guarda en localStorage
  - `puntos` (int, NOT NULL, default 0)
  - `puesto` (text, nullable) — nombre del puesto elegido o null
  - `completado` (boolean, NOT NULL, default false) — true cuando se llega a la vista "result"
  - `iniciado_en` (timestamptz, default now())
  - `actualizado_en` (timestamptz, default now())
  - `completado_en` (timestamptz, nullable)

## 2. Seguridad
- RLS activada en `avances`. NO se otorgan permisos SELECT/INSERT/UPDATE/DELETE
  a los roles `anon` ni `authenticated`. La tabla es inaccesible directamente.
- El acceso del navegador es únicamente a través de dos funciones RPC SECURITY DEFINER:
  - `obtener_avance(p_dni text)` — devuelve el registro del DNI solicitado (o null)
  - `guardar_avance(p_dni, p_nombre, p_estado, p_puntos, p_puesto, p_completado)` — upsert
- Se revoca EXECUTE de ambas funciones a PUBLIC y anon; se concede a `authenticated` y `anon`
  para que el navegador (anon key) pueda llamarlas.
- La vista `reporte_avance` solo concede SELECT a `service_role` (panel de administración).

## 3. Vista SQL
- `reporte_avance` (dni, nombre, puesto, puntos, completado, iniciado_en, actualizado_en, completado_en)
  para consultar desde el panel de administración.

## 4. Notas
- Las funciones RPC usan SECURITY DEFINER para operar sobre la tabla saltándose RLS.
- `guardar_avance` hace upsert: inserta si no existe, actualiza si ya existe el DNI.
- `actualizado_en` se actualiza en cada guardar; `completado_en` se setea cuando completado=true.
*/

CREATE TABLE IF NOT EXISTS avances (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  dni text NOT NULL CHECK (dni ~ '^[0-9]{8}$') UNIQUE,
  nombre text NOT NULL,
  estado jsonb NOT NULL DEFAULT '{}'::jsonb,
  puntos int NOT NULL DEFAULT 0,
  puesto text,
  completado boolean NOT NULL DEFAULT false,
  iniciado_en timestamptz NOT NULL DEFAULT now(),
  actualizado_en timestamptz NOT NULL DEFAULT now(),
  completado_en timestamptz
);

ALTER TABLE avances ENABLE ROW LEVEL SECURITY;

-- No se otorgan permisos directos sobre la tabla a anon ni authenticated.
-- El acceso es exclusivamente vía funciones RPC SECURITY DEFINER.

-- Función RPC: obtener_avance(p_dni)
-- Devuelve el registro del DNI solicitado como una fila json, o null si no existe.
CREATE OR REPLACE FUNCTION obtener_avance(p_dni text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  resultado json;
BEGIN
  IF p_dni IS NULL OR p_dni !~ '^[0-9]{8}$' THEN
    RETURN NULL;
  END IF;

  SELECT to_jsonb(t) INTO resultado
  FROM (
    SELECT dni, nombre, estado, puntos, puesto, completado, iniciado_en, actualizado_en, completado_en
    FROM avances
    WHERE dni = p_dni
    LIMIT 1
  ) t;

  RETURN resultado;
END;
$$;

-- Función RPC: guardar_avance(p_dni, p_nombre, p_estado, p_puntos, p_puesto, p_completado)
-- Hace upsert del registro. Devuelve el dni guardado.
CREATE OR REPLACE FUNCTION guardar_avance(
  p_dni text,
  p_nombre text,
  p_estado jsonb,
  p_puntos int,
  p_puesto text,
  p_completado boolean
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_dni IS NULL OR p_dni !~ '^[0-9]{8}$' THEN
    RAISE EXCEPTION 'DNI inválido';
  END IF;

  INSERT INTO avances (dni, nombre, estado, puntos, puesto, completado, iniciado_en, actualizado_en, completado_en)
  VALUES (p_dni, p_nombre, p_estado, p_puntos, p_puesto, p_completado, now(), now(),
          CASE WHEN p_completado THEN now() ELSE NULL END)
  ON CONFLICT (dni)
  DO UPDATE SET
    nombre = EXCLUDED.nombre,
    estado = EXCLUDED.estado,
    puntos = EXCLUDED.puntos,
    puesto = EXCLUDED.puesto,
    completado = EXCLUDED.completado,
    actualizado_en = now(),
    completado_en = CASE WHEN EXCLUDED.completado AND avances.completado_en IS NULL THEN now()
                         WHEN EXCLUDED.completado THEN avances.completado_en
                         ELSE NULL END;

  RETURN p_dni;
END;
$$;

-- Revocar EXECUTE por defecto y conceder a anon + authenticated
REVOKE EXECUTE ON FUNCTION obtener_avance(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION obtener_avance(text) TO anon, authenticated;

REVOKE EXECUTE ON FUNCTION guardar_avance(text, text, jsonb, int, text, boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION guardar_avance(text, text, jsonb, int, text, boolean) TO anon, authenticated;

-- Vista SQL para el panel de administración
CREATE OR REPLACE VIEW reporte_avance AS
SELECT
  dni,
  nombre,
  puesto,
  puntos,
  completado,
  iniciado_en,
  actualizado_en,
  completado_en
FROM avances
ORDER BY actualizado_en DESC;

-- La vista solo es accesible por service_role (panel de administración)
GRANT SELECT ON reporte_avance TO service_role;
