<%-- ============================================================
     clients.jsp  —  MaxFit Sistema de Gestión
     Módulo de gestión de clientes.

     Servlet:  ClientsController.java  →  GET/POST /clients
     Acceso:   ROL-ADMIN | ROL-RECEP  (RoleFilter)

     ── Parámetros de URL que activan vistas ──────────────────
       /clients               → lista de clientes (default)
       /clients?form=true     → formulario nuevo / edición
       /clients?action=view&id=... → redirige a client-detail.jsp

     ── Atributos de request ─────────────────────────────────

     Vista lista (default):
       clientes       (List<Cliente>)   → todos o filtrados
       query          (String, null)    → texto de búsqueda
       totalClientes  (int)             → tamaño de la lista

     Vista formulario (?form=true):
       cliente        (Cliente)         → obj vacío (nuevo) o cargado (edición)
       tiposDocumento (List<TipoDocumento>)
       modoEdicion    (Boolean)         → false=nuevo, true=editar

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
            <c:set var="pageTitle" value="${modoEdicion ? 'Editar Cliente' : 'Nuevo Cliente'}" scope="request"/>
        </c:when>
        <c:otherwise>
            <c:set var="pageTitle" value="Clientes" scope="request"/>
        </c:otherwise>
    </c:choose>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/modules.css">
</head>
<body>

