-- -----------------------------------------------/ ALTA PAGO /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_alta_pago`;
DELIMITER $$
CREATE PROCEDURE `tsp_alta_pago`(pIdVenta bigint, pTipoComp varchar(10), pNroComp varchar(30), pMonto decimal(12,2))
SALIR: BEGIN
	/*
	Permite dar de alta un nuevo Pago de una Venta, siempre que la venta se encuentre activa y no este pagada ya.
    Devuelve OK+Id o el mensaje de error en Mensaje.
	*/
    DECLARE pMensaje varchar(100);
    DECLARE pNroPago tinyint;
    -- Manejo de error en la transacción
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		-- SHOW ERRORS;
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
	END;
    -- Controla Parámetros Vacios
    IF (pIdVenta IS NULL OR pIdVenta = 0) THEN
        SELECT 'Debe indicar la venta.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pTipoComp IS NULL OR pTipoComp = '') THEN
        SELECT 'Debe indicar el tipo de comprobante.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pNroComp IS NULL OR pNroComp = '') THEN
        SELECT 'Debe indicar el numero del comprobante.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pMonto IS NULL OR pMonto <= 0) THEN
        SELECT 'Debe indicar el monto del pago.' Mensaje;
        LEAVE SALIR;
	END IF;
    -- Controla Parametros Incorrectos
    IF NOT EXISTS(SELECT IdVenta FROM Ventas WHERE IdVenta = pIdVenta AND Estado = 'A') THEN
        SELECT 'La Venta indicada no es valida.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF ( (SELECT COALESCE(MAX(IdVenta), 0) + 1 FROM Ventas) > (SELECT NroPagos FROM Ventas WHERE IdVenta = pIdVenta) ) THEN
		SELECT 'Ya se alcanzo el numero de Pagos.' Mensaje;
		LEAVE SALIR;
	END IF;

    START TRANSACTION;
        SET pNroPago = (SELECT COALESCE(MAX(NroPago), 0)+1 FROM Ventas);

        -- Modifico en monto pagado de la venta
        UPDATE  Ventas
        SET     MontoPagar = MontoPagar + pMonto
        WHERE   IdVenta = pIdVenta;

        -- Alta Pago
	    INSERT INTO Pagos
        SELECT pIdVenta, pNroPago, pTipoComp, pNroComp, pMonto, NOW(), 'A';

        SELECT CONCAT ('OK', pNroPago) Mensaje;
	COMMIT;
END$$
DELIMITER ;

-- -----------------------------------------------/ MODIFICAR PAGO /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_modificar_pago`; 
DELIMITER $$
CREATE PROCEDURE `tsp_modificar_pago`(pIdVenta bigint, pNroPago tinyint, pTipoComp varchar(10), pNroComp varchar(30), pMonto decimal(12,2))
SALIR: BEGIN
    /*
    Permite modificar los datos de un Pago.
    Devuelve OK o el mensaje de error en Mensaje.
    */
    DECLARE pMensaje varchar(100);
    DECLARE pMontoAntiguo decimal(12,2);
    -- Manejo de error en la transacción
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		-- SHOW ERRORS;
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
	END;
    -- Controla Parámetros Vacios
    IF (pIdVenta IS NULL OR pIdVenta = 0 OR pNroPago IS NULL OR pNroPago = 0) THEN
        SELECT 'Debe indicar el pago.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pTipoComp IS NULL OR pTipoComp = '') THEN
        SELECT 'Debe indicar el tipo de comprobante.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pNroComp IS NULL OR pNroComp = '') THEN
        SELECT 'Debe indicar el numero del comprobante.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pMonto IS NULL OR pMonto <= 0) THEN
        SELECT 'Debe indicar el monto del pago.' Mensaje;
        LEAVE SALIR;
	END IF;
    -- Control de Parámetros incorrectos
    IF NOT EXISTS(SELECT IdVenta, NroPago FROM Pagos WHERE IdVenta = pIdVenta AND NroPago = pNroPago AND Estado = 'A') THEN
        SELECT 'El Pago indicado no es valido.' Mensaje;
        LEAVE SALIR;
	END IF;

	START TRANSACTION;
        SET pMontoAntiguo = (SELECT Monto FROM Pagos WHERE IdVenta = pIdVenta AND NroPago = pNroPago);
        IF (pMontoAntiguo != pMonto) THEN
            -- Modifico en monto pagado de la venta
            UPDATE  Ventas
            SET     MontoPagar = MontoPagar - pMontoAntiguo + pMonto 
            WHERE   IdVenta = pIdVenta;
        END IF;

        -- Modifico Pago
		UPDATE  Pagos
		SET     TipoComp = pTipoComp,
                NroComp = pNroComp,
                Monto = pMonto
		WHERE   IdVenta = pIdVenta AND NroPago = pNroPago;

        SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;

