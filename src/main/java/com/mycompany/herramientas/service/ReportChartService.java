package com.mycompany.herramientas.service;

import org.jfree.chart.ChartFactory;
import org.jfree.chart.ChartUtils;
import org.jfree.chart.JFreeChart;
import org.jfree.chart.axis.CategoryAxis;
import org.jfree.chart.axis.CategoryLabelPositions;
import org.jfree.chart.axis.NumberAxis;
import org.jfree.chart.labels.ItemLabelAnchor;
import org.jfree.chart.labels.ItemLabelPosition;
import org.jfree.chart.labels.PieSectionLabelGenerator;
import org.jfree.chart.labels.StandardCategoryItemLabelGenerator;
import org.jfree.chart.labels.StandardPieSectionLabelGenerator;
import org.jfree.chart.plot.CategoryPlot;
import org.jfree.chart.plot.PlotOrientation;
import org.jfree.chart.plot.RingPlot;
import org.jfree.chart.renderer.category.BarRenderer;
import org.jfree.chart.renderer.category.StandardBarPainter;
import org.jfree.chart.title.LegendTitle;
import org.jfree.chart.ui.RectangleEdge;
import org.jfree.chart.ui.TextAnchor;
import org.jfree.data.category.CategoryDataset;
import org.jfree.data.category.DefaultCategoryDataset;
import org.jfree.data.general.DefaultPieDataset;

import java.awt.Color;
import java.awt.Font;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.text.DecimalFormat;
import java.util.LinkedHashMap;
import java.util.Map;

// Genera gráficos como imágenes PNG para insertarlos en los PDF de reportes.
// Separado de la vista web a propósito: la vista usa Chart.js (interactivo,
// del lado del cliente); el PDF usa estas imágenes estáticas generadas en el
// servidor con JFreeChart, porque un PDF no puede contener un <canvas> vivo.
public class ReportChartService {

    // paleta alineada al donut web (Chart.js) y a las tarjetas KPI del PDF
    private static final Color COLOR_POSITIVO = new Color(34, 197, 94);   // verde — "lo que entró/sigue" (Activos o Nuevos, según el periodo)
    private static final Color COLOR_VENCIDOS = new Color(239, 68, 68);   // rojo — igual que el donut web
    private static final Color COLOR_INGRESOS = new Color(0x25, 0x63, 0xEB); // azul — igual que la tarjeta KPI "Ingresos"
    private static final Color COLOR_TEXTO    = new Color(0x11, 0x18, 0x27); // --clr-text
    private static final Color COLOR_BORDE    = new Color(0xE5, 0xE7, 0xEB); // --clr-border
    private static final Color COLOR_GRID     = new Color(0xF0, 0xF1, 0xF3); // --clr-border-light

    // gráfico de dona genérico de 2 categorías, DEL PERIODO exportado (no "hoy").
    // Las etiquetas se reciben como parámetro porque lo que se compara cambia según
    // el tipo de reporte (ver ReportPdfService.agregarGraficos): mensual compara
    // Activos vs Vencidos; anual compara Nuevos vs Vencidos (dos totales del año
    // igual de "acumulados", en vez de mezclar una foto puntual con un acumulado).
    // "Cancelados" no se incluye: no hay fecha_cancelacion en la BD, no se puede
    // filtrar por periodo (ver ContratoDAO.countActivosAlCierre para el detalle).
    public byte[] generarGraficoEstadoContratos(String labelPrincipal, int valorPrincipal,
                                                  String labelVencidos, int valorVencidos,
                                                  int ancho,
                                                  int alto) throws IOException {

        DefaultPieDataset<String> dataset = new DefaultPieDataset<>();
        dataset.setValue(labelPrincipal, valorPrincipal);
        dataset.setValue(labelVencidos, valorVencidos);

        JFreeChart chart = ChartFactory.createRingChart(
                null, dataset, true, true, false
        );

        RingPlot plot = (RingPlot) chart.getPlot();
        plot.setSectionPaint(labelPrincipal, COLOR_POSITIVO);
        plot.setSectionPaint(labelVencidos, COLOR_VENCIDOS);
        plot.setBackgroundPaint(Color.WHITE);
        plot.setOutlineVisible(false);
        plot.setSectionDepth(0.65);
        plot.setSectionOutlinesVisible(false);
        plot.setSeparatorsVisible(false);
        plot.setShadowPaint(null);
        plot.setInteriorGap(0.02);

        // solo el porcentaje sobre cada porción — el nombre ya va en la leyenda
        PieSectionLabelGenerator generadorEtiquetas = new StandardPieSectionLabelGenerator(
                "{2}",
                new DecimalFormat("0"),
                new DecimalFormat("0.0%")
        );
        plot.setLabelGenerator(generadorEtiquetas);
        plot.setLabelFont(new Font("SansSerif", Font.BOLD, 13));
        plot.setLabelPaint(Color.WHITE);
        plot.setLabelBackgroundPaint(null);
        plot.setLabelOutlinePaint(null);
        plot.setLabelShadowPaint(null);
        plot.setLabelLinksVisible(false);
        plot.setSimpleLabels(true);

        // leyenda moderna a la derecha, con la cantidad junto al nombre
        // (ej. "Activos (10)") para que se entienda de un vistazo qué dato es
        plot.setLegendLabelGenerator(new StandardPieSectionLabelGenerator(
                "{0} ({1})",
                new DecimalFormat("0"),
                new DecimalFormat("0.0%")
        ));
        LegendTitle leyenda = chart.getLegend();
        if (leyenda != null) {
            leyenda.setPosition(RectangleEdge.RIGHT);
            leyenda.setItemFont(new Font("SansSerif", Font.PLAIN, 12));
            leyenda.setBackgroundPaint(Color.WHITE);
        }

        chart.setBackgroundPaint(Color.WHITE);
        chart.setBorderVisible(false);

        return aPng(chart, ancho, alto);
    }

