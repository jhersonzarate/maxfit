<%-- ============================================================
     instructor.jsp  —  MaxFit Sistema de Gestión
     Panel de dashboard del Instructor (ROL-TRAINER).

     Servlet:  InstructorController.java  → GET /instructor
     Acceso:   Solo ROL-TRAINER (RoleFilter)

     ── Atributos de request inyectados por el controlador ──────

     Vista principal (action = default):
       misClases          (List<Clase>)    → clases asignadas al instructor
       totalMisClases     (int)            → total de clases asignadas
       totalAlumnos       (int)            → suma total de inscritos en sus clases
       misClasesHoy       (List<Horario>)  → horarios del instructor para hoy
       countMisClasesHoy  (int)            → cantidad de clases hoy
       fechaHoy           (String ISO)     → "2026-05-29"

     Vista de detalle (action = "clase"):
       claseDetalle    (Clase)                  → clase seleccionada
       inscritos       (List<InscripcionClase>) → alumnos inscritos
       horarios        (List<Horario>)          → horarios programados
       totalInscritos  (int)

     Flash:
       successMsg / errorMsg  → consumidos por transferirFlashMessages

     Sesión:
       sessionScope.userName   → nombre del instructor
       sessionScope.userRole   → ROL-TRAINER
       sessionScope.userEmail  → email
     ============================================================ --%>
