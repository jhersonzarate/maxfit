<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"  uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <%@ include file="/WEB-INF/views/includes/head-common.jsp" %>
    <c:set var="pageTitle" value="Tipos de Clase" scope="request"/>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/modules.css">
    <style>
        .cat-kpi-strip {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            background: var(--clr-card);
            border: 1px solid var(--clr-card-border);
            border-radius: var(--radius-lg);
            overflow: hidden;
            margin-bottom: 1.5rem;
        }
        .cat-kpi {
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: 0.88rem 0.75rem;
            gap: 0.18rem;
            border-right: 1px solid var(--clr-border-light);
            transition: background var(--transition);
        }
        .cat-kpi:last-child { border-right: none; }
        .cat-kpi:hover { background: rgba(255,255,255,0.02); }
        .cat-kpi__num {
            font-family: var(--font-display);
            font-size: 1.55rem;
            font-weight: 800;
            line-height: 1;
            color: var(--clr-text);
        }
        .cat-kpi__num.green { color: var(--clr-success); }
        .cat-kpi__num.dim   { color: var(--clr-text-dim); }
        .cat-kpi__label {
            font-size: 0.65rem;
            font-weight: 700;
            letter-spacing: 0.09em;
            text-transform: uppercase;
            color: var(--clr-text-dim);
        }
        .cat-table-wrapper {
            background: var(--clr-card);
            border: 1px solid var(--clr-card-border);
            border-radius: var(--radius-lg);
            overflow: hidden;
            animation: fadeSlideUp 0.4s cubic-bezier(0.4,0,0.2,1) both 0.08s;
        }
        .cat-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 0.875rem;
        }
        .cat-table thead {
            background: var(--clr-surface);
            border-bottom: 1px solid var(--clr-border);
        }
        .cat-table thead th {
            padding: 0.72rem 1.1rem;
            text-align: left;
            font-size: 0.67rem;
            font-weight: 700;
            letter-spacing: 0.10em;
            text-transform: uppercase;
            color: var(--clr-text-muted);
            white-space: nowrap;
        }
        .cat-table thead th:first-child { padding-left: 1.35rem; }
        .cat-table thead th:last-child  { padding-right: 1.35rem; text-align: right; }
        .cat-table tbody tr {
            border-bottom: 1px solid var(--clr-border-light);
            transition: background var(--transition);
        }
        .cat-table tbody tr:last-child { border-bottom: none; }
        .cat-table tbody tr:hover      { background: rgba(255,255,255,0.025); }
        .cat-table tbody td {
            padding: 0.85rem 1.1rem;
            color: var(--clr-text);
            vertical-align: middle;
        }
        .cat-table tbody td:first-child { padding-left: 1.35rem; }
        .cat-table tbody td:last-child  { padding-right: 1.35rem; text-align: right; }
        .cat-form-panel {
            background: var(--clr-card);
            border: 1px solid var(--clr-card-border);
            border-radius: var(--radius-xl);
            overflow: hidden;
            max-width: 720px;
            animation: fadeSlideUp 0.42s cubic-bezier(0.4,0,0.2,1) both 0.05s;
        }
        .estado-pill {
            display: inline-flex;
            align-items: center;
            gap: 0.3rem;
            padding: 0.2rem 0.65rem;
            border-radius: var(--radius-full);
            font-size: 0.68rem;
            font-weight: 700;
            letter-spacing: 0.06em;
            text-transform: uppercase;
        }
        .estado-pill::before {
            content: '';
            width: 5px; height: 5px;
            border-radius: 50%;
            background: currentColor;
            flex-shrink: 0;
        }
        .estado-pill.activo {
            background: var(--clr-success-subtle);
            color: var(--clr-success);
            border: 1px solid rgba(34,197,94,0.22);
        }
        .estado-pill.inactivo {
            background: rgba(255,255,255,0.04);
            color: var(--clr-text-dim);
            border: 1px solid var(--clr-border);
        }
        .toggle-estado-form { display: inline; }
        @media (max-width: 768px) {
            .cat-kpi-strip { grid-template-columns: 1fr; }
            .cat-kpi { border-right: none; border-bottom: 1px solid var(--clr-border-light); }
            .cat-kpi:last-child { border-bottom: none; }
        }
    </style>
