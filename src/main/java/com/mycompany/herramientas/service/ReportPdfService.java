package com.mycompany.herramientas.service;

import com.lowagie.text.Chunk;
import com.lowagie.text.Document;
import com.lowagie.text.DocumentException;
import com.lowagie.text.Element;
import com.lowagie.text.Font;
import com.lowagie.text.Image;
import com.lowagie.text.PageSize;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Phrase;
import com.lowagie.text.Rectangle;
import com.lowagie.text.pdf.ColumnText;
import com.lowagie.text.pdf.PdfContentByte;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfPageEventHelper;
import com.lowagie.text.pdf.PdfWriter;
import com.mycompany.herramientas.model.Contrato;

import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;

// Genera el PDF del reporte de Contratos: encabezado con logo, KPIs,
// gráficos (imágenes de ReportChartService) y tabla de próximos a vencer.
// Usa OpenPDF (com.lowagie.text) — fork libre de iText4, sin las
// restricciones de licencia AGPL de iText7.
public class ReportPdfService {

    // ─── paleta (alineada a styles.css de MaxFit) ───────────────

    private static final Color COLOR_TEXTO  = new Color(0x11, 0x18, 0x27);
    private static final Color COLOR_MUTED  = new Color(0x6B, 0x72, 0x80);
    private static final Color COLOR_ROJO   = new Color(0xE6, 0x30, 0x27);
    private static final Color COLOR_ROJO_OSCURO = new Color(0xC0, 0x39, 0x2B);
    private static final Color COLOR_BANNER = new Color(0x11, 0x18, 0x27);
    private static final Color COLOR_VERDE  = new Color(0x16, 0xA3, 0x4A);
    private static final Color COLOR_AMBAR  = new Color(0xD9, 0x77, 0x06);
    private static final Color COLOR_AZUL   = new Color(0x25, 0x63, 0xEB);
    private static final Color COLOR_BORDE  = new Color(0xE5, 0xE7, 0xEB);
    private static final Color COLOR_BORDE_LIGHT = new Color(0xF0, 0xF1, 0xF3);
    private static final Color COLOR_SURFACE = new Color(0xF9, 0xFA, 0xFB);
    private static final Color COLOR_BANNER_SUBTEXTO = new Color(0xFF, 0xFF, 0xFF);

    // ─── tipografías ─────────────────────────────────────────────

    private static final Font FONT_TITULO       = new Font(Font.HELVETICA, 18, Font.BOLD, COLOR_TEXTO);
    private static final Font FONT_SUBTITULO    = new Font(Font.HELVETICA, 10, Font.NORMAL, COLOR_MUTED);
    private static final Font FONT_SECCION      = new Font(Font.HELVETICA, 12, Font.BOLD, COLOR_TEXTO);
    private static final Font FONT_KPI_LABEL    = new Font(Font.HELVETICA, 8, Font.NORMAL, COLOR_MUTED);
    private static final Font FONT_TABLA_HEADER = new Font(Font.HELVETICA, 9, Font.BOLD, COLOR_MUTED);
    private static final Font FONT_TABLA_CELDA  = new Font(Font.HELVETICA, 9, Font.NORMAL, COLOR_TEXTO);
    private static final Font FONT_TEXTO_MUTED  = new Font(Font.HELVETICA, 9, Font.ITALIC, COLOR_MUTED);

    // tipografías del banner del encabezado (texto claro sobre fondo rojo)
    private static final Font FONT_BANNER_LOGO  = new Font(Font.HELVETICA, 20, Font.BOLD, Color.WHITE);
    private static final Font FONT_BANNER_TITULO = new Font(Font.HELVETICA, 19, Font.BOLD, Color.WHITE);
    private static final Font FONT_BANNER_SUB   = new Font(Font.HELVETICA, 10, Font.NORMAL, COLOR_BANNER_SUBTEXTO);

    private final ReportChartService chartService = new ReportChartService();

    // ─── datos de entrada ───────────────────────────────────────

    // record con todo lo que el reporte de Contratos necesita para exportarse.
    // se arma en ReportsController con los mismos datos que ya usa la vista web.
    public record ContratosReportData(
            int activos,
            int vencidos,
            int cancelados,
            int total,
            BigDecimal ingresosMes,
            LinkedHashMap<String, BigDecimal> ingresosPorMes,
            List<Contrato> proximosVencer,
            List<Contrato> listaActivos,
            List<Contrato> listaVencidos,
            LocalDate fechaReporte,
            String generadoPor,
            String periodoLabel,
            int contratosNuevosPeriodo,
            int contratosVencidosPeriodo
    ) {}

    // cuántas filas máximo se listan por tabla de contratos (activos/vencidos)
    // antes de recortar y mostrar la nota "mostrando N de M"
    private static final int LIMITE_FILAS_TABLA = 25;

