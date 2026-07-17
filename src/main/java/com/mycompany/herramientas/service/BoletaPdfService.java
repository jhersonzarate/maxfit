package com.mycompany.herramientas.service;

import com.lowagie.text.Chunk;
import com.lowagie.text.Document;
import com.lowagie.text.DocumentException;
import com.lowagie.text.Element;
import com.lowagie.text.Font;
import com.lowagie.text.PageSize;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Phrase;
import com.lowagie.text.Rectangle;
import com.lowagie.text.pdf.PdfContentByte;
import com.lowagie.text.pdf.PdfImportedPage;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfReader;
import com.lowagie.text.pdf.PdfWriter;
import com.mycompany.herramientas.model.Contrato;

import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;

public class BoletaPdfService {

    // Fuentes para la ticketera (todas negras, tipo Helvetica)
    private static final Font FONT_EMPRESA = new Font(Font.HELVETICA, 11, Font.BOLD);
    private static final Font FONT_HEADER = new Font(Font.HELVETICA, 8.5f, Font.NORMAL);
    private static final Font FONT_RUC = new Font(Font.HELVETICA, 9, Font.BOLD);
    private static final Font FONT_TITLE = new Font(Font.HELVETICA, 10.5f, Font.BOLD);
    private static final Font FONT_FOLIO = new Font(Font.HELVETICA, 9.5f, Font.BOLD);
    private static final Font FONT_LABEL = new Font(Font.HELVETICA, 8, Font.BOLD, Color.DARK_GRAY);
    private static final Font FONT_TEXT = new Font(Font.HELVETICA, 8.5f, Font.NORMAL);
    private static final Font FONT_TABLE_HEAD = new Font(Font.HELVETICA, 8, Font.BOLD, Color.WHITE);
    private static final Font FONT_TOTAL_LABEL = new Font(Font.HELVETICA, 9, Font.BOLD);
    private static final Font FONT_TOTAL_VALUE = new Font(Font.HELVETICA, 9, Font.BOLD);
    private static final Font FONT_GRAND_TOTAL = new Font(Font.HELVETICA, 11, Font.BOLD);
    private static final Font FONT_FOOTER = new Font(Font.HELVETICA, 7.5f, Font.ITALIC, Color.DARK_GRAY);

    private static final Color COLOR_BANDA = new Color(40, 40, 40);
    private static final Color COLOR_LINEA = new Color(180, 180, 180);

    // Formato de fecha con UTC-5
    private static final DateTimeFormatter FORMATO_FECHA_HORA = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");
    private static final DateTimeFormatter FORMATO_FECHA_CORTA = DateTimeFormatter.ofPattern("dd/MM/yyyy");

    // Ancho fijo del ticket (80mm) y márgenes usados también en el recorte final
    private static final float ANCHO_TICKET = 226.77f;
    private static final float ALTURA_MAXIMA = 1400f; // "lienzo" grande de trabajo, se recorta después
    private static final float MARGEN_LATERAL = 12f;
    private static final float MARGEN_SUPERIOR = 14f;
    private static final float MARGEN_INFERIOR = 14f;

    public byte[] generarBoletaContrato(Contrato contrato, String logoRealPath) throws DocumentException, IOException {
        // 1ra pasada: se dibuja todo en un lienzo alto de sobra, solo para
        // saber cuánto espacio ocupa realmente el contenido de esta boleta.
        ByteArrayOutputStream baosBorrador = new ByteArrayOutputStream();
        Rectangle ticketSize = new Rectangle(ANCHO_TICKET, ALTURA_MAXIMA);
        Document doc = new Document(ticketSize, MARGEN_LATERAL, MARGEN_LATERAL, MARGEN_SUPERIOR, MARGEN_INFERIOR);
        PdfWriter writer = PdfWriter.getInstance(doc, baosBorrador);
        doc.open();

        agregarCabecera(doc, contrato);
        agregarLineaSeparadora(doc);
        agregarDatosCliente(doc, contrato);
        agregarLineaSeparadora(doc);
        agregarDetalleContrato(doc, contrato);
        agregarTotales(doc, contrato);
        agregarFooter(doc);

        // Posición vertical (desde abajo) donde terminó de escribirse el contenido
        float posicionFinalY = writer.getVerticalPosition(true);
        doc.close();

        // 2da pasada: se recorta el PDF a la altura real del contenido
        float alturaReal = (ALTURA_MAXIMA - posicionFinalY) + MARGEN_INFERIOR;
        return recortarAlturaTicket(baosBorrador.toByteArray(), alturaReal);
    }

