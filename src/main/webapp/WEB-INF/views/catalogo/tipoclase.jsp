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
        /* Modal Styles */
        .pm-modal-overlay {
            position: fixed; top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(0,0,0,0.7); backdrop-filter: blur(5px);
            display: flex; align-items: center; justify-content: center;
            z-index: 1000; opacity: 0; pointer-events: none;
            transition: opacity 0.3s ease;
        }
        .pm-modal-overlay.is-open { opacity: 1; pointer-events: auto; }
        .pm-modal {
            background: var(--clr-card); width: 100%; max-width: 480px;
            border-radius: var(--radius-xl); border: 1px solid var(--clr-card-border);
            box-shadow: 0 20px 40px rgba(0,0,0,0.5);
            transform: translateY(20px); transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        }
        .pm-modal-overlay.is-open .pm-modal { transform: translateY(0); }
        .pm-modal__header {
            padding: 1.25rem 1.5rem; border-bottom: 1px solid var(--clr-border);
            display: flex; align-items: center; justify-content: space-between;
            font-family: var(--font-display); font-weight: 700; font-size: 1.2rem;
        }
        .pm-modal__close {
            background: none; border: none; color: var(--clr-text-muted);
            cursor: pointer; padding: 0.5rem; border-radius: 50%;
            display: flex; align-items: center; justify-content: center;
            transition: background 0.2s, color 0.2s;
        }
        .pm-modal__close:hover { background: rgba(255,255,255,0.05); color: var(--clr-text); }
    </style>
