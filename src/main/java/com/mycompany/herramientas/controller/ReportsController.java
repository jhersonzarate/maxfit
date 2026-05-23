package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.config.AppConfig;
import com.mycompany.herramientas.dao.AsistenciaDAO;
import com.mycompany.herramientas.dao.ClaseDAO;
import com.mycompany.herramientas.dao.ClienteDAO;
import com.mycompany.herramientas.dao.ContratoDAO;
import com.mycompany.herramientas.dao.EmpleadoDAO;
import com.mycompany.herramientas.dao.MembresiaDAO;
import com.mycompany.herramientas.model.Asistencia;
import com.mycompany.herramientas.model.Contrato;
import com.mycompany.herramientas.model.Membresia;
import com.mycompany.herramientas.view.ViewRoutes;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.Collections;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Controlador de Reportes del Administrador.
 *
 * Rutas y acciones:
 *   GET /reports                    → resumen general (KPIs globales + alertas)
 *   GET /reports?action=contratos   → reporte detallado de contratos por estado
 *   GET /reports?action=asistencia  → reporte de asistencia (historial reciente)
 *   GET /reports?action=membresias  → reporte de planes de membresía
 *
 * Acceso: ROL-ADMIN únicamente (RoleFilter → /reports).
 *
 * Diseño de carga (degradado parcial):
 *   Cada bloque de datos es independiente. Si un DAO falla (ej: timeout),
 *   se registra el WARNING y se continúa con el resto de los widgets.
 *   Esto evita que un único error tire toda la página de reportes.
 *   El mismo patrón que usa InicioController (Admin dashboard).
 *
 * Nota sobre ingresos:
 *   Los ingresos se calculan sobre monto_pagado de contratos del mes actual.
 *   BigDecimal en todo momento — NUNCA double para dinero.
 *   ContratoDAO.getIngresosMesActual() usa ISNULL(SUM(...), 0) en SQL Server
 *   para retornar 0 en lugar de NULL si no hay contratos el mes actual.
 *
 * Nota sobre countByEstado:
 *   ContratoDAO.countByEstado(String estado) fue añadido en esta iteración.
 *   Usa un único query parametrizado (SELECT COUNT(*) WHERE estado = ?)
 *   para cada estado, evitando cargar todos los contratos en memoria
 *   solo para contar.
 *
 * @author MaxFit
 */
@WebServlet("/reports")
public class ReportsController extends AbstractController {

    private static final Logger LOGGER =
            Logger.getLogger(ReportsController.class.getName());

    // Número máximo de filas en el historial de asistencia del reporte
    private static final int MAX_ASISTENCIAS_REPORTE = 50;

    private final ContratoDAO   contratoDAO   = new ContratoDAO();
    private final ClienteDAO    clienteDAO    = new ClienteDAO();
    private final AsistenciaDAO asistenciaDAO = new AsistenciaDAO();
    private final EmpleadoDAO   empleadoDAO   = new EmpleadoDAO();
    private final ClaseDAO      claseDAO      = new ClaseDAO();
    private final MembresiaDAO  membresiaDAO  = new MembresiaDAO();

    // ─── GET ──────────────────────────────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        transferirFlashMessages(req);

        // Actualizar contratos vencidos silenciosamente antes de mostrar estadísticas.
        // Sin job scheduler, se hace en cada carga (igual que InicioController).
        actualizarVencidosSilencioso();

        String action = getAction(req);