<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="fn"  uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <%@ include file="/WEB-INF/views/includes/head-common.jsp" %>
    <c:set var="pageTitle" value="Mi Panel" scope="request"/>
    <link rel="stylesheet"
          href="${pageContext.request.contextPath}/static/css/modules.css">

    <%-- ── Estilos exclusivos del panel instructor ─────────── --%>
    <style>
    /* ══════════════════════════════════════════════════════════
       PANEL INSTRUCTOR  —  estilos propios
       Convenciones: mismos tokens CSS de styles.css
       ══════════════════════════════════════════════════════════ */

    /* ── Greeting del instructor ─────────────────────────────── */
    .instr-greeting {
        display: flex;
        align-items: flex-end;
        justify-content: space-between;
        gap: 1rem;
        padding: 1.75rem 0 1.25rem;
        flex-wrap: wrap;
    }

    .instr-greeting__tag {
        display: inline-flex;
        align-items: center;
        gap: 0.4rem;
        font-size: 0.7rem;
        font-weight: 700;
        letter-spacing: 0.14em;
        text-transform: uppercase;
        color: var(--clr-red);
        background: var(--clr-red-subtle);
        border: 1px solid rgba(230,48,39,0.18);
        padding: 0.2rem 0.6rem;
        border-radius: var(--radius-full);
        margin-bottom: 0.5rem;
    }

    .instr-greeting__tag svg {
        width: 11px;
        height: 11px;
    }

    .instr-greeting__nombre {
        font-family: var(--font-display);
        font-weight: 800;
        font-size: 1.85rem;
        letter-spacing: 0.02em;
        color: var(--clr-text);
        line-height: 1.1;
        margin: 0;
    }

    .instr-greeting__nombre span {
        color: var(--clr-red);
    }

    .instr-greeting__fecha {
        font-size: 0.82rem;
        color: var(--clr-text-dim);
        margin-top: 0.45rem;
    }

    .instr-greeting__actions {
        display: flex;
        gap: 0.65rem;
        flex-wrap: wrap;
        align-items: center;
        flex-shrink: 0;
    }

    /* ── KPI strip ───────────────────────────────────────────── */
    .instr-kpi-strip {
        display: grid;
        grid-template-columns: repeat(3, 1fr);
        gap: 0.85rem;
        margin-bottom: 1.5rem;
    }

    .instr-kpi {
        background: var(--clr-card);
        border: 1px solid var(--clr-card-border);
        border-radius: var(--radius-lg);
        padding: 1.1rem 1.25rem;
        display: flex;
        align-items: center;
        gap: 1rem;
        box-shadow: var(--shadow-card);
        transition: border-color var(--transition);
    }

    .instr-kpi:hover {
        border-color: var(--clr-surface-3);
    }

    .instr-kpi__icon {
        flex-shrink: 0;
        width: 42px;
        height: 42px;
        border-radius: var(--radius-md);
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .instr-kpi__icon svg {
        width: 20px;
        height: 20px;
    }

    .instr-kpi__icon--red   { background: var(--clr-red-subtle);     color: var(--clr-red); }
    .instr-kpi__icon--green { background: var(--clr-success-subtle);  color: var(--clr-success); }
    .instr-kpi__icon--blue  { background: var(--clr-info-subtle);     color: var(--clr-info); }

    .instr-kpi__body {
        min-width: 0;
    }

    .instr-kpi__value {
        font-family: var(--font-display);
        font-weight: 800;
        font-size: 1.75rem;
        line-height: 1;
        color: var(--clr-text);
        letter-spacing: -0.01em;
    }

    .instr-kpi__label {
        font-size: 0.73rem;
        font-weight: 500;
        color: var(--clr-text-dim);
        text-transform: uppercase;
        letter-spacing: 0.1em;
        margin-top: 0.2rem;
        white-space: nowrap;
    }

    /* ── Layout de 2 columnas ────────────────────────────────── */
    .instr-main-grid {
        display: grid;
        grid-template-columns: 1fr 360px;
        gap: 1rem;
        align-items: start;
    }

    /* ── Panel de clases asignadas ───────────────────────────── */
    .instr-clases-panel {
        display: flex;
        flex-direction: column;
        gap: 0.6rem;
    }

    .panel-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        margin-bottom: 0.65rem;
    }

    .panel-header__title {
        font-family: var(--font-display);
        font-weight: 700;
        font-size: 0.95rem;
        letter-spacing: 0.06em;
        text-transform: uppercase;
        color: var(--clr-text);
    }

    .panel-header__count {
        font-size: 0.73rem;
        font-weight: 600;
        color: var(--clr-text-dim);
        background: var(--clr-surface-2);
        padding: 0.15rem 0.55rem;
        border-radius: var(--radius-full);
    }

    /* Tarjeta de clase ─────────────────────────────────────────*/
    .clase-card {
        background: var(--clr-card);
        border: 1px solid var(--clr-card-border);
        border-radius: var(--radius-lg);
        padding: 1rem 1.2rem;
        display: grid;
        grid-template-columns: 1fr auto;
        gap: 0.75rem;
        align-items: center;
        box-shadow: var(--shadow-card);
        text-decoration: none;
        color: inherit;
        transition: border-color var(--transition), box-shadow var(--transition),
                    background var(--transition);
        cursor: pointer;
    }

    .clase-card:hover {
        border-color: rgba(230,48,39,0.35);
        background: var(--clr-surface);
        box-shadow: 0 4px 16px rgba(0,0,0,0.4);
        color: inherit;
    }

    .clase-card--suspendida {
        opacity: 0.55;
    }

    .clase-card__left {
        min-width: 0;
    }

    .clase-card__tipo {
        font-size: 0.67rem;
        font-weight: 700;
        letter-spacing: 0.14em;
        text-transform: uppercase;
        color: var(--clr-red);
        margin-bottom: 0.2rem;
    }

    .clase-card__nombre {
        font-family: var(--font-display);
        font-weight: 700;
        font-size: 1.05rem;
        letter-spacing: 0.03em;
        color: var(--clr-text);
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }

    .clase-card__desc {
        font-size: 0.78rem;
        color: var(--clr-text-muted);
        margin-top: 0.3rem;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
    }

    .clase-card__meta {
        display: flex;
        gap: 0.75rem;
        margin-top: 0.55rem;
        flex-wrap: wrap;
    }

    .clase-meta-item {
        display: flex;
        align-items: center;
        gap: 0.3rem;
        font-size: 0.74rem;
        color: var(--clr-text-muted);
    }

    .clase-meta-item svg {
        width: 13px;
        height: 13px;
        flex-shrink: 0;
        color: var(--clr-text-dim);
    }

    .clase-card__right {
        display: flex;
        flex-direction: column;
        align-items: flex-end;
        gap: 0.45rem;
        flex-shrink: 0;
    }

    .clase-card__badge {
        font-size: 0.67rem;
        font-weight: 700;
        letter-spacing: 0.08em;
        text-transform: uppercase;
        padding: 0.22rem 0.6rem;
        border-radius: var(--radius-full);
        white-space: nowrap;
    }

    .clase-card__badge--vigente {
        background: var(--clr-success-subtle);
        color: var(--clr-success);
        border: 1px solid rgba(34,197,94,0.18);
    }

    .clase-card__badge--suspendida {
        background: var(--clr-surface-2);
        color: var(--clr-text-dim);
        border: 1px solid var(--clr-border);
    }

    .clase-card__arrow {
        color: var(--clr-text-dim);
        width: 14px;
        height: 14px;
        transition: transform var(--transition), color var(--transition);
    }

    .clase-card:hover .clase-card__arrow {
        transform: translateX(3px);
        color: var(--clr-red);
    }

    /* Estado vacío ─────────────────────────────────────────────*/
    .instr-empty {
        background: var(--clr-card);
        border: 1px dashed var(--clr-card-border);
        border-radius: var(--radius-lg);
        padding: 2.5rem 1.5rem;
        text-align: center;
    }

    .instr-empty__icon {
        width: 44px;
        height: 44px;
        margin: 0 auto 0.85rem;
        color: var(--clr-text-dim);
    }

    .instr-empty__title {
        font-family: var(--font-display);
        font-weight: 700;
        font-size: 1rem;
        letter-spacing: 0.04em;
        color: var(--clr-text-muted);
        margin-bottom: 0.35rem;
    }

    .instr-empty__text {
        font-size: 0.8rem;
        color: var(--clr-text-dim);
        line-height: 1.5;
    }

    /* ── Panel lateral derecho ───────────────────────────────── */
    .instr-side-panel {
        display: flex;
        flex-direction: column;
        gap: 1rem;
    }

    /* Widget: Clases de hoy ─────────────────────────────────── */
    .today-widget {
        background: var(--clr-card);
        border: 1px solid var(--clr-card-border);
        border-radius: var(--radius-lg);
        overflow: hidden;
        box-shadow: var(--shadow-card);
    }

    .today-widget__header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 0.9rem 1.1rem 0.7rem;
        border-bottom: 1px solid var(--clr-border-light);
    }

    .today-widget__title {
        font-family: var(--font-display);
        font-weight: 700;
        font-size: 0.85rem;
        letter-spacing: 0.07em;
        text-transform: uppercase;
        color: var(--clr-text);
    }

    .today-widget__dot {
        width: 8px;
        height: 8px;
        border-radius: 50%;
        background: var(--clr-success);
        box-shadow: 0 0 0 3px var(--clr-success-subtle);
        animation: pulse-dot 2s ease-in-out infinite;
        flex-shrink: 0;
    }

    @keyframes pulse-dot {
        0%, 100% { box-shadow: 0 0 0 3px var(--clr-success-subtle); }
        50%       { box-shadow: 0 0 0 5px rgba(34,197,94,0.06); }
    }

    .today-widget__body {
        padding: 0.5rem 0;
    }

    .today-slot {
        display: flex;
        align-items: center;
        gap: 0.85rem;
        padding: 0.65rem 1.1rem;
        transition: background var(--transition);
    }

    .today-slot:hover {
        background: var(--clr-surface);
    }

    .today-slot__time {
        flex-shrink: 0;
        text-align: right;
        min-width: 64px;
    }

    .today-slot__time-start {
        font-family: var(--font-display);
        font-weight: 700;
        font-size: 0.92rem;
        color: var(--clr-text);
        line-height: 1;
    }

    .today-slot__time-end {
        font-size: 0.69rem;
        color: var(--clr-text-dim);
        margin-top: 0.1rem;
    }

    .today-slot__divider {
        width: 1px;
        height: 28px;
        background: var(--clr-border);
        flex-shrink: 0;
    }

    .today-slot__info {
        min-width: 0;
        flex: 1;
    }

    .today-slot__clase {
        font-size: 0.82rem;
        font-weight: 600;
        color: var(--clr-text);
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }

    .today-slot__dia {
        font-size: 0.69rem;
        color: var(--clr-text-dim);
        margin-top: 0.1rem;
    }

    .today-slot__status {
        flex-shrink: 0;
    }

    .slot-badge {
        font-size: 0.62rem;
        font-weight: 700;
        letter-spacing: 0.08em;
        text-transform: uppercase;
        padding: 0.18rem 0.5rem;
        border-radius: var(--radius-full);
    }

    .slot-badge--ok {
        background: var(--clr-success-subtle);
        color: var(--clr-success);
        border: 1px solid rgba(34,197,94,0.18);
    }

    .slot-badge--cancel {
        background: var(--clr-surface-2);
        color: var(--clr-text-dim);
        border: 1px solid var(--clr-border);
    }

    .today-widget__empty {
        padding: 1.5rem 1.1rem;
        text-align: center;
        font-size: 0.79rem;
        color: var(--clr-text-dim);
    }

    /* Widget: Acceso rápido ──────────────────────────────────── */
    .quick-access {
        background: var(--clr-card);
        border: 1px solid var(--clr-card-border);
        border-radius: var(--radius-lg);
        overflow: hidden;
        box-shadow: var(--shadow-card);
    }

    .quick-access__header {
        padding: 0.9rem 1.1rem 0.7rem;
        border-bottom: 1px solid var(--clr-border-light);
        font-family: var(--font-display);
        font-weight: 700;
        font-size: 0.85rem;
        letter-spacing: 0.07em;
        text-transform: uppercase;
        color: var(--clr-text);
    }

    .quick-access__list {
        padding: 0.5rem 0;
    }

    .quick-access__item {
        display: flex;
        align-items: center;
        gap: 0.75rem;
        padding: 0.7rem 1.1rem;
        text-decoration: none;
        color: var(--clr-text-muted);
        font-size: 0.83rem;
        font-weight: 500;
        transition: background var(--transition), color var(--transition);
    }

    .quick-access__item:hover {
        background: var(--clr-surface);
        color: var(--clr-text);
    }

    .quick-access__item svg {
        width: 16px;
        height: 16px;
        flex-shrink: 0;
        color: var(--clr-text-dim);
        transition: color var(--transition);
    }

    .quick-access__item:hover svg {
        color: var(--clr-red);
    }

    /* ── Vista detalle de clase ──────────────────────────────── */
    .detalle-back {
        display: inline-flex;
        align-items: center;
        gap: 0.4rem;
        font-size: 0.8rem;
        font-weight: 500;
        color: var(--clr-text-dim);
        text-decoration: none;
        margin-bottom: 1.25rem;
        transition: color var(--transition);
    }

    .detalle-back:hover {
        color: var(--clr-red);
    }

    .detalle-back svg {
        width: 14px;
        height: 14px;
        transition: transform var(--transition);
    }

    .detalle-back:hover svg {
        transform: translateX(-3px);
    }

    .detalle-hero {
        background: var(--clr-card);
        border: 1px solid var(--clr-card-border);
        border-radius: var(--radius-lg);
        padding: 1.5rem 1.75rem;
        margin-bottom: 1rem;
        box-shadow: var(--shadow-card);
    }

    .detalle-hero__top {
        display: flex;
        align-items: flex-start;
        justify-content: space-between;
        gap: 1rem;
        flex-wrap: wrap;
    }

    .detalle-hero__tipo {
        font-size: 0.7rem;
        font-weight: 700;
        letter-spacing: 0.14em;
        text-transform: uppercase;
        color: var(--clr-red);
        margin-bottom: 0.35rem;
    }

    .detalle-hero__nombre {
        font-family: var(--font-display);
        font-weight: 800;
        font-size: 1.65rem;
        letter-spacing: 0.02em;
        color: var(--clr-text);
        margin: 0;
    }

    .detalle-hero__desc {
        font-size: 0.83rem;
        color: var(--clr-text-muted);
        margin-top: 0.55rem;
        line-height: 1.55;
    }

    .detalle-hero__stats {
        display: flex;
        gap: 1.5rem;
        margin-top: 1.1rem;
        flex-wrap: wrap;
    }

    .detalle-stat {
        display: flex;
        flex-direction: column;
        gap: 0.1rem;
    }

    .detalle-stat__value {
        font-family: var(--font-display);
        font-weight: 800;
        font-size: 1.4rem;
        color: var(--clr-text);
        line-height: 1;
    }

    .detalle-stat__label {
        font-size: 0.69rem;
        font-weight: 600;
        letter-spacing: 0.1em;
        text-transform: uppercase;
        color: var(--clr-text-dim);
    }

    /* Layout detalle: 2 cols ───────────────────────────────── */
    .detalle-grid {
        display: grid;
        grid-template-columns: 1fr 340px;
        gap: 1rem;
        align-items: start;
    }

    /* Tabla inscritos ──────────────────────────────────────── */
    .inscritos-panel {
        background: var(--clr-card);
        border: 1px solid var(--clr-card-border);
        border-radius: var(--radius-lg);
        overflow: hidden;
        box-shadow: var(--shadow-card);
    }

    .inscritos-panel__header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 0.9rem 1.2rem;
        border-bottom: 1px solid var(--clr-border-light);
    }

    .inscritos-panel__title {
        font-family: var(--font-display);
        font-weight: 700;
        font-size: 0.88rem;
        letter-spacing: 0.06em;
        text-transform: uppercase;
        color: var(--clr-text);
    }

    .inscritos-table {
        width: 100%;
        border-collapse: collapse;
    }

    .inscritos-table thead tr {
        border-bottom: 1px solid var(--clr-border-light);
    }

    .inscritos-table th {
        font-size: 0.67rem;
        font-weight: 700;
        letter-spacing: 0.12em;
        text-transform: uppercase;
        color: var(--clr-text-dim);
        padding: 0.6rem 1.2rem;
        text-align: left;
    }

    .inscritos-table td {
        padding: 0.75rem 1.2rem;
        font-size: 0.82rem;
        color: var(--clr-text-muted);
        border-bottom: 1px solid var(--clr-border-light);
        vertical-align: middle;
    }

    .inscritos-table tbody tr:last-child td {
        border-bottom: none;
    }

    .inscritos-table tbody tr:hover td {
        background: var(--clr-surface);
    }

    .td-alumno {
        display: flex;
        align-items: center;
        gap: 0.6rem;
    }

    .alumno-avatar {
        flex-shrink: 0;
        width: 28px;
        height: 28px;
        border-radius: var(--radius-sm);
        background: var(--clr-surface-2);
        color: var(--clr-text-muted);
        font-size: 0.72rem;
        font-weight: 700;
        display: flex;
        align-items: center;
        justify-content: center;
        text-transform: uppercase;
    }

    .alumno-nombre {
        font-weight: 600;
        color: var(--clr-text);
        font-size: 0.82rem;
    }

    /* Horarios de la clase ─────────────────────────────────── */
    .horarios-panel {
        background: var(--clr-card);
        border: 1px solid var(--clr-card-border);
        border-radius: var(--radius-lg);
        overflow: hidden;
        box-shadow: var(--shadow-card);
    }

    .horarios-panel__header {
        padding: 0.9rem 1.1rem 0.7rem;
        border-bottom: 1px solid var(--clr-border-light);
        font-family: var(--font-display);
        font-weight: 700;
        font-size: 0.85rem;
        letter-spacing: 0.07em;
        text-transform: uppercase;
        color: var(--clr-text);
    }

    .horario-item {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 0.75rem;
        padding: 0.75rem 1.1rem;
        border-bottom: 1px solid var(--clr-border-light);
    }

    .horario-item:last-child {
        border-bottom: none;
    }

    .horario-item:hover {
        background: var(--clr-surface);
    }

    .horario-item__dia {
        font-weight: 600;
        font-size: 0.82rem;
        color: var(--clr-text);
        min-width: 72px;
    }

    .horario-item__rango {
        font-family: var(--font-display);
        font-weight: 700;
        font-size: 0.88rem;
        color: var(--clr-text-muted);
        flex: 1;
        text-align: right;
    }

    .horario-item__estado {
        font-size: 0.63rem;
        font-weight: 700;
        letter-spacing: 0.08em;
        text-transform: uppercase;
        padding: 0.18rem 0.5rem;
        border-radius: var(--radius-full);
    }

    .horario-item__estado--prog {
        background: var(--clr-success-subtle);
        color: var(--clr-success);
        border: 1px solid rgba(34,197,94,0.18);
    }

    .horario-item__estado--cancel {
        background: var(--clr-surface-2);
        color: var(--clr-text-dim);
        border: 1px solid var(--clr-border);
    }

    .horarios-panel__empty {
        padding: 1.25rem;
        text-align: center;
        font-size: 0.79rem;
        color: var(--clr-text-dim);
    }

    /* ── Responsive ─────────────────────────────────────────── */
    @media (max-width: 1100px) {
        .instr-main-grid,
        .detalle-grid {
            grid-template-columns: 1fr;
        }

        .instr-side-panel {
            display: grid;
            grid-template-columns: 1fr 1fr;
        }
    }

    @media (max-width: 768px) {
        .instr-kpi-strip {
            grid-template-columns: repeat(3, 1fr);
        }

        .instr-greeting {
            flex-direction: column;
            align-items: flex-start;
        }

        .instr-greeting__actions {
            width: 100%;
        }

        .instr-side-panel {
            grid-template-columns: 1fr;
        }
    }

    @media (max-width: 480px) {
        .instr-kpi-strip {
            grid-template-columns: 1fr 1fr;
        }

        .instr-kpi-strip .instr-kpi:nth-child(3) {
            grid-column: 1 / -1;
        }

        .instr-greeting__nombre {
            font-size: 1.5rem;
        }
    }
    </style>
