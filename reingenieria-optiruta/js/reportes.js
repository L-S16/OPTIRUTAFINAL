// ─── OPTIRUTA Web — Reportes + PDF ───────────────────────────
// Usa jsPDF (cargado desde CDN en el HTML)

import { db } from "./firebase-config.js";
import {
  collection, getDocs, query, orderBy, where
} from "https://www.gstatic.com/firebasejs/10.12.0/firebase-firestore.js";
import { formatDateTime, estadoBadge, formatBase64Image } from "./utils.js";

// ── Obtener datos para el reporte ─────────────────────────────
export async function getReporteData() {
  const [pedidosSnap, rutasSnap] = await Promise.all([
    getDocs(query(collection(db, "pedidos"),  orderBy("fechaCreacion","desc"))),
    getDocs(query(collection(db, "entregas"), orderBy("fechaCreacion","desc"))),
  ]);
  const pedidos  = pedidosSnap.docs.map(d  => ({ id: d.id,  ...d.data()  }));
  const entregas = rutasSnap.docs.map(d    => ({ id: d.id,  ...d.data()  }));
  return { pedidos, entregas };
}

// ── KPIs generales ────────────────────────────────────────────
export function calcularKPIs(pedidos, entregas) {
  return {
    total:        pedidos.length,
    entregados:   pedidos.filter(p => p.estado === "Entregado").length,
    noEntregados: pedidos.filter(p => p.estado === "No entregado").length,
    pendientes:   pedidos.filter(p => p.estado === "Pendiente").length,
    enRuta:       pedidos.filter(p => p.estado === "En Ruta").length,
    tasaExito:    pedidos.length > 0
                    ? ((pedidos.filter(p=>p.estado==="Entregado").length / pedidos.length) * 100).toFixed(1)
                    : "0.0",
  };
}

// ── Generar PDF General con jsPDF ─────────────────────────────
export async function exportarPDFGeneral() {
  const { jsPDF }    = window.jspdf;
  const { pedidos, entregas } = await getReporteData();
  const kpis = calcularKPIs(pedidos, entregas);

  const pdf = new jsPDF({ orientation: "portrait", unit: "mm", format: "a4" });
  const W   = 210; let y = 20;

  // ── Cabecera ──────────────────────────────────────────────
  pdf.setFillColor(79,70,229);
  pdf.rect(0, 0, W, 30, "F");
  pdf.setTextColor(255,255,255);
  pdf.setFontSize(18); pdf.setFont("helvetica","bold");
  pdf.text("OPTIRUTA — Reporte General de Entregas", W/2, 12, { align:"center" });
  pdf.setFontSize(9);  pdf.setFont("helvetica","normal");
  pdf.text(`Generado: ${new Date().toLocaleString("es-ES")}`, W/2, 22, { align:"center" });

  y = 40;
  // ── KPIs ──────────────────────────────────────────────────
  pdf.setTextColor(30,41,59); pdf.setFontSize(12); pdf.setFont("helvetica","bold");
  pdf.text("Resumen General", 15, y); y += 8;

  const kpiData = [
    ["Total Pedidos", kpis.total],
    ["Entregados",    kpis.entregados],
    ["No Entregados", kpis.noEntregados],
    ["Pendientes",    kpis.pendientes],
    ["En Ruta",       kpis.enRuta],
    ["Tasa de Éxito", `${kpis.tasaExito}%`],
  ];
  const cols = [80, 30];
  kpiData.forEach(([label, val]) => {
    pdf.setFont("helvetica","normal"); pdf.setFontSize(10);
    pdf.setFillColor(248,250,252); pdf.rect(15, y-5, W-30, 9, "F");
    pdf.text(label,      20, y);
    pdf.setFont("helvetica","bold");
    pdf.text(String(val), 100, y);
    y += 10;
  });

  y += 6;
  // ── Tabla de pedidos ──────────────────────────────────────
  pdf.setFont("helvetica","bold"); pdf.setFontSize(12);
  pdf.text("Detalle de Pedidos", 15, y); y += 8;

  const headers = ["ID","Cliente","Dirección","Estado","Prioridad","Cajas"];
  const widths  = [30,   35,        55,          28,       22,        15];
  let x = 15;
  pdf.setFillColor(79,70,229); pdf.rect(15, y-5, W-30, 8, "F");
  pdf.setTextColor(255,255,255); pdf.setFontSize(8); pdf.setFont("helvetica","bold");
  headers.forEach((h,i) => { pdf.text(h, x+2, y); x += widths[i]; });
  y += 5; x = 15; pdf.setTextColor(30,41,59);

  pedidos.slice(0,50).forEach((p, idx) => {
    if (y > 270) { pdf.addPage(); y = 20; }
    pdf.setFillColor(idx%2===0 ? 248:255, idx%2===0 ? 250:255, idx%2===0 ? 252:255);
    pdf.rect(15, y-4, W-30, 8, "F");
    pdf.setFont("helvetica","normal"); pdf.setFontSize(7.5);
    const row = [p.id||"", p.cliente||"", (p.direccion||"").substring(0,30), p.estado||"", p.prioridad||"", String(p.numeroCajas||0)];
    x = 15;
    row.forEach((v,i) => { pdf.text(v, x+2, y); x += widths[i]; });
    y += 8;
  });

  pdf.save("optiruta_reporte_general.pdf");
}

