package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.config.AppConfig;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.util.logging.Logger;

// controlador encargado del cierre de sesión
@WebServlet("/logout")
public class LogoutController extends HttpServlet {

    private static final Logger LOGGER =
            Logger.getLogger(LogoutController.class.getName());

    // ───────────────── GET /logout ────────────────────

    @Override
    protected void doGet(HttpServletRequest req,
                         HttpServletResponse resp)
            throws ServletException, IOException {

        procesarLogout(req, resp);
    }

    // ───────────────── POST /logout ───────────────────

    @Override
    protected void doPost(HttpServletRequest req,
                          HttpServletResponse resp)
            throws ServletException, IOException {

        procesarLogout(req, resp);
    }

    // ───────────────── lógica de logout ───────────────

    private void procesarLogout(HttpServletRequest req,
                                HttpServletResponse resp)
            throws IOException {

        // obtener sesión actual si existe
        HttpSession sesion =
                req.getSession(false);

        if (sesion != null) {

            // obtener datos básicos del usuario
            String userName = (String)
                    sesion.getAttribute(
                            AppConfig.SESSION_USER_NAME
                    );

            String userRole = (String)
                    sesion.getAttribute(
                            AppConfig.SESSION_USER_ROLE
                    );

            // registrar cierre de sesión
            LOGGER.info(
                    "Logout: usuario='"
                            + userName
                            + "' | rol='"
                            + userRole
                            + "'"
            );

            // invalidar sesión completa
            sesion.invalidate();
        }

        // evitar caché del navegador
        resp.setHeader(
                "Cache-Control",
                "no-cache, no-store, must-revalidate"
        );

        resp.setHeader(
                "Pragma",
                "no-cache"
        );

        resp.setDateHeader(
                "Expires",
                0
        );

        // redirigir al login con mensaje de confirmación
        resp.sendRedirect(
                req.getContextPath()
                        + "/login?msg=logout"
        );
    }
}