// ─── OPTIRUTA Web — Utils ────────────────────────────────────

// ── Toast notifications ───────────────────────────────────────
let toastContainer = null;
function getToastContainer() {
  if (!toastContainer) {
    toastContainer = document.createElement("div");
    toastContainer.className = "toast-container";
    document.body.appendChild(toastContainer);
  }
  return toastContainer;
}
export function showToast(message, type = "default", duration = 3500) {
  const c    = getToastContainer();
  const toast = document.createElement("div");
  const icons = { success:"✅", error:"❌", warning:"⚠️", default:"ℹ️" };
  toast.className = `toast ${type}`;
  toast.innerHTML = `<span>${icons[type] || icons.default}</span> ${message}`;
  c.appendChild(toast);
  setTimeout(() => {
    toast.style.animation = "slideIn .3s ease reverse";
    setTimeout(() => toast.remove(), 300);
  }, duration);
}

// ── Modal helpers ─────────────────────────────────────────────
export function openModal(id) {
  const m = document.getElementById(id);
  if (m) { m.classList.add("open"); document.body.style.overflow = "hidden"; }
}
export function closeModal(id) {
  const m = document.getElementById(id);
  if (m) { m.classList.remove("open"); document.body.style.overflow = ""; }
}
export function bindModalClose() {
  document.querySelectorAll("[data-modal-close]").forEach(btn => {
    btn.addEventListener("click", () => closeModal(btn.dataset.modalClose));
  });
  document.querySelectorAll(".modal-overlay").forEach(overlay => {
    overlay.addEventListener("click", e => {
      if (e.target === overlay) { overlay.classList.remove("open"); document.body.style.overflow = ""; }
    });
  });
}

// ── Badge de estado ───────────────────────────────────────────
export function estadoBadge(estado) {
  const map = {
    "Pendiente":     "badge-pendiente",
    "Asignado":      "badge-asignado",
    "En Ruta":       "badge-en-ruta",
    "Entregado":     "badge-entregado",
    "No entregado":  "badge-no-entregado",
    "Activa":        "badge-en-ruta",
    "Completada":    "badge-entregado",
    "Cancelada":     "badge-no-entregado",
  };
  const cls = map[estado] || "badge-pendiente";
  return `<span class="badge ${cls}"><span class="badge-dot"></span>${estado}</span>`;
}

// ── Badge de prioridad ────────────────────────────────────────
export function prioridadBadge(p) {
  const map = { "Alta":"badge-alta", "Media":"badge-media", "Baja":"badge-baja" };
  return `<span class="badge ${map[p] || ''}">${p}</span>`;
}

// ── Formato fecha ─────────────────────────────────────────────
export function formatDate(ts) {
  if (!ts) return "—";
  let d;
  if (ts.toDate) d = ts.toDate();
  else if (typeof ts === "string") d = new Date(ts);
  else d = new Date(ts);
  return d.toLocaleDateString("es-ES", { day:"2-digit", month:"short", year:"numeric" });
}
export function formatDateTime(ts) {
  if (!ts) return "—";
  let d;
  if (ts.toDate) d = ts.toDate();
  else if (typeof ts === "string") d = new Date(ts);
  else d = new Date(ts);
  return d.toLocaleString("es-ES");
}

// ── Loading overlay ───────────────────────────────────────────
let loadingEl = null;
export function showLoading() {
  if (!loadingEl) {
    loadingEl = document.createElement("div");
    loadingEl.className = "loading-overlay";
    loadingEl.innerHTML = '<div class="spinner"></div>';
    document.body.appendChild(loadingEl);
  }
  loadingEl.style.display = "flex";
}
export function hideLoading() {
  if (loadingEl) loadingEl.style.display = "none";
}

// ── Geocodificación Nominatim (OpenStreetMap) ─────────────────
export async function geocodeAddress(address) {
  const url = `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(address)}&limit=1`;
  const res  = await fetch(url, { headers: { "Accept-Language": "es" } });
  const data = await res.json();
  if (!data.length) return null;
  return { lat: parseFloat(data[0].lat), lng: parseFloat(data[0].lon), label: data[0].display_name };
}

// ── Tabs ──────────────────────────────────────────────────────
export function initTabs(containerSel = ".tabs") {
  document.querySelectorAll(containerSel).forEach(tabsEl => {
    tabsEl.querySelectorAll(".tab-btn").forEach(btn => {
      btn.addEventListener("click", () => {
        const panel = btn.dataset.tab;
        tabsEl.querySelectorAll(".tab-btn").forEach(b => b.classList.remove("active"));
        btn.classList.add("active");
        const parent = tabsEl.closest("[data-tabs-root]") || tabsEl.parentElement;
        parent.querySelectorAll(".tab-panel").forEach(p => p.classList.remove("active"));
        const target = parent.querySelector(`#${panel}`);
        if (target) target.classList.add("active");
      });
    });
  });
}

// ── Sidebar mobile toggle ─────────────────────────────────────
export function initSidebar() {
  const sidebar  = document.getElementById("sidebar");
  const overlay  = document.getElementById("sidebar-overlay");
  const menuBtn  = document.getElementById("menu-btn");
  if (!sidebar) return;
  const toggle = () => {
    sidebar.classList.toggle("open");
    overlay?.classList.toggle("open");
  };
  menuBtn?.addEventListener("click", toggle);
  overlay?.addEventListener("click", toggle);
}

// ── Generar ID estilo PED-<timestamp> ─────────────────────────
export function generateId(prefix = "PED") {
  return `${prefix}-${Date.now()}`;
}

// ── Confirmación de acción ────────────────────────────────────
export function confirmAction(msg, cb) {
  if (window.confirm(msg)) cb();
}

// ── Formatear imágenes Base64 ──────────────────────────────────
export function formatBase64Image(base64Str, defaultMime = "image/png") {
  if (!base64Str) return "";
  if (base64Str.startsWith("data:image/")) return base64Str;
  return `data:${defaultMime};base64,${base64Str}`;
}
