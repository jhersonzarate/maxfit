package com.mycompany.herramientas.service;

import com.mycompany.herramientas.config.AppConfig;
import com.mycompany.herramientas.config.DatabaseConnection;
import com.mycompany.herramientas.dao.ContratoDAO;
import com.mycompany.herramientas.model.Contrato;
import com.mycompany.herramientas.model.Membresia;

import java.sql.Connection;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Reglas de negocio para contratos (RF-03, RF-04).
 *
 * Centraliza la lógica que NO debe vivir en el controlador:
 *   - Calcular fecha_fin a partir de fecha_inicio + duracion_meses.
 *   - Verificar que el cliente no tenga ya un contrato activo antes de crear uno nuevo.
 *   - Cancelar un contrato (solo Administrador según RF-03).
 *
 * Por qué usar BigDecimal para montoPagado:
 *   double tiene errores de punto flotante (0.1 + 0.2 = 0.30000000000000004 en Java).
 *   BigDecimal es exacto para operaciones monetarias. El modelo Contrato
 *   ya usa BigDecimal — este servicio lo respeta.
 *
 * ← CORRECCIÓN CRÍTICA — Transacciones:
 *   El patrón anterior era:
 *     DatabaseConnection.beginTransaction();
 *     contratoDAO.save(contrato);   // DAO abría/cerraba su Connection → rollback silencioso
 *     DatabaseConnection.commit();  // nueva conexión, sin transacción real
 *
 *   Ahora:
 *     1. beginTransaction() abre la Connection y pone autoCommit = false.
 *     2. getConnection() devuelve esa misma Connection del ThreadLocal.
 *     3. Se pasa esa Connection al overload save(Connection, Contrato) del DAO.
 *     4. El DAO solo cierra el PreparedStatement, no la Connection.
 *     5. commit() / rollback() operan sobre la misma Connection.
 *     6. closeConnection() cierra en finally.
 *
 * @author MaxFit
 */
public class ContratoService {

    private static final Logger LOGGER = Logger.getLogger(ContratoService.class.getName());

    private final ContratoDAO contratoDAO;

    public ContratoService() {
        this.contratoDAO = new ContratoDAO();
    }

    public ContratoService(ContratoDAO contratoDAO) {
        this.contratoDAO = contratoDAO;
    }

    // ── Resultado de operación ───────────────────────────────────────────────

    public static final class Resultado {
        private final boolean exitoso;
        private final String  mensaje;

        private Resultado(boolean exitoso, String mensaje) {
            this.exitoso  = exitoso;
            this.mensaje  = mensaje;
        }

        public boolean isExitoso() { return exitoso; }
        public String  getMensaje() { return mensaje; }

        public static Resultado ok(String mensaje) {
            return new Resultado(true, mensaje);
        }
        public static Resultado error(String mensaje) {
            return new Resultado(false, mensaje);
        }
    }

    // ── Crear contrato ───────────────────────────────────────────────────────

    /**
     * Crea un nuevo contrato aplicando todas las reglas de negocio:
     *   1. Verifica que no haya contrato activo para el cliente.
     *   2. Calcula fecha_fin = fecha_inicio + duracion_meses de la membresía.
     *   3. Guarda el contrato en la BD dentro de una transacción real.
     *
     * @param contrato objeto Contrato con todos los campos llenos EXCEPTO
     *                 fecha_fin (este método la calcula).
     * @return Resultado con isExitoso() y getMensaje()
     */
    public Resultado crearContrato(Contrato contrato) {

        // ── Validar datos mínimos ────────────────────────────────────────────
        if (contrato.getCliente()     == null) return Resultado.error("Cliente requerido.");
        if (contrato.getMembresia()   == null) return Resultado.error("Membresía requerida.");
        if (contrato.getMetodoPago()  == null) return Resultado.error("Método de pago requerido.");
        if (contrato.getFechaInicio() == null) return Resultado.error("Fecha de inicio requerida.");
        if (contrato.getMontoPagado() == null) return Resultado.error("Monto pagado requerido.");

        String clienteId = contrato.getCliente().getId();

        // ── Verificar contrato activo existente (RF-04) ──────────────────────
        try {
            Contrato activo = contratoDAO.findActiveByClienteId(clienteId);
            if (activo != null) {
                return Resultado.error(
                        "El cliente ya tiene un contrato activo que vence el "
                        + activo.getFechaFin()
                        + ". Debe cancelarlo antes de crear uno nuevo.");
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al verificar contrato activo", e);
            return Resultado.error("Error interno. Intenta nuevamente.");
        }

        // ── Calcular fecha_fin ───────────────────────────────────────────────
        Membresia mem = contrato.getMembresia();
        LocalDate fechaFin = contrato.getFechaInicio().plusMonths(mem.getDuracionMeses());
        contrato.setFechaFin(fechaFin);

        // ── Guardar en BD (con transacción correcta) ─────────────────────────
        try {
            /*
             * ← CORRECCIÓN CRÍTICA:
             * beginTransaction() pone autoCommit=false en la Connection del ThreadLocal.
             * getConnection() devuelve esa misma Connection.
             * Se pasa al DAO para que el INSERT use la misma unidad de trabajo.
             */
            DatabaseConnection.beginTransaction();
            Connection txCon = DatabaseConnection.getConnection();
            contratoDAO.save(txCon, contrato);
            DatabaseConnection.commit();

            LOGGER.info("Contrato creado para cliente: " + clienteId
                    + " | membresía: " + mem.getId()
                    + " | vence: " + fechaFin);

            return Resultado.ok("Contrato registrado exitosamente. Vence el " + fechaFin + ".");

        } catch (SQLException e) {
            DatabaseConnection.rollback();
            LOGGER.log(Level.SEVERE, "Error al guardar contrato — rollback ejecutado", e);
            return Resultado.error("No se pudo guardar el contrato. Intenta nuevamente.");
        } finally {
            DatabaseConnection.closeConnection();
        }
    }

    // ── Cancelar contrato ────────────────────────────────────────────────────

    /**
     * Cancela un contrato activo (solo permitido para Administrador según RF-03).
     * Cambia el estado a 'cancelado'.
     *
     * @param contratoId el ID del contrato a cancelar
     * @return Resultado con isExitoso() y getMensaje()
     */
    public Resultado cancelarContrato(String contratoId) {
        if (contratoId == null || contratoId.trim().isEmpty()) {
            return Resultado.error("ID de contrato inválido.");
        }

        try {
            boolean ok = contratoDAO.cancelar(contratoId, AppConfig.CONTRATO_CANCELADO);
            if (ok) {
                LOGGER.info("Contrato cancelado: " + contratoId);
                return Resultado.ok("Contrato cancelado correctamente.");
            } else {
                return Resultado.error(
                        "No se encontró el contrato o ya estaba cancelado/vencido.");
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al cancelar contrato: " + contratoId, e);
            return Resultado.error("Error interno al cancelar el contrato.");
        }
    }

    // ── Verificar vencimientos ───────────────────────────────────────────────

    /**
     * Actualiza en la BD los contratos cuya fecha_fin ya pasó,
     * cambiando su estado de 'activo' a 'vencido'.
     *
     * @return número de contratos actualizados
     */
    public int actualizarVencidos() {
        try {
            int actualizados = contratoDAO.marcarVencidos(
                    LocalDate.now(),
                    AppConfig.CONTRATO_ACTIVO,
                    AppConfig.CONTRATO_VENCIDO
            );
            if (actualizados > 0) {
                LOGGER.info("Contratos marcados como vencidos: " + actualizados);
            }
            return actualizados;
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al actualizar contratos vencidos", e);
            return 0;
        }
    }
}