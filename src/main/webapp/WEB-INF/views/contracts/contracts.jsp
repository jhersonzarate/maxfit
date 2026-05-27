<%-- ============================================================
     contracts.jsp  —  MaxFit Sistema de Gestión
     Módulo de gestión de contratos de membresía.

     Servlet:  ContractsController.java  → GET/POST /contracts
     Acceso:   ROL-ADMIN | ROL-RECEP  (RoleFilter)

     ── Parámetros de URL que activan vistas ──────────────────
       /contracts                        → lista de contratos (default)
       /contracts?form=true              → formulario nuevo contrato
       /contracts?detail=true&id=...     → detalle de contrato
       /contracts?clienteId=...          → lista filtrada por cliente

     ── Atributos de request ─────────────────────────────────

     Vista lista (default):
       contratos         (List<Contrato>)   → todos o filtrados
       totalContratos    (int)              → tamaño de la lista
       countActivos      (int)              → contratos activos
       clienteFiltro     (Cliente, null)    → si viene filtro por cliente

     Vista formulario (?form=true):
       clientes                (List<Cliente>)    → para el select
       membresias              (List<Membresia>)  → para el select
       metodosPago             (List<MetodoPago>) → activos
       fechaHoy                (String ISO)       → valor default fecha inicio
       clientePreseleccionado  (Cliente, null)    → preselección opcional

     Vista detalle (?detail=true):
       contrato          (Contrato)         → objeto completo con joins

     Flash (todas las vistas, via transferirFlashMessages):
       successMsg / errorMsg

     Sesión:
       sessionScope.userRole  → para condicionar botones de admin
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
        <c:when test="${param.form   eq 'true'}">
            <c:set var="pageTitle" value="Nuevo Contrato"   scope="request"/>
        </c:when>
        <c:when test="${param.detail eq 'true'}">
            <c:set var="pageTitle" value="Detalle Contrato" scope="request"/>
        </c:when>
        <c:otherwise>
            <c:set var="pageTitle" value="Contratos"        scope="request"/>
        </c:otherwise>
    </c:choose>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/modules.css">

    <%-- ── Estilos específicos del módulo de contratos ──────── --%>
    <style>
        /* ── Tarjeta de resumen de membresía en el formulario ── */
        .membresia-preview {
            background: var(--clr-surface);
            border: 1px solid var(--clr-border);
            border-radius: var(--radius-md);
            padding: 0.85rem 1rem;
            display: none; /* Se controla con JSTL cuando el dato existe */
        }

        .membresia-preview.visible {
            display: block;
        }

        .membresia-preview__nombre {
            font-family: var(--font-display);
            font-weight: 700;
            font-size: 1rem;
            letter-spacing: 0.03em;
            text-transform: uppercase;
            color: var(--clr-text);
        }

        .membresia-preview__meta {
            display: flex;
            align-items: center;
            gap: 0.6rem;
            margin-top: 0.3rem;
            font-size: 0.75rem;
            color: var(--clr-text-muted);
        }

        .membresia-preview__meta-dot {
            width: 3px; height: 3px;
            border-radius: 50%;
            background: var(--clr-text-dim);
        }

        /* ── Card de cliente preseleccionado ─────────────────── */
        .cliente-presel-card {
            display: flex;
            align-items: center;
            gap: 0.75rem;
            padding: 0.8rem 1rem;
            background: var(--clr-success-subtle);
            border: 1px solid rgba(34,197,94,0.22);
            border-radius: var(--radius-md);
            margin-bottom: -0.25rem;
        }

        .cliente-presel-card__avatar {
            flex-shrink: 0;
            width: 34px; height: 34px;
            border-radius: var(--radius-sm);
            background: rgba(34,197,94,0.15);
            display: flex; align-items: center; justify-content: center;
            font-family: var(--font-display);
            font-weight: 700; font-size: 0.9rem;
            color: var(--clr-success);
            text-transform: uppercase;
        }

        .cliente-presel-card__info {
            flex: 1; min-width: 0;
        }

        .cliente-presel-card__nombre {
            font-size: 0.85rem;
            font-weight: 600;
            color: var(--clr-text);
        }

        .cliente-presel-card__doc {
            font-size: 0.72rem;
            color: var(--clr-text-muted);
        }

        /* ── Detalle del contrato ────────────────────────────── */
        .contrato-detail-hero {
            background: var(--clr-card);
            border: 1px solid var(--clr-card-border);
            border-radius: var(--radius-xl);
            padding: 1.5rem;
            position: relative;
            overflow: hidden;
            margin-bottom: 1.25rem;
        }

        .contrato-detail-hero::after {
            content: '';
            position: absolute;
            left: 0; top: 0; bottom: 0;
            width: 3px;
            background: var(--clr-red);
            border-radius: 0 2px 2px 0;
        }

        .contrato-detail-hero::before {
            content: '';
            position: absolute;
            top: -80px; right: -80px;
            width: 220px; height: 220px;
            background: radial-gradient(circle, var(--clr-red-glow) 0%, transparent 65%);
            pointer-events: none;
        }

        .contrato-detail-hero__top {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 1rem;
            margin-bottom: 1.1rem;
            padding-left: 0.75rem;
        }

        .contrato-detail-hero__id {
            font-family: var(--font-mono);
            font-size: 0.72rem;
            color: var(--clr-text-dim);
            background: var(--clr-surface);
            padding: 0.18rem 0.55rem;
            border-radius: var(--radius-xs);
            border: 1px solid var(--clr-border-light);
        }

        .contrato-detail-hero__membresia {
            font-family: var(--font-display);
            font-weight: 800;
            font-size: 1.65rem;
            letter-spacing: 0.04em;
            text-transform: uppercase;
            color: var(--clr-text);
            line-height: 1.1;
            padding-left: 0.75rem;
        }

        .contrato-detail-hero__grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 0;
            margin-top: 1.1rem;
            border: 1px solid var(--clr-border-light);
            border-radius: var(--radius-md);
            overflow: hidden;
        }

        .contrato-detail-hero__stat {
            padding: 0.85rem 1rem;
            border-right: 1px solid var(--clr-border-light);
            display: flex;
            flex-direction: column;
            gap: 0.2rem;
        }

        .contrato-detail-hero__stat:last-child { border-right: none; }

        .contrato-detail-hero__stat-label {
            font-size: 0.65rem;
            font-weight: 700;
            letter-spacing: 0.10em;
            text-transform: uppercase;
            color: var(--clr-text-dim);
        }

        .contrato-detail-hero__stat-value {
            font-family: var(--font-display);
            font-size: 1.1rem;
            font-weight: 700;
            color: var(--clr-text);
            line-height: 1.2;
        }

        .contrato-detail-hero__stat-value.is-money {
            color: var(--clr-success);
        }

        .contrato-detail-hero__stat-value.is-date {
            font-family: var(--font-body);
            font-size: 0.88rem;
            font-weight: 600;
        }

        /* ── Timeline de fechas ──────────────────────────────── */
        .fechas-timeline {
            display: flex;
            align-items: center;
            gap: 0;
            background: var(--clr-card);
            border: 1px solid var(--clr-card-border);
            border-radius: var(--radius-lg);
            overflow: hidden;
            margin-bottom: 1rem;
        }

        .fechas-timeline__item {
            flex: 1;
            padding: 1rem 1.25rem;
            border-right: 1px solid var(--clr-border-light);
            display: flex;
            flex-direction: column;
            gap: 0.2rem;
        }

        .fechas-timeline__item:last-child { border-right: none; }

        .fechas-timeline__label {
            font-size: 0.65rem;
            font-weight: 700;
            letter-spacing: 0.10em;
            text-transform: uppercase;
            color: var(--clr-text-dim);
        }

        .fechas-timeline__date {
            font-family: var(--font-display);
            font-weight: 700;
            font-size: 1rem;
            color: var(--clr-text);
        }

        .fechas-timeline__date.vence { color: var(--clr-warning); }
        .fechas-timeline__date.vencido { color: var(--clr-red); }
        .fechas-timeline__date.ok { color: var(--clr-success); }

        /* ── Fila de contrato en lista ───────────────────────── */
        .contrato-monto {
            font-family: var(--font-display);
            font-size: 1.05rem;
            font-weight: 700;
            color: var(--clr-text);
        }

        .contrato-monto::before {
            content: 'S/ ';
            font-size: 0.70rem;
            font-weight: 500;
            color: var(--clr-text-muted);
            font-family: var(--font-body);
        }

        .contrato-fechas {
            font-size: 0.72rem;
            color: var(--clr-text-dim);
            white-space: nowrap;
        }

        /* ── Tarjeta de KPIs del listado ─────────────────────── */
        .contratos-kpi-strip {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 0;
            background: var(--clr-card);
            border: 1px solid var(--clr-card-border);
            border-radius: var(--radius-lg);
            overflow: hidden;
            margin-bottom: 1.5rem;
        }

        .contratos-kpi-strip__item {
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: 1rem 0.75rem;
            gap: 0.2rem;
            border-right: 1px solid var(--clr-border-light);
            transition: background var(--transition);
        }

        .contratos-kpi-strip__item:last-child { border-right: none; }
        .contratos-kpi-strip__item:hover { background: rgba(255,255,255,0.02); }

        .contratos-kpi-strip__num {
            font-family: var(--font-display);
            font-size: 1.7rem;
            font-weight: 800;
            line-height: 1;
            color: var(--clr-text);
        }

        .contratos-kpi-strip__num.green  { color: var(--clr-success); }
        .contratos-kpi-strip__num.red    { color: var(--clr-red); }
        .contratos-kpi-strip__num.yellow { color: var(--clr-warning); }

        .contratos-kpi-strip__label {
            font-size: 0.68rem;
            font-weight: 600;
            letter-spacing: 0.08em;
            text-transform: uppercase;
            color: var(--clr-text-dim);
        }

        /* ── Banner de filtro activo ─────────────────────────── */
        .filter-banner {
            display: flex;
            align-items: center;
            gap: 0.75rem;
            padding: 0.75rem 1rem;
            background: var(--clr-info-subtle);
            border: 1px solid rgba(59,130,246,0.22);
            border-radius: var(--radius-md);
            margin-bottom: 1rem;
        }

        .filter-banner svg {
            flex-shrink: 0;
            width: 15px; height: 15px;
            color: var(--clr-info);
        }

        .filter-banner__text {
            font-size: 0.80rem;
            color: var(--clr-info);
            font-weight: 500;
            flex: 1;
        }
    </style>