</head>
<body>

<%-- ══════════════════════════════════════════════════════════
     SHELL: Sidebar + Main
     ══════════════════════════════════════════════════════════ --%>
<div class="app-shell">

    <%-- Sidebar lateral --%>
    <%@ include file="/WEB-INF/views/includes/sidebar.jsp" %>

    <%-- Área principal --%>
    <div class="app-main">

        <%-- Navbar superior --%>
        <c:choose>
            <c:when test="${not empty claseDetalle}">
                <c:set var="pageTitle"    value="Mi Panel"          scope="request"/>
                <c:set var="pageSubtitle" value="${claseDetalle.nombreClase}" scope="request"/>
            </c:when>
            <c:otherwise>
                <c:set var="pageTitle"    value="Mi Panel"             scope="request"/>
                <c:set var="pageSubtitle" value="Panel del instructor" scope="request"/>
            </c:otherwise>
        </c:choose>
        <%@ include file="/WEB-INF/views/includes/navbar.jsp" %>

        <%-- ══════════════════════════════════════════════════
             CONTENIDO DEL MÓDULO
             ══════════════════════════════════════════════════ --%>
        <div class="page-content">

            <%-- ================================================
                 VISTA DETALLE DE CLASE (action=clase)
                 Renderiza solo cuando el controlador pasa claseDetalle
                 ================================================ --%>
            <c:if test="${not empty claseDetalle}">

                <%-- Botón volver --%>
                <a href="${pageContext.request.contextPath}/instructor"
                   class="detalle-back" aria-label="Volver al panel">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round"
                              d="M10.5 19.5 3 12m0 0 7.5-7.5M3 12h18"/>
                    </svg>
                    Volver al panel
                </a>

                <%-- Hero de la clase --%>
                <div class="detalle-hero">
                    <div class="detalle-hero__top">
                        <div>
                            <div class="detalle-hero__tipo">
                                <c:choose>
                                    <c:when test="${not empty claseDetalle.tipoClase}">
                                        <c:out value="${claseDetalle.tipoClase.nombre}"/>
                                    </c:when>
                                    <c:otherwise>Clase</c:otherwise>
                                </c:choose>
                            </div>
                            <h1 class="detalle-hero__nombre">
                                <c:out value="${claseDetalle.nombreClase}"/>
                            </h1>
                            <c:if test="${not empty claseDetalle.descripcion}">
                                <p class="detalle-hero__desc">
                                    <c:out value="${claseDetalle.descripcion}"/>
                                </p>
                            </c:if>
                        </div>
                        <%-- Badge de estado --%>
                        <c:choose>
                            <c:when test="${claseDetalle.vigente}">
                                <span class="clase-card__badge clase-card__badge--vigente">Vigente</span>
                            </c:when>
                            <c:otherwise>
                                <span class="clase-card__badge clase-card__badge--suspendida">Suspendida</span>
                            </c:otherwise>
                        </c:choose>
                    </div>

                    <%-- Stats rápidos --%>
                    <div class="detalle-hero__stats">
                        <div class="detalle-stat">
                            <span class="detalle-stat__value">${totalInscritos}</span>
                            <span class="detalle-stat__label">Inscritos</span>
                        </div>
                        <div class="detalle-stat">
                            <span class="detalle-stat__value">${claseDetalle.capacidadMaxima}</span>
                            <span class="detalle-stat__label">Capacidad</span>
                        </div>
                        <div class="detalle-stat">
                            <c:set var="disponibles"
                                   value="${claseDetalle.capacidadMaxima - totalInscritos}"/>
                            <span class="detalle-stat__value"
                                  style="${disponibles le 0 ? 'color:var(--clr-red)' : ''}">
                                ${disponibles le 0 ? 0 : disponibles}
                            </span>
                            <span class="detalle-stat__label">Disponibles</span>
                        </div>
                    </div>
                </div>

                <%-- Grid detalle --%>
                <div class="detalle-grid">

                    <%-- ── Lista de inscritos ─────────────────── --%>
                    <div class="inscritos-panel">
                        <div class="inscritos-panel__header">
                            <span class="inscritos-panel__title">Alumnos inscritos</span>
                            <span class="panel-header__count">${totalInscritos}</span>
                        </div>

                        <c:choose>
                            <c:when test="${empty inscritos}">
                                <div class="today-widget__empty">
                                    Aún no hay alumnos inscritos en esta clase.
                                </div>
                            </c:when>
                            <c:otherwise>
                                <table class="inscritos-table" aria-label="Alumnos inscritos">
                                    <thead>
                                        <tr>
                                            <th>Alumno</th>
                                            <th>Documento</th>
                                            <th>Inscripción</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <c:forEach var="ins" items="${inscritos}">
                                            <tr>
                                                <td>
                                                    <div class="td-alumno">
                                                        <div class="alumno-avatar" aria-hidden="true">
                                                            <c:choose>
                                                                <c:when test="${not empty ins.cliente.nombre}">
                                                                    ${fn:substring(ins.cliente.nombre, 0, 1)}
                                                                </c:when>
                                                                <c:otherwise>A</c:otherwise>
                                                            </c:choose>
                                                        </div>
                                                        <span class="alumno-nombre">
                                                            <c:out value="${ins.cliente.nombreCompleto}"/>
                                                        </span>
                                                    </div>
                                                </td>
                                                <td>
                                                    <c:choose>
                                                        <c:when test="${not empty ins.cliente.numeroDocumento}">
                                                            <c:out value="${ins.cliente.numeroDocumento}"/>
                                                        </c:when>
                                                        <c:otherwise>—</c:otherwise>
                                                    </c:choose>
                                                </td>
                                                <td>
                                                    <c:out value="${ins.fechaFormateada}"/>
                                                </td>
                                            </tr>
                                        </c:forEach>
                                    </tbody>
                                </table>
                            </c:otherwise>
                        </c:choose>
                    </div>

                    <%-- ── Horarios programados ───────────────── --%>
                    <div class="horarios-panel">
                        <div class="horarios-panel__header">Horarios</div>

                        <c:choose>
                            <c:when test="${empty horarios}">
                                <div class="horarios-panel__empty">
                                    No hay horarios registrados.
                                </div>
                            </c:when>
                            <c:otherwise>
                                <c:forEach var="h" items="${horarios}">
                                    <div class="horario-item">
                                        <span class="horario-item__dia">
                                            <c:out value="${h.nombreDia}"/>
                                        </span>
                                        <span class="horario-item__rango">
                                            <c:out value="${h.rangoHorario}"/>
                                        </span>
                                        <c:choose>
                                            <c:when test="${h.programado}">
                                                <span class="horario-item__estado horario-item__estado--prog">
                                                    Activo
                                                </span>
                                            </c:when>
                                            <c:otherwise>
                                                <span class="horario-item__estado horario-item__estado--cancel">
                                                    Cancelado
                                                </span>
                                            </c:otherwise>
                                        </c:choose>
                                    </div>
                                </c:forEach>
                            </c:otherwise>
                        </c:choose>
                    </div>

                </div><%-- /detalle-grid --%>

            </c:if>
            <%-- /vista detalle --%>


            <%-- ================================================
                 VISTA PANEL PRINCIPAL (default)
                 Se muestra cuando NO hay claseDetalle
                 ================================================ --%>
            <c:if test="${empty claseDetalle}">

                <%-- ── Saludo del instructor ─────────────────── --%>
                <div class="instr-greeting">
                    <div>
                        <span class="instr-greeting__tag">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.2">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                      d="M9.813 15.904 9 18.75l-.813-2.846a4.5 4.5 0 0 0-3.09-3.09L2.25
                                         12l2.846-.813a4.5 4.5 0 0 0 3.09-3.09L9 5.25l.813 2.846a4.5
                                         4.5 0 0 0 3.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 0 0-3.09 3.09Z"/>
                            </svg>
                            Instructor
                        </span>
                        <h1 class="instr-greeting__nombre">
                            Hola,
                            <span><c:out value="${fn:split(sessionScope.userName, ' ')[0]}"/></span>
                        </h1>
                        <p class="instr-greeting__fecha">
                            <c:choose>
                                <c:when test="${not empty fechaHoy}">
                                    <c:set var="pf" value="${fn:split(fechaHoy, '-')}"/>
                                    Hoy,
                                    <c:choose>
                                        <c:when test="${pf[1] eq '01'}">enero</c:when>
                                        <c:when test="${pf[1] eq '02'}">febrero</c:when>
                                        <c:when test="${pf[1] eq '03'}">marzo</c:when>
                                        <c:when test="${pf[1] eq '04'}">abril</c:when>
                                        <c:when test="${pf[1] eq '05'}">mayo</c:when>
                                        <c:when test="${pf[1] eq '06'}">junio</c:when>
                                        <c:when test="${pf[1] eq '07'}">julio</c:when>
                                        <c:when test="${pf[1] eq '08'}">agosto</c:when>
                                        <c:when test="${pf[1] eq '09'}">septiembre</c:when>
                                        <c:when test="${pf[1] eq '10'}">octubre</c:when>
                                        <c:when test="${pf[1] eq '11'}">noviembre</c:when>
                                        <c:when test="${pf[1] eq '12'}">diciembre</c:when>
                                    </c:choose>
                                    ${pf[2]} de ${pf[0]}
                                </c:when>
                                <c:otherwise>Bienvenido al sistema</c:otherwise>
                            </c:choose>
                        </p>
                    </div>

                    <%-- Acciones rápidas --%>
                    <div class="instr-greeting__actions">
                        <a href="${pageContext.request.contextPath}/schedules"
                           class="btn btn-ghost btn-sm">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                      d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25
                                         0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18
                                         0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0
                                         21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25
                                         2.25 0 0 1 21 11.25v7.5"/>
                            </svg>
                            Ver horarios
                        </a>
                        <a href="${pageContext.request.contextPath}/calendar"
                           class="btn btn-primary btn-sm">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                      d="M3.75 6A2.25 2.25 0 0 1 6 3.75h2.25A2.25 2.25 0 0
                                         1 10.5 6v2.25a2.25 2.25 0 0 1-2.25 2.25H6a2.25 2.25
                                         0 0 1-2.25-2.25V6ZM3.75 15.75A2.25 2.25 0 0 1 6
                                         13.5h2.25a2.25 2.25 0 0 1 2.25 2.25V18a2.25 2.25 0
                                         0 1-2.25 2.25H6A2.25 2.25 0 0 1 3.75 18v-2.25ZM13.5
                                         6a2.25 2.25 0 0 1 2.25-2.25H18A2.25 2.25 0 0 1
                                         20.25 6v2.25A2.25 2.25 0 0 1 18 10.5h-2.25a2.25 2.25
                                         0 0 1-2.25-2.25V6ZM13.5 15.75a2.25 2.25 0 0 1
                                         2.25-2.25H18a2.25 2.25 0 0 1 2.25 2.25V18A2.25 2.25
                                         0 0 1 18 20.25h-2.25A2.25 2.25 0 0 1 13.5 18v-2.25Z"/>
                            </svg>
                            Calendario
                        </a>
                    </div>
                </div>

                <%-- ── KPIs del instructor ────────────────────── --%>
                <div class="instr-kpi-strip">

                    <div class="instr-kpi">
                        <div class="instr-kpi__icon instr-kpi__icon--red" aria-hidden="true">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                      d="M3.75 12h16.5m-16.5 3.75h16.5M3.75 19.5h16.5M5.625
                                         4.5h12.75a1.875 1.875 0 0 1 0 3.75H5.625a1.875 1.875
                                         0 0 1 0-3.75Z"/>
                            </svg>
                        </div>
                        <div class="instr-kpi__body">
                            <div class="instr-kpi__value">${totalMisClases}</div>
                            <div class="instr-kpi__label">Mis clases</div>
                        </div>
                    </div>

                    <div class="instr-kpi">
                        <div class="instr-kpi__icon instr-kpi__icon--green" aria-hidden="true">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                      d="M15 19.128a9.38 9.38 0 0 0 2.625.372 9.337 9.337 0 0
                                         0 4.121-.952 4.125 4.125 0 0 0-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15
                                         19.128v.106A12.318 12.318 0 0 1 8.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375
                                         6.375 0 0 1 11.964-3.07M12 6.375a3.375 3.375 0 1 1-6.75 0 3.375 3.375 0 0 1 6.75
                                         0Zm8.25 2.25a2.625 2.625 0 1 1-5.25 0 2.625 2.625 0 0 1 5.25 0Z"/>
                            </svg>
                        </div>
                        <div class="instr-kpi__body">
                            <div class="instr-kpi__value">${totalAlumnos}</div>
                            <div class="instr-kpi__label">Total alumnos</div>
                        </div>
                    </div>

                    <div class="instr-kpi">
                        <div class="instr-kpi__icon instr-kpi__icon--blue" aria-hidden="true">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                      d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                            </svg>
                        </div>
                        <div class="instr-kpi__body">
                            <div class="instr-kpi__value">${countMisClasesHoy}</div>
                            <div class="instr-kpi__label">Clases hoy</div>
                        </div>
                    </div>

                </div>
                <%-- /kpi-strip --%>

                <%-- ── Grid principal ─────────────────────────── --%>
                <div class="instr-main-grid">

                    <%-- ─────────────────────────────────────────
                         COLUMNA A: Mis clases asignadas
                         ───────────────────────────────────────── --%>
                    <div class="instr-clases-panel">
                        <div class="panel-header">
                            <span class="panel-header__title">Mis clases</span>
                            <span class="panel-header__count">${totalMisClases}</span>
                        </div>

                        <c:choose>
                            <c:when test="${empty misClases}">
                                <div class="instr-empty" role="status">
                                    <svg class="instr-empty__icon"
                                         xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"
                                         aria-hidden="true">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M3.75 12h16.5m-16.5 3.75h16.5M3.75 19.5h16.5M5.625
                                                 4.5h12.75a1.875 1.875 0 0 1 0 3.75H5.625a1.875 1.875
                                                 0 0 1 0-3.75Z"/>
                                    </svg>
                                    <p class="instr-empty__title">Sin clases asignadas</p>
                                    <p class="instr-empty__text">
                                        Aún no tienes clases asignadas.<br>
                                        Contacta al administrador para que te asigne clases.
                                    </p>
                                </div>
                            </c:when>
                            <c:otherwise>
                                <c:forEach var="clase" items="${misClases}">
                                    <a href="${pageContext.request.contextPath}/instructor?action=clase&id=${clase.id}"
                                       class="clase-card ${not clase.vigente ? 'clase-card--suspendida' : ''}"
                                       aria-label="Ver detalle de ${clase.nombreClase}">

                                        <div class="clase-card__left">
                                            <div class="clase-card__tipo">
                                                <c:choose>
                                                    <c:when test="${not empty clase.tipoClase}">
                                                        <c:out value="${clase.tipoClase.nombre}"/>
                                                    </c:when>
                                                    <c:otherwise>General</c:otherwise>
                                                </c:choose>
                                            </div>
                                            <div class="clase-card__nombre">
                                                <c:out value="${clase.nombreClase}"/>
                                            </div>
                                            <c:if test="${not empty clase.descripcion}">
                                                <div class="clase-card__desc">
                                                    <c:out value="${clase.descripcion}"/>
                                                </div>
                                            </c:if>

                                            <div class="clase-card__meta">
                                                <span class="clase-meta-item">
                                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"
                                                         aria-hidden="true">
                                                        <path stroke-linecap="round" stroke-linejoin="round"
                                                              d="M18 18.72a9.094 9.094 0 0 0 3.741-.479 3 3 0 0
                                                                 0-4.682-2.72m.94 3.198.001.031c0 .225-.012.447-.037.666A11.944
                                                                 11.944 0 0 1 12 21c-2.17 0-4.207-.576-5.963-1.584A6.062
                                                                 6.062 0 0 1 6 18.719m12 0a5.971 5.971 0 0 0-.941-3.197m0
                                                                 0A5.995 5.995 0 0 0 12 12.75a5.995 5.995 0 0
                                                                 0-5.058 2.772m0 0a3 3 0 0 0-4.681 2.72 8.986 8.986 0 0
                                                                 0 3.74.477m.94-3.197a5.971 5.971 0 0 0-.94 3.197M15
                                                                 6.75a3 3 0 1 1-6 0 3 3 0 0 1 6 0Zm6 3a2.25 2.25 0 1
                                                                 1-4.5 0 2.25 2.25 0 0 1 4.5 0Zm-13.5 0a2.25 2.25 0
                                                                 1 1-4.5 0 2.25 2.25 0 0 1 4.5 0Z"/>
                                                    </svg>
                                                    Cap. ${clase.capacidadMaxima}
                                                </span>
                                                <span class="clase-meta-item">
                                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"
                                                         aria-hidden="true">
                                                        <path stroke-linecap="round" stroke-linejoin="round"
                                                              d="M15.75 5.25a3 3 0 0 1 3 3m3 0a6 6 0 0 1-7.029
                                                                 5.912c-.563-.097-1.159.026-1.563.43L10.5 17.25H8.25v2.25H6v2.25H2.25v-2.818c0-.597.237-1.17.659-1.591l6.499-6.499c.404-.404.527-1
                                                                 .43-1.563A6 6 0 0 1 21.75 8.25Z"/>
                                                    </svg>
                                                    <c:out value="${clase.id}"/>
                                                </span>
                                            </div>
                                        </div>

                                        <div class="clase-card__right">
                                            <c:choose>
                                                <c:when test="${clase.vigente}">
                                                    <span class="clase-card__badge clase-card__badge--vigente">
                                                        Vigente
                                                    </span>
                                                </c:when>
                                                <c:otherwise>
                                                    <span class="clase-card__badge clase-card__badge--suspendida">
                                                        Suspendida
                                                    </span>
                                                </c:otherwise>
                                            </c:choose>
                                            <svg class="clase-card__arrow"
                                                 xmlns="http://www.w3.org/2000/svg" fill="none"
                                                 viewBox="0 0 24 24" stroke="currentColor"
                                                 stroke-width="2" aria-hidden="true">
                                                <path stroke-linecap="round" stroke-linejoin="round"
                                                      d="M13.5 4.5 21 12m0 0-7.5 7.5M21 12H3"/>
                                            </svg>
                                        </div>

                                    </a>
                                </c:forEach>
                            </c:otherwise>
                        </c:choose>

                    </div>
                    <%-- /instr-clases-panel --%>

                    <%-- ─────────────────────────────────────────
                         COLUMNA B: Panel lateral derecho
                         ───────────────────────────────────────── --%>
                    <div class="instr-side-panel">

                        <%-- Widget: Clases de hoy ────────────── --%>
                        <div class="today-widget">
                            <div class="today-widget__header">
                                <span class="today-widget__title">Clases de hoy</span>
                                <c:choose>
                                    <c:when test="${countMisClasesHoy gt 0}">
                                        <span class="today-widget__dot" aria-hidden="true"
                                              title="Hay clases programadas hoy"></span>
                                    </c:when>
                                    <c:otherwise>
                                        <span class="panel-header__count">${countMisClasesHoy}</span>
                                    </c:otherwise>
                                </c:choose>
                            </div>

                            <div class="today-widget__body">
                                <c:choose>
                                    <c:when test="${empty misClasesHoy}">
                                        <div class="today-widget__empty">
                                            No tienes clases programadas para hoy.
                                        </div>
                                    </c:when>
                                    <c:otherwise>
                                        <c:forEach var="h" items="${misClasesHoy}">
                                            <div class="today-slot">
                                                <div class="today-slot__time">
                                                    <div class="today-slot__time-start">
                                                        <c:choose>
                                                            <c:when test="${not empty h.horaInicio}">
                                                                ${fn:substring(h.horaInicio.toString(), 0, 5)}
                                                            </c:when>
                                                            <c:otherwise>--:--</c:otherwise>
                                                        </c:choose>
                                                    </div>
                                                    <div class="today-slot__time-end">
                                                        <c:choose>
                                                            <c:when test="${not empty h.horaFin}">
                                                                ${fn:substring(h.horaFin.toString(), 0, 5)}
                                                            </c:when>
                                                            <c:otherwise>--:--</c:otherwise>
                                                        </c:choose>
                                                    </div>
                                                </div>
                                                <div class="today-slot__divider" aria-hidden="true"></div>
                                                <div class="today-slot__info">
                                                    <div class="today-slot__clase">
                                                        <c:choose>
                                                            <c:when test="${not empty h.clase}">
                                                                <c:out value="${h.clase.nombreClase}"/>
                                                            </c:when>
                                                            <c:otherwise>Clase</c:otherwise>
                                                        </c:choose>
                                                    </div>
                                                    <div class="today-slot__dia">
                                                        <c:out value="${h.nombreDia}"/>
                                                    </div>
                                                </div>
                                                <div class="today-slot__status">
                                                    <c:choose>
                                                        <c:when test="${h.programado}">
                                                            <span class="slot-badge slot-badge--ok">Activa</span>
                                                        </c:when>
                                                        <c:otherwise>
                                                            <span class="slot-badge slot-badge--cancel">Cancelada</span>
                                                        </c:otherwise>
                                                    </c:choose>
                                                </div>
                                            </div>
                                        </c:forEach>
                                    </c:otherwise>
                                </c:choose>
                            </div>
                        </div>
                        <%-- /today-widget --%>

                        <%-- Widget: Acceso rápido ──────────────── --%>
                        <div class="quick-access">
                            <div class="quick-access__header">Accesos rápidos</div>
                            <nav class="quick-access__list" aria-label="Accesos rápidos">

                                <a href="${pageContext.request.contextPath}/schedules"
                                   class="quick-access__item">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8"
                                         aria-hidden="true">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25
                                                 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18
                                                 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0
                                                 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25
                                                 2.25 0 0 1 21 11.25v7.5"/>
                                    </svg>
                                    Gestión de horarios
                                </a>

                                <a href="${pageContext.request.contextPath}/calendar"
                                   class="quick-access__item">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8"
                                         aria-hidden="true">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M3.75 6A2.25 2.25 0 0 1 6 3.75h2.25A2.25 2.25 0 0
                                                 1 10.5 6v2.25a2.25 2.25 0 0 1-2.25 2.25H6a2.25 2.25
                                                 0 0 1-2.25-2.25V6ZM3.75 15.75A2.25 2.25 0 0 1 6
                                                 13.5h2.25a2.25 2.25 0 0 1 2.25 2.25V18a2.25 2.25 0
                                                 0 1-2.25 2.25H6A2.25 2.25 0 0 1 3.75 18v-2.25ZM13.5
                                                 6a2.25 2.25 0 0 1 2.25-2.25H18A2.25 2.25 0 0 1
                                                 20.25 6v2.25A2.25 2.25 0 0 1 18 10.5h-2.25a2.25 2.25
                                                 0 0 1-2.25-2.25V6ZM13.5 15.75a2.25 2.25 0 0 1
                                                 2.25-2.25H18a2.25 2.25 0 0 1 2.25 2.25V18A2.25 2.25
                                                 0 0 1 18 20.25h-2.25A2.25 2.25 0 0 1 13.5 18v-2.25Z"/>
                                    </svg>
                                    Calendario semanal
                                </a>

                                <a href="${pageContext.request.contextPath}/attendance"
                                   class="quick-access__item">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8"
                                         aria-hidden="true">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                    </svg>
                                    Control de asistencia
                                </a>

                            </nav>
                        </div>
                        <%-- /quick-access --%>

                    </div>
                    <%-- /instr-side-panel --%>

                </div>
                <%-- /instr-main-grid --%>

            </c:if>
            <%-- /vista panel principal --%>

        </div><%-- /page-content --%>
    </div><%-- /app-main --%>
</div><%-- /app-shell --%>

</body>
</html>
