// ─── OPTIRUTA Web — Auth Service ─────────────────────────────
import { auth, db } from "./firebase-config.js";
import {
  signInWithEmailAndPassword,
  signOut,
  sendPasswordResetEmail,
} from "https://www.gstatic.com/firebasejs/10.12.0/firebase-auth.js";
import {
  collection,
  query,
  where,
  getDocs,
  doc,
  setDoc,
  serverTimestamp,
} from "https://www.gstatic.com/firebasejs/10.12.0/firebase-firestore.js";

// ── Guardar / leer sesión en localStorage ─────────────────────
export function saveSession(user, data) {
  const nombre = data.nombre || data.name || user.displayName || user.email;
  localStorage.setItem("or_uid",   user.uid);
  localStorage.setItem("or_email", user.email);
  localStorage.setItem("or_name",  nombre);
  localStorage.setItem("or_rol",   data.rol || "");
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

// ── Login principal ───────────────────────────────────────────
// Autentica con Firebase Auth y busca en la colección 'usuarios' por correo.
// No realiza validaciones restrictivas de rol para permitir que cada pantalla
// maneje su flujo idéntico al Flutter original.
export async function loginWithEmail(email, password) {
  // 1. Autenticar
  const cred = await signInWithEmailAndPassword(auth, email, password);
  const user  = cred.user;

  // 2. Buscar en 'usuarios' por correo (igual que Flutter)
  const q    = query(collection(db, "usuarios"), where("correo", "==", email));
  const snap = await getDocs(q);

  let data = null;

  if (!snap.empty) {
    data = snap.docs[0].data();

    // Verificar si la cuenta está activa
    if (data.estado === false) {
      await signOut(auth);
      throw new Error("Esta cuenta ha sido desactivada. Contacta al administrador.");
    }
  }

  // 3. Guardar sesión local inicial (se puede sobreescribir en cada login)
  saveSession(user, data || { rol: "" });
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

// ── Guardia de ruta ───────────────────────────────────────────
export function requireAuth(rol = null) {
  if (!isLoggedIn())                          { window.location.href = "index.html"; return false; }
  if (rol && getSession().rol !== rol)        { window.location.href = "index.html"; return false; }
  return true;
}

// ── Poblar sidebar con datos del usuario ──────────────────────
export function populateSidebarUser() {
  const s = getSession();
  const nameEl   = document.getElementById("sidebar-user-name");
  const roleEl   = document.getElementById("sidebar-user-role");
  const avatarEl = document.getElementById("sidebar-user-avatar");
  if (nameEl)   nameEl.textContent   = s.name || "Usuario";
  if (roleEl)   roleEl.textContent   = s.rol  || "";
  if (avatarEl) avatarEl.textContent = (s.name || "U")[0].toUpperCase();
}

// ── Botón logout global ───────────────────────────────────────
export function bindLogoutBtn(btnId = "btn-logout") {
  const btn = document.getElementById(btnId);
  if (btn) btn.addEventListener("click", logout);
}
