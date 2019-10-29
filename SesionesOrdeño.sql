-- -----------------------------------------------/ ALTA SESION ORDEÑO /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_alta_sesionordeño`;
DELIMITER $$
CREATE PROCEDURE `tsp_alta_sesionordeño`(pIdSucursal int ,pFecha date,pObservaciones text)
SALIR: BEGIN
	/*
	Permite dar de alta una sesion de ordeño de una Sucursal.
    Devuelve OK+Id o el mensaje de error en Mensaje.
	*/
    DECLARE pMensaje varchar(100);
    DECLARE pIdSesionOrdeño bigint;
    	-- Manejo de error en la transacción
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		-- SHOW ERRORS;
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
	END;
    -- Controla Parámetros Vacios
    IF (pIdSucursal IS NULL OR pIdSucursal = 0) THEN
        SELECT 'Debe indicar la Sucursal' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pFecha IS NULL OR pFecha = '') THEN
        SELECT 'Debe ingresar la fecha de la sesionordeño.' Mensaje;
        LEAVE SALIR;
	END IF;

    -- Controla Parámetros Incorrectos
    IF NOT EXISTS(SELECT IdSucursal FROM Sucursales WHERE IdSucursal= pIdSucursal) THEN
        SELECT 'La Sucursal seleccionada es inexistente.' Mensaje;
        LEAVE SALIR;
	END IF;
  -- IF EXISTS(SELECT IdSesionOrdeño FROM SesionOrdeño WHERE pFecha = Fecha) THEN
	-- SELECT 'Ya existe una sesion ordeño en ese periodo.' Mensaje;
	-- LEAVE SALIR;
	-- END IF;
    START TRANSACTION;
        -- Insercion
        SET pIdSesionOrdeño = (SELECT COALESCE(MAX(IdSesionOrdeño), 0)+1 FROM SesionesOrdeño);
        INSERT INTO `SesionesOrdeño` VALUES (pIdSesionOrdeño, pIdSucursal, pFecha, pObservaciones);
        SELECT CONCAT ('OK', pIdSesionOrdeño) Mensaje;
	COMMIT;
END$$
DELIMITER ;
-- -----------------------------------------------/ MODIFICAR SESION DE ORDEÑO/----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_modificar_sesionordeño`;
DELIMITER $$
CREATE PROCEDURE `tsp_modificar_sesionordeño`(pIdSesionOrdeño bigint ,pFecha date,pObservaciones text)
/*
Permite modificar la fecha y agregar observaciones a una sesion de ordeño.
Devuelve OK o el mensaje de error en Mensaje.
*/
SALIR: BEGIN
DECLARE pMensaje varchar(100);
DECLARE pIdSucursal int;

-- Manejo de error en la transacción
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
	     -- SHOW ERRORS;
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
	END;
    -- Controla Parámetros Vacios
  IF (pIdSesionOrdeño IS NULL OR pIdSesionOrdeño = 0) THEN
          SELECT 'Debe indicar el Idsesionordeño' Mensaje;
          LEAVE SALIR;
  END IF;
  IF (pFecha IS NULL OR pFecha = '') THEN
        SELECT 'Debe ingresar la fecha de la sesion de ordeño.' Mensaje;
        LEAVE SALIR;
	END IF;
    -- Control de Parámetros incorrectos
  --   SET pIdSucursal = (SELECT IdSucursal FROM SesionOrdeño WHERE IdSesionOrdeño = pIdSesionOrdeño);
	-- IF EXISTS(SELECT IdSucursal FROM SesionOrdeño WHERE  (IdSucursal = pIdSucursal AND (pFecha = Fecha)) THEN
	-- 	SELECT 'Ya existe otra sesion de ordeño en esa fecha dentro de la misma sucursal' Mensaje;
	-- 	LEAVE SALIR;
	-- END IF;
  START TRANSACTION;
			UPDATE  SesionesOrdeño
			SET     Fecha = pFecha , Observaciones = pObservaciones
			WHERE   IdSesionOrdeño = pIdSesionOrdeño;
     SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;

-- -----------------------------------------------/ DAME SESION DE ORDEÑO /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_dame_sesionordeño`;
DELIMITER $$
CREATE PROCEDURE `tsp_dame_sesionordeño`(pIdSesionOrdeño bigint)
SALIR: BEGIN
	/*
    Procedimiento que sirve para instanciar una sesion de ordeño desde la base de datos.
    */
	SELECT	*
    FROM	SesionesOrdeño
    WHERE	IdSesionOrdeño = pIdSesionOrdeño;
END$$
DELIMITER ;
-- -----------------------------------------------/ BORRAR sesionordeño/----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_borrar_sesionordeño` ;
DELIMITER $$
CREATE PROCEDURE `tsp_borrar_sesionordeño`(pIdSesionOrdeño bigint)
SALIR: BEGIN
	/*
	Permite borrar un sesion de ordeño si no tiene producciones asociadas.
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
    IF (pIdSesionOrdeño IS NULL OR pIdSesionOrdeño = 0) THEN
        SELECT 'El Id sesionordeño no puede estar vacio' Mensaje;
        LEAVE SALIR;
	  END IF;
    -- Control de Datos Asociados
      IF EXISTS (SELECT IdSesionOrdeño FROM Producciones WHERE IdSesionOrdeño = pIdSesionOrdeño) THEN
          SELECT 'La sesion ordeño indicada no se puede borrar, tiene producciones asociadas.' Mensaje;
          LEAVE SALIR;
  	  END IF;

    START TRANSACTION;
        -- Borra
        DELETE FROM SesionesOrdeño WHERE IdSesionOrdeño = pIdSesionOrdeño;
        SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;
-- -----------------------------------------------/ BUSCAR SESION ORDEÑO /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_buscar_sesionesordeño`;
DELIMITER $$
CREATE PROCEDURE `tsp_buscar_sesionesordeño`(pIdSucursal int,pFechaInicio date, pFechaFin date )
SALIR: BEGIN
	/*
	Permite buscar sesiones de ordeño dentro de una Sucursal ,en una fecha.
	*/
    SELECT  *
    FROM   SesionesOrdeño
    WHERE  (pFechaInicio<=Fecha and Fecha<=pFechaFin)
            AND IdSucursal = pIdSucursal
    ORDER BY Fecha;
END$$
DELIMITER ;
