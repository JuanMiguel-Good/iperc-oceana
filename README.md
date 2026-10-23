# Detectives de Seguridad

Juego interactivo de seguridad y salud en el trabajo para colaboradores. Parte 1: peligros comunes a todos los puestos. Parte 2: peligros propios del puesto elegido.

El juego vive en `index.html` (HTML, CSS y JavaScript puro). Usa Vite en modo vanilla para inyectar las variables de entorno y cargar el cliente de Supabase.

## Avance guardado
- Al iniciar se piden nombre y apellido y DNI (obligatorios).
- El avance se guarda automáticamente en el navegador (localStorage), un registro por DNI.
- Además, el avance se sincroniza con una base de datos Supabase cada vez que se guarda (con debounce de 1 segundo).
- Si la persona cierra el juego, al volver ve "Tienes una partida en curso" y continúa donde se quedó.
- Al ingresar el DNI en otro equipo o navegador, el juego consulta la base de datos y recupera el avance remoto si es más reciente.
- Si no hay internet, el juego sigue funcionando con localStorage y se sincroniza cuando vuelve la conexión.
- No se requiere login ni correo. La identificación es solo nombre y DNI.

## Seguridad de los datos
- La tabla `avances` tiene RLS activada. El navegador no puede listar la tabla ni leer registros de otros DNI.
- El acceso es exclusivamente a través de dos funciones RPC (SECURITY DEFINER):
  - `obtener_avance(p_dni)` — devuelve el avance del DNI solicitado o null.
  - `guardar_avance(p_dni, p_nombre, p_estado, p_puntos, p_puesto, p_completado)` — guarda o actualiza el avance.
- El listado completo de la tabla solo es visible desde el panel de administración (service_role) a través de la vista SQL `reporte_avance`.

## Variables de entorno

El proyecto usa Vite, por lo que las variables deben ir con el prefijo `VITE_`:

| Variable | Descripción |
|---|---|
| `VITE_SUPABASE_URL` | URL del proyecto Supabase |
| `VITE_SUPABASE_ANON_KEY` | Clave pública (anon key) de Supabase |

Estas variables ya están en el archivo `.env` para desarrollo local.

## Configurar en Vercel
1. Subir esta carpeta a un repositorio de GitHub.
2. En vercel.com: Add New > Project > importar el repositorio.
3. Framework Preset: Vite (se detecta automáticamente).
4. Build Command: `vite build` (automático).
5. Output Directory: `dist` (automático).
6. En Settings > Environment Variables, agregar:
   - `VITE_SUPABASE_URL` con la URL del proyecto Supabase.
   - `VITE_SUPABASE_ANON_KEY` con la anon key de Supabase.
7. Deploy.

## Panel de administración
Para consultar el reporte de avance desde el panel de Supabase (SQL Editor), ejecutar:

```sql
SELECT * FROM reporte_avance;
```

Esta vista muestra: dni, nombre, puesto, puntos, completado, iniciado_en, actualizado_en, completado_en.
