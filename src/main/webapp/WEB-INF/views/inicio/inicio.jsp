<%-- ============================================================
     inicio.jsp  —  MaxFit Sistema de Gestión
     Dashboard principal del Administrador.

     Servlet:  InicioController.java  → GET /inicio
     Acceso:   Solo ROL-ADMIN (RoleFilter)

     ── Atributos de request inyectados por el controlador ──────
     KPIs:
       totalClientes     (int / "-")   → total clientes registrados
       contratosActivos  (int / "-")   → contratos con estado 'activo'
       atendidosHoy      (int / "-")   → check-ins del día
       totalEmpleados    (int / "-")   → empleados registrados
       clasesVigentes    (int / "-")   → clases con estado 'vigente'
       ingresosMes       (BigDecimal)  → suma monto_pagado mes actual

     Widgets:
       proximosVencer       (List<Contrato>)    → vencen en ≤ 7 días
       countProximosVencer  (int)               → tamaño de la lista
       diasAlertaVencimiento (int)              → días de alerta (7)
       asistenciasRecientes (List<Asistencia>)  → últimos 5 check-ins
       clasesHoy            (List<Horario>)     → horarios de hoy
       countClasesHoy       (int)               → nro. de clases hoy
       fechaHoy             (String ISO)        → "2026-05-24"

     Sesión:
       sessionScope.userName   → nombre del empleado logueado
       sessionScope.userRole   → ROL-ADMIN
       sessionScope.userEmail  → email

     Flash:
       successMsg / errorMsg   → consumidos por transferirFlashMessages
     ============================================================ --%>
