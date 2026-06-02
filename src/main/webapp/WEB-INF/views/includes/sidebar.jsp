<%-- ============================================================
     sidebar.jsp  —  MaxFit Sistema de Gestión
     Sidebar con sección "Configuración" colapsable (CSS puro)
     para ROL-ADMIN.  SIN JAVASCRIPT.
     Técnica: checkbox-hack  →  <input hidden> + <label> + ~ selector
     ============================================================ --%>
<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"  uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>

<c:set var="currentUri" value="${pageContext.request.requestURI}"/>
<c:set var="ctx"        value="${pageContext.request.contextPath}"/>
<c:set var="userRole"   value="${sessionScope.userRole}"/>
<c:set var="currentTab" value="${param.tab}"/>

<%--
    ¿El usuario está en alguna ruta que pertenece al grupo Configuración?
    Si es así, el acordeón arranca abierto (checked).
--%>
<c:set var="enConfig"
       value="${fn:contains(currentUri,'/employees')
             or fn:contains(currentUri,'/users')
             or fn:contains(currentUri,'/payment-methods')
             or fn:contains(currentUri,'/tipodocumento')
             or fn:contains(currentUri,'/tipoclase')
             or fn:contains(currentUri,'/cargo')
             or fn:contains(currentUri,'/reports')}"/>

