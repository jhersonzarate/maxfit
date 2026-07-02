package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.dao.CatalogoDAO;
import com.mycompany.herramientas.dao.ClienteDAO;
import com.mycompany.herramientas.dao.ContratoDAO;
import com.mycompany.herramientas.dao.IdGenerator;
import com.mycompany.herramientas.dao.InscripcionDAO;
import com.mycompany.herramientas.dao.AsistenciaDAO;
import com.mycompany.herramientas.model.Cliente;
import com.mycompany.herramientas.model.TipoDocumento;
import com.mycompany.herramientas.service.DocumentoValidator;
import com.mycompany.herramientas.view.ViewRoutes;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

// controlador de gestión de clientes
@WebServlet("/clients")
public class ClientsController extends AbstractController {

    private static final Logger LOGGER =
            Logger.getLogger(ClientsController.class.getName());

    private final ClienteDAO     clienteDAO     = new ClienteDAO();
    private final CatalogoDAO    catalogoDAO    = new CatalogoDAO();
    private final ContratoDAO    contratoDAO    = new ContratoDAO();
    private final InscripcionDAO inscripcionDAO = new InscripcionDAO();
    private final AsistenciaDAO  asistenciaDAO  = new AsistenciaDAO();

    // ─── GET ─────────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // paso flash messages al request
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

    // ─── POST ────────────────────────────────────────────

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = getAction(req);

