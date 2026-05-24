<%-- =====================================================================
     MaxFit — login.jsp
     Pantalla de inicio de sesión.
     Controller: LoginController  →  POST /login
     Atributos recibidos del controller:
       errorMsg       → mensaje de error (credenciales incorrectas)
       emailIngresado → email para repoblar el campo tras error
       msg            → "logout" | "password_reset" (params de URL)
     ===================================================================== --%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="es">
<head>
  <title>MaxFit — Iniciar sesión</title>
  <%@ include file="/WEB-INF/views/includes/head-common.jsp" %>
  <%-- CSS específico del login --%>
  <link rel="stylesheet"
        href="${pageContext.request.contextPath}/static/css/login.css">
</head>
<body>

<div class="login-wrapper">

  <%-- ════════════════════════════════════════════════════════════════════
       PANEL IZQUIERDO — Hero con imagen del gym
  ═════════════════════════════════════════════════════════════════════ --%>
  <div class="login-hero">
    <div class="login-hero__bg"></div>
    <div class="login-hero__overlay"></div>

    <div class="login-hero__content">
      <div class="login-hero__badge">
        <span class="login-hero__badge-dot"></span>
        Sistema activo
      </div>

      <h2 class="login-hero__manifesto" style="margin-top:1rem;">
        Disciplina<br>
        Fuerza<br>
        Constancia<br>
        <span>Resultados</span>
      </h2>
    </div>

    <footer class="login-hero__footer">
      &copy; 2025 MaxFit &mdash; Todos los derechos reservados.
    </footer>
  </div>

  <%-- ════════════════════════════════════════════════════════════════════
       PANEL DERECHO — Formulario de login
  ═════════════════════════════════════════════════════════════════════ --%>
  <div class="login-panel">

    <%-- Logo --%>
    <div class="login-logo fade-up">
      <div class="login-logo__wordmark">
        MAX<span class="accent">FIT</span>
      </div>
      <span class="login-logo__sub">Sistema de Gestión</span>
    </div>

    <%-- Heading --%>
    <div class="login-heading fade-up">
      <h1>Bienvenido de vuelta</h1>
      <p>Inicia sesión para continuar</p>
    </div>

    <%-- ── Alertas de sesión (logout / password reset) ─────────────── --%>
    <c:if test="${param.msg == 'logout'}">
      <div class="mf-alert mf-alert--info fade-up" role="alert">
        <i class="bi bi-check-circle-fill mf-alert-icon"></i>
        Sesión cerrada correctamente. ¡Hasta luego!
      </div>
    </c:if>

    <c:if test="${param.msg == 'password_reset'}">
      <div class="mf-alert mf-alert--success fade-up" role="alert">
        <i class="bi bi-shield-check mf-alert-icon"></i>
        Contraseña actualizada correctamente. Ya puedes iniciar sesión.
      </div>
    </c:if>

    <%-- ── Error de credenciales ──────────────────────────────────── --%>
    <c:if test="${not empty errorMsg}">
      <div class="mf-alert mf-alert--error fade-up" role="alert" id="loginError">
        <i class="bi bi-exclamation-triangle-fill mf-alert-icon"></i>
        <c:out value="${errorMsg}"/>
      </div>
    </c:if>

    <%-- ── Formulario ─────────────────────────────────────────────── --%>
    <form action="${pageContext.request.contextPath}/login"
          method="post"
          novalidate
          id="loginForm"
          autocomplete="on">

      <%-- Correo electrónico --%>
      <div class="mf-field fade-up">
        <label class="mf-field__label" for="email">
          Correo electrónico
        </label>
        <div class="mf-field__input-wrap">
          <i class="bi bi-envelope mf-field__icon"></i>
          <input type="email"
                 id="email"
                 name="email"
                 class="mf-input ${not empty errorMsg ? 'is-invalid' : ''}"
                 placeholder="ejemplo@maxfit.com"
                 value="<c:out value='${emailIngresado}'/>"
                 autocomplete="username"
                 required
                 autofocus>
        </div>
      </div>

      <%-- Contraseña --%>
      <div class="mf-field fade-up">
        <label class="mf-field__label" for="password">
          Contraseña
        </label>
        <div class="mf-field__input-wrap">
          <i class="bi bi-lock mf-field__icon"></i>
          <input type="password"
                 id="password"
                 name="password"
                 class="mf-input mf-input--password ${not empty errorMsg ? 'is-invalid' : ''}"
                 placeholder="Ingresa tu contraseña"
                 autocomplete="current-password"
                 required>
          <button type="button"
                  class="btn-toggle-pass"
                  id="togglePass"
                  aria-label="Mostrar contraseña"
                  title="Mostrar / ocultar contraseña">
            <i class="bi bi-eye" id="togglePassIcon"></i>
          </button>
        </div>
      </div>

      <%-- Recordarme + ¿Olvidaste tu contraseña? --%>
      <div class="mf-check-row fade-up">
        <label class="mf-check">
          <input type="checkbox"
                 name="remember"
                 class="mf-check__input"
                 id="remember">
          <span class="mf-check__label">Recordarme</span>
        </label>
        <a href="${pageContext.request.contextPath}/forgot-password"
           class="mf-forgot">
          ¿Olvidaste tu contraseña?
        </a>
      </div>

      <%-- Botón submit --%>
      <button type="submit"
              class="btn-mf-primary fade-up"
              id="loginBtn">
        <span id="btnText">Iniciar sesión</span>
        <i class="bi bi-arrow-right btn-arrow" id="btnArrow"></i>
      </button>

    </form>

    <%-- Footer del panel --%>
    <div class="login-panel__footer fade-up" style="margin-top:2rem;">
      &copy; 2025 MaxFit &mdash; Todos los derechos reservados.
    </div>

  </div><%-- /login-panel --%>
