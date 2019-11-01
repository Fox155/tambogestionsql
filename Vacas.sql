-- -----------------------------------------------/ ALTA Vaca /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_alta_vaca`;
DELIMITER $$
CREATE PROCEDURE `tsp_alta_vaca`(pIdCaravana int, pIdRFID int,pNombre varchar (45),pRaza varchar (45),pPeso smallint, pFechaNac date, pObservaciones text,pIdLote int, pfechaIngresoLote date, pestadoVaca char(15))
SALIR: BEGIN
	/*
	Permite dar de alta una Vaca. Verificando que su idCaravana y IdRFID no esten repetidos en dos vacas que esten activas en un mismo instante
	A su vez si inserta la vaca en un lote y se le asigna un estado.
    Devuelve OK+Id o el mensaje de error en Mensaje.
	*/
    DECLARE pMensaje varchar(100);
    DECLARE pIdVaca int;
    DECLARE pnroEstadoVaca int;
    DECLARE pnroVacaLote int;
    	-- Manejo de error en la transacción
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		-- SHOW ERRORS;
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
	END;
    -- Controla Parámetros Vacios
    IF (pIdCaravana IS NULL OR pIdCaravana = 0) THEN
        SELECT 'Debe indicar el IdCaravana' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pIdRFID IS NULL OR pIdRFID = 0) THEN
        SELECT 'Debe indicar el IdRFID' Mensaje;
        LEAVE SALIR;
	END IF;
     IF (pIdLote IS NULL OR pIdLote = 0) THEN
        SELECT 'Debe indicar el IdLote' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pfechaIngresoLote IS NULL) THEN
        SELECT 'Debe indicar la fecha de ingreso al lote' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pestadoVaca IS NULL OR pestadoVaca = '') THEN
        SELECT 'Debe ingresar el estado de la vaca' Mensaje;
        LEAVE SALIR;
	END IF;
    -- Controla Parámetros Incorrectos    
    IF (EXISTS(SELECT v.IdCaravana FROM Vacas v INNER JOIN EstadosVacas ev USING (IdVaca) WHERE v.IdCaravana = pIdCaravana AND (ev.Estado <> 'VENDIDA' OR ev.Estado <> 'MUERTA'))) THEN
        SELECT 'IdCaravana repetido.' Mensaje; -- Falta comparar si son iguales en una misma fecha
        LEAVE SALIR;
	END IF;
    IF (EXISTS(SELECT v.IdRFID FROM Vacas v INNER JOIN EstadosVacas ev USING (IdVaca)WHERE IdRFID = pIdRFID AND (ev.Estado <> 'VENDIDA' OR ev.Estado <> 'MUERTA'))) THEN
        SELECT 'IdRFID repetido.' Mensaje; -- Falta comparar si son iguales en una misma fecha
        LEAVE SALIR;
	END IF;
    IF (pfechaIngresoLote<pFechaNac) THEN
        SELECT 'Debe ingresar una fecha mayor a la fecha de Nacimiento ' Mensaje;
        LEAVE SALIR;
	END IF;
    START TRANSACTION;
    -- Insercion en vacas
    SET pIdVaca = (SELECT COALESCE(MAX(IdVaca), 0)+1 FROM Vacas);
	INSERT INTO `Vacas` VALUES (pIdVaca,pIdCaravana,pIdRFID,pNombre,pRaza,pPeso,pFechaNac,pObservaciones);
    
    -- Insercion en VacasLote
    SET pnroVacaLote = (SELECT COALESCE(MAX(NroVacaLote), 0)+1 FROM VacasLote);
    INSERT INTO `VacasLote` VALUES (pIdVaca,pIdLote,pnroVacaLote,pfechaIngresoLote,null);

    -- Insercion en EstadoVaca
        -- Consideramos la fecha del inicio del estado la misma que la fecha de nacimiento
    SET pnroEstadoVaca = (SELECT COALESCE(MAX(NroEstadoVaca), 0)+1 FROM EstadosVacas);
    INSERT INTO `EstadosVacas` VALUES (pIdVaca,pnroEstadoVaca,pestadoVaca,pFechaNac,null);
    
    SELECT CONCAT ('OK',pIdVaca) Mensaje;
	COMMIT;
END$$
DELIMITER ;
-- -----------------------------------------------/ MODIFICAR VACA /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_modificar_vaca`; 
DELIMITER $$
CREATE PROCEDURE `tsp_modificar_vaca`(pIdVaca int, pIdCaravana int, pIdRFID int,pNombre varchar (45),pRaza varchar (45),pPeso smallint, pFechaNac date, pObservaciones text)
SALIR: BEGIN
/*
	Permite modificar los datos de una vaca. El IdCarava, IdRFIDVaca podran ser modificados si no hay otra vaca con los mismos datos en una misma fecha.
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
    -- Controla Parámetros Vacios
    IF (pIdVaca IS NULL OR pIdVaca = 0) THEN
        SELECT 'Debe indicar el Idvaca' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pIdCaravana IS NULL OR pIdCaravana = 0) THEN
        SELECT 'Debe indicar el IdCaravana' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pIdRFID IS NULL OR pIdRFID = 0) THEN
        SELECT 'Debe indicar el IdRFID' Mensaje;
        LEAVE SALIR;
	END IF;
     -- Controla Parámetros Incorrectos    
    IF (EXISTS(SELECT v.IdCaravana FROM Vacas v INNER JOIN EstadosVacas ev USING (IdVaca) WHERE v.IdVaca!= pIdVaca AND v.IdCaravana = pIdCaravana AND (ev.Estado <> 'VENDIDA' OR ev.Estado <> 'MUERTA'))) THEN
        SELECT 'IdCaravana repetido.' Mensaje; 
        LEAVE SALIR;
	END IF;
    IF (EXISTS(SELECT v.IdRFID FROM Vacas v INNER JOIN EstadosVacas ev USING (IdVaca)WHERE v.IdVaca!= pIdVaca AND  IdRFID = pIdRFID AND (ev.Estado <> 'VENDIDA' OR ev.Estado <> 'MUERTA'))) THEN
        SELECT 'IdCaravana repetido.' Mensaje; 
        LEAVE SALIR;
	END IF;
    START TRANSACTION;  
			UPDATE Vacas
            SET IdCaravana = pIdCaravana,
                IdRFID =pIdRFID,
                Nombre = pNombre,
                Raza = pRaza,
                Peso = pPeso,
                FechaNac = pFechaNac,
                Observaciones = pObservaciones
            WHERE IdVaca = pIdVaca;
            SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;

-- -----------------------------------------------/ DAME Vaca /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_dame_vaca`;
DELIMITER $$
CREATE PROCEDURE `tsp_dame_vaca`(pIdVaca int)
SALIR: BEGIN
 	/*
    Procedimiento que sirve para instanciar una Vaca desde la base de datos.
    */
	SELECT	*
    FROM	Vacas
    WHERE	IdVaca = pIdVaca;
