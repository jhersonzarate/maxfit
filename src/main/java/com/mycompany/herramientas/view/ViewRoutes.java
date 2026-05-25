package com.mycompany.herramientas.view;

// constantes de rutas de vistas JSP (MVC)
public final class ViewRoutes {

    private ViewRoutes() {}

    private static final String BASE = "/WEB-INF/views/";

    // ─── AUTENTICACIÓN ────────────────────────────────────────
    public static final String AUTH_LOGIN = BASE + "auth/login.jsp";
    public static final String AUTH_FORGOT_PASSWORD = BASE + "auth/forgot-password.jsp";

    // ─── HOME POR ROL ─────────────────────────────────────────
    public static final String HOME_INDEX = BASE + "home/index.jsp";
    public static final String INICIO_ADMIN = BASE + "inicio/inicio.jsp";
    public static final String DASHBOARD_RECEP = BASE + "dashboard/dashboard.jsp";
    public static final String DASHBOARD_INSTR = BASE + "instructor/instructor.jsp";

    // ─── CLIENTES ─────────────────────────────────────────────
    public static final String CLIENTS_INDEX = BASE + "clients/clients.jsp";
    public static final String CLIENT_DETAIL = BASE + "clients/client-detail.jsp";

    // ─── CONTRATOS ────────────────────────────────────────────
    public static final String CONTRACTS_INDEX = BASE + "contracts/contracts.jsp";

    // ─── MEMBRESÍAS ───────────────────────────────────────────
    public static final String MEMBERSHIPS_INDEX = BASE + "memberships/memberships.jsp";

    // ─── ASISTENCIA ───────────────────────────────────────────
    public static final String ATTENDANCE_INDEX = BASE + "attendance/attendance.jsp";

    // ─── HORARIOS ─────────────────────────────────────────────
    public static final String SCHEDULES_INDEX = BASE + "schedules/schedules.jsp";
    public static final String SCHEDULES_CALENDAR = BASE + "schedules/calendar.jsp";

    // ─── EMPLEADOS ────────────────────────────────────────────
    public static final String EMPLOYEES_INDEX = BASE + "employees/employees.jsp";

    // ─── USUARIOS ─────────────────────────────────────────────
    public static final String USERS_INDEX = BASE + "users/users.jsp";

    // ─── PAGOS ────────────────────────────────────────────────
    public static final String PAYMENT_METHODS_INDEX = BASE + "payment-methods/payment-methods.jsp";

    // ─── REPORTES ─────────────────────────────────────────────
    public static final String REPORTS_INDEX = BASE + "reports/reports.jsp";
}