    /**
     * Toma el PDF generado sobre un lienzo alto de sobra y lo "importa" como
     * plantilla dentro de una página del alto exacto del contenido, eliminando
     * el espacio en blanco sobrante debajo del total.
     */
    private byte[] recortarAlturaTicket(byte[] pdfSinRecortar, float alturaReal) throws IOException, DocumentException {
        try (ByteArrayOutputStream baosFinal = new ByteArrayOutputStream()) {
            PdfReader reader = new PdfReader(pdfSinRecortar);

            Document docFinal = new Document(new Rectangle(ANCHO_TICKET, alturaReal), 0, 0, 0, 0);
            PdfWriter writerFinal = PdfWriter.getInstance(docFinal, baosFinal);
            docFinal.open();

            PdfContentByte cb = writerFinal.getDirectContent();
            PdfImportedPage paginaOriginal = writerFinal.getImportedPage(reader, 1);

            // Desplaza la página original hacia abajo para que el contenido
            // (que estaba arriba, en el lienzo alto) quede al inicio de la
            // página recortada, y el sobrante de abajo simplemente quede fuera.
            cb.addTemplate(paginaOriginal, 0, alturaReal - ALTURA_MAXIMA);

            docFinal.close();
            reader.close();
            return baosFinal.toByteArray();
        }
    }

    // ---------------------------------------------------------------
    // CABECERA
    // ---------------------------------------------------------------
    private void agregarCabecera(Document doc, Contrato contrato) throws DocumentException {
        Paragraph header = new Paragraph();
        header.setAlignment(Element.ALIGN_CENTER);
        header.setSpacingAfter(2f);

        header.add(new Chunk("MAXFIT S.A.C.\n", FONT_EMPRESA));
        header.add(new Chunk("Av. 3 de Octubre 217\n", FONT_HEADER));
        header.add(new Chunk("Villa EL Salvador - Lima - Lima\n", FONT_HEADER));
        header.add(new Chunk("RUC: 20123456789\n", FONT_RUC));
        doc.add(header);

        // Banda oscura con el tipo de comprobante, para que resalte como en una boleta
        // real
        PdfPTable bandaTitulo = new PdfPTable(1);
        bandaTitulo.setWidthPercentage(100);
        bandaTitulo.setSpacingBefore(6f);
        bandaTitulo.setSpacingAfter(4f);

        PdfPCell celdaTitulo = new PdfPCell();
        celdaTitulo.setBackgroundColor(COLOR_BANDA);
        celdaTitulo.setBorder(Rectangle.NO_BORDER);
        celdaTitulo.setPadding(5f);
        celdaTitulo.setHorizontalAlignment(Element.ALIGN_CENTER);

        Paragraph textoTitulo = new Paragraph();
        textoTitulo.setAlignment(Element.ALIGN_CENTER);
        textoTitulo.add(
                new Chunk("BOLETA DE VENTA ELECTRÓNICA\n", new Font(Font.HELVETICA, 9.5f, Font.BOLD, Color.WHITE)));
        textoTitulo.add(new Chunk(contrato.getId(), new Font(Font.HELVETICA, 10, Font.BOLD, Color.WHITE)));
        celdaTitulo.addElement(textoTitulo);

        bandaTitulo.addCell(celdaTitulo);
        doc.add(bandaTitulo);
    }

    // ---------------------------------------------------------------
    // DATOS DEL CLIENTE (en formato etiqueta/valor alineado en tabla)
    // ---------------------------------------------------------------
    private void agregarDatosCliente(Document doc, Contrato contrato) throws DocumentException {
        Paragraph titulo = new Paragraph("CLIENTE", FONT_LABEL);
        titulo.setSpacingAfter(3f);
        doc.add(titulo);

        String tipoDoc = contrato.getCliente().getTipoDocumento() != null
                ? contrato.getCliente().getTipoDocumento().getAbreviado()
                : "DNI";

        String fechaEmision = calcularFechaEmision(contrato);

        PdfPTable info = new PdfPTable(2);
        info.setWidthPercentage(100);
        info.setWidths(new float[] { 1.1f, 2f });
        info.setSpacingAfter(4f);

        agregarFila(info, tipoDoc + ":", contrato.getCliente().getNumeroDocumento());
        agregarFila(info, "Nombre:", contrato.getCliente().getNombreCompleto());

        if (contrato.getCliente().getEmail() != null && !contrato.getCliente().getEmail().isEmpty()) {
            agregarFila(info, "Email:", contrato.getCliente().getEmail());
        }

        agregarFila(info, "Emisión:", fechaEmision);

        if (contrato.getFechaFin() != null) {
            agregarFila(info, "Vence:", contrato.getFechaFin().format(FORMATO_FECHA_CORTA));
        }

        agregarFila(info, "Moneda:", "SOLES");
        agregarFila(info, "IGV:", "18.00 %");

        String metodoPagoStr = contrato.getMetodoPago() != null ? contrato.getMetodoPago().getNombre() : "-";
        agregarFila(info, "Pago:", metodoPagoStr);

        doc.add(info);
    }

