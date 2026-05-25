<%-- ============================================================
     login.jsp  —  MaxFit Sistema de Gestión
     Vista de inicio de sesión.

     Acceso:  GET /login  (LoginController.doGet)
     Submit:  POST /login (LoginController.doPost)

     Atributos de request que recibe del controlador:
       - errorMsg        (String)  → mensaje de error tras POST fallido
       - emailIngresado  (String)  → email ya escrito, para no repetirlo

     Sin JavaScript. HTML + CSS + JSTL core.
     Bootstrap se usa solo para el grid de columnas.
     ============================================================ --%>
<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="robots" content="noindex, nofollow">
    <title>Iniciar sesión — MaxFit</title>

    <%-- Google Fonts: Barlow Condensed (display) + DM Sans (body) --%>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Barlow+Condensed:wght@700;800&family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">

    <%-- Bootstrap 5 grid (solo estructura de columnas) --%>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css">

    <%-- Estilos propios de autenticación --%>
    <link rel="stylesheet"
          href="${pageContext.request.contextPath}/static/css/auth.css">
</head>
<body>

<%-- ══════════════════════════════════════════════════════════
     LAYOUT PRINCIPAL: Hero (izquierda) + Panel (derecha)
     ══════════════════════════════════════════════════════════ --%>
<div class="auth-wrapper">

    <%-- ── Panel izquierdo: imagen + texto de marca ─────── --%>
    <aside class="auth-hero" aria-hidden="true">
        <div class="auth-hero__bg"
        style="background-image: url('${pageContext.request.contextPath}/static/img/gym_welcome.jpg');">
    </div>

        <%-- Palabras clave de la marca --%>
        <div class="auth-hero__content">
            <p class="auth-hero__tagline">
                Disciplina<br>
                Fuerza<br>
                Constancia<br>
                <span class="accent">Resultados</span>
            </p>
        </div>

        <%-- Tarjeta descriptiva inferior --%>
        <div class="auth-hero__card">
            <div class="auth-hero__card-icon">
                <%-- Ícono SVG inline: gráfica de barras --%>
                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8"
                     aria-hidden="true">
                    <path stroke-linecap="round" stroke-linejoin="round"
                          d="M3 13.5V21m4.5-10.5V21M12 9v12m4.5-6V21M21 3v18"/>
                </svg>
            </div>
            <div class="auth-hero__card-text">
                <h3>Sistema de Gestión<br>para Gimnasios</h3>
                <p>Controla, organiza y potencia tu gimnasio<br>desde un solo lugar.</p>
            </div>
        </div>

        <%-- Copyright --%>
        <p class="auth-hero__footer">© 2025 MaxFit. Todos los derechos reservados.</p>
    </aside>

    <%-- ── Panel derecho: formulario de login ────────────── --%>
    <main class="auth-panel" role="main">

        <%-- Logo --%>
        <div class="auth-logo">
            <span class="auth-logo__wordmark" aria-label="MaxFit">
                <span class="max">MAX</span><span class="fit">FIT</span>
            </span>
            <span class="auth-logo__sub">Sistema de Gestión</span>
        </div>

        <%-- Encabezado --%>
        <div class="auth-heading">
            <h1>Bienvenido de vuelta</h1>
            <div class="auth-heading__divider" aria-hidden="true"></div>
            <p>Inicia sesión para continuar</p>
        </div>

        <%-- ── Bloque de error (solo se muestra si el controlador lo pone) --%>
        <c:if test="${not empty errorMsg}">
            <div class="auth-alert" role="alert" aria-live="assertive">
                <%-- Ícono de alerta SVG inline --%>
                <svg class="auth-alert__icon" xmlns="http://www.w3.org/2000/svg"
                     fill="none" viewBox="0 0 24 24" stroke="currentColor"
                     stroke-width="2" aria-hidden="true">
                    <path stroke-linecap="round" stroke-linejoin="round"
                          d="M12 9v3.75m-9.303 3.376c-.866 1.5.217
                             3.374 1.948 3.374h14.71c1.73 0 2.813-1.874
                             1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898
                             0L2.697 16.126ZM12 15.75h.007v.008H12v-.008Z"/>
                </svg>
                <p class="auth-alert__text"><c:out value="${errorMsg}"/></p>
            </div>
        </c:if>

        <%-- ── Formulario principal ─────────────────────────────
             action apunta al servlet /login
             method POST → LoginController.doPost
             ──────────────────────────────────────────────────── --%>
        <form class="auth-form"
              action="${pageContext.request.contextPath}/login"
              method="post"
              novalidate
              autocomplete="on">

            <%-- Protección CSRF: token generado por CsrfFilter en el GET --%>
            <input type="hidden" name="_csrf" value="${csrfToken}">

            <%-- ── Campo: Correo electrónico ─────────────────── --%>
            <div class="form-field">
                <label for="email">Correo electrónico</label>
                <div class="input-wrapper">
                    <%-- Ícono sobre/mail SVG inline --%>
                    <svg class="input-wrapper__icon"
                         xmlns="http://www.w3.org/2000/svg" fill="none"
                         viewBox="0 0 24 24" stroke="currentColor"
                         stroke-width="1.8" aria-hidden="true">
                        <path stroke-linecap="round" stroke-linejoin="round"
                              d="M21.75 6.75v10.5a2.25 2.25 0 0 1-2.25
                                 2.25h-15a2.25 2.25 0 0 1-2.25-2.25V6.75m19.5
                                 0A2.25 2.25 0 0 0 19.5 4.5h-15a2.25 2.25 0 0
                                 0-2.25 2.25m19.5 0v.243a2.25 2.25 0 0
                                 1-1.07 1.916l-7.5 4.615a2.25 2.25 0 0
                                 1-2.36 0L3.32 8.91a2.25 2.25 0 0
                                 1-1.07-1.916V6.75"/>
                    </svg>
                    <input
                        type="email"
                        id="email"
                        name="email"
                        placeholder="ejemplo@maxfit.com"
                        autocomplete="email"
                        required
                        maxlength="150"
                        value="<c:out value='${emailIngresado}'/>"
                        aria-describedby="emailError"
                        aria-required="true">
                </div>
            </div>

            <%-- ── Campo: Contraseña ─────────────────────────── --%>
            <div class="form-field">
                <label for="password">Contraseña</label>
                <div class="input-wrapper">
                    <%-- Ícono candado SVG inline --%>
                    <svg class="input-wrapper__icon"
                         xmlns="http://www.w3.org/2000/svg" fill="none"
                         viewBox="0 0 24 24" stroke="currentColor"
                         stroke-width="1.8" aria-hidden="true">
                        <path stroke-linecap="round" stroke-linejoin="round"
                              d="M16.5 10.5V6.75a4.5 4.5 0 1 0-9 0v3.75m-.75
                                 11.25h10.5a2.25 2.25 0 0 0 2.25-2.25v-6.75a2.25
                                 2.25 0 0 0-2.25-2.25H6.75a2.25 2.25 0 0
                                 0-2.25 2.25v6.75a2.25 2.25 0 0 0 2.25 2.25Z"/>
                    </svg>
                    <input
                        type="password"
                        id="password"
                        name="password"
                        placeholder="Ingresa tu contraseña"
                        autocomplete="current-password"
                        required
                        maxlength="255"
                        aria-required="true">
                    <%-- Ícono decorativo de ojo (sin JS no hay toggle, es solo visual) --%>
                    <svg class="input-wrapper__eye"
                         xmlns="http://www.w3.org/2000/svg" fill="none"
                         viewBox="0 0 24 24" stroke="currentColor"
                         stroke-width="1.8" aria-hidden="true">
                        <path stroke-linecap="round" stroke-linejoin="round"
                              d="M2.036 12.322a1.012 1.012 0 0 1
                                 0-.639C3.423 7.51 7.36 4.5 12 4.5c4.638
                                 0 8.573 3.007 9.963 7.178.07.207.07.431
                                 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638
                                 0-8.573-3.007-9.963-7.178Z"/>
                        <path stroke-linecap="round" stroke-linejoin="round"
                              d="M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z"/>
                    </svg>
                </div>
            </div>

            <%-- ── Fila: Recordarme + ¿Olvidaste? ───────────── --%>
            <div class="auth-options">
                <label class="checkbox-label">
                    <input type="checkbox" name="recordarme" value="true">
                    <span>Recordarme</span>
                </label>
                <a href="${pageContext.request.contextPath}/forgot-password"
                   class="auth-link">
                    ¿Olvidaste tu contraseña?
                </a>
            </div>

            <%-- ── Botón de submit ────────────────────────────── --%>
            <button type="submit" class="btn-auth">
                Iniciar sesión
                <%-- Flecha derecha SVG inline --%>
                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                     viewBox="0 0 24 24" stroke="currentColor"
                     stroke-width="2.2" aria-hidden="true">
                    <path stroke-linecap="round" stroke-linejoin="round"
                          d="M13.5 4.5 21 12m0 0-7.5 7.5M21 12H3"/>
                </svg>
            </button>

        </form><%-- /auth-form --%>
    </main><%-- /auth-panel --%>

</div><%-- /auth-wrapper --%>

</body>
</html>