<div class="app-shell">
    <%@ include file="/WEB-INF/views/includes/sidebar.jsp" %>

    <div class="app-main">

        <c:choose>
            <c:when test="${param.form eq 'true'}">
                <c:set var="pageTitle"    value="${modoEdicion ? 'Editar Cliente' : 'Nuevo Cliente'}" scope="request"/>
                <c:set var="pageSubtitle" value="Módulo de Clientes" scope="request"/>
            </c:when>
            <c:otherwise>
                <c:set var="pageTitle"    value="Clientes" scope="request"/>
                <c:set var="pageSubtitle" value="Gestión del padrón de socios" scope="request"/>
            </c:otherwise>
        </c:choose>
        <%@ include file="/WEB-INF/views/includes/navbar.jsp" %>

        <div class="page-content">

            <%-- ═══════════════════════════════════════════════
                 BIFURCACIÓN: lista  ↔  formulario
                 ═══════════════════════════════════════════════ --%>
            <c:choose>

                <%-- ─────────────────────────────────────────
                     VISTA: FORMULARIO (nuevo o edición)
                     ───────────────────────────────────────── --%>
                <c:when test="${param.form eq 'true'}">

                    <%-- Breadcrumb --%>
                    <nav class="module-breadcrumb" aria-label="Breadcrumb">
                        <a href="${pageContext.request.contextPath}/clients">Clientes</a>
                        <svg class="module-breadcrumb__sep" xmlns="http://www.w3.org/2000/svg"
                             fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7"/>
                        </svg>
                        <span>${modoEdicion ? 'Editar' : 'Nuevo'}</span>
                    </nav>

                    <%-- Header del formulario --%>
                    <div class="module-header">
                        <div class="module-header__left">
                            <h1 class="module-header__title">
                                <c:choose>
                                    <c:when test="${modoEdicion}">Editar Cliente</c:when>
                                    <c:otherwise>Registrar Cliente</c:otherwise>
                                </c:choose>
                            </h1>
                            <div class="module-header__meta">
                                <span>Completa los datos del socio</span>
                                <span class="module-header__meta-sep"></span>
                                <span>Los campos marcados con * son obligatorios</span>
                            </div>
                        </div>
                        <div class="module-header__actions">
                            <a href="${pageContext.request.contextPath}/clients"
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

                    <%-- Alerta de error del controlador --%>
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
                    <form action="${pageContext.request.contextPath}/clients"
                          method="post"
                          accept-charset="UTF-8"
                          novalidate
                          autocomplete="off">

                        <input type="hidden" name="action" value="save">
                        <input type="hidden" name="_csrf"  value="${sessionScope._csrfToken}">

                        <c:if test="${modoEdicion}">
                            <input type="hidden" name="id" value="<c:out value='${cliente.id}'/>">
                        </c:if>

                        <div class="form-card form-card--wide">

                            <%-- Header del card del form --%>
                            <div class="form-card__header">
                                <div class="form-card__header-icon">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M15.75 6a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5
                                                 0ZM4.501 20.118a7.5 7.5 0 0 1 14.998 0A17.933
                                                 17.933 0 0 1 12 21.75c-2.676 0-5.216-.584-7.499-1.632Z"/>
                                    </svg>
                                </div>
                                <div>
                                    <p class="form-card__header-title">
                                        ${modoEdicion ? 'Datos del Cliente' : 'Nuevo Socio'}
                                    </p>
                                    <p class="form-card__header-sub">
                                        <c:if test="${modoEdicion}">
                                            ID: <c:out value="${cliente.id}"/>
                                        </c:if>
                                        <c:if test="${not modoEdicion}">
                                            El ID se genera automáticamente al guardar
                                        </c:if>
                                    </p>
                                </div>
                            </div>

                            <div class="form-card__body">

                                <%-- Sección: Datos personales --%>
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
                                               value="<c:out value='${cliente.nombre}'/>">
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
                                               value="<c:out value='${cliente.apellido}'/>">
                                    </div>
                                </div>

                                <div class="form-row">
                                    <%-- Género --%>
                                    <div class="form-field">
                                        <label for="genero">Género</label>
                                        <select id="genero" name="genero" class="form-control">
                                            <option value="">— No especificado —</option>
                                            <option value="Masculino"  ${cliente.genero eq 'Masculino'  ? 'selected' : ''}>Masculino</option>
                                            <option value="Femenino"   ${cliente.genero eq 'Femenino'   ? 'selected' : ''}>Femenino</option>
                                            <option value="Otro"       ${cliente.genero eq 'Otro'       ? 'selected' : ''}>Otro</option>
                                        </select>
                                    </div>

                                                                                                            <%-- Fecha
                                                                                                                de
                                                                                                                nacimiento
                                                                                                                --%>
                                                                                                                <div
                                                                                                                    class="form-field">
                                                                                                                    <label
                                                                                                                        for="fechaNacimiento">Fecha
                                                                                                                        de
                                                                                                                        nacimiento <span class="required-star">*</span></label>
                                                                                                                    <input
                                                                                                                        type="date"
                                                                                                                        id="fechaNacimiento"
                                                                                                                        name="fechaNacimiento"
                                                                                                                        class="form-control"
                                                                                                                        required
                                                                                                                        max="<%= java.time.LocalDate.now().minusYears(18).toString() %>"
                                                                                                                        value="<c:out value='${cliente.fechaNacimiento}'/>">
                                                                                                                </div>
                                                                                                    </div>

                                                                                                    <%-- Sección:
                                                                                                        Documento de
                                                                                                        identidad --%>
                                                                                                        <div
                                                                                                            class="form-section-divider">
                                                                                                            <span
                                                                                                                class="form-section-divider__label">Documento
                                                                                                                de
                                                                                                                identidad</span>
                                                                                                        </div>

                                                                                                        <div
                                                                                                            class="form-row">
                                                                                                            <%-- Tipo de
                                                                                                                documento
                                                                                                                --%>
                                                                                                                <div
                                                                                                                    class="form-field">
                                                                                                                    <label
                                                                                                                        for="idTipoDocumento">
                                                                                                                        Tipo
                                                                                                                        de
                                                                                                                        documento
                                                                                                                        <span
                                                                                                                            class="required-star">*</span>
                                                                                                                    </label>
                                                                                                                    <select
                                                                                                                        id="idTipoDocumento"
                                                                                                                        name="idTipoDocumento"
                                                                                                                        class="form-control"
                                                                                                                        required>
                                                                                                                        <option
                                                                                                                            value="">
                                                                                                                            —
                                                                                                                            Seleccionar
                                                                                                                            —
                                                                                                                        </option>
                                                                                                                        <c:forEach
                                                                                                                            var="td"
                                                                                                                            items="${tiposDocumento}">
                                                                                                                            <option
                                                                                                                                value="<c:out value='${td.id}'/>"
                                                                                                                                ${cliente.tipoDocumento
                                                                                                                                !=null
                                                                                                                                and
                                                                                                                                cliente.tipoDocumento.id
                                                                                                                                eq
                                                                                                                                td.id
                                                                                                                                ? 'selected'
                                                                                                                                : ''
                                                                                                                                }>
                                                                                                                                <c:out
                                                                                                                                    value="${td.abreviado}" />
                                                                                                                                —
                                                                                                                                <c:out
                                                                                                                                    value="${td.nombreDocumento}" />
                                                                                                                            </option>
                                                                                                                        </c:forEach>
                                                                                                                    </select>
                                                                                                                </div>

                                                                                                                <%-- Número
                                                                                                                    de
                                                                                                                    documento
                                                                                                                    --%>
                                                                                                                    <div
                                                                                                                        class="form-field">
                                                                                                                        <label
                                                                                                                            for="numeroDocumento">
                                                                                                                            Número
                                                                                                                            de
                                                                                                                            documento
                                                                                                                            <span
                                                                                                                                class="required-star">*</span>
                                                                                                                        </label>
                                                                                                                        <input
                                                                                                                            type="text"
                                                                                                                            id="numeroDocumento"
                                                                                                                            name="numeroDocumento"
                                                                                                                            class="form-control"
                                                                                                                            placeholder="Ej: 12345678"
                                                                                                                            maxlength="20"
                                                                                                                            required
                                                                                                                            autocomplete="off"
                                                                                                                            value="<c:out value='${cliente.numeroDocumento}'/>">
                                                                                                                        <span
                                                                                                                            class="form-field__hint">
                                                                                                                            Revisa
                                                                                                                            el
                                                                                                                            tipo
                                                                                                                            de
                                                                                                                            documento
                                                                                                                            para
                                                                                                                            el
                                                                                                                            formato
                                                                                                                            correcto
                                                                                                                        </span>
                                                                                                                    </div>
                                                                                                        </div>

                                <%-- Sección: Contacto --%>
                                <div class="form-section-divider">
                                    <span class="form-section-divider__label">Información de contacto</span>
                                </div>

                                <div class="form-row">
                                    <%-- Email --%>
                                    <div class="form-field">
                                        <label for="email">Correo electrónico</label>
                                        <input type="email"
                                               id="email"
                                               name="email"
                                               class="form-control"
                                               placeholder="cliente@email.com"
                                               maxlength="150"
                                               autocomplete="email"
                                               value="<c:out value='${cliente.email}'/>">
                                    </div>

                                    <%-- Teléfono --%>
                                    <div class="form-field">
                                        <label for="telefono">Teléfono</label>
                                        <input type="tel"
                                               id="telefono"
                                               name="telefono"
                                               class="form-control"
                                               placeholder="Ej: 987654321"
                                               maxlength="20"
                                               autocomplete="tel"
                                               value="<c:out value='${cliente.telefono}'/>">
                                    </div>
                                </div>

                            </div><%-- /form-card__body --%>

                            <%-- Footer con acciones --%>
                            <div class="form-card__footer">
                                <button type="submit" class="btn btn-primary">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                    </svg>
                                    ${modoEdicion ? 'Guardar cambios' : 'Registrar cliente'}
                                </button>
                                <a href="${pageContext.request.contextPath}/clients"
                                   class="btn btn-ghost">
                                    Cancelar
                                </a>
                            </div>

                        </div><%-- /form-card --%>
                    </form>

                </c:when>

                <%-- ─────────────────────────────────────────
                     VISTA: LISTA DE CLIENTES (default)
                     ───────────────────────────────────────── --%>
                <c:otherwise>

                    <%-- Header del módulo --%>
                    <div class="module-header">
                        <div class="module-header__left">
                            <h1 class="module-header__title">
                                Clientes
                                <span class="stat-chip">
                                    <c:out value="${totalClientes}"/>
                                </span>
                            </h1>
                            <div class="module-header__meta">
                                <span>Padrón completo de socios registrados</span>
                                <c:if test="${not empty query}">
                                    <span class="module-header__meta-sep"></span>
                                    <span>Búsqueda: "<c:out value='${query}'/>"</span>
                                </c:if>
                            </div>
                        </div>
                        <div class="module-header__actions">
                            <a href="${pageContext.request.contextPath}/clients?action=new"
                               class="btn btn-primary">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.2">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M12 4.5v15m7.5-7.5h-15"/>
                                </svg>
                                Nuevo cliente
                            </a>
                        </div>
                    </div>

                    <%-- ── Barra de búsqueda y filtros ────── --%>
                    <form action="${pageContext.request.contextPath}/clients"
                          method="get"
                          class="toolbar">

                        <div class="toolbar-search">
                            <svg class="toolbar-search__icon"
                                 xmlns="http://www.w3.org/2000/svg" fill="none"
                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                      d="m21 21-5.197-5.197m0 0A7.5 7.5 0 1 0 5.196
                                         5.196a7.5 7.5 0 0 0 10.607 10.607Z"/>
                            </svg>
                            <input type="text"
                                   name="q"
                                   placeholder="Buscar por nombre, apellido o documento…"
                                   value="<c:out value='${query}'/>">
                            <button type="submit" class="toolbar-search__btn">Buscar</button>
                        </div>

                        <%-- Limpiar búsqueda --%>
                        <c:if test="${not empty query}">
                            <a href="${pageContext.request.contextPath}/clients"
                               class="btn btn-ghost btn-sm">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M6 18 18 6M6 6l12 12"/>
                                </svg>
                                Limpiar
                            </a>
                        </c:if>

                        <span class="toolbar-count">
                            <strong><c:out value="${totalClientes}"/></strong> clientes
                        </span>

                    </form>

                    <%-- ── Tabla de clientes ──────────────── --%>
                    <div class="module-table-wrapper">
                        <c:choose>
                            <c:when test="${not empty clientes}">
                                <table class="module-table" aria-label="Lista de clientes">
                                    <thead>
                                        <tr>
                                            <th scope="col">Cliente</th>
                                            <th scope="col">Documento</th>
                                            <th scope="col">Contacto</th>
                                            <th scope="col">Género</th>
                                            <th scope="col" aria-label="Acciones"></th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <c:forEach var="cli" items="${clientes}" varStatus="loop">
                                            <tr>
                                                <%-- Nombre con avatar --%>
                                                <td>
                                                    <div class="cell-name">
                                                        <%-- Color de avatar según posición --%>
                                                        <c:set var="avColors" value="av--red,av--green,av--blue,av--purple,av--teal"/>
                                                        <c:set var="avIdx" value="${loop.index mod 5}"/>
                                                        <div class="cell-name__avatar ${fn:split(avColors, ',')[avIdx]}">
                                                            <c:out value="${fn:substring(cli.nombre, 0, 1)}"/>
                                                        </div>
                                                        <div class="cell-name__info">
                                                            <span class="cell-name__primary">
                                                                <c:out value="${cli.nombre} ${cli.apellido}"/>
                                                            </span>
                                                            <span class="cell-name__secondary">
                                                                <c:out value="${cli.id}"/>
                                                            </span>
                                                        </div>
                                                    </div>
                                                </td>

                                                <%-- Documento --%>
                                                <td>
                                                    <div class="cell-data">
                                                        <span class="cell-data__main">
                                                            <c:out value="${cli.numeroDocumento}"/>
                                                        </span>
                                                        <span class="cell-data__sub">
                                                            <c:if test="${cli.tipoDocumento != null}">
                                                                <c:out value="${cli.tipoDocumento.abreviado}"/>
                                                            </c:if>
                                                        </span>
                                                    </div>
                                                </td>

                                                <%-- Contacto --%>
                                                <td>
                                                    <div class="cell-data">
                                                        <c:choose>
                                                            <c:when test="${not empty cli.email}">
                                                                <span class="cell-data__main">
                                                                    <c:out value="${cli.email}"/>
                                                                </span>
                                                            </c:when>
                                                            <c:otherwise>
                                                                <span class="cell-data__sub">Sin email</span>
                                                            </c:otherwise>
                                                        </c:choose>
                                                        <c:if test="${not empty cli.telefono}">
                                                            <span class="cell-data__sub">
                                                                <c:out value="${cli.telefono}"/>
                                                            </span>
                                                        </c:if>
                                                    </div>
                                                </td>

                                                <%-- Género --%>
                                                <td>
                                                    <c:choose>
                                                        <c:when test="${cli.genero eq 'Masculino'}">
                                                            <span class="badge-estado badge-estado--activo">M</span>
                                                        </c:when>
                                                        <c:when test="${cli.genero eq 'Femenino'}">
                                                            <span class="badge-estado badge-estado--pago-activo">F</span>
                                                        </c:when>
                                                        <c:when test="${not empty cli.genero}">
                                                            <span class="badge-estado badge-estado--pendiente">
                                                                <c:out value="${cli.genero}"/>
                                                            </span>
                                                        </c:when>
                                                        <c:otherwise>
                                                            <span class="cell-date" style="font-size:0.75rem">—</span>
                                                        </c:otherwise>
                                                    </c:choose>
                                                </td>

                                                <%-- Acciones --%>
                                                <td>
                                                    <div class="cell-actions">

                                                        <%-- Ver detalle --%>
                                                        <a href="${pageContext.request.contextPath}/clients?action=view&id=<c:out value='${cli.id}'/>"
                                                           class="btn btn-ghost btn-sm btn-icon"
                                                           title="Ver detalle de ${cli.nombre}">
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

                                                        <%-- Nuevo contrato --%>
                                                        <a href="${pageContext.request.contextPath}/contracts?action=new&clienteId=<c:out value='${cli.id}'/>"
                                                           class="btn btn-ghost btn-sm btn-icon"
                                                           title="Nuevo contrato para ${cli.nombre}">
                                                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                                <path stroke-linecap="round" stroke-linejoin="round"
                                                                      d="M19.5 14.25v-2.625a3.375 3.375 0 0
                                                                         0-3.375-3.375h-1.5A1.125 1.125 0 0 1
                                                                         13.5 7.125v-1.5a3.375 3.375 0 0
                                                                         0-3.375-3.375H8.25m3.75 9v6m3-3H9m1.5-12H5.625c-.621
                                                                         0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125
                                                                         1.125 1.125h12.75c.621 0 1.125-.504
                                                                         1.125-1.125V11.25a9 9 0 0 0-9-9Z"/>
                                                            </svg>
                                                        </a>

                                                        <%-- Editar (solo admin) --%>
                                                        <c:if test="${sessionScope.userRole eq 'ROL-ADMIN'}">
                                                            <a href="${pageContext.request.contextPath}/clients?action=edit&id=<c:out value='${cli.id}'/>"
                                                               class="btn btn-ghost btn-sm btn-icon"
                                                               title="Editar ${cli.nombre}">
                                                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                                    <path stroke-linecap="round" stroke-linejoin="round"
                                                                          d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652
                                                                             2.652L10.582 16.07a4.5 4.5 0 0 1-1.897
                                                                             1.13L6 18l.8-2.685a4.5 4.5 0 0 1
                                                                             1.13-1.897l8.932-8.931Zm0 0L19.5 7.125"/>
                                                                </svg>
                                                            </a>

                                                            <%-- Eliminar (con confirm form POST) --%>
                                                            <form action="${pageContext.request.contextPath}/clients"
                                                                  method="post"
                                                                  style="display:inline;"
                                                                  onsubmit="return confirm('¿Eliminar a ${cli.nombre} ${cli.apellido}? Esta acción no se puede deshacer.');">
                                                                <input type="hidden" name="action" value="delete">
                                                                <input type="hidden" name="id"     value="<c:out value='${cli.id}'/>">
                                                                <input type="hidden" name="_csrf"  value="${sessionScope._csrfToken}">
                                                                <button type="submit"
                                                                        class="btn btn-danger btn-sm btn-icon"
                                                                        title="Eliminar ${cli.nombre}">
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
                                            <c:out value="${totalClientes}"/>
                                        </strong>
                                        cliente<c:if test="${totalClientes ne 1}">s</c:if>
                                        <c:if test="${not empty query}">
                                            para "<c:out value='${query}'/>"
                                        </c:if>
                                    </span>
                                    <a href="${pageContext.request.contextPath}/clients?action=new"
                                       class="btn btn-primary btn-sm">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.2">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M12 4.5v15m7.5-7.5h-15"/>
                                        </svg>
                                        Agregar cliente
                                    </a>
                                </div>

                            </c:when>

                            <c:otherwise>
                                <div class="table-empty">
                                    <div class="table-empty__icon">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M15 19.128a9.38 9.38 0 0 0 2.625.372 9.337 9.337 0 0
                                                     0 4.121-.952 4.125 4.125 0 0 0-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15
                                                     19.128v.106A12.318 12.318 0 0 1 8.624 21c-2.331
                                                     0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0
                                                     1 11.964-3.07M12 6.375a3.375 3.375 0 1 1-6.75 0 3.375
                                                     3.375 0 0 1 6.75 0Zm8.25 2.25a2.625 2.625 0 1 1-5.25
                                                     0 2.625 2.625 0 0 1 5.25 0Z"/>
                                        </svg>
                                    </div>
                                    <c:choose>
                                        <c:when test="${not empty query}">
                                            <p class="table-empty__title">Sin resultados</p>
                                            <p class="table-empty__desc">
                                                No se encontraron clientes para
                                                "<strong><c:out value='${query}'/></strong>".
                                                Intenta con otro nombre o documento.
                                            </p>
                                            <a href="${pageContext.request.contextPath}/clients"
                                               class="btn btn-secondary btn-sm" style="margin-top:0.5rem;">
                                                Ver todos los clientes
                                            </a>
                                        </c:when>
                                        <c:otherwise>
                                            <p class="table-empty__title">No hay clientes registrados</p>
                                            <p class="table-empty__desc">
                                                Empieza registrando el primer socio del gimnasio.
                                            </p>
                                            <a href="${pageContext.request.contextPath}/clients?action=new"
                                               class="btn btn-primary btn-sm" style="margin-top:0.5rem;">
                                                Registrar primer cliente
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
