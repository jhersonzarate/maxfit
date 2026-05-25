<%-- ============================================================
     head-common.jsp  —  MaxFit Sistema de Gestión
     Fragmento <head> compartido por TODAS las vistas autenticadas.

     Uso en cada JSP de módulo:
       <%@ include file="/WEB-INF/views/includes/head-common.jsp" %>

     Parámetro esperado (atributo de request):
       pageTitle  (String, opcional) → título de la pestaña.
                  Si no se pasa, se usa "MaxFit".

     Carga:
       · Google Fonts (Barlow Condensed + DM Sans)
       · Bootstrap 5.3 grid/utilities (CDN)
       · styles.css global
       · El JSP que lo include puede añadir su propio CSS
         DESPUÉS con un segundo <link> si necesita estilos extra.
     ============================================================ --%>
<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="robots" content="noindex, nofollow">

<%-- Título dinámico: usa el atributo pageTitle del request o fallback --%>
<title>
    <c:choose>
        <c:when test="${not empty pageTitle}">
            <c:out value="${pageTitle}"/> — MaxFit
        </c:when>
        <c:otherwise>MaxFit</c:otherwise>
    </c:choose>
</title>

<%-- ── Favicon inline SVG (sin archivo externo) ────────────
     Logotipo "MF" en rojo sobre fondo oscuro, 32×32
     ──────────────────────────────────────────────────────── --%>
<link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'><rect width='32' height='32' rx='6' fill='%230d0d0d'/><text x='16' y='22' font-family='Arial Black,sans-serif' font-size='14' font-weight='900' text-anchor='middle' fill='%23e63027'>MF</text></svg>">

<%-- ── Google Fonts ──────────────────────────────────────── --%>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Barlow+Condensed:wght@600;700;800&family=DM+Sans:ital,opsz,wght@0,9..40,400;0,9..40,500;0,9..40,600;0,9..40,700;1,9..40,400&display=swap"
      rel="stylesheet">

<%-- ── Bootstrap 5.3 (solo grid + utilidades, SIN JS) ──────
     Lo usamos para .row .col-* y algunas utilidades de flex.
     NO importamos bootstrap.bundle.js — cero JavaScript.
     ──────────────────────────────────────────────────────── --%>
<link rel="stylesheet"
      href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css">

<%-- ── Estilos globales de la aplicación ───────────────────
     Contiene: variables CSS, layout shell, cards, tablas,
     badges, botones, forms, flash alerts, animaciones, etc.
     ──────────────────────────────────────────────────────── --%>
<link rel="stylesheet"
      href="${pageContext.request.contextPath}/static/css/styles.css">
