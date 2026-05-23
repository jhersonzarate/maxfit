package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.dao.*;
import com.mycompany.herramientas.model.*;
import com.mycompany.herramientas.service.ContratoService;
import com.mycompany.herramientas.view.ViewRoutes;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.Collections;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Dashboard del Recepcionista (ROL-RECEP).
 *
 * GET /dashboard → panel de operaciones del día.
 *
 * Widgets que muestra:
 *   - KPI: Check-ins de hoy (atendidos hoy)
 *   - KPI: Contratos activos
 *   - KPI: Clases programadas para hoy
 *   - Lista: Últimas asistencias del día (máx. 10) para el widget de actividad
 *   - Lista: Contratos próximos a vencer (7 días) como alerta
 *   - Formulario rápido de check-in (delegado a AttendanceController)
 *
 * Acceso: ROL-RECEP únicamente (garantizado por RoleFilter → /dashboard).
 *
 * Nota de diseño:
 *   El check-in no se procesa aquí — el formulario rápido hace POST a
 *   /attendance?action=checkin, que ya tiene toda la lógica en AttendanceController.
 *   DashboardController solo muestra datos de lectura.
 *
 * @author MaxFit
 */
@WebServlet("/dashboard")
public class DashboardController extends AbstractController {

    private static final Logger LOGGER =
            Logger.getLogger(DashboardController.class.getName());

    private static final int DIAS_ALERTA_VENCIMIENTO = 7;
    private static final int MAX_ASISTENCIAS_HOY     = 10;

    private final AsistenciaDAO   asistenciaDAO   = new AsistenciaDAO();
    private final ContratoDAO     contratoDAO     = new ContratoDAO();
    private final HorarioDAO      horarioDAO      = new HorarioDAO();
    private final ContratoService contratoService = new ContratoService();

    // ─── GET /dashboard ───────────────────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        transferirFlashMessages(req);

        // Actualizar contratos vencidos antes de mostrar contadores
        // (sin job scheduler, se hace en cada carga del dashboard)
        contratoService.actualizarVencidos();

        cargarKpisRecep(req);
        cargarWidgetsRecep(req);

        irA(ViewRoutes.DASHBOARD_RECEP, req, resp);
    }

    // ─── KPIs de recepción ───────────────────────────────────────────────────

    private void cargarKpisRecep(HttpServletRequest req) {

        // Check-ins registrados hoy
        try {
            req.setAttribute("atendidosHoy", asistenciaDAO.countHoy());
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al contar check-ins hoy", e);
            req.setAttribute("atendidosHoy", 0);
        }

        // Contratos activos (para saber cuántos clientes tiene membresía vigente)
        try {
            req.setAttribute("contratosActivos", contratoDAO.countActivos());
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al contar contratos activos", e);
            req.setAttribute("contratosActivos", 0);
        }

        // Clases de hoy
        try {
            int dia = LocalDate.now().getDayOfWeek().getValue();
            req.setAttribute("countClasesHoy", horarioDAO.countByDia(dia));
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al contar clases de hoy", e);
            req.setAttribute("countClasesHoy", 0);
        }
    }

    // ─── Widgets ─────────────────────────────────────────────────────────────

    private void cargarWidgetsRecep(HttpServletRequest req) {

        // Últimas N asistencias del día para el feed de actividad en tiempo real
        try {
            List<Asistencia> recientes =
                    asistenciaDAO.findRecientes(MAX_ASISTENCIAS_HOY);
            req.setAttribute("asistenciasRecientes", recientes);
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al cargar asistencias recientes", e);
            req.setAttribute("asistenciasRecientes", Collections.emptyList());
        }

        // Alertas: contratos que vencen esta semana
        // El recepcionista puede contactar al cliente para renovar
        try {
            List<Contrato> proximos =
                    contratoDAO.findProximosAVencer(DIAS_ALERTA_VENCIMIENTO);
            req.setAttribute("proximosVencer", proximos);
            req.setAttribute("countProximosVencer", proximos.size());
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al cargar próximos vencimientos", e);
            req.setAttribute("proximosVencer", Collections.emptyList());
            req.setAttribute("countProximosVencer", 0);
        }

        // Clases programadas para hoy (para orientar al cliente que llega)
        try {
            int dia = LocalDate.now().getDayOfWeek().getValue();
            List<Horario> clasesHoy = horarioDAO.findByDia(dia);
            req.setAttribute("clasesHoy", clasesHoy);
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al cargar clases de hoy", e);
            req.setAttribute("clasesHoy", Collections.emptyList());
        }

        req.setAttribute("fechaHoy", LocalDate.now().toString());
    }
}