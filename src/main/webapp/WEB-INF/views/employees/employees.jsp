<%-- ============================================================
     employees.jsp  —  MaxFit Sistema de Gestión
     Módulo de gestión de empleados del sistema.

     Servlet:  EmployeesController.java  → GET/POST /employees
     Acceso:   Solo ROL-ADMIN (RoleFilter)

     ── Parámetros de URL que activan vistas ──────────────────
       /employees                  → lista de empleados (default)
       /employees?form=true        → formulario nuevo / edición
       /employees?detail=true      → perfil detallado del empleado

     ── Atributos de request ─────────────────────────────────

     Vista lista (default):
       empleados      (List<Empleado>)  → todos los empleados
       totalEmpleados (int)             → tamaño de la lista

     Vista formulario (?form=true):
       empleado       (Empleado)             → vacío (nuevo) o cargado (edición)
       tiposDocumento (List<TipoDocumento>)  → para el select
       cargos         (List<Cargo>)          → para el select
       modoEdicion    (Boolean)              → false=nuevo, true=editar

     Vista detalle (?detail=true):
       empleado       (Empleado)  → objeto completo con cargo y documento

     Flash (via transferirFlashMessages):
       successMsg / errorMsg

     Sesión:
       sessionScope.userRole → para condicionar acciones de admin
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
            <c:set var="pageTitle" value="${modoEdicion ? 'Editar Empleado' : 'Nuevo Empleado'}" scope="request"/>
        </c:when>
        <c:when test="${param.detail eq 'true'}">
            <c:set var="pageTitle" value="Perfil de Empleado" scope="request"/>
        </c:when>
        <c:otherwise>
            <c:set var="pageTitle" value="Empleados" scope="request"/>
        </c:otherwise>
    </c:choose>
    <link rel="stylesheet"
          href="${pageContext.request.contextPath}/static/css/modules.css">

    <style>
        /* ══════════════════════════════════════════════════════
           ESTILOS ESPECÍFICOS — MÓDULO DE EMPLEADOS
           ══════════════════════════════════════════════════════ */

        /* ── Badge de cargo ──────────────────────────────────── */
        .cargo-badge {
            display: inline-flex;
            align-items: center;
            gap: 0.3rem;
            padding: 0.22rem 0.7rem;
            border-radius: var(--radius-full);
            font-size: 0.68rem;
            font-weight: 700;
            letter-spacing: 0.06em;
            text-transform: uppercase;
            white-space: nowrap;
        }

        .cargo-badge::before {
            content: '';
            width: 5px; height: 5px;
            border-radius: 50%;
            background: currentColor;
            flex-shrink: 0;
        }

        /* Administrador */
        .cargo-badge--admin {
            background: var(--clr-red-subtle);
            color: var(--clr-red);
            border: 1px solid rgba(230,48,39,0.22);
        }

        /* Recepcionista */
        .cargo-badge--recep {
            background: var(--clr-info-subtle);
            color: var(--clr-info);
            border: 1px solid rgba(59,130,246,0.22);
        }

        /* Entrenador / Trainer */
        .cargo-badge--trainer {
            background: var(--clr-success-subtle);
            color: var(--clr-success);
            border: 1px solid rgba(34,197,94,0.22);
        }

        /* Genérico */
        .cargo-badge--default {
            background: rgba(255,255,255,0.05);
            color: var(--clr-text-muted);
            border: 1px solid var(--clr-border);
        }

        /* ── Stats strip de cabecera ──────────────────────────── */
        .emp-stats-strip {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 0;
            background: var(--clr-card);
            border: 1px solid var(--clr-card-border);
            border-radius: var(--radius-lg);
            overflow: hidden;
            margin-bottom: 1.5rem;
        }

        .emp-stat {
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: 0.9rem 0.75rem;
            gap: 0.2rem;
            border-right: 1px solid var(--clr-border-light);
            transition: background var(--transition);
        }

        .emp-stat:last-child { border-right: none; }
        .emp-stat:hover { background: rgba(255,255,255,0.02); }

        .emp-stat__num {
            font-family: var(--font-display);
            font-size: 1.55rem;
            font-weight: 800;
            line-height: 1;
            color: var(--clr-text);
        }

        .emp-stat__num.red    { color: var(--clr-red); }
        .emp-stat__num.green  { color: var(--clr-success); }
        .emp-stat__num.blue   { color: var(--clr-info); }

        .emp-stat__label {
            font-size: 0.67rem;
            font-weight: 600;
            letter-spacing: 0.08em;
            text-transform: uppercase;
            color: var(--clr-text-dim);
        }

        /* ── Vista de detalle: info card del cargo ────────────── */
        .emp-cargo-card {
            background: var(--clr-card);
            border: 1px solid var(--clr-card-border);
            border-radius: var(--radius-lg);
            overflow: hidden;
            margin-bottom: 1rem;
        }

        .emp-cargo-card__inner {
            padding: 1.1rem 1.25rem;
            display: flex;
            align-items: center;
            gap: 0.85rem;
        }

        .emp-cargo-card__icon {
            flex-shrink: 0;
            width: 44px; height: 44px;
            border-radius: var(--radius-md);
            display: flex; align-items: center; justify-content: center;
        }

        .emp-cargo-card__icon svg {
            width: 20px; height: 20px;
        }

        /* Variantes según cargo */
        .emp-cargo-card__icon.icon--admin {
            background: var(--clr-red-subtle);
            color: var(--clr-red);
        }
        .emp-cargo-card__icon.icon--recep {
            background: var(--clr-info-subtle);
            color: var(--clr-info);
        }
        .emp-cargo-card__icon.icon--trainer {
            background: var(--clr-success-subtle);
            color: var(--clr-success);
        }
        .emp-cargo-card__icon.icon--default {
            background: var(--clr-surface-2);
            color: var(--clr-text-dim);
        }

        .emp-cargo-card__info { flex: 1; min-width: 0; }

        .emp-cargo-card__nombre {
            font-family: var(--font-display);
            font-size: 1rem;
            font-weight: 700;
            letter-spacing: 0.04em;
            text-transform: uppercase;
            color: var(--clr-text);
            line-height: 1.2;
        }

        .emp-cargo-card__id {
            font-family: var(--font-mono);
            font-size: 0.68rem;
            color: var(--clr-text-dim);
            margin-top: 0.15rem;
        }

        /* ── Buscador del listado ─────────────────────────────── */
        .emp-toolbar {
            display: flex;
            align-items: center;
            gap: 0.75rem;
            margin-bottom: 1.25rem;
            flex-wrap: wrap;
        }

        /* ── Animaciones de entrada ───────────────────────────── */
        .att-checkin-card,
        .att-feed-card,
        .emp-cargo-card,
        .emp-stats-strip {
            animation: fadeSlideUp 0.4s cubic-bezier(0.4,0,0.2,1) both 0.06s;
        }

        /* ── Responsive ──────────────────────────────────────── */
        @media (max-width: 768px) {
            .emp-stats-strip {
                grid-template-columns: 1fr;
            }
            .emp-stat {
                border-right: none;
                border-bottom: 1px solid var(--clr-border-light);
            }
            .emp-stat:last-child { border-bottom: none; }
        }
    </style>
