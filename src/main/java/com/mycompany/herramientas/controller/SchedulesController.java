package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.config.AppConfig;
import com.mycompany.herramientas.dao.*;
import com.mycompany.herramientas.model.*;
import com.mycompany.herramientas.service.InscripcionService;
import com.mycompany.herramientas.service.ContratoService;
import com.mycompany.herramientas.view.ViewRoutes;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.time.LocalTime;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Controlador de Clases, Horarios e Inscripciones (RF-08, RF-09, RF-10, RF-11).
 *
 * Rutas y acciones para /schedules:
 *   GET  /schedules                       → lista de clases vigentes con horarios
 *   GET  /schedules?action=new            → formulario de nueva clase (Admin)
 *   GET  /schedules?action=edit&id=CLA-X  → formulario de edición (Admin)
 *   GET  /schedules?action=horarios&id=CLA-X → gestión de horarios de una clase
 *   GET  /schedules?action=inscritos&id=CLA-X → lista de inscritos de una clase
 *   POST /schedules?action=saveClase      → crear o actualizar clase (Admin)
 *   POST /schedules?action=toggleEstado&id=CLA-X → vigente ↔ suspendida (Admin)
 *   POST /schedules?action=saveHorario    → agregar horario a una clase (Admin)
 *   POST /schedules?action=deleteHorario&id=HOR-X → eliminar UN horario (Admin)
 *   POST /schedules?action=inscribir      → inscribir cliente en clase (Admin/Recep)
 *   POST /schedules?action=cancelarInscripcion&id=INS-X → cancelar inscripción
 *
 * Rutas para /calendar:
 *   GET  /calendar → vista de calendario semanal con todos los horarios
 *
 * Acceso:
 *   Admin   → CRUD completo (clases, horarios, inscripciones)
 *   Recep   → ver + gestionar inscripciones
 *   Trainer → solo lectura (ver sus clases en /instructor)
 *
 * CORRECCIÓN (bug anterior):
 *   eliminarHorario() llamaba a horarioDAO.deleteByClaseId(claseId)
 *   que borraba TODOS los horarios de la clase. Ahora usa
 *   horarioDAO.deleteById(horarioId) para borrar solo el horario indicado.
 *
 * @author MaxFit
 */
@WebServlet({"/schedules", "/calendar"})
public class SchedulesController extends AbstractController {

    private static final Logger LOGGER =
            Logger.getLogger(SchedulesController.class.getName());

    private final ClaseDAO           claseDAO           = new ClaseDAO();
    private final HorarioDAO         horarioDAO         = new HorarioDAO();
    private final InscripcionDAO     inscripcionDAO     = new InscripcionDAO();
    private final CatalogoDAO        catalogoDAO        = new CatalogoDAO();
    private final EmpleadoDAO        empleadoDAO        = new EmpleadoDAO();
    private final ClienteDAO         clienteDAO         = new ClienteDAO();
    private final InscripcionService inscripcionService = new InscripcionService();

    // ─── GET ──────────────────────────────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        transferirFlashMessages(req);

        // Detectar si es la ruta /calendar
        String uri = req.getRequestURI();
        if (uri.endsWith("/calendar")) {
            mostrarCalendario(req, resp);
            return;
        }

        String action = getAction(req);

