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

// filtro global de autenticación
public class AuthFilter implements Filter {

    // ─── rutas públicas ────────────────────────────────────────

    // rutas accesibles sin iniciar sesión
    private static final Set<String> RUTAS_PUBLICAS =
            new HashSet<>(Arrays.asList(

                    "/login",
                    "/logout",
                    "/forgot-password",
                    "/home"
            ));

    // prefijos públicos para recursos estáticos
    private static final Set<String> PREFIJOS_PUBLICOS =
            new HashSet<>(Arrays.asList(

                    "/static/",
                    "/favicon"
            ));

    @Override
    public void init(FilterConfig filterConfig)
            throws ServletException {

        // no se necesita inicialización
    }

    @Override
    public void doFilter(
            ServletRequest request,
            ServletResponse response,
            FilterChain chain
    ) throws IOException, ServletException {

        HttpServletRequest req =
                (HttpServletRequest) request;

        HttpServletResponse resp =
                (HttpServletResponse) response;

        // contexto de la aplicación
        String contextPath =
                req.getContextPath();

        // URI completa
        String requestURI =
                req.getRequestURI();

        // ruta relativa
        String path =
                requestURI.substring(
                        contextPath.length()
                );

        // ─── rutas públicas exactas ───────────────────────────

        if (RUTAS_PUBLICAS.contains(path)) {

            chain.doFilter(request, response);

            return;
        }

        // ─── recursos públicos ───────────────────────────────

        for (String prefijo : PREFIJOS_PUBLICOS) {

            // permitir css, js e imágenes
            if (path.startsWith(prefijo)) {

                chain.doFilter(request, response);

                return;
            }
        }

        // ─── raíz e index ────────────────────────────────────

        if (path.isEmpty()
                || path.equals("/")
                || path.equals("/index.jsp")) {

            chain.doFilter(request, response);

            return;
        }

        // ─── validar sesión activa ───────────────────────────

        // false = no crear sesión nueva
        HttpSession session =
                req.getSession(false);

        boolean autenticado =
                session != null
                && session.getAttribute(
                        AppConfig.SESSION_USER_NAME
                ) != null;

        // usuario autenticado
        if (autenticado) {

            chain.doFilter(request, response);

        } else {

            // ─── guardar URL original ────────────────────────

            String urlOriginal =
                    req.getRequestURI();

            String query =
                    req.getQueryString();

            // agregar query string si existe
            if (query != null) {

                urlOriginal += "?" + query;
            }

            // evitar guardar recursos estáticos
            if (!urlOriginal.contains(".")) {

                req.getSession(true).setAttribute(
                        "redirectAfterLogin",
                        urlOriginal
                );
            }

            // redirigir al login
            resp.sendRedirect(
                    contextPath + "/login"
            );
        }
    }

    @Override
    public void destroy() {

        // no hay recursos que liberar
    }
}