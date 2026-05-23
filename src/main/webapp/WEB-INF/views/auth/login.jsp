<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MaxFit — Iniciar Sesión</title>

    <!-- Bootstrap 5.3 -->
    <link rel="stylesheet"
          href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css">

    <!-- Bootstrap Icons -->
    <link rel="stylesheet"
          href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">

    <!-- MaxFit Login CSS -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/login.css">
</head>
<body>

<div class="login-wrapper">

    <!-- ═══════════════════════════════════════════════
         PANEL IZQUIERDO — Branding MaxFit
    ════════════════════════════════════════════════ -->
    <aside class="login-brand">
        <div class="login-brand__bg"></div>
        <div class="login-brand__overlay"></div>

        <div class="login-brand__content">

            <!-- Logo -->
            <div class="login-brand__logo">
                <div class="login-brand__logo-icon">
                    <i class="bi bi-lightning-fill text-white"></i>
                </div>
                <div class="login-brand__logo-text">
                    MAX<span>FIT</span>
                </div>
            </div>

            <!-- Tagline central -->
            <div>
                <div class="orange-line"></div>
                <h1 class="login-brand__tagline">
                    GESTIONA<br>
                    TU GYM<br>
                    <em>SIN LÍMITES</em>
                </h1>
                <p class="login-brand__sub">
                    Plataforma profesional de gestión para gimnasios.
                    Control total de clientes, membresías, clases y asistencia
                    desde un solo lugar.
                </p>

                <!-- Stats decorativos -->
                <div class="login-brand__stats">
                    <div class="stat-pill">
                        <span class="stat-pill__icon"><i class="bi bi-people-fill"></i></span>
                        <span class="stat-pill__val">+500</span>
                        <span class="stat-pill__label">clientes</span>
                    </div>
                    <div class="stat-pill">
                        <span class="stat-pill__icon"><i class="bi bi-calendar-check-fill"></i></span>
                        <span class="stat-pill__val">24/7</span>
                        <span class="stat-pill__label">disponible</span>
                    </div>
                    <div class="stat-pill">
                        <span class="stat-pill__icon"><i class="bi bi-shield-fill-check"></i></span>
                        <span class="stat-pill__val">100%</span>
                        <span class="stat-pill__label">seguro</span>
                    </div>
                </div>
            </div>

        </div>
    </aside>

    <!-- ═══════════════════════════════════════════════
         PANEL DERECHO — Formulario de Login
    ════════════════════════════════════════════════ -->
    <main class="login-form-panel">

        <!-- Encabezado -->
        <div class="login-form__header">
            <span class="login-form__eyebrow">Sistema de Gestión</span>
            <h2 class="login-form__title">Bienvenido<br>de vuelta</h2>
            <p class="login-form__desc">Ingresa tus credenciales para continuar.</p>
        </div>

        <!-- ── Mensajes de feedback ── -->
        <c:if test="${not empty errorMsg}">
            <div class="alert-maxfit mb-3" role="alert">
                <i class="bi bi-exclamation-triangle-fill"></i>
                <span><c:out value="${errorMsg}"/></span>
            </div>
        </c:if>

        <c:if test="${not empty successMsg}">
            <div class="alert alert-success border-0 rounded-2 py-2 px-3 mb-3
                        d-flex align-items-center gap-2"
                 style="background:rgba(34,197,94,0.12); color:#86efac;
                        font-size:.88rem; border:1px solid rgba(34,197,94,0.3)!important;">
                <i class="bi bi-check-circle-fill"></i>
                <span><c:out value="${successMsg}"/></span>
            </div>
        </c:if>

        <!-- ── Formulario ── -->
        <form method="post"
              action="${pageContext.request.contextPath}/login"
              autocomplete="on"
              novalidate>

            <!-- Email -->
            <div class="mb-3">
                <label for="email" class="form-label">Correo electrónico</label>
                <div class="input-icon-wrap">
                    <i class="bi bi-envelope-fill input-icon"></i>
                    <input type="email"
                           id="email"
                           name="email"
                           class="form-control"
                           placeholder="usuario@maxfit.pe"
                           value="<c:out value='${emailIngresado}'/>"
                           autocomplete="email"
                           required
                           autofocus>
                </div>
            </div>

            <!-- Contraseña -->
            <div class="mb-3">
                <div class="d-flex justify-content-between align-items-center mb-1">
                    <label for="password" class="form-label mb-0">Contraseña</label>
                    <a href="${pageContext.request.contextPath}/forgot-password"
                       class="text-decoration-none"
                       style="font-size:.8rem; color:var(--mf-orange);">
                        ¿Olvidaste tu contraseña?
                    </a>
                </div>
                <div class="input-icon-wrap">
                    <i class="bi bi-lock-fill input-icon"></i>
                    <input type="password"
                           id="password"
                           name="password"
                           class="form-control pe-5"
                           placeholder="••••••••"
                           autocomplete="current-password"
                           required>
                    <button type="button"
                            class="btn-eye"
                            id="togglePassword"
                            aria-label="Mostrar contraseña">
                        <i class="bi bi-eye-slash" id="eyeIcon"></i>
                    </button>
                </div>
            </div>

            <!-- Recuérdame -->
            <div class="form-check mb-4">
                <input class="form-check-input"
                       type="checkbox"
                       id="remember"
                       name="remember">
                <label class="form-check-label" for="remember">
                    Mantener sesión iniciada
                </label>
            </div>

            <!-- Botón submit -->
            <button type="submit" class="btn-maxfit" id="btnLogin">
                <i class="bi bi-box-arrow-in-right"></i>
                Ingresar al sistema
            </button>

        </form>

        <!-- Divider -->
        <div class="divider">acceso por rol</div>

        <!-- Chips de roles -->
        <div class="roles-info">
            <p class="roles-info__title">Roles del sistema</p>
            <div>
                <span class="role-chip">
                    <span class="dot dot-admin"></span>
                    Administrador
                </span>
                <span class="role-chip">
                    <span class="dot dot-recep"></span>
                    Recepcionista
                </span>
                <span class="role-chip">
                    <span class="dot dot-instr"></span>
                    Instructor
                </span>
            </div>
        </div>

        <!-- Footer -->
        <div class="login-form__footer">
            <p class="mb-0">
                ¿Problemas para ingresar?
                <a href="mailto:soporte@maxfit.pe">Contacta al administrador</a>
            </p>
        </div>

        <!-- Version -->
        <span class="version-badge">MaxFit v1.0</span>

    </main><!-- /login-form-panel -->
</div><!-- /login-wrapper -->

<!-- Bootstrap 5 JS (solo bundle, sin Popper separado) -->
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

<script>
    /* Toggle mostrar/ocultar contraseña */
    (function () {
        var btn  = document.getElementById('togglePassword');
        var inp  = document.getElementById('password');
        var icon = document.getElementById('eyeIcon');

        if (!btn || !inp || !icon) return;

        btn.addEventListener('click', function () {
            var isPass = inp.type === 'password';
            inp.type   = isPass ? 'text' : 'password';
            icon.className = isPass ? 'bi bi-eye' : 'bi bi-eye-slash';
            btn.setAttribute('aria-label', isPass ? 'Ocultar contraseña' : 'Mostrar contraseña');
        });
    }());

    /* Loader en el botón al hacer submit */
    (function () {
        var form = document.querySelector('form');
        var btn  = document.getElementById('btnLogin');
        if (!form || !btn) return;

        form.addEventListener('submit', function () {
            btn.disabled = true;
            btn.innerHTML =
                '<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>'
                + ' Verificando...';
        });
    }());
</script>

</body>
</html>
