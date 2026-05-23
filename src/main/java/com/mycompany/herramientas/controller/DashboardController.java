package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.dao.AsistenciaDAO;
import com.mycompany.herramientas.dao.ContratoDAO;
import com.mycompany.herramientas.dao.HorarioDAO;
import com.mycompany.herramientas.service.ContratoService;
import com.mycompany.herramientas.view.ViewRoutes;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Controlador del panel del Recepcionista.
 *
 * GET /dashboard → carga widgets operativos del día y hace forward a dashboard.jsp
 *
 * Widgets:
 *   - Clientes atendidos hoy (asistencias con estado 'asistio' del día)
 *   - Contratos activos
 *   - Clases programadas para hoy (según el día de la semana actual)
 *   - Últimas 5 asistencias registradas (actividad reciente)
 *   - Contratos próximos a vencer (próximos 7 días — alerta para el recepcionista)
 */
public class DashboardController extends AbstractController {

    private static final Logger LOGGER = Logger.getLogger(DashboardController.class.getName());

    private final AsistenciaDAO   asistenciaDAO  = new AsistenciaDAO();
    private final ContratoDAO     contratoDAO    = new ContratoDAO();
    private final HorarioDAO      horarioDAO     = new HorarioDAO();
    private final ContratoService contratoService = new ContratoService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // Actualizar vencidos al cargar
        contratoService.actualizarVencidos();

        // Día de la semana actual en formato TINYINT de la BD (1=Lunes…7=Domingo)
        // Java DayOfWeek: MONDAY=1, SUNDAY=7 — coincide exactamente con el CHECK de BD
        int diaSemanaHoy = LocalDate.now().getDayOfWeek().getValue();

        try {
            req.setAttribute("atendidosHoy",    asistenciaDAO.countHoy());
            req.setAttribute("contratosActivos", contratoDAO.countActivos());
            req.setAttribute("clasesHoy",        horarioDAO.countPorDia(diaSemanaHoy));
            req.setAttribute("actividadReciente",asistenciaDAO.findRecientes(5));
            req.setAttribute("proximosVencer",   contratoService.obtenerProximosAVencer(7));

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al cargar datos del dashboard", e);
            req.setAttribute("atendidosHoy",     0);
            req.setAttribute("contratosActivos",  0);
            req.setAttribute("clasesHoy",         0);
            setError(req, "Error al cargar algunos datos. Intenta refrescar la página.");
        }

        req.setAttribute("paginaTitulo", "Panel de Recepción — MaxFit");
        forward(req, resp, ViewRoutes.DASHBOARD_RECEP);
    }
}