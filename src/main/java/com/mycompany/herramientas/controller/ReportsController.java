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
 *   Cada bloque de datos es independiente. Si un DAO falla, se registra
 *   el WARNING y se continúa con el resto de los widgets.
 *
 * ← CORRECCIÓN 4 (Corrección menor del análisis):
 *   En reporteMembresias(), se reemplazó el hack de:
 *     contratoDAO.findProximosAVencer(36500)
 *   por la llamada correcta y semánticamente clara:
 *     contratoDAO.findAllActivos()
 *   El "truco" de los 36500 días (~100 años) era confuso y dependía de
 *   un detalle de implementación interna del SQL de findProximosAVencer.
 *   findAllActivos() hace exactamente lo que su nombre indica, con un
 *   query dedicado limpio en ContratoDAO.
 *
 * @author MaxFit
 */
@WebServlet("/reports")
public class ReportsController extends AbstractController {

    private static final Logger LOGGER =
            Logger.getLogger(ReportsController.class.getName());

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

    // ─── Reporte de resumen general (default) ─────────────────────────────────

    private void reporteResumen(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        cargarKpisGlobales(req);

        try {
            List<Contrato> proximos = contratoDAO.findProximosAVencer(7);
            req.setAttribute("proximosVencer",      proximos);
            req.setAttribute("countProximosVencer", proximos.size());
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al cargar próximos vencimientos", e);
            req.setAttribute("proximosVencer",      Collections.emptyList());
            req.setAttribute("countProximosVencer", 0);
        }

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

    private void reporteContratos(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

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

        req.setAttribute("pctActivos",
                total > 0 ? (activos    * 100 / total) : 0);
        req.setAttribute("pctVencidos",
                total > 0 ? (vencidos   * 100 / total) : 0);
        req.setAttribute("pctCancelados",
                total > 0 ? (cancelados * 100 / total) : 0);

        try {
            BigDecimal ingresos = contratoDAO.getIngresosMesActual();
            req.setAttribute("ingresosMes", ingresos);
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al calcular ingresos del mes", e);
            req.setAttribute("ingresosMes", BigDecimal.ZERO);
        }

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

    private void reporteAsistencia(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        try {
            req.setAttribute("atendidosHoy", asistenciaDAO.countHoy());
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al contar asistencias hoy", e);
            req.setAttribute("atendidosHoy", 0);
        }

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

        req.setAttribute("vistaActiva",    "asistencia");
        req.setAttribute("maxAsistencias", MAX_ASISTENCIAS_REPORTE);
        req.setAttribute("fechaReporte",   LocalDate.now().toString());
        irA(ViewRoutes.REPORTS_INDEX, req, resp);
    }

    // ─── Reporte de membresías ────────────────────────────────────────────────

    /**
     * Catálogo de planes de membresía con métricas.
     *
     * ← CORRECCIÓN 4:
     *   Antes: contratoDAO.findProximosAVencer(36500)
     *     → hack que abusaba del filtro de vencimiento para obtener "todos los activos"
     *     → confuso, dependía de un detalle interno del SQL de findProximosAVencer
     *     → semánticamente incorrecto (findProximosAVencer es para alertas, no para reportes)
     *
     *   Ahora: contratoDAO.findAllActivos()
     *     → query dedicado, limpio y correctamente nombrado en ContratoDAO
     *     → SELECT ... WHERE estado = 'activo' ORDER BY fecha_fin ASC
     *     → sin trucos ni números mágicos
     */
    private void reporteMembresias(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        try {
            List<Membresia> membresias = membresiaDAO.findAll();
            req.setAttribute("membresias",  membresias);
            req.setAttribute("totalPlanes", membresias.size());
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al cargar membresías", e);
            req.setAttribute("membresias",  Collections.emptyList());
            req.setAttribute("totalPlanes", 0);
        }

        // ← CORRECCIÓN 4: findAllActivos() en lugar del hack de 36500 días
        try {
            List<Contrato> contratosActivos = contratoDAO.findAllActivos();
            req.setAttribute("contratosActivos",      contratosActivos);
            req.setAttribute("totalContratosActivos", contratosActivos.size());
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al cargar contratos activos", e);
            req.setAttribute("contratosActivos",      Collections.emptyList());
            req.setAttribute("totalContratosActivos", 0);
        }

        req.setAttribute("vistaActiva",  "membresias");
        req.setAttribute("fechaReporte", LocalDate.now().toString());
        irA(ViewRoutes.REPORTS_INDEX, req, resp);
    }

    // ─── Helpers privados ─────────────────────────────────────────────────────

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
            BigDecimal ingresos = contratoDAO.getIngresosMesActual();
            req.setAttribute("ingresosMes", ingresos);
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "KPI fallido: ingresosMes", e);
            req.setAttribute("ingresosMes", BigDecimal.ZERO);
        }
    }

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