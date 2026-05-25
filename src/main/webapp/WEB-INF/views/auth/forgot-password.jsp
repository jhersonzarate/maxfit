<%-- ============================================================
     forgot-password.jsp  —  MaxFit Sistema de Gestión
     Vista de recuperación de contraseña.

     Acceso público: /forgot-password (AuthFilter lo permite).
     Servlet:        ForgotPasswordController.java

     ── Flujo de 3 pasos (todo en esta misma vista) ─────────────
     PASO 1  GET  /forgot-password
             → El JSP muestra solo el form de email (paso 1).
               No hay atributos de request.

     PASO 2  POST /forgot-password?action=buscar
             → Controlador verifica email en BD.
               request.setAttribute("infoMsg",        ...)  siempre
               request.setAttribute("emailEncontrado", true) si es válido
               request.setAttribute("emailIngresado",  email) si es válido
               El JSP muestra el form de nueva contraseña (paso 3).

     PASO 3  POST /forgot-password?action=reset
             → Si OK: redirect a /login?msg=password_reset
               Si error: vuelve aquí con errorMsg + emailEncontrado=true

     ── Atributos usados ─────────────────────────────────────────
       errorMsg        (String)  → error de validación o de BD
       infoMsg         (String)  → mensaje informativo genérico (paso 2)
       emailEncontrado (Boolean) → true = mostrar form de nueva contraseña
       emailIngresado  (String)  → email ya escrito, para no repetirlo

     Sin JavaScript. HTML + JSTL core + CSS externo.
     ============================================================ --%>
<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="robots" content="noindex, nofollow">
    <title>Recuperar contraseña — MaxFit</title>

    <%-- Google Fonts: Barlow Condensed (display) + DM Sans (body) --%>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Barlow+Condensed:wght@700;800&family=DM+Sans:wght@400;500;600;700&display=swap"
          rel="stylesheet">

    <%-- Bootstrap 5 (solo grid/utilidades estructurales) --%>
    <link rel="stylesheet"
          href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css">

    <%-- Estilos propios de autenticación — mismo archivo que login.jsp --%>
    <link rel="stylesheet"
          href="${pageContext.request.contextPath}/static/css/auth.css">
</head>
<body>

<%-- ══════════════════════════════════════════════════════════
     LAYOUT: Hero izquierda + Panel de formulario derecha
     (misma estructura que login.jsp para coherencia visual)
     ══════════════════════════════════════════════════════════ --%>
