<%-- ============================================================
     sidebar.jsp  —  MaxFit Sistema de Gestión
     CORRECCIONES:
       1. Agregado taglib fn (faltaba — causaba error silencioso)
       2. Reemplazado currentUri.contains() por fn:contains()
          (.contains() no existe en EL/JSTL estándar)
       3. Breakpoint colapsado bajado de 1024px a 900px
     ============================================================ --%>
<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"  uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>

<c:set var="currentUri" value="${pageContext.request.requestURI}"/>
<c:set var="ctx"        value="${pageContext.request.contextPath}"/>
<c:set var="userRole"   value="${sessionScope.userRole}"/>

<aside class="app-sidebar" role="navigation" aria-label="Navegación principal">

    <%-- ── Logo / marca ─────────────────────────────────── --%>
    <div class="sidebar-brand">
        <a href="${ctx}/inicio" class="sidebar-brand__link" aria-label="MaxFit inicio">
            <span class="sidebar-brand__wordmark">
                <span class="max">MAX</span><span class="fit">FIT</span>
            </span>
        </a>
        <span class="sidebar-brand__tag">Sistema de Gestión</span>
    </div>

    <%-- ── Perfil compacto del usuario ──────────────────── --%>
    <div class="sidebar-profile">
        <div class="sidebar-profile__avatar" aria-hidden="true">
            <c:choose>
                <c:when test="${not empty sessionScope.userName}">
                    <c:out value="${fn:substring(sessionScope.userName, 0, 1)}"/>
                </c:when>
                <c:otherwise>U</c:otherwise>
            </c:choose>
        </div>
        <div class="sidebar-profile__info">
            <span class="sidebar-profile__name">
                <c:out value="${not empty sessionScope.userName ? sessionScope.userName : 'Usuario'}"/>
            </span>
            <span class="sidebar-profile__role">
                <c:choose>
                    <c:when test="${userRole eq 'ROL-ADMIN'}">Administrador</c:when>
                    <c:when test="${userRole eq 'ROL-RECEP'}">Recepcionista</c:when>
                    <c:when test="${userRole eq 'ROL-TRAINER'}">Instructor</c:when>
                    <c:otherwise>Usuario</c:otherwise>
                </c:choose>
            </span>
        </div>
    </div>

    <%-- ── Navegación ────────────────────────────────────── --%>
    <nav class="sidebar-nav" role="navigation">

        <%-- GRUPO: Dashboard / Inicio según rol --%>
        <div class="sidebar-nav__group">

            <c:if test="${userRole eq 'ROL-ADMIN'}">
                <a href="${ctx}/inicio"
                   class="sidebar-nav__item ${fn:contains(currentUri, '/inicio') ? 'active' : ''}"
                   aria-label="Inicio administrativo">
                    <span class="sidebar-nav__icon" aria-hidden="true">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                             stroke="currentColor" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M2.25 12l8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75
                                     12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125
                                     1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621
                                     0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25"/>
                        </svg>
                    </span>
                    <span class="sidebar-nav__label">Inicio</span>
                </a>
            </c:if>

            <c:if test="${userRole eq 'ROL-RECEP'}">
                <a href="${ctx}/dashboard"
                   class="sidebar-nav__item ${fn:contains(currentUri, '/dashboard') ? 'active' : ''}"
                   aria-label="Dashboard de recepción">
                    <span class="sidebar-nav__icon" aria-hidden="true">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                             stroke="currentColor" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M2.25 12l8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75
                                     12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125
                                     1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621
                                     0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25"/>
                        </svg>
                    </span>
                    <span class="sidebar-nav__label">Dashboard</span>
                </a>
            </c:if>

            <c:if test="${userRole eq 'ROL-TRAINER'}">
                <a href="${ctx}/instructor"
                   class="sidebar-nav__item ${fn:contains(currentUri, '/instructor') ? 'active' : ''}"
                   aria-label="Panel del instructor">
                    <span class="sidebar-nav__icon" aria-hidden="true">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                             stroke="currentColor" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M2.25 12l8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75
                                     12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125
                                     1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621
                                     0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25"/>
                        </svg>
                    </span>
                    <span class="sidebar-nav__label">Mi Panel</span>
                </a>
            </c:if>

        </div>

        <%-- GRUPO: Operaciones (Admin + Recep) --%>
        <c:if test="${userRole eq 'ROL-ADMIN' or userRole eq 'ROL-RECEP'}">
            <div class="sidebar-nav__group">
                <span class="sidebar-nav__group-label">Operaciones</span>

                <a href="${ctx}/clients"
                   class="sidebar-nav__item ${fn:contains(currentUri, '/clients') ? 'active' : ''}"
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
                   class="sidebar-nav__item ${fn:contains(currentUri, '/contracts') ? 'active' : ''}"
                   aria-label="Contratos">
                    <span class="sidebar-nav__icon" aria-hidden="true">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                             stroke="currentColor" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125 1.125 0
                                     0 1 13.5 7.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H8.25m0
                                     12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125
                                     1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0
                                     1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z"/>
                        </svg>
                    </span>
                    <span class="sidebar-nav__label">Contratos</span>
                </a>

                <a href="${ctx}/attendance"
                   class="sidebar-nav__item ${fn:contains(currentUri, '/attendance') ? 'active' : ''}"
                   aria-label="Control de asistencia">
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
                   class="sidebar-nav__item ${fn:contains(currentUri, '/memberships') ? 'active' : ''}"
                   aria-label="Planes de membresía">
                    <span class="sidebar-nav__icon" aria-hidden="true">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                             stroke="currentColor" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M2.25 8.25h19.5M2.25 9h19.5m-16.5 5.25h6m-6 2.25h3m-3.75
                                     3h15a2.25 2.25 0 0 0 2.25-2.25V6.75A2.25 2.25 0 0 0
                                     19.5 4.5h-15a2.25 2.25 0 0 0-2.25 2.25v10.5A2.25 2.25 0
                                     0 0 4.5 19.5Z"/>
                        </svg>
                    </span>
                    <span class="sidebar-nav__label">Membresías</span>
                </a>

            </div>
        </c:if>

        <%-- GRUPO: Clases (todos los roles) --%>
        <div class="sidebar-nav__group">
            <span class="sidebar-nav__group-label">Clases</span>

            <a href="${ctx}/schedules"
               class="sidebar-nav__item ${fn:contains(currentUri, '/schedules') ? 'active' : ''}"
               aria-label="Gestión de clases y horarios">
                <span class="sidebar-nav__icon" aria-hidden="true">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                         stroke="currentColor" stroke-width="1.8">
                        <path stroke-linecap="round" stroke-linejoin="round"
                              d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1
                                 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18
                                 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0
                                 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25
                                 2.25 0 0 1 21 11.25v7.5m-9-6h.008v.008H12v-.008ZM12
                                 15h.008v.008H12V15Zm0 2.25h.008v.008H12v-.008ZM9.75
                                 15h.008v.008H9.75V15Zm0 2.25h.008v.008H9.75v-.008ZM7.5
                                 15h.008v.008H7.5V15Zm0 2.25h.008v.008H7.5v-.008Zm6.75-4.5h.008v.008h-.008v-.008Zm0
                                 2.25h.008v.008h-.008V15Zm0 2.25h.008v.008h-.008v-.008Zm2.25-4.5h.008v.008H16.5v-.008Zm0
                                 2.25h.008v.008H16.5V15Z"/>
                    </svg>
                </span>
                <span class="sidebar-nav__label">Horarios</span>
            </a>

            <a href="${ctx}/calendar"
               class="sidebar-nav__item ${fn:contains(currentUri, '/calendar') ? 'active' : ''}"
               aria-label="Vista de calendario semanal">
                <span class="sidebar-nav__icon" aria-hidden="true">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                         stroke="currentColor" stroke-width="1.8">
                        <path stroke-linecap="round" stroke-linejoin="round"
                              d="M3.75 6A2.25 2.25 0 0 1 6 3.75h2.25A2.25 2.25 0 0
                                 1 10.5 6v2.25a2.25 2.25 0 0 1-2.25 2.25H6a2.25 2.25
                                 0 0 1-2.25-2.25V6ZM3.75 15.75A2.25 2.25 0 0 1 6
                                 13.5h2.25a2.25 2.25 0 0 1 2.25 2.25V18a2.25 2.25 0
                                 0 1-2.25 2.25H6A2.25 2.25 0 0 1 3.75 18v-2.25ZM13.5
                                 6a2.25 2.25 0 0 1 2.25-2.25H18A2.25 2.25 0 0 1
                                 20.25 6v2.25A2.25 2.25 0 0 1 18 10.5h-2.25a2.25 2.25
                                 0 0 1-2.25-2.25V6ZM13.5 15.75a2.25 2.25 0 0 1
                                 2.25-2.25H18a2.25 2.25 0 0 1 2.25 2.25V18A2.25 2.25
                                 0 0 1 18 20.25h-2.25A2.25 2.25 0 0 1 13.5 18v-2.25Z"/>
                    </svg>
                </span>
                <span class="sidebar-nav__label">Calendario</span>
            </a>

        </div>

        <%-- GRUPO: Administración (solo Admin) --%>
        <c:if test="${userRole eq 'ROL-ADMIN'}">
            <div class="sidebar-nav__group">
                <span class="sidebar-nav__group-label">Administración</span>

                <a href="${ctx}/employees"
                   class="sidebar-nav__item ${fn:contains(currentUri, '/employees') ? 'active' : ''}"
                   aria-label="Gestión de empleados">
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

                <a href="${ctx}/users"
                   class="sidebar-nav__item ${fn:contains(currentUri, '/users') ? 'active' : ''}"
                   aria-label="Gestión de usuarios del sistema">
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

                <a href="${ctx}/payment-methods"
                   class="sidebar-nav__item ${fn:contains(currentUri, '/payment-methods') ? 'active' : ''}"
                   aria-label="Métodos de pago">
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

                <a href="${ctx}/reports"
                   class="sidebar-nav__item ${fn:contains(currentUri, '/reports') ? 'active' : ''}"
                   aria-label="Reportes del sistema">
                    <span class="sidebar-nav__icon" aria-hidden="true">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                             stroke="currentColor" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0
                                     1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375
                                     21h-2.25A1.125 1.125 0 0 1 3 19.875v-6.75ZM9.75
                                     8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0
                                     1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125
                                     1.125h-2.25a1.125 1.125 0 0 1-1.125-1.125V8.625ZM16.5
                                     4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496 3
                                     21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125
                                     1.125h-2.25a1.125 1.125 0 0 1-1.125-1.125V4.125Z"/>
                        </svg>
                    </span>
                    <span class="sidebar-nav__label">Reportes</span>
                </a>

            </div>
        </c:if>

    </nav>

    <%-- ── Zona inferior: versión ────────────────────────── --%>
    <div class="sidebar-footer">
        <span class="sidebar-footer__version">MaxFit v1.0</span>
    </div>

