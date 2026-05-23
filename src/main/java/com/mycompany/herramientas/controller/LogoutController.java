package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.config.DatabaseConnection;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

/**
 * Controlador de cierre de sesión.
 *
 * GET /logout  → invalida sesión y redirige al login.
 * POST /logout → mismo comportamiento (soporte para botón de formulario).
 *
 * Seguridad:
 *   - session.invalidate() elimina TODOS los atributos de la sesión.
 *   - Se cierra también la conexión ThreadLocal de BD si quedó abierta.
 *   - No hay información sensible en la URL de redirect.
 */
public class LogoutController extends AbstractController {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        cerrarSesion(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        cerrarSesion(req, resp);
    }

    private void cerrarSesion(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        // Cerrar conexión de BD del hilo actual si quedó abierta por algún error
        DatabaseConnection.closeConnection();

        // Invalidar la sesión HTTP — elimina todos los atributos
        HttpSession session = req.getSession(false);
        if (session != null) {
            session.invalidate();
        }

        // Redirigir al login
        redirect(req, resp, "/login");
    }
}