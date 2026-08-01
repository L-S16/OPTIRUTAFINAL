// ─── OPTIRUTA Web — Auth Service ─────────────────────────────
// Replica exactamente la lógica de login de cada pantalla Flutter
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
  getDoc,
  setDoc,
  updateDoc,
  serverTimestamp,
} from "https://www.gstatic.com/firebasejs/10.12.0/firebase-firestore.js";

// ── Helpers de sesión ─────────────────────────────────────────
export function saveSession(user, nombre, rol) {
  localStorage.setItem("or_uid",   user.uid);
  localStorage.setItem("or_email", user.email);
  localStorage.setItem("or_name",  nombre || user.email);
  localStorage.setItem("or_rol",   rol);
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

// ─────────────────────────────────────────────────────────────
// LOGIN ADMINISTRADOR
// Replica: login_admin_screen.dart
//   1. signInWithEmailAndPassword
//   2. Query 'usuarios' WHERE correo == email
//   3. Si existe → validar rol === 'Administrador'
//   4. Si NO existe → auto-crear con rol Administrador (primer acceso)
// ─────────────────────────────────────────────────────────────
export async function loginAdmin(email, password) {
  const cred = await signInWithEmailAndPassword(auth, email, password);
  const user  = cred.user;

  const snap = await getDocs(
    query(collection(db, "usuarios"), where("correo", "==", email))
  );

  let nombre = "Administrador";

  if (!snap.empty) {
    const data = snap.docs[0].data();
    const rol  = data.rol;
    if (rol !== "Administrador") {
      await signOut(auth);
      throw new Error(`Acceso denegado. Tu rol es: ${rol || "(sin rol)"}`);
    }
    nombre = data.nombre || data.name || nombre;
  } else {
    // Primer acceso — auto-crear perfil igual que Flutter
    await setDoc(doc(db, "usuarios", user.uid), {
      nombre:        "Administrador",
      correo:        email,
      rol:           "Administrador",
      estado:        true,
      fechaRegistro: serverTimestamp(),
    });
  }

  saveSession(user, nombre, "Administrador");
  return { user };
}

// ─────────────────────────────────────────────────────────────
// LOGIN BODEGUERO
// Replica: login_bodeguero_screen.dart
//   1. Query 'usuarios' WHERE correo == email → solo verifica ESTADO (no rol)
//   2. signInWithEmailAndPassword
//   3. Crear/actualizar doc en colección 'bodegueros'
//   4. NO valida el campo 'rol' de usuarios
// ─────────────────────────────────────────────────────────────
export async function loginBodeguero(email, password) {
  // 1. Verificar estado ANTES de autenticar (igual que Flutter)
  const snapU = await getDocs(
    query(collection(db, "usuarios"), where("correo", "==", email))
  );
  if (!snapU.empty) {
    const data   = snapU.docs[0].data();
    const estado = data.estado !== false; // Si estado===false → desactivado
    if (!estado) {
      throw new Error("Esta cuenta ha sido desactivada por el administrador.");
    }
  }

  // 2. Autenticar
  const cred = await signInWithEmailAndPassword(auth, email, password);
  const user  = cred.user;

  // 3. Crear/actualizar en colección 'bodegueros' (igual que Flutter)
  const docRef = doc(db, "bodegueros", user.uid);
  const docSnap = await getDoc(docRef);

  let nombre;
  if (!docSnap.exists()) {
    const localPart   = email.split("@")[0];
    const nameParts   = localPart.split(".");
    const formattedName = nameParts
      .map(s => s.length ? s[0].toUpperCase() + s.slice(1) : "")
      .join(" ");
    nombre = formattedName || "Bodeguero";
    await setDoc(docRef, {
      nombre:       nombre,
      correo:       email,
      fechaRegistro: new Date().toISOString(),
      ultimoAcceso:  new Date().toISOString(),
    });
  } else {
    nombre = docSnap.data().nombre || "Bodeguero";
    await updateDoc(docRef, { ultimoAcceso: new Date().toISOString() });
  }

  saveSession(user, nombre, "Bodeguero");
  return { user };
}

// ─────────────────────────────────────────────────────────────
// LOGIN CONDUCTOR
// Replica: login_conductor_screen.dart
//   1. signInWithEmailAndPassword
//   2. Query 'usuarios' WHERE correo == email → verifica estado Y rol === Conductor
//   3. Si no existe en 'usuarios' → permite el acceso igual que Flutter
// ─────────────────────────────────────────────────────────────
export async function loginConductor(email, password) {
  const cred = await signInWithEmailAndPassword(auth, email, password);
  const user  = cred.user;

  const snapU = await getDocs(
    query(collection(db, "usuarios"), where("correo", "==", email))
  );

  let nombre = "Conductor";

  if (!snapU.empty) {
    const data   = snapU.docs[0].data();
    const estado = data.estado !== false;
    if (!estado) {
      await signOut(auth);
      throw new Error("Esta cuenta ha sido desactivada por el administrador.");
    }
    const rol = data.rol;
    if (rol && rol !== "Conductor") {
      await signOut(auth);
      throw new Error(`Acceso denegado. No tienes permisos de Conductor. Tu rol es: ${rol}`);
    }
    nombre = data.nombre || data.name || nombre;
  }
  // Si no existe en usuarios → permite acceso (igual que Flutter)

  saveSession(user, nombre, "Conductor");
  return { user };
}

// ─────────────────────────────────────────────────────────────
// loginWithEmail genérico (retrocompatibilidad)
// ─────────────────────────────────────────────────────────────
export async function loginWithEmail(email, password) {
  return loginAdmin(email, password);
}

// ── Logout ────────────────────────────────────────────────────
export async function logout() {
  clearSession();
  try { await signOut(auth); } catch(_) {}
  window.location.href = "index.html";
}

// ── Recuperar contraseña ──────────────────────────────────────
export async function resetPassword(email) {
  await sendPasswordResetEmail(auth, email);
}

// ── Guardia de ruta ───────────────────────────────────────────
export function requireAuth(rol = null) {
  if (!isLoggedIn()) { window.location.href = "index.html"; return false; }
  if (rol && getSession().rol !== rol) { window.location.href = "index.html"; return false; }
  return true;
}

// ── Poblar sidebar ────────────────────────────────────────────
export function populateSidebarUser() {
  const s = getSession();
  const nameEl   = document.getElementById("sidebar-user-name");
  const roleEl   = document.getElementById("sidebar-user-role");
  const avatarEl = document.getElementById("sidebar-user-avatar");
  if (nameEl)   nameEl.textContent   = s.name || "Usuario";
  if (roleEl)   roleEl.textContent   = s.rol  || "";
  if (avatarEl) avatarEl.textContent = (s.name || "U")[0].toUpperCase();
}

export function bindLogoutBtn(btnId = "btn-logout") {
  const btn = document.getElementById(btnId);
  if (btn) btn.addEventListener("click", logout);
}
