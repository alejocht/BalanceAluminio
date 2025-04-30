
INSERT INTO aluminio (Codigo, Descripcion, PesoXMetro, Observacion)
VALUES 
('110X25', 'Tubo aluminio 110x25 mm', 1.14, ''),
('75x25', 'Tubo aluminio 75x25 mm', 0.89,'');

INSERT INTO tiposMovimiento (Codigo, Descripcion)
VALUES 
('ING', 'Ingreso a fábrica'),
('CONS', 'Consumo en producción'),
('MOV', 'Movimiento entre depósitos');

INSERT INTO depositos (Codigo, Descripcion)
VALUES 
('FAB', 'Fábrica'),
('GUTY', 'Guty'),
('TDA', 'TDA');

-- Ingreso a fábrica (100 kg)
INSERT INTO movimientos (Fecha, IdAluminio, IdTipoMovimiento, Cantidad, Desde, Hacia, Observaciones)
VALUES 
(GETDATE(), 1, 1, 100.00, NULL, 1, 'Ingreso inicial a fábrica'); -- ING: hacia DEP-FAB (Id=1)

-- Movimiento de fábrica a Guty (30 kg)
INSERT INTO movimientos (Fecha, IdAluminio, IdTipoMovimiento, Cantidad, Desde, Hacia, Observaciones)
VALUES 
(GETDATE(), 1, 3, 30.00, 1, 2, 'Traslado a Guty'); -- MOV: de DEP-FAB (1) a DEP-AUX1 (2)

-- Consumo desde Fabrica (10 kg)
INSERT INTO movimientos (Fecha, IdAluminio, IdTipoMovimiento, Cantidad, Desde, Hacia, Observaciones)
VALUES 
(GETDATE(), 1, 2, 10.00, 1, NULL, 'Consumo del Dia'); -- CON: desde DEP-AUX1 (2)



