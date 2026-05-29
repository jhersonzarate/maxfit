<%-- ============================================================
     attendance.jsp  —  MaxFit Sistema de Gestión
     Módulo de control de asistencia y check-in de clientes.

     Servlet:  AttendanceController.java  → GET/POST /attendance
     Acceso:   ROL-ADMIN | ROL-RECEP  (RoleFilter)

     ── Parámetros de URL que activan vistas ──────────────────
       /attendance                   → panel de check-in (default)
       /attendance?action=hist       → historial filtrable

     ── Atributos de request ─────────────────────────────────

     Vista check-in (default):
       asistenciasRecientes (List<Asistencia>)  → últimas 20
       countHoy             (int)               → check-ins del día

     Vista historial (?action=hist):
       clientes     (List<Cliente>)   → para el select de filtro
       historial    (List<Asistencia>)→ resultados filtrados
       clienteId    (String, null)    → filtro activo cliente
       desde        (String, null)    → filtro fecha desde
       hasta        (String, null)    → filtro fecha hasta
       totalFiltro  (int)             → cantidad de resultados

     Resultado de check-in (post-redirect-get):
       successMsg              → ingreso OK (request attr)
       errorMsg                → error de check-in (request attr)
       sessionScope.checkInCliente   → nombre del cliente
       sessionScope.checkInMembresia → membresía del cliente
       sessionScope.checkInTipo      → tipo de error (enum)

     Flash (via transferirFlashMessages):
       successMsg / errorMsg
     ============================================================ --%>
