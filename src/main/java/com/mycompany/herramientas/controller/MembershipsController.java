package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.dao.IdGenerator;
import com.mycompany.herramientas.dao.MembresiaDAO;
import com.mycompany.herramientas.model.Membresia;
import com.mycompany.herramientas.view.ViewRoutes;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

// controlador de gestión de membresías
@WebServlet("/memberships")
public class MembershipsController extends AbstractController {

    private static final Logger LOGGER =
            Logger.getLogger(MembershipsController.class.getName());

    private final MembresiaDAO membresiaDAO =
            new MembresiaDAO();

    // ───────────────── GET ────────────────────────────

    @Override
    protected void doGet(HttpServletRequest req,
                         HttpServletResponse resp)
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

            default:
                mostrarLista(req, resp);
        }
    }

    // ───────────────── POST ───────────────────────────

    @Override
    protected void doPost(HttpServletRequest req,
                          HttpServletResponse resp)
            throws ServletException, IOException {

        // solo administrador puede modificar membresías
        if (!esAdmin(req)) {

            forbidden(resp);

            return;
        }

        String action = getAction(req);

        switch (action) {

            case "save":
                guardarMembresia(req, resp);
                break;

            case "delete":
                eliminarMembresia(req, resp);
                break;

            case "toggleStatus":
                toggleStatusMembresia(req, resp);
                break;

            default:
                redirigirA("/memberships", req, resp);
        }
    }

    // ───────────────── lista de membresías ────────────

    private void mostrarLista(HttpServletRequest req,
                              HttpServletResponse resp)
            throws ServletException, IOException {

        try {

            List<Membresia> membresias =
                    membresiaDAO.findAll();

            req.setAttribute(
                    "membresias",
                    membresias
            );

            req.setAttribute(
                    "totalMembresias",
                    membresias.size()
            );

            irA(
                    ViewRoutes.MEMBERSHIPS_INDEX,
                    req,
                    resp
            );

        } catch (SQLException e) {

            LOGGER.log(
                    Level.SEVERE,
                    "Error al listar membresías",
                    e
            );

            req.setAttribute(
                    "errorMsg",
                    "Error al cargar los planes. "
                            + "Intenta nuevamente."
            );

            irA(
                    ViewRoutes.MEMBERSHIPS_INDEX,
                    req,
                    resp
            );
        }
    }

    // ───────────────── formulario nuevo ───────────────

    private void mostrarFormularioNuevo(HttpServletRequest req,
                                        HttpServletResponse resp)
            throws ServletException, IOException {

        // validar permisos de administrador
        if (!esAdmin(req)) {

            forbidden(resp);

            return;
        }

        req.setAttribute(
                "modoEdicion",
                false
        );

        req.setAttribute(
                "membresia",
                new Membresia()
        );

        irA(
                ViewRoutes.MEMBERSHIPS_INDEX
                        + "?form=true",
                req,
                resp
        );
    }

    // ───────────────── formulario edición ─────────────

    private void mostrarFormularioEdicion(HttpServletRequest req,
                                          HttpServletResponse resp)
            throws ServletException, IOException {

        // validar permisos de administrador
        if (!esAdmin(req)) {

            forbidden(resp);

            return;
        }

        String id = param(req, "id");

        // validar ID recibido
        if (id == null) {

            mensajeError(
                    req,
                    "ID de membresía no especificado."
            );

            redirigirA(
                    "/memberships",
                    req,
                    resp
            );

            return;
        }

        try {

            Membresia membresia =
                    membresiaDAO.findById(id);

            // validar existencia de membresía
            if (membresia == null) {

                mensajeError(
                        req,
                        "No se encontró el plan con ID: "
                                + id
                );

                redirigirA(
                        "/memberships",
                        req,
                        resp
                );

                return;
            }

            req.setAttribute(
                    "membresia",
                    membresia
            );

            req.setAttribute(
                    "modoEdicion",
                    true
            );

            irA(
                    ViewRoutes.MEMBERSHIPS_INDEX
                            + "?form=true",
                    req,
                    resp
            );

        } catch (SQLException e) {

            LOGGER.log(
                    Level.SEVERE,
                    "Error al cargar membresía para edición: "
                            + id,
                    e
            );

            mensajeError(
                    req,
                    "Error al cargar el plan."
            );

            redirigirA(
                    "/memberships",
                    req,
                    resp
            );
        }
    }

    // ───────────────── guardar membresía ──────────────

    private void guardarMembresia(HttpServletRequest req,
                                  HttpServletResponse resp)
            throws ServletException, IOException {

        String id =
                param(req, "id");

        String nombre =
                param(req, "nombreMembresia");

        String precioStr =
                param(req, "precio");

        String duracionStr =
                param(req, "duracionMeses");

        String descripcion =
                param(req, "descripcion");

        boolean esNuevo =
                (id == null || id.isBlank());

        // validar nombre obligatorio
        if (nombre == null) {

            volverAlFormulario(
                    req,
                    resp,
                    esNuevo,
                    id,
                    "El nombre del plan es obligatorio."
            );

            return;
        }

        // convertir precio a BigDecimal
        BigDecimal precio;

        try {

            precio = new BigDecimal(
                    precioStr != null
                            ? precioStr.trim().replace(",", ".")
                            : ""
            );

            // validar monto positivo
            if (precio.compareTo(BigDecimal.ZERO) <= 0) {

                volverAlFormulario(
                        req,
                        resp,
                        esNuevo,
                        id,
                        "El precio debe ser mayor a cero."
                );

                return;
            }

        } catch (NumberFormatException e) {

            volverAlFormulario(
                    req,
                    resp,
                    esNuevo,
                    id,
                    "El precio ingresado no es válido "
                            + "(usa punto decimal, ej: 120.00)."
            );

            return;
        }

        // convertir duración a entero
        int duracionMeses;

        try {

            duracionMeses = Integer.parseInt(
                    duracionStr != null
                            ? duracionStr.trim()
                            : ""
            );

            // validar duración mínima
            if (duracionMeses <= 0) {

                volverAlFormulario(
                        req,
                        resp,
                        esNuevo,
                        id,
                        "La duración debe ser al menos 1 mes."
                );

                return;
            }

        } catch (NumberFormatException e) {

            volverAlFormulario(
                    req,
                    resp,
                    esNuevo,
                    id,
                    "La duración ingresada no es válida "
                            + "(ingresa un número entero)."
            );

            return;
        }

        // construir objeto membresía
        Membresia membresia =
                new Membresia();

        membresia.setId(
                esNuevo
                        ? generarIdMembresia()
                        : id
        );

        membresia.setNombreMembresia(
                nombre.trim()
        );

        membresia.setPrecio(precio);

        membresia.setDuracionMeses(
                duracionMeses
        );

        membresia.setDescripcion(
                descripcion
        );

        // guardar en base de datos
        try {

            membresiaDAO.save(membresia);

            String accion =
                    esNuevo
                            ? "creado"
                            : "actualizado";

            LOGGER.info(
                    "Plan "
                            + accion
                            + ": "
                            + membresia.getId()
                            + " | "
                            + membresia.getNombreMembresia()
            );

            mensajeExito(
                    req,
                    "Plan \""
                            + membresia.getNombreMembresia()
                            + "\" "
                            + accion
                            + " correctamente."
            );

            redirigirA(
                    "/memberships",
                    req,
                    resp
            );

        } catch (SQLException e) {

            LOGGER.log(
                    Level.SEVERE,
                    "Error al guardar membresía",
                    e
            );

            volverAlFormulario(
                    req,
                    resp,
                    esNuevo,
                    id,
                    "Error al guardar el plan. "
                            + "Intenta nuevamente."
            );
        }
    }

    // ───────────────── eliminar membresía ─────────────

    private void eliminarMembresia(HttpServletRequest req,
                                   HttpServletResponse resp)
            throws IOException {

        String id = param(req, "id");

        // validar ID recibido
        if (id == null) {

            mensajeError(
                    req,
                    "ID de plan no especificado."
            );

            redirigirA(
                    "/memberships",
                    req,
                    resp
            );

            return;
        }

        try {

            boolean eliminado =
                    membresiaDAO.delete(id);

            if (eliminado) {

                LOGGER.info(
                        "Membresía eliminada: "
                                + id
                );

                mensajeExito(
                        req,
                        "Plan eliminado correctamente."
                );

            } else {

                mensajeError(
                        req,
                        "No se encontró el plan con ID: "
                                + id
                );
            }

        } catch (SQLException e) {

            LOGGER.log(
                    Level.SEVERE,
                    "Error al eliminar membresía: "
                            + id,
                    e
            );

            String msg;

            // validar restricción por contratos asociados
            if (e.getMessage() != null
                    && e.getMessage().contains("REFERENCE")) {

                msg =
                        "No se puede eliminar el plan "
                                + "porque ya tiene contratos asociados. "
                                + "Desactívalo o crea un plan nuevo.";

            } else {

                msg =
                        "Error al eliminar el plan. "
                                + "Intenta nuevamente.";
            }

            mensajeError(req, msg);
        }

        redirigirA(
                "/memberships",
                req,
                resp
        );
    }

    // ───────────────── cambiar estado de membresía ────────
    
    private void toggleStatusMembresia(HttpServletRequest req,
                                       HttpServletResponse resp)
            throws IOException {
            
        String id = param(req, "id");
        
        if (id == null) {
            mensajeError(req, "ID de plan no especificado.");
            redirigirA("/memberships", req, resp);
            return;
        }
        
        try {
            Membresia membresia = membresiaDAO.findById(id);
            if (membresia != null) {
                String nuevoEstado = "activo".equalsIgnoreCase(membresia.getEstado()) ? "inactivo" : "activo";
                membresia.setEstado(nuevoEstado);
                membresiaDAO.save(membresia);
                
                LOGGER.info("Estado de membresía " + id + " cambiado a " + nuevoEstado);
                mensajeExito(req, "El plan ahora está " + nuevoEstado + ".");
            } else {
                mensajeError(req, "No se encontró el plan.");
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al cambiar estado de membresía: " + id, e);
            mensajeError(req, "Error al cambiar el estado del plan.");
        }
        
        redirigirA("/memberships", req, resp);
    }

    // ───────────────── helpers privados ───────────────

    // volver al formulario preservando datos y errores
    private void volverAlFormulario(HttpServletRequest req,
                                    HttpServletResponse resp,
                                    boolean esNuevo,
                                    String id,
                                    String errorMsg)
            throws ServletException, IOException {

        // formError: exclusivo para errores inline — el navbar no lo renderiza
        req.setAttribute(
                "formError",
                errorMsg
        );

        req.setAttribute(
                "modoEdicion",
                !esNuevo
        );

        // reconstruir formulario
        if (!esNuevo && id != null) {

            try {

                Membresia original =
                        membresiaDAO.findById(id);

                req.setAttribute(
                        "membresia",
                        original != null
                                ? original
                                : new Membresia()
                );

            } catch (SQLException e) {

                req.setAttribute(
                        "membresia",
                        new Membresia()
                );
            }

        } else {

            req.setAttribute(
                    "membresia",
                    construirDesdeRequest(req)
            );
        }

        irA(
                ViewRoutes.MEMBERSHIPS_INDEX
                        + "?form=true",
                req,
                resp
        );
    }

    // construir membresía parcial desde request
    private Membresia construirDesdeRequest(HttpServletRequest req) {

        Membresia m =
                new Membresia();

        m.setNombreMembresia(
                param(req, "nombreMembresia", "")
        );

        String precioStr =
                param(req, "precio");

        if (precioStr != null) {

            try {

                m.setPrecio(
                        new BigDecimal(
                                precioStr.replace(",", ".")
                        )
                );

            } catch (NumberFormatException ignored) {
            }
        }

        String durStr =
                param(req, "duracionMeses");

        if (durStr != null) {

            try {

                m.setDuracionMeses(
                        Integer.parseInt(durStr)
                );

            } catch (NumberFormatException ignored) {
            }
        }

        m.setDescripcion(
                param(req, "descripcion")
        );

        return m;
    }

    // generar ID automático de membresía
    private String generarIdMembresia() {

        return IdGenerator.generar(
                "MEM",
                "Membresias"
        );
    }
}