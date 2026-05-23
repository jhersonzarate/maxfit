package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.dao.*;
import com.mycompany.herramientas.model.*;
import com.mycompany.herramientas.view.ViewRoutes;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Dashboard del Administrador (ROL-ADMIN).
 *
 * GET /inicio → panel principal con KPIs, alertas y actividad reciente.
 *
 * Widgets que muestra:
 *   - KPI: Total de clientes registrados
 *   - KPI: Contratos activos en este momento
 *   - KPI: Check-ins registrados hoy
 *   - KPI: Total de empleados
 *   - KPI: Clases vigentes
 *   - KPI: Ingresos del mes en curso (sum de monto_pagado)
 *   - Lista: Contratos próximos a vencer (próximos 7 días)
 *   - Lista: Asistencias recientes (últimas 5)
 *   - Lista: Clases programadas para hoy
 *
 * Acceso: ROL-ADMIN únicamente (garantizado por RoleFilter → /inicio).
 *
 * Patrón de carga:
 *   Cada DAO hace su propia consulta. Si alguno falla se registra el error
 *   y se continúa con los demás (degradado parcial), en lugar de lanzar
 *   un 500 completo al admin por un único widget fallido.
 *
 * @author MaxFit
 */
@WebServlet("/inicio")
public class InicioController extends AbstractController {

    private static final Logger LOGGER =
            Logger.getLogger(InicioController.class.getName());

    // Contratos que vencen en los próximos N días se muestran como alerta
    private static final int DIAS_ALERTA_VENCIMIENTO = 7;
    // Cantidad de asistencias recientes en el widget de actividad
    private static final int MAX_ASISTENCIAS_RECIENTES = 5;

    private final ClienteDAO    clienteDAO    = new ClienteDAO();
    private final ContratoDAO   contratoDAO   = new ContratoDAO();
    private final EmpleadoDAO   empleadoDAO   = new EmpleadoDAO();
    private final ClaseDAO      claseDAO      = new ClaseDAO();
    private final AsistenciaDAO asistenciaDAO = new AsistenciaDAO();
    private final HorarioDAO    horarioDAO    = new HorarioDAO();

    // ─── GET /inicio ──────────────────────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        transferirFlashMessages(req);
        cargarKpis(req);
        cargarWidgets(req);
        irA(ViewRoutes.INICIO_ADMIN, req, resp);
    }

    // ─── KPIs ────────────────────────────────────────────────────────────────

    /**
     * Carga los 6 KPIs del panel superior.
     * Cada uno es independiente: si uno falla, los demás siguen cargando.
     */
    private void cargarKpis(HttpServletRequest req) {

        // Total de clientes registrados
        try {
            req.setAttribute("totalClientes", clienteDAO.count());
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al contar clientes", e);
            req.setAttribute("totalClientes", "-");
        }

        // Contratos activos ahora mismo
        try {
            req.setAttribute("contratosActivos", contratoDAO.countActivos());
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al contar contratos activos", e);
            req.setAttribute("contratosActivos", "-");
        }

        // Check-ins de hoy (estado = 'asistio')
        try {
            req.setAttribute("atendidosHoy", asistenciaDAO.countHoy());
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al contar check-ins hoy", e);
            req.setAttribute("atendidosHoy", "-");
        }

        // Total de empleados (la tabla no tiene estado → todos están activos)
        try {
            req.setAttribute("totalEmpleados", empleadoDAO.count());
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al contar empleados", e);
            req.setAttribute("totalEmpleados", "-");
        }

        // Clases con estado 'vigente'
        try {
            req.setAttribute("clasesVigentes", claseDAO.countVigentes());
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al contar clases vigentes", e);
            req.setAttribute("clasesVigentes", "-");
        }

        // Ingresos del mes en curso (suma de monto_pagado)
        // Usamos BigDecimal para evitar errores de punto flotante (nunca double para dinero)
        try {
            BigDecimal ingresos = contratoDAO.getIngresosMesActual();
            req.setAttribute("ingresosMes", ingresos);
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al calcular ingresos del mes", e);
            req.setAttribute("ingresosMes", BigDecimal.ZERO);
        }
    }

    // ─── Widgets ─────────────────────────────────────────────────────────────

    /**
     * Carga los widgets de listas: próximos vencimientos, asistencias recientes,
     * y clases programadas para hoy.
     */
    private void cargarWidgets(HttpServletRequest req) {

        // ── Contratos próximos a vencer (alertas) ───────────────────────────
        try {
            List<Contrato> proximos =
                    contratoDAO.findProximosAVencer(DIAS_ALERTA_VENCIMIENTO);
            req.setAttribute("proximosVencer", proximos);
            req.setAttribute("countProximosVencer", proximos.size());
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al cargar próximos vencimientos", e);
            req.setAttribute("proximosVencer", java.util.Collections.emptyList());
            req.setAttribute("countProximosVencer", 0);
        }

        // ── Últimas asistencias del día (actividad reciente) ─────────────────
        try {
            List<Asistencia> recientes = asistenciaDAO.findRecientes(MAX_ASISTENCIAS_RECIENTES);
            req.setAttribute("asistenciasRecientes", recientes);
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al cargar asistencias recientes", e);
            req.setAttribute("asistenciasRecientes", java.util.Collections.emptyList());
        }

        // ── Clases programadas para hoy (por día de semana ISO: 1=Lunes … 7=Domingo) ──
        try {
            int diaSemanaHoy = LocalDate.now().getDayOfWeek().getValue();
            List<Horario> clasesHoy = horarioDAO.findByDia(diaSemanaHoy);
            req.setAttribute("clasesHoy", clasesHoy);
            req.setAttribute("countClasesHoy", clasesHoy.size());
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al cargar clases de hoy", e);
            req.setAttribute("clasesHoy", java.util.Collections.emptyList());
            req.setAttribute("countClasesHoy", 0);
        }

        // Fecha de hoy para mostrar en el panel
        req.setAttribute("fechaHoy", LocalDate.now().toString());
        req.setAttribute("diasAlertaVencimiento", DIAS_ALERTA_VENCIMIENTO);
    }
}