<%-- =====================================================================
     MaxFit — head-common.jsp
     Fragmento <head> compartido por TODOS los JSP del sistema interno.
     Incluir con: <%@ include file="/WEB-INF/views/includes/head-common.jsp" %>
     
     IMPORTANTE:
       - Bootstrap CSS  → CDN (NO en static/)
       - Bootstrap JS   → CDN, al final del <body> (no aquí)
       - Bootstrap Icons → CDN
       - Google Fonts   → CDN (Bebas Neue + DM Sans)
       - styles.css     → static/css/styles.css   (variables + layout)
       - dashboard.css  → static/css/dashboard.css (KPIs + widgets)
       El JSP específico añade su propio CSS si lo necesita (ej: login.css).
     ===================================================================== --%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="robots" content="noindex, nofollow">
<meta name="theme-color" content="#111111">

<%-- ── Google Fonts ─────────────────────────────────────────────────── --%>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Bebas+Neue&family=DM+Sans:ital,opsz,wght@0,9..40,300;0,9..40,400;0,9..40,500;0,9..40,600;0,9..40,700;0,9..40,800;1,9..40,400&family=JetBrains+Mono:wght@400;600&display=swap"
      rel="stylesheet">

<%-- ── Bootstrap 5.3 CSS (CDN) ────────────────────────────────────────── --%>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
      rel="stylesheet"
      integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH"
      crossorigin="anonymous">

<%-- ── Bootstrap Icons 1.11 (CDN) ─────────────────────────────────────── --%>
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css"
      rel="stylesheet">

<%-- ── CSS propios del sistema MaxFit ─────────────────────────────────── --%>
<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/styles.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/dashboard.css">

<%-- ── Favicon inline SVG (sin archivo extra) ─────────────────────────── --%>
<link rel="icon" type="image/svg+xml"
      href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'><rect width='32' height='32' rx='6' fill='%23111'/><text x='3' y='24' font-size='20' font-family='Impact,sans-serif' font-weight='bold' fill='%23e02020'>M</text></svg>">

<%-- ── Override Bootstrap para tema oscuro MaxFit ─────────────────────── --%>
<style>
  /* Sobreescrituras puntuales de Bootstrap para el tema dark MaxFit.
     NO poner lógica de componentes aquí; va en styles.css / dashboard.css */

  /* Bootstrap form controls → tema dark */
  .form-control,
  .form-select {
    background-color: var(--mf-bg-input) !important;
    border-color: var(--mf-border) !important;
    color: var(--mf-text-primary) !important;
    font-family: var(--mf-font-body);
  }
  .form-control:focus,
  .form-select:focus {
    background-color: #222 !important;
    border-color: var(--mf-red) !important;
    box-shadow: 0 0 0 3px var(--mf-red-glow) !important;
    color: var(--mf-text-primary) !important;
  }
  .form-control::placeholder { color: var(--mf-text-muted) !important; }
  .form-control.is-invalid   { border-color: var(--mf-danger) !important; }

  /* Dropdown Bootstrap → dark */
  .dropdown-menu {
    background-color: var(--mf-bg-card);
    border: 1px solid var(--mf-border);
    border-radius: var(--mf-radius-sm);
    box-shadow: var(--mf-shadow-lg);
    padding: 0.35rem;
  }
  .dropdown-item {
    color: var(--mf-text-secondary);
    border-radius: 6px;
    font-size: 0.84rem;
    padding: 0.5rem 0.85rem;
    transition: all var(--mf-transition);
    font-family: var(--mf-font-body);
  }
  .dropdown-item:hover, .dropdown-item:focus {
    background-color: rgba(255,255,255,0.05);
    color: var(--mf-text-primary);
  }
  .dropdown-divider { border-color: var(--mf-border); }

  /* Modal Bootstrap → dark */
  .modal-content {
    background: var(--mf-bg-card);
    border: 1px solid var(--mf-border);
    border-radius: var(--mf-radius-lg);
    color: var(--mf-text-primary);
  }
  .modal-header {
    border-bottom: 1px solid var(--mf-border);
    padding: 1.1rem 1.4rem;
  }
  .modal-title {
    font-size: 1rem;
    font-weight: 700;
    color: var(--mf-text-primary);
  }
  .modal-footer { border-top: 1px solid var(--mf-border); }
  .btn-close {
    filter: invert(1);
    opacity: 0.5;
  }
  .btn-close:hover { opacity: 1; }

  /* Tooltip Bootstrap → dark */
  .tooltip-inner {
    background: var(--mf-bg-card);
    color: var(--mf-text-primary);
    border: 1px solid var(--mf-border);
    font-family: var(--mf-font-body);
    font-size: 0.78rem;
    border-radius: 6px;
  }

  /* Table Bootstrap → dark (cuando se usa .table de Bootstrap) */
  .table {
    color: var(--mf-text-primary);
    border-color: var(--mf-border);
  }
  .table > :not(caption) > * > * {
    background-color: transparent;
    color: var(--mf-text-primary);
    border-color: var(--mf-border);
  }
  .table-hover > tbody > tr:hover > * {
    background-color: rgba(255,255,255,0.025);
    color: var(--mf-text-primary);
  }

  /* Pagination Bootstrap → dark */
  .pagination .page-link {
    background: var(--mf-bg-card);
    border-color: var(--mf-border);
    color: var(--mf-text-secondary);
    font-size: 0.84rem;
    transition: all var(--mf-transition);
  }
  .pagination .page-link:hover {
    background: var(--mf-bg-card-hover);
    color: var(--mf-text-primary);
    border-color: var(--mf-border-light);
  }
  .pagination .page-item.active .page-link {
    background: var(--mf-red);
    border-color: var(--mf-red);
    color: #fff;
  }
  .pagination .page-item.disabled .page-link {
    background: var(--mf-bg-surface);
    color: var(--mf-text-muted);
  }

  /* Badge Bootstrap sobreescrito por los .mf-badge */
  /* Spinner Bootstrap → color red */
  .spinner-border { color: var(--mf-red) !important; }

  /* Alert Bootstrap → usar .mf-alert en su lugar, pero por compatibilidad: */
  .alert {
    border-radius: var(--mf-radius-sm);
    font-family: var(--mf-font-body);
    font-size: 0.84rem;
    font-weight: 500;
  }
</style>
