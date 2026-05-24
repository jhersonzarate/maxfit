<%-- =====================================================================
     MaxFit — navbar.jsp
     Barra superior del sistema interno.
     Requiere sesión activa (userId, userName, userRole en sessionScope).
     Incluir con: <%@ include file="/WEB-INF/views/includes/navbar.jsp" %>
     ===================================================================== --%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<nav class="mf-navbar">

  <%-- ── Botón hamburguesa (mobile) ───────────────────────────────────── --%>
  <button class="mf-navbar__btn d-lg-none me-2"
          id="sidebarToggle"
          type="button"
          aria-label="Abrir menú"
          onclick="toggleSidebar()">
    <i class="bi bi-list"></i>
  </button>

  <%-- ── Título de la página actual ──────────────────────────────────── --%>
  <div class="mf-navbar__title">
    <span id="navPageTitle">MaxFit</span>
    <span class="d-none d-md-inline"> — Sistema de Gestión</span>
  </div>

  <%-- ── Acciones derechas ────────────────────────────────────────────── --%>
  <div class="mf-navbar__actions">

    <%-- Chip de rol --%>
    <c:choose>
      <c:when test="${sessionScope.userRole == 'ROL-ADMIN'}">
        <span class="mf-role-chip mf-role-chip--admin d-none d-sm-inline-flex">
          <i class="bi bi-shield-fill"></i> Administrador
        </span>
      </c:when>
      <c:when test="${sessionScope.userRole == 'ROL-RECEP'}">
        <span class="mf-role-chip mf-role-chip--recep d-none d-sm-inline-flex">
          <i class="bi bi-person-badge-fill"></i> Recepcionista
        </span>
      </c:when>
      <c:when test="${sessionScope.userRole == 'ROL-TRAINER'}">
        <span class="mf-role-chip mf-role-chip--trainer d-none d-sm-inline-flex">
          <i class="bi bi-trophy-fill"></i> Instructor
        </span>
      </c:when>
    </c:choose>

    <%-- Dropdown de usuario --%>
    <div class="dropdown">
      <button class="mf-navbar__btn d-flex align-items-center gap-2"
              type="button"
              data-bs-toggle="dropdown"
              aria-expanded="false"
              style="width: auto; padding: 0 0.6rem; gap: 0.5rem;">
        <%-- Avatar con iniciales --%>
        <span style="
          width:28px; height:28px; border-radius:50%;
          background: var(--mf-red-subtle);
          border: 1.5px solid rgba(224,32,32,0.4);
          display:flex; align-items:center; justify-content:center;
          font-size:0.68rem; font-weight:700; color:var(--mf-red);
          text-transform:uppercase; flex-shrink:0;">
          <c:out value="${not empty sessionScope.userName ? sessionScope.userName.substring(0,1) : 'U'}"/>
        </span>
        <span class="d-none d-md-inline" style="
          font-size:0.82rem; font-weight:600;
          color:var(--mf-text-primary); max-width:120px;
          white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">
          <c:out value="${sessionScope.userName}"/>
        </span>
        <i class="bi bi-chevron-down" style="font-size:0.65rem; color:var(--mf-text-muted);"></i>
      </button>

      <ul class="dropdown-menu dropdown-menu-end">
        <%-- Info del usuario --%>
        <li>
          <div style="padding:0.6rem 0.85rem 0.5rem; border-bottom:1px solid var(--mf-border); margin-bottom:0.35rem;">
            <div style="font-size:0.84rem; font-weight:700; color:var(--mf-text-primary);">
              <c:out value="${sessionScope.userName}"/>
            </div>
            <div style="font-size:0.72rem; color:var(--mf-text-muted); margin-top:0.1rem;">
              <c:out value="${sessionScope.userEmail}"/>
            </div>
          </div>
        </li>

        <%-- Links según rol --%>
        <c:if test="${sessionScope.userRole == 'ROL-ADMIN'}">
          <li>
            <a class="dropdown-item" href="${pageContext.request.contextPath}/inicio">
              <i class="bi bi-speedometer2 me-2" style="color:var(--mf-red);"></i>Dashboard
            </a>
          </li>
          <li>
            <a class="dropdown-item" href="${pageContext.request.contextPath}/users">
              <i class="bi bi-people me-2" style="color:var(--mf-text-muted);"></i>Usuarios
            </a>
          </li>
        </c:if>
        <c:if test="${sessionScope.userRole == 'ROL-RECEP'}">
          <li>
            <a class="dropdown-item" href="${pageContext.request.contextPath}/dashboard">
              <i class="bi bi-speedometer2 me-2" style="color:var(--mf-red);"></i>Dashboard
            </a>
          </li>
        </c:if>
        <c:if test="${sessionScope.userRole == 'ROL-TRAINER'}">
          <li>
            <a class="dropdown-item" href="${pageContext.request.contextPath}/instructor">
              <i class="bi bi-speedometer2 me-2" style="color:var(--mf-red);"></i>Mi Panel
            </a>
          </li>
        </c:if>

        <li><hr class="dropdown-divider"></li>

        <%-- Cerrar sesión --%>
        <li>
          <a class="dropdown-item" href="${pageContext.request.contextPath}/logout"
             style="color:var(--mf-danger);"
             onclick="return confirm('¿Cerrar sesión?')">
            <i class="bi bi-box-arrow-right me-2"></i>Cerrar sesión
          </a>
        </li>
      </ul>
    </div>

  </div><%-- /actions --%>
</nav>

<%-- ── Overlay para cerrar sidebar en mobile ───────────────────────────── --%>
<div id="sidebarOverlay"
     onclick="toggleSidebar()"
     style="
       display:none; position:fixed; inset:0;
       background:rgba(0,0,0,0.65); z-index:999;
       backdrop-filter:blur(2px);"></div>

<script>
  function toggleSidebar() {
    const sidebar  = document.querySelector('.mf-sidebar');
    const overlay  = document.getElementById('sidebarOverlay');
    const isOpen   = sidebar.classList.contains('open');
    sidebar.classList.toggle('open', !isOpen);
    overlay.style.display = isOpen ? 'none' : 'block';
    document.body.style.overflow = isOpen ? '' : 'hidden';
  }
</script>