// ── Generar PDF individual de una entrega ─────────────────────
export async function exportarPDFEntrega(entrega, pedido) {
  const { jsPDF } = window.jspdf;
  const pdf = new jsPDF({ orientation: "portrait", unit: "mm", format: "a4" });
  const W   = 210; let y = 20;

  pdf.setFillColor(79,70,229); pdf.rect(0,0,W,30,"F");
  pdf.setTextColor(255,255,255); pdf.setFontSize(16); pdf.setFont("helvetica","bold");
  pdf.text("OPTIRUTA — Comprobante de Entrega", W/2, 12, {align:"center"});
  pdf.setFontSize(9); pdf.setFont("helvetica","normal");
  pdf.text(`Fecha: ${new Date().toLocaleString("es-ES")}`, W/2, 22, {align:"center"});

  y = 42;
  const fields = [
    ["ID Pedido",   pedido?.id || entrega.id],
    ["Cliente",     pedido?.cliente || "—"],
    ["Dirección",   pedido?.direccion || "—"],
    ["Estado",      entrega.estado || "—"],
    ["Conductor",   entrega.nombreConductor || "—"],
    ["Observaciones", entrega.observaciones || "—"],
    ["Cajas Devueltas", String(entrega.cajasDevueltas||0)],
    ["Fecha",       formatDateTime(entrega.fechaActualizacion)],
  ];
  fields.forEach(([k,v]) => {
    pdf.setFont("helvetica","bold"); pdf.setFontSize(9); pdf.setTextColor(100,116,139);
    pdf.text(k+":", 15, y);
    pdf.setFont("helvetica","normal"); pdf.setTextColor(30,41,59);
    pdf.text(v, 70, y);
    y += 9;
  });

  // Firma
  if (entrega.firmaBase64) {
    y += 4;
    pdf.setFont("helvetica","bold"); pdf.setTextColor(100,116,139); pdf.setFontSize(9);
    pdf.text("Firma del Cliente:", 15, y); y += 6;
    const imgData = formatBase64Image(entrega.firmaBase64, "image/png");
    try { pdf.addImage(imgData, "PNG", 15, y, 80, 40); y += 46; } catch(e){ console.error("Error firma PDF:", e); }
  }
  // Foto
  if (entrega.fotoBase64) {
    y += 4;
    pdf.setFont("helvetica","bold"); pdf.setTextColor(100,116,139); pdf.setFontSize(9);
    pdf.text("Foto Evidencia:", 15, y); y += 6;
    const imgData = formatBase64Image(entrega.fotoBase64, "image/jpeg");
    try { pdf.addImage(imgData, "JPEG", 15, y, 80, 60); } catch(e){ console.error("Error foto PDF:", e); }
  }

  pdf.save(`optiruta_entrega_${entrega.id}.pdf`);
}