</head>
<body>

<div class="app-shell">
    <%@ include file="/WEB-INF/views/includes/sidebar.jsp" %>

    <div class="app-main">

        <%-- Títulos para el navbar --%>
        <c:choose>
            <c:when test="${param.form eq 'true'}">
                <c:set var="pageTitle"    value="${modoEdicion ? 'Editar Empleado' : 'Nuevo Empleado'}" scope="request"/>
                <c:set var="pageSubtitle" value="Módulo de Empleados" scope="request"/>
            </c:when>
            <c:when test="${param.detail eq 'true'}">
                <c:set var="pageTitle"    value="Perfil de Empleado"  scope="request"/>
                <c:set var="pageSubtitle" value="Módulo de Empleados" scope="request"/>
            </c:when>
            <c:otherwise>
                <c:set var="pageTitle"    value="Empleados"                 scope="request"/>
                <c:set var="pageSubtitle" value="Gestión del equipo de trabajo" scope="request"/>
            </c:otherwise>
        </c:choose>
        <%@ include file="/WEB-INF/views/includes/navbar.jsp" %>

        <div class="page-content">

            <%-- ═══════════════════════════════════════════════
                 BIFURCACIÓN PRINCIPAL DE VISTAS
                 ═══════════════════════════════════════════════ --%>
            <c:choose>

                <%-- ──────────────────────────────────────────
                     VISTA: FORMULARIO (nuevo o edición)
                     param.form=true
                     ────────────────────────────────────────── --%>
                <c:when test="${param.form eq 'true'}">

                    <%-- Breadcrumb --%>
                    <nav class="module-breadcrumb" aria-label="Breadcrumb">
                        <a href="${pageContext.request.contextPath}/employees">Empleados</a>
                        <svg class="module-breadcrumb__sep" xmlns="http://www.w3.org/2000/svg"
                             fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7"/>
                        </svg>
                        <span>${modoEdicion ? 'Editar' : 'Nuevo'}</span>
                    </nav>

                    <%-- Header --%>
                    <div class="module-header">
                        <div class="module-header__left">
                            <h1 class="module-header__title">
                                <c:choose>
                                    <c:when test="${modoEdicion}">Editar Empleado</c:when>
                                    <c:otherwise>Registrar Empleado</c:otherwise>
                                </c:choose>
                            </h1>
                            <div class="module-header__meta">
                                <span>Completa los datos del miembro del equipo</span>
                                <span class="module-header__meta-sep"></span>
                                <span>Los campos marcados con * son obligatorios</span>
                            </div>
                        </div>
                        <div class="module-header__actions">
                            <a href="${pageContext.request.contextPath}/employees"
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
                    <c:if test="${not empty formError}">
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
                                <p class="module-alert__text"><c:out value="${formError}"/></p>
                            </div>
                        </div>
                    </c:if>

                    <%-- ── FORMULARIO PRINCIPAL ─────────────── --%>
                    <form action="${pageContext.request.contextPath}/employees"
                          method="post"
                          novalidate
                          autocomplete="off">

                        <input type="hidden" name="action" value="save">
                        <input type="hidden" name="_csrf"  value="${sessionScope._csrfToken}">

                        <c:if test="${modoEdicion}">
                            <input type="hidden" name="id" value="<c:out value='${empleado.id}'/>">
                        </c:if>

                        <div class="form-card form-card--wide">

                            <%-- Header del card --%>
                            <div class="form-card__header">
                                <div class="form-card__header-icon">
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
                                                 1-4.5 0 2.25 2.25 0 0 1 4.5 0Zm-13.5 0a2.25 2.25 0
                                                 1 1-4.5 0 2.25 2.25 0 0 1 4.5 0Z"/>
                                    </svg>
                                </div>
                                <div>
                                    <p class="form-card__header-title">
                                        ${modoEdicion ? 'Datos del Empleado' : 'Nuevo Miembro del Equipo'}
                                    </p>
                                    <p class="form-card__header-sub">
                                        <c:if test="${modoEdicion}">
                                            ID: <c:out value="${empleado.id}"/>
                                        </c:if>
                                        <c:if test="${not modoEdicion}">
                                            El ID se genera automáticamente al guardar
                                        </c:if>
                                    </p>
                                </div>
                            </div>

                            <div class="form-card__body">

                                <%-- Sección 1: Datos personales --%>
                                <div class="form-section-divider">
                                    <span class="form-section-divider__label">Datos personales</span>
                                </div>

                                <div class="form-row">
                                    <%-- Nombre --%>
                                    <div class="form-field">
                                        <label for="nombre">
                                            Nombre <span class="required-star">*</span>
                                        </label>
                                        <input type="text"
                                               id="nombre"
                                               name="nombre"
                                               class="form-control"
                                               placeholder="Ej: Carlos"
                                               maxlength="100"
                                               required
                                               autocomplete="given-name"
                                               value="<c:out value='${empleado.nombre}'/>">
                                    </div>

                                    <%-- Apellido --%>
                                    <div class="form-field">
                                        <label for="apellido">
                                            Apellido <span class="required-star">*</span>
                                        </label>
                                        <input type="text"
                                               id="apellido"
                                               name="apellido"
                                               class="form-control"
                                               placeholder="Ej: Ramírez Torres"
                                               maxlength="100"
                                               required
                                               autocomplete="family-name"
                                               value="<c:out value='${empleado.apellido}'/>">
                                    </div>
                                </div>

                                <%-- Sección 2: Documento de identidad --%>
                                <div class="form-section-divider">
                                    <span class="form-section-divider__label">Documento de identidad</span>
                                </div>

                                <div class="form-row">
                                    <%-- Tipo de documento --%>
                                    <div class="form-field">
                                        <label for="idTipoDocumento">
                                            Tipo de documento <span class="required-star">*</span>
                                        </label>
                                        <select id="idTipoDocumento"
                                                name="idTipoDocumento"
                                                class="form-control"
                                                required>
                                            <option value="">— Seleccionar —</option>
                                            <c:forEach var="td" items="${tiposDocumento}">
                                                <option value="<c:out value='${td.id}'/>"
                                                    ${empleado.tipoDocumento != null
                                                       and empleado.tipoDocumento.id eq td.id
                                                       ? 'selected' : ''}>
                                                    <c:out value="${td.abreviado}"/> —
                                                    <c:out value="${td.nombreDocumento}"/>
                                                </option>
                                            </c:forEach>
                                        </select>
                                    </div>

                                    <%-- Número de documento --%>
                                    <div class="form-field">
                                        <label for="numeroDocumento">
                                            Número de documento <span class="required-star">*</span>
                                        </label>
                                        <input type="text"
                                               id="numeroDocumento"
                                               name="numeroDocumento"
                                               class="form-control"
                                               placeholder="Ej: 12345678"
                                               maxlength="20"
                                               required
                                               autocomplete="off"
                                               value="<c:out value='${empleado.numeroDocumento}'/>">
                                        <span class="form-field__hint">
                                            Revisa el tipo de documento para el formato correcto
                                        </span>
                                    </div>
                                </div>

                                <%-- Sección 3: Información de contacto --%>
                                <div class="form-section-divider">
                                    <span class="form-section-divider__label">Información de contacto</span>
                                </div>

                                <div class="form-row">
                                    <%-- Email (obligatorio para empleados) --%>
                                    <div class="form-field">
                                        <label for="email">
                                            Correo electrónico <span class="required-star">*</span>
                                        </label>
                                        <input type="email"
                                               id="email"
                                               name="email"
                                               class="form-control"
                                               placeholder="empleado@maxfit.com"
                                               maxlength="150"
                                               required
                                               autocomplete="email"
                                               value="<c:out value='${empleado.email}'/>">
                                        <span class="form-field__hint">
                                            Se usará para crear su cuenta de usuario en el sistema
                                        </span>
                                    </div>

                                    <%-- Teléfono (opcional) --%>
                                    <div class="form-field">
                                        <label for="telefono">Teléfono</label>
                                        <input type="tel"
                                               id="telefono"
                                               name="telefono"
                                               class="form-control"
                                               placeholder="Ej: 987654321"
                                               maxlength="20"
                                               autocomplete="tel"
                                               value="<c:out value='${empleado.telefono}'/>">
                                    </div>
                                </div>

                                <%-- Sección 4: Cargo --%>
                                <div class="form-section-divider">
                                    <span class="form-section-divider__label">Cargo y rol en el equipo</span>
                                </div>

                                <div class="form-row">
                                    <div class="form-field">
                                        <label for="idCargo">
                                            Cargo <span class="required-star">*</span>
                                        </label>
                                        <select id="idCargo"
                                                name="idCargo"
                                                class="form-control"
                                                required>
                                            <option value="">— Seleccionar cargo —</option>
                                            <c:forEach var="cargo" items="${cargos}">
                                                <option value="<c:out value='${cargo.id}'/>"
                                                    ${empleado.cargo != null
                                                       and empleado.cargo.id eq cargo.id
                                                       ? 'selected' : ''}>
                                                    <c:out value="${cargo.nombre}"/>
                                                </option>
                                            </c:forEach>
                                        </select>
                                        <span class="form-field__hint">
                                            El cargo determina el acceso disponible al crear la cuenta de usuario
                                        </span>
                                    </div>

                                    <%-- Espacio visual --%>
                                    <div></div>
                                </div>

                                <%-- Aviso informativo --%>
                                <div class="module-alert module-alert--info"
                                     style="margin-bottom:0;">
                                    <svg class="module-alert__icon" xmlns="http://www.w3.org/2000/svg"
                                         fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="m11.25 11.25.041-.02a.75.75 0 0 1 1.063.852l-.708
                                                 2.836a.75.75 0 0 0 1.063.853l.041-.021M21 12a9 9 0
                                                 1 1-18 0 9 9 0 0 1 18 0Zm-9-3.75h.008v.008H12V8.25Z"/>
                                    </svg>
                                    <div class="module-alert__body">
                                        <p class="module-alert__text">
                                            Después de registrar al empleado, ve a
                                            <a href="${pageContext.request.contextPath}/users"
                                               style="color:var(--clr-info); font-weight:600;">
                                                Usuarios
                                            </a>
                                            para crear sus credenciales de acceso al sistema.
                                        </p>
                                    </div>
                                </div>

                            </div><%-- /form-card__body --%>

                            <%-- Footer del formulario --%>
                            <div class="form-card__footer">
                                <button type="submit" class="btn btn-primary">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                    </svg>
                                    ${modoEdicion ? 'Guardar cambios' : 'Registrar empleado'}
                                </button>
                                <a href="${pageContext.request.contextPath}/employees"
                                   class="btn btn-ghost">
                                    Cancelar
                                </a>
                            </div>

                        </div><%-- /form-card --%>
                    </form>

                </c:when>

                <%-- ──────────────────────────────────────────
                     VISTA: DETALLE DEL EMPLEADO
                     param.detail=true
                     ────────────────────────────────────────── --%>
                <c:when test="${param.detail eq 'true'}">

                    <%-- Breadcrumb --%>
                    <nav class="module-breadcrumb" aria-label="Breadcrumb">
                        <a href="${pageContext.request.contextPath}/employees">Empleados</a>
                        <svg class="module-breadcrumb__sep" xmlns="http://www.w3.org/2000/svg"
                             fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7"/>
                        </svg>
                        <span><c:out value="${empleado.nombreCompleto}"/></span>
                    </nav>

                    <c:choose>
                        <c:when test="${not empty empleado}">

                            <%-- ── Hero del perfil ──────────────────── --%>
                            <div class="profile-hero">
                                <%-- Avatar con inicial --%>
                                <div class="profile-hero__avatar hero--red">
                                    <c:out value="${fn:substring(empleado.nombre, 0, 1)}"/>
                                </div>

                                <div class="profile-hero__info">
                                    <h1 class="profile-hero__name">
                                        <c:out value="${empleado.nombreCompleto}"/>
                                    </h1>
                                    <div class="profile-hero__sub">
                                        <c:if test="${not empty empleado.email}">
                                            <span><c:out value="${empleado.email}"/></span>
                                        </c:if>
                                        <c:if test="${not empty empleado.telefono}">
                                            <span class="profile-hero__sub-sep"></span>
                                            <span><c:out value="${empleado.telefono}"/></span>
                                        </c:if>
                                    </div>
                                    <div class="profile-hero__badges">
                                        <%-- Badge de cargo --%>
                                        <c:if test="${empleado.cargo != null}">
                                            <c:set var="cargoId" value="${empleado.cargo.id}"/>
                                            <c:choose>
                                                <c:when test="${fn:contains(cargoId, 'ADM')}">
                                                    <span class="cargo-badge cargo-badge--admin">
                                                        <c:out value="${empleado.cargo.nombre}"/>
                                                    </span>
                                                </c:when>
                                                <c:when test="${fn:contains(cargoId, 'REC')}">
                                                    <span class="cargo-badge cargo-badge--recep">
                                                        <c:out value="${empleado.cargo.nombre}"/>
                                                    </span>
                                                </c:when>
                                                <c:when test="${fn:contains(cargoId, 'TRAINER')}">
                                                    <span class="cargo-badge cargo-badge--trainer">
                                                        <c:out value="${empleado.cargo.nombre}"/>
                                                    </span>
                                                </c:when>
                                                <c:otherwise>
                                                    <span class="cargo-badge cargo-badge--default">
                                                        <c:out value="${empleado.cargo.nombre}"/>
                                                    </span>
                                                </c:otherwise>
                                            </c:choose>
                                        </c:if>
                                        <%-- ID del sistema --%>
                                        <span class="cell-id"><c:out value="${empleado.id}"/></span>
                                    </div>
                                </div>

                                <%-- Acciones del perfil --%>
                                <div class="profile-hero__actions">
                                    <a href="${pageContext.request.contextPath}/employees?action=edit&id=<c:out value='${empleado.id}'/>"
                                       class="btn btn-secondary btn-sm">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652
                                                     2.652L10.582 16.07a4.5 4.5 0 0 1-1.897 1.13L6
                                                     18l.8-2.685a4.5 4.5 0 0 1 1.13-1.897l8.932-8.931Zm0 0L19.5 7.125"/>
                                        </svg>
                                        Editar
                                    </a>
                                </div>
                            </div>

                            <%-- ── Layout: datos + aside ────────────── --%>
                            <div class="detail-layout">

                                <%-- Columna principal --%>
                                <div>

                                    <%-- Sección: Datos personales --%>
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
                                            <span class="detail-section__title">Información Personal</span>
                                        </div>
                                        <div class="detail-section__body">
                                            <div class="detail-list detail-list--horizontal">

                                                <div class="detail-item">
                                                    <span class="detail-item__label">Nombre completo</span>
                                                    <span class="detail-item__value" style="font-weight:600;">
                                                        <c:out value="${empleado.nombreCompleto}"/>
                                                    </span>
                                                </div>

                                                <div class="detail-item">
                                                    <span class="detail-item__label">Cargo</span>
                                                    <span class="detail-item__value">
                                                        <c:choose>
                                                            <c:when test="${empleado.cargo != null}">
                                                                <c:set var="cargoId" value="${empleado.cargo.id}"/>
                                                                <c:choose>
                                                                    <c:when test="${fn:contains(cargoId,'ADM')}">
                                                                        <span class="cargo-badge cargo-badge--admin">
                                                                            <c:out value="${empleado.cargo.nombre}"/>
                                                                        </span>
                                                                    </c:when>
                                                                    <c:when test="${fn:contains(cargoId,'REC')}">
                                                                        <span class="cargo-badge cargo-badge--recep">
                                                                            <c:out value="${empleado.cargo.nombre}"/>
                                                                        </span>
                                                                    </c:when>
                                                                    <c:when test="${fn:contains(cargoId,'TRAINER')}">
                                                                        <span class="cargo-badge cargo-badge--trainer">
                                                                            <c:out value="${empleado.cargo.nombre}"/>
                                                                        </span>
                                                                    </c:when>
                                                                    <c:otherwise>
                                                                        <span class="cargo-badge cargo-badge--default">
                                                                            <c:out value="${empleado.cargo.nombre}"/>
                                                                        </span>
                                                                    </c:otherwise>
                                                                </c:choose>
                                                            </c:when>
                                                            <c:otherwise>—</c:otherwise>
                                                        </c:choose>
                                                    </span>
                                                </div>

                                                <div class="detail-item">
                                                    <span class="detail-item__label">Correo electrónico</span>
                                                    <span class="detail-item__value">
                                                        <c:choose>
                                                            <c:when test="${not empty empleado.email}">
                                                                <c:out value="${empleado.email}"/>
                                                            </c:when>
                                                            <c:otherwise>—</c:otherwise>
                                                        </c:choose>
                                                    </span>
                                                </div>

                                                <div class="detail-item">
                                                    <span class="detail-item__label">Teléfono</span>
                                                    <span class="detail-item__value">
                                                        <c:choose>
                                                            <c:when test="${not empty empleado.telefono}">
                                                                <c:out value="${empleado.telefono}"/>
                                                            </c:when>
                                                            <c:otherwise>—</c:otherwise>
                                                        </c:choose>
                                                    </span>
                                                </div>

                                            </div>
                                        </div>
                                    </div>

                                    <%-- Sección: Documento de identidad --%>
                                    <div class="detail-section detail-section--full">
                                        <div class="detail-section__header">
                                            <div class="detail-section__icon">
                                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                    <path stroke-linecap="round" stroke-linejoin="round"
                                                          d="M15 9h3.75M15 12h3.75M15 15h3.75M4.5 7.5a3 3 0 0
                                                             1 3-3h9a3 3 0 0 1 3 3v9a3 3 0 0 1-3 3h-9a3 3 0 0
                                                             1-3-3v-9Zm6 0a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z"/>
                                                </svg>
                                            </div>
                                            <span class="detail-section__title">Documento de Identidad</span>
                                        </div>
                                        <div class="detail-section__body">
                                            <div class="detail-list detail-list--horizontal">

                                                <div class="detail-item">
                                                    <span class="detail-item__label">Tipo de documento</span>
                                                    <span class="detail-item__value">
                                                        <c:choose>
                                                            <c:when test="${empleado.tipoDocumento != null}">
                                                                <c:out value="${empleado.tipoDocumento.nombreDocumento}"/>
                                                                (<c:out value="${empleado.tipoDocumento.abreviado}"/>)
                                                            </c:when>
                                                            <c:otherwise>—</c:otherwise>
                                                        </c:choose>
                                                    </span>
                                                </div>

                                                <div class="detail-item">
                                                    <span class="detail-item__label">Número de documento</span>
                                                    <span class="detail-item__value mono"
                                                          style="font-size:0.92rem; font-weight:600;">
                                                        <c:out value="${empleado.numeroDocumento}"/>
                                                    </span>
                                                </div>

                                            </div>
                                        </div>
                                    </div>

                                </div><%-- /columna principal --%>

                                <%-- Aside derecho --%>
                                <aside class="detail-aside">

                                    <%-- Card de cargo --%>
                                    <div class="emp-cargo-card">
                                        <c:choose>
                                            <c:when test="${empleado.cargo != null}">
                                                <c:set var="cargoId" value="${empleado.cargo.id}"/>
                                                <c:set var="iconClass" value="icon--default"/>
                                                <c:if test="${fn:contains(cargoId,'ADM')}">
                                                    <c:set var="iconClass" value="icon--admin"/>
                                                </c:if>
                                                <c:if test="${fn:contains(cargoId,'REC')}">
                                                    <c:set var="iconClass" value="icon--recep"/>
                                                </c:if>
                                                <c:if test="${fn:contains(cargoId,'TRAINER')}">
                                                    <c:set var="iconClass" value="icon--trainer"/>
                                                </c:if>

                                                <div class="emp-cargo-card__inner">
                                                    <div class="emp-cargo-card__icon ${iconClass}">
                                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                                  d="M20.25 14.15v4.25c0 1.094-.787 2.036-1.872
                                                                     2.18-2.087.277-4.216.42-6.378.42s-4.291-.143-6.378-.42c-1.085-.144-1.872-1.086-1.872-2.18v-4.25m16.5
                                                                     0a2.18 2.18 0 0 0 .75-1.661V8.706c0-1.081-.768-2.015-1.837-2.175a48.114
                                                                     48.114 0 0 0-3.413-.387m4.5 8.006c-.194.165-.42.295-.673.38A23.978
                                                                     23.978 0 0 1 12 15.75c-2.648 0-5.195-.429-7.577-1.22a2.016 2.016
                                                                     0 0 1-.673-.38m0 0A2.18 2.18 0 0 1 3 12.489V8.706c0-1.081.768-2.015
                                                                     1.837-2.175a48.111 48.111 0 0 1 3.413-.387m7.5 0V5.25A2.25 2.25 0
                                                                     0 0 13.5 3h-3a2.25 2.25 0 0 0-2.25 2.25v.894m7.5 0a48.667 48.667
                                                                     0 0 0-7.5 0M12 12.75h.008v.008H12v-.008Z"/>
                                                        </svg>
                                                    </div>
                                                    <div class="emp-cargo-card__info">
                                                        <p class="emp-cargo-card__nombre">
                                                            <c:out value="${empleado.cargo.nombre}"/>
                                                        </p>
                                                        <p class="emp-cargo-card__id">
                                                            ID: <c:out value="${empleado.cargo.id}"/>
                                                        </p>
                                                    </div>
                                                </div>
                                            </c:when>
                                            <c:otherwise>
                                                <div class="emp-cargo-card__inner">
                                                    <p style="font-size:0.80rem; color:var(--clr-text-dim);">
                                                        Sin cargo asignado
                                                    </p>
                                                </div>
                                            </c:otherwise>
                                        </c:choose>
                                    </div>

                                    <%-- Card de resumen --%>
                                    <div class="aside-summary-card">
                                        <div class="aside-summary-card__header">Datos del registro</div>
                                        <div class="aside-summary-card__body">

                                            <div class="aside-data-row">
                                                <span class="aside-data-row__label">ID sistema</span>
                                                <span class="aside-data-row__value mono"
                                                      style="font-size:0.70rem;">
                                                    <c:out value="${empleado.id}"/>
                                                </span>
                                            </div>

                                            <div class="aside-data-row">
                                                <span class="aside-data-row__label">Documento</span>
                                                <span class="aside-data-row__value strong mono">
                                                    <c:if test="${empleado.tipoDocumento != null}">
                                                        <c:out value="${empleado.tipoDocumento.abreviado}"/>:
                                                    </c:if>
                                                    <c:out value="${empleado.numeroDocumento}"/>
                                                </span>
                                            </div>

                                            <div class="aside-data-row">
                                                <span class="aside-data-row__label">Email</span>
                                                <span class="aside-data-row__value"
                                                      style="font-size:0.75rem; word-break:break-all;">
                                                    <c:out value="${empleado.email}"/>
                                                </span>
                                            </div>

                                        </div>
                                    </div>

                                    <%-- Acciones rápidas --%>
                                    <div class="aside-summary-card">
                                        <div class="aside-summary-card__header">Acciones rápidas</div>
                                        <div class="aside-summary-card__body">

                                            <a href="${pageContext.request.contextPath}/employees?action=edit&id=<c:out value='${empleado.id}'/>"
                                               class="btn btn-secondary btn-sm"
                                               style="width:100%; justify-content:flex-start;">
                                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                    <path stroke-linecap="round" stroke-linejoin="round"
                                                          d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652
                                                             2.652L10.582 16.07a4.5 4.5 0 0 1-1.897 1.13L6
                                                             18l.8-2.685a4.5 4.5 0 0 1 1.13-1.897l8.932-8.931Zm0 0L19.5 7.125"/>
                                                </svg>
                                                Editar datos
                                            </a>

                                            <a href="${pageContext.request.contextPath}/users"
                                               class="btn btn-secondary btn-sm"
                                               style="width:100%; justify-content:flex-start; margin-top:0.4rem;">
                                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                    <path stroke-linecap="round" stroke-linejoin="round"
                                                          d="M15.75 5.25a3 3 0 0 1 3 3m3 0a6 6 0 0 1-7.029 5.912c-.563-.097-1.159.026-1.563.43L10.5
                                                             17.25H8.25v2.25H6v2.25H2.25v-2.818c0-.597.237-1.17.659-1.591l6.499-6.499c.404-.404.527-1
                                                             .43-1.563A6 6 0 0 1 21.75 8.25Z"/>
                                                </svg>
                                                Gestionar usuario
                                            </a>

                                            <div style="border-top:1px solid var(--clr-border-light);
                                                        padding-top:0.5rem; margin-top:0.4rem;">
                                                <form action="${pageContext.request.contextPath}/employees"
                                                      method="post"
                                                      onsubmit="return confirm('¿Eliminar a ${empleado.nombre} ${empleado.apellido}? Solo es posible si no tiene contratos o clases asignadas.');">
                                                    <input type="hidden" name="action" value="delete">
                                                    <input type="hidden" name="id"     value="<c:out value='${empleado.id}'/>">
                                                    <input type="hidden" name="_csrf"  value="${sessionScope._csrfToken}">
                                                    <button type="submit"
                                                            class="btn btn-danger btn-sm"
                                                            style="width:100%; justify-content:flex-start;">
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
                                                        Eliminar empleado
                                                    </button>
                                                </form>
                                            </div>

                                        </div>
                                    </div>

                                </aside><%-- /detail-aside --%>

                            </div><%-- /detail-layout --%>

                        </c:when>

                        <%-- Empleado no encontrado --%>
                        <c:otherwise>
                            <div class="module-table-wrapper">
                                <div class="table-empty" style="padding:4rem;">
                                    <div class="table-empty__icon">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M15.75 6a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5
                                                     0ZM4.501 20.118a7.5 7.5 0 0 1 14.998 0A17.933 17.933
                                                     0 0 1 12 21.75c-2.676 0-5.216-.584-7.499-1.632Z"/>
                                        </svg>
                                    </div>
                                    <p class="table-empty__title">Empleado no encontrado</p>
                                    <p class="table-empty__desc">
                                        El empleado que buscas no existe o fue eliminado.
                                    </p>
                                    <a href="${pageContext.request.contextPath}/employees"
                                       class="btn btn-secondary btn-sm" style="margin-top:0.5rem;">
                                        Volver a empleados
                                    </a>
                                </div>
                            </div>
                        </c:otherwise>
                    </c:choose>

                </c:when>

                <%-- ──────────────────────────────────────────
                     VISTA: LISTA DE EMPLEADOS (default)
                     ────────────────────────────────────────── --%>
                <c:otherwise>

                    <%-- Header del módulo --%>
                    <div class="module-header">
                        <div class="module-header__left">
                            <h1 class="module-header__title">
                                Empleados
                                <span class="stat-chip">
                                    <c:out value="${totalEmpleados}"/>
                                </span>
                            </h1>
                            <div class="module-header__meta">
                                <span>Equipo de trabajo registrado en el sistema</span>
                            </div>
                        </div>
                        <div class="module-header__actions">
                            <a href="${pageContext.request.contextPath}/users"
                               class="btn btn-secondary">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M15.75 5.25a3 3 0 0 1 3 3m3 0a6 6 0 0 1-7.029 5.912c-.563-.097-1.159.026-1.563.43L10.5
                                             17.25H8.25v2.25H6v2.25H2.25v-2.818c0-.597.237-1.17.659-1.591l6.499-6.499c.404-.404.527-1
                                             .43-1.563A6 6 0 0 1 21.75 8.25Z"/>
                                </svg>
                                Gestionar usuarios
                            </a>
                            <a href="${pageContext.request.contextPath}/employees?action=new"
                               class="btn btn-primary">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.2">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M12 4.5v15m7.5-7.5h-15"/>
                                </svg>
                                Nuevo empleado
                            </a>
                        </div>
                    </div>

                    <%-- Stats strip por cargo --%>
                    <c:if test="${not empty empleados}">
                        <%-- Contar por cargo --%>
                        <c:set var="cntAdmin"   value="0"/>
                        <c:set var="cntRecep"   value="0"/>
                        <c:set var="cntTrainer" value="0"/>
                        <c:forEach var="emp" items="${empleados}">
                            <c:if test="${emp.cargo != null}">
                                <c:if test="${fn:contains(emp.cargo.id,'ADM')}">
                                    <c:set var="cntAdmin" value="${cntAdmin + 1}"/>
                                </c:if>
                                <c:if test="${fn:contains(emp.cargo.id,'REC')}">
                                    <c:set var="cntRecep" value="${cntRecep + 1}"/>
                                </c:if>
                                <c:if test="${fn:contains(emp.cargo.id,'TRAINER')}">
                                    <c:set var="cntTrainer" value="${cntTrainer + 1}"/>
                                </c:if>
                            </c:if>
                        </c:forEach>

                        <div class="emp-stats-strip">
                            <div class="emp-stat">
                                <span class="emp-stat__num red"><c:out value="${cntAdmin}"/></span>
                                <span class="emp-stat__label">Administradores</span>
                            </div>
                            <div class="emp-stat">
                                <span class="emp-stat__num blue"><c:out value="${cntRecep}"/></span>
                                <span class="emp-stat__label">Recepcionistas</span>
                            </div>
                            <div class="emp-stat">
                                <span class="emp-stat__num green"><c:out value="${cntTrainer}"/></span>
                                <span class="emp-stat__label">Entrenadores</span>
                            </div>
                        </div>
                    </c:if>

                    <%-- Tabla de empleados --%>
                    <div class="module-table-wrapper">
                        <c:choose>
                            <c:when test="${not empty empleados}">
                                <table class="module-table" aria-label="Lista de empleados">
                                    <thead>
                                        <tr>
                                            <th scope="col">Empleado</th>
                                            <th scope="col">Cargo</th>
                                            <th scope="col">Documento</th>
                                            <th scope="col">Contacto</th>
                                            <th scope="col" aria-label="Acciones"></th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <c:forEach var="emp" items="${empleados}" varStatus="loop">
                                            <tr>
                                                <%-- Empleado con avatar --%>
                                                <td>
                                                    <div class="cell-name">
                                                        <c:set var="avColors"
                                                               value="av--red,av--green,av--blue,av--purple,av--teal"/>
                                                        <c:set var="avIdx" value="${loop.index mod 5}"/>
                                                        <div class="cell-name__avatar ${fn:split(avColors,',')[avIdx]}">
                                                            <c:out value="${fn:substring(emp.nombre, 0, 1)}"/>
                                                        </div>
                                                        <div class="cell-name__info">
                                                            <span class="cell-name__primary">
                                                                <c:out value="${emp.nombre} ${emp.apellido}"/>
                                                            </span>
                                                            <span class="cell-name__secondary">
                                                                <c:out value="${emp.id}"/>
                                                            </span>
                                                        </div>
                                                    </div>
                                                </td>

                                                <%-- Cargo --%>
                                                <td>
                                                    <c:choose>
                                                        <c:when test="${emp.cargo != null}">
                                                            <c:set var="cId" value="${emp.cargo.id}"/>
                                                            <c:choose>
                                                                <c:when test="${fn:contains(cId,'ADM')}">
                                                                    <span class="cargo-badge cargo-badge--admin">
                                                                        <c:out value="${emp.cargo.nombre}"/>
                                                                    </span>
                                                                </c:when>
                                                                <c:when test="${fn:contains(cId,'REC')}">
                                                                    <span class="cargo-badge cargo-badge--recep">
                                                                        <c:out value="${emp.cargo.nombre}"/>
                                                                    </span>
                                                                </c:when>
                                                                <c:when test="${fn:contains(cId,'TRAINER')}">
                                                                    <span class="cargo-badge cargo-badge--trainer">
                                                                        <c:out value="${emp.cargo.nombre}"/>
                                                                    </span>
                                                                </c:when>
                                                                <c:otherwise>
                                                                    <span class="cargo-badge cargo-badge--default">
                                                                        <c:out value="${emp.cargo.nombre}"/>
                                                                    </span>
                                                                </c:otherwise>
                                                            </c:choose>
                                                        </c:when>
                                                        <c:otherwise>
                                                            <span class="cell-date">—</span>
                                                        </c:otherwise>
                                                    </c:choose>
                                                </td>

                                                <%-- Documento --%>
                                                <td>
                                                    <div class="cell-data">
                                                        <span class="cell-data__main mono">
                                                            <c:out value="${emp.numeroDocumento}"/>
                                                        </span>
                                                        <span class="cell-data__sub">
                                                            <c:if test="${emp.tipoDocumento != null}">
                                                                <c:out value="${emp.tipoDocumento.abreviado}"/>
                                                            </c:if>
                                                        </span>
                                                    </div>
                                                </td>

                                                <%-- Contacto --%>
                                                <td>
                                                    <div class="cell-data">
                                                        <c:choose>
                                                            <c:when test="${not empty emp.email}">
                                                                <span class="cell-data__main">
                                                                    <c:out value="${emp.email}"/>
                                                                </span>
                                                            </c:when>
                                                            <c:otherwise>
                                                                <span class="cell-data__sub">Sin email</span>
                                                            </c:otherwise>
                                                        </c:choose>
                                                        <c:if test="${not empty emp.telefono}">
                                                            <span class="cell-data__sub">
                                                                <c:out value="${emp.telefono}"/>
                                                            </span>
                                                        </c:if>
                                                    </div>
                                                </td>

                                                <%-- Acciones --%>
                                                <td>
                                                    <div class="cell-actions">

                                                        <%-- Ver detalle --%>
                                                        <a href="${pageContext.request.contextPath}/employees?action=view&id=<c:out value='${emp.id}'/>"
                                                           class="btn btn-ghost btn-sm btn-icon"
                                                           title="Ver perfil de ${emp.nombre}">
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

                                                        <%-- Editar --%>
                                                        <a href="${pageContext.request.contextPath}/employees?action=edit&id=<c:out value='${emp.id}'/>"
                                                           class="btn btn-ghost btn-sm btn-icon"
                                                           title="Editar ${emp.nombre}">
                                                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                                <path stroke-linecap="round" stroke-linejoin="round"
                                                                      d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652
                                                                         2.652L10.582 16.07a4.5 4.5 0 0 1-1.897 1.13L6
                                                                         18l.8-2.685a4.5 4.5 0 0 1 1.13-1.897l8.932-8.931Zm0 0L19.5 7.125"/>
                                                            </svg>
                                                        </a>

                                                        <%-- Eliminar --%>
                                                        <form action="${pageContext.request.contextPath}/employees"
                                                              method="post"
                                                              style="display:inline;"
                                                              onsubmit="return confirm('¿Eliminar a ${emp.nombre} ${emp.apellido}? Esta acción no se puede deshacer.');">
                                                            <input type="hidden" name="action" value="delete">
                                                            <input type="hidden" name="id"     value="<c:out value='${emp.id}'/>">
                                                            <input type="hidden" name="_csrf"  value="${sessionScope._csrfToken}">
                                                            <button type="submit"
                                                                    class="btn btn-danger btn-sm btn-icon"
                                                                    title="Eliminar ${emp.nombre}">
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
                                        <strong style="color:var(--clr-text-muted);">
                                            <c:out value="${totalEmpleados}"/>
                                        </strong>
                                        empleado<c:if test="${totalEmpleados ne 1}">s</c:if> registrados
                                    </span>
                                    <a href="${pageContext.request.contextPath}/employees?action=new"
                                       class="btn btn-primary btn-sm">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.2">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M12 4.5v15m7.5-7.5h-15"/>
                                        </svg>
                                        Agregar empleado
                                    </a>
                                </div>

                            </c:when>

                            <%-- Estado vacío --%>
                            <c:otherwise>
                                <div class="table-empty">
                                    <div class="table-empty__icon">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M18 18.72a9.094 9.094 0 0 0 3.741-.479 3 3 0 0
                                                     0-4.682-2.72m.94 3.198.001.031c0 .225-.012.447-.037.666A11.944
                                                     11.944 0 0 1 12 21c-2.17 0-4.207-.576-5.963-1.584A6.062
                                                     6.062 0 0 1 6 18.719m12 0a5.971 5.971 0 0 0-.941-3.197m0
                                                     0A5.995 5.995 0 0 0 12 12.75a5.995 5.995 0 0
                                                     0-5.058 2.772m0 0a3 3 0 0 0-4.681 2.72 8.986 8.986 0
                                                     0 0 3.74.477m.94-3.197a5.971 5.971 0 0 0-.94 3.197M15
                                                     6.75a3 3 0 1 1-6 0 3 3 0 0 1 6 0Zm6 3a2.25 2.25 0 1
                                                     1-4.5 0 2.25 2.25 0 0 1 4.5 0Zm-13.5 0a2.25 2.25 0
                                                     1 1-4.5 0 2.25 2.25 0 0 1 4.5 0Z"/>
                                        </svg>
                                    </div>
                                    <p class="table-empty__title">No hay empleados registrados</p>
                                    <p class="table-empty__desc">
                                        Registra el primer miembro del equipo para comenzar
                                        a gestionar los accesos al sistema.
                                    </p>
                                    <a href="${pageContext.request.contextPath}/employees?action=new"
                                       class="btn btn-primary btn-sm" style="margin-top:0.5rem;">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.2">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M12 4.5v15m7.5-7.5h-15"/>
                                        </svg>
                                        Registrar primer empleado
                                    </a>
                                </div>
                            </c:otherwise>
                        </c:choose>
                    </div><%-- /module-table-wrapper --%>

                    <%-- Nota informativa al pie --%>
                    <c:if test="${not empty empleados}">
                        <div style="margin-top:1rem; padding:0.8rem 1rem;
                                    background:var(--clr-card);
                                    border:1px solid var(--clr-card-border);
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
                                Para dar acceso al sistema, ve a
                                <a href="${pageContext.request.contextPath}/users"
                                   style="color:var(--clr-red); font-weight:600;">
                                    Usuarios
                                </a>
                                y vincula el empleado con una cuenta. No se puede eliminar un empleado
                                que tiene contratos o clases asignadas.
                            </p>
                        </div>
                    </c:if>

                </c:otherwise>
            </c:choose>

        </div><%-- /page-content --%>
    </div><%-- /app-main --%>
</div><%-- /app-shell --%>

</body>
</html>
