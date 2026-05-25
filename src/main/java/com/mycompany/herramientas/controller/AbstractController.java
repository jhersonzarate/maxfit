package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.config.AppConfig;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

// controlador base con helpers reutilizables
public abstract class AbstractController extends HttpServlet {

    // ─── helpers de sesión ─────────────────────────────────────

    // obtener id del usuario autenticado
    protected String getSessionUserId(HttpServletRequest req) {

        HttpSession s = req.getSession(false);

        return s != null
                ? (String) s.getAttribute(AppConfig.SESSION_USER_ID)
                : null;
    }

    // obtener nombre del usuario autenticado
    protected String getSessionUserName(HttpServletRequest req) {

        HttpSession s = req.getSession(false);

        return s != null
                ? (String) s.getAttribute(AppConfig.SESSION_USER_NAME)
                : null;
    }

    // obtener rol del usuario autenticado
    protected String getSessionUserRole(HttpServletRequest req) {

        HttpSession s = req.getSession(false);

        return s != null
                ? (String) s.getAttribute(AppConfig.SESSION_USER_ROLE)
                : null;
    }

    // obtener email del usuario autenticado
    protected String getSessionUserEmail(HttpServletRequest req) {

        HttpSession s = req.getSession(false);

        return s != null
                ? (String) s.getAttribute(AppConfig.SESSION_USER_EMAIL)
                : null;
    }

    // ─── helpers de roles ──────────────────────────────────────

    // verificar si el usuario es admin
    protected boolean esAdmin(HttpServletRequest req) {
        return AppConfig.ROL_ADMIN.equals(getSessionUserRole(req));
    }

    // verificar si el usuario es recepcionista
    protected boolean esRecepcionista(HttpServletRequest req) {
        return AppConfig.ROL_RECEP.equals(getSessionUserRole(req));
    }

    // verificar si el usuario es instructor
    protected boolean esInstructor(HttpServletRequest req) {
        return AppConfig.ROL_INSTRUCTOR.equals(getSessionUserRole(req));
    }

    // verificar si el usuario tiene alguno de los roles indicados
    protected boolean tieneRol(HttpServletRequest req, String... roles) {

        String rolActual = getSessionUserRole(req);

        // si no hay rol en sesión -> retorno false
        if (rolActual == null) {
            return false;
        }

        // recorrer roles permitidos
        for (String r : roles) {

            if (rolActual.equals(r)) {
                return true;
            }
        }

        return false;
    }

    // ─── helpers de parámetros http ────────────────────────────

    // leer parámetro string del request
    protected String param(HttpServletRequest req, String nombre) {

        String val = req.getParameter(nombre);

        return (val != null && !val.trim().isEmpty())
                ? val.trim()
                : null;
    }

    // leer parámetro con valor por defecto
    protected String param(HttpServletRequest req,
                           String nombre,
                           String defecto) {

        String val = param(req, nombre);

        return val != null ? val : defecto;
    }

    // leer parámetro entero de forma segura
    protected int paramInt(HttpServletRequest req,
                           String nombre,
                           int defecto) {

        String val = param(req, nombre);

        // si no existe -> retorno valor por defecto
        if (val == null) {
            return defecto;
        }

        try {

            return Integer.parseInt(val);

        } catch (NumberFormatException e) {

            // si no es número válido -> retorno defecto
            return defecto;
        }
    }

    // obtener acción enviada en el request
    protected String getAction(HttpServletRequest req) {
        return param(req, "action", "list");
    }

    // ─── helpers de navegación ─────────────────────────────────

    // hacer forward hacia una vista jsp
    protected void irA(String vista,
                       HttpServletRequest req,
                       HttpServletResponse resp)
            throws ServletException, IOException {

        req.getRequestDispatcher(vista)
                .forward(req, resp);
    }

    // redirigir a una ruta relativa al context path
    protected void redirigirA(String ruta,
                              HttpServletRequest req,
                              HttpServletResponse resp)
            throws IOException {

        resp.sendRedirect(req.getContextPath() + ruta);
    }

    // ─── helpers de mensajes flash ─────────────────────────────

    // guardar mensaje de éxito en sesión
    protected void mensajeExito(HttpServletRequest req,
                                String mensaje) {

        req.getSession(true)
                .setAttribute("successMsg", mensaje);
    }

    // guardar mensaje de error en sesión
    protected void mensajeError(HttpServletRequest req,
                                String mensaje) {

        req.getSession(true)
                .setAttribute("errorMsg", mensaje);
    }

    // leer y eliminar mensaje de éxito
    protected String consumirMensajeExito(HttpServletRequest req) {

        HttpSession s = req.getSession(false);

        if (s == null) {
            return null;
        }

        String msg = (String) s.getAttribute("successMsg");

        s.removeAttribute("successMsg");

        return msg;
    }

    // leer y eliminar mensaje de error
    protected String consumirMensajeError(HttpServletRequest req) {

        HttpSession s = req.getSession(false);

        if (s == null) {
            return null;
        }

        String msg = (String) s.getAttribute("errorMsg");

        s.removeAttribute("errorMsg");

        return msg;
    }

    // transferir flash messages al request
    protected void transferirFlashMessages(HttpServletRequest req) {

        String exito = consumirMensajeExito(req);
        String error = consumirMensajeError(req);

        if (exito != null) {
            req.setAttribute("successMsg", exito);
        }

        if (error != null) {
            req.setAttribute("errorMsg", error);
        }
    }

    // ─── helpers json ──────────────────────────────────────────

    // responder json simple para peticiones ajax
    protected void responderJson(HttpServletResponse resp,
                                 String json)
            throws IOException {

        resp.setContentType("application/json;charset=UTF-8");

        resp.setCharacterEncoding("UTF-8");

        resp.getWriter().write(json);
    }

    // responder json con estructura ok/mensaje
    protected void responderJson(HttpServletResponse resp,
                                 boolean ok,
                                 String mensaje)
            throws IOException {

        String safeMsg = mensaje != null
                ? mensaje.replace("\"", "'")
                : "";

        responderJson(
                resp,
                "{\"ok\":" + ok +
                ",\"mensaje\":\"" + safeMsg + "\"}"
        );
    }

    // ─── helpers de errores http ───────────────────────────────

    // enviar error 403 forbidden
    protected void forbidden(HttpServletResponse resp)
            throws IOException {

        resp.sendError(
                HttpServletResponse.SC_FORBIDDEN,
                "No tienes permiso para realizar esta acción."
        );
    }

    // enviar error 400 bad request
    protected void badRequest(HttpServletResponse resp,
                              String motivo)
            throws IOException {

        resp.sendError(
                HttpServletResponse.SC_BAD_REQUEST,
                motivo
        );
    }
}