<aside class="app-sidebar" role="navigation" aria-label="Navegación principal">

    <%-- ── Logo ─────────────────────────────────────────────── --%>
    <div class="sidebar-brand">
        <a href="${ctx}/inicio" class="sidebar-brand__link" aria-label="MaxFit inicio">
            <span class="sidebar-brand__wordmark">
                <span class="max">MAX</span><span class="fit">FIT</span>
            </span>
        </a>
        <span class="sidebar-brand__tag">Sistema de Gestión</span>
    </div>

    <nav class="sidebar-nav" role="navigation">

        <%-- ── INICIO / DASHBOARD por rol ─────────────────────── --%>
        <div class="sidebar-nav__group">

            <c:if test="${userRole eq 'ROL-ADMIN'}">
                <a href="${ctx}/inicio"
                   class="sidebar-nav__item ${fn:contains(currentUri,'/inicio') ? 'active' : ''}"
                   aria-label="Inicio">
                    <span class="sidebar-nav__icon" aria-hidden="true">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                             stroke="currentColor" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M2.25 12l8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5
                                     9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125
                                     1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621
                                     0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25"/>
                        </svg>
                    </span>
                    <span class="sidebar-nav__label">Inicio</span>
                </a>
            </c:if>

            <c:if test="${userRole eq 'ROL-RECEP'}">
                <a href="${ctx}/dashboard"
                   class="sidebar-nav__item ${fn:contains(currentUri,'/dashboard') ? 'active' : ''}"
                   aria-label="Dashboard">
                    <span class="sidebar-nav__icon" aria-hidden="true">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                             stroke="currentColor" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M2.25 12l8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5
                                     9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125
                                     1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621
                                     0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25"/>
                        </svg>
                    </span>
                    <span class="sidebar-nav__label">Dashboard</span>
                </a>
            </c:if>

            <c:if test="${userRole eq 'ROL-TRAINER'}">
                <a href="${ctx}/instructor"
                   class="sidebar-nav__item ${fn:contains(currentUri,'/instructor') ? 'active' : ''}"
                   aria-label="Mi Panel">
                    <span class="sidebar-nav__icon" aria-hidden="true">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                             stroke="currentColor" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M2.25 12l8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5
                                     9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125
                                     1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621
                                     0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25"/>
                        </svg>
                    </span>
                    <span class="sidebar-nav__label">Mi Panel</span>
                </a>
            </c:if>

        </div>

        <%-- ── OPERACIONES (Admin + Recep) ─────────────────────── --%>
        <c:if test="${userRole eq 'ROL-ADMIN' or userRole eq 'ROL-RECEP'}">
            <div class="sidebar-nav__group">
                <span class="sidebar-nav__group-label">Operaciones</span>

                <a href="${ctx}/clients"
                   class="sidebar-nav__item ${fn:contains(currentUri,'/clients') ? 'active' : ''}"
                   aria-label="Clientes">
                    <span class="sidebar-nav__icon" aria-hidden="true">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                             stroke="currentColor" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M15 19.128a9.38 9.38 0 0 0 2.625.372 9.337 9.337 0 0
                                     0 4.121-.952 4.125 4.125 0 0 0-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15
                                     19.128v.106A12.318 12.318 0 0 1 8.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375
                                     6.375 0 0 1 11.964-3.07M12 6.375a3.375 3.375 0 1 1-6.75 0 3.375 3.375 0 0 1 6.75
                                     0Zm8.25 2.25a2.625 2.625 0 1 1-5.25 0 2.625 2.625 0 0 1 5.25 0Z"/>
                        </svg>
                    </span>
                    <span class="sidebar-nav__label">Clientes</span>
                </a>

                <a href="${ctx}/contracts"
                   class="sidebar-nav__item ${fn:contains(currentUri,'/contracts') ? 'active' : ''}"
                   aria-label="Contratos">
                    <span class="sidebar-nav__icon" aria-hidden="true">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                             stroke="currentColor" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125 1.125 0
                                     0 1 13.5 7.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H8.25m0
                                     12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125
                                     1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504
                                     1.125-1.125V11.25a9 9 0 0 0-9-9Z"/>
                        </svg>
                    </span>
                    <span class="sidebar-nav__label">Contratos</span>
                </a>

                <a href="${ctx}/attendance"
                   class="sidebar-nav__item ${fn:contains(currentUri,'/attendance') ? 'active' : ''}"
                   aria-label="Asistencia">
                    <span class="sidebar-nav__icon" aria-hidden="true">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                             stroke="currentColor" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                        </svg>
                    </span>
                    <span class="sidebar-nav__label">Asistencia</span>
                </a>

                <a href="${ctx}/memberships"
                   class="sidebar-nav__item ${fn:contains(currentUri,'/memberships') ? 'active' : ''}"
                   aria-label="Membresías">
                    <span class="sidebar-nav__icon" aria-hidden="true">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                             stroke="currentColor" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M2.25 8.25h19.5M2.25 9h19.5m-16.5 5.25h6m-6 2.25h3m-3.75
                                     3h15a2.25 2.25 0 0 0 2.25-2.25V6.75A2.25 2.25 0 0 0
                                     19.5 4.5h-15a2.25 2.25 0 0 0-2.25 2.25v10.5A2.25 2.25
                                     0 0 0 4.5 19.5Z"/>
                        </svg>
                    </span>
                    <span class="sidebar-nav__label">Membresías</span>
                </a>

            </div>
        </c:if>

        <%-- ── CLASES (todos los roles) ────────────────────────── --%>
        <div class="sidebar-nav__group">
            <span class="sidebar-nav__group-label">Clases</span>

            <a href="${ctx}/schedules"
               class="sidebar-nav__item ${fn:contains(currentUri,'/schedules') ? 'active' : ''}"
               aria-label="Horarios">
                <span class="sidebar-nav__icon" aria-hidden="true">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                         stroke="currentColor" stroke-width="1.8">
                        <path stroke-linecap="round" stroke-linejoin="round"
                              d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1
                                 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0
                                 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75m-18 0v-7.5A2.25 2.25 0 0
                                 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5m-9-6h.008v.008H12v-.008Z"/>
                    </svg>
                </span>
                <span class="sidebar-nav__label">Horarios</span>
            </a>

            <a href="${ctx}/calendar"
               class="sidebar-nav__item ${fn:contains(currentUri,'/calendar') ? 'active' : ''}"
               aria-label="Calendario">
                <span class="sidebar-nav__icon" aria-hidden="true">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                         stroke="currentColor" stroke-width="1.8">
                        <path stroke-linecap="round" stroke-linejoin="round"
                              d="M3.75 6A2.25 2.25 0 0 1 6 3.75h2.25A2.25 2.25 0 0 1 10.5 6v2.25a2.25
                                 2.25 0 0 1-2.25 2.25H6a2.25 2.25 0 0 1-2.25-2.25V6ZM3.75 15.75A2.25
                                 2.25 0 0 1 6 13.5h2.25a2.25 2.25 0 0 1 2.25 2.25V18a2.25 2.25 0 0
                                 1-2.25 2.25H6A2.25 2.25 0 0 1 3.75 18v-2.25ZM13.5 6a2.25 2.25 0 0
                                 1 2.25-2.25H18A2.25 2.25 0 0 1 20.25 6v2.25A2.25 2.25 0 0 1 18
                                 10.5h-2.25a2.25 2.25 0 0 1-2.25-2.25V6ZM13.5 15.75a2.25 2.25 0 0
                                 1 2.25-2.25H18a2.25 2.25 0 0 1 2.25 2.25V18A2.25 2.25 0 0 1 18
                                 20.25h-2.25A2.25 2.25 0 0 1 13.5 18v-2.25Z"/>
                    </svg>
                </span>
                <span class="sidebar-nav__label">Calendario</span>
            </a>

        </div>

        <%-- ══════════════════════════════════════════════════════
             ADMINISTRACIÓN — solo ROL-ADMIN
             Solo contiene el botón acordeón "Configuración".
             Dentro del panel van: Empleados, Usuarios y catálogos.

             ORDEN dentro de Configuración:
               1. Empleados        ← gestión de personal
               2. Usuarios         ← gestión de accesos
               3. Tipo Documento   ← catálogo base de personas
               4. Tipo de Clase    ← catálogo base de clases
               5. Cargos           ← catálogo base de RRHH
               6. Métodos de Pago  ← catálogo de cobro
               7. Reportes         ← SIEMPRE AL FINAL
             ══════════════════════════════════════════════════ --%>
        <c:if test="${userRole eq 'ROL-ADMIN'}">

            <div class="sidebar-nav__group">
                <span class="sidebar-nav__group-label">Administración</span>

                <%-- ════════════════════════════════════════════════
                     ACORDEÓN CONFIGURACIÓN — CSS PURO (checkbox-hack)
                     tabindex="-1" evita el scroll involuntario al inicio
                     del sidebar al hacer click en cualquier enlace.
                     ════════════════════════════════════════════ --%>
                <input type="checkbox"
                       id="cfg-toggle"
                       class="cfg-checkbox"
                       tabindex="-1"
                       ${enConfig ? 'checked' : ''}
                       aria-hidden="true"/>

                <label for="cfg-toggle"
                       class="sidebar-nav__item sidebar-nav__accordion-btn"
                       aria-label="Configuración">
                    <span class="sidebar-nav__icon" aria-hidden="true">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                             stroke="currentColor" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0
                                     1.02.398 1.11.94l.213 1.281c.063.374.313.686.645.87.074.04.147.083.22.127.325.196.72.257
                                     1.075.124l1.217-.456a1.125 1.125 0 0 1 1.37.49l1.296 2.247a1.125 1.125 0 0
                                     1-.26 1.431l-1.003.827c-.293.241-.438.613-.43.992a7.723 7.723 0 0 1 0
                                     .255c-.008.378.137.75.43.991l1.004.827c.424.35.534.955.26 1.43l-1.298
                                     2.247a1.125 1.125 0 0 1-1.369.491l-1.217-.456c-.355-.133-.75-.072-1.076.124a6.47
                                     6.47 0 0 1-.22.128c-.331.183-.581.495-.644.869l-.213 1.281c-.09.543-.56.94-1.11.94h-2.594c-.55
                                     0-1.019-.398-1.11-.94l-.213-1.281c-.062-.374-.312-.686-.644-.87a6.52 6.52 0 0
                                     1-.22-.127c-.325-.196-.72-.257-1.076-.124l-1.217.456a1.125 1.125 0 0
                                     1-1.369-.49l-1.297-2.247a1.125 1.125 0 0 1 .26-1.431l1.004-.827c.292-.24.437-.613.43-.991a6.932
                                     6.932 0 0 1 0-.255c.007-.38-.138-.751-.43-.992l-1.004-.827a1.125 1.125 0 0
                                     1-.26-1.43l1.297-2.247a1.125 1.125 0 0 1 1.37-.491l1.216.456c.356.133.751.072
                                     1.076-.124.072-.044.146-.086.22-.128.332-.183.582-.495.644-.869l.214-1.28Z"/>
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z"/>
                        </svg>
                    </span>
                    <span class="sidebar-nav__label">Configuración</span>
                    <span class="cfg-chevron" aria-hidden="true">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                             stroke="currentColor" stroke-width="2.2">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="m8.25 4.5 7.5 7.5-7.5 7.5"/>
                        </svg>
                    </span>
                </label>

                <%-- Panel colapsable — hermano inmediato del checkbox --%>
                <div class="cfg-panel">

                    <%-- 1. Empleados --%>
                    <a href="${ctx}/employees"
                       class="sidebar-nav__item sidebar-nav__sub-item
                         ${fn:contains(currentUri,'/employees') ? 'active' : ''}"
                       aria-label="Empleados">
                        <span class="sidebar-nav__icon" aria-hidden="true">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                                 stroke="currentColor" stroke-width="1.8">
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
                        </span>
                        <span class="sidebar-nav__label">Empleados</span>
                    </a>

                    <%-- 2. Usuarios --%>
                    <a href="${ctx}/users"
                       class="sidebar-nav__item sidebar-nav__sub-item
                         ${fn:contains(currentUri,'/users') ? 'active' : ''}"
                       aria-label="Usuarios">
                        <span class="sidebar-nav__icon" aria-hidden="true">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                                 stroke="currentColor" stroke-width="1.8">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                      d="M15.75 5.25a3 3 0 0 1 3 3m3 0a6 6 0 0 1-7.029 5.912c-.563-.097-1.159.026-1.563.43L10.5
                                         17.25H8.25v2.25H6v2.25H2.25v-2.818c0-.597.237-1.17.659-1.591l6.499-6.499c.404-.404.527-1
                                         .43-1.563A6 6 0 0 1 21.75 8.25Z"/>
                            </svg>
                        </span>
                        <span class="sidebar-nav__label">Usuarios</span>
                    </a>

                    <%-- 3. Tipo de Documento --%>
