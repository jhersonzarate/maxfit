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

            case "new":
                mostrarFormularioNuevo(req, resp);
                break;

            case "edit":
                mostrarFormularioEdicion(req, resp);
                break;

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

            irA(ViewRoutes.EMPLOYEES_INDEX, req, resp);

        } catch (SQLException e) {

            LOGGER.log(Level.SEVERE, "Error al listar empleados", e);

            req.setAttribute(
                    "errorMsg",
                    "Error al cargar los empleados."
            );

            irA(ViewRoutes.EMPLOYEES_INDEX, req, resp);
        }
    }

    // ───────────────── formulario de registro ─────────

    private void mostrarFormularioNuevo(HttpServletRequest req,
                                        HttpServletResponse resp)
            throws ServletException, IOException {

        try {

            cargarCatalogosFormulario(req);

            req.setAttribute("modoEdicion", false);
            req.setAttribute("empleado", new Empleado());

            irA(
                    ViewRoutes.EMPLOYEES_INDEX + "?form=true",
                    req,
                    resp
            );

        } catch (SQLException e) {

            LOGGER.log(
                    Level.SEVERE,
                    "Error al cargar formulario de empleado",
                    e
            );

            mensajeError(req, "Error al cargar el formulario.");

            redirigirA("/employees", req, resp);
        }
    }

    // ───────────────── formulario de edición ──────────

    private void mostrarFormularioEdicion(HttpServletRequest req,
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

            cargarCatalogosFormulario(req);

            req.setAttribute("empleado", empleado);
            req.setAttribute("modoEdicion", true);

            irA(
                    ViewRoutes.EMPLOYEES_INDEX + "?form=true",
                    req,
                    resp
            );

        } catch (SQLException e) {

            LOGGER.log(
                    Level.SEVERE,
                    "Error al cargar empleado para edición: " + id,
                    e
            );

            mensajeError(req, "Error al cargar el empleado.");

            redirigirA("/employees", req, resp);
        }
    }

    // ───────────────── detalle del empleado ───────────

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

            volverAlFormulario(
                    req,
                    resp,
                    esNuevo,
                    id,
                    "El nombre y apellido son obligatorios."
            );

            return;
        }

        if (email == null) {

            volverAlFormulario(
                    req,
                    resp,
                    esNuevo,
                    id,
                    "El correo electrónico es obligatorio."
            );

            return;
        }

        if (idTipoDoc == null || numeroDoc == null) {

            volverAlFormulario(
                    req,
                    resp,
                    esNuevo,
                    id,
                    "Debe seleccionar tipo de documento e ingresar el número."
            );

            return;
        }

        if (idCargo == null) {

            volverAlFormulario(
                    req,
                    resp,
                    esNuevo,
                    id,
                    "Debe seleccionar un cargo."
            );

            return;
        }

        // validar documento según tipo seleccionado
        try {

            TipoDocumento tipoDoc =
                    catalogoDAO.findTipoDocumentoById(idTipoDoc);

            if (tipoDoc == null) {

                volverAlFormulario(
                        req,
                        resp,
                        esNuevo,
                        id,
                        "El tipo de documento seleccionado no es válido."
                );

                return;
            }

            DocumentoValidator.ResultadoValidacion validacion =
                    DocumentoValidator.validar(tipoDoc, numeroDoc);

            if (!validacion.isValido()) {

                volverAlFormulario(
                        req,
                        resp,
                        esNuevo,
                        id,
                        validacion.getMensaje()
                );

                return;
            }

            Cargo cargo = catalogoDAO.findCargoById(idCargo);

            if (cargo == null) {

                volverAlFormulario(
                        req,
                        resp,
                        esNuevo,
                        id,
                        "El cargo seleccionado no es válido."
                );

                return;
            }

            // construir objeto empleado
            Empleado empleado = new Empleado();

            empleado.setId(esNuevo ? IdGenerator.parEmpleado() : id);

            empleado.setNombre(nombre.trim());
            empleado.setApellido(apellido.trim());

            empleado.setTipoDocumento(tipoDoc);
            empleado.setNumeroDocumento(numeroDoc.trim());

            empleado.setEmail(email.trim().toLowerCase());

            empleado.setTelefono(telefono);
            empleado.setCargo(cargo);

            // guardar en base de datos
            empleadoDAO.save(empleado);

            String accion = esNuevo
                    ? "registrado"
                    : "actualizado";

            LOGGER.info(
                    "Empleado " + accion + ": "
                            + empleado.getId()
                            + " | "
                            + empleado.getNombreCompleto()
            );

            mensajeExito(
                    req,
                    "Empleado "
                            + empleado.getNombreCompleto()
                            + " "
                            + accion
                            + " correctamente."
            );

            redirigirA("/employees", req, resp);

        } catch (SQLException e) {

            LOGGER.log(Level.SEVERE, "Error al guardar empleado", e);

            String msg;

            // detectar restricciones únicas de BD
            if (e.getMessage() != null
                    && e.getMessage().contains("UNIQUE")) {

                msg = "El número de documento o correo ya está "
                        + "registrado en el sistema.";

            } else {

                msg = "Error al guardar el empleado. "
                        + "Intenta nuevamente.";
            }

            volverAlFormulario(
                    req,
                    resp,
                    esNuevo,
                    id,
                    msg
            );
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

    // ───────────────── helpers privados ───────────────

    private void cargarCatalogosFormulario(HttpServletRequest req)
            throws SQLException {

        req.setAttribute(
                "tiposDocumento",
                catalogoDAO.findAllTipoDocumentos()
        );

        req.setAttribute(
                "cargos",
                catalogoDAO.findAllCargos()
        );
    }

    // recargar formulario manteniendo datos ingresados
    private void volverAlFormulario(HttpServletRequest req,
                                    HttpServletResponse resp,
                                    boolean esNuevo,
                                    String id,
                                    String errorMsg)
            throws ServletException, IOException {

        req.setAttribute("errorMsg", errorMsg);

        req.setAttribute("modoEdicion", !esNuevo);

        try {

            cargarCatalogosFormulario(req);

            if (!esNuevo && id != null) {

                Empleado original = empleadoDAO.findById(id);

                req.setAttribute(
                        "empleado",
                        original != null
                                ? original
                                : new Empleado()
                );

            } else {

                req.setAttribute(
                        "empleado",
                        construirDesdeRequest(req)
                );
            }

        } catch (SQLException e) {

            LOGGER.log(
                    Level.WARNING,
                    "Error al recargar formulario de empleado",
                    e
            );
        }

        irA(
                ViewRoutes.EMPLOYEES_INDEX + "?form=true",
                req,
                resp
        );
    }

    // construir empleado temporal desde request
    private Empleado construirDesdeRequest(HttpServletRequest req) {

        Empleado e = new Empleado();

        e.setNombre(param(req, "nombre", ""));
        e.setApellido(param(req, "apellido", ""));
        e.setNumeroDocumento(param(req, "numeroDocumento", ""));
        e.setEmail(param(req, "email", ""));
        e.setTelefono(param(req, "telefono"));

        return e;
    }
}