    // gráfico de barras: ingresos de los últimos N meses
    public byte[] generarGraficoIngresosMensuales(LinkedHashMap<String, BigDecimal> datosPorMes,
                                                    int ancho,
                                                    int alto) throws IOException {

        DefaultCategoryDataset dataset = new DefaultCategoryDataset();

        for (Map.Entry<String, BigDecimal> entry : datosPorMes.entrySet()) {
            dataset.addValue(entry.getValue(), "Ingresos (S/.)", entry.getKey());
        }

        JFreeChart chart = ChartFactory.createBarChart(
                null, null, null, dataset,
                PlotOrientation.VERTICAL, false, true, false
        );

        CategoryPlot plot = chart.getCategoryPlot();
        plot.setBackgroundPaint(Color.WHITE);
        plot.setOutlineVisible(false);
        plot.setRangeGridlinePaint(COLOR_GRID);
        plot.setDomainGridlinesVisible(false);

        BarRenderer renderer = (BarRenderer) plot.getRenderer();
        renderer.setSeriesPaint(0, COLOR_INGRESOS);
        renderer.setShadowVisible(false);
        renderer.setBarPainter(new StandardBarPainter());
        renderer.setMaximumBarWidth(0.12);

        // monto encima de cada barra — más legible que solo el eje Y. Si el mes no tuvo
        // ingresos no se dibuja la etiqueta "S/.0" (queda vacío, no aporta información
        // y ensucia el gráfico cuando hay varios meses en cero, como en el reporte anual)
        renderer.setDefaultItemLabelGenerator(new StandardCategoryItemLabelGenerator(
                "S/.{2}", new DecimalFormat("#,##0")
        ) {
            @Override
            public String generateLabel(CategoryDataset dataset, int row, int column) {
                Number valor = dataset.getValue(row, column);
                if (valor == null || valor.doubleValue() == 0) {
                    return null;
                }
                return super.generateLabel(dataset, row, column);
            }
        });
        renderer.setDefaultItemLabelsVisible(true);
        renderer.setDefaultItemLabelFont(new Font("SansSerif", Font.BOLD, 11));
        renderer.setDefaultItemLabelPaint(COLOR_TEXTO);
        renderer.setDefaultPositiveItemLabelPosition(new ItemLabelPosition(
                ItemLabelAnchor.OUTSIDE12, TextAnchor.BOTTOM_CENTER
        ));

        CategoryAxis ejeCategorias = plot.getDomainAxis();
        ejeCategorias.setTickLabelPaint(COLOR_TEXTO);
        ejeCategorias.setAxisLinePaint(COLOR_BORDE);

        // con muchas categorías (reporte ANUAL = 12 meses) las etiquetas horizontales
        // no caben y JFreeChart las reemplaza por "..."; se rotan e achican para que
        // los 12 quepan completos. En MENSUAL (6 categorías) se quedan horizontales.
        if (dataset.getColumnCount() > 6) {
            ejeCategorias.setCategoryLabelPositions(CategoryLabelPositions.createUpRotationLabelPositions(Math.PI / 5));
            ejeCategorias.setTickLabelFont(new Font("SansSerif", Font.PLAIN, 9));
        } else {
            ejeCategorias.setTickLabelFont(new Font("SansSerif", Font.PLAIN, 11));
        }

        NumberAxis ejeValores = (NumberAxis) plot.getRangeAxis();
        ejeValores.setTickLabelPaint(COLOR_TEXTO);
        ejeValores.setTickLabelFont(new Font("SansSerif", Font.PLAIN, 10));
        ejeValores.setAxisLinePaint(COLOR_BORDE);
        // margen extra arriba para que las etiquetas de valor no se corten
        ejeValores.setUpperMargin(0.18);

        chart.setBackgroundPaint(Color.WHITE);
        chart.setBorderVisible(false);

        return aPng(chart, ancho, alto);
    }

    private byte[] aPng(JFreeChart chart, int ancho, int alto) throws IOException {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ChartUtils.writeChartAsPNG(out, chart, ancho, alto);
        return out.toByteArray();
    }
}
