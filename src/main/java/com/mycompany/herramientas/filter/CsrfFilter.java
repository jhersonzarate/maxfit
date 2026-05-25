package com.mycompany.herramientas.filter;

import com.mycompany.herramientas.util.CsrfUtils;

import javax.servlet.*;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;
import java.util.logging.Logger;

/**
 * Filtro de protección CSRF (Cross-Site Request Forgery).
 *
 * Responsabilidades:
 *   1. En cada GET: genera (o recupera) el token CSRF de la sesión.
 *      Lo pone como atributo de request ("csrfToken") para que los JSP
 *      lo incluyan en los formularios via ${csrfToken}.
 *
 *   2. En cada POST: valida que el token del formulario (_csrf) coincida
 *      con el de la sesión. Si no coincide → responde 403 Forbidden.
 *
 * Rutas excluidas de la validación POST:
 *   - /logout  (usa un token de sesión propio; no tiene form con datos sensibles)
 *
 * Debe declararse en web.xml DESPUÉS de AuthFilter y RoleFilter,
 * o en la misma posición — el orden entre filtros no afecta su correctitud
 * porque cada uno tiene una responsabilidad distinta.
 *
 * Buenas prácticas aplicadas:
 *   - El token se lee desde CsrfUtils (SecureRandom, 256 bits).
 *   - La validación usa comparación de tiempo constante (en CsrfUtils).
 *   - Peticiones GET/HEAD/OPTIONS/TRACE son safe methods → no se validan.
 *   - Se loguea cada fallo con IP y URI para auditoría.
 */
public class CsrfFilter implements Filter {

    private static final Logger LOGGER =
            Logger.getLogger(CsrfFilter.class.getName());

    // métodos HTTP seguros (read-only): no modifican estado → no requieren CSRF
    private static final Set<String> SAFE_METHODS = new HashSet<>(
            Arrays.asList("GET", "HEAD", "OPTIONS", "TRACE")
    );

    // rutas POST que están excluidas de la validación CSRF
    // (logout invalida la sesión completa, lo cual ya protege de CSRF)
    private static final Set<String> RUTAS_EXCLUIDAS = new HashSet<>(
            Arrays.asList("/logout")
    );

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        LOGGER.info("CsrfFilter inicializado — protección CSRF activa.");
    }

    @Override
    public void doFilter(ServletRequest request,
                         ServletResponse response,
                         FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest  req  = (HttpServletRequest) request;
        HttpServletResponse resp = (HttpServletResponse) response;

        String method = req.getMethod().toUpperCase();

        // ruta relativa al context path
        String contextPath = req.getContextPath();
        String uri         = req.getRequestURI();
        String path        = uri.substring(contextPath.length());

        // ── 1. Método seguro (GET, HEAD, etc.) ─────────────────
        // Generar / recuperar el token y exponerlo en el request
        // para que login.jsp y forgot-password.jsp lo usen via ${csrfToken}
        if (SAFE_METHODS.contains(method)) {

            // getOrCreate: si no hay token en sesión, lo genera y lo guarda
            String token = CsrfUtils.getOrCreate(req);

            // lo ponemos en el request para EL en los JSP: ${csrfToken}
            req.setAttribute("csrfToken", token);

            chain.doFilter(request, response);
            return;
        }

        // ── 2. Rutas excluidas de validación POST ───────────────
        if (RUTAS_EXCLUIDAS.contains(path)) {
            chain.doFilter(request, response);
            return;
        }

        // ── 3. POST/PUT/DELETE: validar token ───────────────────
        if (!CsrfUtils.isValid(req)) {

            LOGGER.warning(
                    "CSRF BLOQUEADO | ip=" + req.getRemoteAddr() +
                    " | uri=" + uri +
                    " | method=" + method
            );

            // responder 403 con mensaje claro
            resp.sendError(
                    HttpServletResponse.SC_FORBIDDEN,
                    "Solicitud bloqueada: token de seguridad inválido o ausente. " +
                    "Por favor recarga la página e intenta nuevamente."
            );

            return;
        }

        // token válido → continuar
        chain.doFilter(request, response);
    }

    @Override
    public void destroy() {
        // sin recursos que liberar
    }
}