</head>
<body>
<div class="app-shell">
    <%@ include file="/WEB-INF/views/includes/sidebar.jsp" %>

    <div class="app-main">
        <c:set var="pageTitle"    value="Tipos de Clase"                              scope="request"/>
        <c:set var="pageSubtitle" value="Gestión de tipos de clase grupal"      scope="request"/>
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

            <%-- KPI strip + Tabla --%>
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

            <div class="cat-table-wrapper">
                    <div style="display:flex; align-items:center; justify-content:space-between;
                                padding:0.9rem 1.35rem; border-bottom:1px solid var(--clr-border);
                                background:var(--clr-surface);">
                        <span style="font-size:0.80rem; font-weight:700; letter-spacing:0.06em;
                                     text-transform:uppercase; color:var(--clr-text-muted);">
                            Tipos de Clase registrados
                        </span>
                        <button type="button" onclick="openTipoClaseModal()"
                           class="btn btn-primary btn-sm">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.2">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15"/>
                            </svg>
                            Nuevo tipo de clase
                        </button>
                    </div>

                    <c:choose>
                        <c:when test="${not empty tiposClase}">
                            <table class="cat-table" aria-label="Tipos de clase del sistema">
                                <thead>
                                    <tr>
                                        <th>ID</th>
                                        <th>Nombre del tipo de clase</th>
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
                                                    <button type="button"
                                                       onclick="openTipoClaseModal({id: '<c:out value='${tc.id}'/>', nombre: '<c:out value='${fn:escapeXml(tc.nombre)}'/>', estado: '${tc.activo ? 'activo' : 'inactivo'}'})"
                                                       class="btn btn-ghost btn-sm btn-icon" title="Editar">
                                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                                  d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L10.582 16.07a4.5 4.5 0 0 1-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 0 1 1.13-1.897l8.932-8.931Z"/>
                                                        </svg>
                                                    </button>
                                                    <form action="${pageContext.request.contextPath}/tipoclase"
                                                          method="post" class="toggle-estado-form">
                                                        <input type="hidden" name="action" value="toggle">
                                                        <input type="hidden" name="id"     value="<c:out value='${tc.id}'/>">
                                                        <input type="hidden" name="_csrf"  value="${sessionScope._csrfToken}">
                                                        <button type="button"
                                                                onclick="openActionModal(event, '${tc.activo ? 'deactivate' : 'activate'}', '${fn:escapeXml(tc.nombre)}')"
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
                                                    <%-- Eliminar --%>
                                                    <form action="${pageContext.request.contextPath}/tipoclase"
                                                          method="post"
                                                          style="display:inline;">
                                                        <input type="hidden" name="action" value="delete">
                                                        <input type="hidden" name="id"     value="<c:out value='${tc.id}'/>">
                                                        <input type="hidden" name="_csrf"  value="${sessionScope._csrfToken}">
                                                        <button type="button"
                                                                onclick="openActionModal(event, 'delete', '${fn:escapeXml(tc.nombre)}')"
                                                                class="btn btn-danger btn-sm btn-icon"
                                                                title="Eliminar ${fn:escapeXml(tc.nombre)}">
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
                                              d="M20.25 14.15v4.25c0 1.094-.787 2.036-1.872 2.18-2.087.277-4.216.42-6.378.42s-4.291-.143-6.378-.42c-1.085-.144-1.872-1.086-1.872-2.18v-4.25m16.5
                                                 0a2.18 2.18 0 0 0 .75-1.661V8.706c0-1.081-.768-2.015-1.837-2.175a48.114 48.114 0 0 0-3.413-.387m4.5 8.006c-.194.165-.42.295-.673.38A23.978 23.978 0 0 1 12 15.75c-2.648 0-5.195-.429-7.577-1.22a2.016 2.016 0 0 1-.673-.38m0 0A2.18 2.18 0 0 1 3 12.489V8.706c0-1.081.768-2.015 1.837-2.175a48.111 48.111 0 0 1 3.413-.387m7.5 0V5.25A2.25 2.25 0 0 0 13.5 3h-3a2.25 2.25 0 0 0-2.25 2.25v.894m7.5 0a48.667 48.667 0 0 0-7.5 0M12 12.75h.008v.008H12v-.008Z"/>
                                    </svg>
                                </div>
                                <p class="table-empty__title">Sin tipos de clase registrados</p>
                                <p class="table-empty__desc">Crea el primer tipo de clase.</p>
                                <button type="button" onclick="openTipoClaseModal()"
                                   class="btn btn-primary btn-sm" style="margin-top:0.5rem;">
                                    Crear tipo de clase
                                </button>
                            </div>
                        </c:otherwise>
                    </c:choose>
                </div>

        </div><%-- /page-content --%>

        <%-- ── Modal de Formulario ────────────────────────────────── --%>
        <div id="tipoClaseModal" class="pm-modal-overlay">
            <div class="pm-modal">
                <div class="pm-modal__header">
                    <span id="tipoClaseModalTitle">Nuevo Tipo de Clase</span>
                    <button class="pm-modal__close" type="button" onclick="closeTipoClaseModal()">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                             stroke="currentColor" stroke-width="2" width="20" height="20">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
                        </svg>
                    </button>
                </div>
                
                <form action="${pageContext.request.contextPath}/tipoclase" method="post" autocomplete="off">
                    <input type="hidden" name="action" value="save">
                    <input type="hidden" name="id" id="tipoClaseModalId" value="">
                    <input type="hidden" name="_csrf" value="${sessionScope._csrfToken}">

                    <div style="padding: 1.5rem;">
                        
                        <div id="tipoClaseModalIdContainer" style="display:none; margin-bottom: 1.25rem;">
                            <label style="display:block; font-size: 0.75rem; font-weight:600; color:var(--clr-text-dim); margin-bottom: 0.3rem;">
                                ID del Tipo de Clase
                            </label>
                            <div id="tipoClaseModalIdDisplay" style="font-family:var(--font-mono); font-size:0.8rem; color:var(--clr-text-muted); background:var(--clr-surface); padding:0.6rem; border-radius:var(--radius-sm); border:1px solid var(--clr-border);">
                            </div>
                        </div>

                        <div style="margin-bottom: 1.25rem;">
                            <label for="tipoClaseModalNombre" style="display:block; font-size: 0.75rem; font-weight:600; color:var(--clr-text-dim); margin-bottom: 0.3rem;">
                                Nombre <span class="required-star">*</span>
                            </label>
                            <input type="text" id="tipoClaseModalNombre" name="nombre" class="form-control"
                                   placeholder="Ej: Yoga, CrossFit, Spinning"
                                   required maxlength="50"
                                   style="width: 100%; padding: 0.65rem 0.75rem; border-radius: var(--radius-md); border: 1px solid var(--clr-border); background: var(--clr-surface); color: var(--clr-text);">
                        </div>

                        <div style="margin-bottom: 1.75rem;">
                            <label for="tipoClaseModalEstado" style="display:block; font-size: 0.75rem; font-weight:600; color:var(--clr-text-dim); margin-bottom: 0.3rem;">
                                Estado
                            </label>
                            <select id="tipoClaseModalEstado" name="estado" class="form-control" style="width: 100%; padding: 0.65rem 0.75rem; border-radius: var(--radius-md); border: 1px solid var(--clr-border); background: var(--clr-surface); color: var(--clr-text);">
                                <option value="activo">Activo</option>
                                <option value="inactivo">Inactivo</option>
                            </select>
                        </div>
                    </div>

                    <div style="padding: 1rem 1.5rem; border-top: 1px solid var(--clr-border); display: flex; gap: 0.75rem; justify-content: flex-end; background: rgba(0,0,0,0.1);">
                        <button type="button" class="btn btn-secondary" onclick="closeTipoClaseModal()">Cancelar</button>
                        <button type="submit" class="btn btn-primary">Guardar</button>
                    </div>
                </form>
            </div>
        </div>

        <script>
            function openTipoClaseModal(tipoClase) {
                const modal = document.getElementById('tipoClaseModal');
                const title = document.getElementById('tipoClaseModalTitle');
                const idInput = document.getElementById('tipoClaseModalId');
                const idContainer = document.getElementById('tipoClaseModalIdContainer');
                const idDisplay = document.getElementById('tipoClaseModalIdDisplay');
                const nombreInput = document.getElementById('tipoClaseModalNombre');
                const estadoSelect = document.getElementById('tipoClaseModalEstado');

                if (tipoClase) {
                    title.textContent = 'Editar Tipo de Clase';
                    idInput.value = tipoClase.id;
                    idContainer.style.display = 'block';
                    idDisplay.textContent = tipoClase.id;
                    nombreInput.value = tipoClase.nombre;
                    estadoSelect.value = tipoClase.estado;
                } else {
                    title.textContent = 'Nuevo Tipo de Clase';
                    idInput.value = '';
                    idContainer.style.display = 'none';
                    idDisplay.textContent = '';
                    nombreInput.value = '';
                    estadoSelect.value = 'activo';
                }

                modal.classList.add('is-open');
                setTimeout(() => nombreInput.focus(), 100);
            }

            function closeTipoClaseModal() {
                document.getElementById('tipoClaseModal').classList.remove('is-open');
            }

            // --- Confirm Modal Actions ---
            let formToSubmit = null;

            function openActionModal(event, type, methodName) {
                event.preventDefault();
                formToSubmit = event.currentTarget.closest('form');

                const iconContainer = document.getElementById('actionModalIconContainer');
                const icon = document.getElementById('actionModalIcon');
                const text = document.getElementById('actionModalText');
                const btn = document.getElementById('btnConfirmAction');

                if (type === 'delete') {
                    iconContainer.style.borderColor = '#f87171'; // red
                    iconContainer.style.background = 'rgba(248,113,113,0.1)';
                    icon.style.color = '#f87171';
                    icon.textContent = '!';
                    text.innerHTML = `Se eliminará de forma permanente <br><strong><span style="color: var(--clr-text-muted);">` + methodName + `</span></strong><br><br><span style="font-size:0.8rem">Solo se permite si no está en uso por alguna clase.</span>`;
                    btn.className = 'btn btn-primary';
                    btn.textContent = 'Sí, eliminar!';
                } else if (type === 'deactivate') {
                    iconContainer.style.borderColor = '#fbbf24'; // warning yellow
                    iconContainer.style.background = 'rgba(251,191,36,0.1)';
                    icon.style.color = '#fbbf24';
                    icon.textContent = '!';
                    text.innerHTML = `Se desactivará el tipo de clase <br><strong><span style="color: var(--clr-text-muted);">` + methodName + `</span></strong>`;
                    btn.className = 'btn btn-primary';
                    btn.textContent = 'Sí, desactivar!';
                } else if (type === 'activate') {
                    iconContainer.style.borderColor = '#34d399'; // success green
                    iconContainer.style.background = 'rgba(52,211,153,0.1)';
                    icon.style.color = '#34d399';
                    icon.textContent = '?';
                    text.innerHTML = `Se activará el tipo de clase <br><strong><span style="color: var(--clr-text-muted);">` + methodName + `</span></strong>`;
                    btn.className = 'btn btn-primary';
                    btn.textContent = 'Sí, activar!';
                }

                document.getElementById('actionModal').classList.add('is-open');
            }

            function closeActionModal() {
                formToSubmit = null;
                document.getElementById('actionModal').classList.remove('is-open');
            }

            function confirmAction() {
                if (formToSubmit) {
                    formToSubmit.submit();
                }
            }
        </script>

        <%-- ── Modal de Confirmación de Acción ─────────────────────── --%>
        <div id="actionModal" class="pm-modal-overlay">
            <div class="pm-modal" style="max-width: 400px; text-align: center; padding: 2rem 1.5rem;">
                <div style="margin-bottom: 1.5rem;">
                    <div id="actionModalIconContainer" style="width: 80px; height: 80px; border-radius: 50%; border: 3px solid; display: flex; align-items: center; justify-content: center; margin: 0 auto;">
                        <span id="actionModalIcon" style="font-size: 3.5rem; line-height: 1; font-family: var(--font-display); padding-bottom: 0.5rem;"></span>
                    </div>
                </div>
                <h2 style="font-family: var(--font-display); font-size: 1.6rem; font-weight: 800; color: var(--clr-text); margin-bottom: 0.75rem;">
                    ¿Estás seguro?
                </h2>
                <p id="actionModalText" style="color: var(--clr-text-dim); font-size: 0.95rem; margin-bottom: 1.75rem; line-height: 1.5;">
                </p>
                <div style="display: flex; gap: 0.75rem; justify-content: center;">
                    <button type="button" class="btn" id="btnConfirmAction" onclick="confirmAction()" style="min-width: 120px; font-weight: bold;">
                    </button>
                    <button type="button" class="btn btn-secondary" onclick="closeActionModal()" style="min-width: 120px; font-weight: bold; background: #473f3f; border-color: #473f3f;">
                        Cancelar
                    </button>
                </div>
            </div>
        </div>

    </div><%-- /app-main --%>
</div><%-- /app-shell --%>
</body>
</html>