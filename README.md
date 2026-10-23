# Detectives de Seguridad

Juego interactivo de seguridad y salud en el trabajo para colaboradores. Parte 1: peligros comunes a todos los puestos. Parte 2: peligros propios del puesto elegido.

Sitio estático de un solo archivo (`index.html`). No requiere build ni dependencias.

## Avance guardado
- Al iniciar se piden nombre y apellido y DNI (obligatorios).
- El avance se guarda automáticamente en el navegador (localStorage), un registro por DNI.
- Si la persona cierra el juego, al volver ve "Tienes una partida en curso" y continúa donde se quedó.
- En otro equipo o navegador, escribiendo el mismo DNI en el inicio solo recupera el avance guardado en ese mismo navegador.
- Los datos no se envían a ningún servidor.

## Publicar en Vercel
1. Subir esta carpeta a un repositorio de GitHub.
2. En vercel.com: Add New > Project > importar el repositorio.
3. Framework Preset: Other. Sin comando de build ni carpeta de salida (déjalos vacíos). Deploy.
