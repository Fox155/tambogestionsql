-- -----------------------------------------------/ ALTA REGISTRO DE LECHE /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_alta_registroleche`;
DELIMITER $$
CREATE PROCEDURE `tsp_alta_registroleche`(pIdSucursal int, pLitros decimal(12,2), pFecha date)
SALIR: BEGIN
	/*
	Permite dar de alta un registro de leche de una sucursal.
    Controlando que solo se pueda anotar una registracion por dia en una sucursal
    Devuelve OK+Id o el mensaje de error en Mensaje.
	*/
    DECLARE pMensaje varchar(100);
    DECLARE pIdRegistroLeche bigint;
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
    IF (pLitros IS NULL OR pLitros = 0) THEN
        SELECT 'Debe ingresar los litros de leche.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pFecha IS NULL) THEN
        SELECT 'Debe indicar la fecha del registro' Mensaje;
        LEAVE SALIR;
	END IF;
    -- Controla Parámetros Incorrectos
    IF NOT EXISTS(SELECT IdSucursal FROM Sucursales WHERE IdSucursal = pIdSucursal) THEN
        SELECT 'La Sucursal indicada no existe.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF EXISTS(SELECT Fecha FROM  RegistrosLeche WHERE IdSucursal= pIdSucursal and Fecha = pFecha) THEN
		SELECT 'Ya existe un registro para la Fecha indicada.' Mensaje;
		LEAVE SALIR;
	END IF;
    START TRANSACTION;
        -- Insercion
        SET pIdRegistroLeche = (SELECT COALESCE(MAX(IdRegistroLeche), 0)+1 FROM RegistrosLeche);

        INSERT INTO RegistrosLeche
        SELECT pIdSucursal, pIdRegistroLeche, pLitros, pFecha;

        -- Modifico los litros con los que cuenta la sucursal
        UPDATE  Sucursales
        SET     Litros = Litros + pLitros
        WHERE   IdSucursal = pIdSucursal;

        SELECT CONCAT ('OK', pIdRegistroLeche) Mensaje;
	COMMIT;
END$$
DELIMITER ;

-- -----------------------------------------------/ MODIFICAR REGISTRO DE LECHE/----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_modificar_registroleche`; 
DELIMITER $$
CREATE PROCEDURE `tsp_modificar_registroleche`(pIdRegistroLeche bigint, pLitros decimal(12,2), pFecha date)
    /*
    Permite modificar los litros y/o la fecha del registro de leche, controlando que en esa fecha no haya otro registro distinto.
    Devuelve OK o el mensaje de error en Mensaje.
    */
    SALIR: BEGIN
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
    IF (pLitros IS NULL OR pLitros = 0) THEN
        SELECT 'Debe ingresar los litros de leche.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pFecha IS NULL) THEN
        SELECT 'Debe indicar la fecha del registro' Mensaje;
        LEAVE SALIR;
	END IF;
    -- Control de Parámetros incorrectos
    SET pIdSucursal = (SELECT IdSucursal FROM RegistrosLeche WHERE IdRegistroLeche = pIdRegistroLeche);
	IF EXISTS(SELECT Fecha FROM  RegistrosLeche  WHERE  (IdSucursal = pIdSucursal and Fecha = pFecha and IdRegistroLeche <> pIdRegistroLeche)) THEN
		SELECT 'Ya existe otro registro para la fecha indicada' Mensaje;
		LEAVE SALIR;
	END IF; 
    START TRANSACTION; 
        SET pLitrosAntiguos = (SELECT Litros FROM RegistrosLeche WHERE IdRegistroLeche = pIdRegistroLeche);
        IF (pLitrosAntiguos != pLitros) THEN
            -- Modifico los litros con los que cuenta la sucursal
            UPDATE  Sucursales
            SET     Litros = Litros - pLitrosAntiguos + pLitros
            WHERE   IdSucursal = pIdSucursal;
        END IF;

        UPDATE  RegistrosLeche
        SET     Fecha = pFecha , Litros=pLitros
        WHERE   IdRegistroLeche = pIdRegistroLeche;
     SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;

-- -----------------------------------------------/ DAME REGISTRO DE LECHE /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_dame_registroleche`;
DELIMITER $$
CREATE PROCEDURE `tsp_dame_registroleche`(pIdRegistroLeche bigint)
SALIR: BEGIN
	/*
    Procedimiento que sirve para instanciar un registro de leche desde la base de datos.
    */
	SELECT	*
    FROM	RegistrosLeche
    WHERE	IdRegistroLeche = pIdRegistroLeche;
END$$
DELIMITER ;
-- -----------------------------------------------/ BORRAR REGISTRO DE LECHE /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_borrar_registroleche` ; 
DELIMITER $$
CREATE PROCEDURE `tsp_borrar_registroleche`(pIdRegistroLeche bigint)
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
    IF (pIdRegistroLeche IS NULL OR pIdRegistroLeche = 0) THEN
        SELECT 'El Id Registro de leche no puede estar vacio' Mensaje;
        LEAVE SALIR;
	END IF;
    START TRANSACTION;
        -- Modifico los litros con los que cuenta la sucursal
        UPDATE  Sucursales
        SET     Litros = Litros - (SELECT Litros FROM RegistrosLeche WHERE IdRegistroLeche = pIdRegistroLeche)
        WHERE   IdSucursal = (SELECT IdSucursal FROM RegistrosLeche WHERE IdRegistroLeche = pIdRegistroLeche);

        -- Borra
        DELETE FROM RegistrosLeche WHERE IdRegistroLeche = pIdRegistroLeche;
        SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;

-- -----------------------------------------------/ BUSCAR REGISTRO DE LECHE /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_buscar_registroleche`;
DELIMITER $$
CREATE PROCEDURE `tsp_buscar_registroleche`(pIdSucursal int, pFechaInicio date, pFechaFin date)
SALIR: BEGIN
	/*
	Permite buscar registros de leche dentro de una Sucursal, filtrando por un rango de fechas. 
	*/
    IF (pFechaInicio IS NOT NULL AND pFechaFin IS NOT NULL) THEN
        SELECT  *
        FROM    RegistrosLeche
        WHERE   (pFechaInicio <= Fecha AND Fecha <= pFechaFin)
                AND IdSucursal = pIdSucursal
        ORDER BY Fecha;
    ELSE
        SELECT  *
        FROM    RegistrosLeche
        WHERE   IdSucursal = pIdSucursal
        ORDER BY Fecha;
    END IF;
END$$
DELIMITER ;