package com.mycompany.herramientas.service;

import org.jfree.chart.ChartFactory;
import org.jfree.chart.ChartUtils;
import org.jfree.chart.JFreeChart;
import org.jfree.chart.axis.CategoryAxis;
import org.jfree.chart.axis.NumberAxis;
import org.jfree.chart.plot.CategoryPlot;
import org.jfree.chart.plot.PiePlot;
import org.jfree.chart.plot.PlotOrientation;
import org.jfree.chart.renderer.category.BarRenderer;
import org.jfree.chart.renderer.category.StandardBarPainter;
import org.jfree.data.category.DefaultCategoryDataset;
import org.jfree.data.general.DefaultPieDataset;

import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.Map;

// Genera gráficos como imágenes PNG para insertarlos en los PDF de reportes.
// Separado de la vista web a propósito: la vista usa Chart.js (interactivo,
// del lado del cliente); el PDF usa estas imágenes estáticas generadas en el
// servidor con JFreeChart, porque un PDF no puede contener un <canvas> vivo.
public class ReportChartService {

    // paleta alineada a styles.css (MaxFit)
    private static final Color COLOR_ACTIVOS    = new Color(0x16, 0xA3, 0x4A); // --clr-success
    private static final Color COLOR_VENCIDOS   = new Color(0xD9, 0x77, 0x06); // --clr-warning
    private static final Color COLOR_CANCELADOS = new Color(0xE6, 0x30, 0x27); // --clr-red
    private static final Color COLOR_INGRESOS   = new Color(0xE6, 0x30, 0x27); // --clr-red
    private static final Color COLOR_TEXTO      = new Color(0x11, 0x18, 0x27); // --clr-text
    private static final Color COLOR_BORDE      = new Color(0xE5, 0xE7, 0xEB); // --clr-border
    private static final Color COLOR_GRID       = new Color(0xF0, 0xF1, 0xF3); // --clr-border-light

    // gráfico de torta: distribución de contratos por estado
    public byte[] generarGraficoEstadoContratos(int activos,
                                                  int vencidos,
                                                  int cancelados,
                                                  int ancho,
                                                  int alto) throws IOException {

        DefaultPieDataset<String> dataset = new DefaultPieDataset<>();
        dataset.setValue("Activos", activos);
        dataset.setValue("Vencidos", vencidos);
        dataset.setValue("Cancelados", cancelados);

        JFreeChart chart = ChartFactory.createPieChart(
                null, dataset, false, true, false
        );

        PiePlot<String> plot = (PiePlot<String>) chart.getPlot();
        plot.setSectionPaint("Activos", COLOR_ACTIVOS);
        plot.setSectionPaint("Vencidos", COLOR_VENCIDOS);
        plot.setSectionPaint("Cancelados", COLOR_CANCELADOS);
        plot.setBackgroundPaint(Color.WHITE);
        plot.setOutlineVisible(false);
        plot.setLabelGenerator(null);
        plot.setInteriorGap(0.04);
        plot.setShadowPaint(null);

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

        CategoryAxis ejeCategorias = plot.getDomainAxis();
        ejeCategorias.setTickLabelPaint(COLOR_TEXTO);
        ejeCategorias.setAxisLinePaint(COLOR_BORDE);

        NumberAxis ejeValores = (NumberAxis) plot.getRangeAxis();
        ejeValores.setTickLabelPaint(COLOR_TEXTO);
        ejeValores.setAxisLinePaint(COLOR_BORDE);

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