<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="fn"  uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <%@ include file="/WEB-INF/views/includes/head-common.jsp" %>
    <c:choose>
        <c:when test="${param.action eq 'hist'}">
            <c:set var="pageTitle" value="Historial de Asistencia" scope="request"/>
        </c:when>
        <c:otherwise>
            <c:set var="pageTitle" value="Control de Asistencia" scope="request"/>
        </c:otherwise>
    </c:choose>
    <link rel="stylesheet"
          href="${pageContext.request.contextPath}/static/css/modules.css">

    <style>
        /* ══════════════════════════════════════════════════════
           ESTILOS ESPECÍFICOS — MÓDULO DE ASISTENCIA
           ══════════════════════════════════════════════════════ */

        /* ── Grid principal del panel de check-in ─────────── */
        .att-grid {
            display: grid;
            grid-template-columns: 400px 1fr;
            gap: 1.25rem;
            align-items: start;
        }

        /* ── KPI strip de cabecera ─────────────────────────── */
        .att-kpi-strip {
            display: flex;
            align-items: center;
            gap: 1rem;
            padding: 0.9rem 1.25rem;
            background: var(--clr-card);
            border: 1px solid var(--clr-card-border);
            border-radius: var(--radius-lg);
            margin-bottom: 1.25rem;
            position: relative;
            overflow: hidden;
        }

        .att-kpi-strip::after {
            content: '';
            position: absolute;
            left: 0; top: 0; bottom: 0;
            width: 3px;
            background: var(--clr-red);
            border-radius: 0 2px 2px 0;
        }

        .att-kpi-strip__num {
            font-family: var(--font-display);
            font-size: 2rem;
            font-weight: 800;
            line-height: 1;
            color: var(--clr-text);
            letter-spacing: 0.02em;
        }

        .att-kpi-strip__label {
            font-size: 0.73rem;
            font-weight: 600;
            color: var(--clr-text-muted);
            letter-spacing: 0.08em;
            text-transform: uppercase;
        }

        .att-kpi-strip__sep {
            width: 1px;
            height: 36px;
            background: var(--clr-border);
            margin: 0 0.25rem;
        }

        .att-kpi-strip__actions {
            margin-left: auto;
            display: flex;
            align-items: center;
            gap: 0.6rem;
        }

        /* ── Tarjeta de check-in ──────────────────────────── */
        .att-checkin-card {
            background: var(--clr-card);
            border: 1px solid var(--clr-card-border);
            border-radius: var(--radius-xl);
            overflow: hidden;
            position: relative;
        }

        .att-checkin-card::before {
            content: '';
            position: absolute;
            top: -80px; right: -80px;
            width: 200px; height: 200px;
            background: radial-gradient(circle, var(--clr-red-glow) 0%, transparent 65%);
            pointer-events: none;
        }

        .att-checkin-card__header {
            padding: 1.1rem 1.35rem 0.9rem;
            border-bottom: 1px solid var(--clr-border);
            display: flex;
            align-items: center;
            gap: 0.65rem;
        }

        .att-checkin-card__icon {
            flex-shrink: 0;
            width: 36px; height: 36px;
            border-radius: var(--radius-md);
            background: var(--clr-red-subtle);
            display: flex; align-items: center; justify-content: center;
        }

        .att-checkin-card__icon svg {
            width: 18px; height: 18px;
            color: var(--clr-red);
        }

        .att-checkin-card__title {
            font-family: var(--font-display);
            font-weight: 700;
            font-size: 1.05rem;
            letter-spacing: 0.04em;
            text-transform: uppercase;
            color: var(--clr-text);
        }

        .att-checkin-card__body {
            padding: 1.35rem;
            display: flex;
            flex-direction: column;
            gap: 1rem;
        }

        /* Etiqueta instructiva */
        .att-instruction {
            font-size: 0.78rem;
            color: var(--clr-text-muted);
            line-height: 1.55;
            display: flex;
            align-items: flex-start;
            gap: 0.45rem;
            padding: 0.65rem 0.85rem;
            background: var(--clr-surface);
            border-radius: var(--radius-md);
            border: 1px solid var(--clr-border-light);
        }

        .att-instruction svg {
            width: 14px; height: 14px;
            color: var(--clr-text-dim);
            flex-shrink: 0;
            margin-top: 1px;
        }

        /* Input de documento */
        .att-input-wrapper {
            position: relative;
        }

        .att-input-wrapper__icon {
            position: absolute;
            left: 1rem; top: 50%;
            transform: translateY(-50%);
            width: 18px; height: 18px;
            color: var(--clr-text-dim);
            pointer-events: none;
            transition: color var(--transition);
        }

        .att-input {
            width: 100%;
            padding: 0.95rem 1rem 0.95rem 3rem;
            background: var(--clr-surface);
            border: 1.5px solid var(--clr-border);
            border-radius: var(--radius-md);
            color: var(--clr-text);
            font-family: var(--font-mono);
            font-size: 1.05rem;
            font-weight: 600;
            letter-spacing: 0.08em;
            outline: none;
            transition: border-color var(--transition), background var(--transition),
                        box-shadow var(--transition);
            -webkit-appearance: none;
        }

        .att-input::placeholder {
            font-family: var(--font-body);
            font-weight: 400;
            font-size: 0.88rem;
            letter-spacing: 0;
            color: var(--clr-text-dim);
        }

        .att-input:focus {
            border-color: var(--clr-red);
            background: var(--clr-surface-2);
            box-shadow: 0 0 0 3px var(--clr-red-glow);
        }

        .att-input:focus ~ .att-input-wrapper__icon {
            color: var(--clr-red);
        }

        /* Botón principal de check-in */
        .att-btn {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 0.6rem;
            width: 100%;
            padding: 0.95rem 1.25rem;
            background: var(--clr-red);
            color: #fff;
            border: none;
            border-radius: var(--radius-md);
            font-family: var(--font-body);
            font-size: 0.95rem;
            font-weight: 700;
            letter-spacing: 0.03em;
            cursor: pointer;
            box-shadow: 0 3px 18px rgba(230,48,39,0.40);
            transition: background var(--transition), box-shadow var(--transition),
                        transform var(--transition);
        }

        .att-btn svg {
            width: 18px; height: 18px;
            transition: transform var(--transition);
        }

        .att-btn:hover {
            background: var(--clr-red-hover);
            box-shadow: 0 5px 26px rgba(230,48,39,0.55);
            transform: translateY(-1px);
        }

        .att-btn:hover svg { transform: scale(1.15); }
        .att-btn:active  { transform: translateY(0); }

        /* ── Widget de resultado del check-in ──────────────── */
        .att-result {
            border-radius: var(--radius-md);
            padding: 1rem 1.1rem;
            display: flex;
            align-items: flex-start;
            gap: 0.75rem;
            animation: flashIn 0.3s cubic-bezier(0.4,0,0.2,1) both;
        }

        .att-result__icon {
            flex-shrink: 0;
            width: 40px; height: 40px;
            border-radius: var(--radius-md);
            display: flex; align-items: center; justify-content: center;
        }

        .att-result__icon svg { width: 20px; height: 20px; }

        .att-result__body { flex: 1; min-width: 0; }

        .att-result__nombre {
            font-size: 0.92rem;
            font-weight: 700;
            color: var(--clr-text);
            line-height: 1.3;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .att-result__membresia {
            font-size: 0.75rem;
            color: var(--clr-text-muted);
            margin-top: 0.1rem;
        }

        .att-result__msg {
            font-size: 0.80rem;
            margin-top: 0.25rem;
            line-height: 1.4;
        }

        /* Variantes */
        .att-result--ok {
            background: var(--clr-success-subtle);
            border: 1px solid rgba(34,197,94,0.22);
        }
        .att-result--ok .att-result__icon {
            background: rgba(34,197,94,0.15);
        }
        .att-result--ok .att-result__icon svg { color: var(--clr-success); }
        .att-result--ok .att-result__msg      { color: #86efac; }

        .att-result--warn {
            background: var(--clr-warning-subtle);
            border: 1px solid rgba(245,158,11,0.22);
        }
        .att-result--warn .att-result__icon {
            background: rgba(245,158,11,0.15);
        }
        .att-result--warn .att-result__icon svg { color: var(--clr-warning); }
        .att-result--warn .att-result__msg      { color: #fcd34d; }

        .att-result--error {
            background: var(--clr-danger-subtle);
            border: 1px solid rgba(230,48,39,0.22);
        }
        .att-result--error .att-result__icon {
            background: rgba(230,48,39,0.12);
        }
        .att-result--error .att-result__icon svg { color: var(--clr-red); }
        .att-result--error .att-result__msg      { color: #fca5a5; }

        /* Divider "accesos rápidos" */
        .att-divider {
            display: flex;
            align-items: center;
            gap: 0.65rem;
        }

        .att-divider::before, .att-divider::after {
            content: '';
            flex: 1;
            height: 1px;
            background: var(--clr-border-light);
        }

        .att-divider__text {
            font-size: 0.67rem;
            font-weight: 700;
            color: var(--clr-text-dim);
            letter-spacing: 0.12em;
            text-transform: uppercase;
            white-space: nowrap;
        }

        /* Quick links en el panel */
        .att-quick-links {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 0.45rem;
        }

        .att-quick-link {
            display: flex;
            align-items: center;
            gap: 0.4rem;
            padding: 0.55rem 0.75rem;
            background: var(--clr-surface);
            border: 1px solid var(--clr-border);
            border-radius: var(--radius-md);
            font-size: 0.75rem;
            font-weight: 600;
            color: var(--clr-text-muted);
            text-decoration: none;
            transition: all var(--transition);
        }

        .att-quick-link svg { width: 13px; height: 13px; flex-shrink: 0; }

        .att-quick-link:hover {
            background: var(--clr-surface-2);
            border-color: rgba(255,255,255,0.12);
            color: var(--clr-text);
            transform: translateY(-1px);
        }

        /* ── Feed de actividad reciente (columna derecha) ──── */
        .att-feed-card {
            background: var(--clr-card);
            border: 1px solid var(--clr-card-border);
            border-radius: var(--radius-xl);
            overflow: hidden;
        }

        .att-feed-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 0.9rem 1.25rem;
            border-bottom: 1px solid var(--clr-border);
            gap: 0.75rem;
        }

        .att-feed-header__left {
            display: flex;
            align-items: center;
            gap: 0.55rem;
        }

        .att-feed-header__icon {
            flex-shrink: 0;
            width: 30px; height: 30px;
            border-radius: var(--radius-sm);
            background: var(--clr-success-subtle);
            display: flex; align-items: center; justify-content: center;
        }

        .att-feed-header__icon svg {
            width: 14px; height: 14px;
            color: var(--clr-success);
        }

        .att-feed-header__title {
            font-size: 0.85rem;
            font-weight: 600;
            color: var(--clr-text);
        }

        .att-feed-header__count {
            font-family: var(--font-mono);
            font-size: 0.70rem;
            font-weight: 700;
            padding: 0.14rem 0.52rem;
            border-radius: var(--radius-full);
            background: var(--clr-surface-2);
            border: 1px solid var(--clr-border);
            color: var(--clr-text-muted);
        }

        .att-feed-header__link {
            font-size: 0.73rem;
            color: var(--clr-text-dim);
            text-decoration: none;
            display: flex;
            align-items: center;
            gap: 0.28rem;
            transition: color var(--transition), gap var(--transition);
            flex-shrink: 0;
        }

        .att-feed-header__link svg { width: 11px; height: 11px; }
        .att-feed-header__link:hover { color: var(--clr-red); gap: 0.42rem; }

        /* Filas del feed */
        .att-feed-row {
            display: flex;
            align-items: center;
            gap: 0.85rem;
            padding: 0.7rem 1.25rem;
            border-bottom: 1px solid var(--clr-border-light);
            transition: background var(--transition);
        }

        .att-feed-row:last-child { border-bottom: none; }
        .att-feed-row:hover { background: rgba(255,255,255,0.02); }

        .att-feed-row__num {
            flex-shrink: 0;
            width: 24px; height: 24px;
            border-radius: var(--radius-sm);
            background: var(--clr-surface-2);
            border: 1px solid var(--clr-border);
            display: flex; align-items: center; justify-content: center;
            font-family: var(--font-mono);
            font-size: 0.62rem;
            font-weight: 700;
            color: var(--clr-text-dim);
        }

        .att-feed-row__dot {
            flex-shrink: 0;
            width: 8px; height: 8px;
            border-radius: 50%;
            background: var(--clr-success);
        }
        .att-feed-row__dot.falto    { background: var(--clr-text-dim); }
        .att-feed-row__dot.pendiente{ background: var(--clr-warning); }

        .att-feed-row__nombre {
            flex: 1;
            font-size: 0.83rem;
            font-weight: 500;
            color: var(--clr-text);
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .att-feed-row__membresia {
            font-size: 0.70rem;
            color: var(--clr-text-dim);
            white-space: nowrap;
            flex-shrink: 0;
            max-width: 130px;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .att-feed-row__fecha {
            flex-shrink: 0;
            font-size: 0.70rem;
            color: var(--clr-text-dim);
            min-width: 80px;
            text-align: center;
        }

        .att-feed-row__hora {
            flex-shrink: 0;
            font-family: var(--font-mono);
            font-size: 0.70rem;
            color: var(--clr-text-muted);
            background: var(--clr-surface);
            padding: 0.15rem 0.45rem;
            border-radius: var(--radius-xs);
            border: 1px solid var(--clr-border-light);
        }

        .att-feed-footer {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 0.7rem 1.25rem;
            border-top: 1px solid var(--clr-border-light);
            background: rgba(255,255,255,0.012);
        }

        .att-feed-footer__stat {
            font-size: 0.73rem;
            color: var(--clr-text-dim);
        }

        .att-feed-footer__stat strong { color: var(--clr-text-muted); }

        /* ── Vista de Historial ──────────────────────────────── */
        .hist-filter-card {
            background: var(--clr-card);
            border: 1px solid var(--clr-card-border);
            border-radius: var(--radius-lg);
            overflow: hidden;
            margin-bottom: 1.25rem;
        }

        .hist-filter-header {
            padding: 0.85rem 1.25rem;
            border-bottom: 1px solid var(--clr-border);
            background: var(--clr-surface);
            font-size: 0.72rem;
            font-weight: 700;
            letter-spacing: 0.10em;
            text-transform: uppercase;
            color: var(--clr-text-muted);
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        .hist-filter-header svg {
            width: 13px; height: 13px;
            color: var(--clr-red);
        }

        .hist-filter-body {
            padding: 1.1rem 1.25rem;
        }

        .hist-filter-row {
            display: grid;
            grid-template-columns: 1fr 180px 180px auto;
            gap: 0.75rem;
            align-items: end;
        }

        .hist-stats-strip {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 0;
            background: var(--clr-card);
            border: 1px solid var(--clr-card-border);
            border-radius: var(--radius-lg);
            overflow: hidden;
            margin-bottom: 1.25rem;
        }

        .hist-stat {
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: 0.9rem 0.75rem;
            gap: 0.2rem;
            border-right: 1px solid var(--clr-border-light);
            transition: background var(--transition);
        }

        .hist-stat:last-child { border-right: none; }
        .hist-stat:hover { background: rgba(255,255,255,0.02); }

        .hist-stat__num {
            font-family: var(--font-display);
            font-size: 1.55rem;
            font-weight: 800;
            line-height: 1;
            color: var(--clr-text);
        }

        .hist-stat__num.red   { color: var(--clr-red); }
        .hist-stat__num.green { color: var(--clr-success); }

        .hist-stat__label {
            font-size: 0.67rem;
            font-weight: 600;
            letter-spacing: 0.08em;
            text-transform: uppercase;
            color: var(--clr-text-dim);
        }

        /* Banner de filtros activos */
        .hist-filter-banner {
            display: flex;
            align-items: center;
            gap: 0.75rem;
            padding: 0.65rem 1rem;
            background: var(--clr-info-subtle);
            border: 1px solid rgba(59,130,246,0.22);
            border-radius: var(--radius-md);
            margin-bottom: 1rem;
        }

        .hist-filter-banner svg {
            width: 14px; height: 14px;
            color: var(--clr-info);
            flex-shrink: 0;
        }

        .hist-filter-banner__text {
            font-size: 0.78rem;
            color: var(--clr-info);
            font-weight: 500;
            flex: 1;
        }

        /* ── Responsive ──────────────────────────────────────── */
        @media (max-width: 1200px) {
            .att-grid {
                grid-template-columns: 360px 1fr;
            }
        }

        @media (max-width: 1024px) {
            .att-grid {
                grid-template-columns: 1fr;
            }
            .hist-filter-row {
                grid-template-columns: 1fr 1fr;
            }
            .hist-filter-row .btn {
                grid-column: span 2;
            }
        }

        @media (max-width: 640px) {
            .hist-filter-row {
                grid-template-columns: 1fr;
            }
            .hist-filter-row .btn {
                grid-column: span 1;
            }
            .att-quick-links {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>

<div class="app-shell">
    <%@ include file="/WEB-INF/views/includes/sidebar.jsp" %>

    <div class="app-main">

        <c:choose>
            <c:when test="${param.action eq 'hist'}">
                <c:set var="pageTitle"    value="Historial de Asistencia" scope="request"/>
                <c:set var="pageSubtitle" value="Registro completo de ingresos" scope="request"/>
            </c:when>
            <c:otherwise>
                <c:set var="pageTitle"    value="Control de Asistencia" scope="request"/>
                <c:set var="pageSubtitle" value="Check-in de clientes" scope="request"/>
            </c:otherwise>
        </c:choose>
        <%@ include file="/WEB-INF/views/includes/navbar.jsp" %>

        <div class="page-content">

            <%-- ═══════════════════════════════════════════════
                 BIFURCACIÓN: panel check-in  ↔  historial
                 ═══════════════════════════════════════════════ --%>
            <c:choose>

                <%-- ──────────────────────────────────────────
                     VISTA: HISTORIAL (?action=hist)
                     ────────────────────────────────────────── --%>
                <c:when test="${param.action eq 'hist'}">

                    <%-- Breadcrumb --%>
                    <nav class="module-breadcrumb" aria-label="Breadcrumb">
                        <a href="${pageContext.request.contextPath}/attendance">Asistencia</a>
                        <svg class="module-breadcrumb__sep" xmlns="http://www.w3.org/2000/svg"
                             fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7"/>
                        </svg>
                        <span>Historial</span>
                    </nav>

                    <%-- Header --%>
                    <div class="module-header">
                        <div class="module-header__left">
                            <h1 class="module-header__title">
                                Historial de Asistencia
                                <c:if test="${not empty totalFiltro}">
                                    <span class="stat-chip">
                                        <c:out value="${totalFiltro}"/>
                                    </span>
                                </c:if>
                            </h1>
                            <div class="module-header__meta">
                                <span>Consulta y filtra registros de ingresos</span>
                            </div>
                        </div>
                        <div class="module-header__actions">
                            <a href="${pageContext.request.contextPath}/attendance"
                               class="btn btn-secondary">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                </svg>
                                Ir a Check-in
                            </a>
                        </div>
                    </div>

                    <%-- Formulario de filtros (GET, sin CSRF) --%>
                    <div class="hist-filter-card">
                        <div class="hist-filter-header">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                      d="M12 3c2.755 0 5.455.232 8.083.678.533.09.917.556.917
                                         1.096v1.044a2.25 2.25 0 0 1-.659 1.591l-5.432 5.432a2.25
                                         2.25 0 0 0-.659 1.591v2.927a2.25 2.25 0 0
                                         1-1.244 2.013L9.75 21v-6.568a2.25 2.25 0 0
                                         0-.659-1.591L3.659 7.409A2.25 2.25 0 0
                                         1 3 5.818V4.774c0-.54.384-1.006.917-1.096A48.32
                                         48.32 0 0 1 12 3Z"/>
                            </svg>
                            Filtrar registros
                        </div>
                        <div class="hist-filter-body">
                            <form action="${pageContext.request.contextPath}/attendance"
                                  method="get"
                                  novalidate>
                                <input type="hidden" name="action" value="hist">
                                <div class="hist-filter-row">

                                    <%-- Filtro por cliente --%>
                                    <div class="form-field">
                                        <label for="fClienteId">Cliente</label>
                                        <select id="fClienteId"
                                                name="clienteId"
                                                class="form-control">
                                            <option value="">— Todos los clientes —</option>
                                            <c:forEach var="cli" items="${clientes}">
                                                <option value="<c:out value='${cli.id}'/>"
                                                    ${clienteId eq cli.id ? 'selected' : ''}>
                                                    <c:out value="${cli.apellido}"/>,
                                                    <c:out value="${cli.nombre}"/>
                                                </option>
                                            </c:forEach>
                                        </select>
                                    </div>

                                    <%-- Filtro desde --%>
                                    <div class="form-field">
                                        <label for="fDesde">Desde</label>
                                        <input type="date"
                                               id="fDesde"
                                               name="desde"
                                               class="form-control"
                                               value="<c:out value='${desde}'/>">
                                    </div>

                                    <%-- Filtro hasta --%>
                                    <div class="form-field">
                                        <label for="fHasta">Hasta</label>
                                        <input type="date"
                                               id="fHasta"
                                               name="hasta"
                                               class="form-control"
                                               value="<c:out value='${hasta}'/>">
                                    </div>

                                    <%-- Botón --%>
                                    <div class="form-field">
                                        <label>&nbsp;</label>
                                        <button type="submit" class="btn btn-primary">
                                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                                <path stroke-linecap="round" stroke-linejoin="round"
                                                      d="m21 21-5.197-5.197m0 0A7.5 7.5 0 1 0 5.196
                                                         5.196a7.5 7.5 0 0 0 10.607 10.607Z"/>
                                            </svg>
                                            Filtrar
                                        </button>
                                    </div>

                                </div>

                                <%-- Limpiar filtros --%>
                                <c:if test="${not empty clienteId or not empty desde or not empty hasta}">
                                    <div style="margin-top:0.65rem;">
                                        <a href="${pageContext.request.contextPath}/attendance?action=hist"
                                           class="btn btn-ghost btn-sm">
                                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                                <path stroke-linecap="round" stroke-linejoin="round"
                                                      d="M6 18 18 6M6 6l12 12"/>
                                            </svg>
                                            Limpiar filtros
                                        </a>
                                    </div>
                                </c:if>
                            </form>
                        </div>
                    </div>

                    <%-- Stats del historial filtrado --%>
                    <c:if test="${not empty historial}">

                        <%-- Contar estados --%>
                        <c:set var="cntAsistio"   value="0"/>
                        <c:set var="cntFalto"     value="0"/>
                        <c:set var="cntPendiente" value="0"/>
                        <c:forEach var="a" items="${historial}">
                            <c:choose>
                                <c:when test="${a.estado eq 'asistio'}">
                                    <c:set var="cntAsistio" value="${cntAsistio + 1}"/>
                                </c:when>
                                <c:when test="${a.estado eq 'falto'}">
                                    <c:set var="cntFalto" value="${cntFalto + 1}"/>
                                </c:when>
                                <c:otherwise>
                                    <c:set var="cntPendiente" value="${cntPendiente + 1}"/>
                                </c:otherwise>
                            </c:choose>
                        </c:forEach>

                        <div class="hist-stats-strip">
                            <div class="hist-stat">
                                <span class="hist-stat__num green"><c:out value="${cntAsistio}"/></span>
                                <span class="hist-stat__label">Asistió</span>
                            </div>
                            <div class="hist-stat">
                                <span class="hist-stat__num red"><c:out value="${cntFalto}"/></span>
                                <span class="hist-stat__label">Faltó</span>
                            </div>
                            <div class="hist-stat">
                                <span class="hist-stat__num"><c:out value="${totalFiltro}"/></span>
                                <span class="hist-stat__label">Total registros</span>
                            </div>
                        </div>
                    </c:if>

                    <%-- Banner de filtros activos --%>
                    <c:if test="${not empty clienteId or not empty desde or not empty hasta}">
                        <div class="hist-filter-banner">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                      d="M12 3c2.755 0 5.455.232 8.083.678.533.09.917.556.917
                                         1.096v1.044a2.25 2.25 0 0 1-.659 1.591l-5.432 5.432a2.25
                                         2.25 0 0 0-.659 1.591v2.927a2.25 2.25 0 0
                                         1-1.244 2.013L9.75 21v-6.568a2.25 2.25 0 0
                                         0-.659-1.591L3.659 7.409A2.25 2.25 0 0 1 3
                                         5.818V4.774c0-.54.384-1.006.917-1.096A48.32 48.32 0 0 1 12 3Z"/>
                            </svg>
                            <span class="hist-filter-banner__text">
                                Filtros activos:
                                <c:if test="${not empty clienteId}">
                                    <strong>cliente</strong>
                                </c:if>
                                <c:if test="${not empty desde}">
                                    &nbsp;· desde <strong><c:out value="${desde}"/></strong>
                                </c:if>
                                <c:if test="${not empty hasta}">
                                    &nbsp;· hasta <strong><c:out value="${hasta}"/></strong>
                                </c:if>
                                &nbsp;— <strong><c:out value="${totalFiltro}"/></strong>
                                resultado<c:if test="${totalFiltro ne 1}">s</c:if>
                            </span>
                        </div>
                    </c:if>

                    <%-- Tabla de historial --%>
                    <div class="module-table-wrapper">
                        <c:choose>
                            <c:when test="${not empty historial}">
                                <table class="module-table" aria-label="Historial de asistencias">
                                    <thead>
                                        <tr>
                                            <th scope="col">Cliente</th>
                                            <th scope="col">Membresía</th>
                                            <th scope="col">Fecha</th>
                                            <th scope="col">Hora</th>
                                            <th scope="col">Estado</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <c:forEach var="asi" items="${historial}" varStatus="loop">
                                            <tr>
                                                <%-- Cliente --%>
                                                <td>
                                                    <div class="cell-name">
                                                        <c:set var="avColors" value="av--red,av--green,av--blue,av--purple,av--teal"/>
                                                        <c:set var="avIdx" value="${loop.index mod 5}"/>
                                                        <div class="cell-name__avatar ${fn:split(avColors,',')[avIdx]}">
                                                            <c:out value="${fn:substring(asi.contrato.cliente.nombre, 0, 1)}"/>
                                                        </div>
                                                        <div class="cell-name__info">
                                                            <span class="cell-name__primary">
                                                                <c:out value="${asi.contrato.cliente.nombreCompleto}"/>
                                                            </span>
                                                            <span class="cell-name__secondary">
                                                                <c:out value="${asi.contrato.cliente.numeroDocumento}"/>
                                                            </span>
                                                        </div>
                                                    </div>
                                                </td>

                                                <%-- Membresía --%>
                                                <td>
                                                    <div class="cell-data">
                                                        <c:choose>
                                                            <c:when test="${asi.contrato != null and asi.contrato.membresia != null}">
                                                                <span class="cell-data__main">
                                                                    <c:out value="${asi.contrato.membresia.nombreMembresia}"/>
                                                                </span>
                                                            </c:when>
                                                            <c:otherwise>
                                                                <span class="cell-data__sub">—</span>
                                                            </c:otherwise>
                                                        </c:choose>
                                                    </div>
                                                </td>

                                                <%-- Fecha --%>
                                                <td>
                                                    <span class="cell-date">
                                                        <c:out value="${asi.fecha}"/>
                                                    </span>
                                                </td>

                                                <%-- Hora --%>
                                                <td>
                                                    <span style="font-family:var(--font-mono);
                                                                 font-size:0.80rem;
                                                                 color:var(--clr-text-muted);">
                                                        <c:out value="${asi.horaIngresoFormateada}"/>
                                                    </span>
                                                </td>

                                                <%-- Estado --%>
                                                <td>
                                                    <span class="badge-estado badge-estado--${asi.estado}">
                                                        <c:out value="${asi.estado}"/>
                                                    </span>
                                                </td>
                                            </tr>
                                        </c:forEach>
                                    </tbody>
                                </table>

                                <%-- Pie de tabla --%>
                                <div style="display:flex; align-items:center; justify-content:space-between;
                                            padding:0.75rem 1.25rem; border-top:1px solid var(--clr-border-light);
                                            background:rgba(255,255,255,0.012);">
                                    <span style="font-size:0.75rem; color:var(--clr-text-dim);">
                                        <strong style="color:var(--clr-text-muted);">
                                            <c:out value="${totalFiltro}"/>
                                        </strong>
                                        registro<c:if test="${totalFiltro ne 1}">s</c:if> encontrados
                                    </span>
                                    <a href="${pageContext.request.contextPath}/attendance"
                                       class="btn btn-ghost btn-sm">
                                        Ir a check-in
                                    </a>
                                </div>

                            </c:when>

                            <c:otherwise>
                                <div class="table-empty">
                                    <div class="table-empty__icon">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                        </svg>
                                    </div>
                                    <p class="table-empty__title">Sin resultados</p>
                                    <p class="table-empty__desc">
                                        No se encontraron asistencias con los filtros aplicados.<br>
                                        Intenta con un rango de fechas más amplio.
                                    </p>
                                    <a href="${pageContext.request.contextPath}/attendance?action=hist"
                                       class="btn btn-secondary btn-sm" style="margin-top:0.5rem;">
                                        Ver todo el historial
                                    </a>
                                </div>
                            </c:otherwise>
                        </c:choose>
                    </div><%-- /module-table-wrapper --%>

                </c:when>

                <%-- ──────────────────────────────────────────
                     VISTA: PANEL DE CHECK-IN (default)
                     ────────────────────────────────────────── --%>
                <c:otherwise>

                    <%-- Header de módulo con KPI strip --%>
                    <div class="att-kpi-strip">
                        <%-- Ícono de check-in --%>
                        <div style="flex-shrink:0; width:42px; height:42px;
                                    border-radius:var(--radius-md);
                                    background:var(--clr-red-subtle);
                                    display:flex; align-items:center; justify-content:center;">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8"
                                 style="width:20px;height:20px;color:var(--clr-red);">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                      d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                            </svg>
                        </div>

                        <%-- KPI: atendidos hoy --%>
                        <div style="padding-left:0.5rem;">
                            <div class="att-kpi-strip__num">
                                <c:out value="${countHoy}"/>
                            </div>
                            <div class="att-kpi-strip__label">Atendidos hoy</div>
                        </div>

                        <div class="att-kpi-strip__sep"></div>

                        <%-- Info de estado --%>
                        <div>
                            <div style="font-size:0.73rem; font-weight:600; color:var(--clr-success);
                                        display:flex; align-items:center; gap:0.35rem;">
                                <span style="width:7px;height:7px;border-radius:50%;
                                             background:var(--clr-success);
                                             display:inline-block;
                                             animation:pulse-green 2s ease-in-out infinite;">
                                </span>
                                Módulo activo
                            </div>
                            <div style="font-size:0.70rem; color:var(--clr-text-dim); margin-top:0.1rem;">
                                Registra ingresos en tiempo real
                            </div>
                        </div>

                        <%-- Acciones --%>
                        <div class="att-kpi-strip__actions">
                            <a href="${pageContext.request.contextPath}/attendance?action=hist"
                               class="btn btn-secondary btn-sm">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M3.75 12h16.5m-16.5 3.75h16.5M3.75 19.5h16.5M5.625
                                             4.5h12.75a1.875 1.875 0 0 1 0 3.75H5.625a1.875
                                             1.875 0 0 1 0-3.75Z"/>
                                </svg>
                                Ver historial
                            </a>
                        </div>
                    </div>

                    <%-- Grid principal --%>
                    <div class="att-grid">

                        <%-- ══════════════════════════════
                             COLUMNA IZQUIERDA: Check-in
                             ══════════════════════════════ --%>
                        <div class="att-checkin-card">

                            <div class="att-checkin-card__header">
                                <div class="att-checkin-card__icon">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M15 9h3.75M15 12h3.75M15 15h3.75M4.5
                                                 7.5a3 3 0 0 1 3-3h9a3 3 0 0 1 3 3v9a3
                                                 3 0 0 1-3 3h-9a3 3 0 0 1-3-3v-9Zm6
                                                 0a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z"/>
                                    </svg>
                                </div>
                                <span class="att-checkin-card__title">Registrar Ingreso</span>
                            </div>

                            <div class="att-checkin-card__body">

                                <%-- Instrucción --%>
                                <div class="att-instruction">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="m11.25 11.25.041-.02a.75.75 0 0 1 1.063.852l-.708
                                                 2.836a.75.75 0 0 0 1.063.853l.041-.021M21 12a9 9 0
                                                 1 1-18 0 9 9 0 0 1 18 0Zm-9-3.75h.008v.008H12V8.25Z"/>
                                    </svg>
                                    Ingresa el número de documento del cliente para verificar
                                    su contrato activo y registrar la entrada del día.
                                </div>

                                <%-- ── Resultado del último check-in (PRG) ─── --%>
                                <c:if test="${not empty successMsg}">
                                    <div class="att-result att-result--ok" role="status">
                                        <div class="att-result__icon">
                                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.2">
                                                <path stroke-linecap="round" stroke-linejoin="round"
                                                      d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                            </svg>
                                        </div>
                                        <div class="att-result__body">
                                            <c:if test="${not empty sessionScope.checkInCliente}">
                                                <p class="att-result__nombre">
                                                    <c:out value="${sessionScope.checkInCliente}"/>
                                                </p>
                                            </c:if>
                                            <c:if test="${not empty sessionScope.checkInMembresia}">
                                                <p class="att-result__membresia">
                                                    <c:out value="${sessionScope.checkInMembresia}"/>
                                                </p>
                                            </c:if>
                                            <p class="att-result__msg">
                                                <c:out value="${successMsg}"/>
                                            </p>
                                        </div>
                                    </div>
                                    <c:remove var="checkInCliente"   scope="session"/>
                                    <c:remove var="checkInMembresia" scope="session"/>
                                </c:if>

                                <c:if test="${not empty errorMsg}">
                                    <c:set var="resClass" value="att-result--error"/>
                                    <c:if test="${sessionScope.checkInTipo eq 'YA_REGISTRADO_HOY'}">
                                        <c:set var="resClass" value="att-result--warn"/>
                                    </c:if>
                                    <div class="att-result ${resClass}" role="alert">
                                        <div class="att-result__icon">
                                            <c:choose>
                                                <c:when test="${sessionScope.checkInTipo eq 'YA_REGISTRADO_HOY'}">
                                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                                        <path stroke-linecap="round" stroke-linejoin="round"
                                                              d="M12 9v3.75m9-.75a9 9 0 1 1-18 0 9 9 0 0 1 18
                                                                 0Zm-9 3.75h.008v.008H12v-.008Z"/>
                                                    </svg>
                                                </c:when>
                                                <c:otherwise>
                                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                                        <path stroke-linecap="round" stroke-linejoin="round"
                                                              d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948
                                                                 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949
                                                                 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697
                                                                 16.126ZM12 15.75h.007v.008H12v-.008Z"/>
                                                    </svg>
                                                </c:otherwise>
                                            </c:choose>
                                        </div>
                                        <div class="att-result__body">
                                            <p class="att-result__msg">
                                                <c:out value="${errorMsg}"/>
                                            </p>
                                        </div>
                                    </div>
                                    <c:remove var="checkInTipo" scope="session"/>
                                </c:if>

                                <%-- Formulario de check-in --%>
                                <form action="${pageContext.request.contextPath}/attendance"
                                      method="post"
                                      autocomplete="off"
                                      novalidate>

                                    <input type="hidden" name="action" value="checkin">
                                    <input type="hidden" name="_csrf"  value="${sessionScope._csrfToken}">

                                    <div class="att-input-wrapper">
                                        <svg class="att-input-wrapper__icon"
                                             xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor"
                                             stroke-width="1.8" aria-hidden="true">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M15 9h3.75M15 12h3.75M15 15h3.75M4.5 7.5a3
                                                     3 0 0 1 3-3h9a3 3 0 0 1 3 3v9a3 3 0 0 1-3
                                                     3h-9a3 3 0 0 1-3-3v-9Zm6 0a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z"/>
                                        </svg>
                                        <input
                                            type="text"
                                            name="numeroDocumento"
                                            id="numeroDocumento"
                                            class="att-input"
                                            placeholder="Número de documento..."
                                            maxlength="20"
                                            autofocus
                                            autocomplete="off"
                                            inputmode="numeric"
                                            aria-label="Número de documento del cliente"
                                            aria-required="true">
                                    </div>

                                    <button type="submit" class="att-btn" style="margin-top:0.75rem;">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor"
                                             stroke-width="2.2" aria-hidden="true">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0
                                                     1 1-18 0 9 9 0 0 1 18 0Z"/>
                                        </svg>
                                        Registrar Ingreso
                                    </button>

                                </form>

                                <%-- Divider --%>
                                <div class="att-divider">
                                    <span class="att-divider__text">accesos rápidos</span>
                                </div>

                                <%-- Quick links --%>
                                <div class="att-quick-links">
                                    <a href="${pageContext.request.contextPath}/clients"
                                       class="att-quick-link">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M15 19.128a9.38 9.38 0 0 0 2.625.372 9.337 9.337 0
                                                     0 0 4.121-.952 4.125 4.125 0 0 0-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15
                                                     19.128v.106A12.318 12.318 0 0 1 8.624 21c-2.331
                                                     0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0
                                                     0 1 11.964-3.07M12 6.375a3.375 3.375 0 1 1-6.75
                                                     0 3.375 3.375 0 0 1 6.75 0Zm8.25 2.25a2.625
                                                     2.625 0 1 1-5.25 0 2.625 2.625 0 0 1 5.25 0Z"/>
                                        </svg>
                                        Buscar cliente
                                    </a>
                                    <a href="${pageContext.request.contextPath}/contracts"
                                       class="att-quick-link">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125
                                                     1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0
                                                     0-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5
                                                     2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0
                                                     .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504
                                                     1.125-1.125V11.25a9 9 0 0 0-9-9Z"/>
                                        </svg>
                                        Contratos
                                    </a>
                                    <a href="${pageContext.request.contextPath}/clients?action=new"
                                       class="att-quick-link">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M12 4.5v15m7.5-7.5h-15"/>
                                        </svg>
                                        Nuevo cliente
                                    </a>
                                    <a href="${pageContext.request.contextPath}/attendance?action=hist"
                                       class="att-quick-link">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M3.75 12h16.5m-16.5 3.75h16.5M3.75 19.5h16.5M5.625
                                                     4.5h12.75a1.875 1.875 0 0 1 0 3.75H5.625a1.875
                                                     1.875 0 0 1 0-3.75Z"/>
                                        </svg>
                                        Ver historial
                                    </a>
                                </div>

                            </div><%-- /att-checkin-card__body --%>
                        </div><%-- /att-checkin-card --%>

                        <%-- ══════════════════════════════
                             COLUMNA DERECHA: Feed reciente
                             ══════════════════════════════ --%>
                        <div class="att-feed-card">

                            <div class="att-feed-header">
                                <div class="att-feed-header__left">
                                    <div class="att-feed-header__icon">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                        </svg>
                                    </div>
                                    <span class="att-feed-header__title">Actividad Reciente</span>
                                    <span class="att-feed-header__count">
                                        <c:out value="${countHoy}"/> hoy
                                    </span>
                                </div>
                                <a href="${pageContext.request.contextPath}/attendance?action=hist"
                                   class="att-feed-header__link">
                                    Historial completo
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M13.5 4.5 21 12m0 0-7.5 7.5M21 12H3"/>
                                    </svg>
                                </a>
                            </div>

                            <c:choose>
                                <c:when test="${not empty asistenciasRecientes}">

                                    <%-- Cabecera de columnas --%>
                                    <div style="display:flex; align-items:center; gap:0.85rem;
                                                padding:0.5rem 1.25rem;
                                                border-bottom:1px solid var(--clr-border-light);
                                                background:var(--clr-surface);">
                                        <span style="width:24px; flex-shrink:0;"></span>
                                        <span style="width:8px; flex-shrink:0;"></span>
                                        <span style="flex:1; font-size:0.65rem; font-weight:700;
                                                     letter-spacing:0.10em; text-transform:uppercase;
                                                     color:var(--clr-text-dim);">
                                            Cliente
                                        </span>
                                        <span style="font-size:0.65rem; font-weight:700;
                                                     letter-spacing:0.10em; text-transform:uppercase;
                                                     color:var(--clr-text-dim); flex-shrink:0;
                                                     max-width:130px; width:130px;">
                                            Membresía
                                        </span>
                                        <span style="font-size:0.65rem; font-weight:700;
                                                     letter-spacing:0.10em; text-transform:uppercase;
                                                     color:var(--clr-text-dim); flex-shrink:0;
                                                     min-width:80px; text-align:center;">
                                            Fecha
                                        </span>
                                        <span style="font-size:0.65rem; font-weight:700;
                                                     letter-spacing:0.10em; text-transform:uppercase;
                                                     color:var(--clr-text-dim); flex-shrink:0;">
                                            Hora
                                        </span>
                                    </div>

                                    <c:forEach var="asi" items="${asistenciasRecientes}" varStatus="loop">
                                        <div class="att-feed-row">
                                            <span class="att-feed-row__num">
                                                <c:out value="${loop.index + 1}"/>
                                            </span>
                                            <span class="att-feed-row__dot
                                                ${asi.isFalto()     ? 'falto'     : ''}
                                                ${asi.isPendiente() ? 'pendiente' : ''}"
                                                  aria-hidden="true"></span>
                                            <span class="att-feed-row__nombre">
                                                <c:out value="${asi.contrato.cliente.nombreCompleto}"/>
                                            </span>
                                            <span class="att-feed-row__membresia">
                                                <c:if test="${asi.contrato != null and asi.contrato.membresia != null}">
                                                    <c:out value="${asi.contrato.membresia.nombreMembresia}"/>
                                                </c:if>
                                            </span>
                                            <span class="att-feed-row__fecha">
                                                <c:out value="${asi.fecha}"/>
                                            </span>
                                            <span class="att-feed-row__hora">
                                                <c:out value="${asi.horaIngresoFormateada}"/>
                                            </span>
                                        </div>
                                    </c:forEach>

                                    <div class="att-feed-footer">
                                        <span class="att-feed-footer__stat">
                                            Últimas
                                            <strong>
                                                <c:out value="${fn:length(asistenciasRecientes)}"/>
                                            </strong>
                                            asistencias registradas
                                        </span>
                                        <a href="${pageContext.request.contextPath}/attendance?action=hist"
                                           class="btn btn-ghost btn-sm">
                                            Ver todo
                                        </a>
                                    </div>

                                </c:when>

                                <c:otherwise>
                                    <div class="table-empty" style="padding:3rem 2rem;">
                                        <div class="table-empty__icon">
                                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                                                <path stroke-linecap="round" stroke-linejoin="round"
                                                      d="M15.75 6a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1
                                                         7.5 0ZM4.501 20.118a7.5 7.5 0 0 1 14.998 0A17.933
                                                         17.933 0 0 1 12 21.75c-2.676 0-5.216-.584-7.499-1.632Z"/>
                                            </svg>
                                        </div>
                                        <p class="table-empty__title">Sin actividad hoy</p>
                                        <p class="table-empty__desc">
                                            Usa el formulario de check-in para registrar
                                            el primer ingreso del día.
                                        </p>
                                    </div>
                                </c:otherwise>
                            </c:choose>

                        </div><%-- /att-feed-card --%>

                    </div><%-- /att-grid --%>

                </c:otherwise>
            </c:choose>

        </div><%-- /page-content --%>
    </div><%-- /app-main --%>
</div><%-- /app-shell --%>

</body>
</html>
