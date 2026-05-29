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
        <c:set var="pageTitle"    value="Inicio"                   scope="request"/>
        <c:set var="pageSubtitle" value="Panel de administración"  scope="request"/>
        <%@ include file="/WEB-INF/views/includes/navbar.jsp" %>

        <%-- ── Contenido del módulo ─────────────────────────── --%>
        <div class="page-content">

            <%-- ══════════════════════════════════════════════════
                 HERO BANNER — Bienvenida con imagen de fondo
                 ══════════════════════════════════════════════════ --%>
            <div class="inicio-hero">
                <%-- Imagen de fondo del gimnasio --%>
                <div class="inicio-hero__bg"
                     role="img"
                     aria-label="Instalaciones MaxFit"></div>

                <%-- Acento rojo izquierdo --%>
                <div class="inicio-hero__accent" aria-hidden="true"></div>

                <%-- Contenido del hero --%>
                <div class="inicio-hero__body">

                    <%-- Badge de rol --%>
                    <div class="inicio-hero__badge" aria-label="Rol activo">
                        <%-- Ícono escudo --%>
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"
                             aria-hidden="true">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M9 12.75 11.25 15 15 9.75m-3-7.036A11.959 11.959 0
                                     0 1 3.598 6 11.99 11.99 0 0 0 3 9.749c0 5.592 3.824
                                     10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196
                                     0-6.1-1.248-8.25-3.285Z"/>
                        </svg>
                        Administrador
                    </div>

                    <%-- Título --%>
                    <h1 class="inicio-hero__title">
                        Panel de Administración — <span>MaxFit</span>
                    </h1>

                    <%-- Descripción --%>
                    <p class="inicio-hero__desc">
                        Bienvenido<c:if test="${not empty sessionScope.userName}">,
                        <strong><c:out value="${fn:split(sessionScope.userName, ' ')[0]}"/></strong>
                        </c:if>.
                        Desde este panel centralizado puedes supervisar, gestionar y optimizar
                        el rendimiento operativo y financiero de tu gimnasio.
                        Consulta las herramientas disponibles a continuación.
                    </p>

                </div><%-- /inicio-hero__body --%>
            </div><%-- /inicio-hero --%>

            <%-- ══════════════════════════════════════════════════
                 SECCIÓN: ¿Qué puedes hacer como administrador?
                 ══════════════════════════════════════════════════ --%>
            <div class="inicio-section-header">
                <div class="inicio-section-tag" aria-hidden="true">
                    <%-- Ícono cuadrícula --%>
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"
                         aria-hidden="true">
                        <path stroke-linecap="round" stroke-linejoin="round"
                              d="M3.75 6A2.25 2.25 0 0 1 6 3.75h2.25A2.25 2.25
                                 0 0 1 10.5 6v2.25a2.25 2.25 0 0 1-2.25 2.25H6a2.25
                                 2.25 0 0 1-2.25-2.25V6ZM3.75 15.75A2.25 2.25 0 0 1
                                 6 13.5h2.25a2.25 2.25 0 0 1 2.25 2.25V18a2.25 2.25
                                 0 0 1-2.25 2.25H6A2.25 2.25 0 0 1 3.75 18v-2.25Z
                                 M13.5 6a2.25 2.25 0 0 1 2.25-2.25H18A2.25 2.25 0 0 1
                                 20.25 6v2.25A2.25 2.25 0 0 1 18 10.5h-2.25a2.25 2.25
                                 0 0 1-2.25-2.25V6ZM13.5 15.75a2.25 2.25 0 0 1
                                 2.25-2.25H18a2.25 2.25 0 0 1 2.25 2.25V18A2.25 2.25
                                 0 0 1 18 20.25h-2.25A2.25 2.25 0 0 1 13.5 18v-2.25Z"/>
                    </svg>
                    Herramientas disponibles
                </div>
                <h2 class="inicio-section-title">¿Qué puedes hacer como administrador?</h2>
            </div>

            <%-- ── Grid de tarjetas de capacidades ─────────────── --%>
            <div class="inicio-caps-grid" role="list">

                <%-- Tarjeta 1: Supervisar Métricas Financieras --%>
                <article class="inicio-cap-card inicio-cap-card--blue" role="listitem">
                    <div class="inicio-cap-card__icon" aria-hidden="true">
                        <%-- Ícono barras de gráfico --%>
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621
                                     0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21
                                     6.375 21h-2.25A1.125 1.125 0 0 1 3 19.875v-6.75Z
                                     M9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621
                                     0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125
                                     1.125h-2.25a1.125 1.125 0 0 1-1.125-1.125V8.625Z
                                     M16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496
                                     3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125
                                     1.125h-2.25a1.125 1.125 0 0 1-1.125-1.125V4.125Z"/>
                        </svg>
                    </div>
                    <div class="inicio-cap-card__body">
                        <h3 class="inicio-cap-card__name">Supervisar Métricas Financieras</h3>
                        <p class="inicio-cap-card__desc">
                            Consulta los ingresos mensuales consolidados, los contratos activos
                            y la tasa de retención en la sección de Reportes.
                        </p>
                    </div>
                    <div class="inicio-cap-card__footer">
                        <span class="inicio-cap-card__module">Módulo: Reportes</span>
                    </div>
                </article>

                <%-- Tarjeta 2: Gestionar Socios y Contratos --%>
                <article class="inicio-cap-card inicio-cap-card--green" role="listitem">
                    <div class="inicio-cap-card__icon" aria-hidden="true">
                        <%-- Ícono grupo personas --%>
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M15 19.128a9.38 9.38 0 0 0 2.625.372 9.337 9.337
                                     0 0 0 4.121-.952 4.125 4.125 0 0 0-7.533-2.493M15
                                     19.128v-.003c0-1.113-.285-2.16-.786-3.07M15
                                     19.128v.106A12.318 12.318 0 0 1 8.624 21c-2.331
                                     0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0
                                     1 11.964-3.07M12 6.375a3.375 3.375 0 1 1-6.75
                                     0 3.375 3.375 0 0 1 6.75 0Zm8.25 2.25a2.625
                                     2.625 0 1 1-5.25 0 2.625 2.625 0 0 1 5.25 0Z"/>
                        </svg>
                    </div>
                    <div class="inicio-cap-card__body">
                        <h3 class="inicio-cap-card__name">Gestionar Socios y Contratos</h3>
                        <p class="inicio-cap-card__desc">
                            Inscribe clientes, activa contratos de membresía, actualiza información
                            personal y monitorea los próximos vencimientos.
                        </p>
                    </div>
                    <div class="inicio-cap-card__footer">
                        <span class="inicio-cap-card__module">Módulos: Clientes · Contratos</span>
                    </div>
                </article>

                <%-- Tarjeta 3: Controlar Clases y Horarios --%>
                <article class="inicio-cap-card inicio-cap-card--yellow" role="listitem">
                    <div class="inicio-cap-card__icon" aria-hidden="true">
                        <%-- Ícono calendario --%>
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1
                                     2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18
                                     0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21
                                     18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25
                                     2.25 0 0 1 21 11.25v7.5m-9-6h.008v.008H12v-.008ZM12
                                     15h.008v.008H12V15Zm0 2.25h.008v.008H12v-.008Z"/>
                        </svg>
                    </div>
                    <div class="inicio-cap-card__body">
                        <h3 class="inicio-cap-card__name">Controlar Clases y Horarios</h3>
                        <p class="inicio-cap-card__desc">
                            Define nuevas clases grupales, asigna entrenadores calificados,
                            edita capacidades máximas y supervisa la programación semanal.
                        </p>
                    </div>
                    <div class="inicio-cap-card__footer">
                        <span class="inicio-cap-card__module">Módulos: Horarios · Calendario</span>
                    </div>
                </article>

                <%-- Tarjeta 4: Administrar Personal --%>
                <article class="inicio-cap-card inicio-cap-card--purple" role="listitem">
                    <div class="inicio-cap-card__icon" aria-hidden="true">
                        <%-- Ícono badge / empleado --%>
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
                    <div class="inicio-cap-card__body">
                        <h3 class="inicio-cap-card__name">Administrar Personal</h3>
                        <p class="inicio-cap-card__desc">
                            Gestiona la lista de empleados (entrenadores, recepcionistas,
                            administradores), registra nuevos cargos y controla accesos al sistema.
                        </p>
                    </div>
                    <div class="inicio-cap-card__footer">
                        <span class="inicio-cap-card__module">Módulos: Empleados · Usuarios</span>
                    </div>
                </article>

                <%-- Tarjeta 5: Configurar Membresías --%>
                <article class="inicio-cap-card inicio-cap-card--teal" role="listitem">
                    <div class="inicio-cap-card__icon" aria-hidden="true">
                        <%-- Ícono ticket/membresía --%>
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M16.5 6v.75m0 3v.75m0 3v.75m0 3V18m-9-5.25h5.25M7.5
                                     15h3M3.375 5.25c-.621 0-1.125.504-1.125 1.125v3.026a2.999
                                     2.999 0 0 1 0 5.198v3.026c0 .621.504 1.125 1.125
                                     1.125h17.25c.621 0 1.125-.504 1.125-1.125v-3.026a3
                                     3 0 0 1 0-5.198V6.375c0-.621-.504-1.125-1.125-1.125H3.375Z"/>
                        </svg>
                    </div>
                    <div class="inicio-cap-card__body">
                        <h3 class="inicio-cap-card__name">Configurar Membresías</h3>
                        <p class="inicio-cap-card__desc">
                            Diseña los planes de membresía del gimnasio (Mensual, Trimestral, Anual),
                            ajusta tarifas, duraciones y métodos de pago del servicio.
                        </p>
                    </div>
                    <div class="inicio-cap-card__footer">
                        <span class="inicio-cap-card__module">Módulos: Membresías · Pagos</span>
                    </div>
                </article>

                <%-- Tarjeta 6: Historial de Accesos --%>
                <article class="inicio-cap-card inicio-cap-card--red" role="listitem">
                    <div class="inicio-cap-card__icon" aria-hidden="true">
                        <%-- Ícono reloj / historial --%>
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                        </svg>
                    </div>
                    <div class="inicio-cap-card__body">
                        <h3 class="inicio-cap-card__name">Historial de Accesos</h3>
                        <p class="inicio-cap-card__desc">
                            Monitorea en tiempo real los check-ins de los socios y los reportes
                            de asistencias autorizadas y denegadas en la recepción.
                        </p>
                    </div>
                    <div class="inicio-cap-card__footer">
                        <span class="inicio-cap-card__module">Módulo: Asistencia</span>
                    </div>
                </article>

            </div><%-- /inicio-caps-grid --%>

        </div><%-- /page-content --%>
    </div><%-- /app-main --%>
</div><%-- /app-shell --%>

</body>
</html>