END$$
DELIMITER ;
-- -----------------------------------------------/ BORRAR VACA /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_borrar_vaca` ; 
DELIMITER $$
CREATE PROCEDURE `tsp_borrar_vaca`(pIdVaca int)
SALIR: BEGIN
	/*
	Permite borrar un Vaca controlando que no tenga datos asociadas.
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
    -- Control de Parametros Incorrectos
    IF NOT EXISTS(SELECT IdVaca FROM Vacas WHERE IdVaca = pIdVaca) THEN
        SELECT 'La Vaca deseada no existe.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF EXISTS (SELECT pIdVaca FROM Lactancias WHERE IdVaca = pIdVaca) THEN
        SELECT 'La Vaca indicada no se puede borrar, tiene lactancias asociados.' Mensaje;
        LEAVE SALIR;
	END IF;   
    START TRANSACTION;
        -- Borra los estados de esa vaca
        DELETE FROM EstadosVacas WHERE IdVaca = pIdVaca;
        -- Borra los lotes asociados a esa vaca
        DELETE FROM VacasLote WHERE IdVaca = pIdVaca;
         -- Borra la vaca
        DELETE FROM Vacas WHERE IdVaca = pIdVaca;
        
        SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;
-- -----------------------------------------------/ BUSCAR  VACAS /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_buscar_vacas`;
DELIMITER $$
CREATE PROCEDURE `tsp_buscar_vacas`(pIdSucursal int, pIdLote int, pCadena varchar(100),pIncluyeBajas char(1))
SALIR: BEGIN
	/*
	Permite buscar Vacas dentro de los lotes de una Sucursal, indicando una cadena de búsqueda.  
	*/
    SELECT  v.*, l.IdLote, l.Nombre Lote, s.IdSucursal, s.Nombre Sucursal , ev.Estado
    FROM    Vacas v 
    INNER JOIN EstadosVacas ev USING (IdVaca)
    INNER JOIN VacasLote vl USING (IdVaca)
    INNER JOIN Lotes l USING(IdLote)
    INNER JOIN Sucursales s ON l.IdSucursal = s.IdSucursal
    WHERE l.IdSucursal = pIdSucursal 
			AND  (l.IdLote = pIdLote OR pIdLote = 0)
            AND  (v.Nombre LIKE CONCAT('%', pCadena, '%')
				OR v.IdCaravana LIKE CONCAT('%', pCadena, '%')
                OR v.IdRFID LIKE CONCAT('%', pCadena, '%')
                OR ev.Estado LIKE CONCAT('%', pCadena, '%'))
            AND (pIncluyeBajas = 'S'  OR ev.Estado <> 'BAJA')
            AND (ev.FechaInicio <= NOW() AND ev.FechaFin IS NULL);
