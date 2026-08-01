// ─── OPTIRUTA Web — Auth Service ─────────────────────────────
import { auth, db } from "./firebase-config.js";
import {
  signInWithEmailAndPassword,
  signOut,
  sendPasswordResetEmail,
  onAuthStateChanged
} from "https://www.gstatic.com/firebasejs/10.12.0/firebase-auth.js";
import { doc, getDoc } from "https://www.gstatic.com/firebasejs/10.12.0/firebase-firestore.js";

// ── Rol requerido para esta página (se define en cada HTML) ──
const REQUIRED_ROLE = window.REQUIRED_ROLE || null;

// ── Guardar / leer sesión en localStorage ─────────────────────
export function saveSession(user, rol) {
  localStorage.setItem("or_uid",  user.uid);
  localStorage.setItem("or_email",user.email);
  localStorage.setItem("or_name", user.displayName || user.email);
  localStorage.setItem("or_rol",  rol);
}
export function clearSession() {
  ["or_uid","or_email","or_name","or_rol"].forEach(k => localStorage.removeItem(k));
}
export function getSession() {
  return {
    uid:   localStorage.getItem("or_uid"),
    email: localStorage.getItem("or_email"),
    name:  localStorage.getItem("or_name"),
    rol:   localStorage.getItem("or_rol"),
  };
}
export function isLoggedIn() { return !!localStorage.getItem("or_uid"); }

// ── Login ─────────────────────────────────────────────────────
export async function loginWithEmail(email, password) {
  const cred = await signInWithEmailAndPassword(auth, email, password);
  const user  = cred.user;
  // Leer rol desde Firestore colección 'usuarios'
  const snap = await getDoc(doc(db, "usuarios", user.uid));
  if (!snap.exists()) throw new Error("Usuario no encontrado en el sistema.");
  const data = snap.data();
  if (data.estado === false) throw new Error("Tu cuenta está desactivada. Contacta al administrador.");
  saveSession(user, data.rol);
  return { user, data };
}

// ── Logout ────────────────────────────────────────────────────
export async function logout() {
  clearSession();
  await signOut(auth);
  window.location.href = "index.html";
}

// ── Recuperar contraseña ──────────────────────────────────────
export async function resetPassword(email) {
  await sendPasswordResetEmail(auth, email);
}

// ── Guardia de ruta: si no hay sesión → redirige a index ──────
export function requireAuth(rol = null) {
  if (!isLoggedIn()) { window.location.href = "index.html"; return false; }
  if (rol && getSession().rol !== rol) { window.location.href = "index.html"; return false; }
  return true;
}

// ── Poblar datos de usuario en el sidebar ─────────────────────
export function populateSidebarUser() {
  const s = getSession();
  const nameEl  = document.getElementById("sidebar-user-name");
  const roleEl  = document.getElementById("sidebar-user-role");
  const avatarEl = document.getElementById("sidebar-user-avatar");
  if (nameEl)  nameEl.textContent  = s.name || "Usuario";
  if (roleEl)  roleEl.textContent  = s.rol  || "";
  if (avatarEl) avatarEl.textContent = (s.name || "U")[0].toUpperCase();
}

// ── Botón logout global ───────────────────────────────────────
export function bindLogoutBtn(btnId = "btn-logout") {
  const btn = document.getElementById(btnId);
  if (btn) btn.addEventListener("click", logout);
}
