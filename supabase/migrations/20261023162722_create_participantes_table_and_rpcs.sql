/*
# Tabla participantes + reorganizacion de funciones RPC

## Descripcion
Crea la tabla `participantes` que almacena el DNI y nombre de cada persona
autorizada para jugar. Ahora el acceso al juego es SOLO por DNI: la persona
ingresa su DNI, el sistema busca su nombre en esta tabla, y si existe entra
al juego. Si no existe, se le indica que no esta registrado.

Tambien se elimina la funcion buscar_avance_por_nombre (ya no se necesita
buscar por nombre) y se agrega la funcion buscar_participante.

## 1. Nueva tabla
- `participantes`
  - `id` (uuid, primary key, gen_random_uuid)
  - `dni` (text, 8 digitos, UNIQUE, NOT NULL)
  - `nombre` (text, NOT NULL)
  - `creado_en` (timestamptz, default now())

## 2. Funciones RPC
- `buscar_participante(p_dni text)` — devuelve json {dni, nombre} si el DNI
  esta registrado, o null si no existe.
- `listar_participantes()` — devuelve json array con todos los participantes
  ordenados por nombre. Para el panel de administracion.
- `agregar_participante(p_dni text, p_nombre text)` — inserta un participante,
  hace upsert por DNI.
- `agregar_participantes_lote(p_lista json)` — inserta varios participantes
  desde un array [{dni, nombre}, ...].

## 3. Seguridad
- RLS activada en `participantes`. Sin grants directos a anon/authenticated.
- Todas las funciones son SECURITY DEFINER con search_path = public.
- buscar_participante y agregar_participantes: EXECUTE para anon + authenticated.
- listar_participantes y agregar_participante: EXECUTE para anon + authenticated
  (el panel de admin se protege en el frontend por DNI 40667929).

## 4. Eliminaciones
- DROP FUNCTION buscar_avance_por_nombre(text) — ya no se busca por nombre.
*/
CREATE TABLE IF NOT EXISTS participantes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  dni text NOT NULL CHECK (dni ~ '^[0-9]{8}$') UNIQUE,
  nombre text NOT NULL,
  creado_en timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE participantes ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION buscar_participante(p_dni text)
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
    SELECT dni, nombre
    FROM participantes
    WHERE dni = p_dni
    LIMIT 1
  ) t;
  RETURN resultado;
END;
$$;

CREATE OR REPLACE FUNCTION listar_participantes()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  resultado json;
BEGIN
  SELECT jsonb_agg(to_jsonb(t) ORDER BY t.nombre) INTO resultado
  FROM (
    SELECT p.dni, p.nombre, p.creado_en,
           a.completado, a.puntos, a.actualizado_en
    FROM participantes p
    LEFT JOIN avances a ON a.dni = p.dni
  ) t;
  RETURN resultado;
END;
$$;

CREATE OR REPLACE FUNCTION agregar_participante(p_dni text, p_nombre text)
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
  INSERT INTO participantes (dni, nombre) VALUES (p_dni, btrim(p_nombre))
  ON CONFLICT (dni) DO UPDATE SET nombre = EXCLUDED.nombre;
  RETURN p_dni;
END;
$$;

CREATE OR REPLACE FUNCTION agregar_participantes_lote(p_lista json)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  item json;
  agregados int := 0;
  errores text[] := ARRAY[]::text[];
BEGIN
  IF p_lista IS NULL OR jsonb_typeof(p_lista::jsonb) != 'array' THEN
    RETURN jsonb_build_object('agregados', 0, 'errores', ARRAY['Lista invalida']);
  END IF;
  FOR item IN SELECT json_array_elements(p_lista)
  LOOP
    BEGIN
      IF item->>'dni' IS NULL OR (item->>'dni') !~ '^[0-9]{8}$' THEN
        errores := array_append(errores, 'DNI invalido: ' || COALESCE(item->>'dni', 'null'));
        CONTINUE;
      END IF;
      IF item->>'nombre' IS NULL OR btrim(item->>'nombre') = '' THEN
        errores := array_append(errores, 'Nombre vacio para DNI ' || (item->>'dni'));
        CONTINUE;
      END IF;
      INSERT INTO participantes (dni, nombre) VALUES (item->>'dni', btrim(item->>'nombre'))
      ON CONFLICT (dni) DO UPDATE SET nombre = EXCLUDED.nombre;
      agregados := agregados + 1;
    EXCEPTION WHEN OTHERS THEN
      errores := array_append(errores, 'Error con DNI ' || (item->>'dni') || ': ' || SQLERRM);
    END;
  END LOOP;
  RETURN jsonb_build_object('agregados', agregados, 'errores', errores);
END;
$$;

REVOKE EXECUTE ON FUNCTION buscar_participante(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION buscar_participante(text) TO anon, authenticated;

REVOKE EXECUTE ON FUNCTION listar_participantes() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION listar_participantes() TO anon, authenticated;

REVOKE EXECUTE ON FUNCTION agregar_participante(text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION agregar_participante(text, text) TO anon, authenticated;

REVOKE EXECUTE ON FUNCTION agregar_participantes_lote(json) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION agregar_participantes_lote(json) TO anon, authenticated;

DROP FUNCTION IF EXISTS buscar_avance_por_nombre(text);