        switch (action) {
            case "new":
                mostrarFormularioClase(req, resp, null);
                break;
            case "edit":
                mostrarFormularioClase(req, resp, param(req, "id"));
                break;
            case "horarios":
                mostrarGestionHorarios(req, resp);
                break;
            case "inscritos":
                mostrarInscritos(req, resp);
                break;
            default:
                mostrarListaClases(req, resp);
        }
    }

    // ─── POST ─────────────────────────────────────────────────────────────────

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = getAction(req);

        switch (action) {
            case "saveClase":
                guardarClase(req, resp);
                break;
            case "toggleEstado":
                toggleEstadoClase(req, resp);
                break;
            case "saveHorario":
                guardarHorario(req, resp);
                break;
            case "deleteHorario":
                eliminarHorario(req, resp);
                break;
            case "inscribir":
                inscribirCliente(req, resp);
                break;
            case "cancelarInscripcion":
                cancelarInscripcion(req, resp);
                break;
            default:
                redirigirA("/schedules", req, resp);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // GET: vistas
    // ═══════════════════════════════════════════════════════════════════════

    /** Lista de todas las clases con sus horarios programados. */
    private void mostrarListaClases(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        try {
            List<Clase> clases = claseDAO.findAll();
            req.setAttribute("clases",      clases);
            req.setAttribute("totalClases", clases.size());
            irA(ViewRoutes.SCHEDULES_INDEX, req, resp);
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al listar clases", e);
            req.setAttribute("errorMsg", "Error al cargar las clases.");
            irA(ViewRoutes.SCHEDULES_INDEX, req, resp);
        }
    }

    /** Formulario de nueva clase (claseId=null) o edición (claseId!=null). */
    private void mostrarFormularioClase(HttpServletRequest req,
                                         HttpServletResponse resp,
                                         String claseId)
            throws ServletException, IOException {

        if (!esAdmin(req)) {
            forbidden(resp);
            return;
        }

        try {
            // Solo entrenadores (CARGO-TRAINER) pueden dictar clases
            req.setAttribute("entrenadores", empleadoDAO.findByCargo(AppConfig.CARGO_TRAINER));
            req.setAttribute("tiposClase",   catalogoDAO.findAllTipoClases());

            if (claseId != null) {
                Clase clase = claseDAO.findById(claseId);
                if (clase == null) {
                    mensajeError(req, "No se encontró la clase.");
                    redirigirA("/schedules", req, resp);
                    return;
                }
                req.setAttribute("clase",       clase);
                req.setAttribute("modoEdicion", true);
            } else {
                req.setAttribute("clase",       new Clase());
                req.setAttribute("modoEdicion", false);
            }

            irA(ViewRoutes.SCHEDULES_INDEX + "?form=true", req, resp);

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al cargar formulario de clase", e);
            mensajeError(req, "Error al cargar el formulario.");
            redirigirA("/schedules", req, resp);
        }
    }

    /** Gestión de horarios de una clase: lista sus horarios + formulario para agregar. */
    private void mostrarGestionHorarios(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!esAdmin(req)) {
            forbidden(resp);
            return;
        }

        String claseId = param(req, "id");
        if (claseId == null) {
            mensajeError(req, "ID de clase no especificado.");
            redirigirA("/schedules", req, resp);
            return;
        }

        try {
            Clase clase = claseDAO.findById(claseId);
            if (clase == null) {
                mensajeError(req, "No se encontró la clase.");
                redirigirA("/schedules", req, resp);
                return;
            }

            List<Horario> horarios = horarioDAO.findByClaseId(claseId);
            req.setAttribute("clase",    clase);
            req.setAttribute("horarios", horarios);
            irA(ViewRoutes.SCHEDULES_INDEX + "?horarios=true", req, resp);

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al cargar horarios de clase: " + claseId, e);
            mensajeError(req, "Error al cargar los horarios.");
            redirigirA("/schedules", req, resp);
        }
    }

    /** Lista de clientes inscritos en una clase + formulario para inscribir. */
    private void mostrarInscritos(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String claseId = param(req, "id");
        if (claseId == null) {
            mensajeError(req, "ID de clase no especificado.");
            redirigirA("/schedules", req, resp);
            return;
        }

        try {
            Clase clase = claseDAO.findById(claseId);
            if (clase == null) {
                mensajeError(req, "No se encontró la clase.");
                redirigirA("/schedules", req, resp);
                return;
            }

            List<InscripcionClase> inscritos = inscripcionDAO.findByClaseId(claseId);
            int[] cupos = inscripcionService.cuposInfo(claseId);

            req.setAttribute("clase",         clase);
            req.setAttribute("inscritos",      inscritos);
            req.setAttribute("cuposOcupados",  cupos[0]);
            req.setAttribute("cuposTotal",     cupos[1]);
            req.setAttribute("cuposLibres",    cupos[1] - cupos[0]);
            req.setAttribute("clientes",       clienteDAO.findAll());

            irA(ViewRoutes.SCHEDULES_INDEX + "?inscritos=true", req, resp);

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al cargar inscritos de clase: " + claseId, e);
            mensajeError(req, "Error al cargar los inscritos.");
            redirigirA("/schedules", req, resp);
        }
    }

    /** Vista de calendario semanal con todos los horarios programados. */
    private void mostrarCalendario(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        try {
            List<Horario> horarios = horarioDAO.findAll();
            req.setAttribute("horarios", horarios);
            irA(ViewRoutes.SCHEDULES_CALENDAR, req, resp);
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al cargar calendario", e);
            req.setAttribute("errorMsg", "Error al cargar el calendario.");
            irA(ViewRoutes.SCHEDULES_CALENDAR, req, resp);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // POST: operaciones
    // ═══════════════════════════════════════════════════════════════════════

    /** Crea o actualiza una clase (RF-08). Solo Admin. */
    private void guardarClase(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!esAdmin(req)) { forbidden(resp); return; }

        String id           = param(req, "id");
        String nombreClase  = param(req, "nombreClase");
        String idEmpleado   = param(req, "idEmpleado");
        String idTipoClase  = param(req, "idTipoClase");
        String capacidadStr = param(req, "capacidadMaxima");
        String descripcion  = param(req, "descripcion");

        boolean esNuevo = (id == null || id.isBlank());

        if (nombreClase == null) {
            volverAlFormularioClase(req, resp, esNuevo, id,
                    "El nombre de la clase es obligatorio.");
            return;
        }
        if (idEmpleado == null || idTipoClase == null) {
            volverAlFormularioClase(req, resp, esNuevo, id,
                    "Debe seleccionar el entrenador y tipo de clase.");
            return;
        }

        int capacidad;
        try {
            capacidad = Integer.parseInt(capacidadStr != null ? capacidadStr.trim() : "");
            if (capacidad <= 0) {
                volverAlFormularioClase(req, resp, esNuevo, id,
                        "La capacidad máxima debe ser mayor a cero.");
                return;
            }
        } catch (NumberFormatException e) {
            volverAlFormularioClase(req, resp, esNuevo, id,
                    "La capacidad máxima debe ser un número entero válido.");
            return;
        }

        try {
            Empleado empleado   = empleadoDAO.findById(idEmpleado);
            TipoClase tipoClase = catalogoDAO.findTipoClaseById(idTipoClase);

            if (empleado == null || tipoClase == null) {
                volverAlFormularioClase(req, resp, esNuevo, id,
                        "El entrenador o tipo de clase seleccionado no existe.");
                return;
            }

            Clase clase = new Clase();
            clase.setId(esNuevo ? IdGenerator.parClase() : id);
            clase.setNombreClase(nombreClase.trim());
            clase.setEmpleado(empleado);
            clase.setTipoClase(tipoClase);
            clase.setCapacidadMaxima(capacidad);
            clase.setDescripcion(descripcion);
            clase.setEstado(AppConfig.CLASE_VIGENTE);

            claseDAO.save(clase);
            String accion = esNuevo ? "registrada" : "actualizada";
            LOGGER.info("Clase " + accion + ": " + clase.getId()
                    + " | " + clase.getNombreClase());
            mensajeExito(req, "Clase \"" + clase.getNombreClase()
                    + "\" " + accion + " correctamente.");
            redirigirA("/schedules", req, resp);

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al guardar clase", e);
            volverAlFormularioClase(req, resp, esNuevo, id,
                    "Error al guardar la clase. Intenta nuevamente.");
        }
    }

    /** Alterna el estado de una clase: vigente ↔ suspendida (RF-08). Solo Admin. */
    private void toggleEstadoClase(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        if (!esAdmin(req)) { forbidden(resp); return; }

        String id = param(req, "id");
        if (id == null) {
            mensajeError(req, "ID de clase no especificado.");
            redirigirA("/schedules", req, resp);
            return;
        }

        try {
            Clase clase = claseDAO.findById(id);
            if (clase == null) {
                mensajeError(req, "No se encontró la clase.");
                redirigirA("/schedules", req, resp);
                return;
            }

            String nuevoEstado = clase.isVigente()
                    ? AppConfig.CLASE_SUSPENDIDA
                    : AppConfig.CLASE_VIGENTE;
            clase.setEstado(nuevoEstado);
            claseDAO.save(clase);

            LOGGER.info("Estado de clase cambiado: " + id + " → " + nuevoEstado);
            mensajeExito(req, "Clase \"" + clase.getNombreClase() + "\" "
                    + (AppConfig.CLASE_VIGENTE.equals(nuevoEstado) ? "activada" : "suspendida")
                    + " correctamente.");

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al cambiar estado de clase: " + id, e);
            mensajeError(req, "Error al cambiar el estado de la clase.");
        }

        redirigirA("/schedules", req, resp);
    }

    /**
     * Agrega un horario a una clase (RF-09). Solo Admin.
     * dia_semana: TINYINT 1-7 (1=Lunes … 7=Domingo) según el CHECK de la BD.
     * hora_inicio y hora_fin: formato HH:mm del input type="time".
     */
    private void guardarHorario(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        if (!esAdmin(req)) { forbidden(resp); return; }

        String claseId      = param(req, "claseId");
        String diaSemanaStr = param(req, "diaSemana");
        String horaIniStr   = param(req, "horaInicio");
        String horaFinStr   = param(req, "horaFin");

        if (claseId == null || diaSemanaStr == null
                || horaIniStr == null || horaFinStr == null) {
            mensajeError(req, "Todos los campos del horario son obligatorios.");
            redirigirA("/schedules?action=horarios&id=" + claseId, req, resp);
            return;
        }

        int diaSemana;
        try {
            diaSemana = Integer.parseInt(diaSemanaStr.trim());
            if (diaSemana < 1 || diaSemana > 7) {
                throw new NumberFormatException("Fuera de rango 1-7");
            }
        } catch (NumberFormatException e) {
            mensajeError(req, "El día de la semana debe ser un número entre 1 (Lunes) y 7 (Domingo).");
            redirigirA("/schedules?action=horarios&id=" + claseId, req, resp);
            return;
        }

        LocalTime horaInicio, horaFin;
        try {
            horaInicio = LocalTime.parse(horaIniStr.trim());
            horaFin    = LocalTime.parse(horaFinStr.trim());
        } catch (DateTimeParseException e) {
            mensajeError(req, "Formato de hora inválido. Usa HH:mm (ej: 07:00).");
            redirigirA("/schedules?action=horarios&id=" + claseId, req, resp);
            return;
        }

        if (!horaFin.isAfter(horaInicio)) {
            mensajeError(req, "La hora de fin debe ser posterior a la hora de inicio.");
            redirigirA("/schedules?action=horarios&id=" + claseId, req, resp);
            return;
        }

        try {
            Clase clase = claseDAO.findById(claseId);
            if (clase == null) {
                mensajeError(req, "No se encontró la clase.");
                redirigirA("/schedules", req, resp);
                return;
            }

            Horario horario = new Horario();
            horario.setId(IdGenerator.parHorario());
            horario.setClase(clase);
            horario.setDiaSemana(diaSemana);
            horario.setHoraInicio(horaInicio);
            horario.setHoraFin(horaFin);
            horario.setEstado(AppConfig.HORARIO_PROGRAMADO);

            horarioDAO.save(horario);
            LOGGER.info("Horario agregado: " + horario.getId()
                    + " | clase: " + claseId
                    + " | " + horario.getNombreDia()
                    + " " + horario.getRangoHorario());
            mensajeExito(req, "Horario del " + horario.getNombreDia()
                    + " " + horario.getRangoHorario() + " agregado correctamente.");

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al guardar horario", e);
            mensajeError(req, "Error al guardar el horario. Intenta nuevamente.");
        }

        redirigirA("/schedules?action=horarios&id=" + claseId, req, resp);
    }

    /**
     * Elimina UN horario específico de una clase (RF-09). Solo Admin.
     *
     * CORRECCIÓN del bug anterior:
     *   Antes llamaba a horarioDAO.deleteByClaseId(claseId) que borraba
     *   TODOS los horarios de la clase — comportamiento incorrecto.
     *   Ahora usa horarioDAO.deleteById(horarioId) que borra solo
     *   el horario indicado por su PK. HorarioDAO fue actualizado
     *   para exponer este método.
     *
     * Parámetros esperados del formulario:
     *   id      → ID del horario a eliminar (ej: HOR-2026-0001)
     *   claseId → ID de la clase (para redirigir a su página de horarios)
     */
    private void eliminarHorario(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        if (!esAdmin(req)) { forbidden(resp); return; }

        String horarioId = param(req, "id");
        String claseId   = param(req, "claseId");

        if (horarioId == null) {
            mensajeError(req, "ID de horario no especificado.");
            redirigirA("/schedules", req, resp);
            return;
        }

        try {
            // deleteById borra solo ese horario — no afecta a los demás
            boolean eliminado = horarioDAO.deleteById(horarioId);
            if (eliminado) {
                LOGGER.info("Horario eliminado: " + horarioId
                        + " | clase: " + (claseId != null ? claseId : "N/A"));
                mensajeExito(req, "Horario eliminado correctamente.");
            } else {
                mensajeError(req, "No se encontró el horario con ID: " + horarioId);
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al eliminar horario: " + horarioId, e);
            mensajeError(req, "Error al eliminar el horario. Intenta nuevamente.");
        }

        redirigirA("/schedules?action=horarios&id=" + (claseId != null ? claseId : ""),
                req, resp);
    }

    /**
     * Inscribe un cliente en una clase (RF-11).
     * Delega toda la lógica (cupo, duplicados, clase vigente) a InscripcionService.
     */
    private void inscribirCliente(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        String clienteId = param(req, "clienteId");
        String claseId   = param(req, "claseId");

        if (clienteId == null || claseId == null) {
            mensajeError(req, "Selecciona un cliente y una clase para inscribir.");
            redirigirA("/schedules?action=inscritos&id=" + claseId, req, resp);
            return;
        }

        InscripcionService.Resultado resultado =
                inscripcionService.inscribir(clienteId, claseId);

        if (resultado.isExitoso()) {
            mensajeExito(req, resultado.getMensaje());
        } else {
            mensajeError(req, resultado.getMensaje());
        }

        redirigirA("/schedules?action=inscritos&id=" + claseId, req, resp);
    }

    /** Cancela la inscripción de un cliente en una clase. */
    private void cancelarInscripcion(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        String inscripcionId = param(req, "id");
        String claseId       = param(req, "claseId");

        if (inscripcionId == null) {
            mensajeError(req, "ID de inscripción no especificado.");
            redirigirA("/schedules", req, resp);
            return;
        }

        ContratoService.Resultado resultado =
                inscripcionService.cancelar(inscripcionId);

        if (resultado.isExitoso()) {
            mensajeExito(req, resultado.getMensaje());
        } else {
            mensajeError(req, resultado.getMensaje());
        }

        redirigirA("/schedules?action=inscritos&id=" + (claseId != null ? claseId : ""),
                req, resp);
    }

    // ─── Helpers privados ─────────────────────────────────────────────────────

    private void volverAlFormularioClase(HttpServletRequest req,
                                          HttpServletResponse resp,
                                          boolean esNuevo,
                                          String id,
                                          String errorMsg)
            throws ServletException, IOException {

        req.setAttribute("errorMsg",    errorMsg);
        req.setAttribute("modoEdicion", !esNuevo);

        try {
            req.setAttribute("entrenadores", empleadoDAO.findByCargo(AppConfig.CARGO_TRAINER));
            req.setAttribute("tiposClase",   catalogoDAO.findAllTipoClases());
            if (!esNuevo && id != null) {
                Clase original = claseDAO.findById(id);
                req.setAttribute("clase", original != null ? original : new Clase());
            } else {
                req.setAttribute("clase", new Clase());
            }
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al recargar formulario de clase", e);
        }

        irA(ViewRoutes.SCHEDULES_INDEX + "?form=true", req, resp);
    }
}