        switch (action) {
            case "contratos":
                reporteContratos(req, resp);
                break;
            case "asistencia":
                reporteAsistencia(req, resp);
                break;
            case "membresias":
                reporteMembresias(req, resp);
                break;
            default:
                reporteResumen(req, resp);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Vistas de reporte
    // ═══════════════════════════════════════════════════════════════════════

    // ─── Reporte de resumen general (default) ─────────────────────────────────

    /**
     * Vista principal de reportes.
     * Muestra los 6 KPIs globales del sistema más las alertas de
     * contratos próximos a vencer y el historial de asistencias recientes.
     * Misma filosofía que InicioController pero orientada a análisis,
     * no a operación del día a día.
     */
    private void reporteResumen(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // ── KPIs globales (degradado parcial — si uno falla, los demás siguen) ─
        cargarKpisGlobales(req);

        // ── Próximos a vencer (7 días) como alerta de gestión ─────────────────
        try {
            List<Contrato> proximos = contratoDAO.findProximosAVencer(7);
            req.setAttribute("proximosVencer",      proximos);
            req.setAttribute("countProximosVencer", proximos.size());
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al cargar próximos vencimientos", e);
            req.setAttribute("proximosVencer",      Collections.emptyList());
            req.setAttribute("countProximosVencer", 0);
        }

        // ── Asistencias recientes para actividad del día ───────────────────────
        try {
            List<Asistencia> recientes = asistenciaDAO.findRecientes(10);
            req.setAttribute("asistenciasRecientes", recientes);
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al cargar asistencias recientes", e);
            req.setAttribute("asistenciasRecientes", Collections.emptyList());
        }

        req.setAttribute("vistaActiva",  "resumen");
        req.setAttribute("fechaReporte", LocalDate.now().toString());
        irA(ViewRoutes.REPORTS_INDEX, req, resp);
    }

    // ─── Reporte de contratos ─────────────────────────────────────────────────

    /**
     * Desglose completo de contratos por estado (activo / vencido / cancelado).
     * Usa ContratoDAO.countByEstado() para obtener conteos individuales
     * con queries directas a BD (no carga la lista completa para contar).
     * También muestra la lista de todos los contratos para análisis detallado.
     */
    private void reporteContratos(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // ── Conteo por estado ─────────────────────────────────────────────────
        int activos    = 0;
        int vencidos   = 0;
        int cancelados = 0;

        try {
            activos    = contratoDAO.countByEstado(AppConfig.CONTRATO_ACTIVO);
            vencidos   = contratoDAO.countByEstado(AppConfig.CONTRATO_VENCIDO);
            cancelados = contratoDAO.countByEstado(AppConfig.CONTRATO_CANCELADO);
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al contar contratos por estado", e);
        }

        int total = activos + vencidos + cancelados;

        req.setAttribute("contratosActivos",    activos);
        req.setAttribute("contratosVencidos",   vencidos);
        req.setAttribute("contratosCancelados", cancelados);
        req.setAttribute("contratosTotal",      total);

        // ── Porcentajes para barras de progreso en el JSP ─────────────────────
        // Se pasan como enteros (0-100) para usar directamente en style="width:X%"
        req.setAttribute("pctActivos",
                total > 0 ? (activos    * 100 / total) : 0);
        req.setAttribute("pctVencidos",
                total > 0 ? (vencidos   * 100 / total) : 0);
        req.setAttribute("pctCancelados",
                total > 0 ? (cancelados * 100 / total) : 0);

        // ── Ingresos del mes (BigDecimal — nunca double para dinero) ──────────
        try {
            BigDecimal ingresos = contratoDAO.getIngresosMesActual();
            req.setAttribute("ingresosMes", ingresos);
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al calcular ingresos del mes", e);
            req.setAttribute("ingresosMes", BigDecimal.ZERO);
        }

        // ── Próximos a vencer para sección de alertas ─────────────────────────
        try {
            List<Contrato> proximos = contratoDAO.findProximosAVencer(7);
            req.setAttribute("proximosVencer",      proximos);
            req.setAttribute("countProximosVencer", proximos.size());
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al cargar próximos vencimientos", e);
            req.setAttribute("proximosVencer",      Collections.emptyList());
            req.setAttribute("countProximosVencer", 0);
        }

        req.setAttribute("vistaActiva",  "contratos");
        req.setAttribute("fechaReporte", LocalDate.now().toString());
        irA(ViewRoutes.REPORTS_INDEX, req, resp);
    }

    // ─── Reporte de asistencia ────────────────────────────────────────────────

    /**
     * Historial de asistencia para análisis del administrador.
     * Muestra los últimos MAX_ASISTENCIAS_REPORTE registros con toda la
     * información del cliente y membresía (navegando por el contrato).
     *
     * Para filtrar por cliente o rango de fechas el admin puede usar
     * directamente /attendance?action=hist que tiene esa funcionalidad.
     */
    private void reporteAsistencia(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // ── Contador del día (KPI principal del reporte de asistencia) ─────────
        try {
            req.setAttribute("atendidosHoy", asistenciaDAO.countHoy());
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al contar asistencias hoy", e);
            req.setAttribute("atendidosHoy", 0);
        }

        // ── Historial reciente (últimas N asistencias) ────────────────────────
        try {
            List<Asistencia> historial =
                    asistenciaDAO.findRecientes(MAX_ASISTENCIAS_REPORTE);
            req.setAttribute("historialAsistencia", historial);
            req.setAttribute("totalHistorial",      historial.size());
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al cargar historial de asistencia", e);
            req.setAttribute("historialAsistencia", Collections.emptyList());
            req.setAttribute("totalHistorial",      0);
        }

        req.setAttribute("vistaActiva",          "asistencia");
        req.setAttribute("maxAsistencias",       MAX_ASISTENCIAS_REPORTE);
        req.setAttribute("fechaReporte",         LocalDate.now().toString());
        irA(ViewRoutes.REPORTS_INDEX, req, resp);
    }

    // ─── Reporte de membresías ────────────────────────────────────────────────

    /**
     * Catálogo de planes de membresía con métricas.
     * Muestra todos los planes disponibles y su precio/duración.
     * Para ver cuántos contratos tiene cada plan, el JSP puede
     * cruzar la lista de contratos con membresía (groupBy en Java/JSTL).
     *
     * La lista de todos los contratos activos se pasa al JSP para que
     * pueda calcular popularidad de cada membresía sin queries adicionales.
     */
    private void reporteMembresias(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // ── Todos los planes de membresía ─────────────────────────────────────
        try {
            List<Membresia> membresias = membresiaDAO.findAll();
            req.setAttribute("membresias",  membresias);
            req.setAttribute("totalPlanes", membresias.size());
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al cargar membresías", e);
            req.setAttribute("membresias",  Collections.emptyList());
            req.setAttribute("totalPlanes", 0);
        }

        // ── Contratos activos para cruzar con membresías (JSP agrupa) ─────────
        // Se pasan solo los activos para que el JSP calcule qué membresía
        // tiene más contratos vigentes en este momento.
        try {
            List<Contrato> contratosActivos = contratoDAO.findProximosAVencer(36500);
            // Truco: findProximosAVencer con 36500 días (~100 años) equivale
            // a todos los contratos activos, porque solo filtra activos con
            // fecha_fin entre HOY y HOY+N días. Usar findAll y filtrar en Java
            // sería igual de válido pero cargaría también vencidos y cancelados.
            // Alternativa más limpia: añadir findAllActivos() al DAO si el sistema crece.
            req.setAttribute("contratosActivos",          contratosActivos);
            req.setAttribute("totalContratosActivos",     contratosActivos.size());
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al cargar contratos activos", e);
            req.setAttribute("contratosActivos",      Collections.emptyList());
            req.setAttribute("totalContratosActivos", 0);
        }

        req.setAttribute("vistaActiva",  "membresias");
        req.setAttribute("fechaReporte", LocalDate.now().toString());
        irA(ViewRoutes.REPORTS_INDEX, req, resp);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Helpers privados
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Carga los 6 KPIs globales del sistema.
     * Patrón de degradado parcial: cada KPI en su propio try-catch.
     * Si uno falla, los otros siguen cargando normalmente.
     * Se muestra "-" en lugar de un número cuando hay error (no "0",
     * que podría confundirse con un valor real).
     */
    private void cargarKpisGlobales(HttpServletRequest req) {

        try {
            req.setAttribute("totalClientes", clienteDAO.count());
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "KPI fallido: totalClientes", e);
            req.setAttribute("totalClientes", "-");
        }

        try {
            req.setAttribute("contratosActivos", contratoDAO.countActivos());
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "KPI fallido: contratosActivos", e);
            req.setAttribute("contratosActivos", "-");
        }

        try {
            req.setAttribute("atendidosHoy", asistenciaDAO.countHoy());
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "KPI fallido: atendidosHoy", e);
            req.setAttribute("atendidosHoy", "-");
        }