END$$
DELIMITER ;

-- -----------------------------------------------/ LISTAR LACTANCIAS VACA /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_listar_lactancias_vaca`;
DELIMITER $$
CREATE PROCEDURE `tsp_listar_lactancias_vaca`(pIdVaca int)
SALIR: BEGIN
	/*
	Permite listar las lactancias una Vaca. 
	*/
    SELECT  l.*
    FROM Lactancias l
    INNER JOIN Vacas v USING(IdVaca)
    WHERE v.IdVaca = pIdVaca
    ORDER BY l.NroLactancia;
END$$
DELIMITER ;

-- -----------------------------------------------/ LISTAR PRODUCCIONES VACA /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_listar_producciones_vaca`;
DELIMITER $$
CREATE PROCEDURE `tsp_listar_producciones_vaca`(pIdVaca int, pNroLactancia tinyint)
SALIR: BEGIN
	/*
	Permite listar las producciones de una lactancia de una Vaca. 
	*/
    SELECT  p.*
    FROM Producciones p
    INNER JOIN Lactancias l ON p.IdVaca = l.IdVaca AND p.NroLactancia=l.NroLactancia
    INNER JOIN Vacas v ON v.IdVaca = l.IdVaca
    WHERE   v.IdVaca = pIdVaca
        AND l.NroLactancia = pNroLactancia
    ORDER BY l.NroLactancia;
END$$
DELIMITER ;

-- -----------------------------------------------/ RESUMEN PRODUCCIONES VACA /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_resumen_producciones_vaca`;
DELIMITER $$
CREATE PROCEDURE `tsp_resumen_producciones_vaca`(pIdVaca int)
SALIR: BEGIN
	/*
	Permite listar las producciones de la ultima lactancia de una Vaca, en funcion de sus sesiones de ordeñe. 
	*/
    SELECT  JSON_ARRAYAGG(tt.Produccion) 'Data', JSON_ARRAYAGG(tt.Fecha) 'Labels'
    FROM (
        SELECT p.Produccion, so.Fecha
        FROM Producciones p
        INNER JOIN SesionesOrdeño so USING(IdSesionOrdeño)
        INNER JOIN Lactancias l ON p.IdVaca = l.IdVaca AND p.NroLactancia=l.NroLactancia
        INNER JOIN Vacas v ON v.IdVaca = l.IdVaca
        WHERE   v.IdVaca = pIdVaca
            AND l.FechaFin IS NULL
        ORDER BY Fecha DESC
    ) tt;
END$$
DELIMITER ;