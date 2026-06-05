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

// controlador de clases, horarios e inscripciones
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

    // ─── GET ───────────────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        transferirFlashMessages(req);

        // detectar si es la ruta /calendar
        String uri = req.getRequestURI();
        if (uri.endsWith("/calendar")) {
            mostrarCalendario(req, resp);
            return;
        }

        String action = getAction(req);

        switch (action) {

            // formulario de nueva clase
            case "new":
                mostrarFormularioClase(req, resp, null);
                break;

            // formulario de edición de clase
            case "edit":
                mostrarFormularioClase(req, resp, param(req, "id"));
                break;

            // gestión de horarios de una clase
            case "horarios":
                mostrarGestionHorarios(req, resp);
                break;

            // lista de inscritos de una clase
            case "inscritos":
                mostrarInscritos(req, resp);
                break;

            // busqueda ajax de clientes
            case "buscarClientesAjax":
                buscarClientesAjax(req, resp);
                break;

            // lista de todas las clases
            default:
                mostrarListaClases(req, resp);
        }
    }

    // ─── POST ──────────────────────────────────────────────────

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = getAction(req);

        switch (action) {

            // crear o actualizar clase
            case "saveClase":
                guardarClase(req, resp);
                break;

            // cambiar estado vigente/suspendida
            case "toggleEstado":
                toggleEstadoClase(req, resp);
                break;

            // agregar horario a una clase
            case "saveHorario":
                guardarHorario(req, resp);
                break;

            // eliminar un horario específico
            case "deleteHorario":
                eliminarHorario(req, resp);
                break;

            // inscribir cliente en clase
            case "inscribir":
                inscribirCliente(req, resp);
                break;

            // cancelar inscripción de cliente
            case "cancelarInscripcion":
                cancelarInscripcion(req, resp);
                break;

            default:
                redirigirA("/schedules", req, resp);
        }
    }

    // ─── lista de clases ───────────────────────────────────────

    // carga todas las clases con sus horarios programados
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

    // ─── formulario de clase ───────────────────────────────────

    // muestra el formulario para crear (claseId=null) o editar (claseId!=null)
    private void mostrarFormularioClase(HttpServletRequest req,
                                         HttpServletResponse resp,
                                         String claseId)
            throws ServletException, IOException {

        if (!esAdmin(req)) {
            forbidden(resp);
            return;
        }

        try {
            // solo entrenadores pueden dictar clases
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

    // ─── gestión de horarios ───────────────────────────────────

    // lista los horarios de una clase y muestra el formulario para agregar
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

    // ─── lista de inscritos ────────────────────────────────────

    // muestra los clientes inscritos en una clase y el formulario para inscribir
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

            String clienteBusqueda = param(req, "clienteBusqueda");
            List<Cliente> clientesList;
            if (clienteBusqueda != null && !clienteBusqueda.trim().isEmpty()) {
                clientesList = clienteDAO.search(clienteBusqueda);
            } else {
                clientesList = clienteDAO.findAll();
            }

            req.setAttribute("clase",         clase);
            req.setAttribute("inscritos",      inscritos);
            req.setAttribute("cuposOcupados",  cupos[0]);
            req.setAttribute("cuposTotal",     cupos[1]);
            req.setAttribute("cuposLibres",    cupos[1] - cupos[0]);
            req.setAttribute("clientes",       clientesList);

            irA(ViewRoutes.SCHEDULES_INDEX + "?inscritos=true", req, resp);

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al cargar inscritos de clase: " + claseId, e);
            mensajeError(req, "Error al cargar los inscritos.");
            redirigirA("/schedules", req, resp);
        }
    }

    // ─── búsqueda ajax de clientes ─────────────────────────────

    private void buscarClientesAjax(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        String query = param(req, "q");
        try {
            List<Cliente> clientes;
            if (query != null && !query.trim().isEmpty()) {
                clientes = clienteDAO.search(query);
            } else {
                clientes = clienteDAO.findAll();
            }

            resp.setContentType("text/html;charset=UTF-8");
            StringBuilder sb = new StringBuilder();
            sb.append("<option value=\"\">— Buscar cliente —</option>");
            for (Cliente cli : clientes) {
                sb.append("<option value=\"").append(cli.getId()).append("\">");
                sb.append(cli.getApellido()).append(", ").append(cli.getNombre());
                sb.append(" — ");
                if (cli.getTipoDocumento() != null) {
                    sb.append(cli.getTipoDocumento().getAbreviado()).append(":");
                }
                sb.append(cli.getNumeroDocumento());
                sb.append("</option>");
            }
            resp.getWriter().write(sb.toString());
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error en buscarClientesAjax", e);
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
    }

    // ─── calendario semanal ────────────────────────────────────

    // carga todos los horarios para la vista de calendario
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

    // ─── guardar clase ─────────────────────────────────────────

    // crea o actualiza una clase según si llega id o no 
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

        // validar campos obligatorios
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

        // validar que la capacidad sea un entero positivo
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

            // verificar que entrenador y tipo existen en BD
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

    // ─── toggle estado clase ───────────────────────────────────

    // alterna el estado de una clase entre vigente y suspendida
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

    // ─── guardar horario ───────────────────────────────────────

    // agrega un horario a una clase
    // dia_semana: 1=Lunes … 7=Domingo | hora_inicio/fin: formato HH:mm
    private void guardarHorario(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        if (!esAdmin(req)) { forbidden(resp); return; }

        String claseId      = param(req, "claseId");
        String diaSemanaStr = param(req, "diaSemana");
        String horaIniStr   = param(req, "horaInicio");
        String horaFinStr   = param(req, "horaFin");

        // validar que todos los campos lleguen
        if (claseId == null || diaSemanaStr == null
                || horaIniStr == null || horaFinStr == null) {
            mensajeError(req, "Todos los campos del horario son obligatorios.");
            redirigirA("/schedules?action=horarios&id=" + claseId, req, resp);
            return;
        }

        // validar que el día esté en el rango permitido por la BD
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

        // parsear horas y validar que fin sea posterior a inicio
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

            // Validar que no haya choque o superposición de horarios para la misma clase
            List<Horario> horariosExistentes = horarioDAO.findByClaseId(claseId);
            for (Horario h : horariosExistentes) {
                if (h.getDiaSemana() == diaSemana) {
                    // Condición de superposición: InicioA < FinB && InicioB < FinA
                    if (horaInicio.isBefore(h.getHoraFin()) && h.getHoraInicio().isBefore(horaFin)) {
                        mensajeError(req, "Ya existe un horario programado (" + h.getRangoHorario() + ") que coincide o se superpone para este día.");
                        redirigirA("/schedules?action=horarios&id=" + claseId, req, resp);
                        return;
                    }
                }
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

    // ─── eliminar horario ──────────────────────────────────────

    // elimina un único horario por su PK — no afecta a los demás de la clase
    // corrección: antes usaba deleteByClaseId() que borraba todos los horarios
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
            // deleteById borra solo ese horario
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

    // ─── inscribir cliente ─────────────────────────────────────

    // delega la lógica de cupo, duplicados y estado a InscripcionService
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

    // ─── cancelar inscripción ──────────────────────────────────

    // cancela la inscripción de un cliente en una clase
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

    // ─── helpers privados ──────────────────────────────────────

    // recarga el formulario de clase mostrando el error recibido
    private void volverAlFormularioClase(HttpServletRequest req,
                                          HttpServletResponse resp,
                                          boolean esNuevo,
                                          String id,
                                          String errorMsg)
            throws ServletException, IOException {

        // formError: exclusivo para errores inline — el navbar no lo renderiza
        req.setAttribute("formError",    errorMsg);
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