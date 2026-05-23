package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.config.AppConfig;
import com.mycompany.herramientas.view.RoleRoutes;
import com.mycompany.herramientas.view.ViewRoutes;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

/**
 * Controlador de la página pública de bienvenida (/home).
 *
 * GET /home → si tiene sesión activa: redirect a su dashboard.
 *             si no tiene sesión:     muestra la página de bienvenida pública.
 *
 * Esta ruta está en RUTAS_PUBLICAS de AuthFilter — no requiere sesión.
 */
public class HomeController extends AbstractController {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // Si ya está autenticado, ir directo a su página según rol
        HttpSession session = getSession(req);
        if (session != null && session.getAttribute(AppConfig.SESSION_USER_NAME) != null) {
            String rol = (String) session.getAttribute(AppConfig.SESSION_USER_ROLE);
            redirect(req, resp, RoleRoutes.getUrlInicio(rol));
            return;
        }

        // Sin sesión → mostrar landing page pública
        forward(req, resp, ViewRoutes.HOME_INDEX);
    }
}