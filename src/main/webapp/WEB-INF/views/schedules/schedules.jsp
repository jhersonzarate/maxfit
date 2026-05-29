<%-- ============================================================
     schedules.jsp  —  MaxFit Sistema de Gestión
     Módulo de clases grupales, horarios e inscripciones (RF-08, RF-09, RF-10, RF-11).

     Servlet:  SchedulesController.java  → GET/POST /schedules
     Acceso:   ROL-ADMIN | ROL-RECEP | ROL-TRAINER (RoleFilter)

     ── Parámetros de URL que activan vistas ──────────────────
       /schedules                          → lista de clases (default)
       /schedules?form=true                → formulario nueva/editar clase (solo admin)
       /schedules?action=horarios&id=...   → gestión de horarios de una clase (solo admin)
       /schedules?action=inscritos&id=...  → inscritos + formulario inscripción

     ── Atributos de request ─────────────────────────────────

     Vista lista (default):
       clases       (List<Clase>)        → todas las clases con estado
       totalClases  (int)                → tamaño de la lista

     Vista formulario (?form=true):
       clase        (Clase)              → vacío (nuevo) o cargado (edición)
       entrenadores (List<Empleado>)     → solo cargo TRAINER
       tiposClase   (List<TipoClase>)    → catálogo de tipos
       modoEdicion  (Boolean)            → false=nuevo, true=editar

     Vista horarios (?action=horarios):
       clase     (Clase)                 → clase padre
       horarios  (List<Horario>)         → todos sus horarios

     Vista inscritos (?action=inscritos):
       clase          (Clase)                      → clase padre
       inscritos      (List<InscripcionClase>)     → alumnos inscritos
       clientes       (List<Cliente>)              → para el select
       cuposOcupados  (int)
       cuposTotal     (int)
       cuposLibres    (int)

     Flash (via transferirFlashMessages):
       successMsg / errorMsg

     Sesión:
       sessionScope.userRole  → condiciona botones de admin
     ============================================================ --%>