    // ─── generación del PDF ──────────────────────────────────────

    // logoRealPath: ruta absoluta en disco (via ServletContext.getRealPath).
    // si es null o el archivo no existe, se dibuja un wordmark de texto
    // "MAXFIT" en vez de la imagen — el PDF nunca falla por falta de logo.
    public byte[] generarPdfContratos(ContratosReportData data,
                                       String logoRealPath) throws DocumentException, IOException {

        Document doc = new Document(PageSize.A4, 36, 36, 48, 54);
        ByteArrayOutputStream out = new ByteArrayOutputStream();

        PdfWriter writer = PdfWriter.getInstance(doc, out);
        writer.setPageEvent(new PiePagina());

        doc.open();

        agregarEncabezado(doc, data, logoRealPath);
        agregarKpis(doc, data);
        agregarGraficos(doc, data);
        agregarTablaProximosVencer(doc, data);
        agregarTablaContratosPorEstado(doc, "Contratos activos", data.listaActivos());
        agregarTablaContratosPorEstado(doc, "Contratos vencidos", data.listaVencidos());

        doc.close();

        return out.toByteArray();
    }

    // ─── secciones ────────────────────────────────────────────────

    private void agregarEncabezado(Document doc,
                                    ContratosReportData data,
                                    String logoRealPath) throws DocumentException, IOException {

        PdfPTable header = new PdfPTable(2);
        header.setWidthPercentage(100);
        header.setWidths(new float[]{1.3f, 2f});
        header.setSpacingAfter(18);

        // celda del logo (o wordmark de texto si no hay imagen disponible)
        // fondo rojo MaxFit — banner de marca en vez del blanco plano
        PdfPCell logoCell = new PdfPCell();
        logoCell.setBorder(Rectangle.NO_BORDER);
        logoCell.setBackgroundColor(COLOR_BANNER);
        logoCell.setVerticalAlignment(Element.ALIGN_MIDDLE);
        logoCell.setPadding(18);

        boolean logoCargado = false;

        if (logoRealPath != null) {
            try {
                Image logo = Image.getInstance(logoRealPath);
                logo.scaleToFit(90, 40);
                logoCell.addElement(logo);
                logoCargado = true;
            } catch (Exception e) {
                // sin logo disponible todavía -> se usa el wordmark de abajo
                logoCargado = false;
            }
        }

        if (!logoCargado) {
            Font fMax = new Font(Font.HELVETICA, 20, Font.BOLD, Color.WHITE);
            Font fFit = new Font(Font.HELVETICA, 20, Font.BOLD, COLOR_ROJO);
            Paragraph wordmark = new Paragraph();
            wordmark.add(new Chunk("MAX", fMax));
            wordmark.add(new Chunk("FIT", fFit));
            logoCell.addElement(wordmark);
        }

        header.addCell(logoCell);

        // celda del título + fecha, alineada a la derecha, mismo fondo negro
        PdfPCell tituloCell = new PdfPCell();
        tituloCell.setBorder(Rectangle.NO_BORDER);
        tituloCell.setBackgroundColor(COLOR_BANNER);
        tituloCell.setVerticalAlignment(Element.ALIGN_MIDDLE);
        tituloCell.setHorizontalAlignment(Element.ALIGN_RIGHT);
        tituloCell.setPadding(18);

        Paragraph titulo = new Paragraph("Reporte de contratos", FONT_BANNER_TITULO);
        titulo.setAlignment(Element.ALIGN_RIGHT);

        Paragraph periodo = new Paragraph(data.periodoLabel(), FONT_BANNER_SUB);
        periodo.setAlignment(Element.ALIGN_RIGHT);
        periodo.setSpacingBefore(2);

        DateTimeFormatter fmtFecha =
                DateTimeFormatter.ofPattern("dd 'de' MMMM 'de' yyyy", new Locale("es", "PE"));

        Paragraph fecha = new Paragraph(
                "Generado el " + data.fechaReporte().format(fmtFecha),
                new Font(Font.HELVETICA, 8, Font.NORMAL, COLOR_BANNER_SUBTEXTO)
        );
        fecha.setAlignment(Element.ALIGN_RIGHT);
        fecha.setSpacingBefore(1);

        tituloCell.addElement(titulo);
        tituloCell.addElement(periodo);
        tituloCell.addElement(fecha);

        header.addCell(tituloCell);

        doc.add(header);
    }

