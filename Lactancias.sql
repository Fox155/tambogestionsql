-- -----------------------------------------------/ ALTA LACTANCIA /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_alta_lactancia`;
DELIMITER $$
CREATE PROCEDURE `tsp_alta_lactancia`(pIdVaca int ,pFechaInicio date,pObservaciones text)
SALIR: BEGIN
	/*
	Permite dar de alta una Lactancia de una Vaca.
    Controlando que dentro del rango de fechas dado, una vaca solo pueda tener una Lactancia
    Devuelve OK+Id o el mensaje de error en Mensaje.
	*/
    DECLARE pMensaje varchar(100);
    DECLARE pIdLactancia tinyint;
    DECLARE pNroEstadoVaca int;
    
    -- Manejo de error en la transacción
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		-- SHOW ERRORS;
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
	END;
    -- Controla Parámetros Vacios
    IF (pIdVaca IS NULL OR pIdVaca = 0) THEN
        SELECT 'Debe indicar la Vaca' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pFechaInicio IS NULL) THEN
        SELECT 'Debe ingresar la fecha de inicio de la lactancia.' Mensaje;
        LEAVE SALIR;
	END IF;

    -- Controla Parámetros Incorrectos
    IF NOT EXISTS(SELECT IdVaca FROM Vacas WHERE IdVaca= pIdVaca) THEN
        SELECT 'La Vaca seleccionada es inexistente.' Mensaje;
        LEAVE SALIR;
    END IF;
    IF EXISTS(SELECT NroLactancia FROM Lactancias WHERE IdVaca = pIdVaca AND FechaFin IS NULL ) THEN
		SELECT 'La vaca se encuentra en un periodo de lactancia sin fecha fin' Mensaje;
		LEAVE SALIR;
	END IF;
    IF EXISTS(SELECT NroLactancia FROM Lactancias WHERE IdVaca = pIdVaca AND (pFechaInicio < FechaInicio OR pFechaInicio < FechaFin)) THEN
		SELECT 'Ya existe una Lactancia en esa fecha.' Mensaje;
		LEAVE SALIR;
	END IF;
    START TRANSACTION;
        -- Insercion
        SET         pIdLactancia = (SELECT COALESCE(MAX(NroLactancia), 0)+1 FROM Lactancias WHERE IdVaca = pIdVaca);
        INSERT INTO Lactancias VALUES (pIdVaca,pIdLactancia,pFechaInicio,null,pObservaciones);
        SELECT      CONCAT ('OK', pIdLactancia) Mensaje;

        -- Modifica Estado anterior
        UPDATE  EstadosVacas
        SET     FechaFin = NOW()
        WHERE   IdVaca = pIdVaca AND FechaFin IS NULL;

        -- Inserta el nuevo estado
        SET         pNroEstadoVaca = (SELECT COALESCE(MAX(NroEstadoVaca), 0)+1 FROM EstadosVacas WHERE IdVaca = pIdVaca);
        INSERT INTO EstadosVacas
        SELECT      pIdVaca, pNroEstadoVaca, "LACTANTE", NOW(), NULL;
	COMMIT;
END$$
DELIMITER ;
-- -----------------------------------------------/ MODIFICAR LACTANCIA/----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_modificar_lactancia`;
DELIMITER $$
CREATE PROCEDURE `tsp_modificar_lactancia`(pIdLactancia Tinyint, pFechaInicio date,pObservaciones text)
/*
Permite modificar los datos de una Lactancia, controlando que en esas fecha no haya otra lactancia distinta.
Devuelve OK o el mensaje de error en Mensaje.
*/
SALIR: BEGIN
    DECLARE pMensaje varchar(100);
    DECLARE pIdVaca int;

    -- Manejo de error en la transacción
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
	     -- SHOW ERRORS;
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
	END;
    -- Controla Parámetros Vacios
  IF (pIdLactancia IS NULL OR pIdLactancia = 0) THEN
          SELECT 'Debe indicar el IdLactancia' Mensaje;
          LEAVE SALIR;
  END IF;
  IF (pFechaInicio IS NULL) THEN
        SELECT 'Debe ingresar la fecha de inicio de la lactancia.' Mensaje;
        LEAVE SALIR;
	END IF;
    -- Control de Parámetros incorrectos
    SET pIdVaca = (SELECT IdVaca FROM Lactancias WHERE NroLactancia = pIdLactancia);
	  IF EXISTS(SELECT NroLactancia FROM Lactancias WHERE IdVaca = pIdVaca
                                                      AND NroLactancia <> pIdLactancia
                                                      AND (FechaInicio < pFechaInicio  OR pFechaInicio < FechaFin)) THEN
		SELECT 'Ya existe otra lactancia dentro de ese rango de fecha ' Mensaje;
		LEAVE SALIR;
	END IF;
  START TRANSACTION;
			UPDATE  Lactancias
			SET     FechaInicio = pFechaInicio, Observaciones = pObservaciones
			WHERE   NroLactancia = pIdLactancia;
     SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;