<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="fn"  uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <%@ include file="/WEB-INF/views/includes/head-common.jsp" %>

    <%-- Título dinámico --%>
    <c:choose>
        <c:when test="${param.form eq 'true'}">
            <c:set var="pageTitle" value="${modoEdicion ? 'Editar Clase' : 'Nueva Clase'}" scope="request"/>
        </c:when>
        <c:when test="${param.action eq 'horarios'}">
            <c:set var="pageTitle" value="Horarios de Clase" scope="request"/>
        </c:when>
        <c:when test="${param.action eq 'inscritos'}">
            <c:set var="pageTitle" value="Inscritos en Clase" scope="request"/>
        </c:when>
        <c:otherwise>
            <c:set var="pageTitle" value="Clases y Horarios" scope="request"/>
        </c:otherwise>
    </c:choose>

    <link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/modules.css">

    <style>
        /* ══════════════════════════════════════════════════════
           ESTILOS ESPECÍFICOS — MÓDULO SCHEDULES
           ══════════════════════════════════════════════════════ */

        /* ── Grid de tarjetas de clases ─────────────────────── */
        .classes-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
            gap: 1.1rem;
        }

        /* ── Tarjeta individual de clase ─────────────────────── */
        .class-card {
            background: var(--clr-card);
            border: 1px solid var(--clr-card-border);
            border-radius: var(--radius-xl);
            overflow: hidden;
            position: relative;
            display: flex;
            flex-direction: column;
            transition: border-color var(--transition), transform var(--transition),
                        box-shadow var(--transition);
            animation: fadeSlideUp 0.42s cubic-bezier(0.4,0,0.2,1) both;
        }

        .class-card:hover {
            border-color: rgba(230,48,39,0.28);
            transform: translateY(-3px);
            box-shadow: 0 10px 36px rgba(0,0,0,0.45);
        }

        .class-card.is-suspended {
            opacity: 0.65;
        }

        .class-card.is-suspended:hover {
            opacity: 0.85;
        }

        /* Franja de color superior según tipo */
        .class-card__stripe {
            height: 3px;
            width: 100%;
        }

        /* Paleta por tipo de clase */
        .class-card[data-tipo="TCL-CARDIO"]    .class-card__stripe { background: #e63027; }
        .class-card[data-tipo="TCL-YOGA"]      .class-card__stripe { background: #a78bfa; }
        .class-card[data-tipo="TCL-BOX"]       .class-card__stripe { background: #f97316; }
        .class-card[data-tipo="TCL-FUNCIONAL"] .class-card__stripe { background: #2dd4bf; }
        .class-card__stripe.stripe--default    { background: var(--clr-red); }

        /* Colores por índice (fallback) */
        .class-card.color--0 .class-card__stripe { background: #e63027; }
        .class-card.color--1 .class-card__stripe { background: #a78bfa; }
        .class-card.color--2 .class-card__stripe { background: #f97316; }
        .class-card.color--3 .class-card__stripe { background: #2dd4bf; }
        .class-card.color--4 .class-card__stripe { background: #22c55e; }
        .class-card.color--5 .class-card__stripe { background: #3b82f6; }

        /* Header de la tarjeta */
        .class-card__header {
            padding: 1.15rem 1.3rem 0.75rem;
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 0.75rem;
        }

        .class-card__meta {
            flex: 1;
            min-width: 0;
        }

        .class-card__tipo {
            font-size: 0.65rem;
            font-weight: 700;
            letter-spacing: 0.12em;
            text-transform: uppercase;
            color: var(--clr-text-dim);
            margin-bottom: 0.2rem;
        }

        .class-card__nombre {
            font-family: var(--font-display);
            font-weight: 800;
            font-size: 1.1rem;
            letter-spacing: 0.03em;
            text-transform: uppercase;
            color: var(--clr-text);
            line-height: 1.2;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        /* Badge de estado de la clase */
        .class-estado-badge {
            flex-shrink: 0;
            display: inline-flex;
            align-items: center;
            gap: 0.28rem;
            padding: 0.22rem 0.65rem;
            border-radius: var(--radius-full);
            font-size: 0.64rem;
            font-weight: 700;
            letter-spacing: 0.07em;
            text-transform: uppercase;
            white-space: nowrap;
        }

        .class-estado-badge::before {
            content: '';
            width: 5px;
            height: 5px;
            border-radius: 50%;
            background: currentColor;
            flex-shrink: 0;
        }

        .class-estado-badge--vigente {
            background: var(--clr-success-subtle);
            color: var(--clr-success);
            border: 1px solid rgba(34,197,94,0.22);
        }

        .class-estado-badge--vigente::before {
            animation: pulse-green 2s ease-in-out infinite;
        }

        .class-estado-badge--suspendida {
            background: rgba(255,255,255,0.05);
            color: var(--clr-text-dim);
            border: 1px solid var(--clr-border);
        }

        @keyframes pulse-green {
            0%,100% { box-shadow: 0 0 0 0 rgba(34,197,94,0.4); }
            50%      { box-shadow: 0 0 0 5px transparent; }
        }

        /* Separador */
        .class-card__sep {
            height: 1px;
            background: var(--clr-border-light);
            margin: 0 1.3rem;
        }

        /* Info del entrenador */
        .class-card__trainer {
            padding: 0.85rem 1.3rem;
            display: flex;
            align-items: center;
            gap: 0.65rem;
        }

        .class-card__trainer-avatar {
            flex-shrink: 0;
            width: 32px;
            height: 32px;
            border-radius: var(--radius-sm);
            background: var(--clr-surface-2);
            border: 1px solid var(--clr-border);
            display: flex;
            align-items: center;
            justify-content: center;
            font-family: var(--font-display);
            font-size: 0.78rem;
            font-weight: 700;
            color: var(--clr-text-muted);
            text-transform: uppercase;
        }

        .class-card__trainer-info {
            flex: 1;
            min-width: 0;
        }

        .class-card__trainer-nombre {
            font-size: 0.82rem;
            font-weight: 600;
            color: var(--clr-text);
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .class-card__trainer-cargo {
            font-size: 0.68rem;
            color: var(--clr-text-dim);
        }

        /* Stats de la clase (capacidad, horarios) */
        .class-card__stats {
            padding: 0.65rem 1.3rem;
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 0.5rem;
        }

        .class-stat {
            display: flex;
            flex-direction: column;
            gap: 0.08rem;
            padding: 0.5rem 0.7rem;
            background: var(--clr-surface);
            border-radius: var(--radius-sm);
            border: 1px solid var(--clr-border-light);
        }

        .class-stat__num {
            font-family: var(--font-display);
            font-size: 1.2rem;
            font-weight: 700;
            color: var(--clr-text);
            line-height: 1;
        }

        .class-stat__label {
            font-size: 0.62rem;
            font-weight: 600;
            letter-spacing: 0.08em;
            text-transform: uppercase;
            color: var(--clr-text-dim);
        }

        /* Descripción opcional */
        .class-card__desc {
            padding: 0 1.3rem 0.85rem;
            font-size: 0.76rem;
            color: var(--clr-text-dim);
            line-height: 1.55;
            font-style: italic;
            display: -webkit-box;
            -webkit-line-clamp: 2;
            line-clamp: 2;
            -webkit-box-orient: vertical;
            overflow: hidden;
        }

        /* Footer con acciones */
        .class-card__footer {
            margin-top: auto;
            padding: 0.75rem 1.3rem;
            border-top: 1px solid var(--clr-border-light);
            background: rgba(255,255,255,0.012);
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 0.5rem;
        }

        .class-card__id {
            font-family: var(--font-mono);
            font-size: 0.62rem;
            color: var(--clr-text-dim);
            background: var(--clr-surface);
            padding: 0.15rem 0.45rem;
            border-radius: var(--radius-xs);
            border: 1px solid var(--clr-border-light);
        }

        .class-card__actions {
            display: flex;
            align-items: center;
            gap: 0.35rem;
        }

        /* ── Strip de KPIs ──────────────────────────────────── */
        .sch-kpi-strip {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 0;
            background: var(--clr-card);
            border: 1px solid var(--clr-card-border);
            border-radius: var(--radius-lg);
            overflow: hidden;
            margin-bottom: 1.5rem;
        }

        .sch-kpi {
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: 0.9rem 0.75rem;
            gap: 0.15rem;
            border-right: 1px solid var(--clr-border-light);
            transition: background var(--transition);
        }

        .sch-kpi:last-child { border-right: none; }
        .sch-kpi:hover { background: rgba(255,255,255,0.02); }

        .sch-kpi__num {
            font-family: var(--font-display);
            font-size: 1.55rem;
            font-weight: 800;
            line-height: 1;
            color: var(--clr-text);
        }

        .sch-kpi__num.red    { color: var(--clr-red); }
        .sch-kpi__num.green  { color: var(--clr-success); }
        .sch-kpi__num.orange { color: #f97316; }
        .sch-kpi__num.purple { color: #a78bfa; }

        .sch-kpi__label {
            font-size: 0.65rem;
            font-weight: 700;
            letter-spacing: 0.09em;
            text-transform: uppercase;
            color: var(--clr-text-dim);
        }

        /* ── Vista Horarios ─────────────────────────────────── */
        .horarios-grid {
            display: grid;
            grid-template-columns: 1fr 400px;
            gap: 1.25rem;
            align-items: start;
        }

        /* Lista de horarios */
        .horarios-list {
            background: var(--clr-card);
            border: 1px solid var(--clr-card-border);
            border-radius: var(--radius-lg);
            overflow: hidden;
        }

        .horario-row {
            display: flex;
            align-items: center;
            gap: 1rem;
            padding: 0.85rem 1.25rem;
            border-bottom: 1px solid var(--clr-border-light);
            transition: background var(--transition);
        }

        .horario-row:last-child { border-bottom: none; }
        .horario-row:hover { background: rgba(255,255,255,0.025); }

        .horario-row__dia {
            flex-shrink: 0;
            width: 90px;
        }

        .horario-row__dia-nombre {
            font-family: var(--font-display);
            font-size: 0.92rem;
            font-weight: 700;
            letter-spacing: 0.04em;
            text-transform: uppercase;
            color: var(--clr-text);
        }

        .horario-row__dia-num {
            font-size: 0.65rem;
            color: var(--clr-text-dim);
            margin-top: 0.05rem;
        }

        .horario-row__time {
            flex: 1;
            display: flex;
            align-items: center;
            gap: 0.65rem;
        }

        .horario-row__time-block {
            background: var(--clr-surface);
            border: 1px solid var(--clr-border-light);
            border-radius: var(--radius-sm);
            padding: 0.35rem 0.75rem;
            text-align: center;
        }

        .horario-row__time-hora {
            font-family: var(--font-mono);
            font-size: 1rem;
            font-weight: 700;
            color: var(--clr-text);
            line-height: 1;
        }

        .horario-row__time-label {
            font-size: 0.60rem;
            color: var(--clr-text-dim);
            text-transform: uppercase;
            letter-spacing: 0.06em;
        }

        .horario-row__arrow {
            color: var(--clr-text-dim);
        }

        .horario-row__duracion {
            font-size: 0.72rem;
            color: var(--clr-text-muted);
            white-space: nowrap;
            background: var(--clr-surface-2);
            padding: 0.2rem 0.55rem;
            border-radius: var(--radius-full);
            border: 1px solid var(--clr-border);
        }

        .horario-row__estado {
            flex-shrink: 0;
        }

        .horario-row__actions {
            flex-shrink: 0;
        }

        /* Formulario de nuevo horario */
        .horario-form-card {
            background: var(--clr-card);
            border: 1px solid var(--clr-card-border);
            border-radius: var(--radius-lg);
            overflow: hidden;
        }

        .horario-form-header {
            padding: 0.9rem 1.25rem;
            border-bottom: 1px solid var(--clr-border);
            background: var(--clr-surface);
            display: flex;
            align-items: center;
            gap: 0.55rem;
        }

        .horario-form-header__icon {
            flex-shrink: 0;
            width: 28px;
            height: 28px;
            border-radius: var(--radius-xs);
            background: var(--clr-red-subtle);
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .horario-form-header__icon svg {
            width: 13px;
            height: 13px;
            color: var(--clr-red);
        }

        .horario-form-header__title {
            font-size: 0.80rem;
            font-weight: 700;
            letter-spacing: 0.06em;
            text-transform: uppercase;
            color: var(--clr-text-muted);
        }

        .horario-form-body {
            padding: 1.1rem 1.25rem;
            display: flex;
            flex-direction: column;
            gap: 0.85rem;
        }

        /* Días de semana como botones de selección */
        .dia-selector {
            display: grid;
            grid-template-columns: repeat(7, 1fr);
            gap: 0.3rem;
        }

        .dia-selector-label {
            display: block;
            text-align: center;
            padding: 0.45rem 0.2rem;
            background: var(--clr-surface);
            border: 1px solid var(--clr-border);
            border-radius: var(--radius-sm);
            font-size: 0.68rem;
            font-weight: 700;
            color: var(--clr-text-muted);
            cursor: pointer;
            transition: all var(--transition);
            letter-spacing: 0.04em;
            text-transform: uppercase;
            user-select: none;
        }

        .dia-selector input[type="radio"] {
            position: absolute;
            opacity: 0;
            width: 0;
            height: 0;
        }

        .dia-selector input[type="radio"]:checked + .dia-selector-label {
            background: var(--clr-red-subtle);
            border-color: rgba(230,48,39,0.35);
            color: var(--clr-red);
        }

        .dia-selector-label:hover {
            background: var(--clr-surface-2);
            border-color: rgba(255,255,255,0.10);
            color: var(--clr-text);
        }

        /* ── Vista Inscritos ────────────────────────────────── */
        .inscritos-layout {
            display: grid;
            grid-template-columns: 1fr 340px;
            gap: 1.25rem;
            align-items: start;
        }

        /* Barra de cupos */
        .cupos-bar-wrap {
            background: var(--clr-card);
            border: 1px solid var(--clr-card-border);
            border-radius: var(--radius-lg);
            padding: 1.1rem 1.25rem;
            margin-bottom: 1.25rem;
            display: flex;
            align-items: center;
            gap: 1.25rem;
        }

        .cupos-bar-nums {
            display: flex;
            align-items: baseline;
            gap: 0.3rem;
            flex-shrink: 0;
        }

        .cupos-bar-nums__ocu {
            font-family: var(--font-display);
            font-size: 2rem;
            font-weight: 800;
            color: var(--clr-text);
            line-height: 1;
        }

        .cupos-bar-nums__sep {
            font-size: 1.1rem;
            color: var(--clr-text-dim);
        }

        .cupos-bar-nums__total {
            font-family: var(--font-display);
            font-size: 1.1rem;
            font-weight: 700;
            color: var(--clr-text-muted);
        }

        .cupos-bar-track {
            flex: 1;
        }

        .cupos-bar-label {
            font-size: 0.72rem;
            color: var(--clr-text-dim);
            margin-bottom: 0.35rem;
            display: flex;
            justify-content: space-between;
        }

        .cupos-bar-bg {
            height: 8px;
            background: var(--clr-surface-2);
            border-radius: var(--radius-full);
            overflow: hidden;
        }

        .cupos-bar-fill {
            height: 100%;
            border-radius: var(--radius-full);
            background: var(--clr-success);
            width: var(--bar-w, 0%);
            transition: width 0.6s cubic-bezier(0.4,0,0.2,1);
        }

        .cupos-bar-fill.is-full  { background: var(--clr-red); }
        .cupos-bar-fill.is-high  { background: var(--clr-warning); }

        .cupos-chips {
            display: flex;
            gap: 0.5rem;
            flex-shrink: 0;
        }

        .cupos-chip {
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 0.1rem;
            padding: 0.5rem 0.75rem;
            border-radius: var(--radius-md);
            border: 1px solid var(--clr-border-light);
            min-width: 60px;
        }

        .cupos-chip__num {
            font-family: var(--font-display);
            font-size: 1.2rem;
            font-weight: 800;
            line-height: 1;
        }

        .cupos-chip__label {
            font-size: 0.60rem;
            font-weight: 700;
            letter-spacing: 0.08em;
            text-transform: uppercase;
            color: var(--clr-text-dim);
        }

        .cupos-chip--ocupado  { background: var(--clr-danger-subtle);  }
        .cupos-chip--ocupado .cupos-chip__num  { color: var(--clr-red); }
        .cupos-chip--libre    { background: var(--clr-success-subtle); }
        .cupos-chip--libre .cupos-chip__num   { color: var(--clr-success); }

        /* Tabla de inscritos */
        .inscrito-row {
            display: flex;
            align-items: center;
            gap: 0.9rem;
            padding: 0.75rem 1.25rem;
            border-bottom: 1px solid var(--clr-border-light);
            transition: background var(--transition);
        }

        .inscrito-row:last-child { border-bottom: none; }
        .inscrito-row:hover { background: rgba(255,255,255,0.025); }

        .inscrito-row__num {
            flex-shrink: 0;
            width: 26px;
            height: 26px;
            border-radius: var(--radius-sm);
            background: var(--clr-surface-2);
            border: 1px solid var(--clr-border);
            display: flex;
            align-items: center;
            justify-content: center;
            font-family: var(--font-mono);
            font-size: 0.65rem;
            font-weight: 700;
            color: var(--clr-text-dim);
        }

        .inscrito-row__avatar {
            flex-shrink: 0;
            width: 34px;
            height: 34px;
            border-radius: var(--radius-sm);
            background: var(--clr-success-subtle);
            border: 1px solid rgba(34,197,94,0.18);
            display: flex;
            align-items: center;
            justify-content: center;
            font-family: var(--font-display);
            font-size: 0.82rem;
            font-weight: 700;
            color: var(--clr-success);
            text-transform: uppercase;
        }

        .inscrito-row__info { flex: 1; min-width: 0; }

        .inscrito-row__nombre {
            font-size: 0.85rem;
            font-weight: 600;
            color: var(--clr-text);
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .inscrito-row__doc {
            font-size: 0.72rem;
            color: var(--clr-text-dim);
            font-family: var(--font-mono);
        }

        .inscrito-row__fecha {
            flex-shrink: 0;
            font-size: 0.70rem;
            color: var(--clr-text-dim);
        }

        /* Formulario de inscripción lateral */
        .inscribir-card {
            background: var(--clr-card);
            border: 1px solid var(--clr-card-border);
            border-radius: var(--radius-lg);
            overflow: hidden;
        }

        /* ── Info de la clase (aside en horarios/inscritos) ── */
        .clase-info-aside {
            background: var(--clr-card);
            border: 1px solid var(--clr-card-border);
            border-radius: var(--radius-lg);
            overflow: hidden;
        }

        .clase-info-aside__header {
            padding: 1.1rem 1.25rem;
            position: relative;
            overflow: hidden;
        }

        .clase-info-aside__header::after {
            content: '';
            position: absolute;
            left: 0;
            top: 0;
            bottom: 0;
            width: 3px;
            background: var(--clr-red);
            border-radius: 0 2px 2px 0;
        }

        .clase-info-aside__tipo {
            font-size: 0.63rem;
            font-weight: 700;
            letter-spacing: 0.12em;
            text-transform: uppercase;
            color: var(--clr-text-dim);
            margin-bottom: 0.15rem;
            padding-left: 0.65rem;
        }

        .clase-info-aside__nombre {
            font-family: var(--font-display);
            font-weight: 800;
            font-size: 1.15rem;
            letter-spacing: 0.04em;
            text-transform: uppercase;
            color: var(--clr-text);
            line-height: 1.2;
            padding-left: 0.65rem;
        }

        /* Días de semana en el header de horarios */
        .dias-semana-chips {
            display: flex;
            flex-wrap: wrap;
            gap: 0.35rem;
            margin-top: 0.5rem;
        }

        .dia-chip {
            display: inline-flex;
            align-items: center;
            padding: 0.2rem 0.55rem;
            border-radius: var(--radius-full);
            font-size: 0.65rem;
            font-weight: 700;
            letter-spacing: 0.05em;
            text-transform: uppercase;
            background: var(--clr-surface-2);
            color: var(--clr-text-muted);
            border: 1px solid var(--clr-border);
        }

        /* ── Animaciones escalonadas ────────────────────────── */
        .class-card:nth-child(1)  { animation-delay: 0.04s; }
        .class-card:nth-child(2)  { animation-delay: 0.08s; }
        .class-card:nth-child(3)  { animation-delay: 0.12s; }
        .class-card:nth-child(4)  { animation-delay: 0.16s; }
        .class-card:nth-child(5)  { animation-delay: 0.20s; }
        .class-card:nth-child(6)  { animation-delay: 0.24s; }
        .class-card:nth-child(7)  { animation-delay: 0.28s; }
        .class-card:nth-child(8)  { animation-delay: 0.32s; }
        .class-card:nth-child(9)  { animation-delay: 0.36s; }

        /* ── Nota de seguridad horario ──────────────────────── */
        .horario-note {
            display: flex;
            align-items: flex-start;
            gap: 0.55rem;
            padding: 0.75rem 1.1rem;
            background: var(--clr-info-subtle);
            border: 1px solid rgba(59,130,246,0.18);
            border-radius: var(--radius-md);
            margin-top: 0.75rem;
        }

        .horario-note svg {
            flex-shrink: 0;
            width: 13px;
            height: 13px;
            color: var(--clr-info);
            margin-top: 1px;
        }

        .horario-note p {
            font-size: 0.73rem;
            color: #93c5fd;
            line-height: 1.5;
        }

        /* ── Responsive ──────────────────────────────────────── */
        @media (max-width: 1200px) {
            .classes-grid { grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); }
            .horarios-grid { grid-template-columns: 1fr; }
            .inscritos-layout { grid-template-columns: 1fr; }
        }

        @media (max-width: 768px) {
            .classes-grid { grid-template-columns: 1fr; }
            .sch-kpi-strip { grid-template-columns: repeat(2, 1fr); }
            .sch-kpi:nth-child(2) { border-right: none; }
            .sch-kpi:nth-child(3) { border-top: 1px solid var(--clr-border-light); }
            .dia-selector { grid-template-columns: repeat(4, 1fr); }
            .cupos-bar-wrap { flex-direction: column; align-items: flex-start; }
        }
    </style>
</head>
<body>

<div class="app-shell">
    <%@ include file="/WEB-INF/views/includes/sidebar.jsp" %>

    <div class="app-main">

        <%-- Títulos dinámicos para el navbar --%>
        <c:choose>
            <c:when test="${param.form eq 'true'}">
                <c:set var="pageTitle"    value="${modoEdicion ? 'Editar Clase' : 'Nueva Clase'}" scope="request"/>
                <c:set var="pageSubtitle" value="Módulo de Clases y Horarios" scope="request"/>
            </c:when>
            <c:when test="${param.action eq 'horarios'}">
                <c:set var="pageTitle"    value="Horarios" scope="request"/>
                <c:set var="pageSubtitle" value="Gestión de horarios de clase" scope="request"/>
            </c:when>
            <c:when test="${param.action eq 'inscritos'}">
                <c:set var="pageTitle"    value="Inscritos" scope="request"/>
                <c:set var="pageSubtitle" value="Alumnos inscritos en la clase" scope="request"/>
            </c:when>
            <c:otherwise>
                <c:set var="pageTitle"    value="Clases y Horarios" scope="request"/>
                <c:set var="pageSubtitle" value="Programa de clases grupales" scope="request"/>
            </c:otherwise>
        </c:choose>
        <%@ include file="/WEB-INF/views/includes/navbar.jsp" %>

        <div class="page-content">

            <%-- ═══════════════════════════════════════════════
                 BIFURCACIÓN PRINCIPAL DE VISTAS
                 ═══════════════════════════════════════════════ --%>
            <c:choose>

                <%-- ──────────────────────────────────────────
                     VISTA: FORMULARIO DE CLASE
                     param.form=true | solo admin
                     ────────────────────────────────────────── --%>
                <c:when test="${param.form eq 'true'}">

                    <%-- Breadcrumb --%>
                    <nav class="module-breadcrumb" aria-label="Breadcrumb">
                        <a href="${pageContext.request.contextPath}/schedules">Clases</a>
                        <svg class="module-breadcrumb__sep" xmlns="http://www.w3.org/2000/svg"
                             fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7"/>
                        </svg>
                        <span>${modoEdicion ? 'Editar clase' : 'Nueva clase'}</span>
                    </nav>

                    <%-- Header --%>
                    <div class="module-header">
                        <div class="module-header__left">
                            <h1 class="module-header__title">
                                ${modoEdicion ? 'Editar Clase' : 'Registrar Nueva Clase'}
                            </h1>
                            <div class="module-header__meta">
                                <span>Configura el nombre, tipo, entrenador y capacidad</span>
                                <span class="module-header__meta-sep"></span>
                                <span>Los campos con * son obligatorios</span>
                            </div>
                        </div>
                        <div class="module-header__actions">
                            <a href="${pageContext.request.contextPath}/schedules"
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

                    <%-- Alerta de error --%>
                    <c:if test="${not empty errorMsg}">
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
                                <p class="module-alert__text"><c:out value="${errorMsg}"/></p>
                            </div>
                        </div>
                    </c:if>

                    <%-- Formulario --%>
                    <form action="${pageContext.request.contextPath}/schedules"
                          method="post"
                          novalidate
                          autocomplete="off">

                        <input type="hidden" name="action" value="saveClase">
                        <input type="hidden" name="_csrf"  value="${sessionScope._csrfToken}">

                        <c:if test="${modoEdicion}">
                            <input type="hidden" name="id" value="<c:out value='${clase.id}'/>">
                        </c:if>

                        <div class="form-card form-card--wide">

                            <div class="form-card__header">
                                <div class="form-card__header-icon">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z"/>
                                    </svg>
                                </div>
                                <div>
                                    <p class="form-card__header-title">
                                        ${modoEdicion ? 'Datos de la Clase' : 'Nueva Clase Grupal'}
                                    </p>
                                    <p class="form-card__header-sub">
                                        <c:if test="${modoEdicion}">
                                            ID: <c:out value="${clase.id}"/>
                                        </c:if>
                                        <c:if test="${not modoEdicion}">
                                            El ID se genera automáticamente · Los horarios se agregan después
                                        </c:if>
                                    </p>
                                </div>
                            </div>

                            <div class="form-card__body">

                                <%-- Sección: Identificación --%>
                                <div class="form-section-divider">
                                    <span class="form-section-divider__label">Identificación de la clase</span>
                                </div>

                                <div class="form-row">
                                    <%-- Nombre --%>
                                    <div class="form-field">
                                        <label for="nombreClase">
                                            Nombre de la clase <span class="required-star">*</span>
                                        </label>
                                        <input type="text"
                                               id="nombreClase"
                                               name="nombreClase"
                                               class="form-control"
                                               placeholder="Ej: CrossFit Intensivo, Yoga Matutino…"
                                               maxlength="100"
                                               required
                                               autocomplete="off"
                                               value="<c:out value='${clase.nombreClase}'/>">
                                    </div>

                                    <%-- Tipo de clase --%>
                                    <div class="form-field">
                                        <label for="idTipoClase">
                                            Tipo de clase <span class="required-star">*</span>
                                        </label>
                                        <select id="idTipoClase"
                                                name="idTipoClase"
                                                class="form-control"
                                                required>
                                            <option value="">— Seleccionar tipo —</option>
                                            <c:forEach var="tc" items="${tiposClase}">
                                                <option value="<c:out value='${tc.id}'/>"
                                                    ${clase.tipoClase != null
                                                       and clase.tipoClase.id eq tc.id
                                                       ? 'selected' : ''}>
                                                    <c:out value="${tc.nombre}"/>
                                                </option>
                                            </c:forEach>
                                        </select>
                                    </div>
                                </div>

                                <%-- Sección: Entrenador y capacidad --%>
                                <div class="form-section-divider">
                                    <span class="form-section-divider__label">Entrenador y capacidad</span>
                                </div>

                                <div class="form-row">
                                    <%-- Entrenador --%>
                                    <div class="form-field">
                                        <label for="idEmpleado">
                                            Entrenador asignado <span class="required-star">*</span>
                                        </label>
                                        <select id="idEmpleado"
                                                name="idEmpleado"
                                                class="form-control"
                                                required>
                                            <option value="">— Seleccionar entrenador —</option>
                                            <c:forEach var="emp" items="${entrenadores}">
                                                <option value="<c:out value='${emp.id}'/>"
                                                    ${clase.empleado != null
                                                       and clase.empleado.id eq emp.id
                                                       ? 'selected' : ''}>
                                                    <c:out value="${emp.apellido}"/>,
                                                    <c:out value="${emp.nombre}"/>
                                                </option>
                                            </c:forEach>
                                        </select>
                                        <span class="form-field__hint">
                                            Solo se muestran empleados con cargo de Entrenador
                                        </span>
                                    </div>

                                    <%-- Capacidad --%>
                                    <div class="form-field">
                                        <label for="capacidadMaxima">
                                            Capacidad máxima <span class="required-star">*</span>
                                        </label>
                                        <input type="number"
                                               id="capacidadMaxima"
                                               name="capacidadMaxima"
                                               class="form-control"
                                               placeholder="Ej: 15"
                                               min="1"
                                               max="200"
                                               required
                                               autocomplete="off"
                                               value="${clase.capacidadMaxima > 0 ? clase.capacidadMaxima : ''}">
                                        <span class="form-field__hint">
                                            Número máximo de alumnos que pueden inscribirse
                                        </span>
                                    </div>
                                </div>

                                <%-- Sección: Descripción --%>
                                <div class="form-section-divider">
                                    <span class="form-section-divider__label">Descripción (opcional)</span>
                                </div>

                                <div class="form-field">
                                    <label for="descripcion">Descripción</label>
                                    <textarea id="descripcion"
                                              name="descripcion"
                                              class="form-control"
                                              placeholder="Describe los objetivos, nivel de intensidad o equipamiento necesario…"
                                              maxlength="200"
                                              rows="3"><c:out value='${clase.descripcion}'/></textarea>
                                    <span class="form-field__hint">Máx. 200 caracteres · Se muestra en la tarjeta de la clase</span>
                                </div>

                                <%-- Aviso sobre horarios --%>
                                <div class="module-alert module-alert--info" style="margin-bottom:0;">
                                    <svg class="module-alert__icon" xmlns="http://www.w3.org/2000/svg"
                                         fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25
                                                 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0
                                                 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5"/>
                                    </svg>
                                    <div class="module-alert__body">
                                        <p class="module-alert__text">
                                            Después de guardar la clase, podrás agregar
                                            <strong>horarios semanales</strong> desde la tarjeta de la clase
                                            usando el botón <em>Horarios</em>.
                                        </p>
                                    </div>
                                </div>

                            </div><%-- /form-card__body --%>

                            <div class="form-card__footer">
                                <button type="submit" class="btn btn-primary">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                    </svg>
                                    ${modoEdicion ? 'Guardar cambios' : 'Registrar clase'}
                                </button>
                                <a href="${pageContext.request.contextPath}/schedules" class="btn btn-ghost">
                                    Cancelar
                                </a>
                            </div>

                        </div><%-- /form-card --%>
                    </form>

                </c:when>

                <%-- ──────────────────────────────────────────
                     VISTA: HORARIOS DE UNA CLASE
                     param.action=horarios
                     ────────────────────────────────────────── --%>
                <c:when test="${param.action eq 'horarios'}">

                    <%-- Breadcrumb --%>
                    <nav class="module-breadcrumb" aria-label="Breadcrumb">
                        <a href="${pageContext.request.contextPath}/schedules">Clases</a>
                        <svg class="module-breadcrumb__sep" xmlns="http://www.w3.org/2000/svg"
                             fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7"/>
                        </svg>
                        <span><c:out value="${clase.nombreClase}"/></span>
                        <svg class="module-breadcrumb__sep" xmlns="http://www.w3.org/2000/svg"
                             fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7"/>
                        </svg>
                        <span>Horarios</span>
                    </nav>

                    <%-- Header --%>
                    <div class="module-header">
                        <div class="module-header__left">
                            <h1 class="module-header__title">
                                Horarios
                                <span class="stat-chip"><c:out value="${fn:length(horarios)}"/></span>
                            </h1>
                            <div class="module-header__meta">
                                <span>
                                    <c:out value="${clase.nombreClase}"/>
                                </span>
                                <span class="module-header__meta-sep"></span>
                                <c:if test="${clase.tipoClase != null}">
                                    <span><c:out value="${clase.tipoClase.nombre}"/></span>
                                </c:if>
                            </div>
                        </div>
                        <div class="module-header__actions">
                            <a href="${pageContext.request.contextPath}/schedules?action=inscritos&id=<c:out value='${clase.id}'/>"
                               class="btn btn-secondary">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M15 19.128a9.38 9.38 0 0 0 2.625.372 9.337 9.337 0 0
                                             0 4.121-.952 4.125 4.125 0 0 0-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15
                                             19.128v.106A12.318 12.318 0 0 1 8.624 21c-2.331
                                             0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0
                                             1 11.964-3.07M12 6.375a3.375 3.375 0 1 1-6.75 0 3.375
                                             3.375 0 0 1 6.75 0Zm8.25 2.25a2.625 2.625 0 1 1-5.25
                                             0 2.625 2.625 0 0 1 5.25 0Z"/>
                                </svg>
                                Ver inscritos
                            </a>
                            <a href="${pageContext.request.contextPath}/schedules"
                               class="btn btn-ghost">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M10.5 19.5 3 12m0 0 7.5-7.5M3 12h18"/>
                                </svg>
                                Volver
                            </a>
                        </div>
                    </div>

                    <%-- Alertas flash --%>
                    <c:if test="${not empty errorMsg}">
                        <div class="module-alert module-alert--error" role="alert">
                            <svg class="module-alert__icon" xmlns="http://www.w3.org/2000/svg"
                                 fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                      d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73
                                         0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898
                                         0L2.697 16.126ZM12 15.75h.007v.008H12v-.008Z"/>
                            </svg>
                            <div class="module-alert__body">
                                <p class="module-alert__text"><c:out value="${errorMsg}"/></p>
                            </div>
                        </div>
                    </c:if>

                    <%-- Layout: lista de horarios + formulario de agregar --%>
                    <div class="horarios-grid">

                        <%-- Columna principal: lista --%>
                        <div>
                            <div class="horarios-list">
                                <%-- Header de la lista --%>
                                <div style="padding:0.85rem 1.25rem; border-bottom:1px solid var(--clr-border);
                                            background:var(--clr-surface); display:flex; align-items:center;
                                            gap:0.6rem;">
                                    <div style="flex-shrink:0; width:28px; height:28px; border-radius:var(--radius-xs);
                                                background:var(--clr-info-subtle); display:flex; align-items:center;
                                                justify-content:center;">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8"
                                             style="width:13px;height:13px;color:var(--clr-info);">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                        </svg>
                                    </div>
                                    <span style="font-size:0.80rem;font-weight:700;letter-spacing:0.06em;
                                                 text-transform:uppercase;color:var(--clr-text-muted);">
                                        Horarios registrados
                                    </span>
                                    <span class="stat-chip" style="margin-left:auto;">
                                        <c:out value="${fn:length(horarios)}"/>
                                    </span>
                                </div>

                                <c:choose>
                                    <c:when test="${not empty horarios}">
                                        <c:forEach var="hor" items="${horarios}">
                                            <div class="horario-row">

                                                <%-- Día --%>
                                                <div class="horario-row__dia">
                                                    <p class="horario-row__dia-nombre">
                                                        <c:out value="${hor.nombreDia}"/>
                                                    </p>
                                                    <p class="horario-row__dia-num">
                                                        Día <c:out value="${hor.diaSemana}"/> de 7
                                                    </p>
                                                </div>

                                                <%-- Horario --%>
                                                <div class="horario-row__time">
                                                    <div class="horario-row__time-block">
                                                        <p class="horario-row__time-hora">
                                                            <c:out value="${fn:substring(hor.horaInicio.toString(), 0, 5)}"/>
                                                        </p>
                                                        <p class="horario-row__time-label">inicio</p>
                                                    </div>
                                                    <span class="horario-row__arrow">
                                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                             viewBox="0 0 24 24" stroke="currentColor"
                                                             stroke-width="2" style="width:14px;height:14px;">
                                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                                  d="M13.5 4.5 21 12m0 0-7.5 7.5M21 12H3"/>
                                                        </svg>
                                                    </span>
                                                    <div class="horario-row__time-block">
                                                        <p class="horario-row__time-hora">
                                                            <c:out value="${fn:substring(hor.horaFin.toString(), 0, 5)}"/>
                                                        </p>
                                                        <p class="horario-row__time-label">fin</p>
                                                    </div>
                                                </div>

                                                <%-- Estado --%>
                                                <div class="horario-row__estado">
                                                    <span class="badge-estado badge-estado--${hor.estado}">
                                                        <c:out value="${hor.estado}"/>
                                                    </span>
                                                </div>

                                                <%-- Acción eliminar (solo admin) --%>
                                                <div class="horario-row__actions">
                                                    <c:if test="${sessionScope.userRole eq 'ROL-ADMIN'}">
                                                        <form action="${pageContext.request.contextPath}/schedules"
                                                              method="post"
                                                              style="display:inline;"
                                                              onsubmit="return confirm('¿Eliminar el horario del ${hor.nombreDia} ${hor.rangoHorario}? Esta acción no se puede deshacer.');">
                                                            <input type="hidden" name="action"   value="deleteHorario">
                                                            <input type="hidden" name="id"       value="<c:out value='${hor.id}'/>">
                                                            <input type="hidden" name="claseId"  value="<c:out value='${clase.id}'/>">
                                                            <input type="hidden" name="_csrf"    value="${sessionScope._csrfToken}">
                                                            <button type="submit"
                                                                    class="btn btn-danger btn-sm btn-icon"
                                                                    title="Eliminar este horario">
                                                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                                     viewBox="0 0 24 24" stroke="currentColor"
                                                                     stroke-width="1.8">
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

                                            </div>
                                        </c:forEach>

                                        <%-- Pie --%>
                                        <div style="padding:0.65rem 1.25rem; border-top:1px solid var(--clr-border-light);
                                                    background:rgba(255,255,255,0.012);
                                                    font-size:0.75rem; color:var(--clr-text-dim);">
                                            <c:out value="${fn:length(horarios)}"/>
                                            horario<c:if test="${fn:length(horarios) ne 1}">s</c:if>
                                            registrado<c:if test="${fn:length(horarios) ne 1}">s</c:if>
                                            para <c:out value="${clase.nombreClase}"/>
                                        </div>
                                    </c:when>

                                    <c:otherwise>
                                        <div class="table-empty" style="padding:3rem 2rem;">
                                            <div class="table-empty__icon">
                                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                                                    <path stroke-linecap="round" stroke-linejoin="round"
                                                          d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                                </svg>
                                            </div>
                                            <p class="table-empty__title">Sin horarios</p>
                                            <p class="table-empty__desc">
                                                Esta clase aún no tiene horarios asignados.<br>
                                                Agrega el primer horario desde el panel de la derecha.
                                            </p>
                                        </div>
                                    </c:otherwise>
                                </c:choose>
                            </div><%-- /horarios-list --%>
                        </div>

                        <%-- Aside: agregar horario + info de clase --%>
                        <div style="display:flex; flex-direction:column; gap:1rem;">

                            <%-- Formulario de nuevo horario (solo admin) --%>
                            <c:if test="${sessionScope.userRole eq 'ROL-ADMIN'}">
                                <div class="horario-form-card">
                                    <div class="horario-form-header">
                                        <div class="horario-form-header__icon">
                                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                <path stroke-linecap="round" stroke-linejoin="round"
                                                      d="M12 4.5v15m7.5-7.5h-15"/>
                                            </svg>
                                        </div>
                                        <span class="horario-form-header__title">Agregar horario</span>
                                    </div>

                                    <form action="${pageContext.request.contextPath}/schedules"
                                          method="post"
                                          novalidate
                                          autocomplete="off">

                                        <input type="hidden" name="action"  value="saveHorario">
                                        <input type="hidden" name="claseId" value="<c:out value='${clase.id}'/>">
                                        <input type="hidden" name="_csrf"   value="${sessionScope._csrfToken}">

                                        <div class="horario-form-body">

                                            <%-- Selector de día --%>
                                            <div class="form-field">
                                                <label>Día de la semana <span class="required-star">*</span></label>
                                                <div class="dia-selector">
                                                    <c:forEach begin="1" end="7" var="d">
                                                        <c:set var="nombresDia"
                                                               value="Lu,Ma,Mi,Ju,Vi,Sa,Do"/>
                                                        <c:set var="diaAbr"
                                                               value="${fn:split(nombresDia, ',')[d-1]}"/>
                                                        <input type="radio"
                                                               id="dia${d}"
                                                               name="diaSemana"
                                                               value="${d}"
                                                               style="position:absolute;opacity:0;width:0;height:0;"
                                                               ${d eq 1 ? 'checked' : ''}>
                                                        <label for="dia${d}"
                                                               class="dia-selector-label">
                                                            <c:out value="${diaAbr}"/>
                                                        </label>
                                                    </c:forEach>
                                                </div>
                                                <span class="form-field__hint">
                                                    Lun=1 … Dom=7 · Puedes agregar varios horarios para el mismo día
                                                </span>
                                            </div>

                                            <%-- Horas --%>
                                            <div class="form-row">
                                                <div class="form-field">
                                                    <label for="horaInicio">
                                                        Hora inicio <span class="required-star">*</span>
                                                    </label>
                                                    <input type="time"
                                                           id="horaInicio"
                                                           name="horaInicio"
                                                           class="form-control"
                                                           required
                                                           value="07:00">
                                                </div>
                                                <div class="form-field">
                                                    <label for="horaFin">
                                                        Hora fin <span class="required-star">*</span>
                                                    </label>
                                                    <input type="time"
                                                           id="horaFin"
                                                           name="horaFin"
                                                           class="form-control"
                                                           required
                                                           value="08:00">
                                                </div>
                                            </div>

                                            <div class="horario-note">
                                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                                    <path stroke-linecap="round" stroke-linejoin="round"
                                                          d="m11.25 11.25.041-.02a.75.75 0 0 1 1.063.852l-.708
                                                             2.836a.75.75 0 0 0 1.063.853l.041-.021M21 12a9 9 0
                                                             1 1-18 0 9 9 0 0 1 18 0Zm-9-3.75h.008v.008H12V8.25Z"/>
                                                </svg>
                                                <p>La hora de fin debe ser posterior a la de inicio. El estado se establece como <strong>programado</strong> automáticamente.</p>
                                            </div>

                                            <button type="submit" class="btn btn-primary" style="width:100%;">
                                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                                    <path stroke-linecap="round" stroke-linejoin="round"
                                                          d="M12 4.5v15m7.5-7.5h-15"/>
                                                </svg>
                                                Agregar horario
                                            </button>

                                        </div><%-- /horario-form-body --%>
                                    </form>
                                </div>
                            </c:if>

                            <%-- Info de la clase --%>
                            <div class="clase-info-aside">
                                <div class="clase-info-aside__header">
                                    <c:if test="${clase.tipoClase != null}">
                                        <p class="clase-info-aside__tipo">
                                            <c:out value="${clase.tipoClase.nombre}"/>
                                        </p>
                                    </c:if>
                                    <p class="clase-info-aside__nombre">
                                        <c:out value="${clase.nombreClase}"/>
                                    </p>
                                </div>
                                <div class="aside-summary-card__body" style="padding:1rem 1.25rem; display:flex; flex-direction:column; gap:0.65rem;">
                                    <div class="aside-data-row">
                                        <span class="aside-data-row__label">Entrenador</span>
                                        <span class="aside-data-row__value strong">
                                            <c:if test="${clase.empleado != null}">
                                                <c:out value="${clase.empleado.nombreCompleto}"/>
                                            </c:if>
                                        </span>
                                    </div>
                                    <div class="aside-data-row">
                                        <span class="aside-data-row__label">Capacidad</span>
                                        <span class="aside-data-row__value strong">
                                            <c:out value="${clase.capacidadMaxima}"/> alumnos
                                        </span>
                                    </div>
                                    <div class="aside-data-row">
                                        <span class="aside-data-row__label">Estado</span>
                                        <span class="aside-data-row__value">
                                            <span class="class-estado-badge class-estado-badge--${clase.estado}">
                                                <c:out value="${clase.estado}"/>
                                            </span>
                                        </span>
                                    </div>
                                    <div class="aside-data-row">
                                        <span class="aside-data-row__label">ID</span>
                                        <span class="aside-data-row__value mono" style="font-size:0.70rem;">
                                            <c:out value="${clase.id}"/>
                                        </span>
                                    </div>
                                </div>
                                <div style="padding:0.75rem 1.25rem; border-top:1px solid var(--clr-border-light);
                                            display:flex; flex-direction:column; gap:0.45rem;">
                                    <a href="${pageContext.request.contextPath}/schedules?action=inscritos&id=<c:out value='${clase.id}'/>"
                                       class="btn btn-secondary btn-sm" style="width:100%; justify-content:flex-start;">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M15 19.128a9.38 9.38 0 0 0 2.625.372 9.337 9.337 0 0
                                                     0 4.121-.952 4.125 4.125 0 0 0-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15
                                                     19.128v.106A12.318 12.318 0 0 1 8.624 21c-2.331
                                                     0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0
                                                     1 11.964-3.07M12 6.375a3.375 3.375 0 1 1-6.75 0 3.375
                                                     3.375 0 0 1 6.75 0Zm8.25 2.25a2.625 2.625 0 1 1-5.25
                                                     0 2.625 2.625 0 0 1 5.25 0Z"/>
                                        </svg>
                                        Ver inscritos
                                    </a>
                                    <a href="${pageContext.request.contextPath}/calendar"
                                       class="btn btn-ghost btn-sm" style="width:100%; justify-content:flex-start;">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M3.75 6A2.25 2.25 0 0 1 6 3.75h2.25A2.25 2.25 0 0 1 10.5 6v2.25a2.25 2.25 0 0
                                                     1-2.25 2.25H6a2.25 2.25 0 0 1-2.25-2.25V6ZM3.75 15.75A2.25 2.25 0 0 1 6
                                                     13.5h2.25a2.25 2.25 0 0 1 2.25 2.25V18a2.25 2.25 0 0 1-2.25 2.25H6A2.25 2.25
                                                     0 0 1 3.75 18v-2.25ZM13.5 6a2.25 2.25 0 0 1 2.25-2.25H18A2.25 2.25 0 0 1 20.25
                                                     6v2.25A2.25 2.25 0 0 1 18 10.5h-2.25a2.25 2.25 0 0 1-2.25-2.25V6ZM13.5
                                                     15.75a2.25 2.25 0 0 1 2.25-2.25H18a2.25 2.25 0 0 1 2.25 2.25V18A2.25 2.25
                                                     0 0 1 18 20.25h-2.25A2.25 2.25 0 0 1 13.5 18v-2.25Z"/>
                                        </svg>
                                        Ver calendario
                                    </a>
                                </div>
                            </div>

                        </div><%-- /aside --%>
                    </div><%-- /horarios-grid --%>

                </c:when>

                <%-- ──────────────────────────────────────────
                     VISTA: INSCRITOS DE UNA CLASE
                     param.action=inscritos
                     ────────────────────────────────────────── --%>
                <c:when test="${param.action eq 'inscritos'}">

                    <%-- Breadcrumb --%>
                    <nav class="module-breadcrumb" aria-label="Breadcrumb">
                        <a href="${pageContext.request.contextPath}/schedules">Clases</a>
                        <svg class="module-breadcrumb__sep" xmlns="http://www.w3.org/2000/svg"
                             fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7"/>
                        </svg>
                        <span><c:out value="${clase.nombreClase}"/></span>
                        <svg class="module-breadcrumb__sep" xmlns="http://www.w3.org/2000/svg"
                             fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7"/>
                        </svg>
                        <span>Inscritos</span>
                    </nav>

                    <%-- Header --%>
                    <div class="module-header">
                        <div class="module-header__left">
                            <h1 class="module-header__title">
                                Inscritos
                                <span class="stat-chip chip--green">
                                    <c:out value="${cuposOcupados}"/> / <c:out value="${cuposTotal}"/>
                                </span>
                            </h1>
                            <div class="module-header__meta">
                                <span><c:out value="${clase.nombreClase}"/></span>
                                <c:if test="${clase.tipoClase != null}">
                                    <span class="module-header__meta-sep"></span>
                                    <span><c:out value="${clase.tipoClase.nombre}"/></span>
                                </c:if>
                            </div>
                        </div>
                        <div class="module-header__actions">
                            <c:if test="${sessionScope.userRole eq 'ROL-ADMIN'}">
                                <a href="${pageContext.request.contextPath}/schedules?action=horarios&id=<c:out value='${clase.id}'/>"
                                   class="btn btn-secondary">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                    </svg>
                                    Gestionar horarios
                                </a>
                            </c:if>
                            <a href="${pageContext.request.contextPath}/schedules" class="btn btn-ghost">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="M10.5 19.5 3 12m0 0 7.5-7.5M3 12h18"/>
                                </svg>
                                Volver
                            </a>
                        </div>
                    </div>

                    <%-- Barra de cupos --%>
                    <c:set var="porcentaje" value="${cuposTotal > 0 ? (cuposOcupados * 100 / cuposTotal) : 0}"/>
                    <c:set var="fillClass"  value="${porcentaje >= 100 ? 'is-full' : (porcentaje >= 75 ? 'is-high' : '')}"/>

                    <div class="cupos-bar-wrap">
                        <div class="cupos-bar-nums">
                            <span class="cupos-bar-nums__ocu"><c:out value="${cuposOcupados}"/></span>
                            <span class="cupos-bar-nums__sep">/</span>
                            <span class="cupos-bar-nums__total"><c:out value="${cuposTotal}"/></span>
                        </div>

                        <div class="cupos-bar-track">
                            <div class="cupos-bar-label">
                                <span>Capacidad ocupada</span>
                                <span><c:out value="${porcentaje}"/>%</span>
                            </div>
                            <div class="cupos-bar-bg">
                                <div class="cupos-bar-fill ${fillClass}"
                                style="--bar-w:<c:out value='${porcentaje}'/>%">
                                </div>
                            </div>
                        </div>

                        <div class="cupos-chips">
                            <div class="cupos-chip cupos-chip--ocupado">
                                <span class="cupos-chip__num"><c:out value="${cuposOcupados}"/></span>
                                <span class="cupos-chip__label">Ocupados</span>
                            </div>
                            <div class="cupos-chip cupos-chip--libre">
                                <span class="cupos-chip__num"><c:out value="${cuposLibres}"/></span>
                                <span class="cupos-chip__label">Libres</span>
                            </div>
                        </div>
                    </div>

                    <%-- Aviso si clase suspendida --%>
                    <c:if test="${clase.estado eq 'suspendida'}">
                        <div class="module-alert module-alert--warning" style="margin-bottom:1rem;">
                            <svg class="module-alert__icon" xmlns="http://www.w3.org/2000/svg"
                                 fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                      d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0
                                         2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697
                                         16.126ZM12 15.75h.007v.008H12v-.008Z"/>
                            </svg>
                            <div class="module-alert__body">
                                <p class="module-alert__text">
                                    Esta clase está <strong>suspendida</strong>. No se pueden realizar nuevas
                                    inscripciones hasta que se reactive.
                                </p>
                            </div>
                        </div>
                    </c:if>

                    <%-- Layout: inscritos + formulario inscribir --%>
                    <div class="inscritos-layout">

                        <%-- Lista de inscritos --%>
                        <div class="horarios-list">
                            <%-- Header --%>
                            <div style="padding:0.85rem 1.25rem; border-bottom:1px solid var(--clr-border);
                                        background:var(--clr-surface); display:flex; align-items:center; gap:0.6rem;">
                                <div style="flex-shrink:0; width:28px; height:28px; border-radius:var(--radius-xs);
                                            background:var(--clr-success-subtle); display:flex; align-items:center;
                                            justify-content:center;">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8"
                                         style="width:13px;height:13px;color:var(--clr-success);">
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
                                <span style="font-size:0.80rem; font-weight:700; letter-spacing:0.06em;
                                             text-transform:uppercase; color:var(--clr-text-muted);">
                                    Alumnos inscritos
                                </span>
                                <span class="stat-chip chip--green" style="margin-left:auto;">
                                    <c:out value="${fn:length(inscritos)}"/>
                                </span>
                            </div>

                            <c:choose>
                                <c:when test="${not empty inscritos}">
                                    <c:forEach var="ins" items="${inscritos}" varStatus="loop">
                                        <div class="inscrito-row">
                                            <span class="inscrito-row__num">
                                                <c:out value="${loop.index + 1}"/>
                                            </span>
                                            <div class="inscrito-row__avatar">
                                                <c:out value="${fn:substring(ins.cliente.nombre, 0, 1)}"/>
                                            </div>
                                            <div class="inscrito-row__info">
                                                <p class="inscrito-row__nombre">
                                                    <c:out value="${ins.cliente.nombreCompleto}"/>
                                                </p>
                                                <p class="inscrito-row__doc">
                                                    <c:out value="${ins.cliente.numeroDocumento}"/>
                                                </p>
                                            </div>
                                            <span class="inscrito-row__fecha">
                                                <c:out value="${ins.fechaFormateada}"/>
                                            </span>
                                            <%-- Cancelar inscripción --%>
                                            <c:if test="${sessionScope.userRole eq 'ROL-ADMIN'
                                                          or sessionScope.userRole eq 'ROL-RECEP'}">
                                                <form action="${pageContext.request.contextPath}/schedules"
                                                      method="post"
                                                      style="display:inline; flex-shrink:0;"
                                                      onsubmit="return confirm('¿Cancelar la inscripción de ${ins.cliente.nombre}? Esta acción no se puede deshacer.');">
                                                    <input type="hidden" name="action"   value="cancelarInscripcion">
                                                    <input type="hidden" name="id"       value="<c:out value='${ins.id}'/>">
                                                    <input type="hidden" name="claseId"  value="<c:out value='${clase.id}'/>">
                                                    <input type="hidden" name="_csrf"    value="${sessionScope._csrfToken}">
                                                    <button type="submit"
                                                            class="btn btn-danger btn-sm btn-icon"
                                                            title="Cancelar inscripción de ${ins.cliente.nombre}">
                                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                             viewBox="0 0 24 24" stroke="currentColor"
                                                             stroke-width="1.8">
                                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                                  d="M6 18 18 6M6 6l12 12"/>
                                                        </svg>
                                                    </button>
                                                </form>
                                            </c:if>
                                        </div>
                                    </c:forEach>

                                    <div style="padding:0.65rem 1.25rem; border-top:1px solid var(--clr-border-light);
                                                background:rgba(255,255,255,0.012);
                                                font-size:0.75rem; color:var(--clr-text-dim);">
                                        <strong style="color:var(--clr-text-muted);">
                                            <c:out value="${fn:length(inscritos)}"/>
                                        </strong>
                                        alumno<c:if test="${fn:length(inscritos) ne 1}">s</c:if> inscritos
                                        de <strong style="color:var(--clr-text-muted);">
                                            <c:out value="${cuposTotal}"/>
                                        </strong> cupos totales
                                    </div>
                                </c:when>

                                <c:otherwise>
                                    <div class="table-empty" style="padding:3rem 2rem;">
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
                                        <p class="table-empty__title">Sin inscritos</p>
                                        <p class="table-empty__desc">
                                            Nadie está inscrito en esta clase todavía.<br>
                                            Usa el formulario de la derecha para inscribir un alumno.
                                        </p>
                                    </div>
                                </c:otherwise>
                            </c:choose>
                        </div><%-- /lista inscritos --%>

                        <%-- Aside: inscribir + info --%>
                        <div style="display:flex; flex-direction:column; gap:1rem;">

                            <%-- Formulario inscribir (solo admin y recep) --%>
                            <c:if test="${(sessionScope.userRole eq 'ROL-ADMIN'
                                          or sessionScope.userRole eq 'ROL-RECEP')
                                          and clase.estado eq 'vigente'
                                          and cuposLibres > 0}">
                                <div class="inscribir-card">
                                    <div class="horario-form-header">
                                        <div class="horario-form-header__icon">
                                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                <path stroke-linecap="round" stroke-linejoin="round"
                                                      d="M18 7.5v3m0 0v3m0-3h3m-3 0h-3m-2.25-4.125a3.375 3.375 0
                                                         1 1-6.75 0 3.375 3.375 0 0 1 6.75 0ZM3 19.235v-.11a6.375
                                                         6.375 0 0 1 12.75 0v.109A12.318 12.318 0 0 1 9.374 21c-2.331
                                                         0-4.512-.645-6.374-1.766Z"/>
                                            </svg>
                                        </div>
                                        <span class="horario-form-header__title">Inscribir alumno</span>
                                    </div>

                                    <form action="${pageContext.request.contextPath}/schedules"
                                          method="post"
                                          novalidate>
                                        <input type="hidden" name="action"  value="inscribir">
                                        <input type="hidden" name="claseId" value="<c:out value='${clase.id}'/>">
                                        <input type="hidden" name="_csrf"   value="${sessionScope._csrfToken}">

                                        <div class="horario-form-body">
                                            <div class="form-field">
                                                <label for="clienteId">
                                                    Seleccionar cliente <span class="required-star">*</span>
                                                </label>
                                                <select id="clienteId"
                                                        name="clienteId"
                                                        class="form-control"
                                                        required>
                                                    <option value="">— Buscar cliente —</option>
                                                    <c:forEach var="cli" items="${clientes}">
                                                        <option value="<c:out value='${cli.id}'/>">
                                                            <c:out value="${cli.apellido}"/>,
                                                            <c:out value="${cli.nombre}"/>
                                                            —
                                                            <c:if test="${cli.tipoDocumento != null}">
                                                                <c:out value="${cli.tipoDocumento.abreviado}"/>:
                                                            </c:if>
                                                            <c:out value="${cli.numeroDocumento}"/>
                                                        </option>
                                                    </c:forEach>
                                                </select>
                                                <span class="form-field__hint">
                                                    Quedan <strong><c:out value="${cuposLibres}"/></strong>
                                                    cupo<c:if test="${cuposLibres ne 1}">s</c:if>
                                                    libre<c:if test="${cuposLibres ne 1}">s</c:if>
                                                </span>
                                            </div>
                                            <button type="submit" class="btn btn-primary" style="width:100%;">
                                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                                    <path stroke-linecap="round" stroke-linejoin="round"
                                                          d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                                </svg>
                                                Confirmar inscripción
                                            </button>
                                        </div>
                                    </form>
                                </div>
                            </c:if>

                            <%-- Aviso sin cupo --%>
                            <c:if test="${cuposLibres le 0 and clase.estado eq 'vigente'}">
                                <div class="module-alert module-alert--warning" style="margin-bottom:0;">
                                    <svg class="module-alert__icon" xmlns="http://www.w3.org/2000/svg"
                                         fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M12 9v3.75m9-.75a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9 3.75h.008v.008H12v-.008Z"/>
                                    </svg>
                                    <div class="module-alert__body">
                                        <p class="module-alert__text">
                                            <strong>Clase llena.</strong> No quedan cupos disponibles.
                                            Cancela una inscripción existente para poder agregar nuevos alumnos.
                                        </p>
                                    </div>
                                </div>
                            </c:if>

                            <%-- Info de la clase --%>
                            <div class="clase-info-aside">
                                <div class="clase-info-aside__header">
                                    <c:if test="${clase.tipoClase != null}">
                                        <p class="clase-info-aside__tipo">
                                            <c:out value="${clase.tipoClase.nombre}"/>
                                        </p>
                                    </c:if>
                                    <p class="clase-info-aside__nombre">
                                        <c:out value="${clase.nombreClase}"/>
                                    </p>
                                </div>
                                <div style="padding:1rem 1.25rem; display:flex; flex-direction:column; gap:0.65rem;">
                                    <div class="aside-data-row">
                                        <span class="aside-data-row__label">Entrenador</span>
                                        <span class="aside-data-row__value strong">
                                            <c:if test="${clase.empleado != null}">
                                                <c:out value="${clase.empleado.nombreCompleto}"/>
                                            </c:if>
                                        </span>
                                    </div>
                                    <div class="aside-data-row">
                                        <span class="aside-data-row__label">Capacidad</span>
                                        <span class="aside-data-row__value strong">
                                            <c:out value="${cuposOcupados}"/> / <c:out value="${cuposTotal}"/>
                                        </span>
                                    </div>
                                    <div class="aside-data-row">
                                        <span class="aside-data-row__label">Estado</span>
                                        <span class="aside-data-row__value">
                                            <span class="class-estado-badge class-estado-badge--${clase.estado}">
                                                <c:out value="${clase.estado}"/>
                                            </span>
                                        </span>
                                    </div>
                                </div>
                                <c:if test="${sessionScope.userRole eq 'ROL-ADMIN'}">
                                    <div style="padding:0.75rem 1.25rem; border-top:1px solid var(--clr-border-light);">
                                        <a href="${pageContext.request.contextPath}/schedules?action=horarios&id=<c:out value='${clase.id}'/>"
                                           class="btn btn-ghost btn-sm" style="width:100%; justify-content:flex-start;">
                                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                <path stroke-linecap="round" stroke-linejoin="round"
                                                      d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                            </svg>
                                            Gestionar horarios
                                        </a>
                                    </div>
                                </c:if>
                            </div>

                        </div><%-- /aside --%>
                    </div><%-- /inscritos-layout --%>

                </c:when>

                <%-- ──────────────────────────────────────────
                     VISTA: LISTA DE CLASES (default)
                     ────────────────────────────────────────── --%>
                <c:otherwise>

                    <%-- Header del módulo --%>
                    <div class="module-header">
                        <div class="module-header__left">
                            <h1 class="module-header__title">
                                Clases Grupales
                                <span class="stat-chip"><c:out value="${totalClases}"/></span>
                            </h1>
                            <div class="module-header__meta">
                                <span>Programa de clases y horarios</span>
                                <span class="module-header__meta-sep"></span>
                                <a href="${pageContext.request.contextPath}/calendar"
                                   style="color:var(--clr-red); font-weight:600; font-size:0.78rem;
                                          text-decoration:none; display:flex; align-items:center; gap:0.28rem;">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8"
                                         style="width:13px;height:13px;">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M3.75 6A2.25 2.25 0 0 1 6 3.75h2.25A2.25 2.25 0 0 1 10.5 6v2.25a2.25 2.25 0 0
                                                 1-2.25 2.25H6a2.25 2.25 0 0 1-2.25-2.25V6ZM3.75 15.75A2.25 2.25 0 0 1 6
                                                 13.5h2.25a2.25 2.25 0 0 1 2.25 2.25V18a2.25 2.25 0 0 1-2.25 2.25H6A2.25 2.25
                                                 0 0 1 3.75 18v-2.25ZM13.5 6a2.25 2.25 0 0 1 2.25-2.25H18A2.25 2.25 0 0 1 20.25
                                                 6v2.25A2.25 2.25 0 0 1 18 10.5h-2.25a2.25 2.25 0 0 1-2.25-2.25V6ZM13.5
                                                 15.75a2.25 2.25 0 0 1 2.25-2.25H18a2.25 2.25 0 0 1 2.25 2.25V18A2.25 2.25
                                                 0 0 1 18 20.25h-2.25A2.25 2.25 0 0 1 13.5 18v-2.25Z"/>
                                    </svg>
                                    Ver calendario
                                </a>
                            </div>
                        </div>
                        <div class="module-header__actions">
                            <c:if test="${sessionScope.userRole eq 'ROL-ADMIN'}">
                                <a href="${pageContext.request.contextPath}/schedules?action=new"
                                   class="btn btn-primary">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.2">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M12 4.5v15m7.5-7.5h-15"/>
                                    </svg>
                                    Nueva clase
                                </a>
                            </c:if>
                        </div>
                    </div>

                    <%-- Strip de KPIs --%>
                    <c:if test="${not empty clases}">
                        <c:set var="cntVigentes"   value="0"/>
                        <c:set var="cntSuspendidas" value="0"/>
                        <c:forEach var="cl" items="${clases}">
                            <c:if test="${cl.vigente}">
                                <c:set var="cntVigentes" value="${cntVigentes + 1}"/>
                            </c:if>
                            <c:if test="${not cl.vigente}">
                                <c:set var="cntSuspendidas" value="${cntSuspendidas + 1}"/>
                            </c:if>
                        </c:forEach>

                        <div class="sch-kpi-strip">
                            <div class="sch-kpi">
                                <span class="sch-kpi__num"><c:out value="${totalClases}"/></span>
                                <span class="sch-kpi__label">Total clases</span>
                            </div>
                            <div class="sch-kpi">
                                <span class="sch-kpi__num green"><c:out value="${cntVigentes}"/></span>
                                <span class="sch-kpi__label">Vigentes</span>
                            </div>
                            <div class="sch-kpi">
                                <span class="sch-kpi__num orange"><c:out value="${cntSuspendidas}"/></span>
                                <span class="sch-kpi__label">Suspendidas</span>
                            </div>
                            <div class="sch-kpi">
                                <a href="${pageContext.request.contextPath}/calendar"
                                   class="sch-kpi" style="text-decoration:none; color:inherit; display:contents;">
                                    <span class="sch-kpi__num purple" style="font-size:0.92rem;">
                                        ▸ Cal.
                                    </span>
                                    <span class="sch-kpi__label">Ver calendario</span>
                                </a>
                            </div>
                        </div>
                    </c:if>

                    <%-- Grid de tarjetas de clase --%>
                    <c:choose>
                        <c:when test="${not empty clases}">
                            <div class="classes-grid">
                                <c:forEach var="cl" items="${clases}" varStatus="loop">

                                    <c:set var="colorIdx" value="${loop.index mod 6}"/>

                                    <div class="class-card color--${colorIdx}
                                                ${not cl.vigente ? 'is-suspended' : ''}">

                                        <%-- Franja de color --%>
                                        <div class="class-card__stripe"></div>

                                        <%-- Header: nombre + estado --%>
                                        <div class="class-card__header">
                                            <div class="class-card__meta">
                                                <c:if test="${cl.tipoClase != null}">
                                                    <p class="class-card__tipo">
                                                        <c:out value="${cl.tipoClase.nombre}"/>
                                                    </p>
                                                </c:if>
                                                <p class="class-card__nombre">
                                                    <c:out value="${cl.nombreClase}"/>
                                                </p>
                                            </div>
                                            <span class="class-estado-badge class-estado-badge--${cl.estado}">
                                                <c:out value="${cl.estado}"/>
                                            </span>
                                        </div>

                                        <div class="class-card__sep"></div>

                                        <%-- Entrenador --%>
                                        <div class="class-card__trainer">
                                            <div class="class-card__trainer-avatar">
                                                <c:if test="${cl.empleado != null}">
                                                    <c:out value="${fn:substring(cl.empleado.nombre, 0, 1)}"/>
                                                </c:if>
                                            </div>
                                            <div class="class-card__trainer-info">
                                                <p class="class-card__trainer-nombre">
                                                    <c:choose>
                                                        <c:when test="${cl.empleado != null}">
                                                            <c:out value="${cl.empleado.nombreCompleto}"/>
                                                        </c:when>
                                                        <c:otherwise>Sin asignar</c:otherwise>
                                                    </c:choose>
                                                </p>
                                                <p class="class-card__trainer-cargo">
                                                    <c:if test="${cl.empleado != null and cl.empleado.cargo != null}">
                                                        <c:out value="${cl.empleado.cargo.nombre}"/>
                                                    </c:if>
                                                </p>
                                            </div>
                                        </div>

                                        <%-- Stats: capacidad --%>
                                        <div class="class-card__stats">
                                            <div class="class-stat">
                                                <span class="class-stat__num">
                                                    <c:out value="${cl.capacidadMaxima}"/>
                                                </span>
                                                <span class="class-stat__label">capacidad</span>
                                            </div>
                                            <div class="class-stat">
                                                <span class="class-stat__num">
                                                    <c:out value="${cl.id}"/>
                                                </span>
                                                <span class="class-stat__label">ID</span>
                                            </div>
                                        </div>

                                        <%-- Descripción --%>
                                        <c:if test="${not empty cl.descripcion}">
                                            <p class="class-card__desc">
                                                "<c:out value="${cl.descripcion}"/>"
                                            </p>
                                        </c:if>

                                        <%-- Footer: acciones --%>
                                        <div class="class-card__footer">
                                            <span class="class-card__id">
                                                <c:out value="${cl.id}"/>
                                            </span>

                                            <div class="class-card__actions">

                                                <%-- Ver inscritos --%>
                                                <a href="${pageContext.request.contextPath}/schedules?action=inscritos&id=<c:out value='${cl.id}'/>"
                                                   class="btn btn-ghost btn-sm btn-icon"
                                                   title="Ver inscritos en ${cl.nombreClase}">
                                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                        <path stroke-linecap="round" stroke-linejoin="round"
                                                              d="M15 19.128a9.38 9.38 0 0 0 2.625.372 9.337 9.337 0 0
                                                                 0 4.121-.952 4.125 4.125 0 0 0-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15
                                                                 19.128v.106A12.318 12.318 0 0 1 8.624 21c-2.331
                                                                 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0
                                                                 1 11.964-3.07M12 6.375a3.375 3.375 0 1 1-6.75 0 3.375
                                                                 3.375 0 0 1 6.75 0Zm8.25 2.25a2.625 2.625 0 1 1-5.25
                                                                 0 2.625 2.625 0 0 1 5.25 0Z"/>
                                                    </svg>
                                                </a>

                                                <%-- Solo admin: gestionar horarios, editar, toggle, eliminar --%>
                                                <c:if test="${sessionScope.userRole eq 'ROL-ADMIN'}">

                                                    <%-- Horarios --%>
                                                    <a href="${pageContext.request.contextPath}/schedules?action=horarios&id=<c:out value='${cl.id}'/>"
                                                       class="btn btn-ghost btn-sm btn-icon"
                                                       title="Horarios de ${cl.nombreClase}">
                                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                                  d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                                        </svg>
                                                    </a>

                                                    <%-- Editar --%>
                                                    <a href="${pageContext.request.contextPath}/schedules?action=edit&id=<c:out value='${cl.id}'/>"
                                                       class="btn btn-ghost btn-sm btn-icon"
                                                       title="Editar ${cl.nombreClase}">
                                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                                  d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652
                                                                     2.652L10.582 16.07a4.5 4.5 0 0 1-1.897 1.13L6
                                                                     18l.8-2.685a4.5 4.5 0 0 1 1.13-1.897l8.932-8.931Zm0 0L19.5 7.125"/>
                                                        </svg>
                                                    </a>

                                                    <%-- Toggle estado --%>
                                                    <c:set var="toggleClaseMsg" value="${cl.vigente ? 'Suspender' : 'Reactivar'}"/>
                                                    <form action="${pageContext.request.contextPath}/schedules"
                                                    method="post"
                                                    style="display:inline;"
                                                    onsubmit="return confirm('¿${toggleClaseMsg} la clase ${cl.nombreClase}?');">
                                                        <input type="hidden" name="action" value="toggleEstado">
                                                        <input type="hidden" name="id"     value="<c:out value='${cl.id}'/>">
                                                        <input type="hidden" name="_csrf"  value="${sessionScope._csrfToken}">
                                                        <button type="submit"
                                                                class="btn ${cl.vigente ? 'btn-danger' : 'btn-success'} btn-sm btn-icon"
                                                                title="${cl.vigente ? 'Suspender clase' : 'Reactivar clase'}">
                                                            <c:choose>
                                                                <c:when test="${cl.vigente}">
                                                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                                        <path stroke-linecap="round" stroke-linejoin="round"
                                                                              d="M14.25 9v6m-4.5 0V9M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                                                    </svg>
                                                                </c:when>
                                                                <c:otherwise>
                                                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                                        <path stroke-linecap="round" stroke-linejoin="round"
                                                                              d="M5.25 5.653c0-.856.917-1.398 1.667-.986l11.54 6.347a1.125
                                                                                 1.125 0 0 1 0 1.972l-11.54 6.347a1.125 1.125 0 0 1-1.667-.986V5.653Z"/>
                                                                    </svg>
                                                                </c:otherwise>
                                                            </c:choose>
                                                        </button>
                                                    </form>

                                                </c:if>

                                            </div>
                                        </div>

                                    </div><%-- /class-card --%>
                                </c:forEach>
                            </div><%-- /classes-grid --%>

                            <%-- Nota al pie --%>
                            <div style="margin-top:1.25rem; padding:0.85rem 1.1rem;
                                        background:var(--clr-card); border:1px solid var(--clr-card-border);
                                        border-radius:var(--radius-md);
                                        display:flex; align-items:center; gap:0.65rem;">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8"
                                     style="width:14px;height:14px;flex-shrink:0;color:var(--clr-text-dim);">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                          d="m11.25 11.25.041-.02a.75.75 0 0 1 1.063.852l-.708 2.836a.75.75
                                             0 0 0 1.063.853l.041-.021M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9-3.75h.008v.008H12V8.25Z"/>
                                </svg>
                                <p style="font-size:0.73rem; color:var(--clr-text-dim); line-height:1.5;">
                                    Usa el ícono
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"
                                         style="width:11px;height:11px;vertical-align:middle;color:var(--clr-text-muted);">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                    </svg>
                                    para gestionar horarios y el ícono de personas para ver inscritos.
                                    Solo el <strong style="color:var(--clr-text-muted);">Administrador</strong>
                                    puede crear, editar y suspender clases.
                                </p>
                            </div>

                        </c:when>

                        <c:otherwise>
                            <%-- Estado vacío --%>
                            <div style="background:var(--clr-card); border:1px solid var(--clr-card-border);
                                        border-radius:var(--radius-lg); overflow:hidden;">
                                <div class="table-empty">
                                    <div class="table-empty__icon">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z"/>
                                        </svg>
                                    </div>
                                    <p class="table-empty__title">No hay clases registradas</p>
                                    <p class="table-empty__desc">
                                        Registra la primera clase grupal del gimnasio
                                        para comenzar a agregar horarios e inscribir alumnos.
                                    </p>
                                    <c:if test="${sessionScope.userRole eq 'ROL-ADMIN'}">
                                        <a href="${pageContext.request.contextPath}/schedules?action=new"
                                           class="btn btn-primary btn-sm" style="margin-top:0.5rem;">
                                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.2">
                                                <path stroke-linecap="round" stroke-linejoin="round"
                                                      d="M12 4.5v15m7.5-7.5h-15"/>
                                            </svg>
                                            Registrar primera clase
                                        </a>
                                    </c:if>
                                </div>
                            </div>
                        </c:otherwise>
                    </c:choose>

                </c:otherwise>
            </c:choose>

        </div><%-- /page-content --%>
    </div><%-- /app-main --%>
</div><%-- /app-shell --%>

</body>
</html>
