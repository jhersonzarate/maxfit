package com.mycompany.herramientas.service;

import com.mycompany.herramientas.config.AppConfig;
import com.mycompany.herramientas.config.DatabaseConnection;
import com.mycompany.herramientas.dao.ContratoDAO;
import com.mycompany.herramientas.model.Contrato;
import com.mycompany.herramientas.model.Membresia;

import java.sql.SQLException;
import java.time.LocalDate;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Reglas de negocio para contratos (RF-03, RF-04).
 *
 * CORRECCIÓN: cancelarContrato() ahora llama a contratoDAO.updateEstado()
 * que sí existe en ContratoDAO. El método cancelar() no existía → bug de compilación.
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

    // ── Resultado tipado ─────────────────────────────────────────────────────

    public static final class Resultado {
        private final boolean exitoso;
        private final String  mensaje;

        private Resultado(boolean exitoso, String mensaje) {
            this.exitoso = exitoso;
            this.mensaje = mensaje;
        }

        public boolean isExitoso() { return exitoso; }
        public String  getMensaje() { return mensaje; }

        public static Resultado ok(String mensaje)    { return new Resultado(true,  mensaje); }
        public static Resultado error(String mensaje) { return new Resultado(false, mensaje); }
    }

    // ── Crear contrato ───────────────────────────────────────────────────────

    /**
     * Crea un nuevo contrato aplicando todas las reglas de negocio (RF-03):
     *   1. Verifica que el cliente no tenga ya un contrato activo.
     *   2. Calcula fecha_fin = fecha_inicio + duracion_meses.
     *   3. Guarda en BD dentro de una transacción.
     *
     * @param contrato objeto con todos los campos excepto fecha_fin e id (se generan aquí).
     */
    public Resultado crearContrato(Contrato contrato) {

        // Validaciones mínimas
        if (contrato.getCliente()     == null) return Resultado.error("Cliente requerido.");
        if (contrato.getMembresia()   == null) return Resultado.error("Membresía requerida.");
        if (contrato.getMetodoPago()  == null) return Resultado.error("Método de pago requerido.");
        if (contrato.getEmpleado()    == null) return Resultado.error("Empleado responsable requerido.");
        if (contrato.getFechaInicio() == null) return Resultado.error("Fecha de inicio requerida.");
        if (contrato.getMontoPagado() == null) return Resultado.error("Monto pagado requerido.");

        String clienteId = contrato.getCliente().getId();

        // Verificar contrato activo existente (RF-04)
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

        // Calcular fecha_fin
        Membresia mem    = contrato.getMembresia();
        LocalDate fechaFin = contrato.getFechaInicio().plusMonths(mem.getDuracionMeses());
        contrato.setFechaFin(fechaFin);
        contrato.setEstado(AppConfig.CONTRATO_ACTIVO);

        // Guardar en BD con transacción
        try {
            DatabaseConnection.beginTransaction();
            contratoDAO.save(contrato);
            DatabaseConnection.commit();

            LOGGER.info("Contrato creado: cliente=" + clienteId
                    + " | membresía=" + mem.getId() + " | vence=" + fechaFin);

            return Resultado.ok("Contrato registrado exitosamente. Vence el " + fechaFin + ".");

        } catch (SQLException e) {
            DatabaseConnection.rollback();
            LOGGER.log(Level.SEVERE, "Error al guardar contrato — rollback", e);
            return Resultado.error("No se pudo guardar el contrato. Intenta nuevamente.");
        } finally {
            DatabaseConnection.closeConnection();
        }
    }

    // ── Cancelar contrato ────────────────────────────────────────────────────

    /**
     * Cancela un contrato activo (solo Administrador según RF-03).
     *
     * CORRECCIÓN del bug original: se usaba contratoDAO.cancelar() que no existe.
     * Ahora se usa contratoDAO.updateEstado() que sí está definido en ContratoDAO.
     *
     * @param contratoId ID del contrato a cancelar
     */
    public Resultado cancelarContrato(String contratoId) {
        if (contratoId == null || contratoId.trim().isEmpty()) {
            return Resultado.error("ID de contrato inválido.");
        }
        try {
            // ✅ FIX: updateEstado() existe en ContratoDAO; cancelar() no existía.
            boolean ok = contratoDAO.updateEstado(contratoId, AppConfig.CONTRATO_CANCELADO);
            if (ok) {
                LOGGER.info("Contrato cancelado: " + contratoId);
                return Resultado.ok("Contrato cancelado correctamente.");
            } else {
                return Resultado.error("No se encontró el contrato o ya estaba cancelado/vencido.");
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al cancelar contrato: " + contratoId, e);
            return Resultado.error("Error interno al cancelar el contrato.");
        }
    }

    // ── Listar contratos ─────────────────────────────────────────────────────

    /**
     * Todos los contratos — para la vista de gestión (RF-03).
     */
    public List<Contrato> listarTodos() {
        try {
            return contratoDAO.findAll();
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al listar contratos", e);
            return List.of();
        }
    }

    /**
     * Contratos de un cliente específico.
     */
    public List<Contrato> listarPorCliente(String clienteId) {
        try {
            return contratoDAO.findByClienteId(clienteId);
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al listar contratos del cliente: " + clienteId, e);
            return List.of();
        }
    }

    /**
     * Contrato activo y vigente de un cliente (para check-in).
     * Devuelve null si no tiene ninguno.
     */
    public Contrato obtenerContratoActivo(String clienteId) {
        try {
            return contratoDAO.findActiveByClienteId(clienteId);
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al obtener contrato activo: " + clienteId, e);
            return null;
        }
    }

    /**
     * Contratos activos próximos a vencer en N días — para el dashboard.
     */
    public List<Contrato> obtenerProximosAVencer(int dias) {
        try {
            return contratoDAO.findProximosAVencer(dias);
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al obtener contratos por vencer", e);
            return List.of();
        }
    }

    // ── Mantenimiento ────────────────────────────────────────────────────────

    /**
     * Actualiza en BD los contratos cuya fecha_fin ya pasó → estado 'vencido'.
     * Llamar al cargar el dashboard para mantener los estados sincronizados.
     *
     * @return número de contratos actualizados
     */
    public int actualizarVencidos() {
        try {
            int n = contratoDAO.marcarVencidos(
                    LocalDate.now(),
                    AppConfig.CONTRATO_ACTIVO,
                    AppConfig.CONTRATO_VENCIDO);
            if (n > 0) LOGGER.info("Contratos marcados como vencidos: " + n);
            return n;
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al actualizar contratos vencidos", e);
            return 0;
        }
    }
}