    private String calcularFechaEmision(Contrato contrato) {
        ZoneId zonaLima = ZoneId.of("America/Lima");
        if (contrato.getFechaPago() != null) {
            ZonedDateTime zdt = contrato.getFechaPago().atZone(ZoneId.systemDefault()).withZoneSameInstant(zonaLima);
            return zdt.format(FORMATO_FECHA_HORA);
        } else if (contrato.getFechaInicio() != null) {
            return contrato.getFechaInicio().format(FORMATO_FECHA_CORTA);
        }
        return "";
    }

    private void agregarFila(PdfPTable tabla, String etiqueta, String valor) {
        PdfPCell celdaEtiqueta = new PdfPCell(new Phrase(etiqueta, FONT_LABEL));
        celdaEtiqueta.setBorder(Rectangle.NO_BORDER);
        celdaEtiqueta.setPaddingBottom(2.5f);
        celdaEtiqueta.setVerticalAlignment(Element.ALIGN_TOP);

        PdfPCell celdaValor = new PdfPCell(new Phrase(valor != null ? valor : "-", FONT_TEXT));
        celdaValor.setBorder(Rectangle.NO_BORDER);
        celdaValor.setPaddingBottom(2.5f);
        celdaValor.setVerticalAlignment(Element.ALIGN_TOP);

        tabla.addCell(celdaEtiqueta);
        tabla.addCell(celdaValor);
    }

    // ---------------------------------------------------------------
    // DETALLE DE ITEMS (tabla real con encabezado resaltado y bordes)
    // ---------------------------------------------------------------
    private void agregarDetalleContrato(Document doc, Contrato contrato) throws DocumentException {
        PdfPTable table = new PdfPTable(3);
        table.setWidthPercentage(100);
        table.setWidths(new float[] { 4.6f, 1.7f, 1.9f });
        table.setSpacingBefore(2f);

        // Cabecera con fondo oscuro, texto blanco, sin cortes de palabra
        table.addCell(celdaCabeceraTabla("DESCRIPCIÓN", Element.ALIGN_LEFT));
        table.addCell(celdaCabeceraTabla("P.UNIT", Element.ALIGN_RIGHT));
        table.addCell(celdaCabeceraTabla("TOTAL", Element.ALIGN_RIGHT));

        // Fila de ítem
        BigDecimal monto = contrato.getMontoPagado() != null ? contrato.getMontoPagado() : BigDecimal.ZERO;
        String montoStr = String.format("%.2f", monto);
        String desc = "1x Suscripción " + contrato.getMembresia().getNombreMembresia();

        table.addCell(celdaItem(desc, Element.ALIGN_LEFT, true));
        table.addCell(celdaItem(montoStr, Element.ALIGN_RIGHT, true));
        table.addCell(celdaItem(montoStr, Element.ALIGN_RIGHT, true));

        doc.add(table);
    }

    private PdfPCell celdaCabeceraTabla(String texto, int alineacion) {
        PdfPCell cell = new PdfPCell(new Phrase(texto, FONT_TABLE_HEAD));
        cell.setBackgroundColor(COLOR_BANDA);
        cell.setHorizontalAlignment(alineacion);
        cell.setVerticalAlignment(Element.ALIGN_MIDDLE);
        cell.setPadding(4f);
        cell.setBorder(Rectangle.NO_BORDER);
        return cell;
    }

    private PdfPCell celdaItem(String texto, int alineacion, boolean bordeInferior) {
        PdfPCell cell = new PdfPCell(new Phrase(texto, FONT_TEXT));
        cell.setHorizontalAlignment(alineacion);
        cell.setVerticalAlignment(Element.ALIGN_MIDDLE);
        cell.setPadding(4f);
        cell.setBorder(bordeInferior ? Rectangle.BOTTOM : Rectangle.NO_BORDER);
        cell.setBorderColor(COLOR_LINEA);
        cell.setBorderWidthBottom(0.5f);
        return cell;
    }

