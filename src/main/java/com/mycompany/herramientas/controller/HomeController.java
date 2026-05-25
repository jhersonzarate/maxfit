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

// página pública principal del sistema
@WebServlet("/home")
public class HomeController extends HttpServlet {

    // ───────────────── GET /home ──────────────────────

    @Override
    protected void doGet(HttpServletRequest req,
                         HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession sesion = req.getSession(false);

        // si ya inició sesión → ir a su dashboard
        if (sesion != null
                && sesion.getAttribute(AppConfig.SESSION_USER_NAME) != null) {

            String rol = (String)
                    sesion.getAttribute(AppConfig.SESSION_USER_ROLE);

            resp.sendRedirect(
                    req.getContextPath()
                            + RoleRoutes.getUrlInicio(rol)
            );

            return;
        }

        // usuario no autenticado → mostrar landing pública
        req.getRequestDispatcher(
                ViewRoutes.HOME_INDEX
        ).forward(req, resp);
    }
}