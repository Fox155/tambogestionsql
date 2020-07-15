-- -----------------------------------------------/ ALTA PRODUCCION /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_alta_produccion`;
DELIMITER $$
CREATE PROCEDURE `tsp_alta_produccion`(pIdSesionOrdeño bigint, pIdVaca int, pNroLactancia tinyint, pProduccion tinyint,pFechaInicio datetime, pFechaFin datetime, pMedidor json)
SALIR: BEGIN
	/*
	Permite dar de alta una produccion de una lactancia de una vaca.
    Devuelve OK+Id o el mensaje de error en Mensaje.
	*/
    DECLARE pMensaje varchar(100);
    DECLARE pIdProduccion bigint;
    
    -- Manejo de error en la transacción
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		-- SHOW ERRORS;
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
	END;
    -- Controla Parámetros Vacios
    IF (pIdSesionOrdeño IS NULL OR pIdSesionOrdeño = 0) THEN
        SELECT 'Debe indicar la sesion de ordeño' Mensaje;
        LEAVE SALIR;
	  END IF;
    IF (pIdVaca IS NULL OR pIdVaca = 0) THEN
        SELECT 'Debe indicar la vaca' Mensaje;
        LEAVE SALIR;
    END IF;
    IF (pNroLactancia IS NULL OR pNroLactancia = 0) THEN
        SELECT 'Debe indicar el nro de lactancia' Mensaje;
        LEAVE SALIR;
    END IF;
    IF (pProduccion IS NULL OR pProduccion = 0) THEN
        SELECT 'Debe indicar los litros de produccion' Mensaje;
        LEAVE SALIR;
    END IF;
    IF (pFechaInicio IS NULL) THEN
        SELECT 'Debe ingresar la fecha inicio de la produccion' Mensaje;
        LEAVE SALIR;
	  END IF;
    IF (pFechaFin IS NULL) THEN
        SELECT 'Debe ingresar la fecha fin de la produccion' Mensaje;
        LEAVE SALIR;
	  END IF;
    IF (pMedidor IS NULL) THEN
        SELECT 'Debe ingresar los datos del medidor' Mensaje;
        LEAVE SALIR;
    END IF;

    -- Controla Parámetros Incorrectos
    IF NOT EXISTS(SELECT IdSesionOrdeño FROM SesionesOrdeño WHERE IdSesionOrdeño= pIdSesionOrdeño) THEN
        SELECT 'La Sesion de Ordeño seleccionada es inexistente.' Mensaje;
        LEAVE SALIR;
	  END IF;
    IF NOT EXISTS(SELECT NroLactancia FROM Lactancias WHERE NroLactancia= pNroLactancia) THEN
        SELECT 'La lactancia seleccionada es inexistente.' Mensaje;
        LEAVE SALIR;
	  END IF;
    IF NOT EXISTS(SELECT IdVaca FROM Lactancias WHERE IdVaca= pIdVaca AND  NroLactancia = pNroLactancia) THEN
        SELECT 'La vaca no corresponde a la lactancia seleccionada ' Mensaje;
        LEAVE SALIR;
	  END IF;
    -- Control de fechas
    -- IF NOT EXISTS(SELECT p.IdProduccion FROM Producciones p
    --                               INNER JOIN Lactancias l ON l.NroLactancia = p.NroLactancia
    --                               WHERE ((l.FechaInicio < DATE(pFechaInicio)) AND l.FechaFin IS NULL))THEN
    --   		SELECT 'La fecha de la produccion esta en un periodo fuera del rango de la lactancia' Mensaje;
    --   		LEAVE SALIR;
	--   END IF;
    -- IF NOT EXISTS(SELECT IdSesionOrdeño FROM SesionesOrdeño WHERE FECHA = DATE(pFechaInicio))THEN
    --       SELECT 'La fecha de la sesion de ordeño no coincide con la fecha de la produccion' Mensaje;
    --       LEAVE SALIR;
    -- END IF;
    START TRANSACTION;
        -- Insercion
        SET pIdProduccion = (SELECT COALESCE(MAX(IdProduccion), 0)+1 FROM Producciones);
        INSERT INTO `Producciones` VALUES (pIdProduccion,pIdSesionOrdeño , pIdVaca , pNroLactancia , pProduccion ,pFechaInicio , pFechaFin , pMedidor);
        SELECT CONCAT ('OK', pIdProduccion) Mensaje;
	  COMMIT;
END$$
DELIMITER ;
-- -----------------------------------------------/ MODIFICAR SESION DE ORDEÑO/----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_modificar_produccion`;
DELIMITER $$
CREATE PROCEDURE `tsp_modificar_produccion`(pIdProduccion bigint, pProduccion tinyint,pFechaInicio datetime, pFechaFin datetime, pMedidor json)
/*
Permite modificar los datos de una produccion en particular .
Devuelve OK o el mensaje de error en Mensaje.
*/
SALIR: BEGIN
DECLARE pMensaje varchar(100);
DECLARE pIdSesionOrdeño bigint;
DECLARE pNroLactancia tinyint;