-- -----------------------------------------------/ BORRAR PAGO /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_borrar_pago` ; 
DELIMITER $$
CREATE PROCEDURE `tsp_borrar_pago`(pIdVenta bigint, pNroPago tinyint)
SALIR: BEGIN
	/*
	Permite borrar un pago.
    Devuelve OK o un mensaje de error en Mensaje.
	*/
    DECLARE pMensaje varchar(100);
	-- Manejo de error en la transacción
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		-- SHOW ERRORS;
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
	END;
    -- Control de Parametros Vacios
    IF (pIdVenta IS NULL OR pIdVenta = 0 OR pNroPago IS NULL OR pNroPago = 0) THEN
        SELECT 'Debe indicar el pago.' Mensaje;
        LEAVE SALIR;
	END IF;
    -- Control de Parámetros incorrectos
    IF NOT EXISTS(SELECT IdVenta, NroPago FROM Pagos WHERE IdVenta = pIdVenta AND NroPago = pNroPago AND Estado = 'A') THEN
        SELECT 'El Pago indicado no es valido.' Mensaje;
        LEAVE SALIR;
	END IF;

    START TRANSACTION;
        -- Modifico en monto pagado de la venta
        UPDATE  Ventas
        SET     MontoPagar = MontoPagar - (SELECT Monto FROM Pagos WHERE IdVenta = pIdVenta AND NroPago = pNroPago ) 
        WHERE   IdVenta = pIdVenta;

        -- Borra Pago
        DELETE FROM Pagos
        WHERE IdVenta = pIdVenta AND NroPago = pNroPago;

        SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;

-- -----------------------------------------------/ DAME PAGO /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_dame_pago`;
DELIMITER $$
CREATE PROCEDURE `tsp_dame_pago`(pIdVenta bigint, pNroPago tinyint)
SALIR: BEGIN
	/*
    Procedimiento que sirve para instanciar un Pago desde la base de datos.
    */
	SELECT	p.*
    FROM	Pagos p
    WHERE p.IdVenta = pIdVenta AND p.NroPago = pNroPago;
END$$
DELIMITER ;

-- -----------------------------------------------/ BUSCAR PAGOS /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_buscar_pagos`;
DELIMITER $$
CREATE PROCEDURE `tsp_buscar_pagos`(pIdVenta bigint, pFechaInicio date, pFechaFin date, pIncluyeBajas char(1))
SALIR: BEGIN
	/*
	Permite buscar Pagos de una venta, pudiendo filtrar por fecha.
	*/
    IF (pFechaInicio IS NOT NULL AND pFechaFin IS NOT NULL) THEN
        SELECT	p.*
        FROM	Pagos p
        WHERE   (p.IdVenta = pIdVenta)
                AND ( p.Estado = 'A' OR pIncluyeBajas = 'S' )
                AND ( p.Fecha BETWEEN pFechaInicio AND pFechaFin )
        ORDER BY p.Fecha DESC;
    ELSE
        SELECT	p.*
        FROM	Pagos p
        WHERE   (p.IdVenta = pIdVenta)
                AND ( p.Estado = 'A' OR pIncluyeBajas = 'S' )
        ORDER BY p.Fecha DESC;
    END IF;
END$$
DELIMITER ;