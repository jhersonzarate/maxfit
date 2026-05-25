package com.mycompany.herramientas.filter;

import com.mycompany.herramientas.config.AppConfig;

import javax.servlet.*;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

// filtro que controla acceso según el rol del usuario
public class RoleFilter implements Filter {

    // mapa: ruta -> roles permitidos
    private static final Map<String, Set<String>> ACCESOS = new HashMap<>();

    static {

        // solo admin
        allow("/inicio",          AppConfig.ROL_ADMIN);
        allow("/employees",       AppConfig.ROL_ADMIN);
        allow("/users",           AppConfig.ROL_ADMIN);
        allow("/payment-methods", AppConfig.ROL_ADMIN);
        allow("/reports",         AppConfig.ROL_ADMIN);

        // solo recepcionista
        allow("/dashboard",       AppConfig.ROL_RECEP);

        // solo instructor
        allow("/instructor",      AppConfig.ROL_INSTRUCTOR);

        // admin + recepcionista
        allow("/clients",
                AppConfig.ROL_ADMIN,
                AppConfig.ROL_RECEP);

        allow("/contracts",
                AppConfig.ROL_ADMIN,
                AppConfig.ROL_RECEP);

        allow("/attendance",
                AppConfig.ROL_ADMIN,
                AppConfig.ROL_RECEP);

        allow("/memberships",
                AppConfig.ROL_ADMIN,
                AppConfig.ROL_RECEP);

        // todos los roles principales
        allow("/schedules",
                AppConfig.ROL_ADMIN,
                AppConfig.ROL_RECEP,
                AppConfig.ROL_INSTRUCTOR);

        allow("/calendar",
                AppConfig.ROL_ADMIN,
                AppConfig.ROL_RECEP,
                AppConfig.ROL_INSTRUCTOR);
    }

    // helper para registrar permisos de forma limpia
    private static void allow(String ruta, String... roles) {

        Set<String> set = new HashSet<>();

        for (String rol : roles) {
            set.add(rol);
        }

        ACCESOS.put(ruta, set);
    }

    // ─── init ────────────────────────────────────────────────

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        // no se necesita configuración inicial
    }

    // ─── filtro principal ────────────────────────────────────

    @Override
    public void doFilter(ServletRequest request, ServletResponse response,
                         FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest  req  = (HttpServletRequest) request;
        HttpServletResponse resp = (HttpServletResponse) response;

        String contextPath = req.getContextPath();
        String requestURI  = req.getRequestURI();

        // ruta sin el context path
        String path = requestURI.substring(contextPath.length());

        // si la ruta no tiene restricciones -> dejar pasar
        if (!ACCESOS.containsKey(path)) {

            chain.doFilter(request, response);
            return;
        }

        // obtener sesión actual
        HttpSession session = req.getSession(false);

        // seguridad extra por si AuthFilter no interceptó
        if (session == null) {

            resp.sendRedirect(contextPath + "/login");
            return;
        }

        // rol guardado en sesión
        String rolUsuario = (String)
                session.getAttribute(AppConfig.SESSION_USER_ROLE);

        // roles permitidos para la ruta
        Set<String> rolesPermitidos = ACCESOS.get(path);

        // validar acceso
        if (rolesPermitidos != null
                && rolesPermitidos.contains(rolUsuario)) {

            // acceso permitido
            chain.doFilter(request, response);

        } else {

            // acceso denegado
            resp.sendError(
                    HttpServletResponse.SC_FORBIDDEN,

                    "No tienes permiso para acceder a esta sección. "
                    + "Contacta al administrador si crees que es un error."
            );
        }
    }

    // ─── destroy ─────────────────────────────────────────────

    @Override
    public void destroy() {
        // no hay recursos que liberar
    }
}