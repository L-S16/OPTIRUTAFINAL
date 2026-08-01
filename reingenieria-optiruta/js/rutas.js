// ─── OPTIRUTA Web — Rutas Service ────────────────────────────
import { db } from "./firebase-config.js";
import {
  collection, doc, addDoc, setDoc, updateDoc, deleteDoc,
  onSnapshot, query, where, orderBy, getDocs, getDoc
} from "https://www.gstatic.com/firebasejs/10.12.0/firebase-firestore.js";
import { actualizarPedido } from "./pedidos.js";
import { generateId } from "./utils.js";

const COL = "entregas"; // colección principal de rutas/entregas

// ── Crear ruta + asignar conductor ────────────────────────────
export async function crearRuta({ conductorId, nombreConductor, pedidosIds, numeroCajas }) {
  const id = generateId("RUTA");
  await setDoc(doc(db, COL, id), {
    id,
    conductorId,
    nombreConductor,
    pedidos: pedidosIds,
    numeroCajas,
    estado: "Asignado",
    numeroRuta: Date.now(),
    fechaCreacion: new Date().toISOString(),
  });
  // Actualizar estado de cada pedido
  await Promise.all(pedidosIds.map(pid => actualizarPedido(pid, { estado: "Asignado", rutaId: id })));
  return id;
}

// ── Confirmar carga → estado En Ruta ─────────────────────────
export async function confirmarCarga(rutaId, pedidosIds) {
  await updateDoc(doc(db, COL, rutaId), { estado: "En Ruta" });
  await Promise.all(pedidosIds.map(pid => actualizarPedido(pid, { estado: "En Ruta" })));
}

// ── Completar entrega ─────────────────────────────────────────
export async function registrarEntrega(rutaId, { estado, observaciones, firmaBase64, fotoBase64, cajasDevueltas, pedidoId }) {
  await updateDoc(doc(db, COL, rutaId), {
    estado,
    observaciones: observaciones || "",
    firmaBase64:   firmaBase64 || null,
    fotoBase64:    fotoBase64  || null,
    cajasDevueltas: cajasDevueltas || 0,
    fechaActualizacion: new Date().toISOString(),
  });
  if (pedidoId) {
    await actualizarPedido(pedidoId, { estado });
  }
}

// ── Escuchar rutas de un conductor ────────────────────────────
export function listenRutasConductor(conductorId, cb) {
  return onSnapshot(
    query(collection(db, COL), where("conductorId", "==", conductorId)),
    snap => cb(snap.docs.map(d => ({ id: d.id, ...d.data() })))
  );
}

// ── Escuchar todas las rutas (admin) ──────────────────────────
export function listenTodasRutas(cb) {
  return onSnapshot(
    query(collection(db, COL), orderBy("fechaCreacion", "desc")),
    snap => cb(snap.docs.map(d => ({ id: d.id, ...d.data() })))
  );
}

// ── Obtener ruta por id ───────────────────────────────────────
export async function getRuta(id) {
  const snap = await getDoc(doc(db, COL, id));
  return snap.exists() ? { id: snap.id, ...snap.data() } : null;
}

// ── Obtener entregas de un conductor por fecha ────────────────
export async function getHistorialConductor(conductorId) {
  const snap = await getDocs(
    query(collection(db, COL), where("conductorId", "==", conductorId))
  );
  return snap.docs.map(d => ({ id: d.id, ...d.data() }));
}

// ── Eliminar ruta ─────────────────────────────────────────────
export async function eliminarRuta(id) {
  await deleteDoc(doc(db, COL, id));
}
