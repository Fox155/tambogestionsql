-- -----------------------------------------------/ CAMBIAR LOTE /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_cambiar_vacalote`;
DELIMITER $$
CREATE PROCEDURE `tsp_cambiar_vacalote`(pILoteNuevo int, pIdVaca int,pFechaCambio date)
SALIR: BEGIN
	/*
	Cambia a una vaca a un lote distinto del cual esta lote dentro de una misma sucursal.
    Devuelve OK+Id o el mensaje de error en Mensaje.
	*/
    DECLARE pMensaje varchar(100);
    DECLARE pnroEstadoVaca int;
    DECLARE ploteViejo int;
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
    SET ploteViejo = (SELECT IdLote FROM VacasLote WHERE IdVaca=pIdVaca AND FechaEgreso=null);
    IF (ploteViejo = pILoteNuevo) THEN
		SELECT 'El Lote nuevo es el mismo donde se encuentra la vaca.' Mensaje;
		LEAVE SALIR;
	END IF;  
    --el nuevo lote tiene que pertenecer a la misma sucursal
    IF NOT EXISTS(SELECT 
        FROM  Vacas v 
        INNER JOIN VacasLote vl USING (IdVaca)
        INNER JOIN Lotes l USING(IdLote)
        INNER JOIN Sucursales s ON l.IdSucursal = s.IdSucursal
        WHERE v.IdVaca = pIdVaca 
            AND l.Id
    
    
                                            )THEN 
        SELECT 'El Lote nuevo no pertenece a la sucursal' Mensaje;
		LEAVE SALIR;
	END IF; 


    START TRANSACTION; 
    --Insercion de la fecha de egreso del lote del cual se esta por cambiar a la vaca
    UPDATE VacasLote SET FechaEgreso = pFechaCambio WHERE IdVaca = pIdVaca and IdLote=ploteViejo;
    -- Insercion de la vaca en el nuevo lote
    SET pnroVacaLote = (SELECT COALESCE(MAX(NroVacaLote), 0)+1 FROM VacasLote);
    INSERT INTO `VacasLote` VALUES (pIdVaca,pILoteNuevo,pnroVacaLote,pFechaCambio,null);
    SELECT 'OK' Mensaje;
    COMMIT;
END$$
DELIMITER ;