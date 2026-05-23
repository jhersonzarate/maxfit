package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.config.AppConfig;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

/**
 * Controlador base del que heredan todos los demás.
 *
 * Centraliza los helpers repetitivos que todos los controladores necesitan:
 *   - forward() a una vista JSP
 *   - redirect() con el contextPath incluido
 *   - getSession() para leer atributos de sesión
 *   - setError() / setSuccess() para pasar mensajes a las vistas
 *   - getRolUsuario() para verificar permisos dentro de un módulo
 *
 * Por qué heredar de HttpServlet en lugar de implementar todo aquí:
 *   AbstractController NO tiene @WebServlet ni URL mapping — solo es base.
 *   Cada controlador hijo registra su propia URL en web.xml.
 *
 * Uso en un controlador hijo:
 *   public class ClientsController extends AbstractController {
 *     @Override
 *     protected void doGet(HttpServletRequest req, HttpServletResponse resp)
 *             throws ServletException, IOException {
 *         List<Cliente> lista = clienteDAO.findAll();
 *         req.setAttribute("clientes", lista);
 *         forward(req, resp, ViewRoutes.CLIENTS_INDEX);
 *     }
 *   }
 */
public abstract class AbstractController extends HttpServlet {

    // ── Forward y Redirect ───────────────────────────────────────────────────

    /**
     * Hace un forward interno hacia un JSP.
     * El JSP debe estar bajo WEB-INF para que no sea accesible directamente por URL.
     *
     * @param req      la request actual
     * @param resp     la response actual
     * @param jspPath  ruta del JSP (usar constantes de ViewRoutes)
     */
    protected void forward(HttpServletRequest req, HttpServletResponse resp, String jspPath)
            throws ServletException, IOException {
        req.getRequestDispatcher(jspPath).forward(req, resp);
    }

    /**
     * Redirige al cliente a otra URL relativa al contextPath.
     * Usar siempre después de un POST exitoso (patrón PRG: Post-Redirect-Get).
     *
     * @param resp    la response actual
     * @param req     la request (para obtener el contextPath)
     * @param url     URL relativa sin contextPath (ej: "/clients", "/dashboard")
     */
    protected void redirect(HttpServletRequest req, HttpServletResponse resp, String url)
            throws IOException {
        resp.sendRedirect(req.getContextPath() + url);
    }

    /**
     * Redirige con un parámetro de query string.
     * Útil para pasar mensajes entre páginas después de un redirect.
     * Ejemplo: redirect(req, resp, "/clients", "success", "Cliente guardado correctamente.")
     *
     * @param param nombre del parámetro GET
     * @param value valor del parámetro
     */
    protected void redirectWithParam(HttpServletRequest req, HttpServletResponse resp,
                                     String url, String param, String value)
            throws IOException {
        resp.sendRedirect(req.getContextPath() + url + "?" + param + "="
                + java.net.URLEncoder.encode(value, "UTF-8"));
    }

    // ── Sesión ───────────────────────────────────────────────────────────────

    /**
     * Devuelve la sesión activa o null si no existe.
     * Nunca crea una sesión nueva (false).
     */
    protected HttpSession getSession(HttpServletRequest req) {
        return req.getSession(false);
    }

    /**
     * Devuelve el ID del usuario en sesión.
     */
    protected String getUserId(HttpServletRequest req) {
        HttpSession s = getSession(req);
        return s != null ? (String) s.getAttribute(AppConfig.SESSION_USER_ID) : null;
    }

    /**
     * Devuelve el nombre del usuario en sesión (para la navbar).
     */
    protected String getUserName(HttpServletRequest req) {
        HttpSession s = getSession(req);
        return s != null ? (String) s.getAttribute(AppConfig.SESSION_USER_NAME) : null;
    }

    /**
     * Devuelve el rol del usuario en sesión.
     * Comparar con AppConfig.ROL_ADMIN, ROL_RECEP, ROL_INSTRUCTOR.
     */
    protected String getRolUsuario(HttpServletRequest req) {
        HttpSession s = getSession(req);
        return s != null ? (String) s.getAttribute(AppConfig.SESSION_USER_ROLE) : null;
    }

    /**
     * Verifica si el usuario en sesión tiene rol de administrador.
     * Útil para operaciones exclusivas del Admin dentro de un módulo compartido
     * (ej: cancelar contrato en /contracts es solo Admin).
     */
    protected boolean esAdmin(HttpServletRequest req) {
        return AppConfig.ROL_ADMIN.equals(getRolUsuario(req));
    }

    /**
     * Verifica si el usuario en sesión tiene rol de recepcionista.
     */
    protected boolean esRecepcionista(HttpServletRequest req) {
        return AppConfig.ROL_RECEP.equals(getRolUsuario(req));
    }

    /**
     * Verifica si el usuario en sesión tiene rol de instructor.
     */
    protected boolean esInstructor(HttpServletRequest req) {
        return AppConfig.ROL_INSTRUCTOR.equals(getRolUsuario(req));
    }

    // ── Mensajes para la vista ───────────────────────────────────────────────

    /**
     * Pone un mensaje de error en el request para que el JSP lo muestre.
     * En el JSP: ${not empty errorMsg ? errorMsg : ""}
     *
     * @param req     la request
     * @param mensaje texto del error en español
     */
    protected void setError(HttpServletRequest req, String mensaje) {
        req.setAttribute("errorMsg", mensaje);
    }

    /**
     * Pone un mensaje de éxito en el request para que el JSP lo muestre.
     * En el JSP: ${not empty successMsg ? successMsg : ""}
     *
     * @param req     la request
     * @param mensaje texto de éxito en español
     */
    protected void setSuccess(HttpServletRequest req, String mensaje) {
        req.setAttribute("successMsg", mensaje);
    }

    /**
     * Lee un mensaje de éxito del parámetro GET (después de un redirect PRG).
     * Si existe, lo pone en el request para que el JSP lo muestre.
     *
     * Uso en el controlador hijo:
     *   readSuccessParam(req);   // en el doGet, antes del forward
     */
    protected void readSuccessParam(HttpServletRequest req) {
        String msg = req.getParameter("success");
        if (msg != null && !msg.trim().isEmpty()) {
            req.setAttribute("successMsg", msg);
        }
    }

    // ── Parámetros de request ────────────────────────────────────────────────

    /**
     * Lee un parámetro String del request, devuelve null si está vacío.
     */
    protected String param(HttpServletRequest req, String name) {
        String val = req.getParameter(name);
        return (val == null || val.trim().isEmpty()) ? null : val.trim();
    }

    /**
     * Lee un parámetro int del request.
     * Devuelve el defaultValue si el parámetro no existe o no es un número válido.
     */
    protected int paramInt(HttpServletRequest req, String name, int defaultValue) {
        String val = param(req, name);
        if (val == null) return defaultValue;
        try {
            return Integer.parseInt(val);
        } catch (NumberFormatException e) {
            return defaultValue;
        }
    }

    // ── Responder 403 ────────────────────────────────────────────────────────

    /**
     * Responde 403 Forbidden con un mensaje en español.
     * Usar cuando el rol no tiene permiso para una operación específica
     * dentro de un módulo compartido.
     */
    protected void forbidden(HttpServletResponse resp) throws IOException {
        resp.sendError(HttpServletResponse.SC_FORBIDDEN,
                "No tienes permiso para realizar esta operación.");
    }
}