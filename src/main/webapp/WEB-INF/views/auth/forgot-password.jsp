<%-- =====================================================================
     MaxFit — forgot-password.jsp
     Recuperación de contraseña — 3 pasos en una sola vista.
     Controller: ForgotPasswordController
       GET  /forgot-password          → Paso 1: ingresar email
       POST /forgot-password?action=buscar  → Paso 2: email verificado
       POST /forgot-password?action=reset   → Paso 3: nueva contraseña

     Atributos recibidos del controller:
       errorMsg       → error de validación
       infoMsg        → mensaje genérico del paso 2
       emailEncontrado (Boolean true) → habilita el form de nueva clave
       emailIngresado  → email verificado para pre-rellenar
     ===================================================================== --%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="es">
<head>
  <title>MaxFit — Recuperar contraseña</title>
  <%@ include file="/WEB-INF/views/includes/head-common.jsp" %>
  <link rel="stylesheet"
        href="${pageContext.request.contextPath}/static/css/login.css">
</head>
<body>

<div class="login-wrapper">

  <%-- ════════════════════════════════════════════════════════════════════
       PANEL IZQUIERDO — Hero
  ═════════════════════════════════════════════════════════════════════ --%>
  <div class="login-hero">
    <div class="login-hero__bg"></div>
    <div class="login-hero__overlay"></div>

    <div class="login-hero__content">
      <div class="login-hero__badge">
        <span class="login-hero__badge-dot"></span>
        Recuperación segura
      </div>

      <h2 class="login-hero__manifesto" style="margin-top:1rem;">
        Tu acceso<br>
        siempre<br>
        <span>protegido</span>
      </h2>
    </div>

    <footer class="login-hero__footer">
      &copy; 2025 MaxFit &mdash; Todos los derechos reservados.
    </footer>
  </div>

  <%-- ════════════════════════════════════════════════════════════════════
       PANEL DERECHO — Formulario
  ═════════════════════════════════════════════════════════════════════ --%>
  <div class="login-panel">

    <%-- Logo --%>
    <div class="login-logo fade-up">
      <div class="login-logo__wordmark">
        MAX<span class="accent">FIT</span>
      </div>
      <span class="login-logo__sub">Sistema de Gestión</span>
    </div>

    <%-- ── Indicador de pasos ──────────────────────────────────────── --%>
    <div class="mf-steps fade-up">
      <%-- Paso 1: siempre activo o completado --%>
      <div class="mf-step ${not empty emailEncontrado ? 'done' : 'active'}"></div>
      <%-- Paso 2: activo si hay emailEncontrado --%>
      <div class="mf-step ${not empty emailEncontrado ? 'active' : ''}"></div>
      <%-- Paso 3: no se alcanza (el reset hace redirect al login) --%>
      <div class="mf-step"></div>
    </div>

    <%-- ════════════════════════════════════════════════════════════════
         PASO 1 — Ingresar email
         Se muestra cuando NO hay emailEncontrado ni infoMsg
    ════════════════════════════════════════════════════════════════════ --%>
    <c:if test="${empty emailEncontrado && empty infoMsg}">

      <div class="login-heading fade-up">
        <h1>Recuperar acceso</h1>
        <p>Ingresa tu correo y verificaremos tu cuenta</p>
      </div>

      <%-- Error --%>
      <c:if test="${not empty errorMsg}">
        <div class="mf-alert mf-alert--error fade-up" role="alert">
          <i class="bi bi-exclamation-triangle-fill mf-alert-icon"></i>
          <c:out value="${errorMsg}"/>
        </div>
      </c:if>

      <%-- Alerta si llegó con cuenta inactiva --%>
      <c:if test="${param.err == 'cuenta_inactiva'}">
        <div class="mf-alert mf-alert--error fade-up" role="alert">
          <i class="bi bi-slash-circle mf-alert-icon"></i>
          Esta cuenta ha sido desactivada. Contacta al administrador.
        </div>
      </c:if>

      <form action="${pageContext.request.contextPath}/forgot-password"
            method="post"
            novalidate
            id="step1Form">

        <div class="mf-field fade-up">
          <label class="mf-field__label" for="email">
            Correo electrónico registrado
          </label>
          <div class="mf-field__input-wrap">
            <i class="bi bi-envelope mf-field__icon"></i>
            <input type="email"
                   id="email"
                   name="email"
                   class="mf-input"
                   placeholder="tu@correo.com"
                   autocomplete="username"
                   required
                   autofocus>
          </div>
        </div>

        <%-- Botones --%>
        <div style="display:flex; flex-direction:column; gap:0.7rem; margin-top:0.5rem;">
          <button type="submit"
                  class="btn-mf-primary fade-up"
                  name="action"
                  value="buscar"
                  id="step1Btn">
            <span>Verificar correo</span>
            <i class="bi bi-arrow-right btn-arrow"></i>
          </button>

          <a href="${pageContext.request.contextPath}/login"
             class="btn-mf-ghost fade-up"
             style="justify-content:center;">
            <i class="bi bi-arrow-left"></i>
            Volver al inicio de sesión
          </a>
        </div>

      </form>

    </c:if>

    <%-- ════════════════════════════════════════════════════════════════
         PASO 2 — Email verificado o mensaje genérico
         Se muestra cuando hay infoMsg (independiente de si el email existe)
    ════════════════════════════════════════════════════════════════════ --%>
    <c:if test="${not empty infoMsg && empty emailEncontrado}">

      <div class="login-heading fade-up">
        <h1>Verifica tu correo</h1>
        <p>Te indicamos los siguientes pasos</p>
      </div>

      <div class="mf-alert mf-alert--info fade-up" role="alert">
        <i class="bi bi-info-circle-fill mf-alert-icon"></i>
        <c:out value="${infoMsg}"/>
      </div>

      <div style="margin-top:1.5rem;">
        <a href="${pageContext.request.contextPath}/login"
           class="btn-mf-ghost fade-up"
           style="justify-content:center; width:100%;">
          <i class="bi bi-arrow-left"></i>
          Volver al inicio de sesión
        </a>
      </div>

    </c:if>

    <%-- ════════════════════════════════════════════════════════════════
         PASO 2 (con form) — Email válido y activo encontrado
         emailEncontrado = true → mostrar formulario de nueva contraseña
    ════════════════════════════════════════════════════════════════════ --%>
    <c:if test="${not empty emailEncontrado}">

      <div class="login-heading fade-up">
        <h1>Nueva contraseña</h1>
        <p>
          Estableciendo clave para
          <strong style="color:var(--mf-text-primary);">
            <c:out value="${emailIngresado}"/>
          </strong>
        </p>
      </div>

      <%-- Mensaje genérico informativo --%>
      <c:if test="${not empty infoMsg}">
        <div class="mf-alert mf-alert--info fade-up" role="alert" style="margin-bottom:1rem;">
          <i class="bi bi-info-circle-fill mf-alert-icon"></i>
          <c:out value="${infoMsg}"/>
        </div>
      </c:if>

      <%-- Error en el reset --%>
      <c:if test="${not empty errorMsg}">
        <div class="mf-alert mf-alert--error fade-up" role="alert">
          <i class="bi bi-exclamation-triangle-fill mf-alert-icon"></i>
          <c:out value="${errorMsg}"/>
        </div>
      </c:if>

      <form action="${pageContext.request.contextPath}/forgot-password"
            method="post"
            novalidate
            id="resetForm">

        <%-- Nueva contraseña --%>
        <div class="mf-field fade-up">
          <label class="mf-field__label" for="nuevaPassword">
            Nueva contraseña
          </label>
          <div class="mf-field__input-wrap">
            <i class="bi bi-lock mf-field__icon"></i>
            <input type="password"
                   id="nuevaPassword"
                   name="nuevaPassword"
                   class="mf-input mf-input--password"
                   placeholder="Mínimo 8 caracteres"
                   autocomplete="new-password"
                   minlength="8"
                   required
                   autofocus>
            <button type="button"
                    class="btn-toggle-pass"
                    onclick="togglePass('nuevaPassword','iconNueva')"
                    aria-label="Mostrar contraseña">
              <i class="bi bi-eye" id="iconNueva"></i>
            </button>
          </div>
          <%-- Barra de fortaleza --%>
          <div id="strengthWrap"
               style="margin-top:0.5rem; display:none;">
            <div class="mf-progress">
              <div class="mf-progress-bar" id="strengthBar"
                   style="width:0%; transition: width 0.4s ease, background 0.4s ease;"></div>
            </div>
            <div id="strengthLabel"
                 style="font-size:0.72rem; color:var(--mf-text-muted); margin-top:0.3rem;"></div>
          </div>
        </div>

        <%-- Confirmar contraseña --%>
        <div class="mf-field fade-up">
          <label class="mf-field__label" for="confirmaPassword">
            Confirmar contraseña
          </label>
          <div class="mf-field__input-wrap">
            <i class="bi bi-lock-fill mf-field__icon"></i>
            <input type="password"
                   id="confirmaPassword"
                   name="confirmaPassword"
                   class="mf-input mf-input--password"
                   placeholder="Repite la contraseña"
                   autocomplete="new-password"
                   required>
            <button type="button"
                    class="btn-toggle-pass"
                    onclick="togglePass('confirmaPassword','iconConfirma')"
                    aria-label="Mostrar contraseña">
              <i class="bi bi-eye" id="iconConfirma"></i>
            </button>
          </div>
          <div id="matchMsg"
               style="font-size:0.73rem; margin-top:0.35rem; display:none;"></div>
        </div>

        <%-- Botones --%>
        <div style="display:flex; flex-direction:column; gap:0.7rem; margin-top:0.5rem;">
          <button type="submit"
                  class="btn-mf-primary fade-up"
                  name="action"
                  value="reset"
                  id="resetBtn"
                  disabled>
            <span>Actualizar contraseña</span>
            <i class="bi bi-shield-check btn-arrow"></i>
          </button>

          <a href="${pageContext.request.contextPath}/forgot-password"
             class="btn-mf-ghost fade-up"
             style="justify-content:center;">
            <i class="bi bi-arrow-left"></i>
            Ingresar otro correo
          </a>
        </div>

      </form>

    </c:if>

    <%-- Footer --%>
    <div class="login-panel__footer fade-up" style="margin-top:2rem;">
      &copy; 2025 MaxFit &mdash; Todos los derechos reservados.
    </div>

  </div><%-- /login-panel --%>