    private void agregarKpis(Document doc, ContratosReportData data) throws DocumentException {

        PdfPTable kpis = new PdfPTable(4);
        kpis.setWidthPercentage(100);
        kpis.setSpacingAfter(10);

        kpis.addCell(celdaKpi("Activos (hoy)", String.valueOf(data.activos()), COLOR_VERDE));
        kpis.addCell(celdaKpi("Vencidos (hoy)", String.valueOf(data.vencidos()), COLOR_AMBAR));
        kpis.addCell(celdaKpi("Cancelados (hoy)", String.valueOf(data.cancelados()), COLOR_ROJO));
        kpis.addCell(celdaKpi("Ingresos — " + data.periodoLabel(), formatoMoneda(data.ingresosMes()), COLOR_AZUL));

        doc.add(kpis);

        // segunda fila: KPIs del periodo filtrado (mensual/anual)
        Paragraph notaPeriodo = new Paragraph(
                "Resumen del periodo: " + data.periodoLabel(),
                FONT_TABLA_HEADER
        );
        notaPeriodo.setSpacingAfter(6);
        doc.add(notaPeriodo);

        PdfPTable kpisPeriodo = new PdfPTable(2);
        kpisPeriodo.setWidthPercentage(100);
        kpisPeriodo.setSpacingAfter(16);

        kpisPeriodo.addCell(celdaKpi("Contratos nuevos", String.valueOf(data.contratosNuevosPeriodo()), COLOR_VERDE));
        kpisPeriodo.addCell(celdaKpi("Contratos vencidos", String.valueOf(data.contratosVencidosPeriodo()), COLOR_AMBAR));

        doc.add(kpisPeriodo);
    }

    private PdfPCell celdaKpi(String etiqueta, String valor, Color colorValor) {

        PdfPCell cell = new PdfPCell();
        cell.setPadding(10);
        cell.setBorderColor(COLOR_BORDE);
        cell.setBorderWidth(0.5f);

        Paragraph label = new Paragraph(etiqueta.toUpperCase(Locale.ROOT), FONT_KPI_LABEL);

        Paragraph value = new Paragraph(valor, new Font(Font.HELVETICA, 17, Font.BOLD, colorValor));
        value.setSpacingBefore(3);

        cell.addElement(label);
        cell.addElement(value);

        return cell;
    }

    private void agregarGraficos(Document doc, ContratosReportData data) throws DocumentException, IOException {

        byte[] pngEstado = chartService.generarGraficoEstadoContratos(
                data.activos(), data.vencidos(), data.cancelados(), 260, 190
        );

        byte[] pngIngresos = chartService.generarGraficoIngresosMensuales(
                data.ingresosPorMes(), 340, 190
        );

        PdfPTable tabla = new PdfPTable(2);
        tabla.setWidthPercentage(100);
        tabla.setWidths(new float[]{1f, 1.2f});
        tabla.setSpacingAfter(16);

        tabla.addCell(celdaGrafico("Contratos por estado", pngEstado));
        tabla.addCell(celdaGrafico("Tendencia de ingresos", pngIngresos));

        doc.add(tabla);
    }

    private PdfPCell celdaGrafico(String titulo, byte[] png) throws DocumentException, IOException {

        PdfPCell cell = new PdfPCell();
        cell.setPadding(10);
        cell.setBorderColor(COLOR_BORDE);
        cell.setBorderWidth(0.5f);

        Paragraph tituloParrafo = new Paragraph(titulo, FONT_TABLA_HEADER);
        tituloParrafo.setSpacingAfter(6);
        cell.addElement(tituloParrafo);

        Image imagen = Image.getInstance(png);
        imagen.scalePercent(75f);
        imagen.setAlignment(Element.ALIGN_CENTER);
        cell.addElement(imagen);

        return cell;
    }

    private void agregarTablaProximosVencer(Document doc, ContratosReportData data) throws DocumentException {

        Paragraph tituloTabla = new Paragraph("Próximos a vencer (7 días)", FONT_SECCION);
        tituloTabla.setSpacingAfter(8);
        doc.add(tituloTabla);

        List<Contrato> proximos = data.proximosVencer();

        if (proximos == null || proximos.isEmpty()) {
            doc.add(new Paragraph("No hay contratos próximos a vencer.", FONT_TEXTO_MUTED));
            return;
        }

        PdfPTable tabla = new PdfPTable(4);
        tabla.setWidthPercentage(100);
        tabla.setWidths(new float[]{2.2f, 1.6f, 1.2f, 0.8f});
        tabla.setSpacingAfter(16);

        tabla.addCell(celdaHeader("Cliente"));
        tabla.addCell(celdaHeader("Plan"));
        tabla.addCell(celdaHeader("Vence"));
        tabla.addCell(celdaHeader("Días"));

        DateTimeFormatter fmt = DateTimeFormatter.ofPattern("dd MMM yyyy", new Locale("es", "PE"));
        LocalDate hoy = LocalDate.now();

        for (Contrato c : proximos) {

            String nombreCliente = c.getCliente().getNombre() + " " + c.getCliente().getApellido();
            String plan = c.getMembresia().getNombreMembresia();
            String vence = c.getFechaFin().format(fmt);
            long dias = Math.max(0, ChronoUnit.DAYS.between(hoy, c.getFechaFin()));

            tabla.addCell(celdaTexto(nombreCliente));
            tabla.addCell(celdaTexto(plan));
            tabla.addCell(celdaTexto(vence));
            tabla.addCell(celdaTexto(String.valueOf(dias)));
        }

        doc.add(tabla);
    }

