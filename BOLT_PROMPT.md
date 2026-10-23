# Prompt para Bolt (pegar tal cual)

Este repositorio es un juego de seguridad en un solo archivo `index.html` (HTML, CSS y JavaScript puro). Hoy guarda el avance en localStorage. Quiero que agregues una base de datos y sincronices el avance. Reglas:

1. No reescribas el juego en React ni cambies su diseño, textos ni lógica. Mantén `index.html` como página principal. Si necesitas un paso de build para leer variables de entorno, usa Vite en modo vanilla y conserva el juego tal cual.
2. Crea una tabla `avances` con: `dni` (texto de 8 dígitos, único), `nombre`, `estado` (jsonb, es el mismo objeto que hoy se guarda en localStorage, función `saveProgress`), `puntos` (int), `puesto` (texto), `completado` (boolean, true cuando se llega a la vista "result"), `iniciado_en`, `actualizado_en`, `completado_en`.
3. Seguridad: activa RLS. La clave pública del navegador NO debe poder listar la tabla ni leer registros de otros DNI. Expón solo dos funciones RPC con `security definer`: `obtener_avance(p_dni)` y `guardar_avance(p_dni, p_nombre, p_estado, p_puntos, p_puesto, p_completado)`. El listado completo de la tabla solo debe verse desde el panel de administración.
4. Integración en el juego: en `saveProgress()` además de localStorage llama a `guardar_avance` (con debounce de 1 segundo y sin bloquear el juego si falla). En el inicio, al validar nombre y DNI, llama a `obtener_avance`; si existe, usa `applySave` para continuar donde se quedó. Si no hay internet, el juego debe seguir funcionando con localStorage y sincronizar luego.
5. No agregues login ni correos. La identificación es solo nombre y DNI.
6. Deja las claves en variables de entorno (URL y anon key de Supabase), nunca escritas en el código, y documenta en el README cuáles configurar en Vercel.
7. Agrega una vista SQL `reporte_avance` (dni, nombre, puesto, puntos, completado, fechas) para consultarla desde el panel.
