<%--============================================================payment-methods.jsp — MaxFit Sistema de Gestión Módulo
    de gestión de métodos de pago del sistema. Servlet: PaymentMethodsController.java → GET/POST /payment-methods
    Acceso: Solo ROL-ADMIN (RoleFilter) ── Atributos de request ───────────────────────────────── Vista lista (única
    vista): metodos (List<MetodoPago>) → todos: activos e inactivos
    totalMetodos (int) → total de métodos
    totalActivos (long) → métodos con estado 'activo'
    totalInactivos (long) → métodos con estado 'inactivo'

    Acción POST:
    action=toggle + id → activa o desactiva el método indicado
    Solo admin puede ejecutarla (RoleFilter)
    Restricción: no se puede desactivar el único método activo.

    Flash (via transferirFlashMessages en doGet):
    successMsg / errorMsg

    Sesión:
    sessionScope.userRole → ROL-ADMIN (garantizado por RoleFilter)

    Catálogo fijo de IDs:
    PAY-EFECTIVO, PAY-VISA, PAY-MASTERCARD,
    PAY-YAPE, PAY-PLIN, PAY-TRANSFER
    ============================================================ --%>
    <%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
        <%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
            <%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
                <!DOCTYPE html>
                <html lang="es">

                <head>
                    <%@ include file="/WEB-INF/views/includes/head-common.jsp" %>
                        <c:set var="pageTitle" value="Métodos de Pago" scope="request" />
                        <link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/modules.css">

                        <style>
                            /* ══════════════════════════════════════════════════════
           ESTILOS ESPECÍFICOS — MÓDULO DE MÉTODOS DE PAGO
           ══════════════════════════════════════════════════════ */

                            /* ── Grid de tarjetas de métodos ─────────────────────── */
                            .pm-grid {
                                display: grid;
                                grid-template-columns: repeat(auto-fill, minmax(290px, 1fr));
                                gap: 1rem;
                            }

                            /* ── Tarjeta individual de método de pago ──────────────── */
                            .pm-card {
                                background: var(--clr-card);
                                border: 1px solid var(--clr-card-border);
                                border-radius: var(--radius-xl);
                                overflow: hidden;
                                position: relative;
                                transition: border-color var(--transition), transform var(--transition),
                                    box-shadow var(--transition);
                                display: flex;
                                flex-direction: column;
                            }

                            .pm-card:hover {
                                border-color: rgba(255, 255, 255, 0.08);
                                transform: translateY(-2px);
                                box-shadow: 0 8px 28px rgba(0, 0, 0, 0.45);
                            }

                            /* Estado inactivo: más apagado visualmente */
                            .pm-card.is-inactive {
                                opacity: 0.62;
                            }

                            .pm-card.is-inactive:hover {
                                opacity: 0.8;
                            }

                            /* Franja lateral izquierda de color (indicador de estado) */
                            .pm-card::after {
                                content: '';
                                position: absolute;
                                left: 0;
                                top: 0;
                                bottom: 0;
                                width: 3px;
                                background: var(--pm-accent, var(--clr-text-dim));
                                border-radius: 0 2px 2px 0;
                            }

                            .pm-card.is-active::after {
                                background: var(--pm-accent, var(--clr-success));
                            }

                            .pm-card.is-inactive::after {
                                background: var(--clr-text-dim);
                            }

                            /* ── Icono del método de pago ──────────────────────────── */
                            .pm-card__icon-wrap {
                                padding: 1.35rem 1.35rem 0.75rem 1.35rem;
                                display: flex;
                                align-items: center;
                                justify-content: space-between;
                                gap: 0.75rem;
                            }

                            .pm-card__icon {
                                flex-shrink: 0;
                                width: 50px;
                                height: 50px;
                                border-radius: var(--radius-lg);
                                display: flex;
                                align-items: center;
                                justify-content: center;
                                background: var(--pm-icon-bg, var(--clr-surface-2));
                                border: 1px solid var(--pm-icon-border, var(--clr-border));
                                transition: background var(--transition), border-color var(--transition);
                            }

                            .pm-card__icon svg {
                                width: 22px;
                                height: 22px;
                                color: var(--pm-accent, var(--clr-text-muted));
                                transition: color var(--transition);
                            }

                            /* Estado visual del icono */
                            .pm-estado-dot {
                                width: 9px;
                                height: 9px;
                                border-radius: 50%;
                                flex-shrink: 0;
                                align-self: flex-start;
                                margin-top: 0.2rem;
                            }

                            .pm-estado-dot.activo {
                                background: var(--clr-success);
                                box-shadow: 0 0 0 3px rgba(34, 197, 94, 0.18);
                                animation: pulse-green 2.2s ease-in-out infinite;
                            }

                            .pm-estado-dot.inactivo {
                                background: var(--clr-text-dim);
                            }

                            @keyframes pulse-green {

                                0%,
                                100% {
                                    box-shadow: 0 0 0 0 rgba(34, 197, 94, 0.4);
                                }

                                50% {
                                    box-shadow: 0 0 0 6px transparent;
                                }
                            }

                            /* ── Nombre y ID ─────────────────────────────────────────── */
                            .pm-card__body {
                                padding: 0.2rem 1.35rem 1rem;
                                flex: 1;
                                display: flex;
                                flex-direction: column;
                                gap: 0.3rem;
                            }

                            .pm-card__nombre {
                                font-family: var(--font-display);
                                font-weight: 800;
                                font-size: 1.15rem;
                                letter-spacing: 0.04em;
                                text-transform: uppercase;
                                color: var(--clr-text);
                                line-height: 1.15;
                            }

                            .pm-card__id {
                                font-family: var(--font-mono);
                                font-size: 0.65rem;
                                color: var(--clr-text-dim);
                                background: var(--clr-surface);
                                padding: 0.16rem 0.5rem;
                                border-radius: var(--radius-xs);
                                border: 1px solid var(--clr-border-light);
                                display: inline-block;
                                width: fit-content;
                            }

                            .pm-card__status-label {
                                font-size: 0.72rem;
                                font-weight: 600;
                                letter-spacing: 0.05em;
                                text-transform: uppercase;
                                margin-top: 0.3rem;
                            }

                            .pm-card__status-label.activo {
                                color: var(--clr-success);
                            }

                            .pm-card__status-label.inactivo {
                                color: var(--clr-text-dim);
                            }

                            /* ── Footer con acción ───────────────────────────────────── */
                            .pm-card__footer {
                                padding: 0.75rem 1.35rem;
                                border-top: 1px solid var(--clr-border-light);
                                background: rgba(255, 255, 255, 0.012);
                            }

                            /* Botón toggle — ocupa todo el ancho de la tarjeta */
                            .pm-toggle-btn {
                                display: flex;
                                align-items: center;
                                justify-content: center;
                                gap: 0.55rem;
                                width: 100%;
                                padding: 0.55rem 1rem;
                                border-radius: var(--radius-md);
                                font-size: 0.78rem;
                                font-weight: 700;
                                letter-spacing: 0.03em;
                                cursor: pointer;
                                transition: all var(--transition);
                                border: 1px solid;
                            }

                            .pm-toggle-btn svg {
                                width: 13px;
                                height: 13px;
                                flex-shrink: 0;
                            }

                            /* Activar (estaba inactivo) */
                            .pm-toggle-btn--activar {
                                background: var(--clr-success-subtle);
                                color: var(--clr-success);
                                border-color: rgba(34, 197, 94, 0.28);
                            }

                            .pm-toggle-btn--activar:hover {
                                background: var(--clr-success);
                                color: #fff;
                                border-color: var(--clr-success);
                                transform: translateY(-1px);
                                box-shadow: 0 3px 14px rgba(34, 197, 94, 0.4);
                            }

                            /* Desactivar (estaba activo) */
                            .pm-toggle-btn--desactivar {
                                background: var(--clr-danger-subtle);
                                color: var(--clr-red);
                                border-color: rgba(230, 48, 39, 0.25);
                            }

                            .pm-toggle-btn--desactivar:hover {
                                background: var(--clr-red);
                                color: #fff;
                                border-color: var(--clr-red);
                                transform: translateY(-1px);
                                box-shadow: 0 3px 14px rgba(230, 48, 39, 0.38);
                            }

                            /* Botón deshabilitado (único activo — no se puede desactivar) */
                            .pm-toggle-btn--disabled {
                                background: var(--clr-surface);
                                color: var(--clr-text-dim);
                                border-color: var(--clr-border-light);
                                cursor: not-allowed;
                                opacity: 0.55;
                            }

                            .pm-toggle-btn--disabled:hover {
                                transform: none;
                                box-shadow: none;
                            }

                            /* ── Strip de KPIs de cabecera ───────────────────────────── */
                            .pm-kpi-strip {
                                display: grid;
                                grid-template-columns: repeat(3, 1fr);
                                gap: 0;
                                background: var(--clr-card);
                                border: 1px solid var(--clr-card-border);
                                border-radius: var(--radius-lg);
                                overflow: hidden;
                                margin-bottom: 1.5rem;
                            }

                            .pm-kpi {
                                display: flex;
                                flex-direction: column;
                                align-items: center;
                                padding: 0.95rem 0.75rem;
                                gap: 0.2rem;
                                border-right: 1px solid var(--clr-border-light);
                                transition: background var(--transition);
                            }

                            .pm-kpi:last-child {
                                border-right: none;
                            }

                            .pm-kpi:hover {
                                background: rgba(255, 255, 255, 0.025);
                            }

                            .pm-kpi__num {
                                font-family: var(--font-display);
                                font-size: 1.65rem;
                                font-weight: 800;
                                line-height: 1;
                                color: var(--clr-text);
                            }

                            .pm-kpi__num.green {
                                color: var(--clr-success);
                            }

                            .pm-kpi__num.dim {
                                color: var(--clr-text-dim);
                            }

                            .pm-kpi__label {
                                font-size: 0.67rem;
                                font-weight: 700;
                                letter-spacing: 0.09em;
                                text-transform: uppercase;
                                color: var(--clr-text-dim);
                            }

                            /* ── Banner de aviso: único activo ──────────────────────── */
                            .pm-only-active-banner {
                                display: flex;
                                align-items: flex-start;
                                gap: 0.75rem;
                                padding: 0.85rem 1rem;
                                background: var(--clr-warning-subtle);
                                border: 1px solid rgba(245, 158, 11, 0.25);
                                border-radius: var(--radius-md);
                                margin-bottom: 1.25rem;
                            }

                            .pm-only-active-banner svg {
                                flex-shrink: 0;
                                width: 16px;
                                height: 16px;
                                color: var(--clr-warning);
                                margin-top: 1px;
                            }

                            .pm-only-active-banner p {
                                font-size: 0.80rem;
                                color: #fcd34d;
                                font-weight: 500;
                                line-height: 1.5;
                            }

                            .pm-only-active-banner strong {
                                font-weight: 700;
                            }

                            /* ── Paleta por tipo de método ───────────────────────────── */
                            /* Efectivo */
                            .pm-card.pm--efectivo {
                                --pm-accent: #22c55e;
                                --pm-icon-bg: rgba(34, 197, 94, 0.08);
                                --pm-icon-border: rgba(34, 197, 94, 0.18);
                            }

                            /* Visa */
                            .pm-card.pm--visa {
                                --pm-accent: #3b82f6;
                                --pm-icon-bg: rgba(59, 130, 246, 0.08);
                                --pm-icon-border: rgba(59, 130, 246, 0.18);
                            }

                            /* Mastercard */
                            .pm-card.pm--mastercard {
                                --pm-accent: #f97316;
                                --pm-icon-bg: rgba(249, 115, 22, 0.08);
                                --pm-icon-border: rgba(249, 115, 22, 0.18);
                            }

                            /* Yape */
                            .pm-card.pm--yape {
                                --pm-accent: #a78bfa;
                                --pm-icon-bg: rgba(167, 139, 250, 0.08);
                                --pm-icon-border: rgba(167, 139, 250, 0.18);
                            }

                            /* Plin */
                            .pm-card.pm--plin {
                                --pm-accent: #2dd4bf;
                                --pm-icon-bg: rgba(45, 212, 191, 0.08);
                                --pm-icon-border: rgba(45, 212, 191, 0.18);
                            }

                            /* Transferencia */
                            .pm-card.pm--transfer {
                                --pm-accent: #f59e0b;
                                --pm-icon-bg: rgba(245, 158, 11, 0.08);
                                --pm-icon-border: rgba(245, 158, 11, 0.18);
                            }

                            /* Genérico fallback */
                            .pm-card.pm--default {
                                --pm-accent: var(--clr-red);
                                --pm-icon-bg: var(--clr-red-subtle);
                                --pm-icon-border: rgba(230, 48, 39, 0.18);
                            }

                            /* ── Animaciones de entrada escalonadas ─────────────────── */
                            .pm-card {
                                animation: fadeSlideUp 0.42s cubic-bezier(0.4, 0, 0.2, 1) both;
                            }

                            .pm-card:nth-child(1) {
                                animation-delay: 0.04s;
                            }

                            .pm-card:nth-child(2) {
                                animation-delay: 0.08s;
                            }

                            .pm-card:nth-child(3) {
                                animation-delay: 0.12s;
                            }

                            .pm-card:nth-child(4) {
                                animation-delay: 0.16s;
                            }

                            .pm-card:nth-child(5) {
                                animation-delay: 0.20s;
                            }

                            .pm-card:nth-child(6) {
                                animation-delay: 0.24s;
                            }

                            /* ── Info de tabla al pie ───────────────────────────────── */
                            .pm-info-footer {
                                margin-top: 1.25rem;
                                display: flex;
                                align-items: flex-start;
                                gap: 0.65rem;
                                padding: 0.85rem 1.1rem;
                                background: var(--clr-card);
                                border: 1px solid var(--clr-card-border);
                                border-radius: var(--radius-md);
                            }

                            .pm-info-footer svg {
                                flex-shrink: 0;
                                width: 14px;
                                height: 14px;
                                color: var(--clr-text-dim);
                                margin-top: 1px;
                            }

                            .pm-info-footer p {
                                font-size: 0.74rem;
                                color: var(--clr-text-dim);
                                line-height: 1.55;
                            }

                            .pm-info-footer p strong {
                                color: var(--clr-text-muted);
                            }

                            /* ── Modal de CRUD ───────────────────────────────────────── */
                            .pm-modal-overlay {
                                position: fixed;
                                top: 0;
                                left: 0;
                                right: 0;
                                bottom: 0;
                                background: rgba(0, 0, 0, 0.5);
                                backdrop-filter: blur(5px);
                                display: flex;
                                align-items: center;
                                justify-content: center;
                                z-index: 1000;
                                opacity: 0;
                                pointer-events: none;
                                transition: opacity var(--transition);
                            }

                            .pm-modal-overlay.is-open {
                                opacity: 1;
                                pointer-events: auto;
                            }

                            .pm-modal {
                                background: var(--clr-card);
                                border: 1px solid var(--clr-card-border);
                                border-radius: var(--radius-xl);
                                width: 100%;
                                max-width: 450px;
                                padding: 1.5rem;
                                transform: translateY(20px) scale(0.95);
                                transition: transform var(--transition);
                                box-shadow: 0 15px 40px rgba(0, 0, 0, 0.5);
                            }

                            .pm-modal-overlay.is-open .pm-modal {
                                transform: translateY(0) scale(1);
                            }

                            .pm-modal__header {
                                font-family: var(--font-display);
                                font-size: 1.25rem;
                                font-weight: 800;
                                margin-bottom: 1.25rem;
                                color: var(--clr-text);
                                display: flex;
                                justify-content: space-between;
                                align-items: center;
                                text-transform: uppercase;
                            }

                            .pm-modal__close {
                                background: none;
                                border: none;
                                color: var(--clr-text-dim);
                                cursor: pointer;
                                padding: 0.2rem;
                                border-radius: var(--radius-sm);
                            }

                            .pm-modal__close:hover {
                                color: var(--clr-text);
                                background: var(--clr-surface);
                            }

                            /* ── Responsive ─────────────────────────────────────────── */
                            @media (max-width: 768px) {
                                .pm-grid {
                                    grid-template-columns: 1fr 1fr;
                                }

                                .pm-kpi-strip {
                                    grid-template-columns: 1fr;
                                }

                                .pm-kpi {
                                    border-right: none;
                                    border-bottom: 1px solid var(--clr-border-light);
                                }

                                .pm-kpi:last-child {
                                    border-bottom: none;
                                }
                            }

                            @media (max-width: 480px) {
                                .pm-grid {
                                    grid-template-columns: 1fr;
                                }
                            }
                        </style>
                </head>

                <body>

                    <div class="app-shell">
                        <%@ include file="/WEB-INF/views/includes/sidebar.jsp" %>

                            <div class="app-main">
                                <c:set var="pageTitle" value="Métodos de Pago" scope="request" />
                                <c:set var="pageSubtitle" value="Catálogo de formas de cobro" scope="request" />
                                <%@ include file="/WEB-INF/views/includes/navbar.jsp" %>

                                    <div class="page-content">

                                        <%-- ── Header del módulo ──────────────────────────── --%>
                                            <div class="module-header">
                                                <div class="module-header__left">
                                                    <h1 class="module-header__title">
                                                        Métodos de Pago
                                                        <span class="stat-chip">
                                                            <c:out value="${totalMetodos}" />
                                                        </span>
                                                    </h1>
                                                    <div class="module-header__meta">
                                                        <span>Gestiona las formas de cobro disponibles al crear
                                                            contratos</span>
                                                        <span class="module-header__meta-sep"></span>
                                                        <span class="stat-chip chip--green">
                                                            <c:out value="${totalActivos}" /> activos
                                                        </span>
                                                    </div>
                                                </div>

                                                <div class="module-header__actions">
                                                    <button type="button" onclick="openModal(null)"
                                                        class="btn btn-primary btn-sm">
                                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                            viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                                d="M12 4.5v15m7.5-7.5h-15" />
                                                        </svg>
                                                        Nuevo método de pago
                                                    </button>
                                                </div>
                                            </div>

                                            <%-- ── Strip de KPIs ─────────────────────────────────── --%>
                                                <div class="pm-kpi-strip">
                                                    <div class="pm-kpi">
                                                        <span class="pm-kpi__num">
                                                            <c:out value="${totalMetodos}" />
                                                        </span>
                                                        <span class="pm-kpi__label">Métodos totales</span>
                                                    </div>
                                                    <div class="pm-kpi">
                                                        <span class="pm-kpi__num green">
                                                            <c:out value="${totalActivos}" />
                                                        </span>
                                                        <span class="pm-kpi__label">Disponibles</span>
                                                    </div>
                                                    <div class="pm-kpi">
                                                        <span class="pm-kpi__num dim">
                                                            <c:out value="${totalInactivos}" />
                                                        </span>
                                                        <span class="pm-kpi__label">Desactivados</span>
                                                    </div>
                                                </div>

                                                <%-- ── Aviso: solo queda un método activo ─────────────── --%>
                                                    <c:if test="${totalActivos eq 1}">
                                                        <div class="pm-only-active-banner" role="status">
                                                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                                viewBox="0 0 24 24" stroke="currentColor"
                                                                stroke-width="2">
                                                                <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948
                                 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949
                                 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697
                                 16.126ZM12 15.75h.007v.008H12v-.008Z" />
                                                            </svg>
                                                            <p>
                                                                Solo queda <strong>1 método de pago activo</strong>.
                                                                No puedes desactivarlo porque se necesita al menos uno
                                                                para
                                                                registrar contratos. Activa otro método primero.
                                                            </p>
                                                        </div>
                                                    </c:if>

                                                    <%-- ── Grid de tarjetas ─────────────────────────────── --%>
                                                        <c:choose>
                                                            <c:when test="${not empty metodos}">

                                                                <div class="pm-grid">
                                                                    <c:forEach var="mp" items="${metodos}"
                                                                        varStatus="loop">

                                                                        <%-- Determinar clase CSS por ID del método --%>
                                                                            <c:set var="pmClass" value="pm--default" />
                                                                            <c:if
                                                                                test="${fn:containsIgnoreCase(mp.id, 'EFECTIVO')}">
                                                                                <c:set var="pmClass"
                                                                                    value="pm--efectivo" />
                                                                            </c:if>
                                                                            <c:if
                                                                                test="${fn:containsIgnoreCase(mp.id, 'VISA')}">
                                                                                <c:set var="pmClass" value="pm--visa" />
                                                                            </c:if>
                                                                            <c:if
                                                                                test="${fn:containsIgnoreCase(mp.id, 'MASTERCARD')}">
                                                                                <c:set var="pmClass"
                                                                                    value="pm--mastercard" />
                                                                            </c:if>
                                                                            <c:if
                                                                                test="${fn:containsIgnoreCase(mp.id, 'YAPE')}">
                                                                                <c:set var="pmClass" value="pm--yape" />
                                                                            </c:if>
                                                                            <c:if
                                                                                test="${fn:containsIgnoreCase(mp.id, 'PLIN')}">
                                                                                <c:set var="pmClass" value="pm--plin" />
                                                                            </c:if>
                                                                            <c:if
                                                                                test="${fn:containsIgnoreCase(mp.id, 'TRANSFER')}">
                                                                                <c:set var="pmClass"
                                                                                    value="pm--transfer" />
                                                                            </c:if>

                                                                            <div class="pm-card ${pmClass}
                                        ${mp.activo ? 'is-active' : 'is-inactive'}">

                                                                                <%-- Icono + punto de estado --%>
                                                                                    <div class="pm-card__icon-wrap">
                                                                                        <div class="pm-card__icon">

                                                                                            <%-- Ícono según tipo de
                                                                                                método --%>
                                                                                                <c:choose>
                                                                                                    <%-- Efectivo --%>
                                                                                                        <c:when
                                                                                                            test="${fn:containsIgnoreCase(mp.id,'EFECTIVO')}">
                                                                                                            <svg xmlns="http://www.w3.org/2000/svg"
                                                                                                                fill="none"
                                                                                                                viewBox="0 0 24 24"
                                                                                                                stroke="currentColor"
                                                                                                                stroke-width="1.7">
                                                                                                                <path
                                                                                                                    stroke-linecap="round"
                                                                                                                    stroke-linejoin="round"
                                                                                                                    d="M2.25 18.75a60.07 60.07 0 0 1 15.797 2.101c.727.198
                                                             1.453-.342 1.453-1.096V18.75M3.75 4.5v.75A.75.75 0 0
                                                             1 3 6h-.75m0 0v-.375c0-.621.504-1.125 1.125-1.125H20.25M2.25
                                                             6v9m18-10.5v.75c0 .414.336.75.75.75h.75m-1.5-1.5h.375c.621
                                                             0 1.125.504 1.125 1.125v9.75c0 .621-.504 1.125-1.125
                                                             1.125h-.375m1.5-1.5H21a.75.75 0 0 0-.75.75v.75m0
                                                             0H3.75m0 0h-.375a1.125 1.125 0 0
                                                             1-1.125-1.125V15m1.5 1.5v-.75A.75.75 0 0 0 3
                                                             15h-.75M15 10.5a3 3 0 1 1-6 0 3 3 0 0 1 6 0Zm3
                                                             0h.008v.008H18V10.5Zm-12 0h.008v.008H6V10.5Z" />
                                                                                                            </svg>
                                                                                                        </c:when>
                                                                                                        <%-- Tarjeta
                                                                                                            (Visa /
                                                                                                            Mastercard)
                                                                                                            --%>
                                                                                                            <c:when
                                                                                                                test="${fn:containsIgnoreCase(mp.id,'VISA')
                                                         or fn:containsIgnoreCase(mp.id,'MASTERCARD')}">
                                                                                                                <svg xmlns="http://www.w3.org/2000/svg"
                                                                                                                    fill="none"
                                                                                                                    viewBox="0 0 24 24"
                                                                                                                    stroke="currentColor"
                                                                                                                    stroke-width="1.7">
                                                                                                                    <path
                                                                                                                        stroke-linecap="round"
                                                                                                                        stroke-linejoin="round"
                                                                                                                        d="M2.25 8.25h19.5M2.25 9h19.5m-16.5
                                                             5.25h6m-6 2.25h3m-3.75 3h15a2.25 2.25
                                                             0 0 0 2.25-2.25V6.75A2.25 2.25 0 0 0
                                                             19.5 4.5h-15a2.25 2.25 0 0 0-2.25
                                                             2.25v10.5A2.25 2.25 0 0 0 4.5 19.5Z" />
                                                                                                                </svg>
                                                                                                            </c:when>
                                                                                                            <%-- Yape /
                                                                                                                Plin (QR
                                                                                                                / móvil)
                                                                                                                --%>
                                                                                                                <c:when
                                                                                                                    test="${fn:containsIgnoreCase(mp.id,'YAPE')
                                                         or fn:containsIgnoreCase(mp.id,'PLIN')}">
                                                                                                                    <svg xmlns="http://www.w3.org/2000/svg"
                                                                                                                        fill="none"
                                                                                                                        viewBox="0 0 24 24"
                                                                                                                        stroke="currentColor"
                                                                                                                        stroke-width="1.7">
                                                                                                                        <path
                                                                                                                            stroke-linecap="round"
                                                                                                                            stroke-linejoin="round"
                                                                                                                            d="M10.5 1.5H8.25A2.25 2.25 0 0 0 6 3.75v16.5a2.25 2.25
                                                             0 0 0 2.25 2.25h7.5A2.25 2.25 0 0 0 18 20.25V3.75a2.25
                                                             2.25 0 0 0-2.25-2.25H13.5m-3 0V3h3V1.5m-3 0h3m-3
                                                             18.75h3" />
                                                                                                                    </svg>
                                                                                                                </c:when>
                                                                                                                <%-- Transferencia
                                                                                                                    bancaria
                                                                                                                    --%>
                                                                                                                    <c:when
                                                                                                                        test="${fn:containsIgnoreCase(mp.id,'TRANSFER')}">
                                                                                                                        <svg xmlns="http://www.w3.org/2000/svg"
                                                                                                                            fill="none"
                                                                                                                            viewBox="0 0 24 24"
                                                                                                                            stroke="currentColor"
                                                                                                                            stroke-width="1.7">
                                                                                                                            <path
                                                                                                                                stroke-linecap="round"
                                                                                                                                stroke-linejoin="round"
                                                                                                                                d="M7.5 21 3 16.5m0 0L7.5 12M3 16.5h13.5m0-13.5L21
                                                             7.5m0 0L16.5 12M21 7.5H7.5" />
                                                                                                                        </svg>
                                                                                                                    </c:when>
                                                                                                                    <%-- Genérico
                                                                                                                        --%>
                                                                                                                        <c:otherwise>
                                                                                                                            <svg xmlns="http://www.w3.org/2000/svg"
                                                                                                                                fill="none"
                                                                                                                                viewBox="0 0 24 24"
                                                                                                                                stroke="currentColor"
                                                                                                                                stroke-width="1.7">
                                                                                                                                <path
                                                                                                                                    stroke-linecap="round"
                                                                                                                                    stroke-linejoin="round"
                                                                                                                                    d="M12 6v12m-3-2.818.879.659c1.171.879 3.07.879 4.242
                                                             0 1.172-.879 1.172-2.303 0-3.182C13.536
                                                             12.219 12.768 12 12 12c-.725 0-1.45-.22-2.003-.659-1.106-.879-1.106-2.303
                                                             0-3.182s2.9-.879 4.006 0l.415.33M21 12a9 9 0
                                                             1 1-18 0 9 9 0 0 1 18 0Z" />
                                                                                                                            </svg>
                                                                                                                        </c:otherwise>
                                                                                                </c:choose>
                                                                                        </div>

                                                                                        <%-- Punto de estado (activo /
                                                                                            inactivo) --%>
                                                                                            <span
                                                                                                class="pm-estado-dot ${mp.activo ? 'activo' : 'inactivo'}"
                                                                                                title="${mp.activo ? 'Activo' : 'Inactivo'}"></span>
                                                                                    </div>

                                                                                    <%-- Nombre e info --%>
                                                                                        <div class="pm-card__body">
                                                                                            <p class="pm-card__nombre">
                                                                                                <c:out
                                                                                                    value="${mp.nombre}" />
                                                                                            </p>
                                                                                            <span class="pm-card__id">
                                                                                                <c:out
                                                                                                    value="${mp.id}" />
                                                                                            </span>
                                                                                            <p
                                                                                                class="pm-card__status-label ${mp.activo ? 'activo' : 'inactivo'}">
                                                                                                <c:choose>
                                                                                                    <c:when
                                                                                                        test="${mp.activo}">
                                                                                                        Disponible para
                                                                                                        contratos
                                                                                                    </c:when>
                                                                                                    <c:otherwise>No
                                                                                                        disponible
                                                                                                    </c:otherwise>
                                                                                                </c:choose>
                                                                                            </p>
                                                                                        </div>

                                                                                        <%-- Acción: toggle
                                                                                            activo/inactivo --%>
                                                                                            <div
                                                                                                class="pm-card__footer">
                                                                                                <div
                                                                                                    style="display: flex; gap: 0.5rem; margin-bottom: 0.5rem;">
                                                                                                    <button
                                                                                                        type="button"
                                                                                                        onclick="openModal({id: '<c:out value='${mp.id}'/>', nombre: '<c:out value='${fn:escapeXml(mp.nombre)}'/>', estado: '<c:out value='${mp.estado}'/>'})"
                                                                                                        class="btn btn-secondary btn-sm"
                                                                                                        style="flex: 1; display:flex; justify-content:center; padding:0.4rem;">
                                                                                                        Editar
                                                                                                    </button>
                                                                                                    <form
                                                                                                        action="${pageContext.request.contextPath}/payment-methods"
                                                                                                        method="post"
                                                                                                        style="flex: 1;">
                                                                                                        <input
                                                                                                            type="hidden"
                                                                                                            name="action"
                                                                                                            value="delete">
                                                                                                        <input
                                                                                                            type="hidden"
                                                                                                            name="id"
                                                                                                            value="<c:out value='${mp.id}'/>">
                                                                                                        <input
                                                                                                            type="hidden"
                                                                                                            name="_csrf"
                                                                                                            value="${sessionScope._csrfToken}">
                                                                                                        <button
                                                                                                            type="button"
                                                                                                            onclick="openActionModal(this.closest('form'), 'delete', '<c:out value='${fn:escapeXml(mp.nombre)}'/>')"
                                                                                                            class="btn btn-danger btn-sm"
                                                                                                            style="width:100%; padding:0.4rem; justify-content: center; display: flex;">
                                                                                                            Eliminar
                                                                                                        </button>
                                                                                                    </form>
                                                                                                </div>

                                                                                                <%-- Caso especial: es
                                                                                                    el último activo →
                                                                                                    botón deshabilitado
                                                                                                    --%>
                                                                                                    <c:choose>
                                                                                                        <c:when
                                                                                                            test="${mp.activo and totalActivos eq 1}">
                                                                                                            <button
                                                                                                                type="button"
                                                                                                                class="pm-toggle-btn pm-toggle-btn--disabled"
                                                                                                                disabled
                                                                                                                title="No puedes desactivar el único método activo">
                                                                                                                <svg xmlns="http://www.w3.org/2000/svg"
                                                                                                                    fill="none"
                                                                                                                    viewBox="0 0 24 24"
                                                                                                                    stroke="currentColor"
                                                                                                                    stroke-width="1.8">
                                                                                                                    <path
                                                                                                                        stroke-linecap="round"
                                                                                                                        stroke-linejoin="round"
                                                                                                                        d="M16.5 10.5V6.75a4.5 4.5 0 1 0-9 0v3.75m-.75
                                                             11.25h10.5a2.25 2.25 0 0 0 2.25-2.25v-6.75a2.25
                                                             2.25 0 0 0-2.25-2.25H6.75a2.25 2.25 0 0
                                                             0-2.25 2.25v6.75a2.25 2.25 0 0 0 2.25 2.25Z" />
                                                                                                                </svg>
                                                                                                                Protegido
                                                                                                                (último
                                                                                                                activo)
                                                                                                            </button>
                                                                                                        </c:when>

                                                                                                        <%-- Activo →
                                                                                                            botón para
                                                                                                            desactivar
                                                                                                            --%>
                                                                                                            <c:when
                                                                                                                test="${mp.activo}">
                                                                                                                <form
                                                                                                                    action="${pageContext.request.contextPath}/payment-methods"
                                                                                                                    method="post"
                                                                                                                    >
                                                                                                                    <input
                                                                                                                        type="hidden"
                                                                                                                        name="action"
                                                                                                                        value="toggle">
                                                                                                                    <input
                                                                                                                        type="hidden"
                                                                                                                        name="id"
                                                                                                                        value="<c:out value='${mp.id}'/>">
                                                                                                                    <input
                                                                                                                        type="hidden"
                                                                                                                        name="_csrf"
                                                                                                                        value="${sessionScope._csrfToken}">
                                                                                                                    <button
                                                                                                                        type="button"
                                                                                                                        onclick="openActionModal(this.closest('form'), 'deactivate', '<c:out value='${fn:escapeXml(mp.nombre)}'/>')"
                                                                                                                        class="pm-toggle-btn pm-toggle-btn--desactivar">
                                                                                                                        <svg xmlns="http://www.w3.org/2000/svg"
                                                                                                                            fill="none"
                                                                                                                            viewBox="0 0 24 24"
                                                                                                                            stroke="currentColor"
                                                                                                                            stroke-width="1.8">
                                                                                                                            <path
                                                                                                                                stroke-linecap="round"
                                                                                                                                stroke-linejoin="round"
                                                                                                                                d="M6 18 18 6M6 6l12 12" />
                                                                                                                        </svg>
                                                                                                                        Desactivar
                                                                                                                    </button>
                                                                                                                </form>
                                                                                                            </c:when>

                                                                                                            <%-- Inactivo
                                                                                                                → botón
                                                                                                                para
                                                                                                                activar
                                                                                                                --%>
                                                                                                                <c:otherwise>
                                                                                                                    <form
                                                                                                                        action="${pageContext.request.contextPath}/payment-methods"
                                                                                                                        method="post"
                                                                                                                        >
                                                                                                                        <input
                                                                                                                            type="hidden"
                                                                                                                            name="action"
                                                                                                                            value="toggle">
                                                                                                                        <input
                                                                                                                            type="hidden"
                                                                                                                            name="id"
                                                                                                                            value="<c:out value='${mp.id}'/>">
                                                                                                                        <input
                                                                                                                            type="hidden"
                                                                                                                            name="_csrf"
                                                                                                                            value="${sessionScope._csrfToken}">
                                                                                                                        <button
                                                                                                                            type="button"
                                                                                                                            onclick="openActionModal(this.closest('form'), 'activate', '<c:out value='${fn:escapeXml(mp.nombre)}'/>')"
                                                                                                                            class="pm-toggle-btn pm-toggle-btn--activar">
                                                                                                                            <svg xmlns="http://www.w3.org/2000/svg"
                                                                                                                                fill="none"
                                                                                                                                viewBox="0 0 24 24"
                                                                                                                                stroke="currentColor"
                                                                                                                                stroke-width="1.8">
                                                                                                                                <path
                                                                                                                                    stroke-linecap="round"
                                                                                                                                    stroke-linejoin="round"
                                                                                                                                    d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
                                                                                                                            </svg>
                                                                                                                            Activar
                                                                                                                        </button>
                                                                                                                    </form>
                                                                                                                </c:otherwise>
                                                                                                    </c:choose>

                                                                                            </div><%-- /pm-card__footer
                                                                                                --%>
                                                                            </div><%-- /pm-card --%>
                                                                    </c:forEach>
                                                                </div><%-- /pm-grid --%>

                                                            </c:when>

                                                            <%-- Estado vacío (en teoría no debería ocurrir con un
                                                                catálogo fijo) --%>
                                                                <c:otherwise>
                                                                    <div style="background:var(--clr-card); border:1px solid var(--clr-card-border);
                                border-radius:var(--radius-lg); overflow:hidden;">
                                                                        <div class="table-empty">
                                                                            <div class="table-empty__icon">
                                                                                <svg xmlns="http://www.w3.org/2000/svg"
                                                                                    fill="none" viewBox="0 0 24 24"
                                                                                    stroke="currentColor"
                                                                                    stroke-width="1.5">
                                                                                    <path stroke-linecap="round"
                                                                                        stroke-linejoin="round" d="M2.25 8.25h19.5M2.25 9h19.5m-16.5 5.25h6m-6 2.25h3m-3.75
                                             3h15a2.25 2.25 0 0 0 2.25-2.25V6.75A2.25 2.25 0 0 0
                                             19.5 4.5h-15a2.25 2.25 0 0 0-2.25 2.25v10.5A2.25 2.25
                                             0 0 0 4.5 19.5Z" />
                                                                                </svg>
                                                                            </div>
                                                                            <p class="table-empty__title">Sin métodos de
                                                                                pago</p>
                                                                            <p class="table-empty__desc">
                                                                                No hay métodos registrados en la base de
                                                                                datos.<br>
                                                                                Verifica que el catálogo MetodosPago
                                                                                esté poblado en SQL Server.
                                                                            </p>
                                                                        </div>
                                                                    </div>
                                                                </c:otherwise>
                                                        </c:choose>

                                                        <%-- ── Nota informativa al pie ───────────────────────── --%>
                                                            <div class="pm-info-footer">
                                                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                                    viewBox="0 0 24 24" stroke="currentColor"
                                                                    stroke-width="1.8">
                                                                    <path stroke-linecap="round" stroke-linejoin="round"
                                                                        d="m11.25 11.25.041-.02a.75.75 0 0 1 1.063.852l-.708 2.836a.75.75
                             0 0 0 1.063.853l.041-.021M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9-3.75h.008v.008H12V8.25Z" />
                                                                </svg>
                                                                <p>
                                                                    Solo los métodos <strong>activos</strong> aparecen
                                                                    disponibles al registrar nuevos contratos.
                                                                    Desactivar un método no afecta los contratos ya
                                                                    existentes.
                                                                    Debe mantenerse <strong>al menos un método
                                                                        activo</strong> en todo momento.
                                                                </p>
                                                            </div>

                                    </div><%-- /page-content --%>
                            </div><%-- /app-main --%>
                    </div><%-- /app-shell --%>

                        <%-- ── Modal para Método de Pago ─────────────────────── --%>
                            <div id="pmModal" class="pm-modal-overlay">
                                <div class="pm-modal">
                                    <div class="pm-modal__header">
                                        <span id="pmModalTitle">Nuevo Método de Pago</span>
                                        <button class="pm-modal__close" onclick="closeModal()">
                                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                                                stroke="currentColor" stroke-width="2" width="20" height="20">
                                                <path stroke-linecap="round" stroke-linejoin="round"
                                                    d="M6 18L18 6M6 6l12 12" />
                                            </svg>
                                        </button>
                                    </div>

                                    <form action="${pageContext.request.contextPath}/payment-methods" method="post">
                                        <input type="hidden" name="action" value="save">
                                        <input type="hidden" name="id" id="pmModalId" value="">
                                        <input type="hidden" name="_csrf" value="${sessionScope._csrfToken}">

                                        <div id="pmModalIdContainer" style="display:none; margin-bottom: 1.25rem;">
                                            <label
                                                style="display:block; font-size: 0.75rem; font-weight:600; color:var(--clr-text-dim); margin-bottom: 0.3rem;">ID
                                                del Método</label>
                                            <div id="pmModalIdDisplay"
                                                style="font-family:var(--font-mono); font-size:0.8rem; color:var(--clr-text-muted); background:var(--clr-surface); padding:0.6rem; border-radius:var(--radius-sm); border:1px solid var(--clr-border);">
                                            </div>
                                        </div>

                                        <div style="margin-bottom: 1.25rem;">
                                            <label for="pmModalNombre"
                                                style="display:block; font-size: 0.75rem; font-weight:600; color:var(--clr-text-dim); margin-bottom: 0.3rem;">Nombre
                                                del Método *</label>
                                            <input type="text" id="pmModalNombre" name="nombre" required maxlength="50"
                                                style="width: 100%; padding: 0.65rem 0.75rem; border-radius: var(--radius-md); border: 1px solid var(--clr-border); background: var(--clr-surface); color: var(--clr-text);">
                                        </div>

                                        <div style="margin-bottom: 1.75rem;">
                                            <label for="pmModalEstado"
                                                style="display:block; font-size: 0.75rem; font-weight:600; color:var(--clr-text-dim); margin-bottom: 0.3rem;">Estado</label>
                                            <select id="pmModalEstado" name="estado"
                                                style="width: 100%; padding: 0.65rem 0.75rem; border-radius: var(--radius-md); border: 1px solid var(--clr-border); background: var(--clr-surface); color: var(--clr-text);">
                                                <option value="activo">Activo (Disponible)</option>
                                                <option value="inactivo">Inactivo (Oculto)</option>
                                            </select>
                                        </div>

                                        <div style="display: flex; gap: 0.75rem; justify-content: flex-end;">
                                            <button type="button" class="btn btn-secondary"
                                                onclick="closeModal()">Cancelar</button>
                                            <button type="submit" class="btn btn-primary">Guardar</button>
                                        </div>
                                    </form>
                                </div>
                            </div>

                            <script>
                                function openModal(mp) {
                                    const modal = document.getElementById('pmModal');
                                    const title = document.getElementById('pmModalTitle');
                                    const idInput = document.getElementById('pmModalId');
                                    const idContainer = document.getElementById('pmModalIdContainer');
                                    const idDisplay = document.getElementById('pmModalIdDisplay');
                                    const nombreInput = document.getElementById('pmModalNombre');
                                    const estadoSelect = document.getElementById('pmModalEstado');

                                    if (mp) {
                                        title.textContent = 'Editar Método de Pago';
                                        idInput.value = mp.id;
                                        idContainer.style.display = 'block';
                                        idDisplay.textContent = mp.id;
                                        nombreInput.value = mp.nombre;
                                        estadoSelect.value = mp.estado;
                                    } else {
                                        title.textContent = 'Nuevo Método de Pago';
                                        idInput.value = '';
                                        idContainer.style.display = 'none';
                                        idDisplay.textContent = '';
                                        nombreInput.value = '';
                                        estadoSelect.value = 'activo';
                                    }

                                    modal.classList.add('is-open');
                                    setTimeout(() => nombreInput.focus(), 100);
                                }

                                function closeModal() {
                                    document.getElementById('pmModal').classList.remove('is-open');
                                }

                                /* ── Lógica del Modal de Acción ── */
                                let formToSubmit = null;

                                function openActionModal(formElement, type, methodName) {
                                    formToSubmit = formElement;
                                    
                                    const iconContainer = document.getElementById('actionModalIconContainer');
                                    const icon = document.getElementById('actionModalIcon');
                                    const text = document.getElementById('actionModalText');
                                    const btn = document.getElementById('btnConfirmAction');
                                    
                                    if (type === 'delete') {
                                        iconContainer.style.borderColor = '#f87171';
                                        iconContainer.style.background = 'rgba(248,113,113,0.1)';
                                        icon.style.color = '#f87171';
                                        icon.textContent = '!';
                                        text.innerHTML = `Se eliminará de forma permanente <br><strong><span style="color: var(--clr-text-muted);">` + methodName + `</span></strong>`;
                                        btn.className = 'btn btn-primary';
                                        btn.textContent = 'Sí, eliminar!';
                                    } else if (type === 'deactivate') {
                                        iconContainer.style.borderColor = '#fbbf24'; // warning yellow
                                        iconContainer.style.background = 'rgba(251,191,36,0.1)';
                                        icon.style.color = '#fbbf24';
                                        icon.textContent = '!';
                                        text.innerHTML = `Se desactivará el método <br><strong><span style="color: var(--clr-text-muted);">` + methodName + `</span></strong><br><br><span style="font-size:0.8rem">Los contratos existentes no se verán afectados.</span>`;
                                        btn.className = 'btn btn-primary';
                                        btn.textContent = 'Sí, desactivar!';
                                    } else if (type === 'activate') {
                                        iconContainer.style.borderColor = '#34d399'; // success green
                                        iconContainer.style.background = 'rgba(52,211,153,0.1)';
                                        icon.style.color = '#34d399';
                                        icon.textContent = '?';
                                        text.innerHTML = `Se activará el método <br><strong><span style="color: var(--clr-text-muted);">` + methodName + `</span></strong><br><br><span style="font-size:0.8rem">Estará disponible para nuevos contratos.</span>`;
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
                                    <div class="pm-modal"
                                        style="max-width: 400px; text-align: center; padding: 2rem 1.5rem;">
                                        <div style="margin-bottom: 1.5rem;">
                                            <div id="actionModalIconContainer"
                                                style="width: 80px; height: 80px; border-radius: 50%; border: 3px solid; display: flex; align-items: center; justify-content: center; margin: 0 auto;">
                                                <span id="actionModalIcon"
                                                    style="font-size: 3.5rem; line-height: 1; font-family: var(--font-display); padding-bottom: 0.5rem;"></span>
                                            </div>
                                        </div>
                                        <h2
                                            style="font-family: var(--font-display); font-size: 1.6rem; font-weight: 800; color: var(--clr-text); margin-bottom: 0.75rem;">
                                            ¿Estás seguro?
                                        </h2>
                                        <p id="actionModalText"
                                            style="color: var(--clr-text-dim); font-size: 0.95rem; margin-bottom: 1.75rem; line-height: 1.5;">
                                        </p>
                                        <div style="display: flex; gap: 0.75rem; justify-content: center;">
                                            <button type="button" class="btn" id="btnConfirmAction"
                                                onclick="confirmAction()"
                                                style="min-width: 120px; font-weight: bold;">
                                            </button>
                                            <button type="button" class="btn btn-secondary" onclick="closeActionModal()"
                                                style="min-width: 120px; font-weight: bold; background: #473f3f; border-color: #473f3f;">
                                                Cancelar
                                            </button>
                                        </div>
                                    </div>
                                </div>

                </body>

                </html>