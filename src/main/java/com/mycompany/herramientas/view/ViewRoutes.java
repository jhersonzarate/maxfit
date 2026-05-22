package com.mycompany.herramientas.view;

/**
 * Constantes de rutas hacia los JSP (capa Vista del MVC).
 *
 * Centralizar todas las rutas en un solo lugar evita errores de tipeo
 * y facilita renombrar o mover vistas sin buscar en todos los controladores.
 *
 * Todas las vistas están bajo WEB-INF/views/ para que Tomcat no las
 * sirva directamente por URL — solo son accesibles mediante forward
 * desde un controlador (esto es seguridad básica en Java EE).
 */
public final class ViewRoutes {

    private ViewRoutes() {}

    private static final String BASE = "/WEB-INF/views/";

    // ── Autenticación ────────────────────────────────────────────────────────
    public static final String AUTH_LOGIN           = BASE + "auth/login.jsp";
    public static final String AUTH_FORGOT_PASSWORD = BASE + "auth/forgot-password.jsp";

    // ── Páginas de inicio por rol ────────────────────────────────────────────
    public static final String HOME_INDEX      = BASE + "home/index.jsp";
    public static final String INICIO_ADMIN    = BASE + "inicio/inicio.jsp";        // Admin
    public static final String DASHBOARD_RECEP = BASE + "dashboard/dashboard.jsp";  // Recepcionista
    public static final String DASHBOARD_INSTR = BASE + "instructor/instructor.jsp"; // Instructor

    // ── Módulos ──────────────────────────────────────────────────────────────
    public static final String CLIENTS_INDEX    = BASE + "clients/clients.jsp";
    public static final String CLIENT_DETAIL    = BASE + "clients/client-detail.jsp";

    public static final String CONTRACTS_INDEX  = BASE + "contracts/contracts.jsp";

    public static final String MEMBERSHIPS_INDEX = BASE + "memberships/memberships.jsp";

    public static final String ATTENDANCE_INDEX  = BASE + "attendance/attendance.jsp";

    public static final String SCHEDULES_INDEX   = BASE + "schedules/schedules.jsp";
    public static final String SCHEDULES_CALENDAR= BASE + "schedules/calendar.jsp";

    public static final String EMPLOYEES_INDEX   = BASE + "employees/employees.jsp";

    public static final String USERS_INDEX       = BASE + "users/users.jsp";

    public static final String PAYMENT_METHODS_INDEX = BASE + "payment-methods/payment-methods.jsp";

    public static final String REPORTS_INDEX     = BASE + "reports/reports.jsp";
}