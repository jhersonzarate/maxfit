package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.dao.*;
import com.mycompany.herramientas.model.*;
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
 * Dashboard del Instructor (ROL-TRAINER).
 *
 * Rutas y acciones:
 *   GET /instructor              → mis clases + clases de hoy + alumnos
 *   GET /instructor?action=clase&id=CLA-XXX → detalle de una clase (inscritos)
 *
 * Widgets que muestra:
 *   - KPI: Total de clases que dicta
 *   - KPI: Clases programadas para hoy
 *   - KPI: Total de alumnos inscritos en sus clases
 *   - Lista: Mis clases (Clase[] con inscritos y horarios)
 *   - Lista: Clases de hoy (Horario[] del día actual)
 *
 * Acceso: ROL-TRAINER únicamente (garantizado por RoleFilter → /instructor).
 *
 * Identificación del instructor:
 *   Se obtiene el id_empleado del usuario en sesión a través del UsuarioDAO.
 *   Si el usuario no tiene empleado vinculado (caso imposible en producción
 *   normal, pero defensivamente manejado), se muestra panel vacío con mensaje.
 *
 * @author MaxFit
 */
@WebServlet("/instructor")
public class InstructorController extends AbstractController {

    private static final Logger LOGGER =
            Logger.getLogger(InstructorController.class.getName());

    private final ClaseDAO       claseDAO       = new ClaseDAO();
    private final HorarioDAO     horarioDAO     = new HorarioDAO();
    private final InscripcionDAO inscripcionDAO = new InscripcionDAO();
    private final UsuarioDAO     usuarioDAO     = new UsuarioDAO();

    // ─── GET /instructor ──────────────────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        transferirFlashMessages(req);

        // Obtener el empleado vinculado al usuario en sesión
        String empleadoId = resolverEmpleadoId(req);

        if (empleadoId == null) {
            // El usuario instructor no tiene empleado vinculado — caso anómalo
            req.setAttribute("errorMsg",
                    "Tu cuenta no tiene un empleado vinculado. "
                    + "Contacta al administrador.");
            req.setAttribute("misClases", Collections.emptyList());
            irA(ViewRoutes.DASHBOARD_INSTR, req, resp);
            return;
        }

        String action = getAction(req);

        switch (action) {
            case "clase":
                mostrarDetalleClase(req, resp, empleadoId);
                break;
            default:
                mostrarPanelInstructor(req, resp, empleadoId);
        }
    }

    // ─── GET: panel principal del instructor ──────────────────────────────────

    private void mostrarPanelInstructor(HttpServletRequest req,
                                         HttpServletResponse resp,
                                         String empleadoId)
            throws ServletException, IOException {

        // ── Mis clases asignadas (por id_empleado) ───────────────────────────
        List<Clase> misClases;
        try {
            misClases = claseDAO.findByEmpleadoId(empleadoId);
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al cargar clases del instructor: " + empleadoId, e);
            misClases = Collections.emptyList();
            req.setAttribute("errorMsg", "Error al cargar tus clases. Intenta nuevamente.");
        }

        req.setAttribute("misClases", misClases);

        // ── KPI: total de alumnos inscritos en mis clases ────────────────────
        int totalAlumnos = 0;
        for (Clase c : misClases) {
            try {
                totalAlumnos += inscripcionDAO.countInscritos(c.getId());
            } catch (SQLException e) {
                LOGGER.log(Level.WARNING, "Error al contar inscritos en clase: " + c.getId(), e);
            }
        }
        req.setAttribute("totalAlumnos",     totalAlumnos);
        req.setAttribute("totalMisClases",   misClases.size());

        // ── Clases de hoy (horarios del día actual) ──────────────────────────
        try {
            int diaSemana = LocalDate.now().getDayOfWeek().getValue();
            // Filtramos solo los horarios de las clases que dicta este instructor
            List<Horario> todosHoy = horarioDAO.findByDia(diaSemana);
            List<Horario> misClasesHoy = new java.util.ArrayList<>();
            for (Horario h : todosHoy) {
                for (Clase c : misClases) {
                    if (h.getClase() != null && h.getClase().getId().equals(c.getId())) {
                        misClasesHoy.add(h);
                        break;
                    }
                }
            }
            req.setAttribute("misClasesHoy",       misClasesHoy);
            req.setAttribute("countMisClasesHoy",  misClasesHoy.size());
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al cargar horarios de hoy", e);
            req.setAttribute("misClasesHoy",      Collections.emptyList());
            req.setAttribute("countMisClasesHoy", 0);
        }

        req.setAttribute("fechaHoy", LocalDate.now().toString());
        irA(ViewRoutes.DASHBOARD_INSTR, req, resp);
    }

    // ─── GET: detalle de una clase (lista de alumnos inscritos) ──────────────

    /**
     * Muestra los alumnos inscritos en una clase específica.
     * Solo accesible para el instructor dueño de esa clase (verificación de propiedad).
     */
    private void mostrarDetalleClase(HttpServletRequest req,
                                      HttpServletResponse resp,
                                      String empleadoId)
            throws ServletException, IOException {

        String claseId = param(req, "id");
        if (claseId == null) {
            mensajeError(req, "ID de clase no especificado.");
            redirigirA("/instructor", req, resp);
            return;
        }

        try {
            // Verificar que la clase pertenece a este instructor
            Clase clase = claseDAO.findById(claseId);
            if (clase == null) {
                mensajeError(req, "No se encontró la clase.");
                redirigirA("/instructor", req, resp);
                return;
            }

            // Seguridad: solo el instructor dueño puede ver el detalle
            if (!empleadoId.equals(clase.getEmpleado().getId())) {
                forbidden(resp);
                return;
            }

            // Cargar alumnos inscritos en esa clase
            List<InscripcionClase> inscritos = inscripcionDAO.findByClaseId(claseId);
            List<Horario> horarios = horarioDAO.findProgramadosByClaseId(claseId);

            req.setAttribute("claseDetalle",  clase);
            req.setAttribute("inscritos",     inscritos);
            req.setAttribute("horarios",      horarios);
            req.setAttribute("totalInscritos", inscritos.size());

            irA(ViewRoutes.DASHBOARD_INSTR, req, resp);

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al cargar detalle de clase: " + claseId, e);
            mensajeError(req, "Error al cargar el detalle de la clase.");
            redirigirA("/instructor", req, resp);
        }
    }

    // ─── Helper privado ───────────────────────────────────────────────────────

    /**
     * Obtiene el id_empleado vinculado al usuario en sesión.
     * Devuelve null si el usuario no tiene empleado vinculado.
     */
    private String resolverEmpleadoId(HttpServletRequest req) {
        try {
            String userId = getSessionUserId(req);
            if (userId == null) return null;
            Usuario usuario = usuarioDAO.findById(userId);
            if (usuario != null && usuario.getEmpleado() != null) {
                return usuario.getEmpleado().getId();
            }
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al resolver empleado de sesión", e);
        }
        return null;
    }
}