</head>
<body>
<div class="app-shell">
    <%@ include file="/WEB-INF/views/includes/sidebar.jsp" %>

    <div class="app-main">
        <c:set var="pageTitle"    value="Tipos de Clase"                    scope="request"/>
        <c:set var="pageSubtitle" value="Gestión de tipos de clase grupal"  scope="request"/>
        <%@ include file="/WEB-INF/views/includes/navbar.jsp" %>

        <div class="page-content">

            <div class="module-header">
                <div class="module-header__left">
                    <h1 class="module-header__title">Tipos de Clase</h1>
                    <div class="module-header__meta">
                        <span>Gestiona los tipos de clase grupal del gimnasio</span>
                    </div>
                </div>
            </div>

            <%-- KPI strip + Tabla: solo en modo lista --%>
            <c:if test="${!modoForm}">
                <c:set var="tcActivos"   value="0"/>
                <c:set var="tcInactivos" value="0"/>
                <c:forEach var="tc" items="${tiposClase}">
                    <c:if test="${tc.activo}">  <c:set var="tcActivos"   value="${tcActivos + 1}"/></c:if>
                    <c:if test="${!tc.activo}"> <c:set var="tcInactivos" value="${tcInactivos + 1}"/></c:if>
                </c:forEach>
                <div class="cat-kpi-strip">
                    <div class="cat-kpi">
                        <span class="cat-kpi__num">${fn:length(tiposClase)}</span>
                        <span class="cat-kpi__label">Total tipos</span>
                    </div>
                    <div class="cat-kpi">
                        <span class="cat-kpi__num green">${tcActivos}</span>
                        <span class="cat-kpi__label">Activos</span>
                    </div>
                    <div class="cat-kpi">
                        <span class="cat-kpi__num dim">${tcInactivos}</span>
                        <span class="cat-kpi__label">Inactivos</span>
                    </div>
                </div>
            </c:if>

            <%-- Formulario nuevo / edición --%>
            <c:if test="${modoForm}">
                <div class="cat-form-panel" style="margin-bottom:1.5rem;">
                    <div class="form-card__header">
                        <div class="form-card__header-icon">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                      d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z"/>
                            </svg>
                        </div>
                        <div>
                            <p class="form-card__header-title">
                                ${modoEdicion ? 'Editar Tipo de Clase' : 'Nuevo Tipo de Clase'}
                            </p>
                            <p class="form-card__header-sub">
                                <c:if test="${modoEdicion}">ID: <c:out value="${entidad.id}"/></c:if>
                                <c:if test="${!modoEdicion}">El ID se genera automáticamente del nombre</c:if>
                            </p>
                        </div>
                    </div>

                    <c:if test="${not empty errorMsg}">
                        <div class="module-alert module-alert--error" style="margin:1rem 1.5rem 0;">
                            <svg class="module-alert__icon" xmlns="http://www.w3.org/2000/svg"
                                 fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                      d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73
                                         0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898
                                         0L2.697 16.126ZM12 15.75h.007v.008H12v-.008Z"/>
                            </svg>
                            <div class="module-alert__body">
                                <p class="module-alert__text"><c:out value="${errorMsg}"/></p>
                            </div>
                        </div>
                    </c:if>

                    <form action="${pageContext.request.contextPath}/tipoclase"
                          method="post" novalidate autocomplete="off">
                        <input type="hidden" name="action" value="save">
                        <input type="hidden" name="_csrf"  value="${sessionScope._csrfToken}">
                        <c:if test="${modoEdicion}">
                            <input type="hidden" name="id" value="<c:out value='${entidad.id}'/>">
                        </c:if>

                        <div style="padding:1.35rem 1.5rem; display:flex; flex-direction:column; gap:1rem;">
                            <div class="form-section-divider">
                                <span class="form-section-divider__label">Datos del tipo de clase</span>
                            </div>
                            <div class="form-row">
                                <div class="form-field">
                                    <label for="nombreTipoClase">
                                        Nombre <span class="required-star">*</span>
                                    </label>
                                    <input type="text" id="nombreTipoClase" name="nombre"
                                           class="form-control"
                                           placeholder="Ej: Yoga, CrossFit, Spinning"
                                           maxlength="50" required
                                           value="<c:out value='${entidad.nombre}'/>">
                                    <span class="form-field__hint">Nombre descriptivo del tipo de clase</span>
                                </div>
                                <div class="form-field">
                                    <label for="estado-tc">Estado</label>
                                    <select id="estado-tc" name="estado" class="form-control">
                                        <option value="activo"
                                            ${empty entidad.estado or entidad.estado eq 'activo' ? 'selected' : ''}>
                                            Activo
                                        </option>
                                        <option value="inactivo"
                                            ${entidad.estado eq 'inactivo' ? 'selected' : ''}>
                                            Inactivo
                                        </option>
                                    </select>
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
                                ${modoEdicion ? 'Guardar cambios' : 'Crear tipo de clase'}
                            </button>
                            <a href="${pageContext.request.contextPath}/tipoclase"
                               class="btn btn-ghost">Cancelar</a>
                        </div>
                    </form>
                </div>
            </c:if>

            <%-- Tabla: solo en modo lista --%>
            <c:if test="${!modoForm}">
                <div class="cat-table-wrapper">
                    <div style="display:flex; align-items:center; justify-content:space-between;
                                padding:0.9rem 1.35rem; border-bottom:1px solid var(--clr-border);
                                background:var(--clr-surface);">
                        <span style="font-size:0.80rem; font-weight:700; letter-spacing:0.06em;
                                     text-transform:uppercase; color:var(--clr-text-muted);">
                            Tipos de Clase registrados
                        </span>
                        <a href="${pageContext.request.contextPath}/tipoclase?action=new"
                           class="btn btn-primary btn-sm">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.2">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15"/>
                            </svg>
                            Nuevo tipo
                        </a>
                    </div>

                    <c:choose>
                        <c:when test="${not empty tiposClase}">
                            <table class="cat-table" aria-label="Tipos de clase">
                                <thead>
                                    <tr>
                                        <th>ID</th>
                                        <th>Nombre</th>
                                        <th>Estado</th>
                                        <th aria-label="Acciones"></th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <c:forEach var="tc" items="${tiposClase}" varStatus="loop">
                                        <tr>
                                            <td><span class="cell-id"><c:out value="${tc.id}"/></span></td>
                                            <td>
                                                <div class="cell-name">
                                                    <c:set var="avColors" value="av--red,av--green,av--blue,av--purple,av--teal"/>
                                                    <c:set var="avIdx"    value="${loop.index mod 5}"/>
                                                    <div class="cell-name__avatar ${fn:split(avColors,',')[avIdx]}">
                                                        <c:out value="${fn:substring(tc.nombre,0,1)}"/>
                                                    </div>
                                                    <span style="font-weight:500; color:var(--clr-text); font-size:0.875rem;">
                                                        <c:out value="${tc.nombre}"/>
                                                    </span>
                                                </div>
                                            </td>
                                            <td>
                                                <span class="estado-pill ${tc.activo ? 'activo' : 'inactivo'}">
                                                    ${tc.activo ? 'Activo' : 'Inactivo'}
                                                </span>
                                            </td>
                                            <td>
                                                <div class="cell-actions">
                                                    <a href="${pageContext.request.contextPath}/tipoclase?action=edit&id=<c:out value='${tc.id}'/>"
                                                       class="btn btn-ghost btn-sm btn-icon" title="Editar">
                                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                                  d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L10.582 16.07a4.5 4.5 0 0 1-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 0 1 1.13-1.897l8.932-8.931Z"/>
                                                        </svg>
                                                    </a>
                                                    <form action="${pageContext.request.contextPath}/tipoclase"
                                                          method="post" class="toggle-estado-form">
                                                        <input type="hidden" name="action" value="toggle">
                                                        <input type="hidden" name="id"     value="<c:out value='${tc.id}'/>">
                                                        <input type="hidden" name="_csrf"  value="${sessionScope._csrfToken}">
                                                        <button type="submit"
                                                                class="btn ${tc.activo ? 'btn-danger' : 'btn-success'} btn-sm btn-icon"
                                                                title="${tc.activo ? 'Desactivar' : 'Activar'}">
                                                            <c:choose>
                                                                <c:when test="${tc.activo}">
                                                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                                        <path stroke-linecap="round" stroke-linejoin="round" d="M18.364 18.364A9 9 0 0 0 5.636 5.636m12.728 12.728A9 9 0 0 1 5.636 5.636m12.728 12.728L5.636 5.636"/>
                                                                    </svg>
                                                                </c:when>
                                                                <c:otherwise>
                                                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                                        <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                                                    </svg>
                                                                </c:otherwise>
                                                            </c:choose>
                                                        </button>
                                                    </form>
                                                </div>
                                            </td>
                                        </tr>
                                    </c:forEach>
                                </tbody>
                            </table>
                            <div style="padding:0.72rem 1.35rem; border-top:1px solid var(--clr-border-light);
                                        background:rgba(255,255,255,0.012);
                                        font-size:0.74rem; color:var(--clr-text-dim);">
                                <strong style="color:var(--clr-text-muted);">${fn:length(tiposClase)}</strong>
                                tipo(s) de clase registrados
                            </div>
                        </c:when>
                        <c:otherwise>
                            <div class="table-empty">
                                <div class="table-empty__icon">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z"/>
                                    </svg>
                                </div>
                                <p class="table-empty__title">Sin tipos de clase</p>
                                <p class="table-empty__desc">Crea el primer tipo de clase grupal.</p>
                                <a href="${pageContext.request.contextPath}/tipoclase?action=new"
                                   class="btn btn-primary btn-sm" style="margin-top:0.5rem;">
                                    Crear tipo de clase
                                </a>
                            </div>
                        </c:otherwise>
                    </c:choose>
                </div>
            </c:if>

        </div><%-- /page-content --%>
    </div><%-- /app-main --%>
</div><%-- /app-shell --%>
</body>
</html>