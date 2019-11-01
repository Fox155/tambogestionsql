-- -----------------------------------------------/ ALTA VENTA /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_alta_venta`;
DELIMITER $$
CREATE PROCEDURE `tsp_alta_venta`(pIdCliente int, pIdSucursal int, pMontoPres decimal(10,2), pNroPagos tinyint, pLitros decimal(12,2), pDatos json, pObservaciones text)
SALIR: BEGIN
	/*
	Permite dar de alta una nueva Venta, siempre que la sucursal tenga la cantidad necesaria.
    Devuelve OK+Id o el mensaje de error en Mensaje.
	*/
    DECLARE pMensaje varchar(100);
    DECLARE pIdVenta bigint;
    -- Manejo de error en la transacción
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		-- SHOW ERRORS;
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
	END;
    -- Controla Parámetros Vacios
    IF (pIdCliente IS NULL OR pIdCliente = 0) THEN
        SELECT 'Debe indicar el cliente.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pIdSucursal IS NULL OR pIdSucursal = 0) THEN
        SELECT 'Debe indicar la sucursal.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pMontoPres IS NULL OR pMontoPres <= 0) THEN
        SELECT 'Debe indicar la moonto presupuestado.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pNroPagos IS NULL OR pNroPagos <= 0) THEN
        SELECT 'Debe indicar el numero de pagos.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (Litros IS NULL OR Litros <= 0) THEN
        SELECT 'Debe indicar los litros de la venta.' Mensaje;
        LEAVE SALIR;
	END IF;
    -- Controla Parametros Incorrectos
    IF NOT EXISTS(SELECT IdCliente FROM Clientes WHERE IdCliente = pIdCliente AND Estado = 'A') THEN
        SELECT 'El Cliente indicado no existe.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF NOT EXISTS(SELECT IdSucursal FROM Sucursales WHERE IdSucursal = pIdSucursal) THEN
        SELECT 'La Sucursal indicada no existe.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF ( (SELECT Leche FROM Sucursales WHERE IdSucursal = pIdSucursal) < pLitros) THEN
		SELECT 'La Sucursal no cuenta con los litros de leche suficientes.' Mensaje;
		LEAVE SALIR;
	END IF;

    START TRANSACTION;
        SET pIdVenta = (SELECT COALESCE(MAX(IdVenta), 0)+1 FROM Ventas);

        -- Modifico los litros con los que cuenta la sucursal
        UPDATE  Sucursales
        SET     Litros = Litros - pLitros
        WHERE   IdSucursal = pIdSucursal;

        -- Alta de nueva venta
	    INSERT INTO Ventas
        SELECT pIdVenta, pIdSucursal, pIdCliente, pMontoPres, 0, pNroPagos, pLitros, NOW(), 'A', pDatos, pObservaciones;

        SELECT CONCAT ('OK', pIdCliente) Mensaje;
	COMMIT;
END$$
DELIMITER ;
-- -----------------------------------------------/ MODIFICAR VENTA/----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_modificar_venta`; 
DELIMITER $$
CREATE PROCEDURE `tsp_modificar_venta`(pIdVenta bigint, pIdCliente int, pMontoPres decimal(10,2), pNroPagos tinyint, pLitros decimal(12,2), pDatos json, pObservaciones text)
SALIR: BEGIN
/*
    Permite modificar los datos de una Venta.
    Devuelve OK o el mensaje de error en Mensaje.
*/
DECLARE pMensaje varchar(100);
DECLARE pIdSucursal int;
DECLARE pLitrosAntiguos decimal(12,2);
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
    IF (pIdCliente IS NULL OR pIdCliente = 0) THEN
        SELECT 'Debe indicar el cliente.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pMontoPres IS NULL OR pMontoPres <= 0) THEN
        SELECT 'Debe indicar la moonto presupuestado.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pNroPagos IS NULL OR pNroPagos <= 0) THEN
        SELECT 'Debe indicar el numero de pagos.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (Litros IS NULL OR Litros <= 0) THEN
        SELECT 'Debe indicar los litros de la venta.' Mensaje;
        LEAVE SALIR;
	END IF;
    -- Control de Parámetros incorrectos
    IF NOT EXISTS(SELECT IdCliente FROM Clientes WHERE IdCliente = pIdCliente AND Estado = 'A') THEN
        SELECT 'El Cliente indicado no existe.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF NOT EXISTS(SELECT IdVenta FROM Ventas WHERE IdVenta = pIdVenta AND Estado = 'A') THEN
        SELECT 'La Venta indicada no existe.' Mensaje;
        LEAVE SALIR;
	END IF;
    SET pLitrosAntiguos = (SELECT Litros FROM Ventas WHERE IdVenta = pIdVenta);
    IF (pLitrosAntiguos != pLitros) THEN
        IF ( (SELECT Leche FROM Sucursales WHERE IdSucursal = pIdSucursal) + pLitrosAntiguos < pLitros) THEN
            SELECT 'La Sucursal no cuenta con los litros de leche suficientes.' Mensaje;
            LEAVE SALIR;
        END IF;
    END IF;

	START TRANSACTION;
        IF (pLitrosAntiguos != pLitros) THEN
            -- Modifico los litros con los que cuenta la sucursal
            UPDATE  Sucursales
            SET     Litros = Litros + pLitrosAntiguos - pLitros 
            WHERE   IdSucursal = pIdSucursal;
        END IF;

        -- Modifico la venta
		UPDATE  Ventas
		SET     IdCliente = pIdCliente,
                MontoPres = pMontoPres,
                NroPagos = pNroPagos,
                Litros = pLitros,
                Datos = pDatos,
                Observaciones = pObservaciones
		WHERE   IdCliente = pIdCliente;

        SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;

