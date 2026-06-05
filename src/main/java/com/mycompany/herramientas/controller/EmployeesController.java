package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.dao.CatalogoDAO;
import com.mycompany.herramientas.dao.EmpleadoDAO;
import com.mycompany.herramientas.dao.IdGenerator;
import com.mycompany.herramientas.model.Cargo;
import com.mycompany.herramientas.model.Empleado;
import com.mycompany.herramientas.model.TipoDocumento;
import com.mycompany.herramientas.service.DocumentoValidator;
import com.mycompany.herramientas.view.ViewRoutes;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

// gestión de empleados del sistema
@WebServlet("/employees")
public class EmployeesController extends AbstractController {

    private static final Logger LOGGER =
            Logger.getLogger(EmployeesController.class.getName());

    private final EmpleadoDAO empleadoDAO = new EmpleadoDAO();
    private final CatalogoDAO catalogoDAO = new CatalogoDAO();

    // ───────────────── GET /employees ─────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        transferirFlashMessages(req);

        String action = getAction(req);

        switch (action) {
            case "view":
                mostrarDetalle(req, resp);
                break;

            default:
                mostrarLista(req, resp);
        }
    }

    // ───────────────── POST /employees ────────────────

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = getAction(req);

        switch (action) {

            case "save":
                guardarEmpleado(req, resp);
                break;

            case "delete":
                eliminarEmpleado(req, resp);
                break;

            default:
                redirigirA("/employees", req, resp);
        }
    }

    // ───────────────── listado de empleados ───────────

    private void mostrarLista(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        try {

            List<Empleado> empleados = empleadoDAO.findAll();

            req.setAttribute("empleados", empleados);
            req.setAttribute("totalEmpleados", empleados.size());
            req.setAttribute("tiposDocumento", catalogoDAO.findAllTipoDocumentos());
            req.setAttribute("cargos", catalogoDAO.findAllCargos());

            irA(ViewRoutes.EMPLOYEES_INDEX, req, resp);

        } catch (SQLException e) {

            LOGGER.log(Level.SEVERE, "Error al listar empleados", e);

            req.setAttribute("errorMsg", "Error al cargar los empleados.");

            irA(ViewRoutes.EMPLOYEES_INDEX, req, resp);
        }
    }

    // Métodos mostrarFormularioNuevo y mostrarFormularioEdicion eliminados (ahora se usa modal en mostrarLista)

    private void mostrarDetalle(HttpServletRequest req,
                                HttpServletResponse resp)
            throws ServletException, IOException {

        String id = param(req, "id");

        // validar existencia del ID
        if (id == null) {

            mensajeError(req, "ID de empleado no especificado.");

            redirigirA("/employees", req, resp);

            return;
        }

        try {

            Empleado empleado = empleadoDAO.findById(id);

            // validar existencia del empleado
            if (empleado == null) {

                mensajeError(
                        req,
                        "No se encontró el empleado con ID: " + id
                );

                redirigirA("/employees", req, resp);

                return;
            }

            req.setAttribute("empleado", empleado);

            irA(
                    ViewRoutes.EMPLOYEES_INDEX + "?detail=true",
                    req,
                    resp
            );

        } catch (SQLException e) {

            LOGGER.log(
                    Level.SEVERE,
                    "Error al cargar detalle del empleado: " + id,
                    e
            );

            mensajeError(req, "Error al cargar el empleado.");

            redirigirA("/employees", req, resp);
        }
    }

    // ───────────────── guardar empleado ───────────────

    private void guardarEmpleado(HttpServletRequest req,
                                 HttpServletResponse resp)
            throws ServletException, IOException {

        String id        = param(req, "id");
        String nombre    = param(req, "nombre");
        String apellido  = param(req, "apellido");
        String idTipoDoc = param(req, "idTipoDocumento");
        String numeroDoc = param(req, "numeroDocumento");
        String email     = param(req, "email");
        String telefono  = param(req, "telefono");
        String idCargo   = param(req, "idCargo");

        boolean esNuevo = (id == null || id.isBlank());

        // validar campos obligatorios
        if (nombre == null || apellido == null) {
            mensajeError(req, "El nombre y apellido son obligatorios.");
            redirigirA("/employees", req, resp);
            return;
        }

        if (!contieneSoloLetras(nombre)|| !contieneSoloLetras(apellido)) {
            mensajeError(req, "El nombre y apellido solo deben contener letras.");
            redirigirA("/employees", req, resp);
            return;
        }

        if (email == null) {
            mensajeError(req, "El correo electrónico es obligatorio.");
            redirigirA("/employees", req, resp);
            return;
        }

        if (idTipoDoc == null || numeroDoc == null) {
            mensajeError(req, "Debe seleccionar tipo de documento e ingresar el número.");
            redirigirA("/employees", req, resp);
            return;
        }

        if (idCargo == null) {
            mensajeError(req, "Debe seleccionar un cargo.");
            redirigirA("/employees", req, resp);
            return;
        }

        try {
            TipoDocumento tipoDoc = catalogoDAO.findTipoDocumentoById(idTipoDoc);
            if (tipoDoc == null) {
                mensajeError(req, "El tipo de documento seleccionado no es válido.");
                redirigirA("/employees", req, resp);
                return;
            }

            DocumentoValidator.ResultadoValidacion validacion = DocumentoValidator.validar(tipoDoc, numeroDoc);
            if (!validacion.isValido()) {
                mensajeError(req, validacion.getMensaje());
                redirigirA("/employees", req, resp);
                return;
            }

            Cargo cargo = catalogoDAO.findCargoById(idCargo);
            if (cargo == null) {
                mensajeError(req, "El cargo seleccionado no es válido.");
                redirigirA("/employees", req, resp);
                return;
            }

            Empleado empleado = new Empleado();
            empleado.setId(esNuevo ? IdGenerator.parEmpleado() : id);
            empleado.setNombre(nombre.trim());
            empleado.setApellido(apellido.trim());
            empleado.setTipoDocumento(tipoDoc);
            empleado.setNumeroDocumento(numeroDoc.trim());
            empleado.setEmail(email.trim().toLowerCase());
            empleado.setTelefono(telefono);
            empleado.setCargo(cargo);

            empleadoDAO.save(empleado);

            String accion = esNuevo ? "registrado" : "actualizado";
            LOGGER.info("Empleado " + accion + ": " + empleado.getId() + " | " + empleado.getNombreCompleto());
            mensajeExito(req, "Empleado " + empleado.getNombreCompleto() + " " + accion + " correctamente.");
            redirigirA("/employees", req, resp);

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al guardar empleado", e);
            String msg;
            if (e.getMessage() != null && e.getMessage().contains("UNIQUE")) {
                msg = "El número de documento o correo ya está registrado en el sistema.";
            } else {
                msg = "Error al guardar el empleado. Intenta nuevamente.";
            }
            mensajeError(req, msg);
            redirigirA("/employees", req, resp);
        }
    }

    // ───────────────── eliminar empleado ──────────────

    private void eliminarEmpleado(HttpServletRequest req,
                                  HttpServletResponse resp)
            throws IOException {

        String id = param(req, "id");

        // validar existencia del ID
        if (id == null) {

            mensajeError(req, "ID de empleado no especificado.");

            redirigirA("/employees", req, resp);

            return;
        }

        try {

            boolean eliminado = empleadoDAO.delete(id);

            if (eliminado) {

                LOGGER.info("Empleado eliminado: " + id);

                mensajeExito(
                        req,
                        "Empleado eliminado correctamente."
                );

            } else {

                mensajeError(
                        req,
                        "No se encontró el empleado con ID: " + id
                );
            }

        } catch (SQLException e) {

            LOGGER.log(
                    Level.SEVERE,
                    "Error al eliminar empleado: " + id,
                    e
            );

            String msg;

            // validar restricciones por relaciones existentes
            if (e.getMessage() != null
                    && e.getMessage().contains("REFERENCE")) {

                msg = "No se puede eliminar el empleado porque "
                        + "tiene contratos o clases asignadas.";

            } else {

                msg = "Error al eliminar el empleado. "
                        + "Intenta nuevamente.";
            }

            mensajeError(req, msg);
        }

        redirigirA("/employees", req, resp);
    }

    // Helpers privados eliminados (ahora el estado es efímero en el modal)
}