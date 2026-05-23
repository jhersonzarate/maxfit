package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.config.AppConfig;
import com.mycompany.herramientas.view.RoleRoutes;
import com.mycompany.herramientas.view.ViewRoutes;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

/**
 * Controlador de la página pública de inicio (/home).
 *
 * GET /home → muestra la landing page pública (index.jsp en views/home/)
 *
 * Si el usuario ya tiene sesión activa se redirige directamente
 * al dashboard de su rol, evitando que vea la pantalla de bienvenida
 * sin necesidad.
 *
 * Esta ruta está en la lista de RUTAS_PUBLICAS del AuthFilter,
 * por lo que no requiere sesión para accederse.
 *
 * @author MaxFit
 */
@WebServlet("/home")
public class HomeController extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // Si ya tiene sesión → redirigir al inicio de su rol
        HttpSession sesion = req.getSession(false);
        if (sesion != null
                && sesion.getAttribute(AppConfig.SESSION_USER_NAME) != null) {

            String rol = (String) sesion.getAttribute(AppConfig.SESSION_USER_ROLE);
            resp.sendRedirect(req.getContextPath() + RoleRoutes.getUrlInicio(rol));
            return;
        }

        // Sin sesión → mostrar página pública de bienvenida
        req.getRequestDispatcher(ViewRoutes.HOME_INDEX).forward(req, resp);
    }
}