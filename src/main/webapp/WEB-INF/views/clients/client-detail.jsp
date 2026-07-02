<%-- ============================================================
     client-detail.jsp  —  MaxFit Sistema de Gestión
     Vista de detalle completo de un cliente.

     Servlet:  ClientsController.java  →  GET /clients?action=view&id=...
     Acceso:   ROL-ADMIN | ROL-RECEP  (RoleFilter)

     ── Atributos de request ─────────────────────────────────
       cliente       (Cliente)              → datos del cliente
       contratos     (List<Contrato>)       → historial de contratos
       inscripciones (List<InscripcionClase>)→ clases inscritas
       asistencias   (List<Asistencia>)     → historial de check-ins

     Flash: successMsg / errorMsg
     ============================================================ --%>
<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="fn"  uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <%@ include file="/WEB-INF/views/includes/head-common.jsp" %>
    <c:set var="pageTitle" value="Detalle Cliente" scope="request"/>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/modules.css">
    <style>
        /* ── Estilos específicos de client-detail ──────────── */

        /* Timeline de asistencias */
        .attend-timeline {
            display: flex;
            flex-direction: column;
            gap: 0;
        }

        .attend-row {
            display: flex;
            align-items: center;
            gap: 1rem;
            padding: 0.7rem 1.25rem;
            border-bottom: 1px solid var(--clr-border-light);
            transition: background var(--transition);
        }

        .attend-row:last-child { border-bottom: none; }
        .attend-row:hover { background: rgba(255,255,255,0.02); }

        .attend-row__date {
            flex-shrink: 0;
            min-width: 90px;
            font-size: 0.78rem;
            color: var(--clr-text-muted);
            font-weight: 500;
        }

        .attend-row__dot {
            flex-shrink: 0;
            width: 8px;
            height: 8px;
            border-radius: 50%;
        }

        .attend-row__dot.ok      { background: var(--clr-success); }
        .attend-row__dot.falto   { background: var(--clr-text-dim); }
        .attend-row__dot.pending { background: var(--clr-warning); }

        .attend-row__membresia {
            flex: 1;
            font-size: 0.80rem;
            color: var(--clr-text-dim);
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .attend-row__hora {
            flex-shrink: 0;
            font-family: var(--font-mono);
            font-size: 0.72rem;
            color: var(--clr-text-muted);
            background: var(--clr-surface);
            padding: 0.15rem 0.45rem;
            border-radius: var(--radius-xs);
            border: 1px solid var(--clr-border-light);
        }

        /* Card de contrato activo — destacada */
        .active-contract-card {
            background: linear-gradient(135deg, #ffffff 0%, #ffffff 100%);
            border: 1px solid rgba(34,197,94,0.22);
            border-radius: var(--radius-lg);
            padding: 1.1rem 1.25rem;
            position: relative;
            overflow: hidden;
        }

        .active-contract-card::before {
            content: '';
            position: absolute;
            left: 0; top: 0; bottom: 0;
            width: 3px;
            background: var(--clr-success);
            border-radius: 0 2px 2px 0;
        }

        .active-contract-card::after {
            content: '';
            position: absolute;
            bottom: -40px; right: -40px;
            width: 130px; height: 130px;
            background: radial-gradient(circle, rgba(34,197,94,0.10) 0%, transparent 65%);
            pointer-events: none;
        }

        .active-contract-card__badge {
            display: inline-flex;
            align-items: center;
            gap: 0.3rem;
            padding: 0.18rem 0.6rem;
            border-radius: var(--radius-full);
            font-size: 0.65rem;
            font-weight: 700;
            letter-spacing: 0.08em;
            text-transform: uppercase;
            background: var(--clr-success-subtle);
            color: var(--clr-success);
            border: 1px solid rgba(34,197,94,0.25);
            margin-bottom: 0.65rem;
        }

        .active-contract-card__badge::before {
            content: '';
            width: 6px; height: 6px;
            border-radius: 50%;
            background: var(--clr-success);
            animation: pulse-green 2s ease-in-out infinite;
        }

        .active-contract-card__membresia {
            font-family: var(--font-display);
            font-weight: 800;
            font-size: 1.25rem;
            letter-spacing: 0.03em;
            text-transform: uppercase;
            color: var(--clr-text);
            line-height: 1.1;
            margin-bottom: 0.3rem;
        }

        .active-contract-card__meta {
            font-size: 0.78rem;
            color: var(--clr-text-muted);
            display: flex;
            flex-wrap: wrap;
            gap: 0.5rem;
            align-items: center;
        }

        .active-contract-card__meta-sep {
            width: 3px; height: 3px;
            border-radius: 50%;
            background: var(--clr-text-dim);
        }

        .active-contract-card__vence {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-top: 0.85rem;
            padding-top: 0.75rem;
            border-top: 1px solid rgba(34,197,94,0.12);
        }

        .active-contract-card__vence-label {
            font-size: 0.70rem;
            color: var(--clr-text-dim);
            text-transform: uppercase;
            letter-spacing: 0.08em;
        }

        .active-contract-card__vence-date {
            font-family: var(--font-display);
            font-size: 1rem;
            font-weight: 700;
            color: var(--clr-success);
        }

        /* Card de sin contrato */
        .no-contract-card {
            background: var(--clr-surface);
            border: 1px dashed var(--clr-border);
            border-radius: var(--radius-lg);
            padding: 1.25rem;
            display: flex;
            flex-direction: column;
            align-items: center;
            text-align: center;
            gap: 0.65rem;
        }

        .no-contract-card svg {
            width: 32px; height: 32px;
            color: var(--clr-text-dim);
            opacity: 0.4;
        }

        .no-contract-card p {
            font-size: 0.80rem;
            color: var(--clr-text-dim);
            line-height: 1.5;
        }

        /* Stats bar del cliente */
        .client-stats-bar {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 0;
            background: var(--clr-card);
            border: 1px solid var(--clr-card-border);
            border-radius: var(--radius-lg);
            overflow: hidden;
            margin-bottom: 1.5rem;
        }

        .client-stat {
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: 1rem 0.75rem;
            gap: 0.2rem;
            border-right: 1px solid var(--clr-border-light);
            transition: background var(--transition);
        }

        .client-stat:last-child { border-right: none; }
        .client-stat:hover { background: rgba(255,255,255,0.02); }

        .client-stat__num {
            font-family: var(--font-display);
            font-size: 1.6rem;
            font-weight: 800;
            line-height: 1;
            color: var(--clr-text);
        }

        .client-stat__num.accent { color: var(--clr-red); }
        .client-stat__num.green  { color: var(--clr-success); }

        .client-stat__label {
            font-size: 0.68rem;
            font-weight: 600;
            letter-spacing: 0.08em;
            text-transform: uppercase;
            color: var(--clr-text-dim);
        }

        /* Fila de contrato en historial */
        .contract-row {
            display: flex;
            align-items: center;
            gap: 0.85rem;
            padding: 0.8rem 1.25rem;
            border-bottom: 1px solid var(--clr-border-light);
            transition: background var(--transition);
        }

        .contract-row:last-child { border-bottom: none; }
        .contract-row:hover { background: rgba(255,255,255,0.025); }

        .contract-row__icon {
            flex-shrink: 0;
            width: 32px; height: 32px;
            border-radius: var(--radius-sm);
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .contract-row__icon svg { width: 14px; height: 14px; }

        .contract-row__icon.activo    { background: var(--clr-success-subtle); color: var(--clr-success); }
        .contract-row__icon.vencido   { background: var(--clr-danger-subtle);  color: var(--clr-red); }
        .contract-row__icon.cancelado { background: rgba(255,255,255,0.05); color: var(--clr-text-dim); }

        .contract-row__info { flex: 1; min-width: 0; }

        .contract-row__membresia {
            font-size: 0.85rem;
            font-weight: 600;
            color: var(--clr-text);
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .contract-row__fechas {
            font-size: 0.72rem;
            color: var(--clr-text-dim);
        }

        .contract-row__monto {
            flex-shrink: 0;
            font-family: var(--font-display);
            font-size: 1rem;
            font-weight: 700;
            color: var(--clr-text-muted);
        }

        /* Inscripciones */
        .inscripcion-chip {
            display: inline-flex;
            align-items: center;
            gap: 0.45rem;
            padding: 0.45rem 0.85rem;
            background: var(--clr-surface);
            border: 1px solid var(--clr-border);
            border-radius: var(--radius-md);
            font-size: 0.80rem;
            font-weight: 500;
            color: var(--clr-text-muted);
            transition: border-color var(--transition), background var(--transition);
        }

        .inscripcion-chip svg { width: 13px; height: 13px; color: var(--clr-text-dim); }

        .inscripcion-chip:hover {
            border-color: rgba(230,48,39,0.22);
            background: var(--clr-surface-2);
            color: var(--clr-text);
        }

        .inscripciones-grid {
            display: flex;
            flex-wrap: wrap;
            gap: 0.5rem;
            padding: 1rem 1.25rem;
        }

        @keyframes pulse-green {
            0%,100% { box-shadow: 0 0 0 0 rgba(34,197,94,0.4); }
            50%      { box-shadow: 0 0 0 5px transparent; }
        }
    </style>
</head>
<body>

<div class="app-shell">
    <%@ include file="/WEB-INF/views/includes/sidebar.jsp" %>

    <div class="app-main">
        <c:set var="pageTitle"    value="Perfil de Cliente" scope="request"/>
        <c:set var="pageSubtitle" value="Módulo de Clientes" scope="request"/>
        <%@ include file="/WEB-INF/views/includes/navbar.jsp" %>

        <div class="page-content">

            <%-- Breadcrumb --%>
            <nav class="module-breadcrumb" aria-label="Breadcrumb">
                <a href="${pageContext.request.contextPath}/clients">Clientes</a>
                <svg class="module-breadcrumb__sep" xmlns="http://www.w3.org/2000/svg"
                     fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7"/>
                </svg>
                <span><c:out value="${cliente.nombreCompleto}"/></span>
            </nav>

            <%-- ── Hero del perfil del cliente ──────────────── --%>
            <div class="profile-hero">
                <div class="profile-hero__avatar hero--red">
                    <c:out value="${fn:substring(cliente.nombre, 0, 1)}"/>
                </div>

                <div class="profile-hero__info">
                    <h1 class="profile-hero__name">
                        <c:out value="${cliente.nombreCompleto}"/>
                    </h1>
                    <div class="profile-hero__sub">
                        <c:if test="${cliente.tipoDocumento != null}">
                            <span><c:out value="${cliente.tipoDocumento.abreviado}"/>:
                                  <c:out value="${cliente.numeroDocumento}"/></span>
                            <span class="profile-hero__sub-sep"></span>
                        </c:if>
                        <c:if test="${not empty cliente.email}">
                            <span><c:out value="${cliente.email}"/></span>
                        </c:if>
                        <c:if test="${not empty cliente.telefono}">
                            <span class="profile-hero__sub-sep"></span>
                            <span><c:out value="${cliente.telefono}"/></span>
                        </c:if>
                    </div>
                    <div class="profile-hero__badges">
                        <%-- Género --%>
                        <c:if test="${not empty cliente.genero}">
                            <span class="badge-estado badge-estado--pago-activo">
                                <c:out value="${cliente.genero}"/>
                            </span>
                        </c:if>
                        <%-- Fecha nacimiento si existe --%>
                        <c:if test="${not empty cliente.fechaNacimiento}">
                            <span class="badge-estado badge-estado--cancelado">
                                Nació: <c:out value="${cliente.fechaNacimiento}"/>
                            </span>
                        </c:if>
                        <%-- ID del sistema --%>
                        <span class="cell-id"><c:out value="${cliente.id}"/></span>
                    </div>
                </div>

                <div class="profile-hero__actions">
                    <c:if test="${sessionScope.userRole eq 'ROL-ADMIN'}">
                        <a href="${pageContext.request.contextPath}/clients?action=edit&id=<c:out value='${cliente.id}'/>"
                           class="btn btn-secondary btn-sm">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                      d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652
                                         2.652L10.582 16.07a4.5 4.5 0 0 1-1.897 1.13L6 18l.8-2.685a4.5
                                         4.5 0 0 1 1.13-1.897l8.932-8.931Zm0 0L19.5 7.125"/>
                            </svg>
                            Editar
                        </a>
                    </c:if>
                    <a href="${pageContext.request.contextPath}/contracts?action=new&clienteId=<c:out value='${cliente.id}'/>"
                       class="btn btn-primary btn-sm">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M12 4.5v15m7.5-7.5h-15"/>
                        </svg>
                        Nuevo contrato
                    </a>
                </div>
            </div>

            <%-- ── Stats rápidas ────────────────────────────── --%>
            <div class="client-stats-bar">
                <div class="client-stat">
                    <span class="client-stat__num">
                        <c:out value="${fn:length(contratos)}"/>
                    </span>
                    <span class="client-stat__label">Contratos</span>
                </div>
                <div class="client-stat">
                    <span class="client-stat__num green">
                        <c:out value="${fn:length(asistencias)}"/>
                    </span>
                    <span class="client-stat__label">Check-ins</span>
                </div>
                <div class="client-stat">
                    <span class="client-stat__num accent">
                        <c:out value="${fn:length(inscripciones)}"/>
                    </span>
                    <span class="client-stat__label">Clases inscritas</span>
                </div>
            </div>

            <%-- ── Layout principal: contenido + aside ──────── --%>
            <div class="detail-layout">

                <%-- ═══════════════════════════════
                     COLUMNA PRINCIPAL
                     ═══════════════════════════════ --%>
                <div>

                    <%-- ── Historial de contratos ─────────── --%>
                    <div class="detail-section detail-section--full"
                         style="margin-bottom:1.25rem;">
                        <div class="detail-section__header">
                            <div class="detail-section__icon">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125
                                             1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H8.25m0
                                             12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125
                                             1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0
                                             1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z"/>
                                </svg>
                            </div>
                            <span class="detail-section__title">
                                Historial de Contratos
                            </span>
                            <span class="stat-chip" style="margin-left:auto;">
                                <c:out value="${fn:length(contratos)}"/>
                            </span>
                            <a href="${pageContext.request.contextPath}/contracts?action=new&clienteId=<c:out value='${cliente.id}'/>"
                               class="btn btn-primary btn-sm" style="margin-left:0.75rem;">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M12 4.5v15m7.5-7.5h-15"/>
                                </svg>
                                Nuevo
                            </a>
                        </div>

                        <c:choose>
                            <c:when test="${not empty contratos}">
                                <div>
                                    <c:forEach var="con" items="${contratos}">
                                        <div class="contract-row">
                                            <%-- Ícono de estado --%>
                                            <div class="contract-row__icon ${con.estado}">
                                                <c:choose>
                                                    <c:when test="${con.estado eq 'activo'}">
                                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                                  d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                                        </svg>
                                                    </c:when>
                                                    <c:when test="${con.estado eq 'vencido'}">
                                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                                  d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                                        </svg>
                                                    </c:when>
                                                    <c:otherwise>
                                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                                  d="M6 18 18 6M6 6l12 12"/>
                                                        </svg>
                                                    </c:otherwise>
                                                </c:choose>
                                            </div>

                                            <div class="contract-row__info">
                                                <p class="contract-row__membresia">
                                                    <c:out value="${con.membresia.nombreMembresia}"/>
                                                </p>
                                                <p class="contract-row__fechas">
                                                    <c:out value="${con.fechaInicio}"/> →
                                                    <c:out value="${con.fechaFin}"/>
                                                    &nbsp;·&nbsp;
                                                    Pago: <c:out value="${con.metodoPago.nombre}"/>
                                                </p>
                                            </div>

                                            <span class="badge-estado badge-estado--${con.estado}">
                                                <c:out value="${con.estado}"/>
                                            </span>

                                            <span class="contract-row__monto">
                                                S/ <fmt:formatNumber value="${con.montoPagado}" pattern="#,##0.00"/>
                                            </span>

                                            <%-- Ver detalle del contrato --%>
                                            <a href="${pageContext.request.contextPath}/contracts?action=view&id=<c:out value='${con.id}'/>"
                                               class="btn btn-ghost btn-sm btn-icon"
                                               title="Ver contrato <c:out value='${con.id}'/>">
                                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                    <path stroke-linecap="round" stroke-linejoin="round"
                                                          d="M13.5 4.5 21 12m0 0-7.5 7.5M21 12H3"/>
                                                </svg>
                                            </a>
                                        </div>
                                    </c:forEach>
                                </div>
                            </c:when>
                            <c:otherwise>
                                <div class="table-empty" style="padding:2rem;">
                                    <div class="table-empty__icon">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125
                                                     1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0
                                                     0-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621
                                                     0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125
                                                     1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z"/>
                                        </svg>
                                    </div>
                                    <p class="table-empty__title">Sin contratos</p>
                                    <p class="table-empty__desc">
                                        Este cliente aún no tiene contratos registrados.
                                    </p>
                                </div>
                            </c:otherwise>
                        </c:choose>
                    </div>

                    <%-- ── Historial de asistencias ────────── --%>
                    <div class="detail-section detail-section--full"
                         style="margin-bottom:1.25rem;">
                        <div class="detail-section__header">
                            <div class="detail-section__icon">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                </svg>
                            </div>
                            <span class="detail-section__title">Historial de Asistencias</span>
                            <span class="stat-chip chip--green" style="margin-left:auto;">
                                <c:out value="${fn:length(asistencias)}"/> check-ins
                            </span>
                        </div>

                        <c:choose>
                            <c:when test="${not empty asistencias}">
                                <%-- Mostrar máximo 15 recientes --%>
                                <div class="attend-timeline">
                                    <c:forEach var="asi" items="${asistencias}" end="14">
                                        <div class="attend-row">
                                            <span class="attend-row__date">
                                                <c:out value="${asi.fecha}"/>
                                            </span>
                                            <span class="attend-row__dot
                                                ${asi.isAsistio() ? 'ok' : ''}
                                                ${asi.isFalto()   ? 'falto' : ''}
                                                ${asi.isPendiente() ? 'pending' : ''}">
                                            </span>
                                            <span class="attend-row__membresia">
                                                <c:if test="${asi.contrato != null and asi.contrato.membresia != null}">
                                                    <c:out value="${asi.contrato.membresia.nombreMembresia}"/>
                                                </c:if>
                                            </span>
                                            <span class="badge-estado badge-estado--${asi.estado}">
                                                <c:out value="${asi.estado}"/>
                                            </span>
                                            <span class="attend-row__hora">
                                                <c:out value="${asi.horaIngresoFormateada}"/>
                                            </span>
                                        </div>
                                    </c:forEach>
                                </div>

                                <c:if test="${fn:length(asistencias) gt 15}">
                                    <div style="padding:0.65rem 1.25rem; border-top:1px solid var(--clr-border-light);
                                                background:rgba(255,255,255,0.012);
                                                font-size:0.75rem; color:var(--clr-text-dim);">
                                        Mostrando los últimos 15 de
                                        <strong style="color:var(--clr-text-muted);">
                                            <c:out value="${fn:length(asistencias)}"/>
                                        </strong>
                                        registros totales.
                                    </div>
                                </c:if>
                            </c:when>
                            <c:otherwise>
                                <div class="table-empty" style="padding:2rem;">
                                    <div class="table-empty__icon">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                        </svg>
                                    </div>
                                    <p class="table-empty__title">Sin asistencias</p>
                                    <p class="table-empty__desc">
                                        Este cliente aún no tiene check-ins registrados.
                                    </p>
                                </div>
                            </c:otherwise>
                        </c:choose>
                    </div>

                    <%-- ── Clases inscritas ────────────────── --%>
                    <div class="detail-section detail-section--full">
                        <div class="detail-section__header">
                            <div class="detail-section__icon">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75
                                             12 13.5H3.75z"/>
                                </svg>
                            </div>
                            <span class="detail-section__title">Clases Inscritas</span>
                            <span class="stat-chip chip--red" style="margin-left:auto;">
                                <c:out value="${fn:length(inscripciones)}"/>
                            </span>
                        </div>

                        <c:choose>
                            <c:when test="${not empty inscripciones}">
                                <div class="inscripciones-grid">
                                    <c:forEach var="ins" items="${inscripciones}">
                                        <div class="inscripcion-chip">
                                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                <path stroke-linecap="round" stroke-linejoin="round"
                                                      d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25
                                                         0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18
                                                         0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0
                                                         21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25
                                                         9h13.5A2.25 2.25 0 0 1 21 11.25v7.5"/>
                                            </svg>
                                            <c:out value="${ins.clase.nombreClase}"/>
                                        </div>
                                    </c:forEach>
                                </div>
                            </c:when>
                            <c:otherwise>
                                <div class="table-empty" style="padding:1.75rem;">
                                    <div class="table-empty__icon">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75
                                                     12 13.5H3.75z"/>
                                        </svg>
                                    </div>
                                    <p class="table-empty__title">Sin inscripciones</p>
                                    <p class="table-empty__desc">
                                        No está inscrito en ninguna clase grupal.
                                    </p>
                                </div>
                            </c:otherwise>
                        </c:choose>
                    </div>

                </div><%-- /columna principal --%>

                <%-- ═══════════════════════════════
                     ASIDE DERECHO
                     ═══════════════════════════════ --%>
                <aside class="detail-aside">

                    <%-- ── Contrato activo ────────────────── --%>
                    <div>
                        <p style="font-size:0.68rem; font-weight:700; letter-spacing:0.10em;
                                  text-transform:uppercase; color:var(--clr-text-dim);
                                  margin-bottom:0.65rem;">
                            Membresía actual
                        </p>

                        <%-- Buscar contrato activo --%>
                        <c:set var="contratoActivo" value="${null}"/>
                        <c:forEach var="con" items="${contratos}">
                            <c:if test="${con.estado eq 'activo'}">
                                <c:set var="contratoActivo" value="${con}"/>
                            </c:if>
                        </c:forEach>

                        <c:choose>
                            <c:when test="${not empty contratoActivo}">
                                <div class="active-contract-card">
                                    <div class="active-contract-card__badge">
                                        Contrato activo
                                    </div>
                                    <p class="active-contract-card__membresia">
                                        <c:out value="${contratoActivo.membresia.nombreMembresia}"/>
                                    </p>
                                    <div class="active-contract-card__meta">
                                        <span>
                                            S/ <fmt:formatNumber
                                                   value="${contratoActivo.membresia.precio}"
                                                   pattern="#,##0.00"/>
                                        </span>
                                        <span class="active-contract-card__meta-sep"></span>
                                        <span>
                                            <c:out value="${contratoActivo.membresia.duracionMeses}"/> mes(es)
                                        </span>
                                        <span class="active-contract-card__meta-sep"></span>
                                        <span><c:out value="${contratoActivo.metodoPago.nombre}"/></span>
                                    </div>
                                    <div class="active-contract-card__vence">
                                        <span class="active-contract-card__vence-label">Vence el</span>
                                        <span class="active-contract-card__vence-date">
                                            <c:out value="${contratoActivo.fechaFin}"/>
                                        </span>
                                    </div>
                                </div>
                            </c:when>
                            <c:otherwise>
                                <div class="no-contract-card">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125
                                                 1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0
                                                 0-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621
                                                 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125
                                                 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z"/>
                                    </svg>
                                    <p>Sin membresía activa</p>
                                    <a href="${pageContext.request.contextPath}/contracts?action=new&clienteId=<c:out value='${cliente.id}'/>"
                                       class="btn btn-primary btn-sm" style="width:100%;">
                                        Agregar membresía
                                    </a>
                                </div>
                            </c:otherwise>
                        </c:choose>
                    </div>

                    <%-- ── Datos personales ───────────────── --%>
                    <div class="aside-summary-card">
                        <div class="aside-summary-card__header">Datos personales</div>
                        <div class="aside-summary-card__body">

                            <div class="aside-data-row">
                                <span class="aside-data-row__label">Documento</span>
                                <span class="aside-data-row__value strong mono">
                                    <c:if test="${cliente.tipoDocumento != null}">
                                        <c:out value="${cliente.tipoDocumento.abreviado}"/>:
                                    </c:if>
                                    <c:out value="${cliente.numeroDocumento}"/>
                                </span>
                            </div>

                            <div class="aside-data-row">
                                <span class="aside-data-row__label">Email</span>
                                <span class="aside-data-row__value">
                                    <c:choose>
                                        <c:when test="${not empty cliente.email}">
                                            <c:out value="${cliente.email}"/>
                                        </c:when>
                                        <c:otherwise>—</c:otherwise>
                                    </c:choose>
                                </span>
                            </div>

                            <div class="aside-data-row">
                                <span class="aside-data-row__label">Teléfono</span>
                                <span class="aside-data-row__value">
                                    <c:choose>
                                        <c:when test="${not empty cliente.telefono}">
                                            <c:out value="${cliente.telefono}"/>
                                        </c:when>
                                        <c:otherwise>—</c:otherwise>
                                    </c:choose>
                                </span>
                            </div>

                            <div class="aside-data-row">
                                <span class="aside-data-row__label">Nacimiento</span>
                                <span class="aside-data-row__value">
                                    <c:choose>
                                        <c:when test="${not empty cliente.fechaNacimiento}">
                                            <c:out value="${cliente.fechaNacimiento}"/>
                                        </c:when>
                                        <c:otherwise>—</c:otherwise>
                                    </c:choose>
                                </span>
                            </div>

                            <div class="aside-data-row">
                                <span class="aside-data-row__label">Género</span>
                                <span class="aside-data-row__value">
                                    <c:choose>
                                        <c:when test="${not empty cliente.genero}">
                                            <c:out value="${cliente.genero}"/>
                                        </c:when>
                                        <c:otherwise>—</c:otherwise>
                                    </c:choose>
                                </span>
                            </div>

                            <div class="aside-data-row">
                                <span class="aside-data-row__label">ID sistema</span>
                                <span class="aside-data-row__value mono" style="font-size:0.72rem;">
                                    <c:out value="${cliente.id}"/>
                                </span>
                            </div>

                        </div>
                    </div>

                    <%-- ── Acciones rápidas ───────────────── --%>
                    <div class="aside-summary-card">
                        <div class="aside-summary-card__header">Acciones rápidas</div>
                        <div class="aside-summary-card__body" style="gap:0.5rem;">

                            <a href="${pageContext.request.contextPath}/contracts?action=new&clienteId=<c:out value='${cliente.id}'/>"
                               class="btn btn-secondary btn-sm" style="width:100%; justify-content:flex-start;">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125
                                             1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0
                                             0-3.375-3.375H8.25m3.75 9v6m3-3H9m1.5-12H5.625c-.621
                                             0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125
                                             1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z"/>
                                </svg>
                                Nuevo contrato
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

                            <a href="${pageContext.request.contextPath}/schedules?action=inscritos"
                               class="btn btn-secondary btn-sm" style="width:100%; justify-content:flex-start;">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75
                                             12 13.5H3.75z"/>
                                </svg>
                                Ver clases
                            </a>

                            <c:if test="${sessionScope.userRole eq 'ROL-ADMIN'}">
                                <div style="border-top:1px solid var(--clr-border-light);
                                            padding-top:0.5rem; margin-top:0.1rem;">
                                    <a href="${pageContext.request.contextPath}/clients?action=edit&id=<c:out value='${cliente.id}'/>"
                                       class="btn btn-ghost btn-sm" style="width:100%; justify-content:flex-start;">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652
                                                     2.652L10.582 16.07a4.5 4.5 0 0 1-1.897 1.13L6
                                                     18l.8-2.685a4.5 4.5 0 0 1 1.13-1.897l8.932-8.931Zm0
                                                     0L19.5 7.125"/>
                                        </svg>
                                        Editar datos
                                    </a>

                                    <form action="${pageContext.request.contextPath}/clients"
                                          method="post"
                                          style="display:block; margin-top:0.35rem;"
                                          onsubmit="return confirm('¿Eliminar a ${cliente.nombre} ${cliente.apellido}? Solo es posible si no tiene contratos o inscripciones.');">
                                        <input type="hidden" name="action" value="delete">
                                        <input type="hidden" name="id"     value="<c:out value='${cliente.id}'/>">
                                        <input type="hidden" name="_csrf"  value="${sessionScope._csrfToken}">
                                        <button type="submit"
                                                class="btn btn-danger btn-sm"
                                                style="width:100%; justify-content:flex-start;">
                                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                <path stroke-linecap="round" stroke-linejoin="round"
                                                      d="m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107
                                                         1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 0
                                                         1-2.244 2.077H8.084a2.25 2.25 0 0
                                                         1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0
                                                         0 0-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0
                                                         0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964
                                                         51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09
                                                         2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0"/>
                                            </svg>
                                            Eliminar cliente
                                        </button>
                                    </form>
                                </div>
                            </c:if>

                        </div>
                    </div>

                </aside><%-- /detail-aside --%>

            </div><%-- /detail-layout --%>

        </div><%-- /page-content --%>
    </div><%-- /app-main --%>
</div><%-- /app-shell --%>

</body>
</html>
