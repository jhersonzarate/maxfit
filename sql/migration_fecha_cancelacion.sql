-- ============================================================
-- Migración: fecha_cancelacion en Contratos
-- Necesaria para reconstruir el estado histórico de un contrato
-- (activo/vencido/cancelado) a una fecha pasada, usada por el
-- filtro de periodo (mensual/anual) del reporte de Contratos.
-- ============================================================

ALTER TABLE Contratos
    ADD fecha_cancelacion DATE NULL;

-- Nota: los contratos ya cancelados ANTES de esta migración quedan
-- con fecha_cancelacion = NULL (no hay forma de saber cuándo se
-- cancelaron). Para esos, la reconstrucción histórica los va a
-- clasificar como "vencido" o "activo" según sus fechas, no como
-- "cancelado" — es una limitación aceptada, documentada en el código.
-- Los contratos cancelados DE AQUÍ EN ADELANTE sí quedan con fecha
-- exacta y se reconstruyen correctamente.
