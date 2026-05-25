<%-- ============================================================
     navbar.jsp  —  MaxFit Sistema de Gestión
     Barra de navegación superior para todas las vistas autenticadas.

     Uso:
       <%@ include file="/WEB-INF/views/includes/navbar.jsp" %>
       (se coloca dentro de .app-main, ANTES de .page-content)

     Estructura HTML esperada del JSP padre:
       <div class="app-main">
         <%@ include file=".../navbar.jsp" %>
         <div class="page-content"> ... </div>
       </div>

     Parámetros de request que puede recibir:
       pageTitle   (String) → título de la sección actual (ej. "Clientes")
       pageSubtitle (String, opcional) → subtítulo o descripción breve

     Datos de sesión que usa:
       sessionScope.userName   → nombre del usuario logueado
       sessionScope.userRole   → rol actual
       sessionScope.userEmail  → email del usuario

     Funcionalidades (sin JS):
       · Muestra el título de la sección actual
       · Muestra el nombre y rol del usuario
       · Botón de logout (form POST a /logout)
       · Flash messages de éxito/error provenientes del controlador
         (successMsg y errorMsg — consumidos por transferirFlashMessages)
     ============================================================ --%>
<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<c:set var="ctx"      value="${pageContext.request.contextPath}"/>
<c:set var="userRole" value="${sessionScope.userRole}"/>

<header class="app-navbar" role="banner">

    <%-- ── Izquierda: título de la sección ───────────────── --%>
    <div class="navbar-section">
        <c:if test="${not empty pageTitle}">
            <h1 class="navbar-page-title">
                <c:out value="${pageTitle}"/>
            </h1>
        </c:if>
        <c:if test="${not empty pageSubtitle}">
            <span class="navbar-page-subtitle">
                <c:out value="${pageSubtitle}"/>
            </span>
        </c:if>
    </div>

    <%-- ── Spacer ─────────────────────────────────────────── --%>
    <div class="navbar-spacer" aria-hidden="true"></div>

    <%-- ── Derecha: usuario + logout ─────────────────────── --%>
    <div class="navbar-actions">

        <%-- Badge del rol --%>
        <span class="navbar-role-badge" aria-label="Tu rol actual">
            <c:choose>
                <c:when test="${userRole eq 'ROL-ADMIN'}">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                         stroke="currentColor" stroke-width="1.8" aria-hidden="true">
                        <path stroke-linecap="round" stroke-linejoin="round"
                              d="M9 12.75 11.25 15 15 9.75m-3-7.036A11.959 11.959 0 0 1 3.598 6
                                 11.99 11.99 0 0 0 3 9.749c0 5.592 3.824 10.29 9 11.623
                                 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196
                                 0-6.1-1.248-8.25-3.285Z"/>
                    </svg>
                    Administrador
                </c:when>
                <c:when test="${userRole eq 'ROL-RECEP'}">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                         stroke="currentColor" stroke-width="1.8" aria-hidden="true">
                        <path stroke-linecap="round" stroke-linejoin="round"
                              d="M15.75 6a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5
                                 0ZM4.501 20.118a7.5 7.5 0 0 1 14.998 0A17.933 17.933
                                 0 0 1 12 21.75c-2.676 0-5.216-.584-7.499-1.632Z"/>
                    </svg>
                    Recepcionista
                </c:when>
                <c:when test="${userRole eq 'ROL-TRAINER'}">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                         stroke="currentColor" stroke-width="1.8" aria-hidden="true">
                        <path stroke-linecap="round" stroke-linejoin="round"
                              d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z"/>
                    </svg>
                    Instructor
                </c:when>
            </c:choose>
        </span>

        <%-- Separador visual --%>
        <div class="navbar-sep" aria-hidden="true"></div>

        <%-- Info del usuario --%>
        <div class="navbar-user" aria-label="Usuario actual">
            <div class="navbar-user__avatar" aria-hidden="true">
                <c:choose>
                    <c:when test="${not empty sessionScope.userName}">
                        ${fn:substring(sessionScope.userName, 0, 1)}
                    </c:when>
                    <c:otherwise>U</c:otherwise>
                </c:choose>
            </div>
            <div class="navbar-user__info">
                <span class="navbar-user__name">
                    <c:out value="${not empty sessionScope.userName ? sessionScope.userName : 'Usuario'}"/>
                </span>
                <span class="navbar-user__email">
                    <c:out value="${not empty sessionScope.userEmail ? sessionScope.userEmail : ''}"/>
                </span>
            </div>
        </div>

        <%-- Botón Cerrar sesión (POST sin JS — form oculto) --%>
        <form action="${ctx}/logout" method="post" class="navbar-logout-form">
            <input type="hidden" name="_csrf" value="${sessionScope._csrfToken}">
            <button type="submit" class="btn btn-ghost btn-sm navbar-logout-btn"
                    aria-label="Cerrar sesión" title="Cerrar sesión">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                     stroke="currentColor" stroke-width="1.8" aria-hidden="true">
                    <path stroke-linecap="round" stroke-linejoin="round"
                          d="M15.75 9V5.25A2.25 2.25 0 0 0 13.5 3h-6a2.25 2.25 0 0
                             0-2.25 2.25v13.5A2.25 2.25 0 0 0 7.5 21h6a2.25 2.25 0
                             0 0 2.25-2.25V15M12 9l-3 3m0 0 3 3m-3-3h12.75"/>
                </svg>
                <span class="navbar-logout-label">Salir</span>
            </button>
        </form>

    </div><%-- /navbar-actions --%>

