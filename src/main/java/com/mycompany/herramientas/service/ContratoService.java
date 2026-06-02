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

// reglas de negocio para contratos (RF-03, RF-04)
public class ContratoService {

    private static final Logger LOGGER = Logger.getLogger(ContratoService.class.getName());

    private final ContratoDAO contratoDAO;

    public ContratoService() {
        this.contratoDAO = new ContratoDAO();
    }

    public ContratoService(ContratoDAO contratoDAO) {
        this.contratoDAO = contratoDAO;
    }

    // ─── RESULTADO ─────────────────────────────────────────────

    public static final class Resultado {

        private final boolean exitoso;
        private final String mensaje;

        private Resultado(boolean exitoso, String mensaje) {
            this.exitoso = exitoso;
            this.mensaje = mensaje;
        }

        public boolean isExitoso() { return exitoso; }
        public String getMensaje() { return mensaje; }

        public static Resultado ok(String mensaje) {
            return new Resultado(true, mensaje);
        }

        public static Resultado error(String mensaje) {
            return new Resultado(false, mensaje);
        }
    }

    // ─── CREAR CONTRATO ───────────────────────────────────────

    public Resultado crearContrato(Contrato contrato) {

        // validar datos mínimos
        if (contrato.getCliente() == null) return Resultado.error("Cliente requerido.");
        if (contrato.getMembresia() == null) return Resultado.error("Membresía requerida.");
        if (contrato.getMetodoPago() == null) return Resultado.error("Método de pago requerido.");
        if (contrato.getFechaInicio() == null) return Resultado.error("Fecha inicio requerida.");
        if (contrato.getMontoPagado() == null) return Resultado.error("Monto requerido.");

        String clienteId = contrato.getCliente().getId();

        // verificar contrato activo
        try {

            Contrato activo = contratoDAO.findActiveByClienteId(clienteId);

            if (activo != null) {
                return Resultado.error(
                        "Cliente ya tiene contrato activo hasta " + activo.getFechaFin());
            }

        } catch (SQLException e) {

            LOGGER.log(Level.SEVERE, "Error verificando contrato activo", e);
            return Resultado.error("Error interno.");
        }

        // calcular fecha fin
        Membresia mem = contrato.getMembresia();

        LocalDate fechaFin = contrato.getFechaInicio()
                .plusMonths(mem.getDuracionMeses());

        contrato.setId(com.mycompany.herramientas.dao.IdGenerator.parContrato());
        contrato.setFechaFin(fechaFin);

        // guardar contrato (transacción)
        try {

            DatabaseConnection.beginTransaction();
            Connection txCon = DatabaseConnection.getConnection();

            contratoDAO.save(txCon, contrato);

            DatabaseConnection.commit();

            LOGGER.info("Contrato creado: " + clienteId + " vence " + fechaFin);

            return Resultado.ok("Contrato creado. Vence el " + fechaFin);

        } catch (SQLException e) {

            DatabaseConnection.rollback();
            LOGGER.log(Level.SEVERE, "Error creando contrato", e);

            return Resultado.error("No se pudo crear contrato.");

        } finally {

            DatabaseConnection.closeConnection();
        }
    }

    // ─── CANCELAR CONTRATO ────────────────────────────────────

    public Resultado cancelarContrato(String contratoId) {

        if (contratoId == null || contratoId.trim().isEmpty()) {
            return Resultado.error("ID inválido.");
        }

        try {

            boolean ok = contratoDAO.cancelar(contratoId, AppConfig.CONTRATO_CANCELADO);

            if (ok) {
                LOGGER.info("Contrato cancelado: " + contratoId);
                return Resultado.ok("Contrato cancelado.");
            }

            return Resultado.error("Contrato no encontrado.");

        } catch (SQLException e) {

            LOGGER.log(Level.SEVERE, "Error cancelando contrato", e);
            return Resultado.error("Error interno.");
        }
    }

    // ─── VENCIMIENTOS ─────────────────────────────────────────

    public int actualizarVencidos() {

        try {

            int n = contratoDAO.marcarVencidos(
                    LocalDate.now(),
                    AppConfig.CONTRATO_ACTIVO,
                    AppConfig.CONTRATO_VENCIDO
            );

            if (n > 0) {
                LOGGER.info("Contratos vencidos: " + n);
            }

            return n;

        } catch (SQLException e) {

            LOGGER.log(Level.WARNING, "Error vencimientos", e);
            return 0;
        }
    }
}