</div><%-- /login-wrapper --%>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"
        integrity="sha384-YvpcrYf0tY3lHB60NNkmXc4s9bIOgUxi8T/jzmH5xFBFHCBcN+dB/lFrCB1Klwmr"
        crossorigin="anonymous" defer></script>

<script>
(function () {
  'use strict';

  /* ── Toggle show/hide password ───────────────────────────────────── */
  window.togglePass = function (inputId, iconId) {
    var input = document.getElementById(inputId);
    var icon  = document.getElementById(iconId);
    if (!input || !icon) return;
    var hidden = input.type === 'password';
    input.type  = hidden ? 'text' : 'password';
    icon.className = hidden ? 'bi bi-eye-slash' : 'bi bi-eye';
  };

  /* ── Validación en tiempo real (solo en paso 3) ─────────────────── */
  var nueva    = document.getElementById('nuevaPassword');
  var confirma = document.getElementById('confirmaPassword');
  var resetBtn = document.getElementById('resetBtn');
  var matchMsg = document.getElementById('matchMsg');
  var strengthWrap = document.getElementById('strengthWrap');
  var strengthBar  = document.getElementById('strengthBar');
  var strengthLabel= document.getElementById('strengthLabel');

  if (nueva && confirma && resetBtn) {

    /* Fortaleza de contraseña */
    nueva.addEventListener('input', function () {
      var val = nueva.value;
      strengthWrap.style.display = val.length > 0 ? 'block' : 'none';
      var score = calcStrength(val);
      var config = [
        { pct: 20,  color: 'var(--mf-danger)',  label: 'Muy débil' },
        { pct: 40,  color: 'var(--mf-warning)', label: 'Débil' },
        { pct: 60,  color: '#facc15',           label: 'Regular' },
        { pct: 80,  color: 'var(--mf-success)', label: 'Buena' },
        { pct: 100, color: '#22d3ee',           label: 'Muy segura' }
      ][Math.max(0, Math.min(score, 4))];
      strengthBar.style.width      = config.pct + '%';
      strengthBar.style.background = config.color;
      strengthLabel.textContent    = config.label;
      strengthLabel.style.color    = config.color;
      checkMatch();
    });

    /* Coincidencia de contraseñas */
    confirma.addEventListener('input', checkMatch);

    function checkMatch() {
      var nVal = nueva.value;
      var cVal = confirma.value;
      var valid = nVal.length >= 8 && cVal.length > 0;

      if (cVal.length === 0) {
        matchMsg.style.display = 'none';
      } else if (nVal === cVal) {
        matchMsg.style.display = 'block';
        matchMsg.style.color   = 'var(--mf-success)';
        matchMsg.innerHTML     = '<i class="bi bi-check-circle-fill"></i> Las contraseñas coinciden';
      } else {
        matchMsg.style.display = 'block';
        matchMsg.style.color   = 'var(--mf-danger)';
        matchMsg.innerHTML     = '<i class="bi bi-x-circle-fill"></i> Las contraseñas no coinciden';
      }

      resetBtn.disabled = !(valid && nVal === cVal);
    }

    function calcStrength(pwd) {
      var score = 0;
      if (pwd.length >= 8)  score++;
      if (pwd.length >= 12) score++;
      if (/[A-Z]/.test(pwd))   score++;
      if (/[0-9]/.test(pwd))   score++;
      if (/[^A-Za-z0-9]/.test(pwd)) score++;
      return Math.min(score - 1, 4);
    }

    /* Loading en submit */
    var resetForm = document.getElementById('resetForm');
    if (resetForm) {
      resetForm.addEventListener('submit', function () {
        if (!resetBtn.disabled) {
          resetBtn.disabled = true;
          resetBtn.querySelector('span').textContent = 'Actualizando…';
        }
      });
    }
  }

  /* ── Loading step 1 ─────────────────────────────────────────────── */
  var step1Form = document.getElementById('step1Form');
  var step1Btn  = document.getElementById('step1Btn');
  if (step1Form && step1Btn) {
    step1Form.addEventListener('submit', function () {
      step1Btn.disabled = true;
      step1Btn.querySelector('span').textContent = 'Verificando…';
    });
  }

})();
</script>

</body>
</html>
