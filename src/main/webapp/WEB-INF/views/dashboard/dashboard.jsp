<%-- ============================================================
     dashboard.jsp  —  MaxFit Sistema de Gestión
     Dashboard principal del Recepcionista.

     Servlet:  DashboardController.java  → GET /dashboard
     Acceso:   Solo ROL-RECEP (RoleFilter)

     ── Atributos de request inyectados por el controlador ──────
     KPIs:
       atendidosHoy      (int)               → check-ins del día
       contratosActivos  (int)               → contratos activos
       countClasesHoy    (int)               → clases programadas hoy

     Widgets:
       asistenciasRecientes (List<Asistencia>) → últimas 10
       proximosVencer       (List<Contrato>)   → vencen en ≤ 7 días
       countProximosVencer  (int)
       clasesHoy            (List<Horario>)    → horarios de hoy
       fechaHoy             (String ISO)       → "2026-05-24"

     Flash:
       successMsg / errorMsg  → consumidos por transferirFlashMessages

     Sesión:
       sessionScope.userName   → nombre del empleado
       sessionScope.userRole   → ROL-RECEP
       sessionScope.userEmail  → email

     Resultado de check-in (post-redirect):
       sessionScope.checkInCliente   → nombre del cliente (si OK)
       sessionScope.checkInMembresia → membresía del cliente (si OK)
       sessionScope.checkInTipo      → tipo de error (si falló)
     ============================================================ --%>
<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="fn"  uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <%@ include file="/WEB-INF/views/includes/head-common.jsp" %>
    <c:set var="pageTitle" value="Dashboard" scope="request"/>
    <link rel="stylesheet"
          href="${pageContext.request.contextPath}/static/css/dashboard.css">
</head>
<body>

<%-- ══════════════════════════════════════════════════════════
     SHELL: Sidebar + Main
     ══════════════════════════════════════════════════════════ --%>
