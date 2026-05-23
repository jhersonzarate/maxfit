package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.config.AppConfig;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

/**
 * Controlador base con helpers compartidos por todos los controladores.
 *
 * Centraliza operaciones repetitivas como:
 *   - Leer datos de sesión (rol, userId, userName)
 *   - Verificar permisos de rol en operaciones sensibles
 *   - Leer parámetros con valor por defecto
 *   - Renderizar vistas con forward
 *   - Responder con JSON para peticiones AJAX
 *   - Manejar mensajes de feedback (éxito/error) entre redirecciones
 *
 * Por qué AbstractController y no una clase utilitaria estática:
 *   Los helpers necesitan acceso al request/response y a la sesión.
 *   Heredar es más limpio que pasar request como argumento a métodos estáticos.
 *   Además, permite sobreescribir comportamientos si un controlador
 *   necesita lógica especial.
 *
 * @author MaxFit
 */
public abstract class AbstractController extends HttpServlet {

    // ─── Helpers de sesión ────────────────────────────────────────────────────

    /**
     * Obtiene el ID del usuario autenticado desde la sesión.
     * @return userId o null si no hay sesión activa
     */
    protected String getSessionUserId(HttpServletRequest req) {
        HttpSession s = req.getSession(false);
        return s != null ? (String) s.getAttribute(AppConfig.SESSION_USER_ID) : null;
    }

    /**
     * Obtiene el nombre del usuario autenticado desde la sesión.
     * @return userName o null si no hay sesión activa
     */
    protected String getSessionUserName(HttpServletRequest req) {
        HttpSession s = req.getSession(false);
        return s != null ? (String) s.getAttribute(AppConfig.SESSION_USER_NAME) : null;
    }

    /**
     * Obtiene el ID del rol del usuario autenticado desde la sesión.
     * @return userRole (ej: "ROL-ADMIN") o null si no hay sesión activa
     */
    protected String getSessionUserRole(HttpServletRequest req) {
        HttpSession s = req.getSession(false);
        return s != null ? (String) s.getAttribute(AppConfig.SESSION_USER_ROLE) : null;
    }

    /**
     * Obtiene el email del usuario autenticado desde la sesión.
     */
    protected String getSessionUserEmail(HttpServletRequest req) {
        HttpSession s = req.getSession(false);
        return s != null ? (String) s.getAttribute(AppConfig.SESSION_USER_EMAIL) : null;
    }

    // ─── Helpers de verificación de rol ──────────────────────────────────────

    /**
     * Verifica si el usuario en sesión tiene el rol de Administrador.
     */
    protected boolean esAdmin(HttpServletRequest req) {
        return AppConfig.ROL_ADMIN.equals(getSessionUserRole(req));
    }

    /**
     * Verifica si el usuario en sesión tiene el rol de Recepcionista.
     */
    protected boolean esRecepcionista(HttpServletRequest req) {
        return AppConfig.ROL_RECEP.equals(getSessionUserRole(req));
    }

    /**
     * Verifica si el usuario en sesión tiene el rol de Instructor.
     */
    protected boolean esInstructor(HttpServletRequest req) {
        return AppConfig.ROL_INSTRUCTOR.equals(getSessionUserRole(req));
    }

    /**
     * Verifica si el usuario tiene uno de los roles indicados.
     * Útil para acciones permitidas a Admin Y Recepcionista.
     *
     * Ejemplo:
     *   if (!tieneRol(req, AppConfig.ROL_ADMIN, AppConfig.ROL_RECEP)) {
     *       resp.sendError(403);
     *       return;
     *   }
     */
    protected boolean tieneRol(HttpServletRequest req, String... roles) {
        String rolActual = getSessionUserRole(req);
        if (rolActual == null) return false;
        for (String r : roles) {
            if (rolActual.equals(r)) return true;
        }
        return false;
    }

    // ─── Helpers de parámetros HTTP ───────────────────────────────────────────

    /**
     * Lee un parámetro String del request.
     * Devuelve null si es null o solo espacios.
     */
    protected String param(HttpServletRequest req, String nombre) {
        String val = req.getParameter(nombre);
        return (val != null && !val.trim().isEmpty()) ? val.trim() : null;
    }

    /**
     * Lee un parámetro String con valor por defecto.
     */
    protected String param(HttpServletRequest req, String nombre, String defecto) {
        String val = param(req, nombre);
        return val != null ? val : defecto;
    }

    /**
     * Lee un parámetro entero del request.
     * Devuelve el valor por defecto si no existe o no es un número válido.
     */
    protected int paramInt(HttpServletRequest req, String nombre, int defecto) {
        String val = param(req, nombre);
        if (val == null) return defecto;
        try {
            return Integer.parseInt(val);
        } catch (NumberFormatException e) {
            return defecto;
        }
    }

