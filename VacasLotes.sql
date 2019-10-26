-- -----------------------------------------------/ CAMBIAR A UNA VACA DE LOTE /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_cambiar_vacalote`;
DELIMITER $$
CREATE PROCEDURE `tsp_cambiar_vacalote`(pILoteNuevo int, pIdVaca int,pFechaCambio date)
SALIR: BEGIN
	/*
	Cambia a una vaca a un lote distinto dentro de una misma sucursal.
    Verificando que no sea el mismo lote al que se la intena cambiar y que el nuevo lote pertenezca a la misma sucursal
    Devuelve OK o el mensaje de error en Mensaje.
	*/
    DECLARE pMensaje varchar(100);
    DECLARE pnroVacaLote int;
    DECLARE pLoteViejo int;
    DECLARE pSucursal int;
     	-- Manejo de error en la transacción
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		-- SHOW ERRORS;
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
	END;
    -- Controla Parámetros Vacios
    IF (pILoteNuevo IS NULL OR pILoteNuevo = 0) THEN
        SELECT 'Debe indicar el Nuevo Lote' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pIdVaca IS NULL OR pIdVaca = 0) THEN
        SELECT 'Debe indicar el IdVaca' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pFechaCambio IS NULL) THEN
        SELECT 'Debe indicar la fecha de cambio de lote' Mensaje;
        LEAVE SALIR;
	END IF;
    -- Control de Parámetros incorrectos
    SET pLoteViejo = (SELECT IdLote FROM VacasLote WHERE IdVaca=pIdVaca AND FechaEgreso IS null);
    SET pSucursal = (SELECT IdSucursal FROM Lotes WHERE IdLote=pLoteViejo);
    IF (pLoteViejo = pILoteNuevo) THEN
		SELECT 'El Lote nuevo es el mismo donde se encuentra la vaca.' Mensaje;
		LEAVE SALIR;
	END IF;  
    IF NOT EXISTS(SELECT IdSucursal FROM  Lotes  WHERE Idlote = pILoteNuevo AND IdSucursal = pSucursal)THEN 
        SELECT 'El Lote nuevo no pertenece a la sucursal a la cual pertenece la vaca' Mensaje;
		LEAVE SALIR;
	END IF; 
    START TRANSACTION; 
    -- Insercion de la fecha de egreso del lote del cual se esta por cambiar a la vaca
    UPDATE VacasLote SET FechaEgreso = pFechaCambio WHERE IdVaca = pIdVaca and IdLote=ploteViejo;
    -- Insercion de la vaca en el nuevo lote
    SET pnroVacaLote = (SELECT COALESCE(MAX(NroVacaLote), 0)+1 FROM VacasLote);
    INSERT INTO `VacasLote` VALUES (pIdVaca,pILoteNuevo,pnroVacaLote,pFechaCambio,null);
    SELECT 'OK' Mensaje;
    COMMIT;
END$$
DELIMITER ;