<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <%@ include file="/WEB-INF/views/includes/head-common.jsp" %>
    <c:set var="pageTitle" value="Inicio" scope="request"/>
    <link rel="stylesheet"
          href="${pageContext.request.contextPath}/static/css/inicio.css">
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
        <c:set var="pageSubtitle" value="Panel de administración" scope="request"/>
        <%@ include file="/WEB-INF/views/includes/navbar.jsp" %>

        <%-- ── Contenido del módulo ─────────────────────────── --%>
        <div class="page-content">

            <%-- ── Franja de bienvenida ──────────────────────── --%>
            <div class="greeting-strip">
                <div class="greeting__left">
                    <span class="greeting__saludo">Panel de Administración</span>
                    <h1 class="greeting__nombre">
                        Hola, <span><c:out value="${fn:split(sessionScope.userName, ' ')[0]}"/></span>
                    </h1>
                    <p class="greeting__fecha">
                        <%-- Fecha formateada desde el atributo del controlador --%>
                        <c:choose>
                            <c:when test="${not empty fechaHoy}">
                                <c:set var="partesFecha" value="${fn:split(fechaHoy, '-')}"/>
                                <c:set var="anio"  value="${partesFecha[0]}"/>
                                <c:set var="mes"   value="${partesFecha[1]}"/>
                                <c:set var="dia"   value="${partesFecha[2]}"/>
                                Hoy,
                                <c:choose>
                                    <c:when test="${mes eq '01'}">enero</c:when>
                                    <c:when test="${mes eq '02'}">febrero</c:when>
                                    <c:when test="${mes eq '03'}">marzo</c:when>
                                    <c:when test="${mes eq '04'}">abril</c:when>
                                    <c:when test="${mes eq '05'}">mayo</c:when>
                                    <c:when test="${mes eq '06'}">junio</c:when>
                                    <c:when test="${mes eq '07'}">julio</c:when>
                                    <c:when test="${mes eq '08'}">agosto</c:when>
                                    <c:when test="${mes eq '09'}">septiembre</c:when>
                                    <c:when test="${mes eq '10'}">octubre</c:when>
                                    <c:when test="${mes eq '11'}">noviembre</c:when>
                                    <c:when test="${mes eq '12'}">diciembre</c:when>
                                </c:choose>
                                ${dia} de ${anio}
                            </c:when>
                            <c:otherwise>Bienvenido al sistema</c:otherwise>
                        </c:choose>
                    </p>
                </div>
                <div class="greeting__right">
                    <%-- Acceso rápido: nuevo cliente --%>
                    <a href="${pageContext.request.contextPath}/clients?action=new"
                       class="quick-action quick-action--primary">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.2"
                             aria-hidden="true">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M12 4.5v15m7.5-7.5h-15"/>
                        </svg>
                        Nuevo cliente
                    </a>
                    <%-- Acceso rápido: asistencia --%>
                    <a href="${pageContext.request.contextPath}/attendance"
                       class="quick-action quick-action--secondary">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8"
                             aria-hidden="true">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                        </svg>
                        Check-in
                    </a>
                    <%-- Acceso rápido: reportes --%>
                    <a href="${pageContext.request.contextPath}/reports"
                       class="quick-action quick-action--secondary">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8"
                             aria-hidden="true">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621
                                     0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375
                                     21h-2.25A1.125 1.125 0 0 1 3 19.875v-6.75ZM9.75 8.625c0-.621.504-1.125
                                     1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0
                                     .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 0
                                     1-1.125-1.125V8.625ZM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496
                                     3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125
                                     1.125 0 0 1-1.125-1.125V4.125Z"/>
                        </svg>
                        Reportes
                    </a>
                </div>
            </div>

            <%-- ══════════════════════════════════════════════════
                 BLOQUE KPI — 6 tarjetas de métricas clave
                 ══════════════════════════════════════════════════ --%>
            <div class="kpi-row mb-3">

                <%-- KPI 1: Clientes registrados --%>
                <div class="kpi-card--admin kpi--blue">
                    <div class="kpi-card__header">
                        <span class="kpi-card__label-top">Clientes</span>
                        <div class="kpi-card__badge">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8"
                                 aria-hidden="true">
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
                    </div>
                    <div class="kpi-card__num">
                        <c:out value="${totalClientes}"/>
                    </div>
                    <div class="kpi-card__meta">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"
                             aria-hidden="true">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M13.5 16.875h3.375m0 0h3.375m-3.375 0V13.5m0
                                     3.375v3.375M6 10.5h2.25a2.25 2.25 0 0 0
                                     2.25-2.25V6a2.25 2.25 0 0 0-2.25-2.25H6A2.25
                                     2.25 0 0 0 3.75 6v2.25A2.25 2.25 0 0 0 6
                                     10.5Zm0 9.75h2.25A2.25 2.25 0 0 0 10.5 18v-2.25a2.25
                                     2.25 0 0 0-2.25-2.25H6a2.25 2.25 0 0
                                     0-2.25 2.25V18A2.25 2.25 0 0 0 6 20.25Zm9.75-9.75H18a2.25
                                     2.25 0 0 0 2.25-2.25V6A2.25 2.25 0 0 0 18
                                     3.75h-2.25A2.25 2.25 0 0 0 13.5 6v2.25a2.25 2.25 0 0
                                     0 2.25 2.25Z"/>
                        </svg>
                        Total registrados
                    </div>
                </div>

                <%-- KPI 2: Contratos activos --%>
                <div class="kpi-card--admin kpi--green">
                    <div class="kpi-card__header">
                        <span class="kpi-card__label-top">Contratos activos</span>
                        <div class="kpi-card__badge">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8"
                                 aria-hidden="true">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                      d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125
                                         1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0
                                         0-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621
                                         0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125
                                         1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z"/>
                            </svg>
                        </div>
                    </div>
                    <div class="kpi-card__num">
                        <c:out value="${contratosActivos}"/>
                    </div>
                    <div class="kpi-card__meta">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"
                             aria-hidden="true">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                        </svg>
                        Membresías vigentes
                    </div>
                </div>

                <%-- KPI 3: Check-ins hoy --%>
                <div class="kpi-card--admin kpi--red">
                    <div class="kpi-card__header">
                        <span class="kpi-card__label-top">Atendidos hoy</span>
                        <div class="kpi-card__badge">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8"
                                 aria-hidden="true">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                      d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0
                                         1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18
                                         0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21
                                         18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25
                                         2.25 0 0 1 21 11.25v7.5"/>
                            </svg>
                        </div>
                    </div>
                    <div class="kpi-card__num">
                        <c:out value="${atendidosHoy}"/>
                    </div>
                    <div class="kpi-card__meta">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"
                             aria-hidden="true">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                        </svg>
                        Ingresos del día
                    </div>
                </div>

                <%-- KPI 4: Empleados --%>
                <div class="kpi-card--admin kpi--purple">
                    <div class="kpi-card__header">
                        <span class="kpi-card__label-top">Empleados</span>
                        <div class="kpi-card__badge">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8"
                                 aria-hidden="true">
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
                    </div>
                    <div class="kpi-card__num">
                        <c:out value="${totalEmpleados}"/>
                    </div>
                    <div class="kpi-card__meta">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"
                             aria-hidden="true">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M15.75 6a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5
                                     0ZM4.501 20.118a7.5 7.5 0 0 1 14.998 0A17.933 17.933 0
                                     0 1 12 21.75c-2.676 0-5.216-.584-7.499-1.632Z"/>
                        </svg>
                        Staff registrado
                    </div>
                </div>

                <%-- KPI 5: Clases vigentes --%>
                <div class="kpi-card--admin kpi--teal">
                    <div class="kpi-card__header">
                        <span class="kpi-card__label-top">Clases activas</span>
                        <div class="kpi-card__badge">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8"
                                 aria-hidden="true">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                      d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z"/>
                            </svg>
                        </div>
                    </div>
                    <div class="kpi-card__num">
                        <c:out value="${clasesVigentes}"/>
                    </div>
                    <div class="kpi-card__meta">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"
                             aria-hidden="true">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0
                                     1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18
                                     0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21
                                     18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25
                                     2.25 0 0 1 21 11.25v7.5m-9-6h.008v.008H12v-.008ZM12
                                     15h.008v.008H12V15Zm0 2.25h.008v.008H12v-.008ZM9.75
                                     15h.008v.008H9.75V15Zm0 2.25h.008v.008H9.75v-.008ZM7.5
                                     15h.008v.008H7.5V15Zm0 2.25h.008v.008H7.5v-.008Zm6.75-4.5h.008v.008h-.008v-.008Zm0
                                     2.25h.008v.008h-.008V15Zm0 2.25h.008v.008h-.008v-.008Zm2.25-4.5h.008v.008H16.5v-.008Zm0
                                     2.25h.008v.008H16.5V15Z"/>
                        </svg>
                        En programa
                    </div>
                </div>

                <%-- KPI 6: Ingresos del mes (card especial) --%>
                <div class="kpi-card--admin kpi--red ingresos-card">
                    <div class="kpi-card__header">
                        <span class="kpi-card__label-top">Ingresos del mes</span>
                        <div class="kpi-card__badge">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8"
                                 aria-hidden="true">
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
                        </div>
                    </div>
                    <div class="kpi-card__num is-money">
                        <fmt:formatNumber value="${ingresosMes}" pattern="#,##0.00"/>
                    </div>
                    <div class="kpi-card__meta">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"
                             aria-hidden="true">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0
                                     1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18
                                     0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21
                                     18.75m-18 0v-7.5"/>
                        </svg>
                        Facturado este mes
                    </div>
                </div>

            </div><%-- /kpi-row --%>

            <%-- ══════════════════════════════════════════════════
                 DASHBOARD GRID: Widgets
                 ══════════════════════════════════════════════════ --%>
            <div class="dashboard-grid">

                <%-- ─────────────────────────────────────────────
                     WIDGET A: Contratos próximos a vencer
                     Ocupa columna 3 (derecha)
                     ───────────────────────────────────────────── --%>
                <div class="card area-vencimientos">

                    <%-- Header del widget --%>
                    <div class="widget-header">
                        <div class="widget-header__left">
                            <div class="widget-header__icon">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8"
                                     aria-hidden="true">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948
                                             3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949
                                             3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126ZM12
                                             15.75h.007v.008H12v-.008Z"/>
                                </svg>
                            </div>
                            <span class="widget-header__title">Próximos a Vencer</span>
                            <c:choose>
                                <c:when test="${countProximosVencer > 0}">
                                    <span class="widget-header__count alert">
                                        <c:out value="${countProximosVencer}"/>
                                    </span>
                                </c:when>
                                <c:otherwise>
                                    <span class="widget-header__count">0</span>
                                </c:otherwise>
                            </c:choose>
                        </div>
                        <a href="${pageContext.request.contextPath}/contracts"
                           class="widget-header__link"
                           aria-label="Ver todos los contratos">
                            Ver contratos
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"
                                 aria-hidden="true">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                      d="M13.5 4.5 21 12m0 0-7.5 7.5M21 12H3"/>
                            </svg>
                        </a>
                    </div>

                    <%-- Alerta si hay múltiples vencimientos --%>
                    <c:if test="${countProximosVencer > 2}">
                        <div class="alerta-banner">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"
                                 aria-hidden="true">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                      d="M12 9v3.75m9-.75a9 9 0 1 1-18 0 9 9 0 0 1 18
                                         0Zm-9 3.75h.008v.008H12v-.008Z"/>
                            </svg>
                            <p class="alerta-banner__text">
                                <strong><c:out value="${countProximosVencer}"/> contratos</strong>
                                vencen en los próximos
                                <c:out value="${diasAlertaVencimiento}"/> días.
                                Contacta a los clientes.
                            </p>
                        </div>
                    </c:if>

                    <%-- Lista de contratos próximos a vencer --%>
                    <c:choose>
                        <c:when test="${not empty proximosVencer}">
                            <div class="vencimiento-list">
                                <c:forEach var="contrato" items="${proximosVencer}">
                                    <c:set var="fechaFin" value="${contrato.fechaFin}"/>
                                    <%-- Calculamos los días restantes en el JSP de forma aproximada.
                                         El dato exacto viene del controlador via proximoAVencer().
                                         Mostramos la fecha directamente. --%>
                                    <div class="vencimiento-item">

                                        <%-- Avatar con inicial del cliente --%>
                                        <c:set var="nombreCompleto"
                                               value="${contrato.cliente.nombreCompleto}"/>
                                        <c:set var="inicial"
                                               value="${fn:substring(contrato.cliente.nombre, 0, 1)}"/>
                                        <div class="vencimiento-avatar
                                             ${contrato.proximoAVencer(3) ? 'urgent' : ''}">
                                            <c:out value="${inicial}"/>
                                        </div>

                                        <%-- Datos del cliente --%>
                                        <div class="vencimiento-info">
                                            <p class="vencimiento-nombre">
                                                <c:out value="${nombreCompleto}"/>
                                            </p>
                                            <p class="vencimiento-membresia">
                                                <c:out value="${contrato.membresia.nombreMembresia}"/>
                                            </p>
                                        </div>

                                        <%-- Fecha de vencimiento --%>
                                        <div class="vencimiento-fecha">
                                            <p class="vencimiento-dias
                                               ${contrato.proximoAVencer(3) ? 'urgent' : 'safe'}">
                                                <c:out value="${fechaFin}"/>
                                            </p>
                                            <p class="vencimiento-label-dias">vence</p>
                                        </div>

                                    </div>
                                </c:forEach>
                            </div>

                            <%-- Footer con acceso rápido --%>
                            <div class="widget-footer">
                                <span class="widget-footer__stat">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8"
                                         aria-hidden="true">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                    </svg>
                                    Alerta:
                                    <strong><c:out value="${diasAlertaVencimiento}"/> días</strong>
                                </span>
                                <a href="${pageContext.request.contextPath}/reports?action=contratos"
                                   class="btn btn-ghost btn-sm">
                                    Ver reporte
                                </a>
                            </div>
                        </c:when>

                        <c:otherwise>
                            <%-- Estado vacío --%>
                            <div class="widget-empty">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"
                                     aria-hidden="true">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M9 12.75 11.25 15 15 9.75M21 12c0 1.268-.63 2.39-1.593
                                             3.068a3.745 3.745 0 0 1-1.043 3.296 3.745 3.745 0 0
                                             1-3.296 1.043A3.745 3.745 0 0 1 12 21c-1.268
                                             0-2.39-.63-3.068-1.593a3.746 3.746 0 0 1-3.296-1.043
                                             3.745 3.745 0 0 1-1.043-3.296A3.745 3.745 0 0 1 3 12c0-1.268.63-2.39
                                             1.593-3.068a3.745 3.745 0 0 1 1.043-3.296 3.746 3.746
                                             0 0 1 3.296-1.043A3.746 3.746 0 0 1 12 3c1.268 0
                                             2.39.63 3.068 1.593a3.746 3.746 0 0 1 3.296 1.043
                                             3.746 3.746 0 0 1 1.043 3.296A3.745 3.745 0 0 1 21 12Z"/>
                                </svg>
                                <p class="widget-empty__text">
                                    Sin contratos próximos a vencer.<br>
                                    Todo en orden.
                                </p>
                            </div>
                        </c:otherwise>
                    </c:choose>

                </div><%-- /area-vencimientos --%>

                <%-- ─────────────────────────────────────────────
                     WIDGET B: Clases del día de hoy
                     Columna izquierda
                     ───────────────────────────────────────────── --%>
                <div class="card area-clases">
                    <div class="widget-header">
                        <div class="widget-header__left">
                            <div class="widget-header__icon">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8"
                                     aria-hidden="true">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75
                                             12 13.5H3.75z"/>
                                </svg>
                            </div>
                            <span class="widget-header__title">Clases de Hoy</span>
                            <span class="widget-header__count">
                                <c:out value="${countClasesHoy}"/>
                            </span>
                        </div>
                        <a href="${pageContext.request.contextPath}/calendar"
                           class="widget-header__link"
                           aria-label="Ver calendario completo">
                            Calendario
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"
                                 aria-hidden="true">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                      d="M13.5 4.5 21 12m0 0-7.5 7.5M21 12H3"/>
                            </svg>
                        </a>
                    </div>

                    <c:choose>
                        <c:when test="${not empty clasesHoy}">
                            <div class="clases-hoy-list">
                                <c:forEach var="horario" items="${clasesHoy}">
                                    <div class="clase-hoy-item">
                                        <%-- Rango horario --%>
                                        <div class="clase-hoy-hora">
                                            <span class="clase-hoy-hora__inicio">
                                                <%-- HoraInicio formato HH:mm --%>
                                                <c:set var="horaIni"
                                                       value="${fn:substring(horario.horaInicio.toString(), 0, 5)}"/>
                                                <c:out value="${horaIni}"/>
                                            </span>
                                            <span class="clase-hoy-hora__fin">
                                                <c:set var="horaFin"
                                                       value="${fn:substring(horario.horaFin.toString(), 0, 5)}"/>
                                                <c:out value="${horaFin}"/>
                                            </span>
                                        </div>
                                        <div class="clase-hoy-sep" aria-hidden="true"></div>
                                        <%-- Datos de la clase --%>
                                        <div class="clase-hoy-info">
                                            <p class="clase-hoy-nombre">
                                                <c:out value="${horario.clase.nombreClase}"/>
                                            </p>
                                            <p class="clase-hoy-instructor">
                                                <c:out value="${horario.getNombreDia()}"/>
                                            </p>
                                        </div>
                                        <%-- Badge de día --%>
                                        <span class="clase-hoy-dia">Hoy</span>
                                    </div>
                                </c:forEach>
                            </div>
                        </c:when>
                        <c:otherwise>
                            <div class="widget-empty">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"
                                     aria-hidden="true">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0
                                             1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18
                                             0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21
                                             18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25
                                             2.25 0 0 1 21 11.25v7.5"/>
                                </svg>
                                <p class="widget-empty__text">
                                    No hay clases programadas<br>para hoy.
                                </p>
                            </div>
                        </c:otherwise>
                    </c:choose>

                    <%-- Footer --%>
                    <div class="widget-footer">
                        <span class="widget-footer__stat">
                            <c:out value="${countClasesHoy}"/> clases programadas hoy
                        </span>
                        <a href="${pageContext.request.contextPath}/schedules"
                           class="btn btn-ghost btn-sm">
                            Gestionar
                        </a>
                    </div>
                </div><%-- /area-clases --%>

                <%-- ─────────────────────────────────────────────
                     WIDGET C: Asistencias recientes (últimas 5)
                     Columnas centrales / derecha
                     ───────────────────────────────────────────── --%>
                <div class="card area-asistencias">
                    <div class="widget-header">
                        <div class="widget-header__left">
                            <div class="widget-header__icon">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8"
                                     aria-hidden="true">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                </svg>
                            </div>
                            <span class="widget-header__title">Actividad Reciente</span>
                            <span class="widget-header__count">
                                <c:out value="${atendidosHoy}"/> hoy
                            </span>
                        </div>
                        <a href="${pageContext.request.contextPath}/attendance"
                           class="widget-header__link"
                           aria-label="Ver historial completo de asistencias">
                            Ver historial
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"
                                 aria-hidden="true">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                      d="M13.5 4.5 21 12m0 0-7.5 7.5M21 12H3"/>
                            </svg>
                        </a>
                    </div>

                    <c:choose>
                        <c:when test="${not empty asistenciasRecientes}">
                            <div class="asistencia-feed">
                                <c:forEach var="asistencia" items="${asistenciasRecientes}">
                                    <div class="asistencia-row">
                                        <%-- Indicador de estado --%>
                                        <span class="asistencia-dot
                                            ${asistencia.isPendiente() ? 'pendiente' : ''}
                                            ${asistencia.isFalto() ? 'falto' : ''}"
                                              aria-hidden="true"></span>

                                        <%-- Nombre del cliente (via contrato) --%>
                                        <span class="asistencia-nombre">
                                            <c:out value="${asistencia.nombreCliente}"/>
                                        </span>

                                        <%-- Nombre de la membresía --%>
                                        <span class="asistencia-membresia">
                                            <c:if test="${asistencia.contrato != null
                                                          and asistencia.contrato.membresia != null}">
                                                <c:out value="${asistencia.contrato.membresia.nombreMembresia}"/>
                                            </c:if>
                                        </span>

                                        <%-- Hora de ingreso --%>
                                        <span class="asistencia-hora">
                                            <c:out value="${asistencia.horaIngresoFormateada}"/>
                                        </span>
                                    </div>
                                </c:forEach>
                            </div>

                            <div class="widget-footer">
                                <span class="widget-footer__stat">
                                    Mostrando últimos
                                    <strong><c:out value="${fn:length(asistenciasRecientes)}"/></strong>
                                    registros
                                </span>
                                <a href="${pageContext.request.contextPath}/attendance?action=hist"
                                   class="btn btn-ghost btn-sm">
                                    Historial completo
                                </a>
                            </div>
                        </c:when>

                        <c:otherwise>
                            <div class="widget-empty">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"
                                     aria-hidden="true">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M15.75 6a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1
                                             7.5 0ZM4.501 20.118a7.5 7.5 0 0 1 14.998 0A17.933
                                             17.933 0 0 1 12 21.75c-2.676 0-5.216-.584-7.499-1.632Z"/>
                                </svg>
                                <p class="widget-empty__text">
                                    Sin asistencias registradas hoy.<br>
                                    Usa el
                                    <a href="${pageContext.request.contextPath}/attendance">
                                        módulo de check-in
                                    </a>
                                    para registrar ingresos.
                                </p>
                            </div>
                        </c:otherwise>
                    </c:choose>

                </div><%-- /area-asistencias --%>

            </div><%-- /dashboard-grid --%>

        </div><%-- /page-content --%>
    </div><%-- /app-main --%>
</div><%-- /app-shell --%>

</body>
</html>