    /**
     * Lee la acción del request (parámetro "action").
     * Devuelve "list" como acción por defecto si no se especifica.
     */
    protected String getAction(HttpServletRequest req) {
        return param(req, "action", "list");
    }

    // ─── Helpers de navegación ────────────────────────────────────────────────

    /**
     * Hace forward a una vista JSP.
     * Centraliza el manejo de ServletException/IOException para los controllers.
     */
    protected void irA(String vista, HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.getRequestDispatcher(vista).forward(req, resp);
    }

    /**
     * Redirige a una URL relativa al context path.
     * Ejemplo: redirigirA("/clients", req, resp)
     */
    protected void redirigirA(String ruta, HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        resp.sendRedirect(req.getContextPath() + ruta);
    }

    // ─── Helpers de mensajes entre redirecciones ──────────────────────────────

    /**
     * Guarda un mensaje de ÉXITO en la sesión para mostrarlo en la siguiente vista.
     * Se usa antes de un sendRedirect() (Post-Redirect-Get pattern).
     *
     * En el JSP se lee con:
     *   <c:if test="${not empty successMsg}">...</c:if>
     */
    protected void mensajeExito(HttpServletRequest req, String mensaje) {
        req.getSession(true).setAttribute("successMsg", mensaje);
    }

    /**
     * Guarda un mensaje de ERROR en la sesión para mostrarlo en la siguiente vista.
     */
    protected void mensajeError(HttpServletRequest req, String mensaje) {
        req.getSession(true).setAttribute("errorMsg", mensaje);
    }

    /**
     * Lee y elimina el mensaje de éxito de la sesión (flash message).
     * Llamar desde el controlador antes del forward para pasarlo como atributo.
     */
    protected String consumirMensajeExito(HttpServletRequest req) {
        HttpSession s = req.getSession(false);
        if (s == null) return null;
        String msg = (String) s.getAttribute("successMsg");
        s.removeAttribute("successMsg");
        return msg;
    }

    /**
     * Lee y elimina el mensaje de error de la sesión (flash message).
     */
    protected String consumirMensajeError(HttpServletRequest req) {
        HttpSession s = req.getSession(false);
        if (s == null) return null;
        String msg = (String) s.getAttribute("errorMsg");
        s.removeAttribute("errorMsg");
        return msg;
    }

    /**
     * Transfiere los flash messages de sesión a atributos de request.
     * Llamar al inicio de doGet() para que los JSP puedan leerlos.
     *
     * Uso en cualquier doGet():
     *   transferirFlashMessages(req);
     */
    protected void transferirFlashMessages(HttpServletRequest req) {
        String exito = consumirMensajeExito(req);
        String error = consumirMensajeError(req);
        if (exito != null) req.setAttribute("successMsg", exito);
        if (error != null) req.setAttribute("errorMsg",   error);
    }

    // ─── Helper de respuesta JSON (para peticiones AJAX) ─────────────────────

    /**
     * Responde con JSON simple para peticiones AJAX.
     * Evita depender de una librería externa (Jackson, Gson) para respuestas simples.
     *
     * Ejemplo de uso:
     *   responderJson(resp, "{\"ok\":true,\"mensaje\":\"Registrado correctamente\"}");
     */
    protected void responderJson(HttpServletResponse resp, String json)
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setCharacterEncoding("UTF-8");
        resp.getWriter().write(json);
    }

    /**
     * Responde con JSON de resultado simple: {"ok": true/false, "mensaje": "..."}
     */
    protected void responderJson(HttpServletResponse resp,
                                  boolean ok, String mensaje)
            throws IOException {
        String safeMsg = mensaje != null
                ? mensaje.replace("\"", "'") : "";
        responderJson(resp, "{\"ok\":" + ok + ",\"mensaje\":\"" + safeMsg + "\"}");
    }

    // ─── Helper de error HTTP ─────────────────────────────────────────────────

    /**
     * Envía un error HTTP 403 Forbidden con mensaje amigable.
     * Usar cuando un usuario autenticado intenta una acción fuera de su rol.
     */
    protected void forbidden(HttpServletResponse resp) throws IOException {
        resp.sendError(HttpServletResponse.SC_FORBIDDEN,
                "No tienes permiso para realizar esta acción.");
    }

    /**
     * Envía un error HTTP 400 Bad Request con mensaje amigable.
     */
    protected void badRequest(HttpServletResponse resp, String motivo) throws IOException {
        resp.sendError(HttpServletResponse.SC_BAD_REQUEST, motivo);
    }
}