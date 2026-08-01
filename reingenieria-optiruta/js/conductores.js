// ─── OPTIRUTA Web — Conductores Service ──────────────────────
import { db, auth } from "./firebase-config.js";
import {
  collection, doc, setDoc, updateDoc, deleteDoc,
  onSnapshot, query, getDocs, getDoc, where
} from "https://www.gstatic.com/firebasejs/10.12.0/firebase-firestore.js";

const COL      = "conductores";
const COL_USERS= "usuarios";

// ── Escuchar conductores en tiempo real ───────────────────────
export function listenConductores(cb) {
  return onSnapshot(
    query(collection(db, COL)),
    snap => cb(snap.docs.map(d => ({ id: d.id, ...d.data() })))
  );
}

// ── Obtener conductores activos ───────────────────────────────
export async function getConductoresActivos() {
  const snap = await getDocs(query(collection(db, COL_USERS), where("rol", "==", "Conductor"), where("estado", "==", true)));
  return snap.docs.map(d => ({ id: d.id, ...d.data() }));
}

// ── Obtener un conductor ──────────────────────────────────────
export async function getConductor(id) {
  const snap = await getDoc(doc(db, COL, id));
  return snap.exists() ? { id: snap.id, ...snap.data() } : null;
}

// ── Actualizar datos del conductor ────────────────────────────
export async function actualizarConductor(id, data) {
  await updateDoc(doc(db, COL, id), data);
}

// ── Eliminar conductor ────────────────────────────────────────
export async function eliminarConductor(id) {
  await deleteDoc(doc(db, COL, id));
}

// ── Activar / Desactivar usuario ──────────────────────────────
export async function toggleEstadoUsuario(uid, estado) {
  await updateDoc(doc(db, COL_USERS, uid), { estado });
}

// ── Escuchar usuarios del sistema ─────────────────────────────
export function listenUsuarios(cb) {
  return onSnapshot(
    query(collection(db, COL_USERS)),
    snap => cb(snap.docs.map(d => ({ id: d.id, ...d.data() })))
  );
}

// ── Eliminar usuario ──────────────────────────────────────────
export async function eliminarUsuario(id) {
  await deleteDoc(doc(db, COL_USERS, id));
}