<a href="${ctx}/tipodocumento"
   class="sidebar-nav__item sidebar-nav__sub-item
     ${fn:contains(currentUri,'/tipodocumento') ? 'active' : ''}"
   aria-label="Tipo Documento">
    <span class="sidebar-nav__icon" aria-hidden="true">
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
             stroke="currentColor" stroke-width="1.8">
            <path stroke-linecap="round" stroke-linejoin="round"
                  d="M15 9h3.75M15 12h3.75M15 15h3.75M4.5 7.5a3 3 0 0
                     1 3-3h9a3 3 0 0 1 3 3v9a3 3 0 0 1-3 3h-9a3 3 0 0
                     1-3-3v-9ZM12 6.375a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z"/>
        </svg>
    </span>
    <span class="sidebar-nav__label">Tipo Documento</span>
</a>

<%-- 4. Tipo de Clase --%>
<a href="${ctx}/tipoclase"
   class="sidebar-nav__item sidebar-nav__sub-item
     ${fn:contains(currentUri,'/tipoclase') ? 'active' : ''}"
   aria-label="Tipo de Clase">
    <span class="sidebar-nav__icon" aria-hidden="true">
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
             stroke="currentColor" stroke-width="1.8">
            <path stroke-linecap="round" stroke-linejoin="round"
                  d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z"/>
        </svg>
    </span>
    <span class="sidebar-nav__label">Tipo de Clase</span>