</header><%-- /app-navbar --%>

<%-- ── Flash messages globales ─────────────────────────────
     Se renderizan justo debajo del navbar, dentro del .app-main,
     para que sean visibles sin importar qué módulo esté activo.
     Los atributos successMsg / errorMsg son "consumidos" (eliminados
     de sesión) por AbstractController.transferirFlashMessages().
     ──────────────────────────────────────────────────────────── --%>
<c:if test="${not empty successMsg or not empty errorMsg}">
    <div class="flash-messages-container" role="region" aria-label="Notificaciones">

        <c:if test="${not empty successMsg}">
            <div class="flash-alert flash-alert--success" role="status" aria-live="polite">
                <svg class="flash-alert__icon" xmlns="http://www.w3.org/2000/svg"
                     fill="none" viewBox="0 0 24 24" stroke="currentColor"
                     stroke-width="2" aria-hidden="true">
                    <path stroke-linecap="round" stroke-linejoin="round"
                          d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                </svg>
                <p class="flash-alert__text">
                    <c:out value="${successMsg}"/>
                </p>
            </div>
        </c:if>

        <c:if test="${not empty errorMsg}">
            <div class="flash-alert flash-alert--error" role="alert" aria-live="assertive">
                <svg class="flash-alert__icon" xmlns="http://www.w3.org/2000/svg"
                     fill="none" viewBox="0 0 24 24" stroke="currentColor"
                     stroke-width="2" aria-hidden="true">
                    <path stroke-linecap="round" stroke-linejoin="round"
                          d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948
                             3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949
                             3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126ZM12
                             15.75h.007v.008H12v-.008Z"/>
                </svg>
                <p class="flash-alert__text">
                    <c:out value="${errorMsg}"/>
                </p>
            </div>
        </c:if>

    </div>
</c:if>

<%-- ── Estilos del Navbar ──────────────────────────────────── --%>
<style>
/* ── Navbar layout ───────────────────────────────────────── */
.app-navbar {
    gap: 0.75rem;
    padding: 0 1.5rem;
}

.navbar-section {
    display: flex;
    align-items: baseline;
    gap: 0.75rem;
    min-width: 0;
}

.navbar-page-title {
    font-family: var(--font-display);
    font-weight: 700;
    font-size: 1.05rem;
    letter-spacing: 0.04em;
    text-transform: uppercase;
    color: var(--clr-text);
    white-space: nowrap;
    line-height: 1;
}

.navbar-page-subtitle {
    font-size: 0.78rem;
    color: var(--clr-text-dim);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
}

.navbar-spacer {
    flex: 1;
}

/* ── Acciones del navbar ──────────────────────────────────── */
.navbar-actions {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    flex-shrink: 0;
}

/* Badge del rol */
.navbar-role-badge {
    display: inline-flex;
    align-items: center;
    gap: 0.35rem;
    padding: 0.28rem 0.7rem;
    border-radius: var(--radius-full);
    font-size: 0.72rem;
    font-weight: 600;
    letter-spacing: 0.04em;
    text-transform: uppercase;
    background: var(--clr-red-subtle);
    color: var(--clr-red);
    border: 1px solid rgba(230,48,39,0.2);
    white-space: nowrap;
}

.navbar-role-badge svg {
    width: 12px;
    height: 12px;
    flex-shrink: 0;
}

/* Separador vertical */
.navbar-sep {
    width: 1px;
    height: 24px;
    background: var(--clr-border);
    flex-shrink: 0;
}

/* Info de usuario */
.navbar-user {
    display: flex;
    align-items: center;
    gap: 0.55rem;
    min-width: 0;
}

.navbar-user__avatar {
    flex-shrink: 0;
    width: 30px;
    height: 30px;
    border-radius: var(--radius-sm);
    background: var(--clr-red);
    color: #fff;
    font-family: var(--font-display);
    font-weight: 700;
    font-size: 0.85rem;
    display: flex;
    align-items: center;
    justify-content: center;
    text-transform: uppercase;
}

.navbar-user__info {
    display: flex;
    flex-direction: column;
    min-width: 0;
}

.navbar-user__name {
    font-size: 0.82rem;
    font-weight: 600;
    color: var(--clr-text);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    max-width: 140px;
    line-height: 1.2;
}

.navbar-user__email {
    font-size: 0.70rem;
    color: var(--clr-text-dim);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    max-width: 140px;
}

/* Botón logout */
.navbar-logout-form {
    margin: 0;
    padding: 0;
    display: inline-flex;
}

.navbar-logout-btn {
    color: var(--clr-text-dim);
    gap: 0.35rem;
}

.navbar-logout-btn:hover {
    color: var(--clr-red);
    background: var(--clr-red-subtle);
    border-color: rgba(230,48,39,0.2);
}

.navbar-logout-btn svg {
    width: 15px;
    height: 15px;
}

/* ── Flash messages container ─────────────────────────────── */
.flash-messages-container {
    padding: 0.85rem 1.5rem 0;
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
}

.flash-messages-container .flash-alert {
    margin-bottom: 0;
}

/* ── Responsive ───────────────────────────────────────────── */
@media (max-width: 768px) {
    .navbar-role-badge { display: none; }
    .navbar-sep        { display: none; }
    .navbar-user__info { display: none; }
    .navbar-logout-label { display: none; }
    .flash-messages-container {
        padding: 0.75rem 1rem 0;
    }
}

@media (max-width: 480px) {
    .navbar-page-subtitle { display: none; }
}
</style>
