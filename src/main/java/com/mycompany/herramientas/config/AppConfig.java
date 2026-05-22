package com.mycompany.herramientas.config;

import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;
import java.util.logging.Logger;

/**
 * Constantes globales del sistema MaxFit y listener de arranque.
 *
 * Como implementa ServletContextListener, Tomcat la llama automáticamente
 * cuando arranca la aplicación (contextInitialized) y cuando se apaga
 * (contextDestroyed). Es el lugar ideal para verificar la BD al inicio
 * y para liberar recursos al cerrar.
 *
 * Las constantes aquí centralizadas evitan strings sueltos en los DAOs
 * y controllers (IDs de catálogos, roles, estados, etc.).
 *
 * @author MaxFit
 */
@WebListener
public class AppConfig implements ServletContextListener {

    private static final Logger LOGGER =
            Logger.getLogger(AppConfig.class.getName());

    // -----------------------------------------------------------------------
    // Roles del sistema (deben coincidir con la tabla Roles en la BD)
    // -----------------------------------------------------------------------
    public static final String ROL_ADMIN      = "ROL-ADMIN";
    public static final String ROL_RECEP      = "ROL-RECEP";
    public static final String ROL_INSTRUCTOR = "ROL-TRAINER";

    // -----------------------------------------------------------------------
    // Estados comunes reutilizados en múltiples tablas
    // -----------------------------------------------------------------------
    public static final String ESTADO_ACTIVO   = "activo";
    public static final String ESTADO_INACTIVO = "inactivo";

    // Estados específicos de Contratos
    public static final String CONTRATO_ACTIVO    = "activo";
    public static final String CONTRATO_VENCIDO   = "vencido";
    public static final String CONTRATO_CANCELADO = "cancelado";

    // Estados de Asistencia
    public static final String ASISTENCIA_ASISTIO  = "asistio";
    public static final String ASISTENCIA_FALTO    = "falto";
    public static final String ASISTENCIA_PENDIENTE = "pendiente";

    // Estados de Clases
    public static final String CLASE_VIGENTE    = "vigente";
    public static final String CLASE_SUSPENDIDA = "suspendida";

    // Estados de Horarios
    public static final String HORARIO_PROGRAMADO = "programado";
    public static final String HORARIO_CANCELADO  = "cancelado";

    // -----------------------------------------------------------------------
    // IDs de catálogos fijos (coinciden exactamente con los INSERT en la BD)
    // -----------------------------------------------------------------------

    // Tipos de documento
    public static final String TDOC_DNI  = "TDOC-DNI";
    public static final String TDOC_CE   = "TDOC-CE";
    public static final String TDOC_PASS = "TDOC-PASS";

    // Métodos de pago
    public static final String PAY_EFECTIVO   = "PAY-EFECTIVO";
    public static final String PAY_VISA       = "PAY-VISA";
    public static final String PAY_MASTERCARD = "PAY-MASTERCARD";
    public static final String PAY_YAPE       = "PAY-YAPE";
    public static final String PAY_PLIN       = "PAY-PLIN";
    public static final String PAY_TRANSFER   = "PAY-TRANSFER";

    // Cargos
    public static final String CARGO_ADMIN   = "CARGO-ADM";
    public static final String CARGO_RECEP   = "CARGO-REC";
    public static final String CARGO_TRAINER = "CARGO-TRAINER";

    // Tipos de clase
    public static final String TCL_CARDIO    = "TCL-CARDIO";
    public static final String TCL_YOGA      = "TCL-YOGA";
    public static final String TCL_BOX       = "TCL-BOX";
    public static final String TCL_FUNCIONAL = "TCL-FUNCIONAL";

    // -----------------------------------------------------------------------
    // Prefijos para generación de IDs transaccionales
    // Formato: PREFIJO-AÑO-CORRELATIVO → ej: CLI-2026-0001
    // La generación real ocurre en cada DAO con un método generateId()
    // -----------------------------------------------------------------------
    public static final String PREFIX_CLIENTE    = "CLI";
    public static final String PREFIX_EMPLEADO   = "EMP";
    public static final String PREFIX_CONTRATO   = "CON";
    public static final String PREFIX_ASISTENCIA = "ASI";
    public static final String PREFIX_CLASE      = "CLA";
    public static final String PREFIX_HORARIO    = "HOR";
    public static final String PREFIX_INSCRIPCION= "INS";
    public static final String PREFIX_USUARIO    = "USR";

    // -----------------------------------------------------------------------
    // Clave de sesión HTTP (para no usar strings sueltos en los controllers)
    // -----------------------------------------------------------------------
    public static final String SESSION_USER_ID    = "userId";
    public static final String SESSION_USER_NAME  = "userName";
    public static final String SESSION_USER_ROLE  = "userRole";
    public static final String SESSION_USER_EMAIL = "userEmail";

    // -----------------------------------------------------------------------
    // Parámetros de seguridad
    // -----------------------------------------------------------------------

    // Tiempo de sesión inactiva antes de expirar (en segundos, 30 min)
    public static final int SESSION_TIMEOUT_SECONDS = 1800;

    // Factor de coste para BCrypt (12-13 es lo recomendado en 2026)
    public static final int BCRYPT_COST = 12;

    // -----------------------------------------------------------------------
    // Parámetros de paginación
    // -----------------------------------------------------------------------
    public static final int PAGE_SIZE_DEFAULT = 20;

    // -----------------------------------------------------------------------
    // Listener de Tomcat: se ejecuta cuando arranca la aplicación
    // -----------------------------------------------------------------------

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        LOGGER.info("=== MaxFit iniciando ===");

        // Verificar que la BD responde antes de recibir requests
        if (DatabaseConnection.isConfigured()) {
            boolean ok = DatabaseConnection.testConnection();
            if (ok) {
                LOGGER.info("Conexión a gimnasio_db: OK");
            } else {
                // No lanzamos excepción: la app arranca igual pero los DAOs
                // fallarán con mensajes claros cuando se intente una operación.
                LOGGER.severe("Conexión a gimnasio_db: FALLÓ. "
                        + "Verifica SQL Server y las credenciales en db.properties");
            }
        } else {
            LOGGER.severe("db.properties no configurado. "
                    + "La aplicación arrancó pero la BD no está disponible.");
        }

        LOGGER.info("=== MaxFit listo en: "
                + sce.getServletContext().getContextPath() + " ===");
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        // Cerrar la conexión del hilo principal al apagar Tomcat
        DatabaseConnection.closeConnection();
        LOGGER.info("=== MaxFit detenido ===");
    }
}