<%-- ============================================================
     payment-methods.jsp  —  MaxFit Sistema de Gestión
     CRUD completo de métodos de pago (solo ROL-ADMIN)
     Servlet: PaymentMethodsController → GET/POST /payment-methods
     Vistas:
       /payment-methods            → lista de tarjetas
       /payment-methods?action=new → formulario nuevo
       /payment-methods?action=edit → formulario edición
     ============================================================ --%>
<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"  uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <%@ include file="/WEB-INF/views/includes/head-common.jsp" %>
    <c:choose>
        <c:when test="${mostrarForm eq true}"><%-- ← CAMBIADO --%>
            <c:set var="pageTitle" value="${modoEdicion ? 'Editar Método' : 'Nuevo Método'}" scope="request"/>
        </c:when>
        <c:otherwise>
            <c:set var="pageTitle" value="Métodos de Pago" scope="request"/>
        </c:otherwise>
    </c:choose>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/modules.css">

    <style>
        /* ── Grid de tarjetas ──────────────────────────────────── */
        .pm-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
            gap: 1rem;
        }

        /* ── Tarjeta de método de pago ─────────────────────────── */
        .pm-card {
            background: var(--clr-card);
            border: 1px solid var(--clr-card-border);
            border-radius: var(--radius-xl);
            overflow: hidden;
            position: relative;
            display: flex;
            flex-direction: column;
            transition: border-color var(--transition), transform var(--transition),
                        box-shadow var(--transition);
            animation: fadeSlideUp 0.42s cubic-bezier(0.4,0,0.2,1) both;
        }

        .pm-card:hover {
            border-color: rgba(255,255,255,0.08);
            transform: translateY(-2px);
            box-shadow: 0 8px 28px rgba(0,0,0,0.45);
        }

        /* franja lateral indicador de estado */
        .pm-card::after {
            content: '';
            position: absolute;
            left: 0; top: 0; bottom: 0;
            width: 3px;
            background: var(--pm-accent, var(--clr-text-dim));
            border-radius: 0 2px 2px 0;
        }

        .pm-card.is-active::after   { background: var(--pm-accent, var(--clr-success)); }
        .pm-card.is-inactive::after { background: var(--clr-text-dim); opacity: 0.5; }
        .pm-card.is-inactive        { opacity: 0.65; }
        .pm-card.is-inactive:hover  { opacity: 0.85; }

        /* paleta por tipo */
        .pm-card.pm--efectivo   { --pm-accent: #22c55e; --pm-icon-bg: rgba(34,197,94,0.08);  --pm-icon-border: rgba(34,197,94,0.18); }
        .pm-card.pm--visa       { --pm-accent: #3b82f6; --pm-icon-bg: rgba(59,130,246,0.08); --pm-icon-border: rgba(59,130,246,0.18); }
        .pm-card.pm--mastercard { --pm-accent: #f97316; --pm-icon-bg: rgba(249,115,22,0.08); --pm-icon-border: rgba(249,115,22,0.18); }
        .pm-card.pm--yape       { --pm-accent: #a78bfa; --pm-icon-bg: rgba(167,139,250,0.08);--pm-icon-border: rgba(167,139,250,0.18); }
        .pm-card.pm--plin       { --pm-accent: #2dd4bf; --pm-icon-bg: rgba(45,212,191,0.08); --pm-icon-border: rgba(45,212,191,0.18); }
        .pm-card.pm--transfer   { --pm-accent: #f59e0b; --pm-icon-bg: rgba(245,158,11,0.08); --pm-icon-border: rgba(245,158,11,0.18); }
        .pm-card.pm--default    { --pm-accent: var(--clr-red); --pm-icon-bg: var(--clr-red-subtle); --pm-icon-border: rgba(230,48,39,0.18); }

        .pm-card:nth-child(1){animation-delay:0.04s}
        .pm-card:nth-child(2){animation-delay:0.08s}
        .pm-card:nth-child(3){animation-delay:0.12s}
        .pm-card:nth-child(4){animation-delay:0.16s}
        .pm-card:nth-child(5){animation-delay:0.20s}
        .pm-card:nth-child(6){animation-delay:0.24s}

        .pm-card__icon-wrap {
            padding: 1.25rem 1.25rem 0.65rem;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .pm-card__icon {
            width: 48px; height: 48px;
            border-radius: var(--radius-lg);
            display: flex; align-items: center; justify-content: center;
            background: var(--pm-icon-bg, var(--clr-surface-2));
            border: 1px solid var(--pm-icon-border, var(--clr-border));
        }

        .pm-card__icon svg {
            width: 22px; height: 22px;
            color: var(--pm-accent, var(--clr-text-muted));
        }

        .pm-estado-dot {
            width: 9px; height: 9px;
            border-radius: 50%; flex-shrink: 0;
            align-self: flex-start; margin-top: 0.2rem;
        }
        .pm-estado-dot.activo {
            background: var(--clr-success);
            box-shadow: 0 0 0 3px rgba(34,197,94,0.18);
            animation: pulse-green 2.2s ease-in-out infinite;
        }
        .pm-estado-dot.inactivo { background: var(--clr-text-dim); }

        @keyframes pulse-green {
            0%,100%{ box-shadow: 0 0 0 0 rgba(34,197,94,0.4); }
            50%    { box-shadow: 0 0 0 6px transparent; }
        }

        .pm-card__body {
            padding: 0.15rem 1.25rem 0.85rem;
            flex: 1;
            display: flex; flex-direction: column; gap: 0.28rem;
        }

        .pm-card__nombre {
            font-family: var(--font-display);
            font-weight: 800; font-size: 1.1rem;
            letter-spacing: 0.04em; text-transform: uppercase;
            color: var(--clr-text); line-height: 1.15;
        }

        .pm-card__id {
            font-family: var(--font-mono);
            font-size: 0.64rem; color: var(--clr-text-dim);
            background: var(--clr-surface);
            padding: 0.14rem 0.45rem;
            border-radius: var(--radius-xs);
            border: 1px solid var(--clr-border-light);
            display: inline-block; width: fit-content;
        }

        .pm-card__status {
            font-size: 0.70rem; font-weight: 700;
            letter-spacing: 0.05em; text-transform: uppercase;
            margin-top: 0.2rem;
        }
        .pm-card__status.activo  { color: var(--clr-success); }
        .pm-card__status.inactivo{ color: var(--clr-text-dim); }

        /* footer con acciones */
        .pm-card__footer {
            padding: 0.75rem 1.25rem;
            border-top: 1px solid var(--clr-border-light);
            background: rgba(255,255,255,0.012);
            display: flex; gap: 0.5rem;
        }

        /* botón toggle */
        .pm-toggle-btn {
            display: flex; align-items: center; justify-content: center;
            gap: 0.5rem; flex: 1;
            padding: 0.5rem 0.85rem;
            border-radius: var(--radius-md);
            font-size: 0.75rem; font-weight: 700;
            letter-spacing: 0.03em;
            cursor: pointer; border: 1px solid;
            transition: all var(--transition);
        }
        .pm-toggle-btn svg { width: 12px; height: 12px; flex-shrink: 0; }

        .pm-toggle-btn--activar {
            background: var(--clr-success-subtle); color: var(--clr-success);
            border-color: rgba(34,197,94,0.28);
        }
        .pm-toggle-btn--activar:hover {
            background: var(--clr-success); color: #fff;
            border-color: var(--clr-success);
            box-shadow: 0 3px 14px rgba(34,197,94,0.4);
        }

        .pm-toggle-btn--desactivar {
            background: var(--clr-danger-subtle); color: var(--clr-red);
            border-color: rgba(230,48,39,0.25);
        }
        .pm-toggle-btn--desactivar:hover {
            background: var(--clr-red); color: #fff;
            border-color: var(--clr-red);
            box-shadow: 0 3px 14px rgba(230,48,39,0.38);
        }

        .pm-toggle-btn--disabled {
            background: var(--clr-surface); color: var(--clr-text-dim);
            border-color: var(--clr-border-light);
            cursor: not-allowed; opacity: 0.55;
        }

        /* KPI strip */
        .pm-kpi-strip {
            display: grid; grid-template-columns: repeat(3,1fr);
            background: var(--clr-card); border: 1px solid var(--clr-card-border);
            border-radius: var(--radius-lg); overflow: hidden;
            margin-bottom: 1.5rem;
        }
        .pm-kpi {
            display: flex; flex-direction: column;
            align-items: center; padding: 0.9rem 0.75rem; gap: 0.18rem;
            border-right: 1px solid var(--clr-border-light);
        }
        .pm-kpi:last-child { border-right: none; }
        .pm-kpi__num {
            font-family: var(--font-display); font-weight: 800;
            font-size: 1.6rem; line-height: 1; color: var(--clr-text);
        }
        .pm-kpi__num.green  { color: var(--clr-success); }
        .pm-kpi__num.dim    { color: var(--clr-text-dim); }
        .pm-kpi__label {
            font-size: 0.65rem; font-weight: 700;
            letter-spacing: 0.09em; text-transform: uppercase;
            color: var(--clr-text-dim);
        }

        /* aviso único activo */
        .pm-only-active-banner {
            display: flex; align-items: flex-start; gap: 0.75rem;
            padding: 0.85rem 1rem;
            background: var(--clr-warning-subtle);
            border: 1px solid rgba(245,158,11,0.25);
            border-radius: var(--radius-md); margin-bottom: 1.25rem;
        }
        .pm-only-active-banner svg { flex-shrink: 0; width: 16px; height: 16px; color: var(--clr-warning); margin-top:1px; }
        .pm-only-active-banner p   { font-size: 0.80rem; color: #fcd34d; font-weight: 500; line-height: 1.5; }
        .pm-only-active-banner strong { font-weight: 700; }

        /* nota al pie */
        .pm-info-footer {
            margin-top: 1.25rem;
            display: flex; align-items: flex-start; gap: 0.65rem;
            padding: 0.85rem 1.1rem;
            background: var(--clr-card); border: 1px solid var(--clr-card-border);
            border-radius: var(--radius-md);
        }
        .pm-info-footer svg { flex-shrink:0; width:14px; height:14px; color:var(--clr-text-dim); margin-top:1px; }
        .pm-info-footer p   { font-size:0.74rem; color:var(--clr-text-dim); line-height:1.55; }
        .pm-info-footer p strong { color:var(--clr-text-muted); }

        @media(max-width:768px){
            .pm-grid{ grid-template-columns:1fr 1fr; }
            .pm-kpi-strip{ grid-template-columns:1fr; }
            .pm-kpi{ border-right:none; border-bottom:1px solid var(--clr-border-light); }
            .pm-kpi:last-child{ border-bottom:none; }
        }
        @media(max-width:480px){ .pm-grid{ grid-template-columns:1fr; } }
    </style>
</head>
<body>
<div class="app-shell">
    <%@ include file="/WEB-INF/views/includes/sidebar.jsp" %>
    <div class="app-main">
        <c:choose>
            <c:when test="${mostrarForm eq true}"><%-- ← CAMBIADO --%>
                <c:set var="pageTitle"    value="${modoEdicion ? 'Editar Método de Pago' : 'Nuevo Método de Pago'}" scope="request"/>
                <c:set var="pageSubtitle" value="Configuración" scope="request"/>
            </c:when>
            <c:otherwise>
                <c:set var="pageTitle"    value="Métodos de Pago"          scope="request"/>
                <c:set var="pageSubtitle" value="Configuración del sistema" scope="request"/>
            </c:otherwise>
        </c:choose>
        <%@ include file="/WEB-INF/views/includes/navbar.jsp" %>

        <div class="page-content">
            <c:choose>

                <%-- ══════════════════════════════════════
                     VISTA: FORMULARIO NUEVO / EDICIÓN
                     ══════════════════════════════════════ --%>
                <c:when test="${mostrarForm eq true}"><%-- ← CAMBIADO --%>

                    <nav class="module-breadcrumb" aria-label="Breadcrumb">
                        <a href="${pageContext.request.contextPath}/payment-methods">Métodos de Pago</a>
                        <svg class="module-breadcrumb__sep" xmlns="http://www.w3.org/2000/svg"
                             fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7"/>
                        </svg>
                        <span>${modoEdicion ? 'Editar' : 'Nuevo'}</span>
                    </nav>

                    <div class="module-header">
                        <div class="module-header__left">
                            <h1 class="module-header__title">
                                ${modoEdicion ? 'Editar Método de Pago' : 'Nuevo Método de Pago'}
                            </h1>
                            <div class="module-header__meta">
                                <span>${modoEdicion ? 'Modifica los datos del método' : 'Registra un nuevo método de pago'}</span>
                            </div>
                        </div>
                        <div class="module-header__actions">
                            <a href="${pageContext.request.contextPath}/payment-methods"
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

                    <c:if test="${not empty formError}">
                        <div class="module-alert module-alert--error" role="alert">
                            <svg class="module-alert__icon" xmlns="http://www.w3.org/2000/svg"
                                 fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                      d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948
                                         3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949
                                         3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126ZM12
                                         15.75h.007v.008H12v-.008Z"/>
                            </svg>
                            <div class="module-alert__body">
                                <p class="module-alert__title">Error de validación</p>
                                <p class="module-alert__text"><c:out value="${formError}"/></p>
                            </div>
                        </div>
                    </c:if>

                    <form action="${pageContext.request.contextPath}/payment-methods"
                          method="post" novalidate autocomplete="off">
                        <input type="hidden" name="action" value="save">
                        <input type="hidden" name="_csrf"  value="${sessionScope._csrfToken}">
                        <c:if test="${modoEdicion}">
                            <input type="hidden" name="id" value="<c:out value='${metodoPago.id}'/>">
                        </c:if>

                        <div class="form-card">
                            <div class="form-card__header">
                                <div class="form-card__header-icon">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M2.25 8.25h19.5M2.25 9h19.5m-16.5 5.25h6m-6 2.25h3m-3.75
                                                 3h15a2.25 2.25 0 0 0 2.25-2.25V6.75A2.25 2.25 0 0 0
                                                 19.5 4.5h-15a2.25 2.25 0 0 0-2.25 2.25v10.5A2.25 2.25
                                                 0 0 0 4.5 19.5Z"/>
                                    </svg>
                                </div>
                                <div>
                                    <p class="form-card__header-title">
                                        ${modoEdicion ? 'Editar Método' : 'Nuevo Método de Pago'}
                                    </p>
                                    <p class="form-card__header-sub">
                                        <c:if test="${modoEdicion}">ID: <c:out value="${metodoPago.id}"/></c:if>
                                        <c:if test="${not modoEdicion}">El ID se genera automáticamente del nombre</c:if>
                                    </p>
                                </div>
                            </div>

                            <div class="form-card__body">
                                <div class="form-section-divider">
                                    <span class="form-section-divider__label">Datos del método</span>
                                </div>

                                <div class="form-row">
                                    <div class="form-field">
                                        <label for="nombre">
                                            Nombre <span class="required-star">*</span>
                                        </label>
                                        <input type="text" id="nombre" name="nombre"
                                               class="form-control"
                                               placeholder="Ej: Transferencia Bancaria"
                                               maxlength="50" required
                                               value="<c:out value='${metodoPago.nombre}'/>">
                                        <span class="form-field__hint">
                                            Nombre visible al registrar contratos
                                        </span>
                                    </div>

                                    <div class="form-field">
                                        <label for="estado">Estado</label>
                                        <select id="estado" name="estado" class="form-control">
                                            <option value="activo"
                                                ${empty metodoPago.estado or metodoPago.estado eq 'activo' ? 'selected' : ''}>
                                                Activo
                                            </option>
                                            <option value="inactivo"
                                                ${metodoPago.estado eq 'inactivo' ? 'selected' : ''}>
                                                Inactivo
                                            </option>
                                        </select>
                                    </div>
                                </div>

                                <div class="module-alert module-alert--info" style="margin-bottom:0;">
                                    <svg class="module-alert__icon" xmlns="http://www.w3.org/2000/svg"
                                         fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="m11.25 11.25.041-.02a.75.75 0 0 1 1.063.852l-.708
                                                 2.836a.75.75 0 0 0 1.063.853l.041-.021M21 12a9 9 0
                                                 1 1-18 0 9 9 0 0 1 18 0Zm-9-3.75h.008v.008H12V8.25Z"/>
                                    </svg>
                                    <div class="module-alert__body">
                                        <p class="module-alert__text">
                                            Solo los métodos <strong>activos</strong> aparecen
                                            disponibles al registrar contratos. Debe existir
                                            al menos uno activo en todo momento.
                                        </p>
                                    </div>
                                </div>
                            </div>

                            <div class="form-card__footer">
                                <button type="submit" class="btn btn-primary">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                    </svg>
                                    ${modoEdicion ? 'Guardar cambios' : 'Crear método'}
                                </button>
                                <a href="${pageContext.request.contextPath}/payment-methods"
                                   class="btn btn-ghost">Cancelar</a>
                            </div>
                        </div>
                    </form>

                </c:when>

                <%-- ══════════════════════════════════════
                     VISTA: LISTA DE MÉTODOS
                     ══════════════════════════════════════ --%>
                <c:otherwise>

                    <div class="module-header">
                        <div class="module-header__left">
                            <h1 class="module-header__title">
                                Métodos de Pago
                                <span class="stat-chip"><c:out value="${totalMetodos}"/></span>
                            </h1>
                            <div class="module-header__meta">
                                <span>Formas de cobro disponibles al registrar contratos</span>
                                <span class="module-header__meta-sep"></span>
                                <span class="stat-chip chip--green">
                                    <c:out value="${totalActivos}"/> activos
                                </span>
                            </div>
                        </div>
                        <div class="module-header__actions">
                            <a href="${pageContext.request.contextPath}/payment-methods?action=new"
                               class="btn btn-primary">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.2">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M12 4.5v15m7.5-7.5h-15"/>
                                </svg>
                                Nuevo método
                            </a>
                        </div>
                    </div>

                    <%-- KPI strip --%>
                    <div class="pm-kpi-strip">
                        <div class="pm-kpi">
                            <span class="pm-kpi__num"><c:out value="${totalMetodos}"/></span>
                            <span class="pm-kpi__label">Total métodos</span>
                        </div>
                        <div class="pm-kpi">
                            <span class="pm-kpi__num green"><c:out value="${totalActivos}"/></span>
                            <span class="pm-kpi__label">Disponibles</span>
                        </div>
                        <div class="pm-kpi">
                            <span class="pm-kpi__num dim"><c:out value="${totalInactivos}"/></span>
                            <span class="pm-kpi__label">Desactivados</span>
                        </div>
                    </div>

                    <%-- Aviso único activo --%>
                    <c:if test="${totalActivos eq 1}">
                        <div class="pm-only-active-banner" role="status">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                      d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73
                                         0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898
                                         0L2.697 16.126ZM12 15.75h.007v.008H12v-.008Z"/>
                            </svg>
                            <p>
                                Solo queda <strong>1 método activo</strong>.
                                No puedes desactivarlo hasta activar otro primero.
                            </p>
                        </div>
                    </c:if>

                    <%-- Grid de tarjetas --%>
                    <c:choose>
                        <c:when test="${not empty metodos}">
                            <div class="pm-grid">
                                <c:forEach var="mp" items="${metodos}">
                                    <%-- clase visual por ID --%>
                                    <c:set var="pmClass" value="pm--default"/>
                                    <c:if test="${fn:containsIgnoreCase(mp.id,'EFECTIVO')}"><c:set var="pmClass" value="pm--efectivo"/></c:if>
                                    <c:if test="${fn:containsIgnoreCase(mp.id,'VISA')}">    <c:set var="pmClass" value="pm--visa"/></c:if>
                                    <c:if test="${fn:containsIgnoreCase(mp.id,'MASTERCARD')}"><c:set var="pmClass" value="pm--mastercard"/></c:if>
                                    <c:if test="${fn:containsIgnoreCase(mp.id,'YAPE')}">    <c:set var="pmClass" value="pm--yape"/></c:if>
                                    <c:if test="${fn:containsIgnoreCase(mp.id,'PLIN')}">    <c:set var="pmClass" value="pm--plin"/></c:if>
                                    <c:if test="${fn:containsIgnoreCase(mp.id,'TRANSFER')}"><c:set var="pmClass" value="pm--transfer"/></c:if>

                                    <div class="pm-card ${pmClass} ${mp.activo ? 'is-active' : 'is-inactive'}">

                                        <div class="pm-card__icon-wrap">
                                            <div class="pm-card__icon">
                                                <c:choose>
                                                    <c:when test="${fn:containsIgnoreCase(mp.id,'EFECTIVO')}">
                                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.7">
                                                            <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 18.75a60.07 60.07 0 0 1 15.797 2.101c.727.198 1.453-.342 1.453-1.096V18.75M3.75 4.5v.75A.75.75 0 0 1 3 6h-.75m0 0v-.375c0-.621.504-1.125 1.125-1.125H20.25M2.25 6v9m18-10.5v.75c0 .414.336.75.75.75h.75m-1.5-1.5h.375c.621 0 1.125.504 1.125 1.125v9.75c0 .621-.504 1.125-1.125 1.125h-.375m1.5-1.5H21a.75.75 0 0 0-.75.75v.75m0 0H3.75m0 0h-.375a1.125 1.125 0 0 1-1.125-1.125V15m1.5 1.5v-.75A.75.75 0 0 0 3 15h-.75M15 10.5a3 3 0 1 1-6 0 3 3 0 0 1 6 0Zm3 0h.008v.008H18V10.5Zm-12 0h.008v.008H6V10.5Z"/>
                                                        </svg>
                                                    </c:when>
                                                    <c:when test="${fn:containsIgnoreCase(mp.id,'VISA') or fn:containsIgnoreCase(mp.id,'MASTERCARD')}">
                                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.7">
                                                            <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 8.25h19.5M2.25 9h19.5m-16.5 5.25h6m-6 2.25h3m-3.75 3h15a2.25 2.25 0 0 0 2.25-2.25V6.75A2.25 2.25 0 0 0 19.5 4.5h-15a2.25 2.25 0 0 0-2.25 2.25v10.5A2.25 2.25 0 0 0 4.5 19.5Z"/>
                                                        </svg>
                                                    </c:when>
                                                    <c:when test="${fn:containsIgnoreCase(mp.id,'YAPE') or fn:containsIgnoreCase(mp.id,'PLIN')}">
                                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.7">
                                                            <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 1.5H8.25A2.25 2.25 0 0 0 6 3.75v16.5a2.25 2.25 0 0 0 2.25 2.25h7.5A2.25 2.25 0 0 0 18 20.25V3.75a2.25 2.25 0 0 0-2.25-2.25H13.5m-3 0V3h3V1.5m-3 0h3m-3 18.75h3"/>
                                                        </svg>
                                                    </c:when>
                                                    <c:when test="${fn:containsIgnoreCase(mp.id,'TRANSFER')}">
                                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.7">
                                                            <path stroke-linecap="round" stroke-linejoin="round" d="M7.5 21 3 16.5m0 0L7.5 12M3 16.5h13.5m0-13.5L21 7.5m0 0L16.5 12M21 7.5H7.5"/>
                                                        </svg>
                                                    </c:when>
                                                    <c:otherwise>
                                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.7">
                                                            <path stroke-linecap="round" stroke-linejoin="round" d="M12 6v12m-3-2.818.879.659c1.171.879 3.07.879 4.242 0 1.172-.879 1.172-2.303 0-3.182C13.536 12.219 12.768 12 12 12c-.725 0-1.45-.22-2.003-.659-1.106-.879-1.106-2.303 0-3.182s2.9-.879 4.006 0l.415.33M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                                        </svg>
                                                    </c:otherwise>
                                                </c:choose>
                                            </div>
                                            <span class="pm-estado-dot ${mp.activo ? 'activo' : 'inactivo'}"
                                                  title="${mp.activo ? 'Activo' : 'Inactivo'}"></span>
                                        </div>

                                        <div class="pm-card__body">
                                            <p class="pm-card__nombre"><c:out value="${mp.nombre}"/></p>
                                            <span class="pm-card__id"><c:out value="${mp.id}"/></span>
                                            <p class="pm-card__status ${mp.activo ? 'activo' : 'inactivo'}">
                                                ${mp.activo ? 'Disponible para contratos' : 'No disponible'}
                                            </p>
                                        </div>

                                        <div class="pm-card__footer">
                                            <%-- Botón editar --%>
                                            <a href="${pageContext.request.contextPath}/payment-methods?action=edit&id=<c:out value='${mp.id}'/>"
                                               class="btn btn-secondary btn-sm" style="flex:1; justify-content:center;"
                                               title="Editar método">
                                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                    <path stroke-linecap="round" stroke-linejoin="round"
                                                          d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L10.582 16.07a4.5 4.5 0 0 1-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 0 1 1.13-1.897l8.932-8.931Z"/>
                                                </svg>
                                                Editar
                                            </a>

                                            <%-- Botón toggle --%>
                                            <c:choose>
                                                <c:when test="${mp.activo and totalActivos eq 1}">
                                                    <button type="button"
                                                            class="pm-toggle-btn pm-toggle-btn--disabled"
                                                            disabled title="Único método activo — protegido">
                                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                            <path stroke-linecap="round" stroke-linejoin="round" d="M16.5 10.5V6.75a4.5 4.5 0 1 0-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 0 0 2.25-2.25v-6.75a2.25 2.25 0 0 0-2.25-2.25H6.75a2.25 2.25 0 0 0-2.25 2.25v6.75a2.25 2.25 0 0 0 2.25 2.25Z"/>
                                                        </svg>
                                                    </button>
                                                </c:when>
                                                <c:when test="${mp.activo}">
                                                    <form action="${pageContext.request.contextPath}/payment-methods"
                                                          method="post"
                                                          onsubmit="return confirm('¿Desactivar «${mp.nombre}»?');"
                                                          style="flex:1;">
                                                        <input type="hidden" name="action" value="toggle">
                                                        <input type="hidden" name="id"     value="<c:out value='${mp.id}'/>">
                                                        <input type="hidden" name="_csrf"  value="${sessionScope._csrfToken}">
                                                        <button type="submit" class="pm-toggle-btn pm-toggle-btn--desactivar"
                                                                style="width:100%;">
                                                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12"/>
                                                            </svg>
                                                            Desactivar
                                                        </button>
                                                    </form>
                                                </c:when>
                                                <c:otherwise>
                                                    <form action="${pageContext.request.contextPath}/payment-methods"
                                                          method="post"
                                                          onsubmit="return confirm('¿Activar «${mp.nombre}»?');"
                                                          style="flex:1;">
                                                        <input type="hidden" name="action" value="toggle">
                                                        <input type="hidden" name="id"     value="<c:out value='${mp.id}'/>">
                                                        <input type="hidden" name="_csrf"  value="${sessionScope._csrfToken}">
                                                        <button type="submit" class="pm-toggle-btn pm-toggle-btn--activar"
                                                                style="width:100%;">
                                                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                                <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                                            </svg>
                                                            Activar
                                                        </button>
                                                    </form>
                                                </c:otherwise>
                                            </c:choose>
                                        </div>
                                    </div>
                                </c:forEach>
                            </div>

                            <div class="pm-info-footer">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="m11.25 11.25.041-.02a.75.75 0 0 1 1.063.852l-.708
                                             2.836a.75.75 0 0 0 1.063.853l.041-.021M21 12a9 9 0
                                             1 1-18 0 9 9 0 0 1 18 0Zm-9-3.75h.008v.008H12V8.25Z"/>
                                </svg>
                                <p>
                                    Solo los métodos <strong>activos</strong> están disponibles al registrar contratos.
                                    Desactivar un método no afecta los contratos ya existentes.
                                    Debe mantenerse <strong>al menos uno activo</strong> en todo momento.
                                </p>
                            </div>
                        </c:when>

                        <c:otherwise>
                            <div style="background:var(--clr-card);border:1px solid var(--clr-card-border);
                                        border-radius:var(--radius-lg);overflow:hidden;">
                                <div class="table-empty">
                                    <div class="table-empty__icon">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M2.25 8.25h19.5M2.25 9h19.5m-16.5 5.25h6m-6 2.25h3m-3.75
                                                     3h15a2.25 2.25 0 0 0 2.25-2.25V6.75A2.25 2.25 0 0 0
                                                     19.5 4.5h-15a2.25 2.25 0 0 0-2.25 2.25v10.5A2.25 2.25
                                                     0 0 0 4.5 19.5Z"/>
                                        </svg>
                                    </div>
                                    <p class="table-empty__title">Sin métodos de pago</p>
                                    <p class="table-empty__desc">
                                        Crea el primer método de pago del sistema.
                                    </p>
                                    <a href="${pageContext.request.contextPath}/payment-methods?action=new"
                                       class="btn btn-primary btn-sm" style="margin-top:0.5rem;">
                                        Crear primer método
                                    </a>
                                </div>
                            </div>
                        </c:otherwise>
                    </c:choose>

                </c:otherwise>
            </c:choose>
        </div>
    </div>
</div>
</body>
</html>