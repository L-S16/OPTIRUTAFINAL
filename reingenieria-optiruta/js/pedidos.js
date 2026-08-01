// ─── OPTIRUTA Web — Pedidos Service ──────────────────────────
import { db } from "./firebase-config.js";
import {
  collection, doc, addDoc, setDoc, updateDoc, deleteDoc,
  onSnapshot, query, where, orderBy, getDocs, getDoc, serverTimestamp
} from "https://www.gstatic.com/firebasejs/10.12.0/firebase-firestore.js";
import { generateId } from "./utils.js";

const COL = "pedidos";

// ── Escuchar pedidos en tiempo real ───────────────────────────
export function listenPedidos(cb) {
  return onSnapshot(
    query(collection(db, COL), orderBy("fechaCreacion", "desc")),
    snap => cb(snap.docs.map(d => ({ id: d.id, ...d.data() })))
  );
}

// ── Obtener todos los pedidos (una vez) ───────────────────────
export async function getPedidos() {
  const snap = await getDocs(query(collection(db, COL), orderBy("fechaCreacion", "desc")));
  return snap.docs.map(d => ({ id: d.id, ...d.data() }));
}

// ── Obtener un pedido ─────────────────────────────────────────
export async function getPedido(id) {
  const snap = await getDoc(doc(db, COL, id));
  return snap.exists() ? { id: snap.id, ...snap.data() } : null;
}

// ── Registrar nuevo pedido ────────────────────────────────────
export async function registrarPedido({ cliente, direccion, telefono, detalle, numeroCajas, prioridad }) {
  const id = generateId("PED");
  await setDoc(doc(db, COL, id), {
    id, cliente, direccion, telefono, detalle,
    numeroCajas: Number(numeroCajas),
    prioridad,
    estado: "Pendiente",
    zona: "Sin Clasificar",
    fechaCreacion: new Date().toISOString(),
  });
  return id;
}

// ── Actualizar pedido ─────────────────────────────────────────
export async function actualizarPedido(id, data) {
  await updateDoc(doc(db, COL, id), data);
}

// ── Eliminar pedido ───────────────────────────────────────────
export async function eliminarPedido(id) {
  await deleteDoc(doc(db, COL, id));
}

// ── Clasificar pedidos por zona (heurística de dirección) ─────
export function clasificarZona(direccion = "") {
  const d = direccion.toLowerCase();
  if (d.includes("norte") || d.includes("norte") || d.includes("av. norte"))  return "Norte";
  if (d.includes("sur")   || d.includes("av. sur"))   return "Sur";
  if (d.includes("este")  || d.includes("av. este"))  return "Este";
  if (d.includes("oeste") || d.includes("occidente")) return "Oeste";
  if (d.includes("centro") || d.includes("central"))  return "Centro";
  return "Sin Clasificar";
}

// ── Clasificar todos los pedidos pendientes ───────────────────
export async function clasificarTodosPedidos() {
  const pedidos = await getPedidos();
  const batch = pedidos.filter(p => p.estado === "Pendiente" || !p.zona || p.zona === "Sin Clasificar");
  await Promise.all(batch.map(p => actualizarPedido(p.id, { zona: clasificarZona(p.direccion) })));
  return batch.length;
}