</a>

<%-- 5. Cargos --%>
<a href="${ctx}/cargo"
   class="sidebar-nav__item sidebar-nav__sub-item
     ${fn:contains(currentUri,'/cargo') ? 'active' : ''}"
   aria-label="Cargos">
    <span class="sidebar-nav__icon" aria-hidden="true">
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
             stroke="currentColor" stroke-width="1.8">
            <path stroke-linecap="round" stroke-linejoin="round"
                  d="M20.25 14.15v4.25c0 1.094-.787 2.036-1.872 2.18-2.087.277-4.216.42-6.378.42s-4.291-.143-6.378-.42c-1.085-.144-1.872-1.086-1.872-2.18v-4.25m16.5
                     0a2.18 2.18 0 0 0 .75-1.661V8.706c0-1.081-.768-2.015-1.837-2.175a48.114
                     48.114 0 0 0-3.413-.387m4.5 8.006c-.194.165-.42.295-.673.38A23.978
                     23.978 0 0 1 12 15.75c-2.648 0-5.195-.429-7.577-1.22a2.016 2.016
                     0 0 1-.673-.38m0 0A2.18 2.18 0 0 1 3 12.489V8.706c0-1.081.768-2.015
                     1.837-2.175a48.111 48.111 0 0 1 3.413-.387m7.5 0V5.25A2.25 2.25 0
                     0 0 13.5 3h-3a2.25 2.25 0 0 0-2.25 2.25v.894m7.5 0a48.667 48.667
                     0 0 0-7.5 0M12 12.75h.008v.008H12v-.008Z"/>
    </svg>
    </span>
    <span class="sidebar-nav__label">Cargos</span>
