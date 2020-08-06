-- -----------------------------------------------/ CAMBIAR ESTADOVACA /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_cambiar_estadovaca`;
DELIMITER $$
CREATE PROCEDURE `tsp_cambiar_estadovaca`(pEstadoNuevo char(15), pIdVaca int,pFechaCambio date)
SALIR: BEGIN
	/*
	Cambia el estado de una vaca a uno distinto al cual estaba.
    Devuelve OK o el mensaje de error en Mensaje.
	*/
    DECLARE pMensaje varchar(100);
    DECLARE pnroEstadoVaca int;
    DECLARE pEstadoViejo char(15);
     	-- Manejo de error en la transacción
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		-- SHOW ERRORS;
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
	END;
    -- Controla Parámetros Vacios
    IF (pEstadoNuevo IS NULL OR pEstadoNuevo = '') THEN
        SELECT 'Debe indicar el nuevo estado' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pIdVaca IS NULL OR pIdVaca = 0) THEN
        SELECT 'Debe indicar el IdVaca' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pFechaCambio IS NULL) THEN
        SELECT 'Debe indicar la fecha de cambio de Estado' Mensaje;
        LEAVE SALIR;
	END IF;
    -- Control de Parámetros incorrectos
    SET pEstadoViejo = (SELECT Estado FROM EstadosVacas WHERE IdVaca=pIdVaca AND FechaFin IS null);
    IF (pEstadoViejo = pEstadoNuevo) THEN
		SELECT 'Ingrese un estado distinto al actual de la vaca.' Mensaje;
		LEAVE SALIR;
	END IF;
    START TRANSACTION;
    -- Insercion de la fecha fin del estado actual de la vaca.
    UPDATE EstadosVacas SET FechaFin = pFechaCambio WHERE IdVaca = pIdVaca and FechaFin IS null;
    -- Insercion del nuevo estado de la vaca.
    SET pnroEstadoVaca = (SELECT COALESCE(MAX(NroEstadoVaca), 0)+1 FROM EstadosVacas);
    INSERT INTO `EstadosVacas` VALUES (pIdVaca,pnroEstadoVaca,pEstadoNuevo,pFechaCambio,null);
    SELECT 'OK' Mensaje;
    COMMIT;
END$$
DELIMITER ;