</div><%-- /login-wrapper --%>

<%-- ── Bootstrap JS (solo necesario para el toggle de password aquí) ── --%>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"
        integrity="sha384-YvpcrYf0tY3lHB60NNkmXc4s9bIOgUxi8T/jzmH5xFBFHCBcN+dB/lFrCB1Klwmr"
        crossorigin="anonymous" defer></script>

<script>
(function () {
  'use strict';

  /* ── Toggle show/hide password ────────────────────────────────────── */
  const toggleBtn  = document.getElementById('togglePass');
  const passInput  = document.getElementById('password');
  const toggleIcon = document.getElementById('togglePassIcon');

  if (toggleBtn && passInput) {
    toggleBtn.addEventListener('click', function () {
      const isHidden = passInput.type === 'password';
      passInput.type = isHidden ? 'text' : 'password';
      toggleIcon.className = isHidden ? 'bi bi-eye-slash' : 'bi bi-eye';
      toggleBtn.setAttribute('aria-label', isHidden ? 'Ocultar contraseña' : 'Mostrar contraseña');
    });
  }

  /* ── Estado loading en submit ─────────────────────────────────────── */
  const form    = document.getElementById('loginForm');
  const loginBtn = document.getElementById('loginBtn');
  const btnText = document.getElementById('btnText');
  const btnArrow = document.getElementById('btnArrow');

  if (form && loginBtn) {
    form.addEventListener('submit', function (e) {
      const email    = document.getElementById('email').value.trim();
      const password = passInput.value;

      /* Validación básica client-side */
      if (!email || !password) {
        e.preventDefault();
        shakeForm();
        return;
      }

      /* Mostrar estado loading */
      loginBtn.classList.add('loading');
      loginBtn.disabled = true;
      btnText.textContent = 'Verificando…';
      btnArrow.className  = 'btn-spinner';
    });
  }

  /* Shake animation si hay error ya renderizado */
  const errorBox = document.getElementById('loginError');
  if (errorBox) {
    shakeForm();
    /* Enfocar el campo email si tiene error */
    const emailField = document.getElementById('email');
    if (emailField && emailField.value) {
      passInput.focus();
    } else if (emailField) {
      emailField.focus();
    }
  }

  function shakeForm() {
    const panel = document.querySelector('.login-panel');
    if (!panel) return;
    panel.style.animation = 'none';
    panel.offsetHeight; /* reflow */
    panel.style.animation = 'loginShake 0.4s ease';
  }

  /* Auto-dismiss alertas de info/success después de 6s */
  document.querySelectorAll('.mf-alert--info, .mf-alert--success')
    .forEach(function (el) {
      setTimeout(function () {
        el.style.transition = 'opacity 0.5s ease, transform 0.5s ease';
        el.style.opacity    = '0';
        el.style.transform  = 'translateY(-6px)';
        setTimeout(function () { el.remove(); }, 500);
      }, 6000);
    });
})();
</script>

<%-- Keyframe de shake en línea (solo login) --%>
<style>
@keyframes loginShake {
  0%, 100% { transform: translateX(0); }
  15%       { transform: translateX(-6px); }
  45%       { transform: translateX(6px); }
  75%       { transform: translateX(-3px); }
}
</style>

</body>
</html>