-- -----------------------------------------------/ DAME LACTANCIA /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_dame_lactancia`;
DELIMITER $$
CREATE PROCEDURE `tsp_dame_lactancia`(pIdLactancia Tinyint)
SALIR: BEGIN
	/*
    Procedimiento que sirve para instanciar unA Lactancia desde la base de datos.
    */
	SELECT	*
    FROM	Lactancias
    WHERE	NroLactancia = pIdLactancia;
END$$
DELIMITER ;
-- -----------------------------------------------/ BORRAR LACTANCIA/----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_borrar_Lactancia` ;
DELIMITER $$
CREATE PROCEDURE `tsp_borrar_Lactancia`(pIdLactancia Tinyint)
SALIR: BEGIN
	/*
	Permite borrar un Lactancia si no tiene producciones asociadas.
  Devuelve OK o el mensaje de error en Mensaje.
	*/
    DECLARE pMensaje varchar(100);
	-- Manejo de error en la transacción
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
	    SHOW ERRORS;
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
  	END;

    -- Control de Parámetros Vacios
    IF (pIdLactancia IS NULL OR pIdLactancia = 0) THEN
        SELECT 'El Id Lactancia no puede estar vacio' Mensaje;
        LEAVE SALIR;
	  END IF;
    -- Control de Datos Asociados
      IF EXISTS (SELECT NroLactancia FROM Producciones WHERE NroLactancia = pIdLactancia) THEN
          SELECT 'La lactancia indicada no se puede borrar, tiene producciones asociadas.' Mensaje;
          LEAVE SALIR;
  	  END IF;

    START TRANSACTION;
        -- Borra
        DELETE FROM Lactancias WHERE NroLactancia = pIdLactancia;
        SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;
-- -----------------------------------------------/ BUSCAR LACTANCIA /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_buscar_lactancias`;
DELIMITER $$
CREATE PROCEDURE `tsp_buscar_lactancias`(pIdVaca int,pFechaInicio date, pFechaFin date)
SALIR: BEGIN
	/*
	Permite buscar lactancias de una Vaca , dentro de un rango de fechas.
    Si las fechas son nulas muestra todas las lactancias de una vaca
	*/
    SELECT  *
    FROM    Lactancias
    WHERE  ((FechaInicio <= pFechaInicio and pFechaFin <=FechaFin )
				OR (pFechaInicio IS NULL AND pFechaFin IS NULL )
                OR (FechaInicio <= FechaInicio and pFechaFin IS NULL )
				  )
                AND IdVaca = pIdVaca
    ORDER BY FechaInicio;
END$$
DELIMITER ;
-- -----------------------------------------------/ FINALIZAR LACTANCIA /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_finalizar_lactancia`;
DELIMITER $$
CREATE PROCEDURE `tsp_finalizar_lactancia`(pIdVaca int, pFechaFin date)
/*
Establece la fecha de fin de la Lactancia una vaca.En caso que guarde una fecha erronea con este mismo sp la puedo modificar
Devuelve OK o el mensaje de error en Mensaje.
*/
SALIR: BEGIN
    DECLARE pMensaje varchar(100);
    DECLARE pNroLactancia tinyint;
    DECLARE pNroEstadoVaca int;

    -- Manejo de error en la transacción
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
	     -- SHOW ERRORS;
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
	END;
    -- Controla Parámetros Vacios
    IF (pIdVaca IS NULL OR pIdVaca = 0) THEN
        SELECT 'Debe indicar la Vaca' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pFechaFin IS NULL) THEN
        SELECT 'Debe ingresar la fecha de fin de la lactancia.' Mensaje;
        LEAVE SALIR;
	END IF;
    -- Control de Parámetros incorrectos
    IF NOT EXISTS(  
        SELECT v.IdVaca FROM Vacas v
        INNER JOIN EstadosVacas ev USING (IdVaca)
        WHERE   v.IdVaca = pIdVaca
                AND ev.Estado = 'LACTANTE'
                AND ev.FechaFin IS NULL
        ) THEN
        SELECT 'La Vaca debe encuentrarse Lactante para finalizar su lactancia.' Mensaje;
        LEAVE SALIR;
	END IF;
    SET pNroLactancia = (SELECT NroLactancia FROM Lactancias WHERE IdVaca = pIdVaca AND FechaFin IS NULL);
    IF EXISTS(SELECT NroLactancia FROM Lactancias WHERE IdVaca = pIdVaca AND NroLactancia = pNroLactancia AND FechaInicio > pFechaFin) THEN
        SELECT 'Debe ingresar una fecha posterior al inicio de la lactancia ' Mensaje;
        LEAVE SALIR;
    END IF;
	-- IF EXISTS(SELECT NroLactancia FROM Lactancias WHERE  (NroLactancia = pIdLactancia AND FechaFin IS NOT NULL AND FechaFin  )) THEN
	-- 	SELECT 'Esta Lactancia ya posee una fecha de Fin' Mensaje;
	-- 	LEAVE SALIR;
	-- END IF;
    IF NOT EXISTS(SELECT NroLactancia FROM Producciones WHERE IdVaca = pIdVaca AND NroLactancia = pNroLactancia AND pFechaFin < FechaFin) THEN
        SELECT 'Esta Lactancia posee producciones que exceden a la fecha de fin' Mensaje;
        LEAVE SALIR;
    END IF;
    START TRANSACTION;
		UPDATE  Lactancias
		SET     FechaFin = pFechaFin
		WHERE   IdVaca = pIdVaca AND NroLactancia = pNroLactancia;

        -- Modifica Estado anterior
        UPDATE  EstadosVacas
        SET     FechaFin = NOW()
        WHERE   IdVaca = pIdVaca AND FechaFin IS NULL;

        -- Inserta el nuevo estado
        SET         pNroEstadoVaca = (SELECT COALESCE(MAX(NroEstadoVaca), 0)+1 FROM EstadosVacas WHERE IdVaca = pIdVaca);
        INSERT INTO EstadosVacas
        SELECT      pIdVaca, pNroEstadoVaca, "SECA", NOW(), NULL;

        SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;
