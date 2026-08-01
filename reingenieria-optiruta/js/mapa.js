// ─── OPTIRUTA Web — Mapa Leaflet.js ──────────────────────────
// Requiere Leaflet cargado desde CDN en el HTML

let map = null;
let markers = [];

// ── Colores por estado ────────────────────────────────────────
const ESTADO_COLOR = {
  "Entregado":     "#10B981",
  "En Ruta":       "#4F46E5",
  "Asignado":      "#F59E0B",
  "Pendiente":     "#94A3B8",
  "No entregado":  "#EF4444",
};

// ── Inicializar mapa ──────────────────────────────────────────
export function initMap(elementId = "map", center = [-0.2298500, -78.5249500], zoom = 12) {
  if (map) { map.remove(); map = null; }
  map = L.map(elementId).setView(center, zoom);
  L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
    attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
    maxZoom: 19,
  }).addTo(map);
  return map;
}

// ── Limpiar marcadores ────────────────────────────────────────
export function clearMarkers() {
  markers.forEach(m => m.remove());
  markers = [];
}

// ── Crear ícono personalizado ─────────────────────────────────
function createIcon(color) {
  return L.divIcon({
    html: `<div style="
      width:32px;height:32px;border-radius:50% 50% 50% 0;
      background:${color};border:3px solid white;
      box-shadow:0 2px 8px rgba(0,0,0,.3);
      transform:rotate(-45deg);
    "></div>`,
    iconSize: [32,32], iconAnchor: [16,32], popupAnchor: [0,-32],
    className: "",
  });
}

// ── Agregar marcadores desde pedidos con coords ───────────────
export function addPedidoMarkers(pedidos) {
  clearMarkers();
  const bounds = [];
  pedidos.forEach(p => {
    if (!p.lat || !p.lng) return;
    const color  = ESTADO_COLOR[p.estado] || "#94A3B8";
    const marker = L.marker([p.lat, p.lng], { icon: createIcon(color) })
      .bindPopup(`
        <b>${p.cliente || p.id}</b><br/>
        ${p.direccion || ""}<br/>
        <span style="color:${color};font-weight:700">${p.estado}</span><br/>
        Prioridad: ${p.prioridad || "—"}
      `)
      .addTo(map);
    markers.push(marker);
    bounds.push([p.lat, p.lng]);
  });
  if (bounds.length > 0) map.fitBounds(bounds, { padding: [40,40] });
}

// ── Trazar ruta entre puntos ──────────────────────────────────
export function drawRoute(puntos, color = "#4F46E5") {
  if (!puntos || puntos.length < 2) return;
  const poly = L.polyline(puntos, { color, weight: 4, opacity: .8, dashArray: "8 4" }).addTo(map);
  map.fitBounds(poly.getBounds(), { padding: [40,40] });
  return poly;
}

// ── Marcador de la posición actual (conductor) ────────────────
export function addCurrentLocationMarker(lat, lng) {
  const marker = L.marker([lat, lng], {
    icon: L.divIcon({
      html: `<div style="
        width:16px;height:16px;border-radius:50%;
        background:#4F46E5;border:3px solid white;
        box-shadow:0 0 0 4px rgba(79,70,229,.3);
      "></div>`,
      iconSize:[16,16], iconAnchor:[8,8], className:"",
    }),
  }).bindPopup("Tu ubicación actual").addTo(map);
  markers.push(marker);
}

// ── Obtener ubicación GPS ─────────────────────────────────────
export function getCurrentLocation() {
  return new Promise((resolve, reject) => {
    if (!navigator.geolocation) reject(new Error("Geolocalización no disponible"));
    navigator.geolocation.getCurrentPosition(
      p => resolve({ lat: p.coords.latitude, lng: p.coords.longitude }),
      e => reject(e),
      { enableHighAccuracy: true, timeout: 10000 }
    );
  });
}

// ── Geocodificar y centrar el mapa ────────────────────────────
export async function geocodeAndCenter(address) {
  const url  = `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(address)}&limit=1`;
  const res  = await fetch(url, { headers: { "Accept-Language":"es" } });
  const data = await res.json();
  if (!data.length) return null;
  const lat = parseFloat(data[0].lat), lng = parseFloat(data[0].lon);
  map.setView([lat,lng], 15);
  const m = L.marker([lat,lng]).addTo(map).bindPopup(data[0].display_name).openPopup();
  markers.push(m);
  return { lat, lng, label: data[0].display_name };
}
