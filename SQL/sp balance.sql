use balance_aluminio_mike_bd;
go

CREATE PROCEDURE sp_InsertarAluminio
    @Codigo VARCHAR(50),
    @Descripcion VARCHAR(200),
    @PesoXMetro DECIMAL(10,2),
    @Observacion VARCHAR(255),
    @Estado BIT = 1
AS
BEGIN
    INSERT INTO aluminio (Codigo, Descripcion, PesoXMetro, Observacion, Estado)
    VALUES (@Codigo, @Descripcion, @PesoXMetro, @Observacion, @Estado);
END;

go

CREATE PROCEDURE sp_InsertarTipoMovimiento
    @Codigo VARCHAR(50),
    @Descripcion VARCHAR(200),
    @Estado BIT = 1
AS
BEGIN
    INSERT INTO tiposMovimiento (Codigo, Descripcion, Estado)
    VALUES (@Codigo, @Descripcion, @Estado);
END;

go

CREATE PROCEDURE sp_InsertarDeposito
    @Codigo VARCHAR(50),
    @Descripcion VARCHAR(200),
    @Estado BIT = 1
AS
BEGIN
    INSERT INTO depositos (Codigo, Descripcion, Estado)
    VALUES (@Codigo, @Descripcion, @Estado);
END;

go

CREATE PROCEDURE sp_InsertarMovimiento
    @Fecha DATE,
    @IdAluminio INT,
    @IdTipoMovimiento INT,
    @Cantidad DECIMAL(10,2),
    @Desde INT = NULL,
    @Hacia INT = NULL,
    @Observaciones VARCHAR(250) = NULL
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
			INSERT INTO movimientos (Fecha, IdAluminio, IdTipoMovimiento, Cantidad, Desde, Hacia, Observaciones)
			VALUES (@Fecha, @IdAluminio, @IdTipoMovimiento, @Cantidad, @Desde, @Hacia, @Observaciones);	
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
	END CATCH
END;

go

CREATE PROCEDURE sp_InsertarStockDeposito
    @IdDeposito INT,
    @IdAluminio INT,
    @Cantidad DECIMAL(10,2) = 0
AS
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM stock_x_deposito
        WHERE IdDeposito = @IdDeposito AND IdAluminio = @IdAluminio
    )
    BEGIN
        INSERT INTO stock_x_deposito (IdDeposito, IdAluminio, Cantidad)
        VALUES (@IdDeposito, @IdAluminio, @Cantidad);
    END
    ELSE
    BEGIN
        RAISERROR('Ya existe un registro para ese depósito y aluminio.', 16, 1);
    END
END;

CREATE TRIGGER trg_actualizar_stock_al_insertar
ON movimientos
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Ingreso (suma en Hacia)
    UPDATE s
    SET s.Cantidad = s.Cantidad + i.Cantidad
    FROM stock_x_deposito s
    JOIN inserted i ON s.IdDeposito = i.Hacia AND s.IdAluminio = i.IdAluminio
    JOIN tiposMovimiento tm ON tm.Id = i.IdTipoMovimiento
    WHERE tm.Codigo = 'ING';

    INSERT INTO stock_x_deposito (IdDeposito, IdAluminio, Cantidad)
    SELECT i.Hacia, i.IdAluminio, i.Cantidad
    FROM inserted i
    JOIN tiposMovimiento tm ON tm.Id = i.IdTipoMovimiento
    WHERE tm.Codigo = 'ING'
    AND NOT EXISTS (
        SELECT 1 FROM stock_x_deposito s
        WHERE s.IdDeposito = i.Hacia AND s.IdAluminio = i.IdAluminio
    );

    -- Consumo (resta en Desde)
    UPDATE s
    SET s.Cantidad = s.Cantidad - i.Cantidad
    FROM stock_x_deposito s
    JOIN inserted i ON s.IdDeposito = i.Desde AND s.IdAluminio = i.IdAluminio
    JOIN tiposMovimiento tm ON tm.Id = i.IdTipoMovimiento
    WHERE tm.Codigo = 'CON';

    -- Movimiento (resta en Desde, suma en Hacia)
    -- Resta en Desde
    UPDATE s
    SET s.Cantidad = s.Cantidad - i.Cantidad
    FROM stock_x_deposito s
    JOIN inserted i ON s.IdDeposito = i.Desde AND s.IdAluminio = i.IdAluminio
    JOIN tiposMovimiento tm ON tm.Id = i.IdTipoMovimiento
    WHERE tm.Codigo = 'MOV';

    -- Suma en Hacia
    UPDATE s
    SET s.Cantidad = s.Cantidad + i.Cantidad
    FROM stock_x_deposito s
    JOIN inserted i ON s.IdDeposito = i.Hacia AND s.IdAluminio = i.IdAluminio
    JOIN tiposMovimiento tm ON tm.Id = i.IdTipoMovimiento
    WHERE tm.Codigo = 'MOV';

    INSERT INTO stock_x_deposito (IdDeposito, IdAluminio, Cantidad)
    SELECT i.Hacia, i.IdAluminio, i.Cantidad
    FROM inserted i
    JOIN tiposMovimiento tm ON tm.Id = i.IdTipoMovimiento
    WHERE tm.Codigo = 'MOV'
    AND NOT EXISTS (
        SELECT 1 FROM stock_x_deposito s
        WHERE s.IdDeposito = i.Hacia AND s.IdAluminio = i.IdAluminio
    );
