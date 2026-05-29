<%-- ============================================================
     reports.jsp  —  MaxFit Sistema de Gestión
     Reportes globales del sistema (solo ROL-ADMIN).

     Servlet:  ReportsController.java  → GET /reports
     Acceso:   Solo ROL-ADMIN (RoleFilter)

     ── Parámetros de URL que activan vistas ──────────────────
       /reports                      → reporte resumen (default)
       /reports?action=contratos     → reporte de contratos por estado
       /reports?action=asistencia    → reporte de asistencia
       /reports?action=membresias    → reporte de membresías activas

     ── Atributos comunes a todas las vistas ─────────────────
       vistaActiva     (String)       → "resumen"|"contratos"|"asistencia"|"membresias"
       fechaReporte    (String ISO)   → fecha actual del reporte

     ── Vista resumen (default) ──────────────────────────────
       totalClientes        (int / "-")
       contratosActivos     (int / "-")
       atendidosHoy         (int / "-")
       totalEmpleados       (int / "-")
       clasesVigentes       (int / "-")
       ingresosMes          (BigDecimal)
       proximosVencer       (List<Contrato>)
       countProximosVencer  (int)
       asistenciasRecientes (List<Asistencia>)  ← últimas 10

     ── Vista contratos (?action=contratos) ──────────────────
       contratosActivos     (int)
       contratosVencidos    (int)
       contratosCancelados  (int)
       contratosTotal       (int)
       pctActivos           (int)
       pctVencidos          (int)
       pctCancelados        (int)
       ingresosMes          (BigDecimal)
       proximosVencer       (List<Contrato>)
       countProximosVencer  (int)

     ── Vista asistencia (?action=asistencia) ────────────────
       atendidosHoy         (int)
       historialAsistencia  (List<Asistencia>)  ← últimas MAX_ASISTENCIAS_REPORTE=50
       totalHistorial       (int)
       maxAsistencias       (int)               = 50

     ── Vista membresías (?action=membresias) ────────────────
       membresias           (List<Membresia>)
       totalPlanes          (int)
       contratosActivos     (List<Contrato>)    ← findAllActivos()
       totalContratosActivos(int)

     Flash (via transferirFlashMessages):
       successMsg / errorMsg
     ============================================================ --%>