</head>
<body>

<div class="app-shell">
    <%@ include file="/WEB-INF/views/includes/sidebar.jsp" %>

    <div class="app-main">

        <%-- Título dinámico para el navbar --%>
        <c:choose>
            <c:when test="${param.form   eq 'true'}">
                <c:set var="pageTitle"    value="Nuevo Contrato"      scope="request"/>
                <c:set var="pageSubtitle" value="Módulo de Contratos" scope="request"/>
            </c:when>
            <c:when test="${param.detail eq 'true'}">
                <c:set var="pageTitle"    value="Detalle de Contrato" scope="request"/>
                <c:set var="pageSubtitle" value="Módulo de Contratos" scope="request"/>
            </c:when>
            <c:otherwise>
                <c:set var="pageTitle"    value="Contratos"           scope="request"/>
                <c:set var="pageSubtitle" value="Gestión de membresías activas" scope="request"/>
            </c:otherwise>
        </c:choose>
        <%@ include file="/WEB-INF/views/includes/navbar.jsp" %>

        <div class="page-content">

            <%-- ═══════════════════════════════════════════════
                 BIFURCACIÓN PRINCIPAL DE VISTAS
                 ═══════════════════════════════════════════════ --%>
            <c:choose>

                <%-- ──────────────────────────────────────────
                     VISTA: DETALLE DEL CONTRATO
                     param.detail=true
                     ────────────────────────────────────────── --%>
                <c:when test="${param.detail eq 'true'}">

                    <%-- Breadcrumb --%>
                    <nav class="module-breadcrumb" aria-label="Breadcrumb">
                        <a href="${pageContext.request.contextPath}/contracts">Contratos</a>
                        <svg class="module-breadcrumb__sep" xmlns="http://www.w3.org/2000/svg"
                             fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7"/>
                        </svg>
                        <span>
                            <c:choose>
                                <c:when test="${not empty contrato}">
                                    <c:out value="${contrato.id}"/>
                                </c:when>
                                <c:otherwise>Detalle</c:otherwise>
                            </c:choose>
                        </span>
                    </nav>

                    <c:choose>
                        <c:when test="${not empty contrato}">

                            <%-- Hero del contrato --%>
                            <div class="contrato-detail-hero">
                                <div class="contrato-detail-hero__top">
                                    <div>
                                        <span class="contrato-detail-hero__id">
                                            <c:out value="${contrato.id}"/>
                                        </span>
                                        <p class="contrato-detail-hero__membresia">
                                            <c:out value="${contrato.membresia.nombreMembresia}"/>
                                        </p>
                                    </div>
                                    <div style="display:flex; align-items:center; gap:0.65rem; flex-shrink:0;">
                                        <span class="badge-estado badge-estado--${contrato.estado}">
                                            <c:out value="${contrato.estado}"/>
                                        </span>
                                        <c:if test="${sessionScope.userRole eq 'ROL-ADMIN' and contrato.isActivo()}">
                                            <form action="${pageContext.request.contextPath}/contracts"
                                                  method="post"
                                                  style="display:inline;"
                                                  onsubmit="return confirm('¿Cancelar este contrato? Esta acción no se puede deshacer.');">
                                                <input type="hidden" name="action" value="cancel">
                                                <input type="hidden" name="id"     value="<c:out value='${contrato.id}'/>">
                                                <input type="hidden" name="_csrf"  value="${sessionScope._csrfToken}">
                                                <button type="submit" class="btn btn-danger btn-sm">
                                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                        <path stroke-linecap="round" stroke-linejoin="round"
                                                              d="M6 18 18 6M6 6l12 12"/>
                                                    </svg>
                                                    Cancelar contrato
                                                </button>
                                            </form>
                                        </c:if>
                                    </div>
                                </div>

                                <%-- Grid de 4 stats --%>
                                <div class="contrato-detail-hero__grid">
                                    <div class="contrato-detail-hero__stat">
                                        <span class="contrato-detail-hero__stat-label">Monto pagado</span>
                                        <span class="contrato-detail-hero__stat-value is-money">
                                            S/ <fmt:formatNumber value="${contrato.montoPagado}" pattern="#,##0.00"/>
                                        </span>
                                    </div>
                                    <div class="contrato-detail-hero__stat">
                                        <span class="contrato-detail-hero__stat-label">Duración</span>
                                        <span class="contrato-detail-hero__stat-value">
                                            <c:out value="${contrato.membresia.duracionMeses}"/>
                                            <span style="font-size:0.75rem; font-family:var(--font-body); color:var(--clr-text-muted);">
                                                mes(es)
                                            </span>
                                        </span>
                                    </div>
                                    <div class="contrato-detail-hero__stat">
                                        <span class="contrato-detail-hero__stat-label">Inicia</span>
                                        <span class="contrato-detail-hero__stat-value is-date">
                                            <c:out value="${contrato.fechaInicio}"/>
                                        </span>
                                    </div>
                                    <div class="contrato-detail-hero__stat">
                                        <span class="contrato-detail-hero__stat-label">Vence</span>
                                        <span class="contrato-detail-hero__stat-value is-date">
                                            <c:out value="${contrato.fechaFin}"/>
                                        </span>
                                    </div>
                                </div>
                            </div>

                            <%-- Layout detalle: info + aside --%>
                            <div class="detail-layout">

                                <%-- Columna principal --%>
                                <div>

                                    <%-- Sección: Datos del cliente --%>
                                    <div class="detail-section detail-section--full"
                                         style="margin-bottom:1.25rem;">
                                        <div class="detail-section__header">
                                            <div class="detail-section__icon">
                                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                    <path stroke-linecap="round" stroke-linejoin="round"
                                                          d="M15.75 6a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5
                                                             0ZM4.501 20.118a7.5 7.5 0 0 1 14.998 0A17.933 17.933
                                                             0 0 1 12 21.75c-2.676 0-5.216-.584-7.499-1.632Z"/>
                                                </svg>
                                            </div>
                                            <span class="detail-section__title">Cliente</span>
                                        </div>
                                        <div class="detail-section__body">
                                            <div class="detail-list detail-list--horizontal">

                                                <div class="detail-item">
                                                    <span class="detail-item__label">Nombre completo</span>
                                                    <span class="detail-item__value">
                                                        <a href="${pageContext.request.contextPath}/clients?action=view&id=<c:out value='${contrato.cliente.id}'/>"
                                                           style="color:var(--clr-red); font-weight:600; text-decoration:none;">
                                                            <c:out value="${contrato.cliente.nombreCompleto}"/>
                                                        </a>
                                                    </span>
                                                </div>

                                                <div class="detail-item">
                                                    <span class="detail-item__label">Documento</span>
                                                    <span class="detail-item__value mono">
                                                        <c:if test="${contrato.cliente.tipoDocumento != null}">
                                                            <c:out value="${contrato.cliente.tipoDocumento.abreviado}"/>:
                                                        </c:if>
                                                        <c:out value="${contrato.cliente.numeroDocumento}"/>
                                                    </span>
                                                </div>

                                                <div class="detail-item">
                                                    <span class="detail-item__label">Email</span>
                                                    <span class="detail-item__value">
                                                        <c:choose>
                                                            <c:when test="${not empty contrato.cliente.email}">
                                                                <c:out value="${contrato.cliente.email}"/>
                                                            </c:when>
                                                            <c:otherwise>—</c:otherwise>
                                                        </c:choose>
                                                    </span>
                                                </div>

                                                <div class="detail-item">
                                                    <span class="detail-item__label">Teléfono</span>
                                                    <span class="detail-item__value">
                                                        <c:choose>
                                                            <c:when test="${not empty contrato.cliente.telefono}">
                                                                <c:out value="${contrato.cliente.telefono}"/>
                                                            </c:when>
                                                            <c:otherwise>—</c:otherwise>
                                                        </c:choose>
                                                    </span>
                                                </div>

                                            </div>
                                        </div>
                                    </div>

                                    <%-- Sección: Datos de la membresía --%>
                                    <div class="detail-section detail-section--full"
                                         style="margin-bottom:1.25rem;">
                                        <div class="detail-section__header">
                                            <div class="detail-section__icon">
                                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                    <path stroke-linecap="round" stroke-linejoin="round"
                                                          d="M2.25 8.25h19.5M2.25 9h19.5m-16.5 5.25h6m-6 2.25h3m-3.75
                                                             3h15a2.25 2.25 0 0 0 2.25-2.25V6.75A2.25 2.25 0 0 0
                                                             19.5 4.5h-15a2.25 2.25 0 0 0-2.25 2.25v10.5A2.25 2.25
                                                             0 0 0 4.5 19.5Z"/>
                                                </svg>
                                            </div>
                                            <span class="detail-section__title">Membresía</span>
                                        </div>
                                        <div class="detail-section__body">
                                            <div class="detail-list detail-list--horizontal">

                                                <div class="detail-item">
                                                    <span class="detail-item__label">Plan</span>
                                                    <span class="detail-item__value" style="font-weight:700;">
                                                        <c:out value="${contrato.membresia.nombreMembresia}"/>
                                                    </span>
                                                </div>

                                                <div class="detail-item">
                                                    <span class="detail-item__label">Precio del plan</span>
                                                    <span class="detail-item__value">
                                                        S/ <fmt:formatNumber value="${contrato.membresia.precio}" pattern="#,##0.00"/>
                                                    </span>
                                                </div>

                                                <div class="detail-item">
                                                    <span class="detail-item__label">Duración</span>
                                                    <span class="detail-item__value">
                                                        <c:out value="${contrato.membresia.duracionMeses}"/> mes(es)
                                                    </span>
                                                </div>

                                                <div class="detail-item">
                                                    <span class="detail-item__label">Método de pago</span>
                                                    <span class="detail-item__value">
                                                        <c:out value="${contrato.metodoPago.nombre}"/>
                                                    </span>
                                                </div>

                                                <div class="detail-item">
                                                    <span class="detail-item__label">Monto pagado</span>
                                                    <span class="detail-item__value" style="color:var(--clr-success); font-weight:700;">
                                                        S/ <fmt:formatNumber value="${contrato.montoPagado}" pattern="#,##0.00"/>
                                                    </span>
                                                </div>

                                                <c:if test="${not empty contrato.fechaPago}">
                                                    <div class="detail-item">
                                                        <span class="detail-item__label">Fecha de pago</span>
                                                        <span class="detail-item__value">
                                                            <c:out value="${contrato.fechaPago}"/>
                                                        </span>
                                                    </div>
                                                </c:if>

                                                <c:if test="${not empty contrato.membresia.descripcion}">
                                                    <div class="detail-item" style="grid-column: span 2;">
                                                        <span class="detail-item__label">Descripción del plan</span>
                                                        <span class="detail-item__value">
                                                            <c:out value="${contrato.membresia.descripcion}"/>
                                                        </span>
                                                    </div>
                                                </c:if>

                                            </div>
                                        </div>
                                    </div>

                                    <%-- Sección: Datos del empleado responsable --%>
                                    <div class="detail-section detail-section--full">
                                        <div class="detail-section__header">
                                            <div class="detail-section__icon">
                                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                    <path stroke-linecap="round" stroke-linejoin="round"
                                                          d="M18 18.72a9.094 9.094 0 0 0 3.741-.479 3 3 0 0
                                                             0-4.682-2.72m.94 3.198.001.031c0 .225-.012.447-.037.666A11.944
                                                             11.944 0 0 1 12 21c-2.17 0-4.207-.576-5.963-1.584A6.062
                                                             6.062 0 0 1 6 18.719m12 0a5.971 5.971 0 0 0-.941-3.197m0
                                                             0A5.995 5.995 0 0 0 12 12.75a5.995 5.995 0 0
                                                             0-5.058 2.772m0 0a3 3 0 0 0-4.681 2.72 8.986 8.986 0 0
                                                             0 3.74.477m.94-3.197a5.971 5.971 0 0 0-.94 3.197M15
                                                             6.75a3 3 0 1 1-6 0 3 3 0 0 1 6 0Zm6 3a2.25 2.25 0 1
                                                             1-4.5 0 2.25 2.25 0 0 1 4.5 0Zm-13.5 0a2.25 2.25 0 1
                                                             1-4.5 0 2.25 2.25 0 0 1 4.5 0Z"/>
                                                </svg>
                                            </div>
                                            <span class="detail-section__title">Empleado responsable</span>
                                        </div>
                                        <div class="detail-section__body">
                                            <div class="detail-list detail-list--horizontal">
                                                <div class="detail-item">
                                                    <span class="detail-item__label">Nombre</span>
                                                    <span class="detail-item__value" style="font-weight:600;">
                                                        <c:out value="${contrato.empleado.nombreCompleto}"/>
                                                    </span>
                                                </div>
                                                <div class="detail-item">
                                                    <span class="detail-item__label">Cargo</span>
                                                    <span class="detail-item__value">
                                                        <c:out value="${contrato.empleado.cargo.nombre}"/>
                                                    </span>
                                                </div>
                                                <div class="detail-item">
                                                    <span class="detail-item__label">Email</span>
                                                    <span class="detail-item__value">
                                                        <c:out value="${contrato.empleado.email}"/>
                                                    </span>
                                                </div>
                                            </div>
                                        </div>
                                    </div>

                                </div><%-- /columna principal --%>

                                <%-- Aside derecho --%>
                                <aside class="detail-aside">

                                    <%-- Resumen del contrato --%>
                                    <div class="aside-summary-card">
                                        <div class="aside-summary-card__header">Resumen del contrato</div>
                                        <div class="aside-summary-card__body">

                                            <div class="aside-data-row">
                                                <span class="aside-data-row__label">ID contrato</span>
                                                <span class="aside-data-row__value mono" style="font-size:0.70rem;">
                                                    <c:out value="${contrato.id}"/>
                                                </span>
                                            </div>

                                            <div class="aside-data-row">
                                                <span class="aside-data-row__label">Estado</span>
                                                <span class="aside-data-row__value">
                                                    <span class="badge-estado badge-estado--${contrato.estado}">
                                                        <c:out value="${contrato.estado}"/>
                                                    </span>
                                                </span>
                                            </div>

                                            <div class="aside-data-row">
                                                <span class="aside-data-row__label">Fecha inicio</span>
                                                <span class="aside-data-row__value strong">
                                                    <c:out value="${contrato.fechaInicio}"/>
                                                </span>
                                            </div>

                                            <div class="aside-data-row">
                                                <span class="aside-data-row__label">Fecha vence</span>
                                                <span class="aside-data-row__value strong">
                                                    <c:out value="${contrato.fechaFin}"/>
                                                </span>
                                            </div>

                                            <div style="border-top:1px solid var(--clr-border-light); padding-top:0.65rem; margin-top:0.15rem;">
                                                <div class="aside-data-row">
                                                    <span class="aside-data-row__label">Monto</span>
                                                    <span class="aside-data-row__value strong"
                                                          style="color:var(--clr-success); font-size:0.95rem;">
                                                        S/ <fmt:formatNumber value="${contrato.montoPagado}" pattern="#,##0.00"/>
                                                    </span>
                                                </div>
                                            </div>

                                        </div>
                                    </div>

                                    <%-- Acciones --%>
                                    <div class="aside-summary-card">
                                        <div class="aside-summary-card__header">Acciones</div>
                                        <div class="aside-summary-card__body">

                                            <a href="${pageContext.request.contextPath}/clients?action=view&id=<c:out value='${contrato.cliente.id}'/>"
                                               class="btn btn-secondary btn-sm" style="width:100%; justify-content:flex-start;">
                                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                    <path stroke-linecap="round" stroke-linejoin="round"
                                                          d="M15.75 6a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5
                                                             0ZM4.501 20.118a7.5 7.5 0 0 1 14.998 0A17.933 17.933
                                                             0 0 1 12 21.75c-2.676 0-5.216-.584-7.499-1.632Z"/>
                                                </svg>
                                                Ver perfil del cliente
                                            </a>

                                            <a href="${pageContext.request.contextPath}/attendance"
                                               class="btn btn-secondary btn-sm" style="width:100%; justify-content:flex-start;">
                                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                    <path stroke-linecap="round" stroke-linejoin="round"
                                                          d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                                </svg>
                                                Ir a check-in
                                            </a>

                                            <c:if test="${sessionScope.userRole eq 'ROL-ADMIN' and contrato.isActivo()}">
                                                <div style="border-top:1px solid var(--clr-border-light);
                                                            padding-top:0.5rem; margin-top:0.1rem;">
                                                    <form action="${pageContext.request.contextPath}/contracts"
                                                          method="post"
                                                          onsubmit="return confirm('¿Cancelar este contrato? Esta acción es irreversible.');">
                                                        <input type="hidden" name="action" value="cancel">
                                                        <input type="hidden" name="id"     value="<c:out value='${contrato.id}'/>">
                                                        <input type="hidden" name="_csrf"  value="${sessionScope._csrfToken}">
                                                        <button type="submit"
                                                                class="btn btn-danger btn-sm"
                                                                style="width:100%; justify-content:flex-start;">
                                                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                                <path stroke-linecap="round" stroke-linejoin="round"
                                                                      d="M6 18 18 6M6 6l12 12"/>
                                                            </svg>
                                                            Cancelar contrato
                                                        </button>
                                                    </form>
                                                </div>
                                            </c:if>

                                        </div>
                                    </div>

                                </aside>

                            </div><%-- /detail-layout --%>

                        </c:when>

                        <c:otherwise>
                            <%-- Contrato no encontrado --%>
                            <div class="table-empty" style="padding:4rem;">
                                <div class="table-empty__icon">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125
                                                 1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0
                                                 0-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5
                                                 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0
                                                 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504
                                                 1.125-1.125V11.25a9 9 0 0 0-9-9Z"/>
                                    </svg>
                                </div>
                                <p class="table-empty__title">Contrato no encontrado</p>
                                <p class="table-empty__desc">El contrato que buscas no existe o fue eliminado.</p>
                                <a href="${pageContext.request.contextPath}/contracts"
                                   class="btn btn-secondary btn-sm" style="margin-top:0.5rem;">
                                    Volver a contratos
                                </a>
                            </div>
                        </c:otherwise>
                    </c:choose>

                </c:when>

                <%-- ──────────────────────────────────────────
                     VISTA: FORMULARIO (nuevo contrato)
                     param.form=true
                     ────────────────────────────────────────── --%>
                <c:when test="${param.form eq 'true'}">

                    <%-- Breadcrumb --%>
                    <nav class="module-breadcrumb" aria-label="Breadcrumb">
                        <a href="${pageContext.request.contextPath}/contracts">Contratos</a>
                        <svg class="module-breadcrumb__sep" xmlns="http://www.w3.org/2000/svg"
                             fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7"/>
                        </svg>
                        <span>Nuevo contrato</span>
                    </nav>

                    <%-- Header del formulario --%>
                    <div class="module-header">
                        <div class="module-header__left">
                            <h1 class="module-header__title">Registrar Contrato</h1>
                            <div class="module-header__meta">
                                <span>Asigna una membresía a un cliente</span>
                                <span class="module-header__meta-sep"></span>
                                <span>Los campos marcados con * son obligatorios</span>
                            </div>
                        </div>
                        <div class="module-header__actions">
                            <a href="${pageContext.request.contextPath}/contracts"
                               class="btn btn-secondary">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M10.5 19.5 3 12m0 0 7.5-7.5M3 12h18"/>
                                </svg>
                                Cancelar
                            </a>
                        </div>
                    </div>

                    <%-- Alerta de error --%>
                    <c:if test="${not empty errorMsg}">
                        <div class="module-alert module-alert--error" role="alert">
                            <svg class="module-alert__icon" xmlns="http://www.w3.org/2000/svg"
                                 fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                      d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73
                                         0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898
                                         0L2.697 16.126ZM12 15.75h.007v.008H12v-.008Z"/>
                            </svg>
                            <div class="module-alert__body">
                                <p class="module-alert__title">No se pudo registrar el contrato</p>
                                <p class="module-alert__text"><c:out value="${errorMsg}"/></p>
                            </div>
                        </div>
                    </c:if>

                    <%-- Aviso si el cliente ya tiene contrato activo (viene desde el controller) --%>

                    <%-- Formulario principal --%>
                    <form action="${pageContext.request.contextPath}/contracts"
                          method="post"
                          novalidate
                          autocomplete="off">

                        <input type="hidden" name="action" value="save">
                        <input type="hidden" name="_csrf"  value="${sessionScope._csrfToken}">

                        <div class="form-card form-card--wide">

                            <div class="form-card__header">
                                <div class="form-card__header-icon">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125
                                                 1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0
                                                 0-3.375-3.375H8.25m3.75 9v6m3-3H9m1.5-12H5.625c-.621
                                                 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125
                                                 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z"/>
                                    </svg>
                                </div>
                                <div>
                                    <p class="form-card__header-title">Nuevo Contrato de Membresía</p>
                                    <p class="form-card__header-sub">
                                        El ID se genera automáticamente · La fecha de vencimiento
                                        se calcula según la duración del plan
                                    </p>
                                </div>
                            </div>

                            <div class="form-card__body">

                                <%-- Sección: Cliente --%>
                                <div class="form-section-divider">
                                    <span class="form-section-divider__label">Datos del cliente</span>
                                </div>

                                <%-- Si hay cliente preseleccionado, mostrarlo --%>
                                <c:if test="${not empty clientePreseleccionado}">
                                    <div class="cliente-presel-card">
                                        <div class="cliente-presel-card__avatar">
                                            <c:out value="${fn:substring(clientePreseleccionado.nombre, 0, 1)}"/>
                                        </div>
                                        <div class="cliente-presel-card__info">
                                            <p class="cliente-presel-card__nombre">
                                                <c:out value="${clientePreseleccionado.nombreCompleto}"/>
                                            </p>
                                            <p class="cliente-presel-card__doc">
                                                <c:if test="${clientePreseleccionado.tipoDocumento != null}">
                                                    <c:out value="${clientePreseleccionado.tipoDocumento.abreviado}"/>:
                                                </c:if>
                                                <c:out value="${clientePreseleccionado.numeroDocumento}"/>
                                            </p>
                                        </div>
                                        <span class="badge-estado badge-estado--activo">
                                            Cliente seleccionado
                                        </span>
                                    </div>
                                </c:if>

                                <div class="form-row">
                                    <div class="form-field span-2">
                                        <label for="clienteId">
                                            Cliente <span class="required-star">*</span>
                                        </label>
                                        <select id="clienteId"
                                                name="clienteId"
                                                class="form-control"
                                                required>
                                            <option value="">— Seleccionar cliente —</option>
                                            <c:forEach var="cli" items="${clientes}">
                                                <option value="<c:out value='${cli.id}'/>"
                                                    ${not empty clientePreseleccionado and clientePreseleccionado.id eq cli.id ? 'selected' : ''}>
                                                    <c:out value="${cli.apellido}"/>,
                                                    <c:out value="${cli.nombre}"/>
                                                    —
                                                    <c:if test="${cli.tipoDocumento != null}">
                                                        <c:out value="${cli.tipoDocumento.abreviado}"/>:
                                                    </c:if>
                                                    <c:out value="${cli.numeroDocumento}"/>
                                                </option>
                                            </c:forEach>
                                        </select>
                                        <span class="form-field__hint">
                                            Solo se puede tener un contrato activo a la vez por cliente
                                        </span>
                                    </div>
                                </div>

                                <%-- Sección: Membresía y pago --%>
                                <div class="form-section-divider">
                                    <span class="form-section-divider__label">Plan y pago</span>
                                </div>

                                <div class="form-row">
                                    <%-- Membresía --%>
                                    <div class="form-field">
                                        <label for="membresiaId">
                                            Plan de membresía <span class="required-star">*</span>
                                        </label>
                                        <select id="membresiaId"
                                                name="membresiaId"
                                                class="form-control"
                                                required>
                                            <option value="">— Seleccionar plan —</option>
                                            <c:forEach var="mem" items="${membresias}">
                                                <option value="<c:out value='${mem.id}'/>">
                                                    <c:out value="${mem.nombreMembresia}"/>
                                                    — S/ <fmt:formatNumber value="${mem.precio}" pattern="#,##0.00"/>
                                                    (<c:out value="${mem.duracionMeses}"/> mes(es))
                                                </option>
                                            </c:forEach>
                                        </select>
                                    </div>

                                    <%-- Método de pago --%>
                                    <div class="form-field">
                                        <label for="metodoPagoId">
                                            Método de pago <span class="required-star">*</span>
                                        </label>
                                        <select id="metodoPagoId"
                                                name="metodoPagoId"
                                                class="form-control"
                                                required>
                                            <option value="">— Seleccionar método —</option>
                                            <c:forEach var="mp" items="${metodosPago}">
                                                <option value="<c:out value='${mp.id}'/>">
                                                    <c:out value="${mp.nombre}"/>
                                                </option>
                                            </c:forEach>
                                        </select>
                                    </div>
                                </div>

                                <%-- Sección: Fecha y monto --%>
                                <div class="form-section-divider">
                                    <span class="form-section-divider__label">Fecha de inicio y monto</span>
                                </div>

                                <div class="form-row">
                                    <%-- Fecha de inicio --%>
                                    <div class="form-field">
                                        <label for="fechaInicio">
                                            Fecha de inicio <span class="required-star">*</span>
                                        </label>
                                        <input type="date"
                                               id="fechaInicio"
                                               name="fechaInicio"
                                               class="form-control"
                                               required
                                               value="<c:out value='${fechaHoy}'/>">
                                        <span class="form-field__hint">
                                            La fecha de vencimiento se calcula automáticamente
                                        </span>
                                    </div>

                                    <%-- Monto pagado --%>
                                    <div class="form-field">
                                        <label for="montoPagado">
                                            Monto pagado (S/) <span class="required-star">*</span>
                                        </label>
                                        <input type="number"
                                               id="montoPagado"
                                               name="montoPagado"
                                               class="form-control"
                                               placeholder="Ej: 120.00"
                                               min="0"
                                               step="0.01"
                                               required
                                               autocomplete="off">
                                        <span class="form-field__hint">
                                            Puede diferir del precio del plan (descuentos, promociones)
                                        </span>
                                    </div>
                                </div>

                            </div><%-- /form-card__body --%>

                            <div class="form-card__footer">
                                <button type="submit" class="btn btn-primary">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                    </svg>
                                    Registrar contrato
                                </button>
                                <a href="${pageContext.request.contextPath}/contracts"
                                   class="btn btn-ghost">
                                    Cancelar
                                </a>
                                <span style="margin-left:auto; font-size:0.72rem; color:var(--clr-text-dim);">
                                    * El empleado responsable se asigna desde tu sesión activa
                                </span>
                            </div>

                        </div><%-- /form-card --%>
                    </form>

                </c:when>

                <%-- ──────────────────────────────────────────
                     VISTA: LISTA DE CONTRATOS (default)
                     ────────────────────────────────────────── --%>
                <c:otherwise>

                    <%-- Banner de filtro por cliente --%>
                    <c:if test="${not empty clienteFiltro}">
                        <div class="filter-banner">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                      d="m21 21-5.197-5.197m0 0A7.5 7.5 0 1 0 5.196 5.196a7.5 7.5 0 0 0 10.607 10.607Z"/>
                            </svg>
                            <span class="filter-banner__text">
                                Mostrando contratos de:
                                <strong><c:out value="${clienteFiltro.nombreCompleto}"/></strong>
                            </span>
                            <a href="${pageContext.request.contextPath}/contracts"
                               class="btn btn-ghost btn-sm">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M6 18 18 6M6 6l12 12"/>
                                </svg>
                                Quitar filtro
                            </a>
                        </div>
                    </c:if>

                    <%-- Header del módulo --%>
                    <div class="module-header">
                        <div class="module-header__left">
                            <h1 class="module-header__title">
                                Contratos
                                <span class="stat-chip">
                                    <c:out value="${totalContratos}"/>
                                </span>
                            </h1>
                            <div class="module-header__meta">
                                <span>Historial completo de membresías</span>
                                <span class="module-header__meta-sep"></span>
                                <span class="stat-chip chip--green">
                                    <c:out value="${countActivos}"/> activos
                                </span>
                            </div>
                        </div>
                        <div class="module-header__actions">
                            <a href="${pageContext.request.contextPath}/contracts?action=new"
                               class="btn btn-primary">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.2">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M12 4.5v15m7.5-7.5h-15"/>
                                </svg>
                                Nuevo contrato
                            </a>
                        </div>
                    </div>

                    <%-- KPI Strip --%>
                    <div class="contratos-kpi-strip">
                        <div class="contratos-kpi-strip__item">
                            <span class="contratos-kpi-strip__num green">
                                <c:out value="${countActivos}"/>
                            </span>
                            <span class="contratos-kpi-strip__label">Activos</span>
                        </div>
                        <div class="contratos-kpi-strip__item">
                            <span class="contratos-kpi-strip__num">
                                <c:out value="${totalContratos}"/>
                            </span>
                            <span class="contratos-kpi-strip__label">Total</span>
                        </div>
                        <div class="contratos-kpi-strip__item">
                            <c:set var="noActivos" value="${totalContratos - countActivos}"/>
                            <span class="contratos-kpi-strip__num yellow">
                                <c:out value="${noActivos}"/>
                            </span>
                            <span class="contratos-kpi-strip__label">Vencidos / Cancelados</span>
                        </div>
                    </div>

                    <%-- Tabla de contratos --%>
                    <div class="module-table-wrapper">
                        <c:choose>
                            <c:when test="${not empty contratos}">
                                <table class="module-table" aria-label="Lista de contratos">
                                    <thead>
                                        <tr>
                                            <th scope="col">Cliente</th>
                                            <th scope="col">Membresía</th>
                                            <th scope="col">Periodo</th>
                                            <th scope="col">Monto</th>
                                            <th scope="col">Pago</th>
                                            <th scope="col">Estado</th>
                                            <th scope="col" aria-label="Acciones"></th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <c:forEach var="con" items="${contratos}" varStatus="loop">
                                            <tr>
                                                <%-- Cliente con avatar --%>
                                                <td>
                                                    <div class="cell-name">
                                                        <c:set var="avColors" value="av--red,av--green,av--blue,av--purple,av--teal"/>
                                                        <c:set var="avIdx" value="${loop.index mod 5}"/>
                                                        <div class="cell-name__avatar ${fn:split(avColors, ',')[avIdx]}">
                                                            <c:out value="${fn:substring(con.cliente.nombre, 0, 1)}"/>
                                                        </div>
                                                        <div class="cell-name__info">
                                                            <span class="cell-name__primary">
                                                                <c:out value="${con.cliente.nombreCompleto}"/>
                                                            </span>
                                                            <span class="cell-name__secondary">
                                                                <c:if test="${con.cliente.tipoDocumento != null}">
                                                                    <c:out value="${con.cliente.tipoDocumento.abreviado}"/>:
                                                                </c:if>
                                                                <c:out value="${con.cliente.numeroDocumento}"/>
                                                            </span>
                                                        </div>
                                                    </div>
                                                </td>

                                                <%-- Membresía --%>
                                                <td>
                                                    <div class="cell-data">
                                                        <span class="cell-data__main">
                                                            <c:out value="${con.membresia.nombreMembresia}"/>
                                                        </span>
                                                        <span class="cell-data__sub">
                                                            <c:out value="${con.membresia.duracionMeses}"/> mes(es)
                                                        </span>
                                                    </div>
                                                </td>

                                                <%-- Periodo --%>
                                                <td>
                                                    <div class="cell-data">
                                                        <span class="contrato-fechas">
                                                            <c:out value="${con.fechaInicio}"/>
                                                        </span>
                                                        <span class="contrato-fechas">
                                                            → <c:out value="${con.fechaFin}"/>
                                                        </span>
                                                    </div>
                                                </td>

                                                <%-- Monto --%>
                                                <td>
                                                    <span class="contrato-monto">
                                                        <fmt:formatNumber value="${con.montoPagado}" pattern="#,##0.00"/>
                                                    </span>
                                                </td>

                                                <%-- Método de pago --%>
                                                <td>
                                                    <span class="cell-data__sub">
                                                        <c:out value="${con.metodoPago.nombre}"/>
                                                    </span>
                                                </td>

                                                <%-- Estado --%>
                                                <td>
                                                    <span class="badge-estado badge-estado--${con.estado}">
                                                        <c:out value="${con.estado}"/>
                                                    </span>
                                                </td>

                                                <%-- Acciones --%>
                                                <td>
                                                    <div class="cell-actions">

                                                        <%-- Ver detalle --%>
                                                        <a href="${pageContext.request.contextPath}/contracts?action=view&id=<c:out value='${con.id}'/>"
                                                           class="btn btn-ghost btn-sm btn-icon"
                                                           title="Ver detalle del contrato">
                                                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                                <path stroke-linecap="round" stroke-linejoin="round"
                                                                      d="M2.036 12.322a1.012 1.012 0 0 1 0-.639C3.423 7.51
                                                                         7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963
                                                                         7.178.07.207.07.431 0 .639C20.577 16.49 16.64
                                                                         19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178Z"/>
                                                                <path stroke-linecap="round" stroke-linejoin="round"
                                                                      d="M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z"/>
                                                            </svg>
                                                        </a>

                                                        <%-- Ver perfil del cliente --%>
                                                        <a href="${pageContext.request.contextPath}/clients?action=view&id=<c:out value='${con.cliente.id}'/>"
                                                           class="btn btn-ghost btn-sm btn-icon"
                                                           title="Ver perfil de ${con.cliente.nombre}">
                                                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                                <path stroke-linecap="round" stroke-linejoin="round"
                                                                      d="M15.75 6a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5
                                                                         0ZM4.501 20.118a7.5 7.5 0 0 1 14.998 0A17.933 17.933
                                                                         0 0 1 12 21.75c-2.676 0-5.216-.584-7.499-1.632Z"/>
                                                            </svg>
                                                        </a>

                                                        <%-- Cancelar (solo admin, solo activos) --%>
                                                        <c:if test="${sessionScope.userRole eq 'ROL-ADMIN' and con.estado eq 'activo'}">
                                                            <form action="${pageContext.request.contextPath}/contracts"
                                                                  method="post"
                                                                  style="display:inline;"
                                                                  onsubmit="return confirm('¿Cancelar el contrato de ${con.cliente.nombre}? Esta acción no se puede deshacer.');">
                                                                <input type="hidden" name="action" value="cancel">
                                                                <input type="hidden" name="id"     value="<c:out value='${con.id}'/>">
                                                                <input type="hidden" name="_csrf"  value="${sessionScope._csrfToken}">
                                                                <button type="submit"
                                                                        class="btn btn-danger btn-sm btn-icon"
                                                                        title="Cancelar contrato">
                                                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                                        <path stroke-linecap="round" stroke-linejoin="round"
                                                                              d="M6 18 18 6M6 6l12 12"/>
                                                                    </svg>
                                                                </button>
                                                            </form>
                                                        </c:if>

                                                    </div>
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
                                        Mostrando
                                        <strong style="color:var(--clr-text-muted);">
                                            <c:out value="${totalContratos}"/>
                                        </strong>
                                        contrato<c:if test="${totalContratos ne 1}">s</c:if>
                                        <c:if test="${not empty clienteFiltro}">
                                            de <strong style="color:var(--clr-text-muted);">
                                                <c:out value="${clienteFiltro.nombreCompleto}"/>
                                            </strong>
                                        </c:if>
                                    </span>
                                    <a href="${pageContext.request.contextPath}/contracts?action=new"
                                       class="btn btn-primary btn-sm">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.2">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M12 4.5v15m7.5-7.5h-15"/>
                                        </svg>
                                        Agregar contrato
                                    </a>
                                </div>

                            </c:when>

                            <c:otherwise>
                                <div class="table-empty">
                                    <div class="table-empty__icon">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125
                                                     1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0
                                                     0-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5
                                                     2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0
                                                     .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504
                                                     1.125-1.125V11.25a9 9 0 0 0-9-9Z"/>
                                        </svg>
                                    </div>
                                    <c:choose>
                                        <c:when test="${not empty clienteFiltro}">
                                            <p class="table-empty__title">Sin contratos para este cliente</p>
                                            <p class="table-empty__desc">
                                                <strong><c:out value="${clienteFiltro.nombreCompleto}"/></strong>
                                                aún no tiene contratos registrados.
                                            </p>
                                            <a href="${pageContext.request.contextPath}/contracts?action=new&clienteId=<c:out value='${clienteFiltro.id}'/>"
                                               class="btn btn-primary btn-sm" style="margin-top:0.5rem;">
                                                Crear contrato para este cliente
                                            </a>
                                        </c:when>
                                        <c:otherwise>
                                            <p class="table-empty__title">No hay contratos registrados</p>
                                            <p class="table-empty__desc">
                                                Registra el primer contrato asignando una membresía a un cliente.
                                            </p>
                                            <a href="${pageContext.request.contextPath}/contracts?action=new"
                                               class="btn btn-primary btn-sm" style="margin-top:0.5rem;">
                                                Registrar primer contrato
                                            </a>
                                        </c:otherwise>
                                    </c:choose>
                                </div>
                            </c:otherwise>
                        </c:choose>
                    </div><%-- /module-table-wrapper --%>

                </c:otherwise>
            </c:choose>

        </div><%-- /page-content --%>
    </div><%-- /app-main --%>
</div><%-- /app-shell --%>

</body>
</html>
