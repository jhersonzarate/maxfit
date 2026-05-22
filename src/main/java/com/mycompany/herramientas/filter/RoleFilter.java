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

/**
 * Filtro de control de acceso por rol (segunda línea de defensa).
 *
 * Se ejecuta DESPUÉS de AuthFilter (que ya garantizó que hay sesión).
 * Verifica que el rol del usuario en sesión tenga permiso para la ruta solicitada.
 * Si no tiene permiso → responde 403 Forbidden.
 *
 * Tabla de accesos (basada en el documento de requerimientos):
 *
 *   Ruta               Admin  Recep  Instructor
 *   /inicio            ✓      ✗      ✗
 *   /dashboard         ✗      ✓      ✗
 *   /instructor        ✗      ✗      ✓
 *   /clients           ✓      ✓      ✗
 *   /contracts         ✓      ✓      ✗
 *   /attendance        ✓      ✓      ✗
 *   /memberships       ✓      ✓(R)   ✗
 *   /schedules         ✓      ✓(R)   ✓(R)
 *   /calendar          ✓      ✓      ✓
 *   /employees         ✓      ✗      ✗
 *   /users             ✓      ✗      ✗
 *   /payment-methods   ✓      ✗      ✗
 *   /reports           ✓      ✗      ✗
 *
 * (R) = solo lectura, controlado en el propio controlador con el rol de sesión.
 * Este filtro solo controla ACCESO a la ruta, no el nivel de operación dentro de ella.
 *
 * Registro en web.xml (debe ir DESPUÉS de AuthFilter):
 *   <filter-name>RoleFilter</filter-name>
 *   <url-pattern>/*</url-pattern>
 */
public class RoleFilter implements Filter {

    /**
     * Mapa de rutas restringidas → conjunto de roles que SÍ pueden acceder.
     * Si una ruta no aparece en este mapa, cualquier usuario autenticado puede acceder.
     */
    private static final Map<String, Set<String>> ACCESOS = new HashMap<>();

    static {
        // Solo Admin
        allow("/inicio",           AppConfig.ROL_ADMIN);
        allow("/employees",        AppConfig.ROL_ADMIN);
        allow("/users",            AppConfig.ROL_ADMIN);
        allow("/payment-methods",  AppConfig.ROL_ADMIN);
        allow("/reports",          AppConfig.ROL_ADMIN);

        // Solo Recepcionista
        allow("/dashboard",        AppConfig.ROL_RECEP);

        // Solo Instructor
        allow("/instructor",       AppConfig.ROL_INSTRUCTOR);

        // Admin + Recepcionista
        allow("/clients",          AppConfig.ROL_ADMIN, AppConfig.ROL_RECEP);
        allow("/contracts",        AppConfig.ROL_ADMIN, AppConfig.ROL_RECEP);
        allow("/attendance",       AppConfig.ROL_ADMIN, AppConfig.ROL_RECEP);
        allow("/memberships",      AppConfig.ROL_ADMIN, AppConfig.ROL_RECEP);

        // Admin + Recepcionista + Instructor
        allow("/schedules",        AppConfig.ROL_ADMIN, AppConfig.ROL_RECEP, AppConfig.ROL_INSTRUCTOR);
        allow("/calendar",         AppConfig.ROL_ADMIN, AppConfig.ROL_RECEP, AppConfig.ROL_INSTRUCTOR);
    }

    /** Helper para cargar el mapa de accesos de forma legible. */
    private static void allow(String ruta, String... roles) {
        Set<String> set = new HashSet<>();
        for (String rol : roles) set.add(rol);
        ACCESOS.put(ruta, set);
    }

    // ─────────────────────────────────────────────────────────────────────────

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        // No se necesita inicialización
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response,
                         FilterChain chain) throws IOException, ServletException {

        HttpServletRequest  req  = (HttpServletRequest)  request;
        HttpServletResponse resp = (HttpServletResponse) response;

        String contextPath = req.getContextPath();
        String requestURI  = req.getRequestURI();
        String path        = requestURI.substring(contextPath.length());

        // ── 1. Si la ruta no está en el mapa, dejar pasar (ruta libre o pública) ──
        if (!ACCESOS.containsKey(path)) {
            chain.doFilter(request, response);
            return;
        }

        // ── 2. Obtener el rol del usuario en sesión ───────────────────────────
        HttpSession session = req.getSession(false);
        if (session == null) {
            // AuthFilter debería haber capturado esto antes, pero por seguridad:
            resp.sendRedirect(contextPath + "/login");
            return;
        }

        String rolUsuario = (String) session.getAttribute(AppConfig.SESSION_USER_ROLE);

        // ── 3. Verificar si el rol tiene permiso ─────────────────────────────
        Set<String> rolesPermitidos = ACCESOS.get(path);

        if (rolesPermitidos != null && rolesPermitidos.contains(rolUsuario)) {
            // Tiene permiso → continuar
            chain.doFilter(request, response);
        } else {
            // No tiene permiso → 403 Forbidden
            // Se podría redirigir a una página de error personalizada
            resp.sendError(HttpServletResponse.SC_FORBIDDEN,
                    "No tienes permiso para acceder a esta sección. "
                    + "Contacta al administrador si crees que es un error.");
        }
    }

    @Override
    public void destroy() {
        // No hay recursos que liberar
    }
}