-- Manejo de error en la transacción
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
	     -- SHOW ERRORS;
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
	  END;
    -- Controla Parámetros Vacios
    IF (pIdProduccion IS NULL OR pIdProduccion = 0) THEN
        SELECT 'Debe indicar el id de produccion' Mensaje;
        LEAVE SALIR;
    END IF;
    IF (pProduccion IS NULL OR pProduccion = 0) THEN
        SELECT 'Debe indicar los litros de produccion' Mensaje;
        LEAVE SALIR;
    END IF;
    IF (pFechaInicio IS NULL OR pFechaInicio = '') THEN
        SELECT 'Debe ingresar la fecha inicio de la produccion' Mensaje;
        LEAVE SALIR;
	  END IF;
    IF (pFechaFin IS NULL OR pFechaFin = '') THEN
        SELECT 'Debe ingresar la fecha fin de la produccion' Mensaje;
        LEAVE SALIR;
	  END IF;
    IF (pMedidor IS NULL) THEN
        SELECT 'Debe ingresar los datos del medidor' Mensaje;
        LEAVE SALIR;
    END IF;

    -- Control de fechas
    SET pNroLactancia = (SELECT NroLactancia FROM Producciones WHERE IdProduccion = pIdProduccion);
    SET pIdSesionOrdeño = (SELECT IdSesionOrdeño FROM Producciones WHERE IdProduccion = pIdProduccion);

    IF NOT EXISTS(SELECT p.IdProduccion FROM Producciones p
                                  INNER JOIN Lactancias l USING(NroLactancia)
                                  INNER JOIN SesionesOrdeño s USING(IdSesionOrdeño)
                                  WHERE (l.FechaInicio < DATE(pFechaInicio) AND l.FechaInicio < DATE(pFechaFin))
                                  AND  s.FECHA = DATE(pFechaInicio)) THEN
      		SELECT 'La fecha de la produccion esta en un periodo fuera del rango de la lactancia' Mensaje;
      		LEAVE SALIR;
	  END IF;
  START TRANSACTION;
			UPDATE  Producciones
			SET     Produccion = pProduccion , FechaInicio = pFechaInicio, FechaFin = pFechaFin , Medidor = pMedidor
			WHERE   Idproducciones = pIdproducciones;
     SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;

-- -----------------------------------------------/ DAME SESION DE ORDEÑO /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_dame_produccion`;
DELIMITER $$
CREATE PROCEDURE `tsp_dame_produccion`(pIdProduccion bigint)
SALIR: BEGIN
	/*
    Procedimiento que sirve para instanciar una produccion desde la base de datos.
    */
	SELECT	*
    FROM	Producciones
    WHERE	IdProduccion = pIdProduccion;
END$$
DELIMITER ;
-- -----------------------------------------------/ BORRAR PRODUCCIONES/----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_borrar_produccion` ;
DELIMITER $$
CREATE PROCEDURE `tsp_borrar_produccion`(pIdProduccion bigint)
SALIR: BEGIN
	/*
	Permite borrar una produccion.
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
    IF (pIdProduccion IS NULL OR pIdProduccion = 0) THEN
        SELECT 'El Id produccion no puede estar vacio' Mensaje;
        LEAVE SALIR;
	  END IF;
    START TRANSACTION;
        -- Borra
        DELETE FROM Producciones WHERE IdProduccion = pIdProduccion;
        SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;
-- -----------------------------------------------/ BUSCAR PRODUCCIONES /----------------------------------------
-- DROP PROCEDURE IF EXISTS `tsp_buscar_producciones`;
-- DELIMITER $$
-- CREATE PROCEDURE `tsp_buscar_producciones`(pIdVaca int, pNroLactancia tinyint,pFecha date)
-- SALIR: BEGIN
-- 	/*
-- 	Permite buscar producciones de una vaca ,en una fecha.
--   si pNroLactancia= 0 muestra todas las producciones de la vaca de todas sus lactancias
-- 	*/
--     SELECT  *
--     FROM   Producciones
--     WHERE   ((FechaInicio=<pFecha AND pFecha=<FechaFin) OR pfecha = null)
--             AND IdVaca = pIdVaca
--             AND (NroLactancia = pNroLactancia OR pNroLactancia = 0)
--     ORDER BY Fecha;
-- END$$
-- DELIMITER ;