</aside>

<style>
/* ── Sidebar Brand ───────────────────────────────────────── */
.sidebar-brand {
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    padding: 1.25rem 1.1rem 0.9rem;
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

/* ── Perfil compacto ──────────────────────────────────────── */
.sidebar-profile {
    display: flex;
    align-items: center;
    gap: 0.65rem;
    padding: 0.85rem 1.1rem;
    margin: 0.5rem 0.65rem;
    border-radius: var(--radius-md);
    background: var(--clr-surface);
    border: 1px solid var(--clr-border-light);
    flex-shrink: 0;
    overflow: hidden;
    min-width: 0;
}

.sidebar-profile__avatar {
    flex-shrink: 0;
    width: 32px;
    height: 32px;
    border-radius: var(--radius-sm);
    background: var(--clr-red);
    color: #fff;
    font-family: var(--font-display);
    font-weight: 700;
    font-size: 0.95rem;
    display: flex;
    align-items: center;
    justify-content: center;
    text-transform: uppercase;
    letter-spacing: 0;
}

.sidebar-profile__info {
    display: flex;
    flex-direction: column;
    min-width: 0;
    overflow: hidden;
}

.sidebar-profile__name {
    font-size: 0.82rem;
    font-weight: 600;
    color: var(--clr-text);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    line-height: 1.3;
}

.sidebar-profile__role {
    font-size: 0.70rem;
    color: var(--clr-text-dim);
    white-space: nowrap;
    letter-spacing: 0.02em;
}

/* ── Navegación ──────────────────────────────────────────── */
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
    font-size: 0.64rem;
    font-weight: 700;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: var(--clr-text-dim);
    padding: 0.65rem 0.6rem 0.3rem;
}

.sidebar-nav__item {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    padding: 0.6rem 0.75rem;
    border-radius: var(--radius-md);
    color: var(--clr-text-muted);
    text-decoration: none;
    font-size: 0.85rem;
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
    transition: opacity var(--transition);
}

/* ── Footer del sidebar ───────────────────────────────────── */
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

/* ── Responsive ─────────────────────────────────────────────
   > 900px  → sidebar completo con texto
   ≤ 900px  → solo íconos (colapsado)
   NUNCA se oculta con translateX — siempre visible
   ────────────────────────────────────────────────────────── */
@media (max-width: 900px) {
    .sidebar-brand__tag,
    .sidebar-profile__info,
    .sidebar-nav__label,
    .sidebar-nav__group-label,
    .sidebar-footer__version {
        display: none;
    }

    .sidebar-brand {
        align-items: center;
        padding: 1.1rem 0;
    }

    .sidebar-brand__wordmark {
        font-size: 1.1rem;
    }

    .sidebar-profile {
        justify-content: center;
        padding: 0.65rem;
        margin: 0.5rem 0.4rem;
    }

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
}
</style>
