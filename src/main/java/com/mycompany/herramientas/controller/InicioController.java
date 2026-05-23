package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.dao.ClienteDAO;
import com.mycompany.herramientas.dao.ContratoDAO;
import com.mycompany.herramientas.dao.EmpleadoDAO;
import com.mycompany.herramientas.dao.MembresiaDAO;
import com.mycompany.herramientas.service.ContratoService;
import com.mycompany.herramientas.view.ViewRoutes;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Controlador del panel principal del Administrador (RF dashboard).
 *
 * GET /inicio → carga KPIs y listas de widgets, hace forward a inicio.jsp
 *
 * Widgets del panel Admin:
 *   - Total clientes registrados
 *   - Total empleados
 *   - Contratos activos
 *   - Planes de membresía disponibles
 *   - Lista de contratos próximos a vencer (en los próximos 7 días)
 *
 * También ejecuta actualizarVencidos() al cargar para mantener estados al día.
 */
public class InicioController extends AbstractController {

    private static final Logger LOGGER = Logger.getLogger(InicioController.class.getName());

    private final ClienteDAO       clienteDAO       = new ClienteDAO();
    private final EmpleadoDAO      empleadoDAO      = new EmpleadoDAO();
    private final ContratoDAO      contratoDAO      = new ContratoDAO();
    private final MembresiaDAO     membresiaDAO     = new MembresiaDAO();
    private final ContratoService  contratoService  = new ContratoService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // Actualizar contratos vencidos al cargar el panel
        contratoService.actualizarVencidos();

        try {
            // KPIs principales
            req.setAttribute("totalClientes",   clienteDAO.count());
            req.setAttribute("totalEmpleados",  empleadoDAO.count());
            req.setAttribute("contratosActivos",contratoDAO.countActivos());
            req.setAttribute("totalMembresias", membresiaDAO.count());
            req.setAttribute("ingresosMes",     contratoDAO.getIngresosMesActual());

            // Widget: contratos que vencen en los próximos 7 días
            req.setAttribute("proximosVencer",
                    contratoService.obtenerProximosAVencer(7));

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al cargar datos del panel Admin", e);
            // Poner valores neutros para que el JSP no falle
            req.setAttribute("totalClientes",    0);
            req.setAttribute("totalEmpleados",   0);
            req.setAttribute("contratosActivos", 0);
            req.setAttribute("totalMembresias",  0);
            setError(req, "Error al cargar algunos datos del panel. Intenta refrescar la página.");
        }

        req.setAttribute("paginaTitulo", "Panel de Administración — MaxFit");
        forward(req, resp, ViewRoutes.INICIO_ADMIN);
    }
}