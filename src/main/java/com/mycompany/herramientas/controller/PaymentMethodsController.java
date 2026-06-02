package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.config.AppConfig;
import com.mycompany.herramientas.dao.CatalogoDAO;
import com.mycompany.herramientas.model.MetodoPago;
import com.mycompany.herramientas.view.ViewRoutes;
import com.mycompany.herramientas.dao.IdGenerator;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

// gestión de métodos de pago del sistema
@WebServlet("/payment-methods")
public class PaymentMethodsController extends AbstractController {

    private static final Logger LOGGER =
            Logger.getLogger(PaymentMethodsController.class.getName());

    private final CatalogoDAO catalogoDAO = new CatalogoDAO();

    // ─── GET ──────────────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        transferirFlashMessages(req);

        mostrarLista(req, resp);
    }

    // ─── POST ─────────────────────────────────────────────────

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = getAction(req);

        switch (action) {
            case "toggle":
                toggleEstadoMetodoPago(req, resp);
                break;
            case "save":
                guardarMetodoPago(req, resp);
                break;
            case "delete":
                eliminarMetodoPago(req, resp);
                break;
            default:
                redirigirA("/payment-methods", req, resp);
        }
    }

    // ─── GET: lista de métodos de pago ───────────────────────

    private void mostrarLista(HttpServletRequest req,
                               HttpServletResponse resp)
            throws ServletException, IOException {

        try {

            List<MetodoPago> metodos =
                    catalogoDAO.findAllMetodosPago();

            long totalActivos = metodos.stream()
                    .filter(MetodoPago::isActivo)
                    .count();

            long totalInactivos =
                    metodos.size() - totalActivos;

            req.setAttribute("metodos", metodos);

            req.setAttribute(
                    "totalMetodos",
                    metodos.size()
            );

            req.setAttribute(
                    "totalActivos",
                    totalActivos
            );

            req.setAttribute(
                    "totalInactivos",
                    totalInactivos
            );

            irA(ViewRoutes.PAYMENT_METHODS_INDEX, req, resp);

        } catch (SQLException e) {

            LOGGER.log(
                    Level.SEVERE,
                    "Error al listar métodos de pago",
                    e
            );

            req.setAttribute(
                    "errorMsg",
                    "Error al cargar los métodos de pago. "
                    + "Intenta nuevamente."
            );

            irA(ViewRoutes.PAYMENT_METHODS_INDEX, req, resp);
        }
    }

    // ─── POST: activar o desactivar método ───────────────────

    private void toggleEstadoMetodoPago(HttpServletRequest req,
                                         HttpServletResponse resp)
            throws IOException {

        String id = param(req, "id");

        if (id == null) {

            mensajeError(
                    req,
                    "ID de método de pago no especificado."
            );

            redirigirA("/payment-methods", req, resp);

            return;
        }

        try {

            // cargar todos los métodos para validar estado actual
            List<MetodoPago> todos =
                    catalogoDAO.findAllMetodosPago();

            MetodoPago metodo = todos.stream()
                    .filter(m -> id.equals(m.getId()))
                    .findFirst()
                    .orElse(null);

            if (metodo == null) {

                mensajeError(
                        req,
                        "No se encontró el método de pago con ID: " + id
                );

                redirigirA("/payment-methods", req, resp);

                return;
            }

            // impedir desactivar el único método activo
            if (metodo.isActivo()) {

                long totalActivos = todos.stream()
                        .filter(MetodoPago::isActivo)
                        .count();

                if (totalActivos <= 1) {

                    mensajeError(
                            req,
                            "No puedes desactivar \""
                                    + metodo.getNombre()
                                    + "\" porque es el único método activo."
                    );

                    redirigirA("/payment-methods", req, resp);

                    return;
                }
            }

            // invertir estado actual
            String nuevoEstado = metodo.isActivo()
                    ? AppConfig.ESTADO_INACTIVO
                    : AppConfig.ESTADO_ACTIVO;

            boolean actualizado =
                    catalogoDAO.updateEstadoMetodoPago(
                            id,
                            nuevoEstado
                    );

            if (actualizado) {

                LOGGER.info(
                        "Método de pago actualizado: "
                                + metodo.getNombre()
                                + " → "
                                + nuevoEstado
                );

                String accion =
                        AppConfig.ESTADO_ACTIVO.equals(nuevoEstado)
                                ? "activado"
                                : "desactivado";

                mensajeExito(
                        req,
                        "\"" + metodo.getNombre()
                                + "\" "
                                + accion
                                + " correctamente."
                );

            } else {

                mensajeError(
                        req,
                        "No se pudo actualizar el método de pago."
                );
            }

        } catch (SQLException e) {

            LOGGER.log(
                    Level.SEVERE,
                    "Error al cambiar estado del método de pago: " + id,
                    e
            );

            mensajeError(
                    req,
                    "Error interno al actualizar el método de pago."
            );
        }

        redirigirA("/payment-methods", req, resp);
    }

    // ─── POST: guardar (nuevo/editar) ─────────────────────────

    private void guardarMetodoPago(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        
        String id = param(req, "id");
        String nombre = param(req, "nombre");
        String estado = param(req, "estado");

        if (nombre == null || nombre.trim().isEmpty()) {
            mensajeError(req, "El nombre del método de pago es requerido.");
            redirigirA("/payment-methods?action=new", req, resp);
            return;
        }

        boolean esNuevo = (id == null || id.trim().isEmpty());
        MetodoPago mp = new MetodoPago();
        mp.setId(esNuevo ? IdGenerator.parMetodoPago() : id);
        mp.setNombre(nombre.trim());
        mp.setEstado(estado != null && estado.equals("activo") ? "activo" : "inactivo");

        try {
            boolean exito = true;
            if (esNuevo) {
                catalogoDAO.insertMetodoPago(mp);
            } else {
                exito = catalogoDAO.updateMetodoPago(mp);
            }

            if (exito) {
                mensajeExito(req, "Método de pago guardado correctamente.");
            } else {
                mensajeError(req, "No se pudo guardar el método de pago.");
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al guardar método de pago", e);
            mensajeError(req, "Error en la base de datos. Intente nuevamente.");
        }

        redirigirA("/payment-methods", req, resp);
    }

    // ─── POST: eliminar método ────────────────────────────────

    private void eliminarMetodoPago(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        
        String id = param(req, "id");
        if (id == null) {
            redirigirA("/payment-methods", req, resp);
            return;
        }

        try {
            boolean exito = catalogoDAO.deleteMetodoPago(id);
            if (exito) {
                mensajeExito(req, "Método de pago eliminado correctamente.");
            } else {
                mensajeError(req, "No se encontró el método para eliminar.");
            }
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al eliminar método de pago. Posible FK constraint", e);
            mensajeError(req, "No se puede eliminar porque ya está en uso. Considere desactivarlo.");
        }

        redirigirA("/payment-methods", req, resp);
    }
}