</a>

                    <%-- 6. Métodos de Pago --%>
                    <a href="${ctx}/payment-methods"
                       class="sidebar-nav__item sidebar-nav__sub-item
                         ${fn:contains(currentUri,'/payment-methods') ? 'active' : ''}"
                       aria-label="Métodos de Pago">
                        <span class="sidebar-nav__icon" aria-hidden="true">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                                 stroke="currentColor" stroke-width="1.8">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                      d="M2.25 8.25h19.5M2.25 9h19.5m-16.5 5.25h6m-6 2.25h3m-3.75
                                         3h15a2.25 2.25 0 0 0 2.25-2.25V6.75A2.25 2.25 0 0 0
                                         19.5 4.5h-15a2.25 2.25 0 0 0-2.25 2.25v10.5A2.25 2.25
                                         0 0 0 4.5 19.5Z"/>
                            </svg>
                        </span>
                        <span class="sidebar-nav__label">Métodos de Pago</span>
                    </a>

                    <%-- 7. Reportes — SIEMPRE AL FINAL --%>
                    <a href="${ctx}/reports"
                       class="sidebar-nav__item sidebar-nav__sub-item
                         ${fn:contains(currentUri,'/reports') ? 'active' : ''}"
                       aria-label="Reportes">
                        <span class="sidebar-nav__icon" aria-hidden="true">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                                 stroke="currentColor" stroke-width="1.8">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                      d="M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504
                                         1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125
                                         1.125 0 0 1 3 19.875v-6.75ZM9.75 8.625c0-.621.504-1.125
                                         1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0
                                         .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 0
                                         1-1.125-1.125V8.625ZM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496
                                         3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125
                                         1.125 0 0 1-1.125-1.125V4.125Z"/>
                            </svg>
                        </span>
                        <span class="sidebar-nav__label">Reportes</span>
                    </a>

                </div><%-- /cfg-panel --%>

            </div><%-- /sidebar-nav__group Administración --%>

        </c:if>

    </nav>

    <div class="sidebar-footer">
        <span class="sidebar-footer__version">MaxFit v1.0</span>
    </div>

</aside>

