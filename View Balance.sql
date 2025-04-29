CREATE VIEW VW_Movimientos AS
SELECT 
    m.Fecha, 
    a.Descripcion AS DescripcionAluminio,
    t.Descripcion AS DescripcionMovimiento,
    m.Cantidad,
    d.Descripcion AS DepositoDesde, 
    h.Descripcion AS DepositoHacia,
    m.Observaciones,
    m.Estado
FROM movimientos m
LEFT JOIN aluminio a ON a.Id = m.IdAluminio
LEFT JOIN depositos d ON d.Id = m.Desde
LEFT JOIN depositos h ON h.Id = m.Hacia
LEFT JOIN tiposMovimiento t ON t.Id = m.IdTipoMovimiento;