        try {
            req.setAttribute("totalEmpleados", empleadoDAO.count());
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "KPI fallido: totalEmpleados", e);
            req.setAttribute("totalEmpleados", "-");
        }

        try {
            req.setAttribute("clasesVigentes", claseDAO.countVigentes());
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "KPI fallido: clasesVigentes", e);
            req.setAttribute("clasesVigentes", "-");
        }

        try {
            // BigDecimal obligatorio — NUNCA double para dinero
            BigDecimal ingresos = contratoDAO.getIngresosMesActual();
            req.setAttribute("ingresosMes", ingresos);
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "KPI fallido: ingresosMes", e);
            req.setAttribute("ingresosMes", BigDecimal.ZERO);
        }
    }

    /**
     * Marca contratos vencidos sin lanzar excepción al controlador.
     * Se llama al inicio de cada GET para mantener el estado de la BD
     * consistente con la fecha actual, sin necesidad de un scheduler.
     */
    private void actualizarVencidosSilencioso() {
        try {
            int n = contratoDAO.marcarVencidos(
                    LocalDate.now(),
                    AppConfig.CONTRATO_ACTIVO,
                    AppConfig.CONTRATO_VENCIDO
            );
            if (n > 0) {
                LOGGER.info("Reports: contratos marcados como vencidos = " + n);
            }
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING,
                    "Reports: no se pudieron actualizar contratos vencidos", e);
        }
    }
}