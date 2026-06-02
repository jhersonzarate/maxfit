package com.mycompany.herramientas.config;

import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;
import java.util.logging.Logger;

// configuración global y listener principal del sistema
@WebListener
public class AppConfig implements ServletContextListener {

    private static final Logger LOGGER =
            Logger.getLogger(AppConfig.class.getName());

    // ─── roles del sistema ─────────────────────────────────────

    // rol administrador
    public static final String ROL_ADMIN = "ROL-ADMIN";

    // rol recepcionista
    public static final String ROL_RECEP = "ROL-RECEP";

    // rol instructor
    public static final String ROL_INSTRUCTOR = "ROL-TRAINER";

    // ─── estados generales ────────────────────────────────────

    // estado activo
    public static final String ESTADO_ACTIVO = "activo";

    // estado inactivo
    public static final String ESTADO_INACTIVO = "inactivo";

    // ─── estados de contratos ─────────────────────────────────

    public static final String CONTRATO_ACTIVO    = "activo";
    public static final String CONTRATO_VENCIDO   = "vencido";
    public static final String CONTRATO_CANCELADO = "cancelado";

    // ─── estados de asistencia ────────────────────────────────

    public static final String ASISTENCIA_ASISTIO   = "asistio";
    public static final String ASISTENCIA_FALTO     = "falto";
    public static final String ASISTENCIA_PENDIENTE = "pendiente";

    // ─── estados de clases ────────────────────────────────────

    public static final String CLASE_VIGENTE    = "vigente";
    public static final String CLASE_SUSPENDIDA = "suspendida";

    // ─── estados de horarios ──────────────────────────────────

    public static final String HORARIO_PROGRAMADO = "programado";
    public static final String HORARIO_CANCELADO  = "cancelado";

    // ─── tipos de documento ───────────────────────────────────

    public static final String TDOC_DNI  = "TDOC-DNI";
    public static final String TDOC_CE   = "TDOC-CE";
    public static final String TDOC_PASS = "TDOC-PASS";

    // ─── métodos de pago ──────────────────────────────────────

    public static final String PAY_EFECTIVO   = "PAY-EFECTIVO";
    public static final String PAY_VISA       = "PAY-VISA";
    public static final String PAY_MASTERCARD = "PAY-MASTERCARD";
    public static final String PAY_YAPE       = "PAY-YAPE";
    public static final String PAY_PLIN       = "PAY-PLIN";
    public static final String PAY_TRANSFER   = "PAY-TRANSFER";

    // ─── cargos ───────────────────────────────────────────────

    public static final String CARGO_ADMIN   = "CARGO-ADM";
    public static final String CARGO_RECEP   = "CARGO-REC";
    public static final String CARGO_TRAINER = "CARGO-TRAINER";

    // ─── tipos de clase ───────────────────────────────────────

    public static final String TCL_CARDIO    = "TCL-CARDIO";
    public static final String TCL_YOGA      = "TCL-YOGA";
    public static final String TCL_BOX       = "TCL-BOX";
    public static final String TCL_FUNCIONAL = "TCL-FUNCIONAL";

    // ─── prefijos para IDs ────────────────────────────────────

    // prefijo clientes
    public static final String PREFIX_CLIENTE = "CLI";

    // prefijo empleados
    public static final String PREFIX_EMPLEADO = "EMP";

    // prefijo contratos
    public static final String PREFIX_CONTRATO = "CON";

    // prefijo asistencias
    public static final String PREFIX_ASISTENCIA = "ASI";

    // prefijo clases
    public static final String PREFIX_CLASE = "CLA";

    // prefijo horarios
    public static final String PREFIX_HORARIO = "HOR";

    // prefijo inscripciones
    public static final String PREFIX_INSCRIPCION = "INS";

    // prefijo usuarios
    public static final String PREFIX_USUARIO = "USR";

    // prefijo metodos de pago
    public static final String PREFIX_METODO_PAGO = "PAY";

    // ─── claves de sesión ─────────────────────────────────────

    public static final String SESSION_USER_ID    = "userId";
    public static final String SESSION_USER_NAME  = "userName";
    public static final String SESSION_USER_ROLE  = "userRole";
    public static final String SESSION_USER_EMAIL = "userEmail";

    // ─── seguridad ────────────────────────────────────────────

    // tiempo máximo de sesión
    public static final int SESSION_TIMEOUT_SECONDS = 1800;

    // costo BCrypt recomendado
    public static final int BCRYPT_COST = 12;

    // ─── paginación ───────────────────────────────────────────

    // tamaño por defecto de tablas
    public static final int PAGE_SIZE_DEFAULT = 20;

    // ─── listener de Tomcat ───────────────────────────────────

    @Override
    public void contextInitialized(ServletContextEvent sce) {

        LOGGER.info("=== MaxFit iniciando ===");

        // validar configuración de base de datos
        if (DatabaseConnection.isConfigured()) {

            boolean ok =
                    DatabaseConnection.testConnection();

            // conexión exitosa
            if (ok) {

                LOGGER.info(
                        "Conexión a gimnasio_db: OK"
                );

            } else {

                // error de conexión
                LOGGER.severe(
                        "Conexión a gimnasio_db: FALLÓ. "
                        + "Verifica SQL Server y las credenciales en db.properties"
                );
            }

        } else {

            // archivo db.properties faltante
            LOGGER.severe(
                    "db.properties no configurado. "
                    + "La aplicación arrancó pero la BD no está disponible."
            );
        }

        LOGGER.info(
                "=== MaxFit listo en: "
                        + sce.getServletContext().getContextPath()
                        + " ==="
        );
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {

        // cerrar conexión global
        DatabaseConnection.closeConnection();

        LOGGER.info("=== MaxFit detenido ===");
    }
}