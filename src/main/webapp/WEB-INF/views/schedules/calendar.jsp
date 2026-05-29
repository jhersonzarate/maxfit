<%-- ============================================================
     calendar.jsp  —  MaxFit Sistema de Gestión
     Vista de calendario semanal de clases grupales (RF-09).

     Servlet:  SchedulesController.java  → GET /calendar
     Acceso:   ROL-ADMIN | ROL-RECEP | ROL-TRAINER (RoleFilter)

     ── Atributos de request ─────────────────────────────────
       horarios  (List<Horario>)  → todos los horarios programados
                                    con clase y estado incluidos

     Horario.diaSemana → 1=Lunes … 7=Domingo (ISO-8601)
     Solo se muestran horarios con estado = 'programado'.
     Los cancelados se muestran atenuados si el admin los ve.

     Flash (via transferirFlashMessages):
       successMsg / errorMsg
     ============================================================ --%>
<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn"  uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <%@ include file="/WEB-INF/views/includes/head-common.jsp" %>
    <c:set var="pageTitle" value="Calendario Semanal" scope="request"/>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/modules.css">

    <style>
        /* ══════════════════════════════════════════════════════
           ESTILOS ESPECÍFICOS — CALENDARIO SEMANAL
           ══════════════════════════════════════════════════════ */

        /* ── Variables de la vista ──────────────────────────── */
        :root {
            --cal-col-min: 130px;
            --cal-slot-h:  72px;
            --cal-header-h: 52px;
            --cal-time-w:  60px;
        }

        /* ── Strip de KPIs de cabecera ──────────────────────── */
        .cal-kpi-strip {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 0;
            background: var(--clr-card);
            border: 1px solid var(--clr-card-border);
            border-radius: var(--radius-lg);
            overflow: hidden;
            margin-bottom: 1.5rem;
        }

        .cal-kpi {
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: 0.9rem 0.75rem;
            gap: 0.15rem;
            border-right: 1px solid var(--clr-border-light);
            transition: background var(--transition);
        }

        .cal-kpi:last-child { border-right: none; }
        .cal-kpi:hover      { background: rgba(255,255,255,0.02); }

        .cal-kpi__num {
            font-family: var(--font-display);
            font-size: 1.55rem;
            font-weight: 800;
            line-height: 1;
            color: var(--clr-text);
        }

        .cal-kpi__num.red    { color: var(--clr-red); }
        .cal-kpi__num.green  { color: var(--clr-success); }
        .cal-kpi__num.blue   { color: var(--clr-info); }
        .cal-kpi__num.purple { color: #a78bfa; }

        .cal-kpi__label {
            font-size: 0.65rem;
            font-weight: 700;
            letter-spacing: 0.09em;
            text-transform: uppercase;
            color: var(--clr-text-dim);
        }

        /* ── Wrapper del calendario ─────────────────────────── */
        .cal-wrapper {
            background: var(--clr-card);
            border: 1px solid var(--clr-card-border);
            border-radius: var(--radius-xl);
            overflow: hidden;
            position: relative;
        }

        /* ── Cabecera del calendario (días de semana) ────────── */
        .cal-header {
            display: grid;
            grid-template-columns: var(--cal-time-w) repeat(7, 1fr);
            border-bottom: 1px solid var(--clr-border);
            position: sticky;
            top: var(--navbar-height);
            z-index: 10;
            background: var(--clr-surface);
        }

        .cal-header__spacer {
            border-right: 1px solid var(--clr-border-light);
            height: var(--cal-header-h);
        }

        .cal-header__day {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            height: var(--cal-header-h);
            border-right: 1px solid var(--clr-border-light);
            gap: 0.1rem;
            cursor: default;
            transition: background var(--transition);
            position: relative;
        }

        .cal-header__day:last-child {
            border-right: none;
        }

        .cal-header__day:hover {
            background: rgba(255,255,255,0.025);
        }

        /* Día actual — resaltado */
        .cal-header__day.is-today {
            background: var(--clr-red-subtle);
        }

        .cal-header__day.is-today::after {
            content: '';
            position: absolute;
            bottom: 0;
            left: 0;
            right: 0;
            height: 2px;
            background: var(--clr-red);
        }

        .cal-header__day-name {
            font-size: 0.68rem;
            font-weight: 700;
            letter-spacing: 0.10em;
            text-transform: uppercase;
            color: var(--clr-text-dim);
        }

        .cal-header__day.is-today .cal-header__day-name {
            color: var(--clr-red);
        }

        .cal-header__day-num {
            font-family: var(--font-display);
            font-size: 0.70rem;
            font-weight: 600;
            color: var(--clr-text-dim);
            letter-spacing: 0.05em;
            text-transform: uppercase;
        }

        .cal-header__day-count {
            font-size: 0.62rem;
            font-weight: 700;
            color: var(--clr-text-dim);
            background: var(--clr-surface-2);
            border: 1px solid var(--clr-border-light);
            border-radius: var(--radius-full);
            padding: 0.08rem 0.4rem;
            font-family: var(--font-mono);
            line-height: 1.4;
            min-width: 18px;
            text-align: center;
        }

        .cal-header__day.is-today .cal-header__day-count {
            background: var(--clr-red-subtle);
            border-color: rgba(230,48,39,0.25);
            color: var(--clr-red);
        }

        .cal-header__day-count.has-classes {
            background: var(--clr-success-subtle);
            border-color: rgba(34,197,94,0.22);
            color: var(--clr-success);
        }

        /* ── Grilla del cuerpo del calendario ───────────────── */
        .cal-body {
            display: grid;
            grid-template-columns: var(--cal-time-w) repeat(7, 1fr);
            min-height: 200px;
        }

        /* Columna de franja horaria (vacía — decorativa) */
        .cal-time-col {
            border-right: 1px solid var(--clr-border-light);
            background: rgba(255,255,255,0.01);
        }

        /* Columna de día */
        .cal-day-col {
            border-right: 1px solid var(--clr-border-light);
            padding: 0.65rem 0.4rem;
            min-height: 200px;
            display: flex;
            flex-direction: column;
            gap: 0.4rem;
            position: relative;
        }

        .cal-day-col:last-child {
            border-right: none;
        }

        /* Columna vacía — mensaje sutil */
        .cal-day-col.is-empty {
            justify-content: center;
            align-items: center;
        }

        .cal-day-col.is-empty::after {
            content: '—';
            font-size: 0.75rem;
            color: var(--clr-text-dim);
            opacity: 0.35;
        }

        /* ── Tarjeta de clase en la grilla ─────────────────── */
        .cal-event {
            border-radius: var(--radius-md);
            padding: 0.6rem 0.75rem;
            display: flex;
            flex-direction: column;
            gap: 0.2rem;
            position: relative;
            overflow: hidden;
            transition: transform var(--transition), box-shadow var(--transition),
                        border-color var(--transition);
            cursor: default;
            border: 1px solid transparent;
            text-decoration: none;
        }

        .cal-event:hover {
            transform: translateY(-2px) scale(1.015);
            box-shadow: 0 6px 24px rgba(0,0,0,0.5);
            z-index: 2;
        }

        /* Franja izquierda de color */
        .cal-event::before {
            content: '';
            position: absolute;
            left: 0;
            top: 0;
            bottom: 0;
            width: 3px;
            background: var(--event-accent, var(--clr-red));
            border-radius: 2px 0 0 2px;
        }

        /* Paleta de colores por tipo de clase */
        .cal-event[data-tipo="TCL-CARDIO"],
        .cal-event.ev--0 {
            background: rgba(230,48,39,0.10);
            border-color: rgba(230,48,39,0.20);
            --event-accent: var(--clr-red);
        }

        .cal-event[data-tipo="TCL-YOGA"],
        .cal-event.ev--1 {
            background: rgba(167,139,250,0.10);
            border-color: rgba(167,139,250,0.20);
            --event-accent: #a78bfa;
        }

        .cal-event[data-tipo="TCL-BOX"],
        .cal-event.ev--2 {
            background: rgba(249,115,22,0.10);
            border-color: rgba(249,115,22,0.20);
            --event-accent: #f97316;
        }

        .cal-event[data-tipo="TCL-FUNCIONAL"],
        .cal-event.ev--3 {
            background: rgba(45,212,191,0.10);
            border-color: rgba(45,212,191,0.20);
            --event-accent: #2dd4bf;
        }

        .cal-event.ev--4 {
            background: rgba(34,197,94,0.10);
            border-color: rgba(34,197,94,0.20);
            --event-accent: var(--clr-success);
        }

        .cal-event.ev--5 {
            background: rgba(59,130,246,0.10);
            border-color: rgba(59,130,246,0.20);
            --event-accent: var(--clr-info);
        }

        /* Estado cancelado */
        .cal-event.is-cancelled {
            opacity: 0.45;
            filter: grayscale(0.6);
        }

        /* Nombre de la clase */
        .cal-event__nombre {
            font-family: var(--font-display);
            font-weight: 700;
            font-size: 0.82rem;
            letter-spacing: 0.03em;
            text-transform: uppercase;
            color: var(--clr-text);
            line-height: 1.2;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        /* Rango horario */
        .cal-event__time {
            display: flex;
            align-items: center;
            gap: 0.3rem;
            font-family: var(--font-mono);
            font-size: 0.70rem;
            font-weight: 600;
            color: var(--event-accent, var(--clr-red));
            line-height: 1;
        }

        .cal-event__time svg {
            width: 10px;
            height: 10px;
            flex-shrink: 0;
            opacity: 0.75;
        }

        /* Tipo de clase */
        .cal-event__tipo {
            font-size: 0.60rem;
            font-weight: 600;
            letter-spacing: 0.08em;
            text-transform: uppercase;
            color: var(--clr-text-dim);
        }

        /* Badge de estado cancelado */
        .cal-event__cancelled {
            position: absolute;
            top: 0.35rem;
            right: 0.35rem;
            width: 16px;
            height: 16px;
            border-radius: var(--radius-full);
            background: var(--clr-danger-subtle);
            border: 1px solid rgba(230,48,39,0.25);
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .cal-event__cancelled svg {
            width: 9px;
            height: 9px;
            color: var(--clr-red);
        }

        /* ── Leyenda de tipos ───────────────────────────────── */
        .cal-legend {
            display: flex;
            align-items: center;
            gap: 1rem;
            padding: 0.9rem 1.25rem;
            border-top: 1px solid var(--clr-border-light);
            background: rgba(255,255,255,0.012);
            flex-wrap: wrap;
        }

        .cal-legend__title {
            font-size: 0.65rem;
            font-weight: 700;
            letter-spacing: 0.10em;
            text-transform: uppercase;
            color: var(--clr-text-dim);
            flex-shrink: 0;
        }

        .cal-legend__items {
            display: flex;
            align-items: center;
            gap: 0.75rem;
            flex-wrap: wrap;
        }

        .cal-legend__item {
            display: flex;
            align-items: center;
            gap: 0.35rem;
            font-size: 0.72rem;
            color: var(--clr-text-muted);
        }

        .cal-legend__dot {
            width: 8px;
            height: 8px;
            border-radius: 2px;
            flex-shrink: 0;
        }

        /* ── Vista de lista compacta (fallback mobile) ──────── */
        .cal-list-view {
            display: none;
        }

        .cal-list-day {
            border-bottom: 1px solid var(--clr-border-light);
        }

        .cal-list-day:last-child {
            border-bottom: none;
        }

        .cal-list-day__header {
            display: flex;
            align-items: center;
            gap: 0.65rem;
            padding: 0.7rem 1.25rem;
            background: var(--clr-surface);
            border-bottom: 1px solid var(--clr-border-light);
            cursor: default;
        }

        .cal-list-day__name {
            font-family: var(--font-display);
            font-size: 0.85rem;
            font-weight: 700;
            letter-spacing: 0.06em;
            text-transform: uppercase;
            color: var(--clr-text);
        }

        .cal-list-day.is-today .cal-list-day__name {
            color: var(--clr-red);
        }

        .cal-list-day__count {
            font-size: 0.65rem;
            font-family: var(--font-mono);
            font-weight: 700;
            background: var(--clr-surface-2);
            border: 1px solid var(--clr-border);
            color: var(--clr-text-dim);
            padding: 0.1rem 0.45rem;
            border-radius: var(--radius-full);
        }

        .cal-list-day__empty {
            padding: 0.85rem 1.25rem;
            font-size: 0.78rem;
            color: var(--clr-text-dim);
            font-style: italic;
        }

        /* Fila de evento en lista */
        .cal-list-event {
            display: flex;
            align-items: center;
            gap: 0.85rem;
            padding: 0.65rem 1.25rem;
            border-bottom: 1px solid var(--clr-border-light);
            transition: background var(--transition);
        }

        .cal-list-event:last-child {
            border-bottom: none;
        }

        .cal-list-event:hover {
            background: rgba(255,255,255,0.025);
        }

        .cal-list-event__accent {
            flex-shrink: 0;
            width: 3px;
            height: 36px;
            border-radius: 2px;
            background: var(--event-accent, var(--clr-red));
        }

        .cal-list-event__time {
            flex-shrink: 0;
            min-width: 90px;
            font-family: var(--font-mono);
            font-size: 0.80rem;
            font-weight: 600;
            color: var(--event-accent, var(--clr-red));
        }

        .cal-list-event__info {
            flex: 1;
            min-width: 0;
        }

        .cal-list-event__nombre {
            font-size: 0.85rem;
            font-weight: 600;
            color: var(--clr-text);
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .cal-list-event__tipo {
            font-size: 0.70rem;
            color: var(--clr-text-dim);
        }

        .cal-list-event.is-cancelled {
            opacity: 0.45;
        }

        /* ── Tooltip custom (sin JS) ────────────────────────── */
        .cal-tooltip-wrap {
            position: relative;
        }

        /* ── Barra de navegación del calendario ─────────────── */
        .cal-nav {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 1rem;
            padding: 0.9rem 1.25rem;
            border-bottom: 1px solid var(--clr-border);
            flex-wrap: wrap;
        }

        .cal-nav__title {
            font-family: var(--font-display);
            font-weight: 700;
            font-size: 1rem;
            letter-spacing: 0.05em;
            text-transform: uppercase;
            color: var(--clr-text);
        }

        .cal-nav__sub {
            font-size: 0.72rem;
            color: var(--clr-text-dim);
        }

        .cal-nav__actions {
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        /* ── Estado vacío del calendario ─────────────────────── */
        .cal-empty {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 5rem 2rem;
            gap: 0.85rem;
            text-align: center;
        }

        .cal-empty__icon {
            width: 64px;
            height: 64px;
            border-radius: var(--radius-xl);
            background: var(--clr-surface);
            border: 1px solid var(--clr-border);
            display: flex;
            align-items: center;
            justify-content: center;
            margin-bottom: 0.35rem;
        }

        .cal-empty__icon svg {
            width: 28px;
            height: 28px;
            color: var(--clr-text-dim);
        }

        .cal-empty__title {
            font-weight: 600;
            font-size: 1rem;
            color: var(--clr-text);
        }

        .cal-empty__desc {
            font-size: 0.83rem;
            color: var(--clr-text-muted);
            max-width: 320px;
            line-height: 1.6;
        }

        /* ── Animaciones ─────────────────────────────────────── */
        .cal-event {
            animation: fadeSlideUp 0.42s cubic-bezier(0.4,0,0.2,1) both;
        }

        /* Escalonado por columna de día */
        .cal-day-col:nth-child(2) .cal-event { animation-delay: 0.04s; }
        .cal-day-col:nth-child(3) .cal-event { animation-delay: 0.08s; }
        .cal-day-col:nth-child(4) .cal-event { animation-delay: 0.12s; }
        .cal-day-col:nth-child(5) .cal-event { animation-delay: 0.16s; }
        .cal-day-col:nth-child(6) .cal-event { animation-delay: 0.20s; }
        .cal-day-col:nth-child(7) .cal-event { animation-delay: 0.24s; }
        .cal-day-col:nth-child(8) .cal-event { animation-delay: 0.28s; }

        /* ── Responsive ──────────────────────────────────────── */

        /* Tablet — reducir columnas de la grilla */
        @media (max-width: 1200px) {
            :root { --cal-col-min: 110px; }
        }

        /* Mobile — cambiar a vista de lista */
        @media (max-width: 900px) {
            .cal-grid-view  { display: none; }
            .cal-list-view  { display: block; }
            .cal-kpi-strip  { grid-template-columns: repeat(2, 1fr); }
            .cal-kpi:nth-child(2)  { border-right: none; }
            .cal-kpi:nth-child(3)  { border-top: 1px solid var(--clr-border-light); }
        }

        @media (max-width: 480px) {
            .cal-kpi-strip  { grid-template-columns: 1fr 1fr; }
        }
    </style>
</head>
<body>

<div class="app-shell">
    <%@ include file="/WEB-INF/views/includes/sidebar.jsp" %>

    <div class="app-main">
        <c:set var="pageTitle"    value="Calendario Semanal"             scope="request"/>
        <c:set var="pageSubtitle" value="Programa de clases por semana"  scope="request"/>
        <%@ include file="/WEB-INF/views/includes/navbar.jsp" %>

        <div class="page-content">

            <%-- ── Breadcrumb ─────────────────────────────────── --%>
            <nav class="module-breadcrumb" aria-label="Breadcrumb">
                <a href="${pageContext.request.contextPath}/schedules">Clases</a>
                <svg class="module-breadcrumb__sep" xmlns="http://www.w3.org/2000/svg"
                     fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7"/>
                </svg>
                <span>Calendario semanal</span>
            </nav>

            <%-- ── Header del módulo ──────────────────────────── --%>
            <div class="module-header">
                <div class="module-header__left">
                    <h1 class="module-header__title">
                        Calendario Semanal
                        <c:if test="${not empty horarios}">
                            <span class="stat-chip">
                                <c:out value="${fn:length(horarios)}"/>
                                horario<c:if test="${fn:length(horarios) ne 1}">s</c:if>
                            </span>
                        </c:if>
                    </h1>
                    <div class="module-header__meta">
                        <span>Programa recurrente de clases grupales</span>
                        <span class="module-header__meta-sep"></span>
                        <span>Lunes → Domingo</span>
                    </div>
                </div>
                <div class="module-header__actions">
                    <a href="${pageContext.request.contextPath}/schedules"
                       class="btn btn-secondary">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M3.75 6A2.25 2.25 0 0 1 6 3.75h2.25A2.25 2.25 0 0 1 10.5
                                     6v2.25a2.25 2.25 0 0 1-2.25 2.25H6a2.25 2.25 0 0
                                     1-2.25-2.25V6ZM3.75 15.75A2.25 2.25 0 0 1 6 13.5h2.25a2.25
                                     2.25 0 0 1 2.25 2.25V18a2.25 2.25 0 0 1-2.25 2.25H6A2.25
                                     2.25 0 0 1 3.75 18v-2.25ZM13.5 6a2.25 2.25 0 0 1
                                     2.25-2.25H18A2.25 2.25 0 0 1 20.25 6v2.25A2.25 2.25 0 0 1 18
                                     10.5h-2.25a2.25 2.25 0 0 1-2.25-2.25V6ZM13.5 15.75a2.25 2.25
                                     0 0 1 2.25-2.25H18a2.25 2.25 0 0 1 2.25 2.25V18A2.25 2.25 0
                                     0 1 18 20.25h-2.25A2.25 2.25 0 0 1 13.5 18v-2.25Z"/>
                        </svg>
                        Ver clases
                    </a>
                    <c:if test="${sessionScope.userRole eq 'ROL-ADMIN'}">
                        <a href="${pageContext.request.contextPath}/schedules?action=new"
                           class="btn btn-primary">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.2">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                      d="M12 4.5v15m7.5-7.5h-15"/>
                            </svg>
                            Nueva clase
                        </a>
                    </c:if>
                </div>
            </div>

            <%-- ── Conteo de clases por día (para KPIs) ────────── --%>
            <%-- Usamos JSTL para contar cuántos horarios hay por día --%>
            <c:set var="cntLun" value="0"/>
            <c:set var="cntMar" value="0"/>
            <c:set var="cntMie" value="0"/>
            <c:set var="cntJue" value="0"/>
            <c:set var="cntVie" value="0"/>
            <c:set var="cntSab" value="0"/>
            <c:set var="cntDom" value="0"/>
            <c:set var="cntProg" value="0"/>
            <c:set var="cntCanc" value="0"/>

            <c:forEach var="h" items="${horarios}">
                <c:choose>
                    <c:when test="${h.diaSemana eq 1}"><c:set var="cntLun" value="${cntLun + 1}"/></c:when>
                    <c:when test="${h.diaSemana eq 2}"><c:set var="cntMar" value="${cntMar + 1}"/></c:when>
                    <c:when test="${h.diaSemana eq 3}"><c:set var="cntMie" value="${cntMie + 1}"/></c:when>
                    <c:when test="${h.diaSemana eq 4}"><c:set var="cntJue" value="${cntJue + 1}"/></c:when>
                    <c:when test="${h.diaSemana eq 5}"><c:set var="cntVie" value="${cntVie + 1}"/></c:when>
                    <c:when test="${h.diaSemana eq 6}"><c:set var="cntSab" value="${cntSab + 1}"/></c:when>
                    <c:when test="${h.diaSemana eq 7}"><c:set var="cntDom" value="${cntDom + 1}"/></c:when>
                </c:choose>
                <c:if test="${h.estado eq 'programado'}">
                    <c:set var="cntProg" value="${cntProg + 1}"/>
                </c:if>
                <c:if test="${h.estado eq 'cancelado'}">
                    <c:set var="cntCanc" value="${cntCanc + 1}"/>
                </c:if>
            </c:forEach>

            <%-- Obtener día ISO actual (1=Lun…7=Dom) via scriptlet mínimo --%>
            <%
                int diaSemanaHoy = java.time.LocalDate.now().getDayOfWeek().getValue();
                request.setAttribute("diaSemanaHoy", diaSemanaHoy);
            %>

            <%-- ── KPI Strip ───────────────────────────────────── --%>
            <div class="cal-kpi-strip">
                <div class="cal-kpi">
                    <span class="cal-kpi__num">
                        <c:out value="${fn:length(horarios)}"/>
                    </span>
                    <span class="cal-kpi__label">Horarios totales</span>
                </div>
                <div class="cal-kpi">
                    <span class="cal-kpi__num green">
                        <c:out value="${cntProg}"/>
                    </span>
                    <span class="cal-kpi__label">Programados</span>
                </div>
                <div class="cal-kpi">
                    <span class="cal-kpi__num red">
                        <c:out value="${cntCanc}"/>
                    </span>
                    <span class="cal-kpi__label">Cancelados</span>
                </div>
                <div class="cal-kpi">
                    <%-- Día con más clases --%>
                    <c:set var="maxDia" value="${cntLun}"/>
                    <c:if test="${cntMar gt maxDia}"><c:set var="maxDia" value="${cntMar}"/></c:if>
                    <c:if test="${cntMie gt maxDia}"><c:set var="maxDia" value="${cntMie}"/></c:if>
                    <c:if test="${cntJue gt maxDia}"><c:set var="maxDia" value="${cntJue}"/></c:if>
                    <c:if test="${cntVie gt maxDia}"><c:set var="maxDia" value="${cntVie}"/></c:if>
                    <c:if test="${cntSab gt maxDia}"><c:set var="maxDia" value="${cntSab}"/></c:if>
                    <c:if test="${cntDom gt maxDia}"><c:set var="maxDia" value="${cntDom}"/></c:if>
                    <span class="cal-kpi__num purple">
                        <c:out value="${maxDia}"/>
                    </span>
                    <span class="cal-kpi__label">Máx. clases/día</span>
                </div>
            </div>

            <%-- ══════════════════════════════════════════════════
                 CALENDARIO — solo se renderiza si hay horarios
                 ══════════════════════════════════════════════════ --%>
            <c:choose>
                <c:when test="${not empty horarios}">

                    <%-- ══════════════════════════════════════════
                         VISTA GRILLA (desktop ≥ 900px)
                         ══════════════════════════════════════════ --%>
                    <div class="cal-wrapper cal-grid-view">

                        <%-- Barra de navegación / info del calendario --%>
                        <div class="cal-nav">
                            <div>
                                <p class="cal-nav__title">Horario semanal recurrente</p>
                                <p class="cal-nav__sub">
                                    Clases disponibles de lunes a domingo
                                </p>
                            </div>
                            <div class="cal-nav__actions">
                                <%-- Leyenda inline compacta --%>
                                <div style="display:flex; align-items:center; gap:0.5rem;">
                                    <span style="display:flex; align-items:center; gap:0.3rem;
                                                 font-size:0.68rem; color:var(--clr-text-dim);">
                                        <span style="width:8px; height:8px; border-radius:2px;
                                                     background:var(--clr-success);"></span>
                                        Programada
                                    </span>
                                    <span style="display:flex; align-items:center; gap:0.3rem;
                                                 font-size:0.68rem; color:var(--clr-text-dim);">
                                        <span style="width:8px; height:8px; border-radius:2px;
                                                     background:var(--clr-text-dim); opacity:0.5;"></span>
                                        Cancelada
                                    </span>
                                </div>
                                <a href="${pageContext.request.contextPath}/schedules"
                                   class="btn btn-ghost btn-sm">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M10.5 19.5 3 12m0 0 7.5-7.5M3 12h18"/>
                                    </svg>
                                    Gestionar clases
                                </a>
                            </div>
                        </div>

                        <%-- Cabecera con nombre de días --%>
                        <div class="cal-header">
                            <div class="cal-header__spacer"></div>

                            <%-- Lunes --%>
                            <div class="cal-header__day ${diaSemanaHoy eq 1 ? 'is-today' : ''}">
                                <span class="cal-header__day-name">Lun</span>
                                <span class="cal-header__day-count ${cntLun > 0 ? 'has-classes' : ''}">
                                    <c:out value="${cntLun}"/>
                                </span>
                            </div>
                            <%-- Martes --%>
                            <div class="cal-header__day ${diaSemanaHoy eq 2 ? 'is-today' : ''}">
                                <span class="cal-header__day-name">Mar</span>
                                <span class="cal-header__day-count ${cntMar > 0 ? 'has-classes' : ''}">
                                    <c:out value="${cntMar}"/>
                                </span>
                            </div>
                            <%-- Miércoles --%>
                            <div class="cal-header__day ${diaSemanaHoy eq 3 ? 'is-today' : ''}">
                                <span class="cal-header__day-name">Mié</span>
                                <span class="cal-header__day-count ${cntMie > 0 ? 'has-classes' : ''}">
                                    <c:out value="${cntMie}"/>
                                </span>
                            </div>
                            <%-- Jueves --%>
                            <div class="cal-header__day ${diaSemanaHoy eq 4 ? 'is-today' : ''}">
                                <span class="cal-header__day-name">Jue</span>
                                <span class="cal-header__day-count ${cntJue > 0 ? 'has-classes' : ''}">
                                    <c:out value="${cntJue}"/>
                                </span>
                            </div>
                            <%-- Viernes --%>
                            <div class="cal-header__day ${diaSemanaHoy eq 5 ? 'is-today' : ''}">
                                <span class="cal-header__day-name">Vie</span>
                                <span class="cal-header__day-count ${cntVie > 0 ? 'has-classes' : ''}">
                                    <c:out value="${cntVie}"/>
                                </span>
                            </div>
                            <%-- Sábado --%>
                            <div class="cal-header__day ${diaSemanaHoy eq 6 ? 'is-today' : ''}">
                                <span class="cal-header__day-name">Sáb</span>
                                <span class="cal-header__day-count ${cntSab > 0 ? 'has-classes' : ''}">
                                    <c:out value="${cntSab}"/>
                                </span>
                            </div>
                            <%-- Domingo --%>
                            <div class="cal-header__day ${diaSemanaHoy eq 7 ? 'is-today' : ''}">
                                <span class="cal-header__day-name">Dom</span>
                                <span class="cal-header__day-count ${cntDom > 0 ? 'has-classes' : ''}">
                                    <c:out value="${cntDom}"/>
                                </span>
                            </div>
                        </div>

                        <%-- Cuerpo del calendario — 7 columnas (1 por día) --%>
                        <div class="cal-body">

                            <%-- Columna de hora (decorativa) --%>
                            <div class="cal-time-col"></div>

                            <%-- ── Columna Lunes (dia=1) ─────────────────── --%>
                            <div class="cal-day-col ${cntLun eq 0 ? 'is-empty' : ''}"
                                 aria-label="Lunes">
                                <c:forEach var="h" items="${horarios}">
                                    <c:if test="${h.diaSemana eq 1}">
                                        <c:set var="evIdx" value="${h.clase.tipoClase != null ? h.clase.tipoClase.id : 'ev--0'}"/>
                                        <a href="${pageContext.request.contextPath}/schedules?action=inscritos&id=<c:out value='${h.clase.id}'/>"
                                           class="cal-event ev--0 ${h.estado eq 'cancelado' ? 'is-cancelled' : ''}"
                                           title="${h.clase.nombreClase} — ${h.rangoHorario}">

                                            <c:if test="${h.estado eq 'cancelado'}">
                                                <div class="cal-event__cancelled" aria-label="Cancelada">
                                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                                                        <path stroke-linecap="round" stroke-linejoin="round"
                                                              d="M6 18 18 6M6 6l12 12"/>
                                                    </svg>
                                                </div>
                                            </c:if>

                                            <span class="cal-event__nombre">
                                                <c:out value="${h.clase.nombreClase}"/>
                                            </span>
                                            <div class="cal-event__time">
                                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                                    <path stroke-linecap="round" stroke-linejoin="round"
                                                          d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                                </svg>
                                                <c:out value="${h.rangoHorario}"/>
                                            </div>
                                            <c:if test="${h.clase.tipoClase != null}">
                                                <span class="cal-event__tipo">
                                                    <c:out value="${h.clase.tipoClase.nombre}"/>
                                                </span>
                                            </c:if>
                                        </a>
                                    </c:if>
                                </c:forEach>
                            </div>

                            <%-- ── Columna Martes (dia=2) ────────────────── --%>
                            <div class="cal-day-col ${cntMar eq 0 ? 'is-empty' : ''}"
                                 aria-label="Martes">
                                <c:forEach var="h" items="${horarios}">
                                    <c:if test="${h.diaSemana eq 2}">
                                        <a href="${pageContext.request.contextPath}/schedules?action=inscritos&id=<c:out value='${h.clase.id}'/>"
                                           class="cal-event ev--1 ${h.estado eq 'cancelado' ? 'is-cancelled' : ''}"
                                           title="${h.clase.nombreClase} — ${h.rangoHorario}">
                                            <c:if test="${h.estado eq 'cancelado'}">
                                                <div class="cal-event__cancelled">
                                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                                                        <path stroke-linecap="round" stroke-linejoin="round"
                                                              d="M6 18 18 6M6 6l12 12"/>
                                                    </svg>
                                                </div>
                                            </c:if>
                                            <span class="cal-event__nombre">
                                                <c:out value="${h.clase.nombreClase}"/>
                                            </span>
                                            <div class="cal-event__time">
                                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                                    <path stroke-linecap="round" stroke-linejoin="round"
                                                          d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                                </svg>
                                                <c:out value="${h.rangoHorario}"/>
                                            </div>
                                            <c:if test="${h.clase.tipoClase != null}">
                                                <span class="cal-event__tipo">
                                                    <c:out value="${h.clase.tipoClase.nombre}"/>
                                                </span>
                                            </c:if>
                                        </a>
                                    </c:if>
                                </c:forEach>
                            </div>

                            <%-- ── Columna Miércoles (dia=3) ─────────────── --%>
                            <div class="cal-day-col ${cntMie eq 0 ? 'is-empty' : ''}"
                                 aria-label="Miércoles">
                                <c:forEach var="h" items="${horarios}">
                                    <c:if test="${h.diaSemana eq 3}">
                                        <a href="${pageContext.request.contextPath}/schedules?action=inscritos&id=<c:out value='${h.clase.id}'/>"
                                           class="cal-event ev--2 ${h.estado eq 'cancelado' ? 'is-cancelled' : ''}"
                                           title="${h.clase.nombreClase} — ${h.rangoHorario}">
                                            <c:if test="${h.estado eq 'cancelado'}">
                                                <div class="cal-event__cancelled">
                                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                                                        <path stroke-linecap="round" stroke-linejoin="round"
                                                              d="M6 18 18 6M6 6l12 12"/>
                                                    </svg>
                                                </div>
                                            </c:if>
                                            <span class="cal-event__nombre">
                                                <c:out value="${h.clase.nombreClase}"/>
                                            </span>
                                            <div class="cal-event__time">
                                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                                    <path stroke-linecap="round" stroke-linejoin="round"
                                                          d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                                </svg>
                                                <c:out value="${h.rangoHorario}"/>
                                            </div>
                                            <c:if test="${h.clase.tipoClase != null}">
                                                <span class="cal-event__tipo">
                                                    <c:out value="${h.clase.tipoClase.nombre}"/>
                                                </span>
                                            </c:if>
                                        </a>
                                    </c:if>
                                </c:forEach>
                            </div>

                            <%-- ── Columna Jueves (dia=4) ─────────────────── --%>
                            <div class="cal-day-col ${cntJue eq 0 ? 'is-empty' : ''}"
                                 aria-label="Jueves">
                                <c:forEach var="h" items="${horarios}">
                                    <c:if test="${h.diaSemana eq 4}">
                                        <a href="${pageContext.request.contextPath}/schedules?action=inscritos&id=<c:out value='${h.clase.id}'/>"
                                           class="cal-event ev--3 ${h.estado eq 'cancelado' ? 'is-cancelled' : ''}"
                                           title="${h.clase.nombreClase} — ${h.rangoHorario}">
                                            <c:if test="${h.estado eq 'cancelado'}">
                                                <div class="cal-event__cancelled">
                                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                                                        <path stroke-linecap="round" stroke-linejoin="round"
                                                              d="M6 18 18 6M6 6l12 12"/>
                                                    </svg>
                                                </div>
                                            </c:if>
                                            <span class="cal-event__nombre">
                                                <c:out value="${h.clase.nombreClase}"/>
                                            </span>
                                            <div class="cal-event__time">
                                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                                    <path stroke-linecap="round" stroke-linejoin="round"
                                                          d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                                </svg>
                                                <c:out value="${h.rangoHorario}"/>
                                            </div>
                                            <c:if test="${h.clase.tipoClase != null}">
                                                <span class="cal-event__tipo">
                                                    <c:out value="${h.clase.tipoClase.nombre}"/>
                                                </span>
                                            </c:if>
                                        </a>
                                    </c:if>
                                </c:forEach>
                            </div>

                            <%-- ── Columna Viernes (dia=5) ─────────────────── --%>
                            <div class="cal-day-col ${cntVie eq 0 ? 'is-empty' : ''}"
                                 aria-label="Viernes">
                                <c:forEach var="h" items="${horarios}">
                                    <c:if test="${h.diaSemana eq 5}">
                                        <a href="${pageContext.request.contextPath}/schedules?action=inscritos&id=<c:out value='${h.clase.id}'/>"
                                           class="cal-event ev--4 ${h.estado eq 'cancelado' ? 'is-cancelled' : ''}"
                                           title="${h.clase.nombreClase} — ${h.rangoHorario}">
                                            <c:if test="${h.estado eq 'cancelado'}">
                                                <div class="cal-event__cancelled">
                                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                                                        <path stroke-linecap="round" stroke-linejoin="round"
                                                              d="M6 18 18 6M6 6l12 12"/>
                                                    </svg>
                                                </div>
                                            </c:if>
                                            <span class="cal-event__nombre">
                                                <c:out value="${h.clase.nombreClase}"/>
                                            </span>
                                            <div class="cal-event__time">
                                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                                    <path stroke-linecap="round" stroke-linejoin="round"
                                                          d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                                </svg>
                                                <c:out value="${h.rangoHorario}"/>
                                            </div>
                                            <c:if test="${h.clase.tipoClase != null}">
                                                <span class="cal-event__tipo">
                                                    <c:out value="${h.clase.tipoClase.nombre}"/>
                                                </span>
                                            </c:if>
                                        </a>
                                    </c:if>
                                </c:forEach>
                            </div>

                            <%-- ── Columna Sábado (dia=6) ──────────────────── --%>
                            <div class="cal-day-col ${cntSab eq 0 ? 'is-empty' : ''}"
                                 aria-label="Sábado">
                                <c:forEach var="h" items="${horarios}">
                                    <c:if test="${h.diaSemana eq 6}">
                                        <a href="${pageContext.request.contextPath}/schedules?action=inscritos&id=<c:out value='${h.clase.id}'/>"
                                           class="cal-event ev--5 ${h.estado eq 'cancelado' ? 'is-cancelled' : ''}"
                                           title="${h.clase.nombreClase} — ${h.rangoHorario}">
                                            <c:if test="${h.estado eq 'cancelado'}">
                                                <div class="cal-event__cancelled">
                                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                                                        <path stroke-linecap="round" stroke-linejoin="round"
                                                              d="M6 18 18 6M6 6l12 12"/>
                                                    </svg>
                                                </div>
                                            </c:if>
                                            <span class="cal-event__nombre">
                                                <c:out value="${h.clase.nombreClase}"/>
                                            </span>
                                            <div class="cal-event__time">
                                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                                    <path stroke-linecap="round" stroke-linejoin="round"
                                                          d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                                </svg>
                                                <c:out value="${h.rangoHorario}"/>
                                            </div>
                                            <c:if test="${h.clase.tipoClase != null}">
                                                <span class="cal-event__tipo">
                                                    <c:out value="${h.clase.tipoClase.nombre}"/>
                                                </span>
                                            </c:if>
                                        </a>
                                    </c:if>
                                </c:forEach>
                            </div>

                            <%-- ── Columna Domingo (dia=7) ─────────────────── --%>
                            <div class="cal-day-col ${cntDom eq 0 ? 'is-empty' : ''}"
                                 aria-label="Domingo">
                                <c:forEach var="h" items="${horarios}">
                                    <c:if test="${h.diaSemana eq 7}">
                                        <a href="${pageContext.request.contextPath}/schedules?action=inscritos&id=<c:out value='${h.clase.id}'/>"
                                           class="cal-event ev--0 ${h.estado eq 'cancelado' ? 'is-cancelled' : ''}"
                                           title="${h.clase.nombreClase} — ${h.rangoHorario}">
                                            <c:if test="${h.estado eq 'cancelado'}">
                                                <div class="cal-event__cancelled">
                                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                                                        <path stroke-linecap="round" stroke-linejoin="round"
                                                              d="M6 18 18 6M6 6l12 12"/>
                                                    </svg>
                                                </div>
                                            </c:if>
                                            <span class="cal-event__nombre">
                                                <c:out value="${h.clase.nombreClase}"/>
                                            </span>
                                            <div class="cal-event__time">
                                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                                    <path stroke-linecap="round" stroke-linejoin="round"
                                                          d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                                </svg>
                                                <c:out value="${h.rangoHorario}"/>
                                            </div>
                                            <c:if test="${h.clase.tipoClase != null}">
                                                <span class="cal-event__tipo">
                                                    <c:out value="${h.clase.tipoClase.nombre}"/>
                                                </span>
                                            </c:if>
                                        </a>
                                    </c:if>
                                </c:forEach>
                            </div>

                        </div><%-- /cal-body --%>

                        <%-- Leyenda de tipos al pie --%>
                        <div class="cal-legend">
                            <span class="cal-legend__title">Tipos de clase</span>
                            <div class="cal-legend__items">
                                <div class="cal-legend__item">
                                    <span class="cal-legend__dot" style="background:var(--clr-red);"></span>
                                    Cardio
                                </div>
                                <div class="cal-legend__item">
                                    <span class="cal-legend__dot" style="background:#a78bfa;"></span>
                                    Yoga
                                </div>
                                <div class="cal-legend__item">
                                    <span class="cal-legend__dot" style="background:#f97316;"></span>
                                    Box
                                </div>
                                <div class="cal-legend__item">
                                    <span class="cal-legend__dot" style="background:#2dd4bf;"></span>
                                    Funcional
                                </div>
                                <div class="cal-legend__item">
                                    <span class="cal-legend__dot" style="background:var(--clr-success);"></span>
                                    Otro
                                </div>
                            </div>
                            <span style="margin-left:auto; font-size:0.70rem; color:var(--clr-text-dim);">
                                Haz clic en una clase para ver sus inscritos
                            </span>
                        </div>

                    </div><%-- /cal-wrapper (grid) --%>

                    <%-- ══════════════════════════════════════════
                         VISTA LISTA (mobile ≤ 900px)
                         ══════════════════════════════════════════ --%>
                    <div class="cal-wrapper cal-list-view">

                        <div class="cal-nav">
                            <p class="cal-nav__title">Horario semanal recurrente</p>
                            <a href="${pageContext.request.contextPath}/schedules"
                               class="btn btn-ghost btn-sm">
                                Gestionar clases
                            </a>
                        </div>

                        <%-- Un bloque por cada día de la semana --%>
                        <c:forEach var="d" begin="1" end="7">

                            <%-- Calcular nombre y cuenta del día --%>
                            <c:set var="nombreDia" value="Lunes"/>
                            <c:set var="cntDiaActual" value="${cntLun}"/>
                            <c:if test="${d eq 2}"><c:set var="nombreDia" value="Martes"/>   <c:set var="cntDiaActual" value="${cntMar}"/></c:if>
                            <c:if test="${d eq 3}"><c:set var="nombreDia" value="Miércoles"/><c:set var="cntDiaActual" value="${cntMie}"/></c:if>
                            <c:if test="${d eq 4}"><c:set var="nombreDia" value="Jueves"/>   <c:set var="cntDiaActual" value="${cntJue}"/></c:if>
                            <c:if test="${d eq 5}"><c:set var="nombreDia" value="Viernes"/>  <c:set var="cntDiaActual" value="${cntVie}"/></c:if>
                            <c:if test="${d eq 6}"><c:set var="nombreDia" value="Sábado"/>   <c:set var="cntDiaActual" value="${cntSab}"/></c:if>
                            <c:if test="${d eq 7}"><c:set var="nombreDia" value="Domingo"/>  <c:set var="cntDiaActual" value="${cntDom}"/></c:if>

                            <div class="cal-list-day ${diaSemanaHoy eq d ? 'is-today' : ''}">
                                <div class="cal-list-day__header">
                                    <span class="cal-list-day__name">
                                        <c:out value="${nombreDia}"/>
                                        <c:if test="${diaSemanaHoy eq d}">
                                            &nbsp;
                                            <span style="font-size:0.62rem; background:var(--clr-red-subtle);
                                                         color:var(--clr-red); border:1px solid rgba(230,48,39,0.22);
                                                         border-radius:var(--radius-full); padding:0.1rem 0.45rem;
                                                         font-weight:700; letter-spacing:0.06em; vertical-align:middle;">
                                                Hoy
                                            </span>
                                        </c:if>
                                    </span>
                                    <span class="cal-list-day__count">
                                        <c:out value="${cntDiaActual}"/>
                                    </span>
                                </div>

                                <c:set var="tienePorEsseDia" value="false"/>
                                <c:forEach var="h" items="${horarios}">
                                    <c:if test="${h.diaSemana eq d}">
                                        <c:set var="tienePorEsseDia" value="true"/>

                                        <%-- Color de acento según índice --%>
                                        <c:set var="listAccent" value="var(--clr-red)"/>
                                        <c:if test="${d eq 2}"><c:set var="listAccent" value="#a78bfa"/></c:if>
                                        <c:if test="${d eq 3}"><c:set var="listAccent" value="#f97316"/></c:if>
                                        <c:if test="${d eq 4}"><c:set var="listAccent" value="#2dd4bf"/></c:if>
                                        <c:if test="${d eq 5}"><c:set var="listAccent" value="var(--clr-success)"/></c:if>
                                        <c:if test="${d eq 6}"><c:set var="listAccent" value="var(--clr-info)"/></c:if>
                                        <c:if test="${d eq 7}"><c:set var="listAccent" value="var(--clr-red)"/></c:if>

                                        <a href="${pageContext.request.contextPath}/schedules?action=inscritos&id=<c:out value='${h.clase.id}'/>"
                                           class="cal-list-event ${h.estado eq 'cancelado' ? 'is-cancelled' : ''}"
                                           style="--event-accent:${listAccent}; text-decoration:none;">
                                            <div class="cal-list-event__accent"></div>
                                            <div class="cal-list-event__time">
                                                <c:out value="${h.rangoHorario}"/>
                                            </div>
                                            <div class="cal-list-event__info">
                                                <p class="cal-list-event__nombre">
                                                    <c:out value="${h.clase.nombreClase}"/>
                                                </p>
                                                <p class="cal-list-event__tipo">
                                                    <c:choose>
                                                        <c:when test="${h.clase.tipoClase != null}">
                                                            <c:out value="${h.clase.tipoClase.nombre}"/>
                                                        </c:when>
                                                        <c:otherwise>Clase grupal</c:otherwise>
                                                    </c:choose>
                                                    <c:if test="${h.estado eq 'cancelado'}">
                                                        &nbsp;·&nbsp;
                                                        <span style="color:var(--clr-red);">Cancelada</span>
                                                    </c:if>
                                                </p>
                                            </div>
                                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8"
                                                 style="width:13px;height:13px;flex-shrink:0;color:var(--clr-text-dim);">
                                                <path stroke-linecap="round" stroke-linejoin="round"
                                                      d="M13.5 4.5 21 12m0 0-7.5 7.5M21 12H3"/>
                                            </svg>
                                        </a>
                                    </c:if>
                                </c:forEach>

                                <c:if test="${cntDiaActual eq 0}">
                                    <p class="cal-list-day__empty">Sin clases programadas</p>
                                </c:if>

                            </div><%-- /cal-list-day --%>
                        </c:forEach>

                        <%-- Pie de la vista lista --%>
                        <div style="padding:0.75rem 1.25rem; border-top:1px solid var(--clr-border-light);
                                    background:rgba(255,255,255,0.012);
                                    font-size:0.72rem; color:var(--clr-text-dim);
                                    display:flex; align-items:center; justify-content:space-between;">
                            <span>
                                <strong style="color:var(--clr-text-muted);">
                                    <c:out value="${fn:length(horarios)}"/>
                                </strong>
                                horario<c:if test="${fn:length(horarios) ne 1}">s</c:if> en total
                            </span>
                            <a href="${pageContext.request.contextPath}/schedules"
                               class="btn btn-ghost btn-sm">
                                Ver todas las clases
                            </a>
                        </div>

                    </div><%-- /cal-wrapper (lista) --%>

                    <%-- ── Nota informativa al pie ─────────────────────────── --%>
                    <div style="margin-top:1rem; padding:0.85rem 1.1rem;
                                background:var(--clr-card); border:1px solid var(--clr-card-border);
                                border-radius:var(--radius-md);
                                display:flex; align-items:center; gap:0.65rem;">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8"
                             style="width:14px;height:14px;flex-shrink:0;color:var(--clr-text-dim);">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="m11.25 11.25.041-.02a.75.75 0 0 1 1.063.852l-.708 2.836a.75.75
                                     0 0 0 1.063.853l.041-.021M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9-3.75h.008v.008H12V8.25Z"/>
                        </svg>
                        <p style="font-size:0.73rem; color:var(--clr-text-dim); line-height:1.5;">
                            Este calendario muestra el programa recurrente semanal.
                            Los horarios mostrados son los
                            <strong style="color:var(--clr-text-muted);">mismos cada semana</strong>.
                            Haz clic en cualquier clase para ver sus alumnos inscritos y cupos disponibles.
                            <c:if test="${sessionScope.userRole eq 'ROL-ADMIN'}">
                                Para agregar o eliminar horarios, usa
                                <a href="${pageContext.request.contextPath}/schedules"
                                   style="color:var(--clr-red); font-weight:600;">
                                    Gestionar clases
                                </a>.
                            </c:if>
                        </p>
                    </div>

                </c:when>

                <%-- ── Estado vacío ────────────────────────────────────── --%>
                <c:otherwise>
                    <div class="cal-wrapper">
                        <div class="cal-empty">
                            <div class="cal-empty__icon">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25
                                             2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0
                                             0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5"/>
                                </svg>
                            </div>
                            <p class="cal-empty__title">Sin horarios registrados</p>
                            <p class="cal-empty__desc">
                                El calendario está vacío. Crea clases y agrégales horarios
                                para que aparezcan aquí.
                            </p>
                            <c:if test="${sessionScope.userRole eq 'ROL-ADMIN'}">
                                <div style="display:flex; gap:0.65rem; margin-top:0.5rem; flex-wrap:wrap; justify-content:center;">
                                    <a href="${pageContext.request.contextPath}/schedules?action=new"
                                       class="btn btn-primary btn-sm">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.2">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M12 4.5v15m7.5-7.5h-15"/>
                                        </svg>
                                        Crear primera clase
                                    </a>
                                    <a href="${pageContext.request.contextPath}/schedules"
                                       class="btn btn-secondary btn-sm">
                                        Ver clases existentes
                                    </a>
                                </div>
                            </c:if>
                        </div>
                    </div>
                </c:otherwise>
            </c:choose>

        </div><%-- /page-content --%>
    </div><%-- /app-main --%>
</div><%-- /app-shell --%>

</body>
</html>