-- -----------------------------------------------/ BORRAR VENTA /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_borrar_venta` ; 
DELIMITER $$
CREATE PROCEDURE `tsp_borrar_venta`(pIdVenta bigint)
SALIR: BEGIN
	/*
	Permite borrar una venta controlando que no tenga pagos asociados.
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
    IF (pIdVenta IS NULL OR pIdVenta = 0 ) THEN
        SELECT 'Debe indicar la venta.' Mensaje;
        LEAVE SALIR;
	END IF;
    -- Control de Parametros Incorrectos
    IF EXISTS (SELECT IdVenta FROM Pagos WHERE IdVenta = pIdVenta) THEN
        SELECT 'La Venta indicada no se puede borrar, tiene pagos asociados.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF NOT EXISTS(SELECT IdVenta FROM Ventas WHERE IdVenta = pIdVenta AND Estado = 'A') THEN
        SELECT 'La Venta indicada no existe.' Mensaje;
        LEAVE SALIR;
	END IF;

    START TRANSACTION;
        -- Modifico los litros con los que cuenta la sucursal
            UPDATE  Sucursales
        SET     Litros = Litros + (SELECT Litros FROM Ventas WHERE IdVenta = pIdVenta)
        WHERE   IdSucursal = (SELECT IdSucursal FROM Ventas WHERE IdVenta = pIdVenta);

        -- Borra 
        DELETE FROM Ventas
        WHERE IdVenta = pIdVenta;

        SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;

-- -----------------------------------------------/ DAME VENTA /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_dame_venta`;
DELIMITER $$
CREATE PROCEDURE `tsp_dame_venta`(pIdVenta bigint)
SALIR: BEGIN
	/*
    Procedimiento que sirve para instanciar una Venta desde la base de datos.
    */
	SELECT	*
    FROM	Ventas
    WHERE	IdVenta = pIdVenta;
END$$
DELIMITER ;

-- -----------------------------------------------/ BUSCAR VENTAS /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_buscar_ventas`;
DELIMITER $$
CREATE PROCEDURE `tsp_buscar_ventas`(pIdSucursal int, pCadena varchar(45), pIncluyeBajas char(1))
SALIR: BEGIN
	/*
	Permite buscar Ventas dentro de una sucursal, indicando una cadena de búsqueda.
	*/
    SELECT  v.*
    FROM    Ventas v
    INNER JOIN ListasPrecio lp
    WHERE   ( v.Litros LIKE CONCAT('%', pCadena, '%') )
            AND ( v.IdSucursal = pIdSucursal )
            AND ( v.Estado = 'A' OR pIncluyeBajas = 'S' );
END$$
DELIMITER ;

-- -----------------------------------------------/ DAR DE BAJA VENTA /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_darbaja_venta`; 
DELIMITER $$
CREATE PROCEDURE `tsp_darbaja_venta`(pIdVenta bigint)
SALIR: BEGIN
    /*
    Permite dar de baja una venta, controlando que no este dado de baja ya.
    Devuelve OK o el mensaje de error en Mensaje.
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
    IF (pIdVenta IS NULL OR pIdVenta = 0 ) THEN
        SELECT 'Debe indicar la venta.' Mensaje;
        LEAVE SALIR;
	END IF;
    -- Control de Parametros Incorrectos
    IF EXISTS (SELECT IdVenta FROM Pagos WHERE IdVenta = pIdVenta AND Estado = 'A') THEN
        SELECT 'La Venta indicada no se puede borrar, tiene pagos activos asociados.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF NOT EXISTS(SELECT IdVenta FROM Ventas WHERE IdVenta = pIdVenta AND Estado = 'A') THEN
        SELECT 'La Venta indicada no existe.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF NOT EXISTS(SELECT IdVenta FROM Ventas WHERE IdVenta = pIdVenta  AND Estado = 'B') THEN
		SELECT 'La Venta ya se encuentra dada de baja.' Mensaje;
		LEAVE SALIR;
	END IF;
    START TRANSACTION;
        -- Modifico los litros con los que cuenta la sucursal
        UPDATE  Sucursales
        SET     Litros = Litros + (SELECT Litros FROM Ventas WHERE IdVenta = pIdVenta)
        WHERE   IdSucursal = (SELECT IdSucursal FROM Ventas WHERE IdVenta = pIdVenta);

        -- Da de Baja
        UPDATE  Ventas
        SET  Estado = 'B'
        WHERE IdVenta = pIdVenta ;

        SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;

-- -----------------------------------------------/ ACTIVAR VENTA /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_activar_venta`; 
DELIMITER $$
CREATE PROCEDURE `tsp_activar_venta`(pIdVenta bigint)
SALIR: BEGIN
    /*
    Permite dar de baja una venta, controlando que no este activa.
    Devuelve OK o el mensaje de error en Mensaje.
    */
    DECLARE pMensaje varchar(100);
    -- Manejo de error en la transacción
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		-- SHOW ERRORS;
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
	END;
    -- Control de Parámetros incorrectos
    IF NOT EXISTS(SELECT IdVenta FROM Clientes WHERE IdVenta = pIdVenta  AND Estado = 'A') THEN
		SELECT 'La Venta ya se encuentra activa.' Mensaje;
		LEAVE SALIR;
	END IF;
    START TRANSACTION; 

        -- Activa
        UPDATE  Ventas
        SET  Estado = 'A'
        WHERE IdVenta = pIdVenta ;

        SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;