    // ---------------------------------------------------------------
    // TOTALES (caja delimitada con el total final resaltado)
    // ---------------------------------------------------------------
    private void agregarTotales(Document doc, Contrato contrato) throws DocumentException {
        BigDecimal monto = contrato.getMontoPagado() != null ? contrato.getMontoPagado() : BigDecimal.ZERO;
        BigDecimal igv = monto.multiply(new BigDecimal("0.18")).setScale(2, BigDecimal.ROUND_HALF_UP);
        BigDecimal subtotal = monto.subtract(igv);

        PdfPTable table = new PdfPTable(2);
        table.setWidthPercentage(100);
        table.setWidths(new float[] { 2f, 1.4f });
        table.setSpacingBefore(6f);

        table.addCell(celdaTotal("Op. Gravada  S/", Element.ALIGN_RIGHT, FONT_TOTAL_LABEL, false));
        table.addCell(celdaTotal(String.format("%.2f", subtotal), Element.ALIGN_RIGHT, FONT_TOTAL_VALUE, false));

        table.addCell(celdaTotal("IGV (18%)  S/", Element.ALIGN_RIGHT, FONT_TOTAL_LABEL, false));
        table.addCell(celdaTotal(String.format("%.2f", igv), Element.ALIGN_RIGHT, FONT_TOTAL_VALUE, false));

        // Fila final resaltada con banda oscura, como el total de un ticket real
        PdfPCell totalLabel = new PdfPCell(
                new Phrase("TOTAL A PAGAR  S/", new Font(Font.HELVETICA, 9.5f, Font.BOLD, Color.WHITE)));
        totalLabel.setBackgroundColor(COLOR_BANDA);
        totalLabel.setHorizontalAlignment(Element.ALIGN_RIGHT);
        totalLabel.setVerticalAlignment(Element.ALIGN_MIDDLE);
        totalLabel.setPadding(5f);
        totalLabel.setBorder(Rectangle.NO_BORDER);

        PdfPCell totalValue = new PdfPCell(new Phrase(String.format("%.2f", monto), FONT_GRAND_TOTAL));
        totalValue.setBackgroundColor(COLOR_BANDA);
        totalValue.getPhrase().getFont().setColor(Color.WHITE);
        totalValue.setHorizontalAlignment(Element.ALIGN_RIGHT);
        totalValue.setVerticalAlignment(Element.ALIGN_MIDDLE);
        totalValue.setPadding(5f);
        totalValue.setBorder(Rectangle.NO_BORDER);

        table.addCell(totalLabel);
        table.addCell(totalValue);

        doc.add(table);
    }

    private PdfPCell celdaTotal(String texto, int alineacion, Font fuente, boolean destacado) {
        PdfPCell cell = new PdfPCell(new Phrase(texto, fuente));
        cell.setHorizontalAlignment(alineacion);
        cell.setVerticalAlignment(Element.ALIGN_MIDDLE);
        cell.setPadding(3f);
        cell.setBorder(Rectangle.NO_BORDER);
        return cell;
    }

    // ---------------------------------------------------------------
    // LÍNEA SEPARADORA (línea real dibujada, no guiones de texto)
    // ---------------------------------------------------------------
    private void agregarLineaSeparadora(Document doc) throws DocumentException {
        PdfPTable linea = new PdfPTable(1);
        linea.setWidthPercentage(100);
        linea.setSpacingBefore(3f);
        linea.setSpacingAfter(3f);

        PdfPCell celda = new PdfPCell();
        celda.setFixedHeight(0.75f);
        celda.setBackgroundColor(COLOR_LINEA);
        celda.setBorder(Rectangle.NO_BORDER);
        linea.addCell(celda);

        doc.add(linea);
    }

    // ---------------------------------------------------------------
    // FOOTER
    // ---------------------------------------------------------------
    private void agregarFooter(Document doc) throws DocumentException {
        Paragraph pFooter = new Paragraph("\nRepresentación impresa de la\nBOLETA DE VENTA ELECTRÓNICA", FONT_FOOTER);
        pFooter.setAlignment(Element.ALIGN_CENTER);
        pFooter.setSpacingBefore(8f);
        doc.add(pFooter);
    }
}