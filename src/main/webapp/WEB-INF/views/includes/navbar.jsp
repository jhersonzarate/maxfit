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

        <%-- Badge de rol eliminado: el rol ya se deduce del contexto del sistema.
             El nombre + email del usuario son suficiente identidad en el navbar.
             (Fuente: Nielsen Norman Group — "Avoid redundant labels") --%>

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
     Toasts flotantes en esquina inferior derecha.
     Los atributos successMsg / errorMsg son "consumidos" (eliminados
     de sesión) por AbstractController.transferirFlashMessages().
     ──────────────────────────────────────────────────────────── --%>
<c:if test="${not empty successMsg or not empty errorMsg}">
    <div class="flash-messages-modal-container" style="position: fixed; bottom: 20px; right: 20px; z-index: 9999; pointer-events: none; display: flex; flex-direction: column; gap: 10px;">

        <c:if test="${not empty successMsg}">
            <div class="flash-modal-card" style="background: var(--clr-surface); border: 1px solid var(--clr-border-light); border-left: 4px solid #34d399; border-radius: var(--radius-md); width: 340px; padding: 1rem; box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.3); pointer-events: auto; animation: slideInBottomRight 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275) forwards; display: flex; align-items: center; gap: 1rem;">
                <div style="flex-shrink: 0; width: 42px; height: 42px; border-radius: 50%; background: rgba(52,211,153,0.1); display: flex; align-items: center; justify-content: center;">
                    <svg style="color: #34d399; width: 22px; height: 22px;" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="3">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                    </svg>
                </div>
                <div style="text-align: left;">
                    <h4 style="font-family: var(--font-display); font-size: 1rem; font-weight: 700; color: var(--clr-text); margin: 0 0 0.25rem 0;">¡Éxito!</h4>
                    <p style="color: var(--clr-text-dim); font-size: 0.85rem; line-height: 1.4; margin: 0;"><c:out value="${successMsg}"/></p>
                </div>
            </div>
        </c:if>

        <c:if test="${not empty errorMsg}">
            <div class="flash-modal-card" style="background: var(--clr-surface); border: 1px solid var(--clr-border-light); border-left: 4px solid #fbbf24; border-radius: var(--radius-md); width: 340px; padding: 1rem; box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.3); pointer-events: auto; animation: slideInBottomRight 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275) forwards; display: flex; align-items: center; gap: 1rem;">
                <div style="flex-shrink: 0; width: 42px; height: 42px; border-radius: 50%; background: rgba(251,191,36,0.1); display: flex; align-items: center; justify-content: center;">
                    <span style="font-size: 1.7rem; line-height: 1; font-family: var(--font-display); color: #fbbf24; font-weight: bold; margin-top: -2px;">!</span>
                </div>
                <div style="text-align: left;">
                    <h4 style="font-family: var(--font-display); font-size: 1rem; font-weight: 700; color: var(--clr-text); margin: 0 0 0.25rem 0;">¡Atención!</h4>
                    <p style="color: var(--clr-text-dim); font-size: 0.85rem; line-height: 1.4; margin: 0;"><c:out value="${errorMsg}"/></p>
                </div>
            </div>
        </c:if>

    </div>

    <script>
        document.addEventListener("DOMContentLoaded", function() {
            const flashContainer = document.querySelector('.flash-messages-modal-container');
            const flashCard = document.querySelector('.flash-modal-card');
            if (flashContainer && flashCard) {
                setTimeout(() => {
                    flashCard.style.animation = 'slideOutBottomRight 0.4s ease-in forwards';
                    setTimeout(() => {
                        flashContainer.remove();
                    }, 400);
                }, 5000);
            }
        });
    </script>
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

/* .navbar-role-badge y .navbar-sep eliminados — sin uso */

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
    .navbar-user__info { display: none; }
    .navbar-logout-label { display: none; }
    .flash-messages-container {
        padding: 0.75rem 1rem 0;
    }
}

@media (max-width: 480px) {
    .navbar-page-subtitle { display: none; }
}

@keyframes slideInBottomRight {
    0% { transform: translateX(120%); opacity: 0; }
    100% { transform: translateX(0); opacity: 1; }
}
@keyframes slideOutBottomRight {
    0% { transform: translateX(0); opacity: 1; }
    100% { transform: translateX(120%); opacity: 0; }
}
</style>