<style>
/* ════════════════════════════════════════════════════════════
   SIDEBAR — estilos completos
   ════════════════════════════════════════════════════════════ */

/* ── Brand ──────────────────────────────────────────────── */
.sidebar-brand {
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    justify-content: center;
    height: var(--navbar-height);
    padding: 0 1.1rem;
    border-bottom: 1px solid var(--clr-sidebar-border);
    flex-shrink: 0;
}

.sidebar-brand__link {
    text-decoration: none;
    line-height: 1;
}

.sidebar-brand__wordmark {
    font-family: var(--font-display);
    font-weight: 800;
    font-size: 1.5rem;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    user-select: none;
}

.sidebar-brand__wordmark .max { color: var(--clr-text); }
.sidebar-brand__wordmark .fit { color: var(--clr-red); }

.sidebar-brand__tag {
    font-size: 0.62rem;
    font-weight: 500;
    letter-spacing: 0.18em;
    text-transform: uppercase;
    color: var(--clr-text-dim);
    margin-top: 0.25rem;
}

/* ── Navegación ─────────────────────────────────────────── */
.sidebar-nav {
    flex: 1;
    overflow-y: auto;
    overflow-x: hidden;
    padding: 0.5rem 0.65rem;
    scrollbar-width: none;
    display: flex;
    flex-direction: column;
    gap: 0.15rem;
}

.sidebar-nav::-webkit-scrollbar { display: none; }

.sidebar-nav__group {
    display: flex;
    flex-direction: column;
    gap: 0.1rem;
    margin-bottom: 0.35rem;
}

.sidebar-nav__group-label {
    font-size: 0.62rem;
    font-weight: 700;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: var(--clr-text-dim);
    padding: 0.65rem 0.6rem 0.28rem;
}

.sidebar-nav__group + .sidebar-nav__group {
    border-top: 1px solid var(--clr-sidebar-border);
    padding-top: 0.25rem;
}

.sidebar-nav__item {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    padding: 0.58rem 0.75rem;
    border-radius: var(--radius-md);
    color: var(--clr-text-muted);
    text-decoration: none;
    font-size: 0.84rem;
    font-weight: 500;
    transition: background var(--transition), color var(--transition);
    position: relative;
    min-width: 0;
    white-space: nowrap;
}

.sidebar-nav__item:hover {
    background: var(--clr-surface-2);
    color: var(--clr-text);
}

.sidebar-nav__item.active {
    background: var(--clr-red-subtle);
    color: var(--clr-red);
    font-weight: 600;
}

.sidebar-nav__item.active::before {
    content: '';
    position: absolute;
    left: 0;
    top: 50%;
    transform: translateY(-50%);
    width: 3px;
    height: 60%;
    background: var(--clr-red);
    border-radius: 0 2px 2px 0;
}

.sidebar-nav__icon {
    flex-shrink: 0;
    width: 18px;
    height: 18px;
    display: flex;
    align-items: center;
    justify-content: center;
}

.sidebar-nav__icon svg {
    width: 18px;
    height: 18px;
}

.sidebar-nav__label {
    overflow: hidden;
    text-overflow: ellipsis;
    flex: 1;
    transition: opacity var(--transition);
}

/* ── Footer ─────────────────────────────────────────────── */
.sidebar-footer {
    padding: 0.85rem 1.1rem;
    border-top: 1px solid var(--clr-sidebar-border);
    flex-shrink: 0;
}

.sidebar-footer__version {
    font-size: 0.68rem;
    color: var(--clr-text-dim);
    letter-spacing: 0.06em;
}

/* ════════════════════════════════════════════════════════════
   ACORDEÓN CONFIGURACIÓN — CSS PURO (checkbox-hack)
   ════════════════════════════════════════════════════════════
   Estructura en el DOM (dentro del .sidebar-nav__group):

     <input  id="cfg-toggle"  type="checkbox"  class="cfg-checkbox"  tabindex="-1">
     <label  for="cfg-toggle" class="... sidebar-nav__accordion-btn">
     <div    class="cfg-panel">
       <a ...> sub-ítem 1 </a>
       ...
     </div>

   El selector CSS  .cfg-checkbox:checked ~ .cfg-panel  activa el panel.
   tabindex="-1" en el checkbox evita el scroll involuntario al inicio.
   ════════════════════════════════════════════════════════════ */

