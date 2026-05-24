<%-- =====================================================================
     MaxFit — sidebar.jsp
     Menú lateral fijo. Muestra links según sessionScope.userRole:
       ROL-ADMIN   → todo el menú
       ROL-RECEP   → clientes, contratos, asistencia, membresías, horarios
       ROL-TRAINER → solo horarios y calendario
     Incluir con: <%@ include file="/WEB-INF/views/includes/sidebar.jsp" %>
     ===================================================================== --%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<%-- URI actual para marcar el ítem activo --%>
<c:set var="uri" value="${pageContext.request.requestURI}"/>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>

<aside class="mf-sidebar" id="mainSidebar">

  <%-- ── Logo ──────────────────────────────────────────────────────────── --%>
  <a class="mf-sidebar__logo" href="${ctx}/">
    <div>
      <div class="mf-sidebar__logo-text">MAX<span class="accent">FIT</span></div>
      <span class="mf-sidebar__logo-sub">Sistema de Gestión</span>
    </div>
  </a>

  <%-- ══════════════════════════════════════════════════════════════════════
       ADMIN — acceso completo
  ══════════════════════════════════════════════════════════════════════ --%>
  <c:if test="${sessionScope.userRole == 'ROL-ADMIN'}">

    <div class="mf-sidebar__section">

      <%-- General --%>
      <div class="mf-sidebar__section-label">General</div>

      <a href="${ctx}/inicio"
         class="mf-nav-item ${uri.endsWith('/inicio') ? 'active' : ''}">
        <i class="bi bi-speedometer2"></i>
        Dashboard
      </a>

      <a href="${ctx}/reports"
         class="mf-nav-item ${uri.endsWith('/reports') ? 'active' : ''}">
        <i class="bi bi-bar-chart-line"></i>
        Reportes
      </a>

      <%-- Operaciones --%>
      <div class="mf-sidebar__section-label" style="margin-top:0.75rem;">Operaciones</div>

      <a href="${ctx}/clients"
         class="mf-nav-item ${uri.endsWith('/clients') ? 'active' : ''}">
        <i class="bi bi-people"></i>
        Clientes
      </a>

      <a href="${ctx}/contracts"
         class="mf-nav-item ${uri.endsWith('/contracts') ? 'active' : ''}">
        <i class="bi bi-file-earmark-text"></i>
        Contratos
      </a>

      <a href="${ctx}/memberships"
         class="mf-nav-item ${uri.endsWith('/memberships') ? 'active' : ''}">
        <i class="bi bi-credit-card"></i>
        Membresías
      </a>

      <a href="${ctx}/attendance"
         class="mf-nav-item ${uri.endsWith('/attendance') ? 'active' : ''}">
        <i class="bi bi-qr-code-scan"></i>
        Asistencia
      </a>

      <%-- Clases --%>
      <div class="mf-sidebar__section-label" style="margin-top:0.75rem;">Clases</div>

      <a href="${ctx}/schedules"
         class="mf-nav-item ${uri.endsWith('/schedules') ? 'active' : ''}">
        <i class="bi bi-grid-3x3-gap"></i>
        Clases
      </a>

      <a href="${ctx}/calendar"
         class="mf-nav-item ${uri.endsWith('/calendar') ? 'active' : ''}">
        <i class="bi bi-calendar3-week"></i>
        Calendario
      </a>

      <%-- Administración --%>
      <div class="mf-sidebar__section-label" style="margin-top:0.75rem;">Administración</div>

      <a href="${ctx}/employees"
         class="mf-nav-item ${uri.endsWith('/employees') ? 'active' : ''}">
        <i class="bi bi-person-vcard"></i>
        Empleados
      </a>

      <a href="${ctx}/users"
         class="mf-nav-item ${uri.endsWith('/users') ? 'active' : ''}">
        <i class="bi bi-person-lock"></i>
        Usuarios
      </a>

      <a href="${ctx}/payment-methods"
         class="mf-nav-item ${uri.endsWith('/payment-methods') ? 'active' : ''}">
        <i class="bi bi-wallet2"></i>
        Métodos de Pago
      </a>

    </div><%-- /section --%>
  </c:if>

  <%-- ══════════════════════════════════════════════════════════════════════
       RECEPCIONISTA — operaciones del día
  ══════════════════════════════════════════════════════════════════════ --%>
  <c:if test="${sessionScope.userRole == 'ROL-RECEP'}">

    <div class="mf-sidebar__section">

      <div class="mf-sidebar__section-label">Recepción</div>

      <a href="${ctx}/dashboard"
         class="mf-nav-item ${uri.endsWith('/dashboard') ? 'active' : ''}">
        <i class="bi bi-speedometer2"></i>
        Mi Panel
      </a>

      <a href="${ctx}/attendance"
         class="mf-nav-item ${uri.endsWith('/attendance') ? 'active' : ''}">
        <i class="bi bi-qr-code-scan"></i>
        Check-in
      </a>

      <div class="mf-sidebar__section-label" style="margin-top:0.75rem;">Gestión</div>

      <a href="${ctx}/clients"
         class="mf-nav-item ${uri.endsWith('/clients') ? 'active' : ''}">
        <i class="bi bi-people"></i>
        Clientes
      </a>

      <a href="${ctx}/contracts"
         class="mf-nav-item ${uri.endsWith('/contracts') ? 'active' : ''}">
        <i class="bi bi-file-earmark-text"></i>
        Contratos
      </a>

      <a href="${ctx}/memberships"
         class="mf-nav-item ${uri.endsWith('/memberships') ? 'active' : ''}">
        <i class="bi bi-credit-card"></i>
        Membresías
      </a>

      <div class="mf-sidebar__section-label" style="margin-top:0.75rem;">Clases</div>

      <a href="${ctx}/schedules"
         class="mf-nav-item ${uri.endsWith('/schedules') ? 'active' : ''}">
        <i class="bi bi-grid-3x3-gap"></i>
        Clases
      </a>

      <a href="${ctx}/calendar"
         class="mf-nav-item ${uri.endsWith('/calendar') ? 'active' : ''}">
        <i class="bi bi-calendar3-week"></i>
        Calendario
      </a>

    </div>
  </c:if>

  <%-- ══════════════════════════════════════════════════════════════════════
       INSTRUCTOR — solo sus clases y calendario
  ══════════════════════════════════════════════════════════════════════ --%>
  <c:if test="${sessionScope.userRole == 'ROL-TRAINER'}">

    <div class="mf-sidebar__section">

      <div class="mf-sidebar__section-label">Instructor</div>

      <a href="${ctx}/instructor"
         class="mf-nav-item ${uri.endsWith('/instructor') ? 'active' : ''}">
        <i class="bi bi-trophy"></i>
        Mi Panel
      </a>

      <a href="${ctx}/schedules"
         class="mf-nav-item ${uri.endsWith('/schedules') ? 'active' : ''}">
        <i class="bi bi-grid-3x3-gap"></i>
        Clases
      </a>

      <a href="${ctx}/calendar"
         class="mf-nav-item ${uri.endsWith('/calendar') ? 'active' : ''}">
        <i class="bi bi-calendar3-week"></i>
        Calendario
      </a>

    </div>
  </c:if>

  <%-- ── Usuario al fondo ────────────────────────────────────────────────── --%>
  <div class="mf-sidebar__user">

    <%-- Avatar con inicial --%>
    <div class="mf-sidebar__avatar">
      <c:out value="${not empty sessionScope.userName
                       ? sessionScope.userName.substring(0,1)
                       : 'U'}"/>
    </div>

    <%-- Info --%>
    <div class="mf-sidebar__user-info">
      <div class="mf-sidebar__user-name">
        <c:out value="${sessionScope.userName}"/>
      </div>
      <div class="mf-sidebar__user-role">
        <c:choose>
          <c:when test="${sessionScope.userRole == 'ROL-ADMIN'}">Admin</c:when>
          <c:when test="${sessionScope.userRole == 'ROL-RECEP'}">Recepción</c:when>
          <c:when test="${sessionScope.userRole == 'ROL-TRAINER'}">Instructor</c:when>
          <c:otherwise>Usuario</c:otherwise>
        </c:choose>
      </div>
    </div>

    <%-- Logout rápido --%>
    <a href="${ctx}/logout"
       class="mf-sidebar__logout"
       title="Cerrar sesión"
       onclick="return confirm('¿Cerrar sesión?')">
      <i class="bi bi-box-arrow-right"></i>
    </a>

  </div><%-- /user --%>

</aside>
