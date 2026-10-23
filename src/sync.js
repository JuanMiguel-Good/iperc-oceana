import { supabase, hasSupabase } from './supabase.js';

let debounceTimer = null;
let pendingSnap = null;

async function doSync() {
  if (!pendingSnap || !hasSupabase()) return;
  const s = pendingSnap;
  try {
    await supabase.rpc('guardar_avance', {
      p_dni: s.dni,
      p_nombre: s.name,
      p_estado: s,
      p_puntos: s.pts,
      p_puesto: s.pn || null,
      p_completado: s.view === 'result',
    });
    pendingSnap = null;
  } catch (e) {
    // Sin internet o error: el juego sigue con localStorage y se sincroniza luego
  }
}

// Hook que se llama desde saveProgress() con debounce de 1 segundo
window._onSaveProgress = function (snap) {
  pendingSnap = snap;
  if (debounceTimer) clearTimeout(debounceTimer);
  debounceTimer = setTimeout(doSync, 1000);
};

// Consulta el avance remoto por DNI. Devuelve el snap o null.
window._checkRemoteSave = async function (dni) {
  if (!hasSupabase()) return null;
  try {
    const { data, error } = await supabase.rpc('obtener_avance', { p_dni: dni });
    if (error || !data) return null;
    const snap = data.estado;
    if (snap && snap.v === 1 && snap.dni === dni && Array.isArray(snap.secs)) return snap;
    return null;
  } catch (e) {
    return null;
  }
};

// Busca un participante por DNI. Devuelve {dni, nombre} o null.
window._lookupDni = async function (dni) {
  if (!hasSupabase()) return null;
  try {
    const { data, error } = await supabase.rpc('buscar_participante', { p_dni: dni });
    if (error || !data) return null;
    return data;
  } catch (e) {
    return null;
  }
};

// Al volver la conexión, reintentar sincronización pendiente
window.addEventListener('online', () => {
  if (pendingSnap && hasSupabase()) {
    if (debounceTimer) clearTimeout(debounceTimer);
    debounceTimer = setTimeout(doSync, 500);
  }
});

// Sincronización en segundo plano al cargar: si hay partida local, comprobar si la remota es más reciente
(function backgroundSync() {
  if (!hasSupabase()) return;
  const S = window.S;
  if (!S || !S.resume || !S.resume.saved) return;
  const localSnap = S.resume.saved;
  const dni = localSnap.dni;
  if (!dni) return;
  window._checkRemoteSave(dni).then((remoteSnap) => {
    if (!remoteSnap) return;
    if (remoteSnap.t && (!localSnap.t || remoteSnap.t > localSnap.t)) {
      try {
        localStorage.setItem('detectives-seguridad:v1:' + dni, JSON.stringify(remoteSnap));
        localStorage.setItem('detectives-seguridad:ultimo', dni);
      } catch (e) {}
      if (S.resume && S.resume.saved) {
        S.resume.saved = remoteSnap;
        if (S.view === 'start' && window._rerender) window._rerender();
      }
    }
  });
})();