END;

CREATE OR ALTER TRIGGER trg_ajustar_stock_al_cambiar_estado
ON movimientos
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -------------------------------
    -- 1. Estado cambió de 1 ? 0
    -------------------------------
    -- Revertir stock
    UPDATE s
    SET s.Cantidad = s.Cantidad - i.Cantidad
    FROM stock_x_deposito s
    JOIN inserted i ON s.IdAluminio = i.IdAluminio
    JOIN deleted d ON d.Id = i.Id
    JOIN tiposMovimiento tm ON tm.Id = i.IdTipoMovimiento
    WHERE i.Estado = 0 AND d.Estado = 1 AND tm.Codigo = 'ING' AND s.IdDeposito = i.Hacia;

    UPDATE s
    SET s.Cantidad = s.Cantidad + i.Cantidad
    FROM stock_x_deposito s
    JOIN inserted i ON s.IdAluminio = i.IdAluminio
    JOIN deleted d ON d.Id = i.Id
    JOIN tiposMovimiento tm ON tm.Id = i.IdTipoMovimiento
    WHERE i.Estado = 0 AND d.Estado = 1 AND tm.Codigo = 'CON' AND s.IdDeposito = i.Desde;

    -- Movimiento: sumar en Desde, restar en Hacia
    UPDATE s
    SET s.Cantidad = s.Cantidad + i.Cantidad
    FROM stock_x_deposito s
    JOIN inserted i ON s.IdAluminio = i.IdAluminio
    JOIN deleted d ON d.Id = i.Id
    JOIN tiposMovimiento tm ON tm.Id = i.IdTipoMovimiento
    WHERE i.Estado = 0 AND d.Estado = 1 AND tm.Codigo = 'MOV' AND s.IdDeposito = i.Desde;

    UPDATE s
    SET s.Cantidad = s.Cantidad - i.Cantidad
    FROM stock_x_deposito s
    JOIN inserted i ON s.IdAluminio = i.IdAluminio
    JOIN deleted d ON d.Id = i.Id
    JOIN tiposMovimiento tm ON tm.Id = i.IdTipoMovimiento
    WHERE i.Estado = 0 AND d.Estado = 1 AND tm.Codigo = 'MOV' AND s.IdDeposito = i.Hacia;


    -------------------------------
    -- 2. Estado cambió de 0 ? 1
    -------------------------------
    -- Aplicar stock
    UPDATE s
    SET s.Cantidad = s.Cantidad + i.Cantidad
    FROM stock_x_deposito s
    JOIN inserted i ON s.IdAluminio = i.IdAluminio
    JOIN deleted d ON d.Id = i.Id
    JOIN tiposMovimiento tm ON tm.Id = i.IdTipoMovimiento
    WHERE i.Estado = 1 AND d.Estado = 0 AND tm.Codigo = 'ING' AND s.IdDeposito = i.Hacia;

    UPDATE s
    SET s.Cantidad = s.Cantidad - i.Cantidad
    FROM stock_x_deposito s
    JOIN inserted i ON s.IdAluminio = i.IdAluminio
    JOIN deleted d ON d.Id = i.Id
    JOIN tiposMovimiento tm ON tm.Id = i.IdTipoMovimiento
    WHERE i.Estado = 1 AND d.Estado = 0 AND tm.Codigo = 'CON' AND s.IdDeposito = i.Desde;

    -- Movimiento: restar en Desde, sumar en Hacia
    UPDATE s
    SET s.Cantidad = s.Cantidad - i.Cantidad
    FROM stock_x_deposito s
    JOIN inserted i ON s.IdAluminio = i.IdAluminio
    JOIN deleted d ON d.Id = i.Id
    JOIN tiposMovimiento tm ON tm.Id = i.IdTipoMovimiento
    WHERE i.Estado = 1 AND d.Estado = 0 AND tm.Codigo = 'MOV' AND s.IdDeposito = i.Desde;

    UPDATE s
    SET s.Cantidad = s.Cantidad + i.Cantidad
    FROM stock_x_deposito s
    JOIN inserted i ON s.IdAluminio = i.IdAluminio
    JOIN deleted d ON d.Id = i.Id
    JOIN tiposMovimiento tm ON tm.Id = i.IdTipoMovimiento
    WHERE i.Estado = 1 AND d.Estado = 0 AND tm.Codigo = 'MOV' AND s.IdDeposito = i.Hacia;
END;
 


