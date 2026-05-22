package com.mycompany.herramientas.filter;

import com.mycompany.herramientas.config.AppConfig;

import javax.servlet.*;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

/**
 * Filtro de autenticación global (primera línea de defensa).
 *
 * Se ejecuta ANTES que cualquier controlador para TODAS las rutas (/*).
 * Verifica que exista una sesión activa con userName.
 * Si no hay sesión → redirige a /login.
 * Si hay sesión   → deja pasar al siguiente filtro o controlador.
 *
 * Rutas públicas (no requieren sesión):
 *   /login, /logout, /forgot-password, /home, /static/*, index.jsp
 *
 * Por qué un Filter y no verificar en cada Servlet:
 *   - Un solo punto de control → imposible olvidarse de proteger una ruta nueva.
 *   - Si se agrega un controlador nuevo, queda automáticamente protegido.
 *   - Elimina el código repetido de "if session == null → redirect login" en cada servlet.
 *
 * Registro en web.xml (orden importa — debe ir antes que RoleFilter):
 *   <filter-name>AuthFilter</filter-name>
 *   <url-pattern>/*</url-pattern>
 */
public class AuthFilter implements Filter {

    /**
     * Rutas accesibles SIN sesión iniciada.
     * Usar el path relativo al contexto (sin el contextPath).
     */
    private static final Set<String> RUTAS_PUBLICAS = new HashSet<>(Arrays.asList(
            "/login",
            "/logout",
            "/forgot-password",
            "/home"
    ));

    /**
     * Prefijos de rutas públicas (recursos estáticos y raíz).
     * Cualquier ruta que EMPIECE con estos prefijos se deja pasar sin autenticación.
     */
    private static final Set<String> PREFIJOS_PUBLICOS = new HashSet<>(Arrays.asList(
            "/static/",   // CSS, JS, imágenes
            "/favicon"    // favicon.ico
    ));

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        // No se necesita inicialización
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response,
                         FilterChain chain) throws IOException, ServletException {

        HttpServletRequest  req  = (HttpServletRequest)  request;
        HttpServletResponse resp = (HttpServletResponse) response;

        String contextPath = req.getContextPath();         // Ej: /Herramientas
        String requestURI  = req.getRequestURI();          // Ej: /Herramientas/clients
        String path        = requestURI.substring(contextPath.length()); // Ej: /clients

        // ── 1. Rutas públicas exactas ────────────────────────────────────────
        if (RUTAS_PUBLICAS.contains(path)) {
            chain.doFilter(request, response);
            return;
        }

        // ── 2. Prefijos públicos (estáticos, favicon) ────────────────────────
        for (String prefijo : PREFIJOS_PUBLICOS) {
            if (path.startsWith(prefijo)) {
                chain.doFilter(request, response);
                return;
            }
        }

        // ── 3. Raíz del contexto y index.jsp ────────────────────────────────
        if (path.isEmpty() || path.equals("/") || path.equals("/index.jsp")) {
            chain.doFilter(request, response);
            return;
        }

        // ── 4. Verificar sesión activa ───────────────────────────────────────
        HttpSession session = req.getSession(false); // false = no crear sesión nueva

        boolean autenticado = session != null
                && session.getAttribute(AppConfig.SESSION_USER_NAME) != null;

        if (autenticado) {
            // Sesión válida → continuar al siguiente filtro o controlador
            chain.doFilter(request, response);
        } else {
            // Sin sesión → redirigir al login
            // Se guarda la URL original para poder redirigir después del login (opcional)
            String urlOriginal = req.getRequestURI();
            String query       = req.getQueryString();
            if (query != null) urlOriginal += "?" + query;

            // Solo guardar si no es una petición de recurso
            if (!urlOriginal.contains(".")) {
                req.getSession(true).setAttribute("redirectAfterLogin", urlOriginal);
            }

            resp.sendRedirect(contextPath + "/login");
        }
    }

    @Override
    public void destroy() {
        // No hay recursos que liberar
    }
}