        switch (action) {

            case "save":
                guardarCliente(req, resp);
                break;

            case "delete":
                eliminarCliente(req, resp);
                break;

            default:
                redirigirA("/clients", req, resp);
        }
    }

    // ─── mostrar lista de clientes ──────────────────────

    private void mostrarLista(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // búsqueda opcional desde el input
        String query = param(req, "q");

        try {

            List<Cliente> clientes = (query != null)
                    ? clienteDAO.search(query)
                    : clienteDAO.findAll();

            req.setAttribute("clientes", clientes);
            req.setAttribute("query", query);
            req.setAttribute("totalClientes", clientes.size());

            irA(ViewRoutes.CLIENTS_INDEX, req, resp);

        } catch (SQLException e) {

            LOGGER.log(Level.SEVERE, "Error al listar clientes", e);

            req.setAttribute(
                    "errorMsg",
                    "Error al cargar los clientes. Intenta nuevamente."
            );

            irA(ViewRoutes.CLIENTS_INDEX, req, resp);
        }
    }

    // ─── mostrar formulario de nuevo cliente ────────────

    private void mostrarFormularioNuevo(HttpServletRequest req,
                                        HttpServletResponse resp)
            throws ServletException, IOException {

        try {

            req.setAttribute(
                    "tiposDocumento",
                    catalogoDAO.findAllTipoDocumentos()
            );

            req.setAttribute("modoEdicion", false);

            // envío cliente vacío para evitar null en el JSP
            req.setAttribute("cliente", new Cliente());

            irA(ViewRoutes.CLIENTS_INDEX + "?form=true", req, resp);

        } catch (SQLException e) {

            LOGGER.log(
                    Level.SEVERE,
                    "Error al cargar formulario de cliente",
                    e
            );

            mensajeError(req, "Error al cargar el formulario.");

            redirigirA("/clients", req, resp);
        }
    }

    // ─── mostrar formulario de edición ──────────────────

    private void mostrarFormularioEdicion(HttpServletRequest req,
                                          HttpServletResponse resp)
            throws ServletException, IOException {

        // solo admin puede editar
        if (!esAdmin(req)) {
            forbidden(resp);
            return;
        }

        String id = param(req, "id");

        if (id == null) {

            mensajeError(req, "ID de cliente no especificado.");

            redirigirA("/clients", req, resp);

            return;
        }

        try {

            Cliente cliente = clienteDAO.findById(id);

            // si no existe el cliente
            if (cliente == null) {

                mensajeError(
                        req,
                        "No se encontró el cliente con ID: " + id
                );

                redirigirA("/clients", req, resp);

                return;
            }

            req.setAttribute("cliente", cliente);

            req.setAttribute(
                    "tiposDocumento",
                    catalogoDAO.findAllTipoDocumentos()
            );

            req.setAttribute("modoEdicion", true);

            irA(ViewRoutes.CLIENTS_INDEX + "?form=true", req, resp);

        } catch (SQLException e) {

            LOGGER.log(
                    Level.SEVERE,
                    "Error al cargar cliente para edición: " + id,
                    e
            );

            mensajeError(req, "Error al cargar el cliente.");

            redirigirA("/clients", req, resp);
        }
    }

    // ─── mostrar detalle del cliente ────────────────────

    private void mostrarDetalle(HttpServletRequest req,
                                HttpServletResponse resp)
            throws ServletException, IOException {

        String id = param(req, "id");

        if (id == null) {

            mensajeError(req, "ID de cliente no especificado.");

            redirigirA("/clients", req, resp);

            return;
        }

        try {

            Cliente cliente = clienteDAO.findById(id);

            // si el cliente no existe
            if (cliente == null) {

                mensajeError(
                        req,
                        "No se encontró el cliente con ID: " + id
                );

                redirigirA("/clients", req, resp);

                return;
            }

            // cargo toda la info relacionada
            req.setAttribute("cliente", cliente);

            req.setAttribute(
                    "contratos",
                    contratoDAO.findByClienteId(id)
            );

            req.setAttribute(
                    "inscripciones",
                    inscripcionDAO.findByClienteId(id)
            );

            req.setAttribute(
                    "asistencias",
                    asistenciaDAO.findByClienteId(id)
            );

            irA(ViewRoutes.CLIENT_DETAIL, req, resp);

        } catch (SQLException e) {

            LOGGER.log(
                    Level.SEVERE,
                    "Error al cargar detalle del cliente: " + id,
                    e
            );

            mensajeError(req, "Error al cargar el cliente.");

            redirigirA("/clients", req, resp);
        }
    }

    // ─── guardar cliente ────────────────────────────────

    private void guardarCliente(HttpServletRequest req,
                                HttpServletResponse resp)
            throws ServletException, IOException {

        // leo datos del formulario
        String id              = param(req, "id");
        String nombre          = param(req, "nombre");
        String apellido        = param(req, "apellido");
        String idTipoDoc       = param(req, "idTipoDocumento");
        String numeroDoc       = param(req, "numeroDocumento");
        String email           = param(req, "email");
        String telefono        = param(req, "telefono");
        String fechaNacStr     = param(req, "fechaNacimiento");
        String genero          = param(req, "genero");

        boolean esNuevo = (id == null || id.isBlank());

        // solo admin puede editar
        if (!esNuevo && !esAdmin(req)) {
            forbidden(resp);
            return;
        }

        // validación básica
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

        //validacion para evitar Numeros en nombreApellido
        if (!contieneSoloLetras(nombre)|| !contieneSoloLetras(apellido)) {

            volverAlFormulario(
                    req,
                    resp,
                    esNuevo,
                    id,
                    "El nombre y apellido no pueden contener números."
            );

            return;
        }

        // validar documento SOLO si es nuevo
        if (esNuevo) {
            if (idTipoDoc == null || numeroDoc == null || idTipoDoc.isBlank() || numeroDoc.isBlank()) {
                volverAlFormulario(
                        req,
                        resp,
                        esNuevo,
                        id,
                        "Debe seleccionar un tipo de documento e ingresar el número."
                );
                return;
            }
        }

        try {

            TipoDocumento tipoDoc = null;

            if (esNuevo) {
                tipoDoc = catalogoDAO.findTipoDocumentoById(idTipoDoc);

                // si el tipo de documento no existe
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

                // si el documento no cumple formato
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
            }

            // construyo el objeto cliente
            Cliente cliente = new Cliente();

            if (esNuevo) {
                cliente.setId(IdGenerator.parCliente());
                cliente.setTipoDocumento(tipoDoc);
                cliente.setNumeroDocumento(numeroDoc);
            } else {
                cliente.setId(id);
                // En edición también actualizamos tipo y número de documento
                TipoDocumento tipoDocEdicion = catalogoDAO.findTipoDocumentoById(idTipoDoc);
                if (tipoDocEdicion != null) {
                    cliente.setTipoDocumento(tipoDocEdicion);
                    cliente.setNumeroDocumento(numeroDoc);
                } else {
                    // Si no viene tipo doc válido, preservamos el original
                    Cliente clienteOriginal = clienteDAO.findById(id);
                    if (clienteOriginal != null) {
                        cliente.setTipoDocumento(clienteOriginal.getTipoDocumento());
                        cliente.setNumeroDocumento(clienteOriginal.getNumeroDocumento());
                    }
                }
            }

            cliente.setNombre(nombre);
            cliente.setApellido(apellido);

            cliente.setEmail(email);
            cliente.setTelefono(telefono);

            cliente.setGenero(
                    esGeneroValido(genero)
                            ? genero
                            : null
            );

            // validación de fecha de nacimiento (obligatoria)
            if (fechaNacStr == null || fechaNacStr.isBlank()) {
                volverAlFormulario(req, resp, esNuevo, id, "La fecha de nacimiento es obligatoria.");
                return;
            }

            try {
                LocalDate fechaNacimiento = LocalDate.parse(fechaNacStr);

                // Regla de negocio: Fecha no puede ser futura
                if (fechaNacimiento.isAfter(LocalDate.now())) {
                    volverAlFormulario(req, resp, esNuevo, id, "La fecha de nacimiento no puede estar en el futuro.");
                    return;
                }

                // Regla de negocio: Edad mínima (14 años)
                long edad = java.time.temporal.ChronoUnit.YEARS.between(fechaNacimiento, LocalDate.now());
                if (edad < 14) {
                    volverAlFormulario(req, resp, esNuevo, id, "El cliente debe tener al menos 14 años.");
                    return;
                }

                cliente.setFechaNacimiento(fechaNacimiento);

            } catch (java.time.format.DateTimeParseException e) {

                    volverAlFormulario(
                            req,
                            resp,
                            esNuevo,
                            id,
                            "El formato de fecha no es válido."
                    );

                    return;
                }

            // Regla de negocio: Duplicidad de DNI
            if (esNuevo) {
                Cliente clienteExistente = clienteDAO.findByDocument(numeroDoc);
                if (clienteExistente != null) {
                    volverAlFormulario(req, resp, esNuevo, id, "El documento ingresado ya está registrado para otro cliente.");
                    return;
                }
            }

            // guardo el cliente
            clienteDAO.save(cliente);

            String accion = esNuevo
                    ? "registrado"
                    : "actualizado";

            LOGGER.info(
                    "Cliente " + accion + ": "
                            + cliente.getId()
            );

            mensajeExito(
                    req,
                    "Cliente "
                            + cliente.getNombreCompleto()
                            + " "
                            + accion
                            + " correctamente."
            );

            redirigirA("/clients", req, resp);

        } catch (SQLException e) {

            LOGGER.log(Level.SEVERE,
                    "Error al guardar cliente",
                    e);

            String msgError;

            // detectar duplicados UNIQUE
            if (e.getMessage() != null
                    && e.getMessage().contains("UNIQUE")) {

                msgError =
                        "El documento o email ya está registrado.";

            } else {

                msgError =
                        "Error al guardar el cliente.";
            }

            volverAlFormulario(
                    req,
                    resp,
                    esNuevo,
                    id,
                    msgError
            );
        }
    }

    // ─── eliminar cliente ───────────────────────────────

    private void eliminarCliente(HttpServletRequest req,
                                 HttpServletResponse resp)
            throws ServletException, IOException {

        // solo admin puede eliminar
        if (!esAdmin(req)) {
            forbidden(resp);
            return;
        }

        String id = param(req, "id");

        if (id == null) {

            mensajeError(req, "ID de cliente no especificado.");

            redirigirA("/clients", req, resp);

            return;
        }

        try {

            boolean eliminado = clienteDAO.delete(id);

            if (eliminado) {

                LOGGER.info("Cliente eliminado: " + id);

                mensajeExito(
                        req,
                        "Cliente eliminado correctamente."
                );

            } else {

                mensajeError(
                        req,
                        "No se encontró el cliente con ID: " + id
                );
            }

        } catch (SQLException e) {

            LOGGER.log(
                    Level.SEVERE,
                    "Error al eliminar cliente: " + id,
                    e
            );

            String msgError;

            // error por relaciones FK
            if (e.getMessage() != null
                    && e.getMessage().contains("REFERENCE")) {

                msgError =
                        "No se puede eliminar el cliente porque tiene registros asociados.";

            } else {

                msgError =
                        "Error al eliminar el cliente.";
            }

            mensajeError(req, msgError);
        }

        redirigirA("/clients", req, resp);
    }

    // ─── helpers privados ───────────────────────────────

    // recargo el formulario sin perder los datos
    private void volverAlFormulario(HttpServletRequest req,
                                    HttpServletResponse resp,
                                    boolean esNuevo,
                                    String id,
                                    String errorMsg)
            throws ServletException, IOException {

        // formError: atributo exclusivo para errores inline en el formulario
        // (no lo renderiza el navbar, evita la duplicación del mensaje)
        req.setAttribute("formError", errorMsg);

        req.setAttribute("modoEdicion", !esNuevo);

        try {

            req.setAttribute(
                    "tiposDocumento",
                    catalogoDAO.findAllTipoDocumentos()
            );

            // si es edición cargo cliente original
            if (!esNuevo && id != null) {

                Cliente clienteOriginal =
                        clienteDAO.findById(id);

                req.setAttribute(
                        "cliente",
                        clienteOriginal != null
                                ? clienteOriginal
                                : new Cliente()
                );

            } else {

                // mantengo los datos ingresados
                req.setAttribute(
                        "cliente",
                        construirClienteDesdeRequest(req)
                );
            }

        } catch (SQLException e) {

            LOGGER.log(
                    Level.WARNING,
                    "Error al recargar formulario",
                    e
            );
        }

        irA(ViewRoutes.CLIENTS_INDEX + "?form=true", req, resp);
    }

    // construyo cliente parcial desde el request
    private Cliente construirClienteDesdeRequest(HttpServletRequest req) {

        Cliente c = new Cliente();

        c.setNombre(param(req, "nombre", ""));
        c.setApellido(param(req, "apellido", ""));
        c.setNumeroDocumento(param(req, "numeroDocumento", ""));
        c.setEmail(param(req, "email"));
        c.setTelefono(param(req, "telefono"));

        String genero = param(req, "genero");
        c.setGenero(
                esGeneroValido(genero)
                        ? genero
                        : null
        );

        String fechaNacStr = param(req, "fechaNacimiento");
        if (fechaNacStr != null && !fechaNacStr.isBlank()) {
            try {
                c.setFechaNacimiento(java.time.LocalDate.parse(fechaNacStr));
            } catch (Exception e) {
                // Ignorar error de parseo
            }
        }

        String idTipoDocStr = param(req, "idTipoDocumento");
        if (idTipoDocStr != null && !idTipoDocStr.isBlank()) {
            try {
                TipoDocumento td = new TipoDocumento();
                td.setId(idTipoDocStr);
                c.setTipoDocumento(td);
            } catch (NumberFormatException e) {
                // Ignorar
            }
        }

        return c;
    }

    // valido los géneros permitidos por la BD
    private boolean esGeneroValido(String genero) {

        return "Masculino".equals(genero)
                || "Femenino".equals(genero)
                || "Otro".equals(genero);
    }
}