/* Checkbox invisible — ocupa 0px pero sigue siendo funcional */
.cfg-checkbox {
    position: absolute;
    opacity: 0;
    pointer-events: none;
    width: 0;
    height: 0;
    margin: 0;
}

/* El <label> actúa como botón; reutiliza el estilo base de ítem */
.sidebar-nav__accordion-btn {
    cursor: pointer;
    user-select: none;
}

/* Chevron — apunta a la derecha (panel cerrado) */
.cfg-chevron {
    flex-shrink: 0;
    width: 14px;
    height: 14px;
    margin-left: auto;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: transform var(--transition, 220ms ease);
}

.cfg-chevron svg {
    width: 14px;
    height: 14px;
}

/* Rotar chevron 90° cuando el panel está abierto */
.cfg-checkbox:checked ~ .sidebar-nav__accordion-btn .cfg-chevron {
    transform: rotate(90deg);
}

/* Resaltar el botón Configuración cuando el panel está abierto */
.cfg-checkbox:checked ~ .sidebar-nav__accordion-btn {
    color: var(--clr-text);
    background: var(--clr-surface-2);
}

/* ── Panel colapsable ──────────────────────────────────── */
/* Estado cerrado: altura 0, invisible */
.cfg-panel {
    display: flex;
    flex-direction: column;
    gap: 0.1rem;
    overflow: hidden;
    max-height: 0;
    opacity: 0;
    transition:
        max-height 280ms cubic-bezier(0.4, 0, 0.2, 1),
        opacity    200ms ease;
}

/* Estado abierto: cuando el checkbox hermano está checked */
.cfg-checkbox:checked ~ .cfg-panel {
    /* 7 ítems × ~42px + padding = valor generoso */
    max-height: 500px;
    opacity: 1;
    transition:
        max-height 320ms cubic-bezier(0.4, 0, 0.2, 1),
        opacity    220ms ease 50ms;
}

/* Sub-ítems: sangría + línea guía izquierda */
.sidebar-nav__sub-item {
    padding-left: 1.65rem;
}

.sidebar-nav__sub-item::after {
    content: '';
    position: absolute;
    left: 0.88rem;
    top: 50%;
    transform: translateY(-50%);
    width: 1px;
    height: 55%;
    background: var(--clr-sidebar-border, rgba(255,255,255,.1));
    border-radius: 1px;
}

/* ── Responsive ≤ 900px → solo íconos ───────────────────── */
@media (max-width: 900px) {
    .sidebar-brand__tag,
    .sidebar-nav__label,
    .sidebar-nav__group-label,
    .sidebar-footer__version,
    .cfg-chevron {
        display: none;
    }

    .sidebar-brand {
        align-items: center;
        padding: 0;
        justify-content: center;
    }

    .sidebar-brand__wordmark { font-size: 1.1rem; }

    .sidebar-nav {
        padding: 0.5rem 0.4rem;
        align-items: center;
    }

    .sidebar-nav__item {
        justify-content: center;
        padding: 0.65rem;
        width: 40px;
        height: 40px;
        gap: 0;
    }

    .sidebar-nav__item.active::before {
        left: -1px;
        height: 50%;
    }

    .sidebar-nav__group + .sidebar-nav__group {
        border-top: none;
        padding-top: 0;
    }

    /* En modo icono el panel Configuración siempre visible */
    .cfg-panel {
        max-height: 500px !important;
        opacity: 1 !important;
    }

    /* Quitar sangría y línea guía en modo icono */
    .sidebar-nav__sub-item { padding-left: 0.65rem; }
    .sidebar-nav__sub-item::after { display: none; }
}
</style>