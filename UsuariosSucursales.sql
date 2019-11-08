-- -----------------------------------------------/ ALTA USUARIO SUCURSAL /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_asignar_usuario_sucursal`;
DELIMITER $$
CREATE PROCEDURE `tsp_asignar_usuario_sucursal`(pIdSucursal int, pIdUsuario int)
SALIR: BEGIN
	/*
	Permite dar de alta un registro de leche de una sucursal.
    Controlando que solo se pueda anotar una registracion por dia en una sucursal
    Devuelve OK+Id o el mensaje de error en Mensaje.
	*/
    DECLARE pMensaje varchar(100);
    DECLARE pNroUsuarioSucursal int;
    DECLARE pIdTambo int;
    	-- Manejo de error en la transacción
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		-- SHOW ERRORS;
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
	END;
    -- Controla Parámetros Vacios
    IF (pIdSucursal IS NULL OR pIdSucursal = 0) THEN
        SELECT 'Debe indicar la Sucursal.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pIdUsuario IS NULL OR pIdUsuario = 0) THEN
        SELECT 'Debe indicar el Usuario.' Mensaje;
        LEAVE SALIR;
	END IF;
    -- Controla Parámetros Incorrectos
    IF NOT EXISTS(SELECT IdSucursal FROM Sucursales WHERE IdSucursal = pIdSucursal) THEN
        SELECT 'La Sucursal indicada no existe.' Mensaje;
        LEAVE SALIR;
	END IF;
    SET pIdTambo = (SELECT IdTambo FROM Sucursales WHERE IdSucursal = pIdSucursal);
    IF NOT EXISTS(SELECT IdUsuario FROM Usuarios WHERE IdUsuario = pIdUsuario AND Estado = 'A' AND IdTambo = pIdTambo) THEN
        SELECT 'El Usuario indicada no es valido.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF EXISTS(SELECT NroUsuarioSucursal FROM UsuariosSucursales
    WHERE IdUsuario = pIdUsuario AND IdSucursal = pIdSucursal AND FechaHasta IS NULL) THEN
        SELECT 'El Usuario ya se encuentra asignado a la Sucursal.' Mensaje;
        LEAVE SALIR;
	END IF;
    START TRANSACTION;
        -- Insercion
        SET pNroUsuarioSucursal = (SELECT COALESCE(MAX(NroUsuarioSucursal), 0)+1 
        FROM UsuariosSucursales WHERE IdSucursal = pIdSucursal AND IdUsuario = pIdUsuario);

        INSERT INTO UsuariosSucursales
        SELECT pNroUsuarioSucursal, pIdUsuario, pIdSucursal, NOW(), NULL;

        SELECT CONCAT ('OK', pNroUsuarioSucursal) Mensaje;
	COMMIT;
END$$
DELIMITER ;

-- -----------------------------------------------/ DESASIGNAR USUARIO SUCURSAL /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_desasignar_usuario_sucursal` ; 
DELIMITER $$
CREATE PROCEDURE `tsp_desasignar_usuario_sucursal`(pIdSucursal int, pIdUsuario int)
SALIR: BEGIN
	/*
	Permite borrar un registro de leche.
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

    -- Control de Parámetros Vacios
    IF (pIdSucursal IS NULL OR pIdSucursal = 0) THEN
        SELECT 'Debe indicar la Sucursal.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pIdUsuario IS NULL OR pIdUsuario = 0) THEN
        SELECT 'Debe indicar el Usuario.' Mensaje;
        LEAVE SALIR;
	END IF;
    -- Controla Parámetros Incorrectos
    IF NOT EXISTS(SELECT NroUsuarioSucursal FROM UsuariosSucursales
    WHERE IdUsuario = pIdUsuario AND IdSucursal = pIdSucursal AND FechaHasta IS NULL) THEN
        SELECT 'El Usuario no se encuentra asignado a la Sucursal.' Mensaje;
        LEAVE SALIR;
	END IF;
    START TRANSACTION;

        -- Modifico los usuarios anterios
        UPDATE  UsuariosSucursales
        SET     FechaHasta = NOW()
        WHERE IdUsuario = pIdUsuario AND IdSucursal = pIdSucursal AND FechaHasta IS NULL;

        SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;