<div class="auth-wrapper">

    <%-- ── Panel izquierdo: imagen de fondo + marca ──────── --%>
    <aside class="auth-hero" aria-hidden="true">
        <div class="auth-hero__bg"
        style="background-image: url('${pageContext.request.contextPath}/static/img/gym_welcome.jpg');">
    </div>

        <div class="auth-hero__content">
            <p class="auth-hero__tagline">
                Disciplina<br>
                Fuerza<br>
                Constancia<br>
                <span class="accent">Resultados</span>
            </p>
        </div>

        <div class="auth-hero__card">
            <div class="auth-hero__card-icon">
                <%-- Ícono candado SVG --%>
                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                     viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8"
                     aria-hidden="true">
                    <path stroke-linecap="round" stroke-linejoin="round"
                          d="M16.5 10.5V6.75a4.5 4.5 0 1 0-9 0v3.75m-.75
                             11.25h10.5a2.25 2.25 0 0 0 2.25-2.25v-6.75a2.25
                             2.25 0 0 0-2.25-2.25H6.75a2.25 2.25 0 0
                             0-2.25 2.25v6.75a2.25 2.25 0 0 0 2.25 2.25Z"/>
                </svg>
            </div>
            <div class="auth-hero__card-text">
                <h3>Acceso seguro<br>al sistema</h3>
                <p>Restablece tu contraseña de forma<br>segura desde aquí.</p>
            </div>
        </div>

        <p class="auth-hero__footer">© 2025 MaxFit. Todos los derechos reservados.</p>
    </aside>

    <%-- ── Panel derecho: formulario de recuperación ───────── --%>
    <main class="auth-panel" role="main">

        <%-- Logo --%>
        <div class="auth-logo">
            <span class="auth-logo__wordmark" aria-label="MaxFit">
                <span class="max">MAX</span><span class="fit">FIT</span>
            </span>
            <span class="auth-logo__sub">Sistema de Gestión</span>
        </div>

        <%-- ══════════════════════════════════════════════════
             PASO 1 y PASO 2 comparten encabezado condicional
             ══════════════════════════════════════════════════ --%>
        <div class="auth-heading">
            <c:choose>
                <c:when test="${emailEncontrado == true}">
                    <%-- Encabezado del PASO 3: establecer nueva contraseña --%>
                    <h1>Nueva contraseña</h1>
                    <div class="auth-heading__divider" aria-hidden="true"></div>
                    <p>Elige una contraseña segura para tu cuenta</p>
                </c:when>
                <c:otherwise>
                    <%-- Encabezado del PASO 1: ingresar email --%>
                    <h1>Recuperar acceso</h1>
                    <div class="auth-heading__divider" aria-hidden="true"></div>
                    <p>Ingresa tu correo para verificar tu cuenta</p>
                </c:otherwise>
            </c:choose>
        </div>

        <%-- ── Alerta de error (validación o BD) ─────────── --%>
        <c:if test="${not empty errorMsg}">
            <div class="auth-alert" role="alert" aria-live="assertive">
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

        <%-- ── Mensaje informativo genérico (paso 2 → mismo para email válido e inválido) --%>
        <c:if test="${not empty infoMsg}">
            <div class="auth-alert auth-alert--info" role="status" aria-live="polite">
                <svg class="auth-alert__icon" xmlns="http://www.w3.org/2000/svg"
                     fill="none" viewBox="0 0 24 24" stroke="currentColor"
                     stroke-width="2" aria-hidden="true">
                    <path stroke-linecap="round" stroke-linejoin="round"
                          d="m11.25 11.25.041-.02a.75.75 0 0 1 1.063.852l-.708
                             2.836a.75.75 0 0 0 1.063.853l.041-.021M21 12a9 9
                             0 1 1-18 0 9 9 0 0 1 18 0Zm-9-3.75h.008v.008H12V8.25Z"/>
                </svg>
                <p class="auth-alert__text"><c:out value="${infoMsg}"/></p>
            </div>
        </c:if>

        <%-- ══════════════════════════════════════════════════
             PASO 1 — Formulario: ingresar email
             Se muestra cuando emailEncontrado NO está en request.
             ══════════════════════════════════════════════════ --%>
        <c:if test="${empty emailEncontrado}">
            <form class="auth-form"
                  action="${pageContext.request.contextPath}/forgot-password"
                  method="post"
                  novalidate
                  autocomplete="on">

                <%-- Campo oculto que indica al controlador qué acción ejecutar --%>
                <input type="hidden" name="action" value="buscar">
                <input type="hidden" name="_csrf" value="${sessionScope._csrfToken}">

                <%-- Campo: email --%>
                <div class="form-field">
                    <label for="email">Correo electrónico registrado</label>
                    <div class="input-wrapper">
                        <%-- Ícono email SVG inline --%>
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
                            aria-required="true">
                    </div>
                </div>

                <%-- Botón verificar --%>
                <button type="submit" class="btn-auth">
                    Verificar correo
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                         viewBox="0 0 24 24" stroke="currentColor"
                         stroke-width="2.2" aria-hidden="true">
                        <path stroke-linecap="round" stroke-linejoin="round"
                              d="M13.5 4.5 21 12m0 0-7.5 7.5M21 12H3"/>
                    </svg>
                </button>

            </form>
        </c:if><%-- /PASO 1 --%>

        <%-- ══════════════════════════════════════════════════
             PASO 3 — Formulario: nueva contraseña
             Solo se renderiza si el controlador puso emailEncontrado=true
             en el request. El SESSION_RESET_EMAIL actúa de guard en Java.
             ══════════════════════════════════════════════════ --%>
        <c:if test="${emailEncontrado == true}">
            <form class="auth-form"
                  action="${pageContext.request.contextPath}/forgot-password"
                  method="post"
                  novalidate
                  autocomplete="off">

                <input type="hidden" name="action" value="reset">
                <input type="hidden" name="_csrf" value="${sessionScope._csrfToken}">

                <%-- Campo oculto con el email (lo muestra el controlador,
                     el guard real es SESSION_RESET_EMAIL en sesión) --%>
                <input type="hidden" name="emailRef"
                       value="<c:out value='${emailIngresado}'/>">

                <%-- Indicador visual de la cuenta afectada --%>
                <div class="auth-account-badge" aria-label="Cuenta a modificar">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                         viewBox="0 0 24 24" stroke="currentColor"
                         stroke-width="1.8" aria-hidden="true">
                        <path stroke-linecap="round" stroke-linejoin="round"
                              d="M15.75 6a3.75 3.75 0 1 1-7.5 0 3.75 3.75
                                 0 0 1 7.5 0ZM4.501 20.118a7.5 7.5 0 0
                                 1 14.998 0A17.933 17.933 0 0 1 12 21.75c-2.676
                                 0-5.216-.584-7.499-1.632Z"/>
                    </svg>
                    <span><c:out value="${emailIngresado}"/></span>
                </div>

                <%-- Campo: nueva contraseña --%>
                <div class="form-field">
                    <label for="nuevaPassword">Nueva contraseña</label>
                    <div class="input-wrapper">
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
                            id="nuevaPassword"
                            name="nuevaPassword"
                            placeholder="Mínimo 8 caracteres"
                            required
                            minlength="8"
                            maxlength="255"
                            autocomplete="new-password"
                            aria-required="true"
                            aria-describedby="passHint">
                        <svg class="input-wrapper__eye"
                             xmlns="http://www.w3.org/2000/svg" fill="none"
                             viewBox="0 0 24 24" stroke="currentColor"
                             stroke-width="1.8" aria-hidden="true">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M2.036 12.322a1.012 1.012 0 0 1 0-.639C3.423
                                     7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963
                                     7.178.07.207.07.431 0 .639C20.577 16.49 16.64
                                     19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178Z"/>
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z"/>
                        </svg>
                    </div>
                    <span class="form-field__hint" id="passHint">
                        Mínimo 8 caracteres
                    </span>
                </div>

                <%-- Campo: confirmar contraseña --%>
                <div class="form-field">
                    <label for="confirmaPassword">Confirmar contraseña</label>
                    <div class="input-wrapper">
                        <svg class="input-wrapper__icon"
                             xmlns="http://www.w3.org/2000/svg" fill="none"
                             viewBox="0 0 24 24" stroke="currentColor"
                             stroke-width="1.8" aria-hidden="true">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M9 12.75 11.25 15 15 9.75m-3-7.036A11.959
                                     11.959 0 0 1 3.598 6 11.99 11.99 0 0 0 3
                                     9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332
                                     9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196
                                     0-6.1-1.248-8.25-3.285Z"/>
                        </svg>
                        <input
                            type="password"
                            id="confirmaPassword"
                            name="confirmaPassword"
                            placeholder="Repite tu nueva contraseña"
                            required
                            maxlength="255"
                            autocomplete="new-password"
                            aria-required="true">
                        <svg class="input-wrapper__eye"
                             xmlns="http://www.w3.org/2000/svg" fill="none"
                             viewBox="0 0 24 24" stroke="currentColor"
                             stroke-width="1.8" aria-hidden="true">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M2.036 12.322a1.012 1.012 0 0 1 0-.639C3.423
                                     7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963
                                     7.178.07.207.07.431 0 .639C20.577 16.49 16.64
                                     19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178Z"/>
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z"/>
                        </svg>
                    </div>
                </div>

                <%-- Botón restablecer --%>
                <button type="submit" class="btn-auth">
                    Restablecer contraseña
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                         viewBox="0 0 24 24" stroke="currentColor"
                         stroke-width="2.2" aria-hidden="true">
                        <path stroke-linecap="round" stroke-linejoin="round"
                              d="M13.5 4.5 21 12m0 0-7.5 7.5M21 12H3"/>
                    </svg>
                </button>

            </form>
        </c:if><%-- /PASO 3 --%>

        <%-- ── Volver al login — siempre visible ─────────── --%>
        <div class="auth-back">
            <a href="${pageContext.request.contextPath}/login"
               class="auth-back__link">
                <%-- Ícono flecha izquierda SVG --%>
                <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                     viewBox="0 0 24 24" stroke="currentColor"
                     stroke-width="2" aria-hidden="true">
                    <path stroke-linecap="round" stroke-linejoin="round"
                          d="M10.5 19.5 3 12m0 0 7.5-7.5M3 12h18"/>
                </svg>
                Volver al inicio de sesión
            </a>
        </div>

    </main><%-- /auth-panel --%>
</div><%-- /auth-wrapper --%>

</body>
</html>
