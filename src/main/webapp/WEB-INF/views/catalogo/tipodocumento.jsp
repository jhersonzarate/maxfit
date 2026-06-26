<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"  uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <%@ include file="/WEB-INF/views/includes/head-common.jsp" %>
    <c:set var="pageTitle" value="Tipos de Documento" scope="request"/>
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
        .alfa-badge {
            display: inline-flex;
            align-items: center;
            gap: 0.28rem;
            padding: 0.18rem 0.6rem;
            border-radius: var(--radius-full);
            font-size: 0.67rem;
            font-weight: 700;
            letter-spacing: 0.06em;
            text-transform: uppercase;
        }
        .alfa-badge.alfa {
            background: var(--clr-info-subtle);
            color: var(--clr-info);
            border: 1px solid rgba(59,130,246,0.2);
        }
        .alfa-badge.num {
            background: var(--clr-surface-2);
            color: var(--clr-text-muted);
            border: 1px solid var(--clr-border);
        }
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
        .size-badge {
            font-family: var(--font-mono);
            font-size: 0.78rem;
            font-weight: 600;
            color: var(--clr-text-muted);
            background: var(--clr-surface);
            padding: 0.18rem 0.5rem;
            border-radius: var(--radius-xs);
            border: 1px solid var(--clr-border-light);
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
        <c:set var="pageTitle"    value="Tipos de Documento"                  scope="request"/>
        <c:set var="pageSubtitle" value="Gestión de tipos de documento de identidad" scope="request"/>
        <%@ include file="/WEB-INF/views/includes/navbar.jsp" %>

        <div class="page-content">

            <div class="module-header">
                <div class="module-header__left">
                    <h1 class="module-header__title">Tipos de Documento</h1>
                    <div class="module-header__meta">
                        <span>Gestiona los tipos de documento de identidad del sistema</span>
                    </div>
                </div>
            </div>

            <%-- KPI strip + Tabla: solo en modo lista --%>
            <c:if test="${!modoForm}">
                <c:set var="tdActivos"   value="0"/>
                <c:set var="tdInactivos" value="0"/>
                <c:forEach var="td" items="${tiposDocumento}">
                    <c:if test="${td.activo}">  <c:set var="tdActivos"   value="${tdActivos + 1}"/></c:if>
                    <c:if test="${!td.activo}"> <c:set var="tdInactivos" value="${tdInactivos + 1}"/></c:if>
                </c:forEach>
                <div class="cat-kpi-strip">
                    <div class="cat-kpi">
                        <span class="cat-kpi__num">${fn:length(tiposDocumento)}</span>
                        <span class="cat-kpi__label">Total tipos</span>
                    </div>
                    <div class="cat-kpi">
                        <span class="cat-kpi__num green">${tdActivos}</span>
                        <span class="cat-kpi__label">Activos</span>
                    </div>
                    <div class="cat-kpi">
                        <span class="cat-kpi__num dim">${tdInactivos}</span>
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
                                      d="M15 9h3.75M15 12h3.75M15 15h3.75M4.5 7.5a3 3 0 0 1 3-3h9a3 3 0 0
                                         1 3 3v9a3 3 0 0 1-3 3h-9a3 3 0 0 1-3-3v-9ZM12 6.375a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z"/>
                            </svg>
                        </div>
                        <div>
                            <p class="form-card__header-title">
                                ${modoEdicion ? 'Editar Tipo de Documento' : 'Nuevo Tipo de Documento'}
                            </p>
                            <p class="form-card__header-sub">
                                <c:if test="${modoEdicion}">ID: <c:out value="${entidad.id}"/></c:if>
                                <c:if test="${!modoEdicion}">El ID se genera automáticamente del abreviado</c:if>
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

                    <form action="${pageContext.request.contextPath}/tipodocumento"
                          method="post" novalidate autocomplete="off">
                        <input type="hidden" name="action" value="save">
                        <input type="hidden" name="_csrf"  value="${sessionScope._csrfToken}">
                        <c:if test="${modoEdicion}">
                            <input type="hidden" name="id" value="<c:out value='${entidad.id}'/>">
                        </c:if>

                        <div style="padding:1.35rem 1.5rem; display:flex; flex-direction:column; gap:1rem;">
                            <div class="form-section-divider">
                                <span class="form-section-divider__label">Datos del tipo de documento</span>
                            </div>
                            <div class="form-row">
                                <div class="form-field">
                                    <label for="nombreDocumento">
                                        Nombre completo <span class="required-star">*</span>
                                    </label>
                                    <input type="text" id="nombreDocumento" name="nombreDocumento"
                                           class="form-control"
                                           placeholder="Ej: Documento Nacional de Identidad"
                                           maxlength="100" required
                                           value="<c:out value='${entidad.nombreDocumento}'/>">
                                </div>
                                <div class="form-field">
                                    <label for="abreviado">
                                        Abreviado <span class="required-star">*</span>
                                    </label>
                                    <input type="text" id="abreviado" name="abreviado"
                                           class="form-control"
                                           placeholder="Ej: DNI"
                                           maxlength="10" required
                                           style="text-transform:uppercase;"
                                           value="<c:out value='${entidad.abreviado}'/>">
                                    <span class="form-field__hint">
                                        Se usará como prefijo del ID (TDOC-ABREVIADO)
                                    </span>
                                </div>
                            </div>
                            <div class="form-row">
                                <div class="form-field">
                                    <label for="tamañoMin">
                                        Longitud mínima <span class="required-star">*</span>
                                    </label>
                                    <input type="number" id="tamañoMin" name="tamañoMin"
                                           class="form-control" placeholder="Ej: 8"
                                           min="1" max="50" required
                                           value="${entidad.tamañoMin > 0 ? entidad.tamañoMin : ''}">
                                </div>
                                <div class="form-field">
                                    <label for="tamañoMax">
                                        Longitud máxima <span class="required-star">*</span>
                                    </label>
                                    <input type="number" id="tamañoMax" name="tamañoMax"
                                           class="form-control" placeholder="Ej: 8"
                                           min="1" max="50" required
                                           value="${entidad.tamañoMax > 0 ? entidad.tamañoMax : ''}">
                                </div>
                            </div>
                            <div class="form-row">
                                <div class="form-field">
                                    <label for="estado-td">Estado</label>
                                    <select id="estado-td" name="estado" class="form-control">
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
                                <div class="form-field" style="justify-content:flex-end; padding-top:1.5rem;">
                                    <label style="display:flex; align-items:center; gap:0.65rem; cursor:pointer;">
                                        <input type="checkbox" name="esAlfanumerico" value="on"
                                               ${entidad.esAlfanumerico ? 'checked' : ''}
                                               style="width:16px;height:16px;accent-color:var(--clr-red);cursor:pointer;">
                                        <span style="font-size:0.83rem; font-weight:500; color:var(--clr-text);">
                                            Permite letras y números (alfanumérico)
                                        </span>
                                    </label>
                                    <span class="form-field__hint" style="margin-top:0.25rem;">
                                        Si está desmarcado, solo acepta dígitos numéricos
                                    </span>
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
                                ${modoEdicion ? 'Guardar cambios' : 'Crear tipo de documento'}
                            </button>
                            <a href="${pageContext.request.contextPath}/tipodocumento"
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
                            Tipos de Documento registrados
                        </span>
                        <a href="${pageContext.request.contextPath}/tipodocumento?action=new"
                           class="btn btn-primary btn-sm">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.2">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15"/>
                            </svg>
                            Nuevo tipo
                        </a>
                    </div>

                    <c:choose>
                        <c:when test="${not empty tiposDocumento}">
                            <table class="cat-table" aria-label="Tipos de documento">
                                <thead>
                                    <tr>
                                        <th>ID</th>
                                        <th>Nombre</th>
                                        <th>Abreviado</th>
                                        <th>Longitud</th>
                                        <th>Formato</th>
                                        <th>Estado</th>
                                        <th aria-label="Acciones"></th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <c:forEach var="td" items="${tiposDocumento}">
                                        <tr>
                                            <td><span class="cell-id"><c:out value="${td.id}"/></span></td>
                                            <td>
                                                <span style="font-weight:500; color:var(--clr-text); font-size:0.875rem;">
                                                    <c:out value="${td.nombreDocumento}"/>
                                                </span>
                                            </td>
                                            <td>
                                                <span style="font-family:var(--font-display); font-weight:700;
                                                             font-size:0.92rem; letter-spacing:0.05em; color:var(--clr-text);">
                                                    <c:out value="${td.abreviado}"/>
                                                </span>
                                            </td>
                                            <td>
                                                <span class="size-badge">
                                                    <c:choose>
                                                        <c:when test="${td.tamañoMin eq td.tamañoMax}">
                                                            <c:out value="${td.tamañoMin}"/> dígitos
                                                        </c:when>
                                                        <c:otherwise>
                                                            <c:out value="${td.tamañoMin}"/>–<c:out value="${td.tamañoMax}"/>
                                                        </c:otherwise>
                                                    </c:choose>
                                                </span>
                                            </td>
                                            <td>
                                                <c:choose>
                                                    <c:when test="${td.esAlfanumerico}">
                                                        <span class="alfa-badge alfa">Alfanumérico</span>
                                                    </c:when>
                                                    <c:otherwise>
                                                        <span class="alfa-badge num">Solo números</span>
                                                    </c:otherwise>
                                                </c:choose>
                                            </td>
                                            <td>
                                                <span class="estado-pill ${td.activo ? 'activo' : 'inactivo'}">
                                                    ${td.activo ? 'Activo' : 'Inactivo'}
                                                </span>
                                            </td>
                                            <td>
                                                <div class="cell-actions">
                                                    <a href="${pageContext.request.contextPath}/tipodocumento?action=edit&id=<c:out value='${td.id}'/>"
                                                       class="btn btn-ghost btn-sm btn-icon" title="Editar tipo de documento">
                                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                                  d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L10.582 16.07a4.5 4.5 0 0 1-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 0 1 1.13-1.897l8.932-8.931Z"/>
                                                        </svg>
                                                    </a>
                                                    <form action="${pageContext.request.contextPath}/tipodocumento"
                                                          method="post" class="toggle-estado-form">
                                                        <input type="hidden" name="action" value="toggle">
                                                        <input type="hidden" name="id"     value="<c:out value='${td.id}'/>">
                                                        <input type="hidden" name="_csrf"  value="${sessionScope._csrfToken}">
                                                        <button type="submit"
                                                                class="btn ${td.activo ? 'btn-danger' : 'btn-success'} btn-sm btn-icon"
                                                                title="${td.activo ? 'Desactivar' : 'Activar'}">
                                                            <c:choose>
                                                                <c:when test="${td.activo}">
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
                                <strong style="color:var(--clr-text-muted);">${fn:length(tiposDocumento)}</strong>
                                tipo(s) de documento registrados
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
                                                 0-3.375-3.375H8.25m2.25 0H5.625c-.621 0-1.125.504-1.125
                                                 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0
                                                 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z"/>
                                    </svg>
                                </div>
                                <p class="table-empty__title">Sin tipos de documento</p>
                                <p class="table-empty__desc">Crea el primer tipo de documento para el sistema.</p>
                                <a href="${pageContext.request.contextPath}/tipodocumento?action=new"
                                   class="btn btn-primary btn-sm" style="margin-top:0.5rem;">
                                    Crear tipo de documento
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