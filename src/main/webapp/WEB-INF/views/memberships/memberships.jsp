<%-- ============================================================
     memberships.jsp  —  MaxFit Sistema de Gestión
     Módulo de gestión de planes de membresía.

     Servlet:  MembershipsController.java  → GET/POST /memberships
     Acceso:   ROL-ADMIN | ROL-RECEP  (RoleFilter)
               Solo admin puede crear, editar y eliminar.

     ── Parámetros de URL que activan vistas ──────────────────
       /memberships               → lista de planes (default)
       /memberships?form=true     → formulario nuevo / edición

     ── Atributos de request ─────────────────────────────────

     Vista lista (default):
       membresias      (List<Membresia>)  → todos los planes
       totalMembresias (int)              → tamaño de la lista

     Vista formulario (?form=true):
       membresia    (Membresia)   → vacío (nuevo) o cargado (edición)
       modoEdicion  (Boolean)     → false=nuevo, true=editar

     Flash (ambas vistas, via transferirFlashMessages):
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
        <c:when test="${param.form eq 'true'}">
            <c:set var="pageTitle" value="${modoEdicion ? 'Editar Plan' : 'Nuevo Plan'}" scope="request"/>
        </c:when>
        <c:otherwise>
            <c:set var="pageTitle" value="Membresías" scope="request"/>
        </c:otherwise>
    </c:choose>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/modules.css">

    <%-- ── Estilos específicos del módulo de membresías ────── --%>
    <style>

        /* ── Grid de tarjetas de planes ─────────────────────── */
        .planes-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
            gap: 1.1rem;
        }

        /* ── Tarjeta individual de plan ──────────────────────── */
        .plan-card {
            background: var(--clr-card);
            border: 1px solid var(--clr-card-border);
            border-radius: var(--radius-xl);
            overflow: hidden;
            position: relative;
            transition: border-color var(--transition), transform var(--transition),
                        box-shadow var(--transition);
            display: flex;
            flex-direction: column;
        }

        .plan-card:hover {
            border-color: rgba(230,48,39,0.28);
            transform: translateY(-3px);
            box-shadow: 0 8px 32px rgba(0,0,0,0.4);
        }

        /* Franja de color superior --%>
        .plan-card__stripe {
            height: 3px;
            width: 100%;
            background: var(--stripe-color, var(--clr-red));
        }

        /* Paleta de colores para la franja según posición */
        .plan-card.stripe--red    { --stripe-color: var(--clr-red); }
        .plan-card.stripe--green  { --stripe-color: var(--clr-success); }
        .plan-card.stripe--blue   { --stripe-color: var(--clr-info); }
        .plan-card.stripe--purple { --stripe-color: #a78bfa; }
        .plan-card.stripe--teal   { --stripe-color: #2dd4bf; }
        .plan-card.stripe--orange { --stripe-color: #f97316; }

        /* Header de la tarjeta */
        .plan-card__header {
            padding: 1.25rem 1.35rem 0.75rem;
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 0.75rem;
        }

        .plan-card__nombre {
            font-family: var(--font-display);
            font-weight: 800;
            font-size: 1.15rem;
            letter-spacing: 0.04em;
            text-transform: uppercase;
            color: var(--clr-text);
            line-height: 1.2;
            flex: 1;
            min-width: 0;
        }

        .plan-card__id-badge {
            flex-shrink: 0;
            font-family: var(--font-mono);
            font-size: 0.62rem;
            color: var(--clr-text-dim);
            background: var(--clr-surface);
            padding: 0.18rem 0.5rem;
            border-radius: var(--radius-xs);
            border: 1px solid var(--clr-border-light);
        }

        /* Precio principal */
        .plan-card__precio-wrap {
            padding: 0.5rem 1.35rem 1rem;
            display: flex;
            align-items: baseline;
            gap: 0.35rem;
        }

        .plan-card__moneda {
            font-size: 1rem;
            font-weight: 600;
            color: var(--clr-text-muted);
            line-height: 1;
        }

        .plan-card__precio {
            font-family: var(--font-display);
            font-weight: 800;
            font-size: 2.2rem;
            line-height: 1;
            color: var(--clr-text);
            letter-spacing: 0.02em;
        }

        .plan-card__periodo {
            font-size: 0.78rem;
            color: var(--clr-text-dim);
            align-self: flex-end;
            padding-bottom: 0.2rem;
        }

        /* Separator */
        .plan-card__sep {
            height: 1px;
            background: var(--clr-border-light);
            margin: 0 1.35rem;
        }

        /* Detalles del plan */
        .plan-card__details {
            padding: 0.9rem 1.35rem;
            display: flex;
            flex-direction: column;
            gap: 0.55rem;
            flex: 1;
        }

        .plan-card__detail-row {
            display: flex;
            align-items: center;
            gap: 0.55rem;
            font-size: 0.82rem;
        }

        .plan-card__detail-icon {
            flex-shrink: 0;
            width: 16px; height: 16px;
            color: var(--stripe-color, var(--clr-red));
        }

        .plan-card__detail-label {
            color: var(--clr-text-muted);
        }

        .plan-card__detail-value {
            color: var(--clr-text);
            font-weight: 600;
            margin-left: auto;
        }

        /* Descripción */
        .plan-card__descripcion {
            padding: 0.65rem 1.35rem 0.85rem;
            font-size: 0.78rem;
            color: var(--clr-text-dim);
            line-height: 1.55;
            font-style: italic;
        }

        /* Footer con acciones */
        .plan-card__footer {
            padding: 0.75rem 1.35rem;
            border-top: 1px solid var(--clr-border-light);
            background: rgba(255,255,255,0.012);
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 0.5rem;
        }

        .plan-card__footer-left {
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        /* Chip de duración en el footer */
        .duracion-chip {
            display: inline-flex;
            align-items: center;
            gap: 0.35rem;
            padding: 0.22rem 0.65rem;
            border-radius: var(--radius-full);
            font-size: 0.68rem;
            font-weight: 700;
            letter-spacing: 0.06em;
            text-transform: uppercase;
            background: color-mix(in srgb, var(--stripe-color, var(--clr-red)) 12%, transparent);
            color: var(--stripe-color, var(--clr-red));
            border: 1px solid color-mix(in srgb, var(--stripe-color, var(--clr-red)) 28%, transparent);
        }

        /* ── Barra de resumen global de planes ───────────────── */
        .planes-summary-strip {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 0;
            background: var(--clr-card);
            border: 1px solid var(--clr-card-border);
            border-radius: var(--radius-lg);
            overflow: hidden;
            margin-bottom: 1.5rem;
        }

        .planes-summary-strip__item {
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: 0.9rem 0.75rem;
            gap: 0.2rem;
            border-right: 1px solid var(--clr-border-light);
            transition: background var(--transition);
        }

        .planes-summary-strip__item:last-child { border-right: none; }
        .planes-summary-strip__item:hover { background: rgba(255,255,255,0.02); }

        .planes-summary-strip__num {
            font-family: var(--font-display);
            font-size: 1.55rem;
            font-weight: 800;
            line-height: 1;
            color: var(--clr-text);
        }

        .planes-summary-strip__num.red   { color: var(--clr-red); }
        .planes-summary-strip__num.green { color: var(--clr-success); }

        .planes-summary-strip__label {
            font-size: 0.67rem;
            font-weight: 600;
            letter-spacing: 0.08em;
            text-transform: uppercase;
            color: var(--clr-text-dim);
        }

        /* ── Vista de tabla (toggle para admins) ─────────────── */
        .membresias-table-wrapper {
            display: none; /* Por defecto tarjetas, tabla opcional */
        }

        /* ── Formulario: preview de precio ───────────────────── */
        .precio-preview {
            background: var(--clr-surface);
            border: 1px solid var(--clr-border);
            border-radius: var(--radius-md);
            padding: 0.75rem 1rem;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 0.75rem;
            margin-top: 0.25rem;
        }

        .precio-preview__label {
            font-size: 0.75rem;
            color: var(--clr-text-muted);
        }

        .precio-preview__val {
            font-family: var(--font-display);
            font-size: 1.2rem;
            font-weight: 700;
            color: var(--clr-text);
        }

        /* ── Animación de entrada para tarjetas ──────────────── */
        .plan-card {
            animation: fadeSlideUp 0.42s cubic-bezier(0.4,0,0.2,1) both;
        }

        .plan-card:nth-child(1) { animation-delay: 0.04s; }
        .plan-card:nth-child(2) { animation-delay: 0.08s; }
        .plan-card:nth-child(3) { animation-delay: 0.12s; }
        .plan-card:nth-child(4) { animation-delay: 0.16s; }
        .plan-card:nth-child(5) { animation-delay: 0.20s; }
        .plan-card:nth-child(6) { animation-delay: 0.24s; }

        /* ── Responsive ──────────────────────────────────────── */
        @media (max-width: 768px) {
            .planes-grid {
                grid-template-columns: 1fr;
            }
            .planes-summary-strip {
                grid-template-columns: 1fr;
            }
            .planes-summary-strip__item {
                border-right: none;
                border-bottom: 1px solid var(--clr-border-light);
            }
            .planes-summary-strip__item:last-child {
                border-bottom: none;
            }
        }
    </style>
</head>
<body>

<div class="app-shell">
    <%@ include file="/WEB-INF/views/includes/sidebar.jsp" %>

    <div class="app-main">

        <c:choose>
            <c:when test="${param.form eq 'true'}">
                <c:set var="pageTitle"    value="${modoEdicion ? 'Editar Plan' : 'Nuevo Plan'}" scope="request"/>
                <c:set var="pageSubtitle" value="Módulo de Membresías" scope="request"/>
            </c:when>
            <c:otherwise>
                <c:set var="pageTitle"    value="Membresías"                       scope="request"/>
                <c:set var="pageSubtitle" value="Planes de acceso al gimnasio"     scope="request"/>
            </c:otherwise>
        </c:choose>
        <%@ include file="/WEB-INF/views/includes/navbar.jsp" %>

        <div class="page-content">

            <%-- ═══════════════════════════════════════════════
                 BIFURCACIÓN: lista  ↔  formulario
                 ═══════════════════════════════════════════════ --%>
            <c:choose>

                <%-- ──────────────────────────────────────────
                     VISTA: FORMULARIO (nuevo o edición)
                     param.form=true
                     ────────────────────────────────────────── --%>
                <c:when test="${param.form eq 'true'}">

                    <%-- Breadcrumb --%>
                    <nav class="module-breadcrumb" aria-label="Breadcrumb">
                        <a href="${pageContext.request.contextPath}/memberships">Membresías</a>
                        <svg class="module-breadcrumb__sep" xmlns="http://www.w3.org/2000/svg"
                             fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7"/>
                        </svg>
                        <span>${modoEdicion ? 'Editar plan' : 'Nuevo plan'}</span>
                    </nav>

                    <%-- Header --%>
                    <div class="module-header">
                        <div class="module-header__left">
                            <h1 class="module-header__title">
                                <c:choose>
                                    <c:when test="${modoEdicion}">Editar Plan</c:when>
                                    <c:otherwise>Nuevo Plan de Membresía</c:otherwise>
                                </c:choose>
                            </h1>
                            <div class="module-header__meta">
                                <span>Define el precio, duración y descripción del plan</span>
                                <span class="module-header__meta-sep"></span>
                                <span>Los campos marcados con * son obligatorios</span>
                            </div>
                        </div>
                        <div class="module-header__actions">
                            <a href="${pageContext.request.contextPath}/memberships"
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
                                <p class="module-alert__title">Error de validación</p>
                                <p class="module-alert__text"><c:out value="${errorMsg}"/></p>
                            </div>
                        </div>
                    </c:if>

                    <%-- Formulario --%>
                    <form action="${pageContext.request.contextPath}/memberships"
                          method="post"
                          novalidate
                          autocomplete="off">

                        <input type="hidden" name="action" value="save">
                        <input type="hidden" name="_csrf"  value="${sessionScope._csrfToken}">

                        <c:if test="${modoEdicion}">
                            <input type="hidden" name="id" value="<c:out value='${membresia.id}'/>">
                        </c:if>

                        <div class="form-card">

                            <div class="form-card__header">
                                <div class="form-card__header-icon">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M2.25 8.25h19.5M2.25 9h19.5m-16.5 5.25h6m-6
                                                 2.25h3m-3.75 3h15a2.25 2.25 0 0 0
                                                 2.25-2.25V6.75A2.25 2.25 0 0 0
                                                 19.5 4.5h-15a2.25 2.25 0 0 0-2.25
                                                 2.25v10.5A2.25 2.25 0 0 0 4.5 19.5Z"/>
                                    </svg>
                                </div>
                                <div>
                                    <p class="form-card__header-title">
                                        ${modoEdicion ? 'Datos del Plan' : 'Nuevo Plan'}
                                    </p>
                                    <p class="form-card__header-sub">
                                        <c:if test="${modoEdicion}">
                                            ID: <c:out value="${membresia.id}"/>
                                        </c:if>
                                        <c:if test="${not modoEdicion}">
                                            El ID se genera automáticamente al guardar
                                        </c:if>
                                    </p>
                                </div>
                            </div>

                            <div class="form-card__body">

                                <%-- Sección: Identificación del plan --%>
                                <div class="form-section-divider">
                                    <span class="form-section-divider__label">Identificación</span>
                                </div>

                                <div class="form-field">
                                    <label for="nombreMembresia">
                                        Nombre del plan <span class="required-star">*</span>
                                    </label>
                                    <input type="text"
                                           id="nombreMembresia"
                                           name="nombreMembresia"
                                           class="form-control"
                                           placeholder="Ej: Plan Mensual, Plan Anual Premium…"
                                           maxlength="100"
                                           required
                                           autocomplete="off"
                                           value="<c:out value='${membresia.nombreMembresia}'/>">
                                    <span class="form-field__hint">
                                        Nombre visible para clientes y en contratos
                                    </span>
                                </div>

                                <div class="form-field">
                                    <label for="descripcion">Descripción</label>
                                    <textarea id="descripcion"
                                              name="descripcion"
                                              class="form-control"
                                              placeholder="Describe los beneficios incluidos en este plan…"
                                              maxlength="200"
                                              rows="3"><c:out value='${membresia.descripcion}'/></textarea>
                                    <span class="form-field__hint">Opcional · máx. 200 caracteres</span>
                                </div>

                                <%-- Sección: Precio y duración --%>
                                <div class="form-section-divider">
                                    <span class="form-section-divider__label">Precio y duración</span>
                                </div>

                                <div class="form-row">

                                    <%-- Precio --%>
                                    <div class="form-field">
                                        <label for="precio">
                                            Precio (S/) <span class="required-star">*</span>
                                        </label>
                                        <div style="position:relative;">
                                            <span style="position:absolute; left:0.9rem; top:50%;
                                                         transform:translateY(-50%);
                                                         font-size:0.85rem; font-weight:600;
                                                         color:var(--clr-text-muted);
                                                         pointer-events:none;">
                                                S/
                                            </span>
                                            <input type="number"
                                                   id="precio"
                                                   name="precio"
                                                   class="form-control"
                                                   placeholder="0.00"
                                                   style="padding-left:2.2rem;"
                                                   min="0.01"
                                                   step="0.01"
                                                   required
                                                   autocomplete="off"
                                                   value="<c:out value='${membresia.precio}'/>">
                                        </div>
                                        <span class="form-field__hint">
                                            Usa punto decimal (ej: 120.00)
                                        </span>
                                    </div>

                                    <%-- Duración en meses --%>
                                    <div class="form-field">
                                        <label for="duracionMeses">
                                            Duración (meses) <span class="required-star">*</span>
                                        </label>
                                        <div style="position:relative;">
                                            <input type="number"
                                                   id="duracionMeses"
                                                   name="duracionMeses"
                                                   class="form-control"
                                                   placeholder="1"
                                                   style="padding-right:3.5rem;"
                                                   min="1"
                                                   max="120"
                                                   step="1"
                                                   required
                                                   autocomplete="off"
                                                   value="<c:out value='${membresia.duracionMeses}'/>">
                                            <span style="position:absolute; right:0.9rem; top:50%;
                                                         transform:translateY(-50%);
                                                         font-size:0.72rem; font-weight:600;
                                                         color:var(--clr-text-dim);
                                                         pointer-events:none;">
                                                mes(es)
                                            </span>
                                        </div>
                                        <span class="form-field__hint">
                                            Mínimo 1 mes. Determina la fecha de vencimiento del contrato
                                        </span>
                                    </div>

                                </div>

                                <%-- Info adicional para admin --%>
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
                                            <c:choose>
                                                <c:when test="${modoEdicion}">
                                                    Los cambios en el precio y duración solo afectan
                                                    a <strong>contratos nuevos</strong>.
                                                    Los contratos existentes no se modifican.
                                                </c:when>
                                                <c:otherwise>
                                                    El precio ingresado es referencial. Al crear un contrato,
                                                    el recepcionista puede registrar un monto diferente
                                                    (descuentos, promociones).
                                                </c:otherwise>
                                            </c:choose>
                                        </p>
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
                                    ${modoEdicion ? 'Guardar cambios' : 'Crear plan'}
                                </button>
                                <a href="${pageContext.request.contextPath}/memberships"
                                   class="btn btn-ghost">
                                    Cancelar
                                </a>
                            </div>

                        </div><%-- /form-card --%>
                    </form>

                </c:when>

                <%-- ──────────────────────────────────────────
                     VISTA: LISTA DE PLANES (default)
                     ────────────────────────────────────────── --%>
                <c:otherwise>

                    <%-- Header del módulo --%>
                    <div class="module-header">
                        <div class="module-header__left">
                            <h1 class="module-header__title">
                                Membresías
                                <span class="stat-chip">
                                    <c:out value="${totalMembresias}"/>
                                </span>
                            </h1>
                            <div class="module-header__meta">
                                <span>Planes disponibles para contratos</span>
                            </div>
                        </div>
                        <div class="module-header__actions">
                            <c:if test="${sessionScope.userRole eq 'ROL-ADMIN'}">
                                <a href="${pageContext.request.contextPath}/memberships?action=new"
                                   class="btn btn-primary">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.2">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M12 4.5v15m7.5-7.5h-15"/>
                                    </svg>
                                    Nuevo plan
                                </a>
                            </c:if>
                        </div>
                    </div>

                    <%-- Strip de resumen numérico --%>
                    <c:if test="${not empty membresias}">
                        <%-- Calculamos precio mín y máx con JSTL --%>
                        <c:set var="precioMin" value="${membresias[0].precio}"/>
                        <c:set var="precioMax" value="${membresias[0].precio}"/>
                        <c:set var="durMin"    value="${membresias[0].duracionMeses}"/>
                        <c:set var="durMax"    value="${membresias[0].duracionMeses}"/>
                        <c:forEach var="m" items="${membresias}">
                            <c:if test="${m.precio lt precioMin}"><c:set var="precioMin" value="${m.precio}"/></c:if>
                            <c:if test="${m.precio gt precioMax}"><c:set var="precioMax" value="${m.precio}"/></c:if>
                            <c:if test="${m.duracionMeses lt durMin}"><c:set var="durMin" value="${m.duracionMeses}"/></c:if>
                            <c:if test="${m.duracionMeses gt durMax}"><c:set var="durMax" value="${m.duracionMeses}"/></c:if>
                        </c:forEach>

                        <div class="planes-summary-strip">
                            <div class="planes-summary-strip__item">
                                <span class="planes-summary-strip__num red">
                                    <c:out value="${totalMembresias}"/>
                                </span>
                                <span class="planes-summary-strip__label">Planes activos</span>
                            </div>
                            <div class="planes-summary-strip__item">
                                <span class="planes-summary-strip__num green"
                                      style="font-size:1.2rem; padding-top:0.1rem;">
                                    S/ <fmt:formatNumber value="${precioMin}" pattern="#,##0.00"/>
                                    —
                                    S/ <fmt:formatNumber value="${precioMax}" pattern="#,##0.00"/>
                                </span>
                                <span class="planes-summary-strip__label">Rango de precios</span>
                            </div>
                            <div class="planes-summary-strip__item">
                                <span class="planes-summary-strip__num"
                                      style="font-size:1.2rem; padding-top:0.1rem;">
                                    <c:out value="${durMin}"/>
                                    <c:if test="${durMin ne durMax}"> — <c:out value="${durMax}"/></c:if>
                                    mes(es)
                                </span>
                                <span class="planes-summary-strip__label">Duración disponible</span>
                            </div>
                        </div>
                    </c:if>

                    <%-- Grid de tarjetas de planes --%>
                    <c:choose>
                        <c:when test="${not empty membresias}">

                            <c:set var="stripeColors" value="stripe--red,stripe--green,stripe--blue,stripe--purple,stripe--teal,stripe--orange"/>

                            <div class="planes-grid">
                                <c:forEach var="mem" items="${membresias}" varStatus="loop">

                                    <c:set var="stripeIdx"   value="${loop.index mod 6}"/>
                                    <c:set var="stripeClass" value="${fn:split(stripeColors, ',')[stripeIdx]}"/>

                                    <div class="plan-card <c:out value='${stripeClass}'/>">

                                        <%-- Franja superior de color --%>
                                        <div class="plan-card__stripe"></div>

                                        <%-- Header: nombre + ID --%>
                                        <div class="plan-card__header">
                                            <h2 class="plan-card__nombre">
                                                <c:out value="${mem.nombreMembresia}"/>
                                            </h2>
                                            <span class="plan-card__id-badge">
                                                <c:out value="${mem.id}"/>
                                            </span>
                                        </div>

                                        <%-- Precio grande --%>
                                        <div class="plan-card__precio-wrap">
                                            <span class="plan-card__moneda">S/</span>
                                            <span class="plan-card__precio">
                                                <fmt:formatNumber value="${mem.precio}" pattern="#,##0.00"/>
                                            </span>
                                            <span class="plan-card__periodo">
                                                / <c:out value="${mem.duracionMeses}"/> mes(es)
                                            </span>
                                        </div>

                                        <div class="plan-card__sep"></div>

                                        <%-- Detalles --%>
                                        <div class="plan-card__details">

                                            <div class="plan-card__detail-row">
                                                <svg class="plan-card__detail-icon"
                                                     xmlns="http://www.w3.org/2000/svg" fill="none"
                                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                                    <path stroke-linecap="round" stroke-linejoin="round"
                                                          d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0
                                                             1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18
                                                             0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21
                                                             18.75m-18 0v-7.5"/>
                                                </svg>
                                                <span class="plan-card__detail-label">Duración</span>
                                                <span class="plan-card__detail-value">
                                                    <c:out value="${mem.duracionMeses}"/>
                                                    <c:choose>
                                                        <c:when test="${mem.duracionMeses eq 1}"> mes</c:when>
                                                        <c:otherwise> meses</c:otherwise>
                                                    </c:choose>
                                                </span>
                                            </div>

                                            <div class="plan-card__detail-row">
                                                <svg class="plan-card__detail-icon"
                                                     xmlns="http://www.w3.org/2000/svg" fill="none"
                                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                                    <path stroke-linecap="round" stroke-linejoin="round"
                                                          d="M2.25 18.75a60.07 60.07 0 0 1 15.797 2.101c.727.198
                                                             1.453-.342 1.453-1.096V18.75M3.75 4.5v.75A.75.75 0 0
                                                             1 3 6h-.75m0 0v-.375c0-.621.504-1.125 1.125-1.125H20.25M2.25
                                                             6v9m18-10.5v.75c0 .414.336.75.75.75h.75m-1.5-1.5h.375c.621
                                                             0 1.125.504 1.125 1.125v9.75c0 .621-.504 1.125-1.125
                                                             1.125h-.375m1.5-1.5H21a.75.75 0 0 0-.75.75v.75m0
                                                             0H3.75m0 0h-.375a1.125 1.125 0 0 1-1.125-1.125V15m1.5
                                                             1.5v-.75A.75.75 0 0 0 3 15h-.75M15 10.5a3 3 0 1 1-6
                                                             0 3 3 0 0 1 6 0Zm3 0h.008v.008H18V10.5Zm-12
                                                             0h.008v.008H6V10.5Z"/>
                                                </svg>
                                                <span class="plan-card__detail-label">Precio</span>
                                                <span class="plan-card__detail-value"
                                                      style="color:var(--clr-success);">
                                                    S/ <fmt:formatNumber value="${mem.precio}" pattern="#,##0.00"/>
                                                </span>
                                            </div>

                                            <%-- Costo diario aproximado --%>
                                            <div class="plan-card__detail-row">
                                                <svg class="plan-card__detail-icon"
                                                     xmlns="http://www.w3.org/2000/svg" fill="none"
                                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                                    <path stroke-linecap="round" stroke-linejoin="round"
                                                          d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                                </svg>
                                                <span class="plan-card__detail-label">Costo aprox./día</span>
                                                <span class="plan-card__detail-value" style="font-size:0.78rem;">
                                                    <%-- precio / (duracion * 30) redondeado --%>
                                                    S/ <fmt:formatNumber
                                                           value="${mem.precio / (mem.duracionMeses * 30)}"
                                                           pattern="#,##0.00"/>
                                                </span>
                                            </div>

                                        </div>

                                        <%-- Descripción --%>
                                        <c:if test="${not empty mem.descripcion}">
                                            <p class="plan-card__descripcion">
                                                "<c:out value="${mem.descripcion}"/>"
                                            </p>
                                        </c:if>

                                        <%-- Footer: chips + acciones --%>
                                        <div class="plan-card__footer">
                                            <div class="plan-card__footer-left">
                                                <span class="duracion-chip">
                                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                         viewBox="0 0 24 24" stroke="currentColor"
                                                         stroke-width="2" style="width:10px;height:10px;">
                                                        <path stroke-linecap="round" stroke-linejoin="round"
                                                              d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                                    </svg>
                                                    <c:out value="${mem.duracionMeses}"/> mes(es)
                                                </span>
                                            </div>

                                            <%-- Acciones (solo admin puede editar/eliminar) --%>
                                            <div class="cell-actions" style="justify-content:flex-end;">

                                                <%-- Nuevo contrato con este plan --%>
                                                <a href="${pageContext.request.contextPath}/contracts?action=new"
                                                   class="btn btn-ghost btn-sm btn-icon"
                                                   title="Crear contrato con este plan">
                                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                        <path stroke-linecap="round" stroke-linejoin="round"
                                                              d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125
                                                                 1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0
                                                                 0-3.375-3.375H8.25m3.75 9v6m3-3H9m1.5-12H5.625c-.621
                                                                 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125
                                                                 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z"/>
                                                    </svg>
                                                </a>

                                                <c:if test="${sessionScope.userRole eq 'ROL-ADMIN'}">

                                                    <%-- Editar --%>
                                                    <a href="${pageContext.request.contextPath}/memberships?action=edit&id=<c:out value='${mem.id}'/>"
                                                       class="btn btn-ghost btn-sm btn-icon"
                                                       title="Editar plan ${mem.nombreMembresia}">
                                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                                  d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652
                                                                     2.652L10.582 16.07a4.5 4.5 0 0 1-1.897 1.13L6
                                                                     18l.8-2.685a4.5 4.5 0 0 1 1.13-1.897l8.932-8.931Zm0 0L19.5 7.125"/>
                                                        </svg>
                                                    </a>

                                                    <%-- Eliminar --%>
                                                    <form action="${pageContext.request.contextPath}/memberships"
                                                          method="post"
                                                          style="display:inline;"
                                                          onsubmit="return confirm('¿Eliminar el plan «${mem.nombreMembresia}»? Solo es posible si no tiene contratos asociados.');">
                                                        <input type="hidden" name="action" value="delete">
                                                        <input type="hidden" name="id"     value="<c:out value='${mem.id}'/>">
                                                        <input type="hidden" name="_csrf"  value="${sessionScope._csrfToken}">
                                                        <button type="submit"
                                                                class="btn btn-danger btn-sm btn-icon"
                                                                title="Eliminar plan ${mem.nombreMembresia}">
                                                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                                <path stroke-linecap="round" stroke-linejoin="round"
                                                                      d="m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107
                                                                         1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 0
                                                                         1-2.244 2.077H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772
                                                                         5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12
                                                                         .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0
                                                                         0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964
                                                                         51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09
                                                                         2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0"/>
                                                            </svg>
                                                        </button>
                                                    </form>

                                                </c:if>
                                            </div>
                                        </div>

                                    </div><%-- /plan-card --%>
                                </c:forEach>
                            </div><%-- /planes-grid --%>

                            <%-- Nota informativa al pie (solo admin) --%>
                            <c:if test="${sessionScope.userRole eq 'ROL-ADMIN'}">
                                <div style="margin-top:1.25rem; padding:0.85rem 1rem;
                                            background:var(--clr-card);
                                            border:1px solid var(--clr-card-border);
                                            border-radius:var(--radius-md);
                                            display:flex; align-items:center; gap:0.65rem;">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8"
                                         style="width:15px; height:15px; flex-shrink:0; color:var(--clr-text-dim);">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="m11.25 11.25.041-.02a.75.75 0 0 1 1.063.852l-.708 2.836a.75.75
                                                 0 0 0 1.063.853l.041-.021M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9-3.75h.008v.008H12V8.25Z"/>
                                    </svg>
                                    <p style="font-size:0.75rem; color:var(--clr-text-dim); line-height:1.5;">
                                        No se puede eliminar un plan que ya tiene contratos asociados.
                                        En ese caso, crea un plan nuevo con los precios actualizados.
                                    </p>
                                </div>
                            </c:if>

                        </c:when>

                        <%-- Estado vacío --%>
                        <c:otherwise>
                            <div style="background:var(--clr-card); border:1px solid var(--clr-card-border);
                                        border-radius:var(--radius-lg); overflow:hidden;">
                                <div class="table-empty">
                                    <div class="table-empty__icon">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M2.25 8.25h19.5M2.25 9h19.5m-16.5 5.25h6m-6
                                                     2.25h3m-3.75 3h15a2.25 2.25 0 0 0
                                                     2.25-2.25V6.75A2.25 2.25 0 0 0
                                                     19.5 4.5h-15a2.25 2.25 0 0 0-2.25
                                                     2.25v10.5A2.25 2.25 0 0 0 4.5 19.5Z"/>
                                        </svg>
                                    </div>
                                    <p class="table-empty__title">No hay planes de membresía</p>
                                    <p class="table-empty__desc">
                                        Crea el primer plan para comenzar a registrar contratos con clientes.
                                    </p>
                                    <c:if test="${sessionScope.userRole eq 'ROL-ADMIN'}">
                                        <a href="${pageContext.request.contextPath}/memberships?action=new"
                                           class="btn btn-primary btn-sm" style="margin-top:0.5rem;">
                                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.2">
                                                <path stroke-linecap="round" stroke-linejoin="round"
                                                      d="M12 4.5v15m7.5-7.5h-15"/>
                                            </svg>
                                            Crear primer plan
                                        </a>
                                    </c:if>
                                </div>
                            </div>
                        </c:otherwise>
                    </c:choose>

                </c:otherwise>
            </c:choose>

        </div><%-- /page-content --%>
    </div><%-- /app-main --%>
</div><%-- /app-shell --%>

</body>
</html>