<div class="app-shell">

    <%-- Sidebar lateral --%>
    <%@ include file="/WEB-INF/views/includes/sidebar.jsp" %>

    <%-- Área principal --%>
    <div class="app-main">

        <%-- Navbar superior --%>
        <c:set var="pageTitle"    value="Dashboard" scope="request"/>
        <c:set var="pageSubtitle" value="Panel de recepción" scope="request"/>
        <%@ include file="/WEB-INF/views/includes/navbar.jsp" %>

        <%-- ── Contenido del módulo ─────────────────────────── --%>
        <div class="page-content">

            <%-- ══════════════════════════════════════════════════
                 BIENVENIDA DEL RECEPCIONISTA
                 ══════════════════════════════════════════════════ --%>
            <div class="recep-greeting">
                <div class="recep-greeting__left">
                    <span class="recep-greeting__rol">
                        <span class="turno-badge">Turno activo</span>
                    </span>
                    <h1 class="recep-greeting__nombre" style="margin-top:0.5rem;">
                        Hola,
                        <span><c:out value="${fn:split(sessionScope.userName, ' ')[0]}"/></span>
                    </h1>
                    <p class="recep-greeting__fecha">
                        <c:choose>
                            <c:when test="${not empty fechaHoy}">
                                <c:set var="pf" value="${fn:split(fechaHoy, '-')}"/>
                                Hoy,
                                <c:choose>
                                    <c:when test="${pf[1] eq '01'}">enero</c:when>
                                    <c:when test="${pf[1] eq '02'}">febrero</c:when>
                                    <c:when test="${pf[1] eq '03'}">marzo</c:when>
                                    <c:when test="${pf[1] eq '04'}">abril</c:when>
                                    <c:when test="${pf[1] eq '05'}">mayo</c:when>
                                    <c:when test="${pf[1] eq '06'}">junio</c:when>
                                    <c:when test="${pf[1] eq '07'}">julio</c:when>
                                    <c:when test="${pf[1] eq '08'}">agosto</c:when>
                                    <c:when test="${pf[1] eq '09'}">septiembre</c:when>
                                    <c:when test="${pf[1] eq '10'}">octubre</c:when>
                                    <c:when test="${pf[1] eq '11'}">noviembre</c:when>
                                    <c:when test="${pf[1] eq '12'}">diciembre</c:when>
                                </c:choose>
                                ${pf[2]} de ${pf[0]}
                            </c:when>
                            <c:otherwise>Bienvenido al sistema</c:otherwise>
                        </c:choose>
                    </p>
                </div>
                <div class="recep-greeting__right">
                    <a href="${pageContext.request.contextPath}/clients?action=new"
                       class="recep-action recep-action--green">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.2">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M12 4.5v15m7.5-7.5h-15"/>
                        </svg>
                        Nuevo cliente
                    </a>
                    <a href="${pageContext.request.contextPath}/contracts?action=new"
                       class="recep-action recep-action--ghost">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125
                                     1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H8.25m0
                                     12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125
                                     1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504
                                     1.125-1.125V11.25a9 9 0 0 0-9-9Z"/>
                        </svg>
                        Nuevo contrato
                    </a>
                </div>
            </div>

            <%-- ══════════════════════════════════════════════════
                 GRID PRINCIPAL
                 ══════════════════════════════════════════════════ --%>
            <div class="dashboard-recep-grid">

                <%-- ─────────────────────────────────────────────
                     COLUMNA A: Panel de Check-in rápido
                     Fila 1-2 (izquierda)
                     ───────────────────────────────────────────── --%>
                <div class="card area-checkin">
                    <div class="checkin-panel">

                        <%-- Cabecera del panel --%>
                        <div class="checkin-panel__header">
                            <div class="checkin-panel__icon">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                </svg>
                            </div>
                            <span class="checkin-panel__title">Check-in de Ingreso</span>
                        </div>

                        <%-- Cuerpo del formulario --%>
                        <div class="checkin-form-area">

                            <%-- Instrucción --%>
                            <p class="checkin-instruction">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="m11.25 11.25.041-.02a.75.75 0 0 1 1.063.852l-.708
                                             2.836a.75.75 0 0 0 1.063.853l.041-.021M21 12a9 9 0
                                             1 1-18 0 9 9 0 0 1 18 0Zm-9-3.75h.008v.008H12V8.25Z"/>
                                </svg>
                                Ingresa el número de documento del cliente para registrar su entrada.
                            </p>

                            <%-- ── RESULTADO DEL ÚLTIMO CHECK-IN ─────────────
                                 Se muestra solo después del POST/redirect (PRG).
                                 successMsg → ingreso OK
                                 errorMsg   → error (sin contrato, ya registrado, etc.)
                                 ──────────────────────────────────────────────── --%>
                            <c:if test="${not empty checkInSuccessMsg}">
                                <div class="checkin-result checkin-result--ok">
                                    <div class="checkin-result__icon">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.2">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                        </svg>
                                    </div>
                                    <div class="checkin-result__body">
                                        <c:if test="${not empty sessionScope.checkInCliente}">
                                            <p class="checkin-result__nombre">
                                                <c:out value="${sessionScope.checkInCliente}"/>
                                            </p>
                                        </c:if>
                                        <c:if test="${not empty sessionScope.checkInMembresia}">
                                            <p class="checkin-result__membresia">
                                                <c:out value="${sessionScope.checkInMembresia}"/>
                                            </p>
                                        </c:if>
                                        <p class="checkin-result__msg">
                                            <c:out value="${checkInSuccessMsg}"/>
                                        </p>
                                    </div>
                                </div>
                                <%-- Limpiar atributos de sesión del check-in --%>
                                <c:remove var="checkInCliente"   scope="session"/>
                                <c:remove var="checkInMembresia" scope="session"/>
                            </c:if>

                            <c:if test="${not empty checkInErrorMsg}">
                                <%-- Determinar estilo según tipo de error --%>
                                <c:set var="errorClass" value="checkin-result--error"/>
                                <c:if test="${sessionScope.checkInTipo eq 'YA_REGISTRADO_HOY'}">
                                    <c:set var="errorClass" value="checkin-result--warn"/>
                                </c:if>

                                <div class="checkin-result ${errorClass}">
                                    <div class="checkin-result__icon">
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
                                                          d="M12 9v3.75m-9.303 3.376c-.866 1.5.217
                                                             3.374 1.948 3.374h14.71c1.73 0 2.813-1.874
                                                             1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898
                                                             0L2.697 16.126ZM12 15.75h.007v.008H12v-.008Z"/>
                                                </svg>
                                            </c:otherwise>
                                        </c:choose>
                                    </div>
                                    <div class="checkin-result__body">
                                        <p class="checkin-result__msg">
                                            <c:out value="${checkInErrorMsg}"/>
                                        </p>
                                    </div>
                                </div>
                                <c:remove var="checkInTipo" scope="session"/>
                            </c:if>

                            <%-- ── Formulario de check-in ──────────────────── --%>
                            <form action="${pageContext.request.contextPath}/attendance"
                                  method="post"
                                  autocomplete="off"
                                  novalidate>

                                <input type="hidden" name="action"  value="checkin">
                                <input type="hidden" name="_csrf"   value="${sessionScope._csrfToken}">

                                <div class="checkin-input-wrapper">
                                    <%-- Ícono ID card --%>
                                    <svg class="checkin-input-wrapper__icon"
                                         xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor"
                                         stroke-width="1.8" aria-hidden="true">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M15 9h3.75M15 12h3.75M15 15h3.75M4.5
                                                 7.5a3 3 0 0 1 3-3h9a3 3 0 0 1 3 3v9a3 3
                                                 0 0 1-3 3h-9a3 3 0 0 1-3-3v-9Zm6
                                                 0a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z"/>
                                    </svg>
                                    <input
                                        type="text"
                                        name="numeroDocumento"
                                        id="numeroDocumento"
                                        class="checkin-input"
                                        placeholder="Nro. de documento..."
                                        maxlength="20"
                                        autofocus
                                        autocomplete="off"
                                        inputmode="numeric"
                                        aria-label="Número de documento del cliente"
                                        aria-required="true">
                                </div>

                                <button type="submit" class="checkin-btn">
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
                            <div class="checkin-divider">
                                <span class="checkin-divider__text">accesos rápidos</span>
                            </div>

                            <%-- Accesos rápidos --%>
                            <div class="checkin-quick-links">
                                <a href="${pageContext.request.contextPath}/clients"
                                   class="checkin-quick-link">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M15 19.128a9.38 9.38 0 0 0 2.625.372 9.337 9.337
                                                 0 0 0 4.121-.952 4.125 4.125 0 0
                                                 0-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15
                                                 19.128v.106A12.318 12.318 0 0 1 8.624 21c-2.331
                                                 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0
                                                 1 11.964-3.07M12 6.375a3.375 3.375 0 1 1-6.75 0 3.375
                                                 3.375 0 0 1 6.75 0Zm8.25 2.25a2.625 2.625 0 1 1-5.25
                                                 0 2.625 2.625 0 0 1 5.25 0Z"/>
                                    </svg>
                                    Clientes
                                </a>
                                <a href="${pageContext.request.contextPath}/contracts"
                                   class="checkin-quick-link">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125
                                                 1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0
                                                 0-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621
                                                 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125
                                                 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z"/>
                                    </svg>
                                    Contratos
                                </a>
                                <a href="${pageContext.request.contextPath}/memberships"
                                   class="checkin-quick-link">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M2.25 8.25h19.5M2.25 9h19.5m-16.5 5.25h6m-6
                                                 2.25h3m-3.75 3h15a2.25 2.25 0 0 0
                                                 2.25-2.25V6.75A2.25 2.25 0 0 0
                                                 19.5 4.5h-15a2.25 2.25 0 0 0-2.25 2.25v10.5A2.25 2.25 0
                                                 0 0 4.5 19.5Z"/>
                                    </svg>
                                    Membresías
                                </a>
                                <a href="${pageContext.request.contextPath}/attendance?action=hist"
                                   class="checkin-quick-link">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M3.75 12h16.5m-16.5 3.75h16.5M3.75 19.5h16.5M5.625
                                                 4.5h12.75a1.875 1.875 0 0 1 0 3.75H5.625a1.875 1.875
                                                 0 0 1 0-3.75Z"/>
                                    </svg>
                                    Historial
                                </a>
                            </div>

                        </div><%-- /checkin-form-area --%>
                    </div><%-- /checkin-panel --%>
                </div><%-- /area-checkin --%>

                <%-- ─────────────────────────────────────────────
                     COLUMNA B FILA 1: KPI Strip (3 métricas)
                     ───────────────────────────────────────────── --%>
                <div class="area-kpis-recep">
                    <div class="kpi-strip">

                        <%-- KPI 1: Atendidos hoy --%>
                        <div class="kpi-strip-card strip--red">
                            <div class="kpi-strip-card__icon">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                </svg>
                            </div>
                            <div class="kpi-strip-card__body">
                                <div class="kpi-strip-card__value">
                                    <c:out value="${atendidosHoy}"/>
                                </div>
                                <div class="kpi-strip-card__label">Atendidos hoy</div>
                            </div>
                        </div>

                        <%-- KPI 2: Contratos activos --%>
                        <div class="kpi-strip-card strip--green">
                            <div class="kpi-strip-card__icon">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125
                                             1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0
                                             0-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5
                                             2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504
                                             1.125 1.125 1.125h12.75c.621 0 1.125-.504
                                             1.125-1.125V11.25a9 9 0 0 0-9-9Z"/>
                                </svg>
                            </div>
                            <div class="kpi-strip-card__body">
                                <div class="kpi-strip-card__value">
                                    <c:out value="${contratosActivos}"/>
                                </div>
                                <div class="kpi-strip-card__label">Contratos activos</div>
                            </div>
                        </div>

                        <%-- KPI 3: Clases de hoy --%>
                        <div class="kpi-strip-card strip--blue">
                            <div class="kpi-strip-card__icon">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0
                                             1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18
                                             0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21
                                             18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25
                                             2.25 0 0 1 21 11.25v7.5"/>
                                </svg>
                            </div>
                            <div class="kpi-strip-card__body">
                                <div class="kpi-strip-card__value">
                                    <c:out value="${countClasesHoy}"/>
                                </div>
                                <div class="kpi-strip-card__label">Clases hoy</div>
                            </div>
                        </div>

                    </div><%-- /kpi-strip --%>
                </div><%-- /area-kpis-recep --%>

                <%-- ─────────────────────────────────────────────
                     COLUMNA B FILA 2: Actividad reciente
                     Últimas 10 asistencias del día
                     ───────────────────────────────────────────── --%>
                <div class="card area-actividad">

                    <div class="widget-header">
                        <div class="widget-header__left">
                            <div class="widget-header__icon">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                </svg>
                            </div>
                            <span class="widget-header__title">Actividad del Día</span>
                            <span class="widget-header__count">
                                <c:out value="${atendidosHoy}"/> ingresos
                            </span>
                        </div>
                        <a href="${pageContext.request.contextPath}/attendance?action=hist"
                           class="widget-header__link">
                            Ver historial
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                      d="M13.5 4.5 21 12m0 0-7.5 7.5M21 12H3"/>
                            </svg>
                        </a>
                    </div>

                    <c:choose>
                        <c:when test="${not empty asistenciasRecientes}">
                            <div class="actividad-feed">
                                <c:forEach var="asistencia"
                                           items="${asistenciasRecientes}"
                                           varStatus="loop">
                                    <div class="actividad-row">
                                        <%-- Número de entrada --%>
                                        <span class="actividad-row__num">
                                            <c:out value="${loop.index + 1}"/>
                                        </span>
                                        <%-- Estado --%>
                                        <span class="actividad-dot
                                            ${asistencia.isPendiente() ? 'pendiente' : ''}
                                            ${asistencia.isFalto()     ? 'falto'     : ''}"
                                              aria-hidden="true"></span>
                                        <%-- Nombre del cliente --%>
                                        <span class="actividad-nombre">
                                            <c:out value="${asistencia.nombreCliente}"/>
                                        </span>
                                        <%-- Membresía --%>
                                        <span class="actividad-membresia">
                                            <c:if test="${asistencia.contrato != null
                                                          and asistencia.contrato.membresia != null}">
                                                <c:out value="${asistencia.contrato.membresia.nombreMembresia}"/>
                                            </c:if>
                                        </span>
                                        <%-- Hora --%>
                                        <span class="actividad-hora">
                                            <c:out value="${asistencia.horaIngresoFormateada}"/>
                                        </span>
                                    </div>
                                </c:forEach>
                            </div>

                            <div class="widget-footer">
                                <span class="widget-footer__stat">
                                    Últimos
                                    <strong><c:out value="${fn:length(asistenciasRecientes)}"/></strong>
                                    registros
                                </span>
                                <a href="${pageContext.request.contextPath}/attendance"
                                   class="btn btn-ghost btn-sm">
                                    Panel completo
                                </a>
                            </div>
                        </c:when>

                        <c:otherwise>
                            <div class="widget-empty">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M15.75 6a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1
                                             7.5 0ZM4.501 20.118a7.5 7.5 0 0 1 14.998
                                             0A17.933 17.933 0 0 1 12 21.75c-2.676
                                             0-5.216-.584-7.499-1.632Z"/>
                                </svg>
                                <p class="widget-empty__text">
                                    Sin ingresos registrados hoy.<br>
                                    Usa el formulario de check-in para comenzar.
                                </p>
                            </div>
                        </c:otherwise>
                    </c:choose>

                </div><%-- /area-actividad --%>

                <%-- ─────────────────────────────────────────────
                     FILA 3 IZQUIERDA: Clases del día
                     ───────────────────────────────────────────── --%>
                <div class="card area-clases-hoy">

                    <div class="widget-header">
                        <div class="widget-header__left">
                            <div class="widget-header__icon blue-icon">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75
                                             21.75 12 13.5H3.75z"/>
                                </svg>
                            </div>
                            <span class="widget-header__title">Clases de Hoy</span>
                            <span class="widget-header__count">
                                <c:out value="${countClasesHoy}"/>
                            </span>
                        </div>
                        <a href="${pageContext.request.contextPath}/calendar"
                           class="widget-header__link">
                            Calendario
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                      d="M13.5 4.5 21 12m0 0-7.5 7.5M21 12H3"/>
                            </svg>
                        </a>
                    </div>

                    <c:choose>
                        <c:when test="${not empty clasesHoy}">
                            <div class="clases-recep-list">
                                <c:forEach var="horario" items="${clasesHoy}">
                                    <div class="clase-recep-item">
                                        <%-- Hora --%>
                                        <div class="clase-recep-hora">
                                            <span class="clase-recep-hora__ini">
                                                <c:out value="${fn:substring(horario.horaInicio.toString(), 0, 5)}"/>
                                            </span>
                                            <span class="clase-recep-hora__fin">
                                                <c:out value="${fn:substring(horario.horaFin.toString(), 0, 5)}"/>
                                            </span>
                                        </div>
                                        <%-- Barra de color --%>
                                        <div class="clase-recep-bar" aria-hidden="true"></div>
                                        <%-- Info de la clase --%>
                                        <div class="clase-recep-info">
                                            <p class="clase-recep-nombre">
                                                <c:out value="${horario.clase.nombreClase}"/>
                                            </p>
                                            <p class="clase-recep-instructor">
                                                <c:out value="${horario.getNombreDia()}"/>
                                            </p>
                                        </div>
                                        <%-- Badge --%>
                                        <span class="clase-recep-badge">Hoy</span>
                                    </div>
                                </c:forEach>
                            </div>

                            <div class="widget-footer">
                                <span class="widget-footer__stat">
                                    <strong><c:out value="${countClasesHoy}"/></strong> clases programadas
                                </span>
                                <a href="${pageContext.request.contextPath}/schedules"
                                   class="btn btn-ghost btn-sm">
                                    Ver horarios
                                </a>
                            </div>
                        </c:when>

                        <c:otherwise>
                            <div class="widget-empty">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0
                                             1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18
                                             0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21
                                             18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25
                                             2.25 0 0 1 21 11.25v7.5"/>
                                </svg>
                                <p class="widget-empty__text">
                                    No hay clases programadas para hoy.
                                </p>
                            </div>
                        </c:otherwise>
                    </c:choose>

                </div><%-- /area-clases-hoy --%>

                <%-- ─────────────────────────────────────────────
                     FILA 3 DERECHA: Contratos próximos a vencer
                     ───────────────────────────────────────────── --%>
                <div class="card area-vence-recep">

                    <div class="widget-header">
                        <div class="widget-header__left">
                            <div class="widget-header__icon">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948
                                             3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949
                                             3.378c-.866-1.5-3.032-1.5-3.898 0L2.697
                                             16.126ZM12 15.75h.007v.008H12v-.008Z"/>
                                </svg>
                            </div>
                            <span class="widget-header__title">Próximos Vencer</span>
                            <c:choose>
                                <c:when test="${countProximosVencer > 0}">
                                    <span class="widget-header__count count--alert">
                                        <c:out value="${countProximosVencer}"/>
                                    </span>
                                </c:when>
                                <c:otherwise>
                                    <span class="widget-header__count">0</span>
                                </c:otherwise>
                            </c:choose>
                        </div>
                        <a href="${pageContext.request.contextPath}/contracts"
                           class="widget-header__link">
                            Ver contratos
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                      d="M13.5 4.5 21 12m0 0-7.5 7.5M21 12H3"/>
                            </svg>
                        </a>
                    </div>

                    <c:choose>
                        <c:when test="${not empty proximosVencer}">
                            <div class="vence-compact-list">
                                <c:forEach var="contrato" items="${proximosVencer}">
                                    <div class="vence-compact-item">
                                        <%-- Avatar con inicial --%>
                                        <div class="vence-compact-avatar
                                             ${contrato.proximoAVencer(3) ? 'urgent' : ''}">
                                            <c:out value="${fn:substring(contrato.cliente.nombre, 0, 1)}"/>
                                        </div>
                                        <%-- Info --%>
                                        <div class="vence-compact-info">
                                            <p class="vence-compact-nombre">
                                                <c:out value="${contrato.cliente.nombreCompleto}"/>
                                            </p>
                                            <p class="vence-compact-fecha
                                               ${contrato.proximoAVencer(3) ? 'urgent' : ''}">
                                                Vence: <c:out value="${contrato.fechaFin}"/>
                                            </p>
                                        </div>
                                    </div>
                                </c:forEach>
                            </div>

                            <div class="widget-footer">
                                <span class="widget-footer__stat">
                                    <strong><c:out value="${countProximosVencer}"/></strong>
                                    en los próximos 7 días
                                </span>
                            </div>
                        </c:when>

                        <c:otherwise>
                            <div class="widget-empty">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M9 12.75 11.25 15 15 9.75M21 12c0 1.268-.63 2.39-1.593
                                             3.068a3.745 3.745 0 0 1-1.043 3.296 3.745 3.745 0 0
                                             1-3.296 1.043A3.745 3.745 0 0 1 12 21c-1.268
                                             0-2.39-.63-3.068-1.593a3.746 3.746 0 0
                                             1-3.296-1.043 3.745 3.745 0 0 1-1.043-3.296A3.745
                                             3.745 0 0 1 3 12c0-1.268.63-2.39 1.593-3.068a3.745
                                             3.745 0 0 1 1.043-3.296 3.746 3.746 0 0 1
                                             3.296-1.043A3.746 3.746 0 0 1 12 3c1.268 0
                                             2.39.63 3.068 1.593a3.746 3.746 0 0 1 3.296
                                             1.043 3.746 3.746 0 0 1 1.043 3.296A3.745
                                             3.745 0 0 1 21 12Z"/>
                                </svg>
                                <p class="widget-empty__text">
                                    Sin contratos próximos<br>a vencer.
                                </p>
                            </div>
                        </c:otherwise>
                    </c:choose>

                </div><%-- /area-vence-recep --%>

            </div><%-- /dashboard-recep-grid --%>

        </div><%-- /page-content --%>
    </div><%-- /app-main --%>
</div><%-- /app-shell --%>

</body>
</html>
