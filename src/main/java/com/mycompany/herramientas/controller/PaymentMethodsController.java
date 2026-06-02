package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.config.AppConfig;
import com.mycompany.herramientas.dao.CatalogoDAO;
import com.mycompany.herramientas.model.MetodoPago;
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

// gestión de métodos de pago del sistema — CRUD completo
@WebServlet("/payment-methods")
public class PaymentMethodsController extends AbstractController {

    private static final Logger LOGGER =
            Logger.getLogger(PaymentMethodsController.class.getName());

    private final CatalogoDAO catalogoDAO = new CatalogoDAO();

    // ─── GET ──────────────────────────────────────────────────

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

    // ─── POST ─────────────────────────────────────────────────

    @Override
    protected void doPost(HttpServletRequest req,
                          HttpServletResponse resp)
            throws ServletException, IOException {

        String action = getAction(req);

        switch (action) {

            case "save":
                guardarMetodoPago(req, resp);
                break;

            case "toggle":
                toggleEstadoMetodoPago(req, resp);
                break;

            default:
                redirigirA("/payment-methods", req, resp);
        }
    }

    // ─── lista de métodos de pago ─────────────────────────────

    private void mostrarLista(HttpServletRequest req,
                               HttpServletResponse resp)
            throws ServletException, IOException {

        try {
            List<MetodoPago> metodos =
                    catalogoDAO.findAllMetodosPago();

            long totalActivos = metodos.stream()
                    .filter(MetodoPago::isActivo)
                    .count();

            long totalInactivos = metodos.size() - totalActivos;

            req.setAttribute("metodos",        metodos);
            req.setAttribute("totalMetodos",   metodos.size());
            req.setAttribute("totalActivos",   totalActivos);
            req.setAttribute("totalInactivos", totalInactivos);
            // mostrarForm NO se setea → JSP muestra la lista

            irA(ViewRoutes.PAYMENT_METHODS_INDEX, req, resp);

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE,
                    "Error al listar métodos de pago", e);
            req.setAttribute("errorMsg",
                    "Error al cargar los métodos de pago.");
            irA(ViewRoutes.PAYMENT_METHODS_INDEX, req, resp);
        }
    }

    // ─── formulario nuevo ─────────────────────────────────────

    private void mostrarFormularioNuevo(HttpServletRequest req,
                                         HttpServletResponse resp)
            throws ServletException, IOException {

        req.setAttribute("mostrarForm", true);   // ← señal para JSP
        req.setAttribute("modoEdicion", false);
        req.setAttribute("metodoPago",  new MetodoPago());

        try {
            cargarListaParaVista(req);
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING,
                    "Error al cargar lista para formulario", e);
        }

        irA(ViewRoutes.PAYMENT_METHODS_INDEX, req, resp);
    }

    // ─── formulario edición ───────────────────────────────────

    private void mostrarFormularioEdicion(HttpServletRequest req,
                                           HttpServletResponse resp)
            throws ServletException, IOException {

        String id = param(req, "id");

        if (id == null) {
            mensajeError(req, "ID de método no especificado.");
            redirigirA("/payment-methods", req, resp);
            return;
        }

        try {
            MetodoPago mp = catalogoDAO.findMetodoPagoById(id);

            if (mp == null) {
                mensajeError(req,
                        "No se encontró el método de pago con ID: " + id);
                redirigirA("/payment-methods", req, resp);
                return;
            }

            req.setAttribute("mostrarForm", true);   // ← señal para JSP
            req.setAttribute("metodoPago",  mp);
            req.setAttribute("modoEdicion", true);
            cargarListaParaVista(req);

            irA(ViewRoutes.PAYMENT_METHODS_INDEX, req, resp);

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE,
                    "Error al cargar método para edición: " + id, e);
            mensajeError(req, "Error al cargar el método de pago.");
            redirigirA("/payment-methods", req, resp);
        }
    }

    // ─── guardar método de pago ───────────────────────────────

    private void guardarMetodoPago(HttpServletRequest req,
                                    HttpServletResponse resp)
            throws ServletException, IOException {

        String id     = param(req, "id");
        String nombre = param(req, "nombre");
        String estado = param(req, "estado", AppConfig.ESTADO_ACTIVO);

        boolean esNuevo = (id == null || id.isBlank());

        // ── validación: nombre obligatorio ────────────────────
        if (nombre == null || nombre.isBlank()) {
            req.setAttribute("mostrarForm", true);   // ← señal para JSP
            req.setAttribute("formError",
                    "El nombre del método de pago es obligatorio.");
            req.setAttribute("modoEdicion", !esNuevo);
            req.setAttribute("metodoPago",  new MetodoPago());
            irA(ViewRoutes.PAYMENT_METHODS_INDEX, req, resp);
            return;
        }

        MetodoPago mp = new MetodoPago();

        if (esNuevo) {
            // generar ID tipo: PAY-NOMBRE
            String sufijo = nombre.trim()
                    .toUpperCase()
                    .replaceAll("[^A-Z0-9]", "");
            if (sufijo.length() > 10) sufijo = sufijo.substring(0, 10);
            mp.setId("PAY-" + sufijo);
        } else {
            mp.setId(id);
        }

        mp.setNombre(nombre.trim());
        mp.setEstado(estado);

        try {
            if (esNuevo) {
                catalogoDAO.insertMetodoPago(mp);
                LOGGER.info("MetodoPago creado: " + mp.getId());
                mensajeExito(req,
                        "Método de pago \""
                                + mp.getNombre()
                                + "\" creado correctamente.");
            } else {
                catalogoDAO.updateMetodoPago(mp);
                LOGGER.info("MetodoPago actualizado: " + mp.getId());
                mensajeExito(req,
                        "Método de pago \""
                                + mp.getNombre()
                                + "\" actualizado correctamente.");
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE,
                    "Error al guardar método de pago", e);
            String msg = e.getMessage() != null
                    && e.getMessage().contains("PRIMARY")
                    ? "Ya existe un método con ese nombre."
                    : "Error al guardar. Intenta nuevamente.";

            // ── regresar al form con error y datos preservados ─
            MetodoPago mpError = new MetodoPago();
            mpError.setId(mp.getId());
            mpError.setNombre(mp.getNombre());
            mpError.setEstado(mp.getEstado());

            req.setAttribute("mostrarForm", true);   // ← señal para JSP
            req.setAttribute("formError",   msg);
            req.setAttribute("modoEdicion", !esNuevo);
            req.setAttribute("metodoPago",  mpError);
            irA(ViewRoutes.PAYMENT_METHODS_INDEX, req, resp);
            return;
        }

        redirigirA("/payment-methods", req, resp);
    }

    // ─── toggle activo/inactivo ───────────────────────────────

    private void toggleEstadoMetodoPago(HttpServletRequest req,
                                         HttpServletResponse resp)
            throws IOException {

        String id = param(req, "id");

        if (id == null) {
            mensajeError(req,
                    "ID de método de pago no especificado.");
            redirigirA("/payment-methods", req, resp);
            return;
        }

        try {
            List<MetodoPago> todos =
                    catalogoDAO.findAllMetodosPago();

            MetodoPago metodo = todos.stream()
                    .filter(m -> id.equals(m.getId()))
                    .findFirst()
                    .orElse(null);

            if (metodo == null) {
                mensajeError(req,
                        "No se encontró el método de pago con ID: "
                                + id);
                redirigirA("/payment-methods", req, resp);
                return;
            }

            // impedir desactivar el único método activo
            if (metodo.isActivo()) {
                long totalActivos = todos.stream()
                        .filter(MetodoPago::isActivo)
                        .count();

                if (totalActivos <= 1) {
                    mensajeError(req,
                            "No puedes desactivar \""
                                    + metodo.getNombre()
                                    + "\" porque es el único "
                                    + "método activo.");
                    redirigirA("/payment-methods", req, resp);
                    return;
                }
            }

            String nuevoEstado = metodo.isActivo()
                    ? AppConfig.ESTADO_INACTIVO
                    : AppConfig.ESTADO_ACTIVO;

            boolean actualizado =
                    catalogoDAO.updateEstadoMetodoPago(id, nuevoEstado);

            if (actualizado) {
                String accion =
                        AppConfig.ESTADO_ACTIVO.equals(nuevoEstado)
                                ? "activado"
                                : "desactivado";

                LOGGER.info("MetodoPago " + metodo.getNombre()
                        + " → " + nuevoEstado);

                mensajeExito(req,
                        "\"" + metodo.getNombre()
                                + "\" " + accion
                                + " correctamente.");
            } else {
                mensajeError(req,
                        "No se pudo actualizar el método de pago.");
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE,
                    "Error al cambiar estado MetodoPago: " + id, e);
            mensajeError(req,
                    "Error interno al actualizar el método de pago.");
        }

        redirigirA("/payment-methods", req, resp);
    }

    // ─── helper privado ───────────────────────────────────────

    private void cargarListaParaVista(HttpServletRequest req)
            throws SQLException {

        List<MetodoPago> metodos =
                catalogoDAO.findAllMetodosPago();

        long totalActivos = metodos.stream()
                .filter(MetodoPago::isActivo).count();

        req.setAttribute("metodos",        metodos);
        req.setAttribute("totalMetodos",   metodos.size());
        req.setAttribute("totalActivos",   totalActivos);
        req.setAttribute("totalInactivos", metodos.size() - totalActivos);
    }
}