    // tabla genérica de contratos (activos / vencidos): Cliente, Plan, Inicio, Fin, Monto.
    // recorta a LIMITE_FILAS_TABLA filas para no disparar el PDF a decenas de páginas;
    // si hay más, agrega una nota indicando el total real.
    private void agregarTablaContratosPorEstado(Document doc,
                                                  String titulo,
                                                  List<Contrato> contratos) throws DocumentException {

        int totalReal = contratos != null ? contratos.size() : 0;

        Paragraph tituloTabla = new Paragraph(titulo + " (" + totalReal + ")", FONT_SECCION);
        tituloTabla.setSpacingBefore(14);
        tituloTabla.setSpacingAfter(8);
        doc.add(tituloTabla);

        if (contratos == null || contratos.isEmpty()) {
            doc.add(new Paragraph("Sin registros.", FONT_TEXTO_MUTED));
            return;
        }

        PdfPTable tabla = new PdfPTable(5);
        tabla.setWidthPercentage(100);
        tabla.setWidths(new float[]{2.2f, 1.8f, 1.1f, 1.1f, 1.2f});

        tabla.addCell(celdaHeader("Cliente"));
        tabla.addCell(celdaHeader("Plan"));
        tabla.addCell(celdaHeader("Inicio"));
        tabla.addCell(celdaHeader("Fin"));
        tabla.addCell(celdaHeader("Monto"));

        DateTimeFormatter fmt = DateTimeFormatter.ofPattern("dd MMM yyyy", new Locale("es", "PE"));

        int filas = Math.min(totalReal, LIMITE_FILAS_TABLA);

        for (int i = 0; i < filas; i++) {

            Contrato c = contratos.get(i);
            String nombreCliente = c.getCliente().getNombre() + " " + c.getCliente().getApellido();
            String plan = c.getMembresia().getNombreMembresia();
            String inicio = c.getFechaInicio().format(fmt);
            String fin = c.getFechaFin().format(fmt);
            String monto = formatoMoneda(c.getMontoPagado());

            tabla.addCell(celdaTexto(nombreCliente));
            tabla.addCell(celdaTexto(plan));
            tabla.addCell(celdaTexto(inicio));
            tabla.addCell(celdaTexto(fin));
            tabla.addCell(celdaTexto(monto));
        }

        doc.add(tabla);

        if (totalReal > LIMITE_FILAS_TABLA) {
            Paragraph nota = new Paragraph(
                    "Mostrando " + LIMITE_FILAS_TABLA + " de " + totalReal
                            + " — ve el listado completo en el módulo de Contratos.",
                    FONT_TEXTO_MUTED
            );
            nota.setSpacingBefore(4);
            doc.add(nota);
        }
    }

    private PdfPCell celdaHeader(String texto) {
        PdfPCell cell = new PdfPCell(new Phrase(texto, FONT_TABLA_HEADER));
        cell.setBackgroundColor(COLOR_SURFACE);
        cell.setPadding(6);
        cell.setBorderColor(COLOR_BORDE);
        cell.setBorderWidth(0.5f);
        return cell;
    }

    private PdfPCell celdaTexto(String texto) {
        PdfPCell cell = new PdfPCell(new Phrase(texto, FONT_TABLA_CELDA));
        cell.setPadding(6);
        cell.setBorderColor(COLOR_BORDE_LIGHT);
        cell.setBorderWidth(0.5f);
        return cell;
    }

    private String formatoMoneda(BigDecimal monto) {
        BigDecimal valor = monto != null ? monto : BigDecimal.ZERO;
        return "S/. " + String.format(new Locale("es", "PE"), "%,.2f", valor);
    }

    // ─── pie de página con numeración ────────────────────────────

    private static class PiePagina extends PdfPageEventHelper {

        @Override
        public void onEndPage(PdfWriter writer, Document document) {

            PdfContentByte cb = writer.getDirectContent();

            Phrase footer = new Phrase(
                    "MaxFit — Sistema de Gestión  ·  Página " + writer.getPageNumber(),
                    FONT_TEXTO_MUTED
            );

            ColumnText.showTextAligned(
                    cb, Element.ALIGN_CENTER, footer,
                    (document.right() + document.left()) / 2,
                    document.bottom() - 20,
                    0
            );
        }
    }
}