<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="fn"  uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <%@ include file="/WEB-INF/views/includes/head-common.jsp" %>
    <c:set var="pageTitle" value="Reportes" scope="request"/>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/modules.css">

    <style>
        /* ══════════════════════════════════════════════════════
           ESTILOS ESPECÍFICOS — MÓDULO REPORTES
           ══════════════════════════════════════════════════════ */

        /* ── Tabs de navegación entre reportes ──────────────── */
        .report-tabs {
            display: flex;
            align-items: stretch;
            gap: 0;
            background: var(--clr-card);
            border: 1px solid var(--clr-card-border);
            border-radius: var(--radius-lg);
            overflow: hidden;
            margin-bottom: 1.75rem;
        }

        .report-tab {
            display: flex;
            align-items: center;
            gap: 0.55rem;
            padding: 0.85rem 1.35rem;
            font-size: 0.82rem;
            font-weight: 600;
            color: var(--clr-text-muted);
            text-decoration: none;
            border-right: 1px solid var(--clr-border-light);
            transition: background var(--transition), color var(--transition);
            position: relative;
            white-space: nowrap;
            flex: 1;
            justify-content: center;
        }

        .report-tab:last-child { border-right: none; }

        .report-tab svg {
            width: 15px;
            height: 15px;
            flex-shrink: 0;
        }

        .report-tab:hover {
            background: var(--clr-surface);
            color: var(--clr-text);
        }

        .report-tab.active {
            background: var(--clr-surface);
            color: var(--clr-red);
        }

        .report-tab.active::after {
            content: '';
            position: absolute;
            bottom: 0;
            left: 0;
            right: 0;
            height: 2px;
            background: var(--clr-red);
            border-radius: 2px 2px 0 0;
        }

        /* ── Header de sección de reporte ───────────────────── */
        .report-section-header {
            display: flex;
            align-items: center;
            gap: 0.75rem;
            margin-bottom: 1.5rem;
        }

        .report-section-header__icon {
            flex-shrink: 0;
            width: 40px;
            height: 40px;
            border-radius: var(--radius-md);
            background: var(--clr-red-subtle);
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .report-section-header__icon svg {
            width: 18px;
            height: 18px;
            color: var(--clr-red);
        }

        .report-section-header__info {
            flex: 1;
        }

        .report-section-header__title {
            font-family: var(--font-display);
            font-weight: 800;
            font-size: 1.35rem;
            letter-spacing: 0.04em;
            text-transform: uppercase;
            color: var(--clr-text);
            line-height: 1.1;
        }

        .report-section-header__sub {
            font-size: 0.75rem;
            color: var(--clr-text-dim);
            margin-top: 0.1rem;
        }

        /* ── Grid de KPIs del reporte ───────────────────────── */
        .report-kpi-grid {
            display: grid;
            grid-template-columns: repeat(6, 1fr);
            gap: 1rem;
            margin-bottom: 1.75rem;
        }

        .report-kpi-card {
            background: var(--clr-card);
            border: 1px solid var(--clr-card-border);
            border-radius: var(--radius-lg);
            padding: 1.1rem 1.15rem;
            display: flex;
            flex-direction: column;
            gap: 0.55rem;
            position: relative;
            overflow: hidden;
            transition: border-color var(--transition), transform var(--transition);
            animation: fadeSlideUp 0.4s cubic-bezier(0.4,0,0.2,1) both;
        }

        .report-kpi-card:hover {
            border-color: rgba(255,255,255,0.10);
            transform: translateY(-2px);
        }

        /* Franja superior al hover */
        .report-kpi-card::before {
            content: '';
            position: absolute;
            top: 0; left: 0; right: 0;
            height: 2px;
            background: var(--kpi-c, var(--clr-red));
            transform: scaleX(0);
            transform-origin: left;
            transition: transform 0.35s cubic-bezier(0.4,0,0.2,1);
            border-radius: 0 0 2px 2px;
        }

        .report-kpi-card:hover::before { transform: scaleX(1); }

        /* Variantes de color */
        .report-kpi-card.c--red    { --kpi-c: var(--clr-red); }
        .report-kpi-card.c--green  { --kpi-c: var(--clr-success); }
        .report-kpi-card.c--blue   { --kpi-c: var(--clr-info); }
        .report-kpi-card.c--yellow { --kpi-c: var(--clr-warning); }
        .report-kpi-card.c--purple { --kpi-c: #a78bfa; }
        .report-kpi-card.c--teal   { --kpi-c: #2dd4bf; }

        .report-kpi-card__header {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 0.5rem;
        }

        .report-kpi-card__label {
            font-size: 0.68rem;
            font-weight: 600;
            letter-spacing: 0.08em;
            text-transform: uppercase;
            color: var(--clr-text-muted);
            line-height: 1.3;
        }

        .report-kpi-card__badge {
            flex-shrink: 0;
            width: 30px;
            height: 30px;
            border-radius: var(--radius-sm);
            background: color-mix(in srgb, var(--kpi-c, var(--clr-red)) 12%, transparent);
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .report-kpi-card__badge svg {
            width: 14px;
            height: 14px;
            color: var(--kpi-c, var(--clr-red));
        }

        .report-kpi-card__value {
            font-family: var(--font-display);
            font-weight: 800;
            font-size: 1.75rem;
            line-height: 1;
            color: var(--clr-text);
            letter-spacing: 0.02em;
        }

        .report-kpi-card__value.is-money::before {
            content: 'S/ ';
            font-size: 0.9rem;
            font-weight: 600;
            color: var(--clr-text-muted);
            font-family: var(--font-body);
            letter-spacing: 0;
        }

        .report-kpi-card__meta {
            font-size: 0.70rem;
            color: var(--clr-text-dim);
            display: flex;
            align-items: center;
            gap: 0.25rem;
        }

        .report-kpi-card__meta svg {
            width: 11px;
            height: 11px;
            flex-shrink: 0;
        }

        /* Animaciones escalonadas de las KPI cards */
        .report-kpi-card:nth-child(1) { animation-delay: 0.04s; }
        .report-kpi-card:nth-child(2) { animation-delay: 0.08s; }
        .report-kpi-card:nth-child(3) { animation-delay: 0.12s; }
        .report-kpi-card:nth-child(4) { animation-delay: 0.16s; }
        .report-kpi-card:nth-child(5) { animation-delay: 0.20s; }
        .report-kpi-card:nth-child(6) { animation-delay: 0.24s; }

        /* ── Layout de dos columnas para reportes ──────────── */
        .report-two-col {
            display: grid;
            grid-template-columns: 1fr 360px;
            gap: 1.25rem;
            align-items: start;
        }

        .report-two-col--wide {
            grid-template-columns: 1fr 320px;
        }

        /* ── Card genérica de reporte ───────────────────────── */
        .report-card {
            background: var(--clr-card);
            border: 1px solid var(--clr-card-border);
            border-radius: var(--radius-lg);
            overflow: hidden;
            animation: fadeSlideUp 0.4s cubic-bezier(0.4,0,0.2,1) both 0.10s;
        }

        .report-card__header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 0.9rem 1.25rem;
            border-bottom: 1px solid var(--clr-border);
            background: var(--clr-surface);
            gap: 0.75rem;
        }

        .report-card__header-left {
            display: flex;
            align-items: center;
            gap: 0.55rem;
        }

        .report-card__icon {
            flex-shrink: 0;
            width: 28px;
            height: 28px;
            border-radius: var(--radius-xs);
            background: var(--clr-red-subtle);
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .report-card__icon svg {
            width: 13px;
            height: 13px;
            color: var(--clr-red);
        }

        .report-card__icon.green-icon {
            background: var(--clr-success-subtle);
        }

        .report-card__icon.green-icon svg { color: var(--clr-success); }

        .report-card__icon.blue-icon {
            background: var(--clr-info-subtle);
        }

        .report-card__icon.blue-icon svg { color: var(--clr-info); }

        .report-card__icon.yellow-icon {
            background: var(--clr-warning-subtle);
        }

        .report-card__icon.yellow-icon svg { color: var(--clr-warning); }

        .report-card__title {
            font-size: 0.82rem;
            font-weight: 700;
            letter-spacing: 0.04em;
            text-transform: uppercase;
            color: var(--clr-text-muted);
        }

        /* ── Gráfico de barras donut (CSS puro) ─────────────── */
        .donut-chart-wrap {
            padding: 1.5rem;
            display: flex;
            align-items: center;
            gap: 1.5rem;
        }

        .donut-chart {
            flex-shrink: 0;
            width: 120px;
            height: 120px;
            border-radius: 50%;
            position: relative;
        }

        .donut-chart__svg {
            width: 120px;
            height: 120px;
            transform: rotate(-90deg);
        }

        .donut-chart__bg {
            fill: none;
            stroke: var(--clr-surface-2);
            stroke-width: 18;
        }

        .donut-chart__seg {
            fill: none;
            stroke-width: 18;
            stroke-linecap: round;
            transition: stroke-dashoffset 0.8s cubic-bezier(0.4,0,0.2,1);
        }

        .donut-chart__seg--activos    { stroke: var(--clr-success); }
        .donut-chart__seg--vencidos   { stroke: var(--clr-red); }
        .donut-chart__seg--cancelados { stroke: var(--clr-text-dim); }

        .donut-chart__center {
            position: absolute;
            inset: 0;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
        }

        .donut-chart__center-num {
            font-family: var(--font-display);
            font-weight: 800;
            font-size: 1.5rem;
            line-height: 1;
            color: var(--clr-text);
        }

        .donut-chart__center-label {
            font-size: 0.60rem;
            font-weight: 700;
            letter-spacing: 0.06em;
            text-transform: uppercase;
            color: var(--clr-text-dim);
            margin-top: 0.15rem;
        }

        .donut-legend {
            flex: 1;
            display: flex;
            flex-direction: column;
            gap: 0.65rem;
        }

        .donut-legend-item {
            display: flex;
            align-items: center;
            gap: 0.55rem;
        }

        .donut-legend-dot {
            flex-shrink: 0;
            width: 10px;
            height: 10px;
            border-radius: 50%;
        }

        .donut-legend-dot--activos    { background: var(--clr-success); }
        .donut-legend-dot--vencidos   { background: var(--clr-red); }
        .donut-legend-dot--cancelados { background: var(--clr-text-dim); }

        .donut-legend-info {
            flex: 1;
        }

        .donut-legend-nombre {
            font-size: 0.78rem;
            font-weight: 500;
            color: var(--clr-text-muted);
        }

        .donut-legend-val {
            display: flex;
            align-items: baseline;
            gap: 0.35rem;
        }

        .donut-legend-num {
            font-family: var(--font-display);
            font-size: 1.15rem;
            font-weight: 700;
            color: var(--clr-text);
            line-height: 1;
        }

        .donut-legend-pct {
            font-size: 0.70rem;
            color: var(--clr-text-dim);
        }

        /* ── Barras de porcentaje (CSS) ─────────────────────── */
        .pct-bar-list {
            padding: 1rem 1.25rem;
            display: flex;
            flex-direction: column;
            gap: 0.85rem;
        }

        .pct-bar-item {
            display: flex;
            flex-direction: column;
            gap: 0.3rem;
        }

        .pct-bar-item__header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 0.5rem;
        }

        .pct-bar-item__label {
            font-size: 0.78rem;
            font-weight: 600;
            color: var(--clr-text-muted);
            display: flex;
            align-items: center;
            gap: 0.4rem;
        }

        .pct-bar-item__dot {
            width: 7px;
            height: 7px;
            border-radius: 50%;
            flex-shrink: 0;
        }

        .pct-bar-item__val {
            font-family: var(--font-mono);
            font-size: 0.78rem;
            font-weight: 700;
            color: var(--clr-text);
        }

        .pct-bar-bg {
            height: 7px;
            background: var(--clr-surface-2);
            border-radius: var(--radius-full);
            overflow: hidden;
        }

        .pct-bar-fill {
            height: 100%;
            border-radius: var(--radius-full);
            transition: width 0.9s cubic-bezier(0.4,0,0.2,1);
        }

        /* ── Tabla de reporte de asistencia ─────────────────── */
        .attendance-row {
            display: flex;
            align-items: center;
            gap: 0.85rem;
            padding: 0.7rem 1.25rem;
            border-bottom: 1px solid var(--clr-border-light);
            transition: background var(--transition);
        }

        .attendance-row:last-child { border-bottom: none; }
        .attendance-row:hover { background: rgba(255,255,255,0.025); }

        .attendance-row__num {
            flex-shrink: 0;
            width: 24px;
            height: 24px;
            border-radius: var(--radius-xs);
            background: var(--clr-surface-2);
            border: 1px solid var(--clr-border);
            display: flex;
            align-items: center;
            justify-content: center;
            font-family: var(--font-mono);
            font-size: 0.62rem;
            font-weight: 700;
            color: var(--clr-text-dim);
        }

        .attendance-row__dot {
            flex-shrink: 0;
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background: var(--clr-success);
        }

        .attendance-row__dot.falto     { background: var(--clr-text-dim); }
        .attendance-row__dot.pendiente { background: var(--clr-warning); }

        .attendance-row__nombre {
            flex: 1;
            font-size: 0.83rem;
            font-weight: 500;
            color: var(--clr-text);
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .attendance-row__membresia {
            font-size: 0.70rem;
            color: var(--clr-text-dim);
            white-space: nowrap;
            max-width: 130px;
            overflow: hidden;
            text-overflow: ellipsis;
            flex-shrink: 0;
        }

        .attendance-row__fecha {
            flex-shrink: 0;
            font-size: 0.72rem;
            color: var(--clr-text-muted);
            min-width: 86px;
        }

        .attendance-row__hora {
            flex-shrink: 0;
            font-family: var(--font-mono);
            font-size: 0.70rem;
            color: var(--clr-text-muted);
            background: var(--clr-surface);
            padding: 0.14rem 0.42rem;
            border-radius: var(--radius-xs);
            border: 1px solid var(--clr-border-light);
        }

        /* ── Tabla de próximos a vencer ─────────────────────── */
        .vence-row {
            display: flex;
            align-items: center;
            gap: 0.75rem;
            padding: 0.7rem 1.25rem;
            border-bottom: 1px solid var(--clr-border-light);
            transition: background var(--transition);
        }

        .vence-row:last-child { border-bottom: none; }
        .vence-row:hover { background: rgba(255,255,255,0.025); }

        .vence-row__avatar {
            flex-shrink: 0;
            width: 30px;
            height: 30px;
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

        .vence-row__avatar.urgent {
            background: var(--clr-danger-subtle);
            color: var(--clr-red);
            border-color: rgba(230,48,39,0.22);
        }

        .vence-row__info { flex: 1; min-width: 0; }

        .vence-row__nombre {
            font-size: 0.82rem;
            font-weight: 600;
            color: var(--clr-text);
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .vence-row__membresia {
            font-size: 0.68rem;
            color: var(--clr-text-dim);
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .vence-row__fecha {
            flex-shrink: 0;
            font-size: 0.72rem;
            font-weight: 600;
            color: var(--clr-warning);
        }

        .vence-row__fecha.urgente { color: var(--clr-red); }

        /* ── Tarjetas de membresía en reporte ───────────────── */
        .membresia-report-list {
            display: flex;
            flex-direction: column;
            gap: 0;
        }

        .membresia-report-row {
            display: flex;
            align-items: center;
            gap: 0.85rem;
            padding: 0.85rem 1.25rem;
            border-bottom: 1px solid var(--clr-border-light);
            transition: background var(--transition);
        }

        .membresia-report-row:last-child { border-bottom: none; }
        .membresia-report-row:hover { background: rgba(255,255,255,0.025); }

        .membresia-report-row__rank {
            flex-shrink: 0;
            width: 28px;
            height: 28px;
            border-radius: var(--radius-sm);
            background: var(--clr-red-subtle);
            border: 1px solid rgba(230,48,39,0.15);
            display: flex;
            align-items: center;
            justify-content: center;
            font-family: var(--font-display);
            font-size: 0.80rem;
            font-weight: 800;
            color: var(--clr-red);
        }

        .membresia-report-row__info { flex: 1; min-width: 0; }

        .membresia-report-row__nombre {
            font-family: var(--font-display);
            font-weight: 700;
            font-size: 0.95rem;
            letter-spacing: 0.03em;
            text-transform: uppercase;
            color: var(--clr-text);
            line-height: 1.2;
        }

        .membresia-report-row__dur {
            font-size: 0.70rem;
            color: var(--clr-text-dim);
        }

        .membresia-report-row__precio {
            flex-shrink: 0;
            font-family: var(--font-display);
            font-weight: 800;
            font-size: 1.1rem;
            color: var(--clr-success);
        }

        .membresia-report-row__precio::before {
            content: 'S/ ';
            font-size: 0.72rem;
            font-weight: 600;
            color: rgba(34,197,94,0.6);
            font-family: var(--font-body);
        }

        /* ── Tabla contratos activos en reporte membresias ──── */
        .contrato-compact-row {
            display: flex;
            align-items: center;
            gap: 0.75rem;
            padding: 0.65rem 1.25rem;
            border-bottom: 1px solid var(--clr-border-light);
            transition: background var(--transition);
        }

        .contrato-compact-row:last-child { border-bottom: none; }
        .contrato-compact-row:hover { background: rgba(255,255,255,0.02); }

        .contrato-compact-row__avatar {
            flex-shrink: 0;
            width: 26px;
            height: 26px;
            border-radius: var(--radius-xs);
            background: var(--clr-success-subtle);
            border: 1px solid rgba(34,197,94,0.15);
            display: flex;
            align-items: center;
            justify-content: center;
            font-family: var(--font-display);
            font-size: 0.68rem;
            font-weight: 700;
            color: var(--clr-success);
            text-transform: uppercase;
        }

        .contrato-compact-row__nombre {
            flex: 1;
            font-size: 0.78rem;
            font-weight: 500;
            color: var(--clr-text);
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .contrato-compact-row__plan {
            flex-shrink: 0;
            font-size: 0.70rem;
            color: var(--clr-text-dim);
            max-width: 100px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .contrato-compact-row__vence {
            flex-shrink: 0;
            font-size: 0.68rem;
            color: var(--clr-text-dim);
            white-space: nowrap;
        }

        /* ── Badge fecha del reporte ─────────────────────────── */
        .report-date-badge {
            display: inline-flex;
            align-items: center;
            gap: 0.35rem;
            padding: 0.3rem 0.75rem;
            border-radius: var(--radius-full);
            font-size: 0.72rem;
            font-weight: 600;
            background: var(--clr-surface-2);
            border: 1px solid var(--clr-border);
            color: var(--clr-text-muted);
            flex-shrink: 0;
        }

        .report-date-badge svg {
            width: 12px;
            height: 12px;
            flex-shrink: 0;
            color: var(--clr-text-dim);
        }

        /* ── Strip resumen de ingresos ──────────────────────── */
        .ingresos-highlight {
            background: linear-gradient(135deg, #161618 0%, #1c1416 60%, #1a1212 100%);
            border: 1px solid rgba(230,48,39,0.18);
            border-radius: var(--radius-lg);
            padding: 1.35rem 1.5rem;
            display: flex;
            align-items: center;
            gap: 1.5rem;
            position: relative;
            overflow: hidden;
            margin-bottom: 1.25rem;
        }

        .ingresos-highlight::after {
            content: '';
            position: absolute;
            bottom: -50px;
            right: -50px;
            width: 160px;
            height: 160px;
            background: radial-gradient(circle, rgba(230,48,39,0.12) 0%, transparent 70%);
            pointer-events: none;
        }

        .ingresos-highlight::before {
            content: '';
            position: absolute;
            left: 0; top: 0; bottom: 0;
            width: 3px;
            background: var(--clr-red);
            border-radius: 0 2px 2px 0;
        }

        .ingresos-highlight__icon {
            flex-shrink: 0;
            width: 52px;
            height: 52px;
            border-radius: var(--radius-lg);
            background: var(--clr-red-subtle);
            border: 1px solid rgba(230,48,39,0.18);
            display: flex;
            align-items: center;
            justify-content: center;
            margin-left: 0.5rem;
        }

        .ingresos-highlight__icon svg {
            width: 24px;
            height: 24px;
            color: var(--clr-red);
        }

        .ingresos-highlight__info { flex: 1; }

        .ingresos-highlight__label {
            font-size: 0.70rem;
            font-weight: 700;
            letter-spacing: 0.12em;
            text-transform: uppercase;
            color: var(--clr-text-dim);
            margin-bottom: 0.2rem;
        }

        .ingresos-highlight__amount {
            font-family: var(--font-display);
            font-weight: 800;
            font-size: 2.1rem;
            line-height: 1;
            color: var(--clr-text);
            letter-spacing: 0.02em;
        }

        .ingresos-highlight__amount::before {
            content: 'S/ ';
            font-size: 1rem;
            font-weight: 600;
            color: var(--clr-text-muted);
            font-family: var(--font-body);
        }

        .ingresos-highlight__meta {
            font-size: 0.75rem;
            color: var(--clr-text-dim);
            margin-top: 0.25rem;
        }

        .ingresos-highlight__meta strong {
            color: var(--clr-text-muted);
        }

        /* ── Nota vacía dentro de cards ─────────────────────── */
        .report-empty {
            padding: 2.5rem 1.5rem;
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 0.6rem;
            text-align: center;
        }

        .report-empty svg {
            width: 36px;
            height: 36px;
            color: var(--clr-text-dim);
            opacity: 0.4;
        }

        .report-empty p {
            font-size: 0.80rem;
            color: var(--clr-text-dim);
            line-height: 1.5;
        }

        /* ── Responsive ─────────────────────────────────────── */
        @media (max-width: 1280px) {
            .report-kpi-grid { grid-template-columns: repeat(3, 1fr); }
        }

        @media (max-width: 1024px) {
            .report-two-col,
            .report-two-col--wide {
                grid-template-columns: 1fr;
            }
            .report-kpi-grid { grid-template-columns: repeat(3, 1fr); }
        }

        @media (max-width: 768px) {
            .report-kpi-grid { grid-template-columns: repeat(2, 1fr); }
            .report-tabs { flex-wrap: wrap; }
            .report-tab { flex: none; border-right: none; border-bottom: 1px solid var(--clr-border-light); }
            .donut-chart-wrap { flex-direction: column; align-items: flex-start; }
        }

        @media (max-width: 480px) {
            .report-kpi-grid { grid-template-columns: 1fr 1fr; }
        }
    </style>
</head>
<body>

<div class="app-shell">
    <%@ include file="/WEB-INF/views/includes/sidebar.jsp" %>

    <div class="app-main">

        <c:set var="pageTitle"    value="Reportes"                      scope="request"/>
        <c:set var="pageSubtitle" value="Panel analítico del sistema"   scope="request"/>
        <%@ include file="/WEB-INF/views/includes/navbar.jsp" %>

        <div class="page-content">

            <%-- ── Header del módulo ──────────────────────────── --%>
            <div class="module-header" style="margin-bottom:1.25rem;">
                <div class="module-header__left">
                    <div class="report-section-header">
                        <div class="report-section-header__icon">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                      d="M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504
                                         1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125
                                         1.125 0 0 1 3 19.875v-6.75ZM9.75 8.625c0-.621.504-1.125
                                         1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0
                                         .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 0
                                         1-1.125-1.125V8.625ZM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496
                                         3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125
                                         1.125h-2.25a1.125 1.125 0 0 1-1.125-1.125V4.125Z"/>
                            </svg>
                        </div>
                        <div class="report-section-header__info">
                            <h1 class="report-section-header__title">
                                Reportes del Sistema
                            </h1>
                            <p class="report-section-header__sub">
                                Datos en tiempo real — generado el
                                <strong style="color:var(--clr-text-muted);">
                                    <c:out value="${fechaReporte}"/>
                                </strong>
                            </p>
                        </div>
                    </div>
                </div>
                <div class="module-header__actions">
                    <span class="report-date-badge">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25
                                     2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0
                                     0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5"/>
                        </svg>
                        <c:out value="${fechaReporte}"/>
                    </span>
                </div>
            </div>

            <%-- ── Tabs de navegación ────────────────────────── --%>
            <div class="report-tabs" role="tablist" aria-label="Secciones del reporte">

                <%-- Resumen --%>
                <a href="${pageContext.request.contextPath}/reports"
                   class="report-tab ${vistaActiva eq 'resumen' ? 'active' : ''}"
                   role="tab"
                   aria-selected="${vistaActiva eq 'resumen' ? 'true' : 'false'}">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                        <path stroke-linecap="round" stroke-linejoin="round"
                              d="M3.75 6A2.25 2.25 0 0 1 6 3.75h2.25A2.25 2.25 0 0 1 10.5 6v2.25a2.25 2.25
                                 0 0 1-2.25 2.25H6a2.25 2.25 0 0 1-2.25-2.25V6ZM3.75 15.75A2.25 2.25 0 0 1
                                 6 13.5h2.25a2.25 2.25 0 0 1 2.25 2.25V18a2.25 2.25 0 0 1-2.25 2.25H6A2.25
                                 2.25 0 0 1 3.75 18v-2.25ZM13.5 6a2.25 2.25 0 0 1 2.25-2.25H18A2.25 2.25 0
                                 0 1 20.25 6v2.25A2.25 2.25 0 0 1 18 10.5h-2.25a2.25 2.25 0 0 1-2.25-2.25V6Z
                                 M13.5 15.75a2.25 2.25 0 0 1 2.25-2.25H18a2.25 2.25 0 0 1 2.25 2.25V18A2.25
                                 2.25 0 0 1 18 20.25h-2.25A2.25 2.25 0 0 1 13.5 18v-2.25Z"/>
                    </svg>
                    Resumen general
                </a>

                <%-- Contratos --%>
                <a href="${pageContext.request.contextPath}/reports?action=contratos"
                   class="report-tab ${vistaActiva eq 'contratos' ? 'active' : ''}"
                   role="tab"
                   aria-selected="${vistaActiva eq 'contratos' ? 'true' : 'false'}">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                        <path stroke-linecap="round" stroke-linejoin="round"
                              d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125 1.125 0 0 1
                                 13.5 7.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5
                                 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125
                                 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z"/>
                    </svg>
                    Contratos
                </a>

                <%-- Asistencia --%>
                <a href="${pageContext.request.contextPath}/reports?action=asistencia"
                   class="report-tab ${vistaActiva eq 'asistencia' ? 'active' : ''}"
                   role="tab"
                   aria-selected="${vistaActiva eq 'asistencia' ? 'true' : 'false'}">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                        <path stroke-linecap="round" stroke-linejoin="round"
                              d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                    </svg>
                    Asistencia
                </a>

                <%-- Membresías --%>
                <a href="${pageContext.request.contextPath}/reports?action=membresias"
                   class="report-tab ${vistaActiva eq 'membresias' ? 'active' : ''}"
                   role="tab"
                   aria-selected="${vistaActiva eq 'membresias' ? 'true' : 'false'}">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                        <path stroke-linecap="round" stroke-linejoin="round"
                              d="M2.25 8.25h19.5M2.25 9h19.5m-16.5 5.25h6m-6 2.25h3m-3.75 3h15a2.25 2.25
                                 0 0 0 2.25-2.25V6.75A2.25 2.25 0 0 0 19.5 4.5h-15a2.25 2.25 0 0 0-2.25
                                 2.25v10.5A2.25 2.25 0 0 0 4.5 19.5Z"/>
                    </svg>
                    Membresías
                </a>

            </div>

            <%-- ═══════════════════════════════════════════════
                 BIFURCACIÓN PRINCIPAL DE VISTAS
                 ═══════════════════════════════════════════════ --%>
            <c:choose>

                <%-- ──────────────────────────────────────────
                     VISTA: REPORTE DE CONTRATOS
                     ?action=contratos
                     ────────────────────────────────────────── --%>
                <c:when test="${vistaActiva eq 'contratos'}">

                    <%-- KPIs de contratos --%>
                    <div class="report-kpi-grid">

                        <%-- Activos --%>
                        <div class="report-kpi-card c--green">
                            <div class="report-kpi-card__header">
                                <span class="report-kpi-card__label">Contratos activos</span>
                                <div class="report-kpi-card__badge">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                    </svg>
                                </div>
                            </div>
                            <div class="report-kpi-card__value">
                                <c:out value="${contratosActivos}"/>
                            </div>
                            <div class="report-kpi-card__meta">
                                <c:out value="${pctActivos}"/>% del total
                            </div>
                        </div>

                        <%-- Vencidos --%>
                        <div class="report-kpi-card c--red">
                            <div class="report-kpi-card__header">
                                <span class="report-kpi-card__label">Contratos vencidos</span>
                                <div class="report-kpi-card__badge">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                    </svg>
                                </div>
                            </div>
                            <div class="report-kpi-card__value">
                                <c:out value="${contratosVencidos}"/>
                            </div>
                            <div class="report-kpi-card__meta">
                                <c:out value="${pctVencidos}"/>% del total
                            </div>
                        </div>

                        <%-- Cancelados --%>
                        <div class="report-kpi-card c--yellow">
                            <div class="report-kpi-card__header">
                                <span class="report-kpi-card__label">Cancelados</span>
                                <div class="report-kpi-card__badge">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M6 18 18 6M6 6l12 12"/>
                                    </svg>
                                </div>
                            </div>
                            <div class="report-kpi-card__value">
                                <c:out value="${contratosCancelados}"/>
                            </div>
                            <div class="report-kpi-card__meta">
                                <c:out value="${pctCancelados}"/>% del total
                            </div>
                        </div>

                        <%-- Total general --%>
                        <div class="report-kpi-card c--blue">
                            <div class="report-kpi-card__header">
                                <span class="report-kpi-card__label">Total contratos</span>
                                <div class="report-kpi-card__badge">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M3.75 12h16.5m-16.5 3.75h16.5M3.75 19.5h16.5M5.625
                                                 4.5h12.75a1.875 1.875 0 0 1 0 3.75H5.625a1.875 1.875
                                                 0 0 1 0-3.75Z"/>
                                    </svg>
                                </div>
                            </div>
                            <div class="report-kpi-card__value">
                                <c:out value="${contratosTotal}"/>
                            </div>
                            <div class="report-kpi-card__meta">Histórico acumulado</div>
                        </div>

                        <%-- Próximos a vencer --%>
                        <div class="report-kpi-card c--yellow">
                            <div class="report-kpi-card__header">
                                <span class="report-kpi-card__label">Vencen pronto</span>
                                <div class="report-kpi-card__badge">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73
                                                 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898
                                                 0L2.697 16.126ZM12 15.75h.007v.008H12v-.008Z"/>
                                    </svg>
                                </div>
                            </div>
                            <div class="report-kpi-card__value">
                                <c:out value="${countProximosVencer}"/>
                            </div>
                            <div class="report-kpi-card__meta">En los próximos 7 días</div>
                        </div>

                        <%-- Ingresos del mes --%>
                        <div class="report-kpi-card c--red">
                            <div class="report-kpi-card__header">
                                <span class="report-kpi-card__label">Ingresos del mes</span>
                                <div class="report-kpi-card__badge">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
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
                            <div class="report-kpi-card__value is-money">
                                <fmt:formatNumber value="${ingresosMes}" pattern="#,##0.00"/>
                            </div>
                            <div class="report-kpi-card__meta">Facturado este mes</div>
                        </div>

                    </div><%-- /report-kpi-grid --%>

                    <%-- Layout: gráfico + próximos --%>
                    <div class="report-two-col">

                        <%-- Distribución de contratos --%>
                        <div class="report-card">
                            <div class="report-card__header">
                                <div class="report-card__header-left">
                                    <div class="report-card__icon">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
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
                                    </div>
                                    <span class="report-card__title">Distribución de contratos</span>
                                </div>
                                <span class="stat-chip">
                                    Total: <c:out value="${contratosTotal}"/>
                                </span>
                            </div>

                            <%-- Gráfico de donut CSS --%>
                            <c:if test="${contratosTotal > 0}">
                                <c:set var="circum" value="282.74"/>
                                <%-- Activos --%>
                                <c:set var="dashaActivo"    value="${pctActivos * 2.8274}"/>
                                <c:set var="dashgActivo"    value="${circum - dashaActivo}"/>
                                <%-- Vencidos (arranca después de activos) --%>
                                <c:set var="offsetVencido"  value="${circum - dashaActivo}"/>
                                <c:set var="dashaVencido"   value="${pctVencidos * 2.8274}"/>
                                <c:set var="dashgVencido"   value="${circum - dashaVencido}"/>

                                <div class="donut-chart-wrap">
                                    <div class="donut-chart">
                                        <svg class="donut-chart__svg"
                                             viewBox="0 0 120 120"
                                             xmlns="http://www.w3.org/2000/svg"
                                             aria-label="Gráfico de distribución de contratos"
                                             role="img">
                                            <title>Distribución de contratos por estado</title>
                                            <%-- Fondo --%>
                                            <circle class="donut-chart__bg" cx="60" cy="60" r="45"/>
                                            <%-- Segmento activos --%>
                                            <circle class="donut-chart__seg donut-chart__seg--activos"
                                                    cx="60" cy="60" r="45"
                                                    stroke-dasharray="${dashaActivo} ${dashgActivo}"
                                                    stroke-dashoffset="0"/>
                                            <%-- Segmento vencidos --%>
                                            <circle class="donut-chart__seg donut-chart__seg--vencidos"
                                                    cx="60" cy="60" r="45"
                                                    stroke-dasharray="${dashaVencido} ${dashgVencido}"
                                                    stroke-dashoffset="-${dashaActivo}"/>
                                        </svg>
                                        <div class="donut-chart__center">
                                            <span class="donut-chart__center-num">
                                                <c:out value="${contratosTotal}"/>
                                            </span>
                                            <span class="donut-chart__center-label">Total</span>
                                        </div>
                                    </div>

                                    <div class="donut-legend">
                                        <div class="donut-legend-item">
                                            <div class="donut-legend-dot donut-legend-dot--activos"></div>
                                            <div class="donut-legend-info">
                                                <p class="donut-legend-nombre">Activos</p>
                                                <div class="donut-legend-val">
                                                    <span class="donut-legend-num">
                                                        <c:out value="${contratosActivos}"/>
                                                    </span>
                                                    <span class="donut-legend-pct">
                                                        (<c:out value="${pctActivos}"/>%)
                                                    </span>
                                                </div>
                                            </div>
                                        </div>
                                        <div class="donut-legend-item">
                                            <div class="donut-legend-dot donut-legend-dot--vencidos"></div>
                                            <div class="donut-legend-info">
                                                <p class="donut-legend-nombre">Vencidos</p>
                                                <div class="donut-legend-val">
                                                    <span class="donut-legend-num">
                                                        <c:out value="${contratosVencidos}"/>
                                                    </span>
                                                    <span class="donut-legend-pct">
                                                        (<c:out value="${pctVencidos}"/>%)
                                                    </span>
                                                </div>
                                            </div>
                                        </div>
                                        <div class="donut-legend-item">
                                            <div class="donut-legend-dot donut-legend-dot--cancelados"></div>
                                            <div class="donut-legend-info">
                                                <p class="donut-legend-nombre">Cancelados</p>
                                                <div class="donut-legend-val">
                                                    <span class="donut-legend-num">
                                                        <c:out value="${contratosCancelados}"/>
                                                    </span>
                                                    <span class="donut-legend-pct">
                                                        (<c:out value="${pctCancelados}"/>%)
                                                    </span>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <%-- Barras de porcentaje --%>
                                <div class="pct-bar-list" style="border-top:1px solid var(--clr-border-light);">
                                    <%-- Activos --%>
                                    <div class="pct-bar-item">
                                        <div class="pct-bar-item__header">
                                            <span class="pct-bar-item__label">
                                                <span class="pct-bar-item__dot" style="background:var(--clr-success);"></span>
                                                Contratos activos
                                            </span>
                                            <span class="pct-bar-item__val">
                                                <c:out value="${contratosActivos}"/> / <c:out value="${contratosTotal}"/>
                                            </span>
                                        </div>
                                        <div class="pct-bar-bg">
                                            <div class="pct-bar-fill"
                                                 style="width:<c:out value='${pctActivos}'/>%;
                                                        background:var(--clr-success);">
                                            </div>
                                        </div>
                                    </div>
                                    <%-- Vencidos --%>
                                    <div class="pct-bar-item">
                                        <div class="pct-bar-item__header">
                                            <span class="pct-bar-item__label">
                                                <span class="pct-bar-item__dot" style="background:var(--clr-red);"></span>
                                                Contratos vencidos
                                            </span>
                                            <span class="pct-bar-item__val">
                                                <c:out value="${contratosVencidos}"/> / <c:out value="${contratosTotal}"/>
                                            </span>
                                        </div>
                                        <div class="pct-bar-bg">
                                            <div class="pct-bar-fill"
                                                 style="width:<c:out value='${pctVencidos}'/>%;
                                                        background:var(--clr-red);">
                                            </div>
                                        </div>
                                    </div>
                                    <%-- Cancelados --%>
                                    <div class="pct-bar-item">
                                        <div class="pct-bar-item__header">
                                            <span class="pct-bar-item__label">
                                                <span class="pct-bar-item__dot" style="background:var(--clr-text-dim);"></span>
                                                Cancelados
                                            </span>
                                            <span class="pct-bar-item__val">
                                                <c:out value="${contratosCancelados}"/> / <c:out value="${contratosTotal}"/>
                                            </span>
                                        </div>
                                        <div class="pct-bar-bg">
                                            <div class="pct-bar-fill"
                                                 style="width:<c:out value='${pctCancelados}'/>%;
                                                        background:var(--clr-text-dim);">
                                            </div>
                                        </div>
                                    </div>
                                </div>

                            </c:if>

                            <c:if test="${contratosTotal eq 0}">
                                <div class="report-empty">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125
                                                 1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0
                                                 0-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5
                                                 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0
                                                 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504
                                                 1.125-1.125V11.25a9 9 0 0 0-9-9Z"/>
                                    </svg>
                                    <p>Sin contratos registrados aún.</p>
                                </div>
                            </c:if>
                        </div>

                        <%-- Columna derecha: ingresos + próximos vencer --%>
                        <div style="display:flex; flex-direction:column; gap:1rem;">

                            <%-- Ingresos del mes --%>
                            <div class="ingresos-highlight">
                                <div class="ingresos-highlight__icon">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.7">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M2.25 18.75a60.07 60.07 0 0 1 15.797 2.101c.727.198
                                                 1.453-.342 1.453-1.096V18.75M3.75 4.5v.75A.75.75 0 0
                                                 1 3 6h-.75m0 0v-.375c0-.621.504-1.125 1.125-1.125H20.25M2.25
                                                 6v9m18-10.5v.75c0 .414.336.75.75.75h.75m-1.5-1.5h.375c.621
                                                 0 1.125.504 1.125 1.125v9.75c0 .621-.504 1.125-1.125
                                                 1.125h-.375m1.5-1.5H21a.75.75 0 0 0-.75.75v.75m0
                                                 0H3.75m0 0h-.375a1.125 1.125 0 0
                                                 1-1.125-1.125V15m1.5 1.5v-.75A.75.75 0 0 0 3 15h-.75"/>
                                    </svg>
                                </div>
                                <div class="ingresos-highlight__info">
                                    <p class="ingresos-highlight__label">Ingresos del mes actual</p>
                                    <p class="ingresos-highlight__amount">
                                        <fmt:formatNumber value="${ingresosMes}" pattern="#,##0.00"/>
                                    </p>
                                    <p class="ingresos-highlight__meta">
                                        Suma de <strong>monto_pagado</strong> en contratos del mes
                                    </p>
                                </div>
                            </div>

                            <%-- Próximos a vencer --%>
                            <div class="report-card">
                                <div class="report-card__header">
                                    <div class="report-card__header-left">
                                        <div class="report-card__icon yellow-icon">
                                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                <path stroke-linecap="round" stroke-linejoin="round"
                                                      d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73
                                                         0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898
                                                         0L2.697 16.126ZM12 15.75h.007v.008H12v-.008Z"/>
                                            </svg>
                                        </div>
                                        <span class="report-card__title">Próximos a vencer</span>
                                    </div>
                                    <c:if test="${countProximosVencer > 0}">
                                        <span class="stat-chip chip--yellow">
                                            <c:out value="${countProximosVencer}"/>
                                        </span>
                                    </c:if>
                                </div>

                                <c:choose>
                                    <c:when test="${not empty proximosVencer}">
                                        <c:forEach var="con" items="${proximosVencer}">
                                            <div class="vence-row">
                                                <div class="vence-row__avatar
                                                     ${con.proximoAVencer(3) ? 'urgent' : ''}">
                                                    <c:out value="${fn:substring(con.cliente.nombre, 0, 1)}"/>
                                                </div>
                                                <div class="vence-row__info">
                                                    <p class="vence-row__nombre">
                                                        <c:out value="${con.cliente.nombreCompleto}"/>
                                                    </p>
                                                    <p class="vence-row__membresia">
                                                        <c:out value="${con.membresia.nombreMembresia}"/>
                                                    </p>
                                                </div>
                                                <span class="vence-row__fecha ${con.proximoAVencer(3) ? 'urgente' : ''}">
                                                    <c:out value="${con.fechaFin}"/>
                                                </span>
                                            </div>
                                        </c:forEach>
                                        <div style="padding:0.65rem 1.25rem; border-top:1px solid var(--clr-border-light);
                                                    background:rgba(255,255,255,0.012);
                                                    font-size:0.73rem; color:var(--clr-text-dim);">
                                            Contratos que vencen en los próximos 7 días
                                        </div>
                                    </c:when>
                                    <c:otherwise>
                                        <div class="report-empty">
                                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                                                <path stroke-linecap="round" stroke-linejoin="round"
                                                      d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                            </svg>
                                            <p>Sin contratos próximos a vencer.<br>Todo en orden.</p>
                                        </div>
                                    </c:otherwise>
                                </c:choose>
                            </div>

                        </div><%-- /aside columna derecha --%>
                    </div><%-- /report-two-col --%>

                </c:when>

                <%-- ──────────────────────────────────────────
                     VISTA: REPORTE DE ASISTENCIA
                     ?action=asistencia
                     ────────────────────────────────────────── --%>
                <c:when test="${vistaActiva eq 'asistencia'}">

                    <%-- KPI principal --%>
                    <div class="report-kpi-grid" style="grid-template-columns: repeat(3, 1fr);">

                        <div class="report-kpi-card c--green">
                            <div class="report-kpi-card__header">
                                <span class="report-kpi-card__label">Atendidos hoy</span>
                                <div class="report-kpi-card__badge">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                    </svg>
                                </div>
                            </div>
                            <div class="report-kpi-card__value">
                                <c:out value="${atendidosHoy}"/>
                            </div>
                            <div class="report-kpi-card__meta">Check-ins del día actual</div>
                        </div>

                        <div class="report-kpi-card c--blue">
                            <div class="report-kpi-card__header">
                                <span class="report-kpi-card__label">Registros en historial</span>
                                <div class="report-kpi-card__badge">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M3.75 12h16.5m-16.5 3.75h16.5M3.75 19.5h16.5M5.625
                                                 4.5h12.75a1.875 1.875 0 0 1 0 3.75H5.625a1.875 1.875
                                                 0 0 1 0-3.75Z"/>
                                    </svg>
                                </div>
                            </div>
                            <div class="report-kpi-card__value">
                                <c:out value="${totalHistorial}"/>
                            </div>
                            <div class="report-kpi-card__meta">
                                Mostrando últimos <c:out value="${maxAsistencias}"/>
                            </div>
                        </div>

                        <div class="report-kpi-card c--red">
                            <div class="report-kpi-card__header">
                                <span class="report-kpi-card__label">Más reciente</span>
                                <div class="report-kpi-card__badge">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                    </svg>
                                </div>
                            </div>
                            <div class="report-kpi-card__value" style="font-size:1.1rem; padding-top:0.1rem;">
                                <c:choose>
                                    <c:when test="${not empty historialAsistencia}">
                                        <c:out value="${historialAsistencia[0].fecha}"/>
                                    </c:when>
                                    <c:otherwise>—</c:otherwise>
                                </c:choose>
                            </div>
                            <div class="report-kpi-card__meta">Fecha del último registro</div>
                        </div>

                    </div>

                    <%-- Tabla de historial --%>
                    <div class="report-card">
                        <div class="report-card__header">
                            <div class="report-card__header-left">
                                <div class="report-card__icon green-icon">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                    </svg>
                                </div>
                                <span class="report-card__title">Historial de asistencias</span>
                            </div>
                            <div style="display:flex; align-items:center; gap:0.65rem;">
                                <span class="stat-chip chip--green">
                                    <c:out value="${totalHistorial}"/> registros
                                </span>
                                <a href="${pageContext.request.contextPath}/attendance?action=hist"
                                   class="btn btn-ghost btn-sm">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M13.5 4.5 21 12m0 0-7.5 7.5M21 12H3"/>
                                    </svg>
                                    Módulo asistencia
                                </a>
                            </div>
                        </div>

                        <%-- Cabecera de columnas --%>
                        <div style="display:flex; align-items:center; gap:0.85rem;
                                    padding:0.5rem 1.25rem;
                                    background:var(--clr-surface);
                                    border-bottom:1px solid var(--clr-border-light);">
                            <span style="width:24px; flex-shrink:0;"></span>
                            <span style="width:8px; flex-shrink:0;"></span>
                            <span style="flex:1; font-size:0.65rem; font-weight:700;
                                         letter-spacing:0.10em; text-transform:uppercase;
                                         color:var(--clr-text-dim);">
                                Cliente
                            </span>
                            <span style="font-size:0.65rem; font-weight:700;
                                         letter-spacing:0.10em; text-transform:uppercase;
                                         color:var(--clr-text-dim); flex-shrink:0; max-width:130px; width:130px;">
                                Membresía
                            </span>
                            <span style="font-size:0.65rem; font-weight:700;
                                         letter-spacing:0.10em; text-transform:uppercase;
                                         color:var(--clr-text-dim); flex-shrink:0; min-width:86px;">
                                Fecha
                            </span>
                            <span style="font-size:0.65rem; font-weight:700;
                                         letter-spacing:0.10em; text-transform:uppercase;
                                         color:var(--clr-text-dim); flex-shrink:0;">
                                Hora
                            </span>
                            <span style="font-size:0.65rem; font-weight:700;
                                         letter-spacing:0.10em; text-transform:uppercase;
                                         color:var(--clr-text-dim); flex-shrink:0; min-width:72px; text-align:center;">
                                Estado
                            </span>
                        </div>

                        <c:choose>
                            <c:when test="${not empty historialAsistencia}">
                                <c:forEach var="asi" items="${historialAsistencia}" varStatus="loop">
                                    <div class="attendance-row">
                                        <span class="attendance-row__num">
                                            <c:out value="${loop.index + 1}"/>
                                        </span>
                                        <span class="attendance-row__dot
                                            ${asi.isFalto() ? 'falto' : ''}
                                            ${asi.isPendiente() ? 'pendiente' : ''}">
                                        </span>
                                        <span class="attendance-row__nombre">
                                            <c:out value="${asi.contrato.cliente.nombreCompleto}"/>
                                        </span>
                                        <span class="attendance-row__membresia">
                                            <c:if test="${asi.contrato != null and asi.contrato.membresia != null}">
                                                <c:out value="${asi.contrato.membresia.nombreMembresia}"/>
                                            </c:if>
                                        </span>
                                        <span class="attendance-row__fecha">
                                            <c:out value="${asi.fecha}"/>
                                        </span>
                                        <span class="attendance-row__hora">
                                            <c:out value="${asi.horaIngresoFormateada}"/>
                                        </span>
                                        <span style="flex-shrink:0; min-width:72px; text-align:center;">
                                            <span class="badge-estado badge-estado--${asi.estado}">
                                                <c:out value="${asi.estado}"/>
                                            </span>
                                        </span>
                                    </div>
                                </c:forEach>

                                <div style="display:flex; align-items:center; justify-content:space-between;
                                            padding:0.75rem 1.25rem; border-top:1px solid var(--clr-border-light);
                                            background:rgba(255,255,255,0.012);">
                                    <span style="font-size:0.75rem; color:var(--clr-text-dim);">
                                        Mostrando los últimos
                                        <strong style="color:var(--clr-text-muted);">
                                            <c:out value="${maxAsistencias}"/>
                                        </strong>
                                        registros de asistencia
                                    </span>
                                    <a href="${pageContext.request.contextPath}/attendance?action=hist"
                                       class="btn btn-secondary btn-sm">
                                        Ver historial completo
                                    </a>
                                </div>
                            </c:when>

                            <c:otherwise>
                                <div class="report-empty">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                    </svg>
                                    <p>No hay registros de asistencia todavía.</p>
                                </div>
                            </c:otherwise>
                        </c:choose>
                    </div><%-- /report-card --%>

                </c:when>

                <%-- ──────────────────────────────────────────
                     VISTA: REPORTE DE MEMBRESÍAS
                     ?action=membresias
                     ────────────────────────────────────────── --%>
                <c:when test="${vistaActiva eq 'membresias'}">

                    <%-- KPIs --%>
                    <div class="report-kpi-grid" style="grid-template-columns: repeat(3, 1fr);">

                        <div class="report-kpi-card c--red">
                            <div class="report-kpi-card__header">
                                <span class="report-kpi-card__label">Planes disponibles</span>
                                <div class="report-kpi-card__badge">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M2.25 8.25h19.5M2.25 9h19.5m-16.5 5.25h6m-6 2.25h3m-3.75 3h15a2.25
                                                 2.25 0 0 0 2.25-2.25V6.75A2.25 2.25 0 0 0 19.5 4.5h-15a2.25 2.25
                                                 0 0 0-2.25 2.25v10.5A2.25 2.25 0 0 0 4.5 19.5Z"/>
                                    </svg>
                                </div>
                            </div>
                            <div class="report-kpi-card__value">
                                <c:out value="${totalPlanes}"/>
                            </div>
                            <div class="report-kpi-card__meta">Planes en catálogo</div>
                        </div>

                        <div class="report-kpi-card c--green">
                            <div class="report-kpi-card__header">
                                <span class="report-kpi-card__label">Contratos activos</span>
                                <div class="report-kpi-card__badge">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                    </svg>
                                </div>
                            </div>
                            <div class="report-kpi-card__value">
                                <c:out value="${totalContratosActivos}"/>
                            </div>
                            <div class="report-kpi-card__meta">Membresías vigentes ahora</div>
                        </div>

                        <div class="report-kpi-card c--teal">
                            <div class="report-kpi-card__header">
                                <span class="report-kpi-card__label">Promedio por plan</span>
                                <div class="report-kpi-card__badge">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504
                                                 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125
                                                 1.125 0 0 1 3 19.875v-6.75Z"/>
                                    </svg>
                                </div>
                            </div>
                            <div class="report-kpi-card__value" style="font-size:1.3rem; padding-top:0.1rem;">
                                <c:choose>
                                    <c:when test="${totalPlanes > 0}">
                                        <fmt:formatNumber
                                            value="${totalContratosActivos / totalPlanes}"
                                            pattern="#.0"/>
                                    </c:when>
                                    <c:otherwise>0</c:otherwise>
                                </c:choose>
                            </div>
                            <div class="report-kpi-card__meta">Contratos / plan (promedio)</div>
                        </div>

                    </div>

                    <%-- Layout: planes + contratos activos --%>
                    <div class="report-two-col--wide report-two-col">

                        <%-- Lista de planes --%>
                        <div class="report-card">
                            <div class="report-card__header">
                                <div class="report-card__header-left">
                                    <div class="report-card__icon">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M2.25 8.25h19.5M2.25 9h19.5m-16.5 5.25h6m-6 2.25h3m-3.75 3h15a2.25
                                                     2.25 0 0 0 2.25-2.25V6.75A2.25 2.25 0 0 0 19.5 4.5h-15a2.25 2.25 0 0
                                                     0-2.25 2.25v10.5A2.25 2.25 0 0 0 4.5 19.5Z"/>
                                        </svg>
                                    </div>
                                    <span class="report-card__title">Planes de membresía</span>
                                </div>
                                <span class="stat-chip">
                                    <c:out value="${totalPlanes}"/> planes
                                </span>
                            </div>

                            <c:choose>
                                <c:when test="${not empty membresias}">
                                    <div class="membresia-report-list">
                                        <c:forEach var="mem" items="${membresias}" varStatus="loop">
                                            <div class="membresia-report-row">
                                                <span class="membresia-report-row__rank">
                                                    <c:out value="${loop.index + 1}"/>
                                                </span>
                                                <div class="membresia-report-row__info">
                                                    <p class="membresia-report-row__nombre">
                                                        <c:out value="${mem.nombreMembresia}"/>
                                                    </p>
                                                    <p class="membresia-report-row__dur">
                                                        <c:out value="${mem.duracionMeses}"/>
                                                        mes(es) ·
                                                        <span class="cell-id"><c:out value="${mem.id}"/></span>
                                                    </p>
                                                </div>
                                                <span class="membresia-report-row__precio">
                                                    <fmt:formatNumber value="${mem.precio}" pattern="#,##0.00"/>
                                                </span>
                                            </div>
                                        </c:forEach>
                                    </div>
                                    <div style="padding:0.65rem 1.25rem; border-top:1px solid var(--clr-border-light);
                                                background:rgba(255,255,255,0.012); display:flex; justify-content:flex-end;">
                                        <a href="${pageContext.request.contextPath}/memberships"
                                           class="btn btn-ghost btn-sm">
                                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                <path stroke-linecap="round" stroke-linejoin="round"
                                                      d="M13.5 4.5 21 12m0 0-7.5 7.5M21 12H3"/>
                                            </svg>
                                            Gestionar membresías
                                        </a>
                                    </div>
                                </c:when>
                                <c:otherwise>
                                    <div class="report-empty">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M2.25 8.25h19.5M2.25 9h19.5m-16.5 5.25h6m-6 2.25h3m-3.75 3h15a2.25
                                                     2.25 0 0 0 2.25-2.25V6.75A2.25 2.25 0 0 0 19.5 4.5h-15a2.25 2.25 0 0
                                                     0-2.25 2.25v10.5A2.25 2.25 0 0 0 4.5 19.5Z"/>
                                        </svg>
                                        <p>No hay planes de membresía registrados.</p>
                                    </div>
                                </c:otherwise>
                            </c:choose>
                        </div>

                        <%-- Contratos activos (resumen) --%>
                        <div class="report-card">
                            <div class="report-card__header">
                                <div class="report-card__header-left">
                                    <div class="report-card__icon green-icon">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                        </svg>
                                    </div>
                                    <span class="report-card__title">Contratos activos</span>
                                </div>
                                <span class="stat-chip chip--green">
                                    <c:out value="${totalContratosActivos}"/>
                                </span>
                            </div>

                            <c:choose>
                                <c:when test="${not empty contratosActivos}">
                                    <%-- Mostrar máximo 15 --%>
                                    <c:forEach var="con" items="${contratosActivos}" end="14">
                                        <div class="contrato-compact-row">
                                            <div class="contrato-compact-row__avatar">
                                                <c:out value="${fn:substring(con.cliente.nombre, 0, 1)}"/>
                                            </div>
                                            <span class="contrato-compact-row__nombre">
                                                <c:out value="${con.cliente.nombreCompleto}"/>
                                            </span>
                                            <span class="contrato-compact-row__plan">
                                                <c:out value="${con.membresia.nombreMembresia}"/>
                                            </span>
                                            <span class="contrato-compact-row__vence">
                                                <c:out value="${con.fechaFin}"/>
                                            </span>
                                        </div>
                                    </c:forEach>

                                    <div style="padding:0.65rem 1.25rem; border-top:1px solid var(--clr-border-light);
                                                background:rgba(255,255,255,0.012);
                                                display:flex; align-items:center; justify-content:space-between;">
                                        <span style="font-size:0.72rem; color:var(--clr-text-dim);">
                                            <c:choose>
                                                <c:when test="${totalContratosActivos > 15}">
                                                    Mostrando 15 de <strong style="color:var(--clr-text-muted);">
                                                        <c:out value="${totalContratosActivos}"/>
                                                    </strong>
                                                </c:when>
                                                <c:otherwise>
                                                    <strong style="color:var(--clr-text-muted);">
                                                        <c:out value="${totalContratosActivos}"/>
                                                    </strong> contratos activos
                                                </c:otherwise>
                                            </c:choose>
                                        </span>
                                        <a href="${pageContext.request.contextPath}/contracts"
                                           class="btn btn-ghost btn-sm">Ver todos</a>
                                    </div>
                                </c:when>
                                <c:otherwise>
                                    <div class="report-empty">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125
                                                     1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0
                                                     0-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5
                                                     2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0
                                                     .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504
                                                     1.125-1.125V11.25a9 9 0 0 0-9-9Z"/>
                                        </svg>
                                        <p>Sin contratos activos en este momento.</p>
                                    </div>
                                </c:otherwise>
                            </c:choose>
                        </div>

                    </div><%-- /report-two-col --%>

                </c:when>

                <%-- ──────────────────────────────────────────
                     VISTA: REPORTE RESUMEN (default)
                     vistaActiva = "resumen"
                     ────────────────────────────────────────── --%>
                <c:otherwise>

                    <%-- KPIs globales: 6 métricas principales --%>
                    <div class="report-kpi-grid">

                        <%-- Total clientes --%>
                        <div class="report-kpi-card c--blue">
                            <div class="report-kpi-card__header">
                                <span class="report-kpi-card__label">Clientes</span>
                                <div class="report-kpi-card__badge">
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
                                </div>
                            </div>
                            <div class="report-kpi-card__value">
                                <c:out value="${totalClientes}"/>
                            </div>
                            <div class="report-kpi-card__meta">Registrados en el sistema</div>
                        </div>

                        <%-- Contratos activos --%>
                        <div class="report-kpi-card c--green">
                            <div class="report-kpi-card__header">
                                <span class="report-kpi-card__label">Contratos activos</span>
                                <div class="report-kpi-card__badge">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                    </svg>
                                </div>
                            </div>
                            <div class="report-kpi-card__value">
                                <c:out value="${contratosActivos}"/>
                            </div>
                            <div class="report-kpi-card__meta">Membresías vigentes</div>
                        </div>

                        <%-- Atendidos hoy --%>
                        <div class="report-kpi-card c--red">
                            <div class="report-kpi-card__header">
                                <span class="report-kpi-card__label">Atendidos hoy</span>
                                <div class="report-kpi-card__badge">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25
                                                 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0
                                                 0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5"/>
                                    </svg>
                                </div>
                            </div>
                            <div class="report-kpi-card__value">
                                <c:out value="${atendidosHoy}"/>
                            </div>
                            <div class="report-kpi-card__meta">Check-ins del día</div>
                        </div>

                        <%-- Total empleados --%>
                        <div class="report-kpi-card c--purple">
                            <div class="report-kpi-card__header">
                                <span class="report-kpi-card__label">Empleados</span>
                                <div class="report-kpi-card__badge">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
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
                            <div class="report-kpi-card__value">
                                <c:out value="${totalEmpleados}"/>
                            </div>
                            <div class="report-kpi-card__meta">Staff registrado</div>
                        </div>

                        <%-- Clases vigentes --%>
                        <div class="report-kpi-card c--teal">
                            <div class="report-kpi-card__header">
                                <span class="report-kpi-card__label">Clases activas</span>
                                <div class="report-kpi-card__badge">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z"/>
                                    </svg>
                                </div>
                            </div>
                            <div class="report-kpi-card__value">
                                <c:out value="${clasesVigentes}"/>
                            </div>
                            <div class="report-kpi-card__meta">En programa</div>
                        </div>

                        <%-- Ingresos del mes --%>
                        <div class="report-kpi-card c--red" style="border-color:rgba(230,48,39,0.15);">
                            <div class="report-kpi-card__header">
                                <span class="report-kpi-card__label">Ingresos del mes</span>
                                <div class="report-kpi-card__badge">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M2.25 18.75a60.07 60.07 0 0 1 15.797 2.101c.727.198
                                                 1.453-.342 1.453-1.096V18.75M3.75 4.5v.75A.75.75 0 0
                                                 1 3 6h-.75m0 0v-.375c0-.621.504-1.125 1.125-1.125H20.25M2.25
                                                 6v9m18-10.5v.75c0 .414.336.75.75.75h.75"/>
                                    </svg>
                                </div>
                            </div>
                            <div class="report-kpi-card__value is-money">
                                <fmt:formatNumber value="${ingresosMes}" pattern="#,##0.00"/>
                            </div>
                            <div class="report-kpi-card__meta">Facturado este mes</div>
                        </div>

                    </div><%-- /report-kpi-grid --%>

                    <%-- Layout: actividad reciente + próximos a vencer --%>
                    <div class="report-two-col">

                        <%-- Actividad reciente --%>
                        <div class="report-card">
                            <div class="report-card__header">
                                <div class="report-card__header-left">
                                    <div class="report-card__icon green-icon">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                        </svg>
                                    </div>
                                    <span class="report-card__title">Actividad reciente</span>
                                </div>
                                <div style="display:flex; align-items:center; gap:0.65rem;">
                                    <span class="stat-chip chip--green">
                                        <c:out value="${atendidosHoy}"/> hoy
                                    </span>
                                    <a href="${pageContext.request.contextPath}/attendance?action=hist"
                                       class="btn btn-ghost btn-sm">
                                        Ver historial
                                    </a>
                                </div>
                            </div>

                            <c:choose>
                                <c:when test="${not empty asistenciasRecientes}">
                                    <c:forEach var="asi" items="${asistenciasRecientes}" varStatus="loop">
                                        <div class="attendance-row">
                                            <span class="attendance-row__num">
                                                <c:out value="${loop.index + 1}"/>
                                            </span>
                                            <span class="attendance-row__dot
                                                ${asi.isFalto() ? 'falto' : ''}
                                                ${asi.isPendiente() ? 'pendiente' : ''}">
                                            </span>
                                            <span class="attendance-row__nombre">
                                                <c:out value="${asi.contrato.cliente.nombreCompleto}"/>
                                            </span>
                                            <span class="attendance-row__membresia">
                                                <c:if test="${asi.contrato != null and asi.contrato.membresia != null}">
                                                    <c:out value="${asi.contrato.membresia.nombreMembresia}"/>
                                                </c:if>
                                            </span>
                                            <span class="attendance-row__fecha">
                                                <c:out value="${asi.fecha}"/>
                                            </span>
                                            <span class="attendance-row__hora">
                                                <c:out value="${asi.horaIngresoFormateada}"/>
                                            </span>
                                        </div>
                                    </c:forEach>

                                    <div style="padding:0.65rem 1.25rem; border-top:1px solid var(--clr-border-light);
                                                background:rgba(255,255,255,0.012);
                                                display:flex; align-items:center; justify-content:space-between;">
                                        <span style="font-size:0.73rem; color:var(--clr-text-dim);">
                                            Últimas <strong style="color:var(--clr-text-muted);">
                                                <c:out value="${fn:length(asistenciasRecientes)}"/>
                                            </strong> asistencias
                                        </span>
                                        <a href="${pageContext.request.contextPath}/reports?action=asistencia"
                                           class="btn btn-ghost btn-sm">
                                            Reporte completo
                                        </a>
                                    </div>
                                </c:when>
                                <c:otherwise>
                                    <div class="report-empty">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                        </svg>
                                        <p>Sin asistencias registradas hoy.</p>
                                    </div>
                                </c:otherwise>
                            </c:choose>
                        </div>

                        <%-- Contratos próximos a vencer --%>
                        <div style="display:flex; flex-direction:column; gap:1rem;">

                            <%-- Highlight ingresos --%>
                            <div class="ingresos-highlight">
                                <div class="ingresos-highlight__icon">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.7">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                              d="M12 6v12m-3-2.818.879.659c1.171.879 3.07.879 4.242
                                                 0 1.172-.879 1.172-2.303 0-3.182C13.536
                                                 12.219 12.768 12 12 12c-.725 0-1.45-.22-2.003-.659-1.106-.879-1.106-2.303
                                                 0-3.182s2.9-.879 4.006 0l.415.33M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                    </svg>
                                </div>
                                <div class="ingresos-highlight__info">
                                    <p class="ingresos-highlight__label">Ingresos del mes</p>
                                    <p class="ingresos-highlight__amount">
                                        <fmt:formatNumber value="${ingresosMes}" pattern="#,##0.00"/>
                                    </p>
                                    <p class="ingresos-highlight__meta">
                                        <a href="${pageContext.request.contextPath}/reports?action=contratos"
                                           style="color:rgba(230,48,39,0.7); font-size:0.73rem;
                                                  text-decoration:none;">
                                            Ver reporte de contratos →
                                        </a>
                                    </p>
                                </div>
                            </div>

                            <%-- Próximos a vencer --%>
                            <div class="report-card">
                                <div class="report-card__header">
                                    <div class="report-card__header-left">
                                        <div class="report-card__icon yellow-icon">
                                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                <path stroke-linecap="round" stroke-linejoin="round"
                                                      d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73
                                                         0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898
                                                         0L2.697 16.126ZM12 15.75h.007v.008H12v-.008Z"/>
                                            </svg>
                                        </div>
                                        <span class="report-card__title">Próximos a vencer</span>
                                    </div>
                                    <c:if test="${countProximosVencer > 0}">
                                        <span class="stat-chip chip--yellow">
                                            <c:out value="${countProximosVencer}"/>
                                        </span>
                                    </c:if>
                                </div>

                                <c:choose>
                                    <c:when test="${not empty proximosVencer}">
                                        <c:forEach var="con" items="${proximosVencer}">
                                            <div class="vence-row">
                                                <div class="vence-row__avatar
                                                     ${con.proximoAVencer(3) ? 'urgent' : ''}">
                                                    <c:out value="${fn:substring(con.cliente.nombre, 0, 1)}"/>
                                                </div>
                                                <div class="vence-row__info">
                                                    <p class="vence-row__nombre">
                                                        <c:out value="${con.cliente.nombreCompleto}"/>
                                                    </p>
                                                    <p class="vence-row__membresia">
                                                        <c:out value="${con.membresia.nombreMembresia}"/>
                                                    </p>
                                                </div>
                                                <span class="vence-row__fecha ${con.proximoAVencer(3) ? 'urgente' : ''}">
                                                    <c:out value="${con.fechaFin}"/>
                                                </span>
                                            </div>
                                        </c:forEach>
                                        <div style="padding:0.65rem 1.25rem; border-top:1px solid var(--clr-border-light);
                                                    background:rgba(255,255,255,0.012);
                                                    display:flex; justify-content:flex-end;">
                                            <a href="${pageContext.request.contextPath}/contracts"
                                               class="btn btn-ghost btn-sm">Ver contratos</a>
                                        </div>
                                    </c:when>
                                    <c:otherwise>
                                        <div class="report-empty">
                                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                                                <path stroke-linecap="round" stroke-linejoin="round"
                                                      d="M9 12.75 11.25 15 15 9.75M21 12c0 1.268-.63 2.39-1.593
                                                         3.068a3.745 3.745 0 0 1-1.043 3.296 3.745 3.745 0 0
                                                         1-3.296 1.043A3.745 3.745 0 0 1 12 21c-1.268
                                                         0-2.39-.63-3.068-1.593a3.746 3.746 0 0 1-3.296-1.043
                                                         3.745 3.745 0 0 1-1.043-3.296A3.745 3.745 0 0 1 3 12c0-1.268.63-2.39
                                                         1.593-3.068a3.745 3.745 0 0 1 1.043-3.296 3.746 3.746
                                                         0 0 1 3.296-1.043A3.746 3.746 0 0 1 12 3c1.268 0
                                                         2.39.63 3.068 1.593a3.746 3.746 0 0 1 3.296
                                                         1.043 3.746 3.746 0 0 1 1.043 3.296A3.745 3.745
                                                         0 0 1 21 12Z"/>
                                            </svg>
                                            <p>Sin contratos próximos a vencer.</p>
                                        </div>
                                    </c:otherwise>
                                </c:choose>
                            </div>

                            <%-- Accesos rápidos a otros reportes --%>
                            <div class="report-card">
                                <div class="report-card__header">
                                    <div class="report-card__header-left">
                                        <div class="report-card__icon blue-icon">
                                            <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                 viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                                <path stroke-linecap="round" stroke-linejoin="round"
                                                      d="M13.5 4.5 21 12m0 0-7.5 7.5M21 12H3"/>
                                            </svg>
                                        </div>
                                        <span class="report-card__title">Accesos rápidos</span>
                                    </div>
                                </div>
                                <div style="padding:1rem 1.25rem; display:flex; flex-direction:column; gap:0.5rem;">
                                    <a href="${pageContext.request.contextPath}/reports?action=contratos"
                                       class="btn btn-secondary btn-sm" style="justify-content:flex-start;">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125
                                                     1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0
                                                     0-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5
                                                     2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0
                                                     .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504
                                                     1.125-1.125V11.25a9 9 0 0 0-9-9Z"/>
                                        </svg>
                                        Reporte de contratos
                                    </a>
                                    <a href="${pageContext.request.contextPath}/reports?action=asistencia"
                                       class="btn btn-secondary btn-sm" style="justify-content:flex-start;">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                                        </svg>
                                        Reporte de asistencia
                                    </a>
                                    <a href="${pageContext.request.contextPath}/reports?action=membresias"
                                       class="btn btn-secondary btn-sm" style="justify-content:flex-start;">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                             viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                  d="M2.25 8.25h19.5M2.25 9h19.5m-16.5 5.25h6m-6 2.25h3m-3.75 3h15a2.25 2.25
                                                     0 0 0 2.25-2.25V6.75A2.25 2.25 0 0 0 19.5 4.5h-15a2.25 2.25 0 0 0-2.25
                                                     2.25v10.5A2.25 2.25 0 0 0 4.5 19.5Z"/>
                                        </svg>
                                        Reporte de membresías
                                    </a>
                                </div>
                            </div>

                        </div><%-- /aside --%>
                    </div><%-- /report-two-col --%>

                </c:otherwise>
            </c:choose>

        </div><%-- /page-content --%>
    </div><%-- /app-main --%>
</div><%-- /app-shell --%>

</body>
</html>
