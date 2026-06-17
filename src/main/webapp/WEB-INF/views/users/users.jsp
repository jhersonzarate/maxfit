<%--============================================================users.jsp — MaxFit Sistema de Gestión Módulo de gestión
    de usuarios del sistema (RF-14). Servlet: UsersController.java → GET/POST /users Acceso: Solo ROL-ADMIN (RoleFilter)
    ── Parámetros de URL que activan vistas ────────────────── /users → lista de usuarios (default) /users?form=true →
    formulario nuevo / edición ── Atributos de request ───────────────────────────────── Vista lista (default): usuarios
    (List<Usuario>) → todos los usuarios
    totalUsuarios (int) → tamaño de la lista

    Vista formulario (?form=true):
    usuario (Usuario) → vacío (nuevo) o cargado (edición)
    roles (List<Rol>) → para el select de rol
        empleados (List<Empleado>) → para el select de empleado vinculado
            modoEdicion (Boolean) → false=nuevo, true=editar

            Flash (ambas vistas, via transferirFlashMessages):
            successMsg / errorMsg

            Acciones POST:
            action=save → crear o actualizar usuario
            action=toggleEstado → activar / desactivar cuenta
            action=resetPassword → resetear contraseña (solo admin)

            Sesión:
            sessionScope.userId → para bloquear auto-desactivación
            sessionScope.userRole → debe ser ROL-ADMIN
            ============================================================ --%>
            <%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
                <%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
                    <%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
                        <%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
                            <!DOCTYPE html>
                            <html lang="es">

                            <head>
                                <%@ include file="/WEB-INF/views/includes/head-common.jsp" %>
                                    <c:choose>
                                        <c:when test="${param.form eq 'true'}">
                                            <c:set var="pageTitle"
                                                value="${modoEdicion ? 'Editar Usuario' : 'Nuevo Usuario'}"
                                                scope="request" />
                                        </c:when>
                                        <c:otherwise>
                                            <c:set var="pageTitle" value="Usuarios" scope="request" />
                                        </c:otherwise>
                                    </c:choose>
                                    <link rel="stylesheet"
                                        href="${pageContext.request.contextPath}/static/css/modules.css">

                                    <style>
                                        /* ══════════════════════════════════════════════════════
           ESTILOS ESPECÍFICOS — MÓDULO DE USUARIOS
           ══════════════════════════════════════════════════════ */

                                        /* ── Badge de rol ─────────────────────────────────────── */
                                        .rol-badge {
                                            display: inline-flex;
                                            align-items: center;
                                            gap: 0.32rem;
                                            padding: 0.22rem 0.72rem;
                                            border-radius: var(--radius-full);
                                            font-size: 0.67rem;
                                            font-weight: 700;
                                            letter-spacing: 0.07em;
                                            text-transform: uppercase;
                                            white-space: nowrap;
                                        }

                                        .rol-badge::before {
                                            content: '';
                                            width: 5px;
                                            height: 5px;
                                            border-radius: 50%;
                                            background: currentColor;
                                            flex-shrink: 0;
                                        }

                                        .rol-badge--admin {
                                            background: var(--clr-red-subtle);
                                            color: var(--clr-red);
                                            border: 1px solid rgba(230, 48, 39, 0.22);
                                        }

                                        .rol-badge--recep {
                                            background: var(--clr-info-subtle);
                                            color: var(--clr-info);
                                            border: 1px solid rgba(59, 130, 246, 0.22);
                                        }

                                        .rol-badge--trainer {
                                            background: var(--clr-success-subtle);
                                            color: var(--clr-success);
                                            border: 1px solid rgba(34, 197, 94, 0.22);
                                        }

                                        .rol-badge--default {
                                            background: rgba(255, 255, 255, 0.05);
                                            color: var(--clr-text-dim);
                                            border: 1px solid var(--clr-border);
                                        }

                                        /* ── Estado de cuenta ─────────────────────────────────── */
                                        .estado-cuenta {
                                            display: inline-flex;
                                            align-items: center;
                                            gap: 0.35rem;
                                            font-size: 0.75rem;
                                            font-weight: 600;
                                        }

                                        .estado-cuenta__dot {
                                            width: 7px;
                                            height: 7px;
                                            border-radius: 50%;
                                            flex-shrink: 0;
                                        }

                                        .estado-cuenta.activo .estado-cuenta__dot {
                                            background: var(--clr-success);
                                        }

                                        .estado-cuenta.activo {
                                            color: var(--clr-success);
                                        }

                                        .estado-cuenta.inactivo .estado-cuenta__dot {
                                            background: var(--clr-text-dim);
                                        }

                                        .estado-cuenta.inactivo {
                                            color: var(--clr-text-dim);
                                        }

                                        /* Pulso en activos */
                                        .estado-cuenta.activo .estado-cuenta__dot {
                                            animation: pulse-green 2.2s ease-in-out infinite;
                                        }

                                        @keyframes pulse-green {

                                            0%,
                                            100% {
                                                box-shadow: 0 0 0 0 rgba(34, 197, 94, 0.45);
                                            }

                                            50% {
                                                box-shadow: 0 0 0 5px transparent;
                                            }
                                        }

                                        /* ── Stats strip de cabecera ──────────────────────────── */
                                        .usr-stats-strip {
                                            display: grid;
                                            grid-template-columns: repeat(4, 1fr);
                                            gap: 0;
                                            background: var(--clr-card);
                                            border: 1px solid var(--clr-card-border);
                                            border-radius: var(--radius-lg);
                                            overflow: hidden;
                                            margin-bottom: 1.5rem;
                                        }

                                        .usr-stat {
                                            display: flex;
                                            flex-direction: column;
                                            align-items: center;
                                            padding: 0.85rem 0.75rem;
                                            gap: 0.15rem;
                                            border-right: 1px solid var(--clr-border-light);
                                            transition: background var(--transition);
                                        }

                                        .usr-stat:last-child {
                                            border-right: none;
                                        }

                                        .usr-stat:hover {
                                            background: rgba(255, 255, 255, 0.02);
                                        }

                                        .usr-stat__num {
                                            font-family: var(--font-display);
                                            font-size: 1.5rem;
                                            font-weight: 800;
                                            line-height: 1;
                                            color: var(--clr-text);
                                        }

                                        .usr-stat__num.red {
                                            color: var(--clr-red);
                                        }

                                        .usr-stat__num.green {
                                            color: var(--clr-success);
                                        }

                                        .usr-stat__num.blue {
                                            color: var(--clr-info);
                                        }

                                        .usr-stat__num.dim {
                                            color: var(--clr-text-dim);
                                        }

                                        .usr-stat__label {
                                            font-size: 0.65rem;
                                            font-weight: 700;
                                            letter-spacing: 0.09em;
                                            text-transform: uppercase;
                                            color: var(--clr-text-dim);
                                        }

                                        /* ── Panel "Reset Password" (modal-less, inline form) ─── */
                                        .reset-pw-form {
                                            display: inline-flex;
                                            align-items: center;
                                            gap: 0.4rem;
                                        }

                                        .reset-pw-input {
                                            width: 140px;
                                            padding: 0.35rem 0.65rem;
                                            background: var(--clr-surface);
                                            border: 1px solid var(--clr-border);
                                            border-radius: var(--radius-sm);
                                            color: var(--clr-text);
                                            font-size: 0.78rem;
                                            outline: none;
                                            transition: border-color var(--transition), box-shadow var(--transition);
                                        }

                                        .reset-pw-input:focus {
                                            border-color: var(--clr-red);
                                            box-shadow: 0 0 0 2px var(--clr-red-glow);
                                        }

                                        .reset-pw-input::placeholder {
                                            color: var(--clr-text-dim);
                                            font-size: 0.72rem;
                                        }

                                        /* ── Info de usuario vinculado (empleado) en tabla ───── */
                                        .usr-emp-info {
                                            display: flex;
                                            flex-direction: column;
                                            gap: 0.1rem;
                                        }

                                        .usr-emp-info__nombre {
                                            font-size: 0.82rem;
                                            font-weight: 500;
                                            color: var(--clr-text);
                                        }

                                        .usr-emp-info__email {
                                            font-size: 0.70rem;
                                            color: var(--clr-text-dim);
                                            white-space: nowrap;
                                            overflow: hidden;
                                            text-overflow: ellipsis;
                                            max-width: 180px;
                                        }

                                        /* ── Aviso de seguridad en el formulario ──────────────── */
                                        .security-tip {
                                            display: flex;
                                            align-items: flex-start;
                                            gap: 0.6rem;
                                            padding: 0.85rem 1rem;
                                            background: rgba(245, 158, 11, 0.07);
                                            border: 1px solid rgba(245, 158, 11, 0.22);
                                            border-radius: var(--radius-md);
                                        }

                                        .security-tip svg {
                                            flex-shrink: 0;
                                            width: 15px;
                                            height: 15px;
                                            color: var(--clr-warning);
                                            margin-top: 1px;
                                        }

                                        .security-tip p {
                                            font-size: 0.78rem;
                                            color: #fcd34d;
                                            line-height: 1.5;
                                        }

                                        /* ── Ícono de candado en columna email ─────────────────── */
                                        .email-cell {
                                            display: flex;
                                            align-items: center;
                                            gap: 0.45rem;
                                        }

                                        .email-cell svg {
                                            width: 12px;
                                            height: 12px;
                                            color: var(--clr-text-dim);
                                            flex-shrink: 0;
                                        }

                                        /* ── Acciones de toggle con confirmación ──────────────── */
                                        .toggle-form {
                                            display: inline;
                                        }

                                        /* ── Tag "propio usuario" ─────────────────────────────── */
                                        .you-tag {
                                            display: inline-flex;
                                            align-items: center;
                                            gap: 0.25rem;
                                            padding: 0.12rem 0.45rem;
                                            border-radius: var(--radius-full);
                                            font-size: 0.60rem;
                                            font-weight: 700;
                                            letter-spacing: 0.06em;
                                            text-transform: uppercase;
                                            background: var(--clr-red-subtle);
                                            color: var(--clr-red);
                                            border: 1px solid rgba(230, 48, 39, 0.20);
                                            vertical-align: middle;
                                            margin-left: 0.35rem;
                                        }

                                        /* ── Animaciones ──────────────────────────────────────── */
                                        @media (max-width: 1024px) {
                                            .usr-stats-strip {
                                                grid-template-columns: repeat(2, 1fr);
                                            }

                                            .usr-stat:nth-child(2) {
                                                border-right: none;
                                            }

                                            .usr-stat:nth-child(3) {
                                                border-top: 1px solid var(--clr-border-light);
                                            }
                                        }

                                        @media (max-width: 640px) {
                                             .usr-stats-strip {
                                                 grid-template-columns: 1fr 1fr;
                                             }

                                             .reset-pw-form {
                                                 flex-direction: column;
                                                 align-items: flex-start;
                                             }

                                             .reset-pw-input {
                                                 width: 120px;
                                             }
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
                                             background: var(--clr-card); width: 100%; max-width: 520px;
                                             border-radius: var(--radius-xl); border: 1px solid var(--clr-card-border);
                                             box-shadow: 0 20px 40px rgba(0,0,0,0.5);
                                             transform: translateY(20px); transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
                                             max-height: 90vh; overflow-y: auto;
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
                                         .form-row-custom {
                                             display: grid; grid-template-columns: 1fr 1fr;
                                             gap: 1rem; margin-bottom: 1.25rem;
                                         }
                                         @media (max-width: 480px) { .form-row-custom { grid-template-columns: 1fr; } }
                                     </style>
                            </head>

                            <body>

                                <div class="app-shell">
                                    <%@ include file="/WEB-INF/views/includes/sidebar.jsp" %>

                                        <div class="app-main">

                                            <c:choose>
                                                <c:when test="${param.form eq 'true'}">
                                                    <c:set var="pageTitle"
                                                        value="${modoEdicion ? 'Editar Usuario' : 'Nuevo Usuario'}"
                                                        scope="request" />
                                                    <c:set var="pageSubtitle" value="Módulo de Usuarios"
                                                        scope="request" />
                                                </c:when>
                                                <c:otherwise>
                                                    <c:set var="pageTitle" value="Usuarios" scope="request" />
                                                    <c:set var="pageSubtitle" value="Gestión de accesos al sistema"
                                                        scope="request" />
                                                </c:otherwise>
                                            </c:choose>
                                            <%@ include file="/WEB-INF/views/includes/navbar.jsp" %>

                                                <div class="page-content">

                                                    <%-- ═══════════════════════════════════════════════ BIFURCACIÓN:
                                                        lista ↔ formulario
                                                        ═══════════════════════════════════════════════ --%>
                                                        <c:choose>

                                                            <%-- ────────────────────────────────────────── VISTA:
                                                                FORMULARIO (nuevo o edición) param.form=true
                                                                ────────────────────────────────────────── --%>
                                                                <c:when test="${param.form eq 'true'}">

                                                                    <%-- Breadcrumb --%>
                                                                        <nav class="module-breadcrumb"
                                                                            aria-label="Breadcrumb">
                                                                            <a
                                                                                href="${pageContext.request.contextPath}/users">Usuarios</a>
                                                                            <svg class="module-breadcrumb__sep"
                                                                                xmlns="http://www.w3.org/2000/svg"
                                                                                fill="none" viewBox="0 0 24 24"
                                                                                stroke="currentColor" stroke-width="2">
                                                                                <path stroke-linecap="round"
                                                                                    stroke-linejoin="round"
                                                                                    d="M9 5l7 7-7 7" />
                                                                            </svg>
                                                                            <span>${modoEdicion ? 'Editar' :
                                                                                'Nuevo'}</span>
                                                                        </nav>

                                                                        <%-- Header --%>
                                                                            <div class="module-header">
                                                                                <div class="module-header__left">
                                                                                    <h1 class="module-header__title">
                                                                                        <c:choose>
                                                                                            <c:when
                                                                                                test="${modoEdicion}">
                                                                                                Editar Usuario</c:when>
                                                                                            <c:otherwise>Crear Usuario
                                                                                            </c:otherwise>
                                                                                        </c:choose>
                                                                                    </h1>
                                                                                    <div class="module-header__meta">
                                                                                        <span>Configura el acceso al
                                                                                            sistema</span>
                                                                                        <span
                                                                                            class="module-header__meta-sep"></span>
                                                                                        <span>Los campos con * son
                                                                                            obligatorios</span>
                                                                                    </div>
                                                                                </div>
                                                                                <div class="module-header__actions">
                                                                                    <a href="${pageContext.request.contextPath}/users"
                                                                                        class="btn btn-secondary">
                                                                                        <svg xmlns="http://www.w3.org/2000/svg"
                                                                                            fill="none"
                                                                                            viewBox="0 0 24 24"
                                                                                            stroke="currentColor"
                                                                                            stroke-width="1.8">
                                                                                            <path stroke-linecap="round"
                                                                                                stroke-linejoin="round"
                                                                                                d="M10.5 19.5 3 12m0 0 7.5-7.5M3 12h18" />
                                                                                        </svg>
                                                                                        Cancelar
                                                                                    </a>
                                                                                </div>
                                                                            </div>

                                                                            <%-- Alerta de error --%>
                                                                                <c:if test="${not empty formError}">
                                                                                    <div class="module-alert module-alert--error"
                                                                                        role="alert">
                                                                                        <svg class="module-alert__icon"
                                                                                            xmlns="http://www.w3.org/2000/svg"
                                                                                            fill="none"
                                                                                            viewBox="0 0 24 24"
                                                                                            stroke="currentColor"
                                                                                            stroke-width="2">
                                                                                            <path stroke-linecap="round"
                                                                                                stroke-linejoin="round"
                                                                                                d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73
                                         0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898
                                         0L2.697 16.126ZM12 15.75h.007v.008H12v-.008Z" />
                                                                                        </svg>
                                                                                        <div class="module-alert__body">
                                                                                            <p
                                                                                                class="module-alert__title">
                                                                                                Error de validación</p>
                                                                                            <p
                                                                                                class="module-alert__text">
                                                                                                <c:out
                                                                                                    value="${formError}" />
                                                                                            </p>
                                                                                        </div>
                                                                                    </div>
                                                                                </c:if>

                                                                                <%-- Formulario principal --%>
                                                                                    <form
                                                                                        action="${pageContext.request.contextPath}/users"
                                                                                        method="post" novalidate
                                                                                        autocomplete="off">

                                                                                        <input type="hidden"
                                                                                            name="action" value="save">
                                                                                        <input type="hidden"
                                                                                            name="_csrf"
                                                                                            value="${sessionScope._csrfToken}">

                                                                                        <c:if test="${modoEdicion}">
                                                                                            <input type="hidden"
                                                                                                name="id"
                                                                                                value="<c:out value='${usuario.id}'/>">
                                                                                        </c:if>

                                                                                        <div
                                                                                            class="form-card form-card--wide">

                                                                                            <div
                                                                                                class="form-card__header">
                                                                                                <div
                                                                                                    class="form-card__header-icon">
                                                                                                    <svg xmlns="http://www.w3.org/2000/svg"
                                                                                                        fill="none"
                                                                                                        viewBox="0 0 24 24"
                                                                                                        stroke="currentColor"
                                                                                                        stroke-width="1.8">
                                                                                                        <path
                                                                                                            stroke-linecap="round"
                                                                                                            stroke-linejoin="round"
                                                                                                            d="M15.75 5.25a3 3 0 0 1 3 3m3 0a6 6 0 0 1-7.029 5.912c-.563-.097-1.159.026-1.563.43L10.5
                                                 17.25H8.25v2.25H6v2.25H2.25v-2.818c0-.597.237-1.17.659-1.591l6.499-6.499c.404-.404.527-1
                                                 .43-1.563A6 6 0 0 1 21.75 8.25Z" />
                                                                                                    </svg>
                                                                                                </div>
                                                                                                <div>
                                                                                                    <p
                                                                                                        class="form-card__header-title">
                                                                                                        ${modoEdicion ?
                                                                                                        'Datos del
                                                                                                        Usuario' :
                                                                                                        'Nueva Cuenta de
                                                                                                        Acceso'}
                                                                                                    </p>
                                                                                                    <p
                                                                                                        class="form-card__header-sub">
                                                                                                        <c:if
                                                                                                            test="${modoEdicion}">
                                                                                                            ID:
                                                                                                            <c:out
                                                                                                                value="${usuario.id}" />
                                                                                                        </c:if>
                                                                                                        <c:if
                                                                                                            test="${not modoEdicion}">
                                                                                                            El ID se
                                                                                                            genera
                                                                                                            automáticamente
                                                                                                        </c:if>
                                                                                                    </p>
                                                                                                </div>
                                                                                            </div>

                                                                                            <div
                                                                                                class="form-card__body">

                                                                                                <%-- Sección:
                                                                                                    Credenciales --%>
                                                                                                    <div
                                                                                                        class="form-section-divider">
                                                                                                        <span
                                                                                                            class="form-section-divider__label">Credenciales
                                                                                                            de
                                                                                                            acceso</span>
                                                                                                    </div>

                                                                                                    <div
                                                                                                        class="form-row">
                                                                                                        <%-- Email --%>
                                                                                                            <div
                                                                                                                class="form-field">
                                                                                                                <label
                                                                                                                    for="email">
                                                                                                                    Correo
                                                                                                                    electrónico
                                                                                                                    <span
                                                                                                                        class="required-star">*</span>
                                                                                                                </label>
                                                                                                                <input
                                                                                                                    type="email"
                                                                                                                    id="email"
                                                                                                                    name="email"
                                                                                                                    class="form-control"
                                                                                                                    placeholder="usuario@maxfit.com"
                                                                                                                    maxlength="150"
                                                                                                                    required
                                                                                                                    autocomplete="off"
                                                                                                                    value="<c:out value='${usuario.email}'/>">
                                                                                                                <span
                                                                                                                    class="form-field__hint">
                                                                                                                    Será
                                                                                                                    el
                                                                                                                    nombre
                                                                                                                    de
                                                                                                                    usuario
                                                                                                                    para
                                                                                                                    iniciar
                                                                                                                    sesión
                                                                                                                </span>
                                                                                                            </div>

                                                                                                            <%-- Contraseña
                                                                                                                (solo en
                                                                                                                creación)
                                                                                                                --%>
                                                                                                                <div
                                                                                                                    class="form-field">
                                                                                                                    <label
                                                                                                                        for="password">
                                                                                                                        Contraseña
                                                                                                                        <c:if
                                                                                                                            test="${not modoEdicion}">
                                                                                                                            <span
                                                                                                                                class="required-star">*</span>
                                                                                                                        </c:if>
                                                                                                                    </label>
                                                                                                                    <input
                                                                                                                        type="password"
                                                                                                                        id="password"
                                                                                                                        name="password"
                                                                                                                        class="form-control"
                                                                                                                        placeholder="${modoEdicion ? 'Sin cambios — usa Resetear contraseña' : 'Mínimo 8 caracteres'}"
                                                                                                                        minlength="${not modoEdicion ? '8' : ''}"
                                                                                                                        maxlength="255"
                                                                                                                        ${not
                                                                                                                        modoEdicion
                                                                                                                        ? 'required'
                                                                                                                        : 'disabled'
                                                                                                                        }
                                                                                                                        autocomplete="new-password">
                                                                                                                    <span
                                                                                                                        class="form-field__hint">
                                                                                                                        <c:choose>
                                                                                                                            <c:when
                                                                                                                                test="${modoEdicion}">
                                                                                                                                La
                                                                                                                                contraseña
                                                                                                                                actual
                                                                                                                                se
                                                                                                                                conserva.
                                                                                                                                Para
                                                                                                                                cambiarla
                                                                                                                                usa
                                                                                                                                "Resetear
                                                                                                                                contraseña".
                                                                                                                            </c:when>
                                                                                                                            <c:otherwise>
                                                                                                                                Mínimo
                                                                                                                                8
                                                                                                                                caracteres.
                                                                                                                            </c:otherwise>
                                                                                                                        </c:choose>
                                                                                                                    </span>
                                                                                                                </div>
                                                                                                    </div>

                                                                                                    <%-- Sección: Rol y
                                                                                                        empleado --%>
                                                                                                        <div
                                                                                                            class="form-section-divider">
                                                                                                            <span
                                                                                                                class="form-section-divider__label">Rol
                                                                                                                y
                                                                                                                empleado
                                                                                                                vinculado</span>
                                                                                                        </div>

                                                                                                        <div
                                                                                                            class="form-row">
                                                                                                            <%-- Rol
                                                                                                                --%>
                                                                                                                <div
                                                                                                                    class="form-field">
                                                                                                                    <label
                                                                                                                        for="idRol">
                                                                                                                        Rol
                                                                                                                        del
                                                                                                                        sistema
                                                                                                                        <span
                                                                                                                            class="required-star">*</span>
                                                                                                                    </label>
                                                                                                                    <select
                                                                                                                        id="idRol"
                                                                                                                        name="idRol"
                                                                                                                        class="form-control"
                                                                                                                        required>
                                                                                                                        <option
                                                                                                                            value="">
                                                                                                                            —
                                                                                                                            Seleccionar
                                                                                                                            rol
                                                                                                                            —
                                                                                                                        </option>
                                                                                                                        <c:forEach
                                                                                                                            var="rol"
                                                                                                                            items="${roles}">
                                                                                                                            <option
                                                                                                                                value="<c:out value='${rol.id}'/>"
                                                                                                                                ${usuario.rol
                                                                                                                                !=null
                                                                                                                                and
                                                                                                                                usuario.rol.id
                                                                                                                                eq
                                                                                                                                rol.id
                                                                                                                                ? 'selected'
                                                                                                                                : ''
                                                                                                                                }>
                                                                                                                                <c:out
                                                                                                                                    value="${rol.nombreRol}" />
                                                                                                                                <c:if
                                                                                                                                    test="${not empty rol.descripcion}">
                                                                                                                                    —
                                                                                                                                    <c:out
                                                                                                                                        value="${rol.descripcion}" />
                                                                                                                                </c:if>
                                                                                                                            </option>
                                                                                                                        </c:forEach>
                                                                                                                    </select>
                                                                                                                    <span
                                                                                                                        class="form-field__hint">
                                                                                                                        El
                                                                                                                        rol
                                                                                                                        determina
                                                                                                                        qué
                                                                                                                        módulos
                                                                                                                        puede
                                                                                                                        ver
                                                                                                                        y
                                                                                                                        usar
                                                                                                                        el
                                                                                                                        usuario
                                                                                                                    </span>
                                                                                                                </div>

                                                                                                                <%-- Empleado
                                                                                                                    vinculado
                                                                                                                    --%>
                                                                                                                    <div
                                                                                                                        class="form-field">
                                                                                                                        <label
                                                                                                                            for="idEmpleado">Empleado
                                                                                                                            vinculado</label>
                                                                                                                        <select
                                                                                                                            id="idEmpleado"
                                                                                                                            name="idEmpleado"
                                                                                                                            class="form-control">
                                                                                                                            <option
                                                                                                                                value="">
                                                                                                                                —
                                                                                                                                Sin
                                                                                                                                empleado
                                                                                                                                vinculado
                                                                                                                                —
                                                                                                                            </option>
                                                                                                                            <c:forEach
                                                                                                                                var="emp"
                                                                                                                                items="${empleados}">
                                                                                                                                <option
                                                                                                                                    value="<c:out value='${emp.id}'/>"
                                                                                                                                    ${usuario.empleado
                                                                                                                                    !=null
                                                                                                                                    and
                                                                                                                                    usuario.empleado.id
                                                                                                                                    eq
                                                                                                                                    emp.id
                                                                                                                                    ? 'selected'
                                                                                                                                    : ''
                                                                                                                                    }>
                                                                                                                                    <c:out
                                                                                                                                        value="${emp.apellido}" />
                                                                                                                                    ,
                                                                                                                                    <c:out
                                                                                                                                        value="${emp.nombre}" />
                                                                                                                                    <c:if
                                                                                                                                        test="${emp.cargo != null}">
                                                                                                                                        —
                                                                                                                                        <c:out
                                                                                                                                            value="${emp.cargo.nombre}" />
                                                                                                                                    </c:if>
                                                                                                                                </option>
                                                                                                                            </c:forEach>
                                                                                                                        </select>
                                                                                                                        <span
                                                                                                                            class="form-field__hint">
                                                                                                                            Vincular
                                                                                                                            permite
                                                                                                                            al
                                                                                                                            sistema
                                                                                                                            identificar
                                                                                                                            al
                                                                                                                            empleado
                                                                                                                            que
                                                                                                                            usa
                                                                                                                            la
                                                                                                                            cuenta.
                                                                                                                            Opcional
                                                                                                                            pero
                                                                                                                            recomendado.
                                                                                                                        </span>
                                                                                                                    </div>
                                                                                                        </div>

                                                                                                        <%-- Nota sobre
                                                                                                            accesos por
                                                                                                            rol --%>
                                                                                                            <div class="module-alert module-alert--info"
                                                                                                                style="margin-bottom:0;">
                                                                                                                <svg class="module-alert__icon"
                                                                                                                    xmlns="http://www.w3.org/2000/svg"
                                                                                                                    fill="none"
                                                                                                                    viewBox="0 0 24 24"
                                                                                                                    stroke="currentColor"
                                                                                                                    stroke-width="2">
                                                                                                                    <path
                                                                                                                        stroke-linecap="round"
                                                                                                                        stroke-linejoin="round"
                                                                                                                        d="m11.25 11.25.041-.02a.75.75 0 0 1 1.063.852l-.708 2.836a.75.75
                                                 0 0 0 1.063.853l.041-.021M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9-3.75h.008v.008H12V8.25Z" />
                                                                                                                </svg>
                                                                                                                <div
                                                                                                                    class="module-alert__body">
                                                                                                                    <p
                                                                                                                        class="module-alert__text">
                                                                                                                        <strong>ROL-ADMIN</strong>:
                                                                                                                        acceso
                                                                                                                        completo
                                                                                                                        ·
                                                                                                                        <strong>ROL-RECEP</strong>:
                                                                                                                        clientes,
                                                                                                                        contratos,
                                                                                                                        asistencia,
                                                                                                                        membresías
                                                                                                                        ·
                                                                                                                        <strong>ROL-TRAINER</strong>:
                                                                                                                        solo
                                                                                                                        su
                                                                                                                        panel
                                                                                                                        de
                                                                                                                        clases
                                                                                                                        e
                                                                                                                        inscripciones
                                                                                                                    </p>
                                                                                                                </div>
                                                                                                            </div>

                                                                                            </div><%-- /form-card__body
                                                                                                --%>

                                                                                                <div
                                                                                                    class="form-card__footer">
                                                                                                    <button
                                                                                                        type="submit"
                                                                                                        class="btn btn-primary">
                                                                                                        <svg xmlns="http://www.w3.org/2000/svg"
                                                                                                            fill="none"
                                                                                                            viewBox="0 0 24 24"
                                                                                                            stroke="currentColor"
                                                                                                            stroke-width="2">
                                                                                                            <path
                                                                                                                stroke-linecap="round"
                                                                                                                stroke-linejoin="round"
                                                                                                                d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
                                                                                                        </svg>
                                                                                                        ${modoEdicion ?
                                                                                                        'Guardar
                                                                                                        cambios' :
                                                                                                        'Crear usuario'}
                                                                                                    </button>
                                                                                                    <a href="${pageContext.request.contextPath}/users"
                                                                                                        class="btn btn-ghost">
                                                                                                        Cancelar
                                                                                                    </a>
                                                                                                </div>

                                                                                        </div><%-- /form-card --%>
                                                                                    </form>

                                                                </c:when>

                                                                <%-- ────────────────────────────────────────── VISTA:
                                                                    LISTA DE USUARIOS (default)
                                                                    ────────────────────────────────────────── --%>
                                                                    <c:otherwise>

                                                                        <%-- Header del módulo --%>
                                                                            <div class="module-header">
                                                                                <div class="module-header__left">
                                                                                    <h1 class="module-header__title">
                                                                                        Usuarios
                                                                                        <span class="stat-chip">
                                                                                            <c:out
                                                                                                value="${totalUsuarios}" />
                                                                                        </span>
                                                                                    </h1>
                                                                                    <div class="module-header__meta">
                                                                                        <span>Cuentas de acceso al
                                                                                            sistema</span>
                                                                                    </div>
                                                                                </div>
                                                                                <div class="module-header__actions">
                                                                                     <a href="${pageContext.request.contextPath}/employees"
                                                                                         class="btn btn-secondary">
                                                                                         <svg xmlns="http://www.w3.org/2000/svg"
                                                                                             fill="none" viewBox="0 0 24 24"
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
                                                                             1 1-4.5 0 2.25 2.25 0 0 1 4.5 0Z" />
                                                                                         </svg>
                                                                                         Empleados
                                                                                     </a>
                                                                                     <button type="button" onclick="openUserModal()"
                                                                                         class="btn btn-primary">
                                                                                         <svg xmlns="http://www.w3.org/2000/svg"
                                                                                             fill="none" viewBox="0 0 24 24"
                                                                                             stroke="currentColor" stroke-width="2.2">
                                                                                             <path stroke-linecap="round" stroke-linejoin="round"
                                                                                                 d="M12 4.5v15m7.5-7.5h-15" />
                                                                                         </svg>
                                                                                         Nuevo usuario
                                                                                     </button>
                                                                                 </div>
                                                                            </div>

                                                                            <%-- Stats strip --%>
                                                                                <c:if test="${not empty usuarios}">
                                                                                    <c:set var="cntActivos" value="0" />
                                                                                    <c:set var="cntInactivos"
                                                                                        value="0" />
                                                                                    <c:set var="cntAdmin" value="0" />
                                                                                    <c:set var="cntNoAdmin" value="0" />
                                                                                    <c:forEach var="u"
                                                                                        items="${usuarios}">
                                                                                        <c:if test="${u.activo}">
                                                                                            <c:set var="cntActivos"
                                                                                                value="${cntActivos + 1}" />
                                                                                        </c:if>
                                                                                        <c:if test="${not u.activo}">
                                                                                            <c:set var="cntInactivos"
                                                                                                value="${cntInactivos + 1}" />
                                                                                        </c:if>
                                                                                        <c:if
                                                                                            test="${u.rol != null and fn:contains(u.rol.id,'ADMIN')}">
                                                                                            <c:set var="cntAdmin"
                                                                                                value="${cntAdmin + 1}" />
                                                                                        </c:if>
                                                                                        <c:if
                                                                                            test="${u.rol != null and not fn:contains(u.rol.id,'ADMIN')}">
                                                                                            <c:set var="cntNoAdmin"
                                                                                                value="${cntNoAdmin + 1}" />
                                                                                        </c:if>
                                                                                    </c:forEach>

                                                                                    <div class="usr-stats-strip">
                                                                                        <div class="usr-stat">
                                                                                            <span class="usr-stat__num">
                                                                                                <c:out
                                                                                                    value="${totalUsuarios}" />
                                                                                            </span>
                                                                                            <span
                                                                                                class="usr-stat__label">Total
                                                                                                cuentas</span>
                                                                                        </div>
                                                                                        <div class="usr-stat">
                                                                                            <span
                                                                                                class="usr-stat__num green">
                                                                                                <c:out
                                                                                                    value="${cntActivos}" />
                                                                                            </span>
                                                                                            <span
                                                                                                class="usr-stat__label">Activas</span>
                                                                                        </div>
                                                                                        <div class="usr-stat">
                                                                                            <span
                                                                                                class="usr-stat__num dim">
                                                                                                <c:out
                                                                                                    value="${cntInactivos}" />
                                                                                            </span>
                                                                                            <span
                                                                                                class="usr-stat__label">Inactivas</span>
                                                                                        </div>
                                                                                        <div class="usr-stat">
                                                                                            <span
                                                                                                class="usr-stat__num red">
                                                                                                <c:out
                                                                                                    value="${cntAdmin}" />
                                                                                            </span>
                                                                                            <span
                                                                                                class="usr-stat__label">Administradores</span>
                                                                                        </div>
                                                                                    </div>
                                                                                </c:if>

                                                                                <%-- Tabla de usuarios --%>
                                                                                    <div class="module-table-wrapper">
                                                                                        <c:choose>
                                                                                            <c:when
                                                                                                test="${not empty usuarios}">
                                                                                                <table
                                                                                                    class="module-table"
                                                                                                    aria-label="Lista de usuarios del sistema">
                                                                                                    <thead>
                                                                                                        <tr>
                                                                                                            <th
                                                                                                                scope="col">
                                                                                                                Usuario
                                                                                                            </th>
                                                                                                            <th
                                                                                                                scope="col">
                                                                                                                Empleado
                                                                                                                vinculado
                                                                                                            </th>
                                                                                                            <th
                                                                                                                scope="col">
                                                                                                                Rol</th>
                                                                                                            <th
                                                                                                                scope="col">
                                                                                                                Estado
                                                                                                            </th>
                                                                                                            <th
                                                                                                                scope="col">
                                                                                                                Resetear
                                                                                                                contraseña
                                                                                                            </th>
                                                                                                            <th scope="col"
                                                                                                                aria-label="Acciones">
                                                                                                            </th>
                                                                                                        </tr>
                                                                                                    </thead>
                                                                                                    <tbody>
                                                                                                        <c:forEach
                                                                                                            var="usr"
                                                                                                            items="${usuarios}"
                                                                                                            varStatus="loop">
                                                                                                            <c:set
                                                                                                                var="esMiCuenta"
                                                                                                                value="${usr.id eq sessionScope.userId}" />
                                                                                                            <tr>

                                                                                                                <%-- Email
                                                                                                                    + ID
                                                                                                                    --%>
                                                                                                                    <td>
                                                                                                                        <div
                                                                                                                            class="email-cell">
                                                                                                                            <svg xmlns="http://www.w3.org/2000/svg"
                                                                                                                                fill="none"
                                                                                                                                viewBox="0 0 24 24"
                                                                                                                                stroke="currentColor"
                                                                                                                                stroke-width="1.8">
                                                                                                                                <path
                                                                                                                                    stroke-linecap="round"
                                                                                                                                    stroke-linejoin="round"
                                                                                                                                    d="M21.75 6.75v10.5a2.25 2.25 0 0 1-2.25
                                                                     2.25h-15a2.25 2.25 0 0 1-2.25-2.25V6.75m19.5
                                                                     0A2.25 2.25 0 0 0 19.5 4.5h-15a2.25 2.25 0 0
                                                                     0-2.25 2.25m19.5 0v.243a2.25 2.25 0 0
                                                                     1-1.07 1.916l-7.5 4.615a2.25 2.25 0 0
                                                                     1-2.36 0L3.32 8.91a2.25 2.25 0 0
                                                                     1-1.07-1.916V6.75" />
                                                                                                                            </svg>
                                                                                                                            <div
                                                                                                                                class="cell-name__info">
                                                                                                                                <span
                                                                                                                                    class="cell-name__primary">
                                                                                                                                    <c:out
                                                                                                                                        value="${usr.email}" />
                                                                                                                                    <c:if
                                                                                                                                        test="${esMiCuenta}">
                                                                                                                                        <span
                                                                                                                                            class="you-tag">Tú</span>
                                                                                                                                    </c:if>
                                                                                                                                </span>
                                                                                                                                <span
                                                                                                                                    class="cell-id"
                                                                                                                                    style="margin-top:0.15rem;">
                                                                                                                                    <c:out
                                                                                                                                        value="${usr.id}" />
                                                                                                                                </span>
                                                                                                                            </div>
                                                                                                                        </div>
                                                                                                                    </td>

                                                                                                                    <%-- Empleado
                                                                                                                        vinculado
                                                                                                                        --%>
                                                                                                                        <td>
                                                                                                                            <c:choose>
                                                                                                                                <c:when
                                                                                                                                    test="${usr.empleado != null}">
                                                                                                                                    <div
                                                                                                                                        class="usr-emp-info">
                                                                                                                                        <span
                                                                                                                                            class="usr-emp-info__nombre">
                                                                                                                                            <c:out
                                                                                                                                                value="${usr.empleado.nombreCompleto}" />
                                                                                                                                        </span>
                                                                                                                                        <span
                                                                                                                                            class="usr-emp-info__email">
                                                                                                                                            <c:if
                                                                                                                                                test="${usr.empleado.cargo != null}">
                                                                                                                                                <c:out
                                                                                                                                                    value="${usr.empleado.cargo.nombre}" />
                                                                                                                                            </c:if>
                                                                                                                                        </span>
                                                                                                                                    </div>
                                                                                                                                </c:when>
                                                                                                                                <c:otherwise>
                                                                                                                                    <span
                                                                                                                                        style="font-size:0.78rem; color:var(--clr-text-dim);">
                                                                                                                                        Sin
                                                                                                                                        vincular
                                                                                                                                    </span>
                                                                                                                                </c:otherwise>
                                                                                                                            </c:choose>
                                                                                                                        </td>

                                                                                                                        <%-- Rol
                                                                                                                            --%>
                                                                                                                            <td>
                                                                                                                                <c:choose>
                                                                                                                                    <c:when
                                                                                                                                        test="${usr.rol != null}">
                                                                                                                                        <c:set
                                                                                                                                            var="rolId"
                                                                                                                                            value="${usr.rol.id}" />
                                                                                                                                        <c:choose>
                                                                                                                                            <c:when
                                                                                                                                                test="${fn:contains(rolId,'ADMIN')}">
                                                                                                                                                <span
                                                                                                                                                    class="rol-badge rol-badge--admin">
                                                                                                                                                    <c:out
                                                                                                                                                        value="${usr.rol.nombreRol}" />
                                                                                                                                                </span>
                                                                                                                                            </c:when>
                                                                                                                                            <c:when
                                                                                                                                                test="${fn:contains(rolId,'RECEP')}">
                                                                                                                                                <span
                                                                                                                                                    class="rol-badge rol-badge--recep">
                                                                                                                                                    <c:out
                                                                                                                                                        value="${usr.rol.nombreRol}" />
                                                                                                                                                </span>
                                                                                                                                            </c:when>
                                                                                                                                            <c:when
                                                                                                                                                test="${fn:contains(rolId,'TRAINER')}">
                                                                                                                                                <span
                                                                                                                                                    class="rol-badge rol-badge--trainer">
                                                                                                                                                    <c:out
                                                                                                                                                        value="${usr.rol.nombreRol}" />
                                                                                                                                                </span>
                                                                                                                                            </c:when>
                                                                                                                                            <c:otherwise>
                                                                                                                                                <span
                                                                                                                                                    class="rol-badge rol-badge--default">
                                                                                                                                                    <c:out
                                                                                                                                                        value="${usr.rol.nombreRol}" />
                                                                                                                                                </span>
                                                                                                                                            </c:otherwise>
                                                                                                                                        </c:choose>
                                                                                                                                    </c:when>
                                                                                                                                    <c:otherwise>
                                                                                                                                        <span
                                                                                                                                            style="font-size:0.75rem; color:var(--clr-text-dim);">
                                                                                                                                            Sin
                                                                                                                                            rol
                                                                                                                                        </span>
                                                                                                                                    </c:otherwise>
                                                                                                                                </c:choose>
                                                                                                                            </td>

                                                                                                                            <%-- Estado
                                                                                                                                --%>
                                                                                                                                <td>
                                                                                                                                    <span
                                                                                                                                        class="estado-cuenta ${usr.activo ? 'activo' : 'inactivo'}">
                                                                                                                                        <span
                                                                                                                                            class="estado-cuenta__dot"></span>
                                                                                                                                        <c:out
                                                                                                                                            value="${usr.activo ? 'Activo' : 'Inactivo'}" />
                                                                                                                                    </span>
                                                                                                                                </td>

                                                                                                                                <%-- Resetear
                                                                                                                                    contraseña
                                                                                                                                    (inline
                                                                                                                                    form)
                                                                                                                                    --%>
                                                                                                                                    <td>
                                                                                                                                        <form
                                                                                                                                            action="${pageContext.request.contextPath}/users"
                                                                                                                                            method="post"
                                                                                                                                            class="reset-pw-form"
                                                                                                                                            onsubmit="return confirm('¿Resetear la contraseña de ${usr.email}?');">
                                                                                                                                            <input
                                                                                                                                                type="hidden"
                                                                                                                                                name="action"
                                                                                                                                                value="resetPassword">
                                                                                                                                            <input
                                                                                                                                                type="hidden"
                                                                                                                                                name="id"
                                                                                                                                                value="<c:out value='${usr.id}'/>">
                                                                                                                                            <input
                                                                                                                                                type="hidden"
                                                                                                                                                name="_csrf"
                                                                                                                                                value="${sessionScope._csrfToken}">
                                                                                                                                            <input
                                                                                                                                                type="password"
                                                                                                                                                name="newPassword"
                                                                                                                                                class="reset-pw-input"
                                                                                                                                                placeholder="Nueva contraseña…"
                                                                                                                                                minlength="8"
                                                                                                                                                maxlength="255"
                                                                                                                                                autocomplete="new-password"
                                                                                                                                                aria-label="Nueva contraseña para ${usr.email}">
                                                                                                                                            <button
                                                                                                                                                type="submit"
                                                                                                                                                class="btn btn-secondary btn-sm"
                                                                                                                                                title="Aplicar nueva contraseña">
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
                                                                                                                                            </button>
                                                                                                                                        </form>
                                                                                                                                    </td>

                                                                                                                                    <%-- Acciones
                                                                                                                                        principales
                                                                                                                                        --%>
                                                                                                                                        <td>
                                                                                                                                            <div
                                                                                                                                                class="cell-actions">

                                                                                                                                                    <%-- Editar --%>
                                                                                                                                                     <button type="button"
                                                                                                                                                         class="btn btn-ghost btn-sm btn-icon"
                                                                                                                                                         title="Editar usuario"
                                                                                                                                                         onclick="openUserModal('<c:out value="${usr.id}"/>', '<c:out value="${fn:escapeXml(usr.email)}"/>', '${usr.rol != null ? usr.rol.id : ""}', '${usr.empleado != null ? usr.empleado.id : ""}')">
                                                                                                                                                         <svg xmlns="http://www.w3.org/2000/svg"
                                                                                                                                                             fill="none" viewBox="0 0 24 24"
                                                                                                                                                             stroke="currentColor" stroke-width="1.8">
                                                                                                                                                             <path stroke-linecap="round" stroke-linejoin="round"
                                                                                                                                                                 d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652
                                                                                                                                              2.652L10.582 16.07a4.5 4.5 0 0 1-1.897 1.13L6
                                                                                                                                              18l.8-2.685a4.5 4.5 0 0 1 1.13-1.897l8.932-8.931Zm0 0L19.5 7.125" />
                                                                                                                                                         </svg>
                                                                                                                                                     </button>

                                                                                                                                                    <%-- Toggle
                                                                                                                                                        estado
                                                                                                                                                        --%>
                                                                                                                                                        <c:if
                                                                                                                                                            test="${not esMiCuenta}">
                                                                                                                                                            <form
                                                                                                                                                                action="${pageContext.request.contextPath}/users"
                                                                                                                                                                method="post"
                                                                                                                                                                class="toggle-form"
                                                                                                                                                                onsubmit="openActionModal(event, '${usr.activo ? 'deactivate' : 'activate'}', '${fn:escapeXml(usr.email)}'); return false;">
                                                                                                                                                                <input
                                                                                                                                                                    type="hidden"
                                                                                                                                                                    name="action"
                                                                                                                                                                    value="toggleEstado">
                                                                                                                                                                <input
                                                                                                                                                                    type="hidden"
                                                                                                                                                                    name="id"
                                                                                                                                                                    value="<c:out value='${usr.id}'/>">
                                                                                                                                                                <input
                                                                                                                                                                    type="hidden"
                                                                                                                                                                    name="_csrf"
                                                                                                                                                                    value="${sessionScope._csrfToken}">
                                                                                                                                                                <button
                                                                                                                                                                    type="submit"
                                                                                                                                                                    class="btn ${usr.activo ? 'btn-danger' : 'btn-success'} btn-sm btn-icon"
                                                                                                                                                                    title="${usr.activo ? 'Desactivar cuenta' : 'Activar cuenta'}">
                                                                                                                                                                    <c:choose>
                                                                                                                                                                        <c:when
                                                                                                                                                                            test="${usr.activo}">
                                                                                                                                                                                <svg xmlns="http://www.w3.org/2000/svg"
                                                                                                                                                                                    fill="none"
                                                                                                                                                                                    viewBox="0 0 24 24"
                                                                                                                                                                                    stroke="currentColor"
                                                                                                                                                                                    stroke-width="1.8">
                                                                                                                                                                                    <path
                                                                                                                                                                                        stroke-linecap="round"
                                                                                                                                                                                        stroke-linejoin="round"
                                                                                                                                                                                        d="M18.364 18.364A9 9 0 0 0 5.636 5.636m12.728
                                                                                         12.728A9 9 0 0 1 5.636 5.636m12.728 12.728L5.636 5.636" />
                                                                                                                                                                                </svg>
                                                                                                                                                                        </c:when>
                                                                                                                                                                        <c:otherwise>
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
                                                                                                                                                                        </c:otherwise>
                                                                                                                                                                    </c:choose>
                                                                                                                                                                </button>
                                                                                                                                                            </form>
                                                                                                                                                        </c:if>

                                                                                                                                                        <%-- Delete button --%>
                                                                                                                                                        <c:if test="${not esMiCuenta}">
                                                                                                                                                            <form action="${pageContext.request.contextPath}/users" method="post" class="toggle-form" onsubmit="openActionModal(event, 'delete', '${fn:escapeXml(usr.email)}'); return false;">
                                                                                                                                                                <input type="hidden" name="action" value="delete">
                                                                                                                                                                <input type="hidden" name="id" value="<c:out value='${usr.id}'/>">
                                                                                                                                                                <input type="hidden" name="_csrf" value="${sessionScope._csrfToken}">
                                                                                                                                                                <button type="submit" class="btn btn-danger btn-sm btn-icon" title="Eliminar usuario">
                                                                                                                                                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                                                                                                                                        <path stroke-linecap="round" stroke-linejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
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
                                                                                                        <span
                                                                                                            style="font-size:0.75rem; color:var(--clr-text-dim);">
                                                                                                            <strong
                                                                                                                style="color:var(--clr-text-muted);">
                                                                                                                <c:out
                                                                                                                    value="${totalUsuarios}" />
                                                                                                            </strong>
                                                                                                            usuario<c:if
                                                                                                                test="${totalUsuarios ne 1}">
                                                                                                                s</c:if>
                                                                                                            registrados
                                                                                                        </span>
                                                                                                    </div>

                                                                                            </c:when>

                                                                                            <%-- Estado vacío --%>
                                                                                                <c:otherwise>
                                                                                                         <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 5.25a3 3 0 0 1 3 3m3 0a6 6 0 0 1-7.029 5.912c-.563-.097-1.159.026-1.563.43L10.5 17.25H8.25v2.25H6v2.25H2.25v-2.818c0-.597.237-1.17.659-1.591l6.499-6.499c.404-.404.527-1.43-1.563A6 6 0 0 1 21.75 8.25Z" />
                                                                                                            </svg>
                                                                                                        </div>
                                                                                                        <p class="table-empty__title">No hay usuarios registrados</p>
                                                                                                        <p class="table-empty__desc">Crea el primer usuario para dar acceso al sistema.</p>
                                                                                                        <button type="button" onclick="openUserModal()" class="btn btn-primary btn-sm" style="margin-top:0.5rem;">Crear primer usuario</button>
                                                                                                    </div>
                                                                                                </c:otherwise>
                                                                                        </c:choose>
                                                                                    </div><%-- /module-table-wrapper
                                                                                        --%>

                                                                    </c:otherwise>
                                                        </c:choose>

                                                </div><%-- /page-content --%>
                                        </div><%-- /app-main --%>
                                </div><%-- /app-shell --%>

                            
<%-- ─── Modal: Nuevo / Editar Usuario ─────────────────────────────────────── --%>
<div id="userModal" class="pm-modal-overlay">
    <div class="pm-modal" style="max-width:560px;">
        <div class="pm-modal__header">
            <span id="userModalTitle">Nuevo Usuario</span>
            <button class="pm-modal__close" type="button" onclick="closeUserModal()">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                     stroke="currentColor" stroke-width="2" width="20" height="20">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
                </svg>
            </button>
        </div>
        <form action="${pageContext.request.contextPath}/users" method="post" autocomplete="off" id="userForm">
            <input type="hidden" name="action" value="save">
            <input type="hidden" name="_csrf" value="${sessionScope._csrfToken}">
            <input type="hidden" name="id" id="userModalId">
            <div style="padding:1.5rem;">
                <p style="font-size:0.72rem;font-weight:700;letter-spacing:0.09em;text-transform:uppercase;
                           color:var(--clr-text-dim);margin-bottom:0.85rem;">Cuenta de acceso</p>

                <div style="margin-bottom:1.25rem;">
                    <label for="userModalEmail" style="display:block;font-size:0.75rem;font-weight:600;color:var(--clr-text-dim);margin-bottom:0.3rem;">
                        Correo electr&oacute;nico <span style="color:#f87171;">*</span>
                    </label>
                    <input type="email" id="userModalEmail" name="email" required maxlength="150"
                           style="width:100%;padding:0.65rem 0.75rem;border-radius:var(--radius-md);border:1px solid var(--clr-border);background:var(--clr-surface);color:var(--clr-text);font-size:0.9rem;box-sizing:border-box;">
                </div>

                <div style="margin-bottom:1.25rem;">
                    <label for="userModalPwd" style="display:block;font-size:0.75rem;font-weight:600;color:var(--clr-text-dim);margin-bottom:0.3rem;">
                        Contrase&ntilde;a <span id="userModalPwdReq" style="color:#f87171;">*</span>
                        <span id="userModalPwdHint" style="font-weight:400;color:var(--clr-text-dim);font-style:italic;"></span>
                    </label>
                    <input type="password" id="userModalPwd" name="password"
                           minlength="8" maxlength="255" autocomplete="new-password"
                           style="width:100%;padding:0.65rem 0.75rem;border-radius:var(--radius-md);border:1px solid var(--clr-border);background:var(--clr-surface);color:var(--clr-text);font-size:0.9rem;box-sizing:border-box;">
                </div>

                <p style="font-size:0.72rem;font-weight:700;letter-spacing:0.09em;text-transform:uppercase;
                           color:var(--clr-text-dim);margin-bottom:0.85rem;margin-top:1rem;">Rol y empleado</p>

                <div class="form-row-custom">
                    <div>
                        <label for="userModalRol" style="display:block;font-size:0.75rem;font-weight:600;color:var(--clr-text-dim);margin-bottom:0.3rem;">
                            Rol <span style="color:#f87171;">*</span>
                        </label>
                        <select id="userModalRol" name="idRol" required
                                style="width:100%;padding:0.65rem 0.75rem;border-radius:var(--radius-md);border:1px solid var(--clr-border);background:var(--clr-surface);color:var(--clr-text);font-size:0.9rem;box-sizing:border-box;">
                            <option value="">&#8212; Seleccionar rol &#8212;</option>
                            <c:forEach var="rol" items="${roles}">
                                <option value="<c:out value='${rol.id}'/>"><c:out value="${rol.nombreRol}"/></option>
                            </c:forEach>
                        </select>
                    </div>
                    <div>
                        <label for="userModalEmpleado" style="display:block;font-size:0.75rem;font-weight:600;color:var(--clr-text-dim);margin-bottom:0.3rem;">
                            Empleado vinculado
                        </label>
                        <select id="userModalEmpleado" name="idEmpleado"
                                style="width:100%;padding:0.65rem 0.75rem;border-radius:var(--radius-md);border:1px solid var(--clr-border);background:var(--clr-surface);color:var(--clr-text);font-size:0.9rem;box-sizing:border-box;">
                            <option value="">&#8212; Ninguno &#8212;</option>
                            <c:forEach var="emp" items="${empleados}">
                                <option value="<c:out value='${emp.id}'/>"><c:out value="${emp.nombre} ${emp.apellido}"/></option>
                            </c:forEach>
                        </select>
                    </div>
                </div>
            </div>
            <div style="padding:1rem 1.5rem;border-top:1px solid var(--clr-border);
                        display:flex;gap:0.75rem;justify-content:flex-end;background:rgba(0,0,0,0.1);">
                <button type="button" class="btn btn-secondary" onclick="closeUserModal()">Cancelar</button>
                <button type="submit" class="btn btn-primary">
                    <span id="userModalBtnText">Crear usuario</span>
                </button>
            </div>
        </form>
    </div>
</div>

<%-- ─── Modal de Confirmaci&oacute;n ────────────────────────────────────────────── --%>
<div id="actionModal" class="pm-modal-overlay">
    <div class="pm-modal" style="max-width:400px;text-align:center;padding:2rem 1.5rem;">
        <div style="margin-bottom:1.5rem;">
            <div id="actionModalIconContainer" style="width:80px;height:80px;border-radius:50%;border:3px solid;
                 display:flex;align-items:center;justify-content:center;margin:0 auto;">
                <span id="actionModalIcon" style="font-size:3.5rem;line-height:1;
                      font-family:var(--font-display);padding-bottom:0.5rem;"></span>
            </div>
        </div>
        <h2 style="font-family:var(--font-display);font-size:1.6rem;font-weight:800;color:var(--clr-text);margin-bottom:0.75rem;">&iquest;Est&aacute;s seguro?</h2>
        <p id="actionModalText" style="color:var(--clr-text-dim);font-size:0.95rem;margin-bottom:1.75rem;line-height:1.5;"></p>
        <div style="display:flex;gap:0.75rem;justify-content:center;">
            <button type="button" class="btn" id="btnConfirmAction"
                    onclick="confirmAction()" style="min-width:120px;font-weight:bold;"></button>
            <button type="button" class="btn btn-secondary" onclick="closeActionModal()"
                    style="min-width:120px;font-weight:bold;background:#473f3f;border-color:#473f3f;">Cancelar</button>
        </div>
    </div>
</div>

<script>
    var userModal = document.getElementById('userModal');
    var userForm  = document.getElementById('userForm');

    function openUserModal(id, email, idRol, idEmpleado) {
        var isEdit = (id !== undefined && id !== null && id !== '');
        document.getElementById('userModalTitle').textContent = isEdit ? 'Editar Usuario' : 'Nuevo Usuario';
        document.getElementById('userModalBtnText').textContent = isEdit ? 'Guardar cambios' : 'Crear usuario';
        document.getElementById('userModalId').value = isEdit ? id : '';
        document.getElementById('userModalEmail').value = isEdit ? (email || '') : '';
        document.getElementById('userModalRol').value = isEdit ? (idRol || '') : '';
        document.getElementById('userModalEmpleado').value = isEdit ? (idEmpleado || '') : '';
        var pwdInput = document.getElementById('userModalPwd');
        var pwdHint  = document.getElementById('userModalPwdHint');
        var pwdReq   = document.getElementById('userModalPwdReq');
        if (isEdit) {
            pwdInput.required = false;
            pwdHint.textContent = '(dejar vac\u00edo para no cambiar)';
            if (pwdReq) pwdReq.style.display = 'none';
        } else {
            pwdInput.required = true;
            pwdHint.textContent = '';
            if (pwdReq) pwdReq.style.display = '';
        }
        userModal.classList.add('is-open');
        document.body.style.overflow = 'hidden';
    }

    function closeUserModal() {
        userModal.classList.remove('is-open');
        userForm.reset();
        document.body.style.overflow = '';
    }

    var formToSubmit = null;

    function openActionModal(event, type, name) {
        event.preventDefault();
        formToSubmit = event.currentTarget.closest('form');
        var iconContainer = document.getElementById('actionModalIconContainer');
        var icon = document.getElementById('actionModalIcon');
        var text = document.getElementById('actionModalText');
        var btn  = document.getElementById('btnConfirmAction');
        if (type === 'delete') {
            iconContainer.style.borderColor = '#f87171';
            iconContainer.style.background  = 'rgba(248,113,113,0.1)';
            icon.style.color = '#f87171'; icon.textContent = '!';
            text.innerHTML = 'Se eliminar\u00e1 permanentemente la cuenta de<br><strong>' + name + '</strong><br><br><span style="font-size:0.8rem">Solo se permite si no está relacionado a clientes, contratos u horarios.</span>';
            btn.className = 'btn btn-primary'; btn.textContent = 'S\u00ed, eliminar';
        } else if (type === 'deactivate') {
            iconContainer.style.borderColor = '#fbbf24';
            iconContainer.style.background  = 'rgba(251,191,36,0.1)';
            icon.style.color = '#fbbf24'; icon.textContent = '!';
            text.innerHTML = 'Se desactivar\u00e1 la cuenta de<br><strong>' + name + '</strong>';
            btn.className = 'btn btn-primary'; btn.textContent = 'S\u00ed, desactivar';
        } else if (type === 'activate') {
            iconContainer.style.borderColor = '#34d399';
            iconContainer.style.background  = 'rgba(52,211,153,0.1)';
            icon.style.color = '#34d399'; icon.textContent = '\u2713';
            text.innerHTML = 'Se activar\u00e1 la cuenta de<br><strong>' + name + '</strong>';
            btn.className = 'btn btn-primary'; btn.textContent = 'S\u00ed, activar';
        }
        document.getElementById('actionModal').classList.add('is-open');
    }

    function closeActionModal() {
        formToSubmit = null;
        document.getElementById('actionModal').classList.remove('is-open');
    }

    function confirmAction() {
        if (formToSubmit) formToSubmit.submit();
    }
</script>

</body>

                            </html>