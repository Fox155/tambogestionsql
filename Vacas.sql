-- -----------------------------------------------/ ALTA VACA /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_alta_vaca`;
DELIMITER $$
CREATE PROCEDURE `tsp_alta_vaca`(pIdCaravana int, pIdRFID int, pIdLote int, pNombre varchar (45), pRaza varchar (45), pPeso smallint,
pFechaNac date, pObservaciones text, pFechaIngresoLote date, pEstadoVaca char(15))
SALIR: BEGIN
	/*
	Permite dar de alta una Vaca. Verificando que su idCaravana y IdRFID no esten repetidos en dos vacas que esten activas en un mismo instante
	A su vez se inserta la vaca en un Lote y se le asigna un Estado.
    Devuelve OK+Id o el mensaje de error en Mensaje.
	*/
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
    IF (pIdCaravana IS NULL OR pIdCaravana = 0) THEN
        SELECT 'Debe indicar la Caravana.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pIdRFID IS NULL OR pIdRFID = 0) THEN
        SELECT 'Debe indicar el Identificador de Radio Frecuencia(RFID).' Mensaje;
        LEAVE SALIR;
	END IF;
     IF (pIdLote IS NULL OR pIdLote = 0) THEN
        SELECT 'Debe indicar el Lote.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pFechaIngresoLote IS NULL) THEN
        SELECT 'Debe indicar la Fecha de ingreso al lote.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pEstadoVaca IS NULL OR pEstadoVaca = '') THEN
        SELECT 'Debe ingresar el Estado incial.' Mensaje;
        LEAVE SALIR;
	END IF;
    -- Controla Parámetros Incorrectos    
    IF EXISTS(  
        SELECT v.IdCaravana FROM Vacas v
        INNER JOIN EstadosVacas ev USING (IdVaca)
        WHERE   v.IdCaravana = pIdCaravana
                AND (ev.Estado <> 'Vendida' AND ev.Estado <> 'Muerta')
                AND ev.FechaFin IS NULL) THEN
        SELECT 'Caravana repetida.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF EXISTS(
        SELECT v.IdRFID FROM Vacas v 
        INNER JOIN EstadosVacas ev USING (IdVaca)
        WHERE   IdRFID = pIdRFID 
                AND (ev.Estado <> 'Vendida' AND ev.Estado <> 'Muerta')
                AND ev.FechaFin IS NULL) THEN
        SELECT 'Identificador de Radio Frecuencia(RFID) repetido.' Mensaje; -- Falta comparar si son iguales en una misma fecha
        LEAVE SALIR;
	END IF;
    IF ( pFechaIngresoLote < pFechaNac) THEN
        SELECT 'La Fecha de ingreso al Lote debe ser mayor que la de Nacimiento.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF ( pPeso IS NOT NULL AND pPeso <= 0) THEN
        SET pPeso = NULL;
	END IF;
    START TRANSACTION;
        -- Insercion en Vacas
        SET pIdVaca = (SELECT COALESCE(MAX(IdVaca), 0)+1 FROM Vacas);
        INSERT INTO Vacas
        SELECT pIdVaca, pIdCaravana, pIdRFID, pNombre, pRaza, pPeso, pFechaNac, pObservaciones;
        
        -- Insercion en VacasLote
        INSERT INTO VacasLote 
        SELECT pIdVaca, pIdLote, 1, pFechaIngresoLote, NULL;

        -- Insercion en EstadoVaca
        INSERT INTO EstadosVacas
        SELECT pIdVaca, 1, pEstadoVaca, pFechaNac, NULL;
        
        SELECT CONCAT ('OK',pIdVaca) Mensaje;
	COMMIT;
END$$
DELIMITER ;

-- -----------------------------------------------/ MODIFICAR VACA /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_modificar_vaca`; 
DELIMITER $$
CREATE PROCEDURE `tsp_modificar_vaca`(pIdVaca int, pIdCaravana int, pIdRFID int, pNombre varchar (45), pRaza varchar (45),
pPeso smallint, pFechaNac date, pObservaciones text)
SALIR: BEGIN
    /*
        Permite modificar los datos de una vaca. El IdCarava, IdRFID podran ser modificados si no hay otra vaca con los mismos datos en una misma fecha.
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
        SELECT 'Debe indicar la Vaca.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pIdCaravana IS NULL OR pIdCaravana = 0) THEN
        SELECT 'Debe indicar la Caravana.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pIdRFID IS NULL OR pIdRFID = 0) THEN
        SELECT 'Debe indicar el Identificador de Radio Frecuencia(RFID).' Mensaje;
        LEAVE SALIR;
	END IF;
     -- Controla Parámetros Incorrectos    
    IF EXISTS(  
        SELECT v.IdCaravana FROM Vacas v
        INNER JOIN EstadosVacas ev USING (IdVaca)
        WHERE   v.IdCaravana = pIdCaravana
                AND (ev.Estado <> 'Vendida' AND ev.Estado <> 'Muerta')
                AND ev.FechaFin IS NULL) THEN
        SELECT 'Caravana repetida.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF EXISTS(
        SELECT v.IdRFID FROM Vacas v 
        INNER JOIN EstadosVacas ev USING (IdVaca)
        WHERE   IdRFID = pIdRFID 
                AND (ev.Estado <> 'Vendida' AND ev.Estado <> 'Muerta')
                AND ev.FechaFin IS NULL) THEN
        SELECT 'Identificador de Radio Frecuencia(RFID) repetido.' Mensaje; -- Falta comparar si son iguales en una misma fecha
        LEAVE SALIR;
	END IF;
    IF ( pPeso IS NOT NULL AND pPeso <= 0) THEN
        SET pPeso = NULL;
	END IF;
    START TRANSACTION; 
        -- Modifaca
        UPDATE Vacas
        SET IdCaravana = pIdCaravana,
            IdRFID = pIdRFID,
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
		-- SHOW ERRORS;
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
	END;
    -- Control de Parametros Incorrectos
    IF EXISTS (SELECT pIdVaca FROM Lactancias WHERE IdVaca = pIdVaca) THEN
        SELECT 'La Vaca indicada no se puede borrar, tiene lactancias asociadas.' Mensaje;
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

-- -----------------------------------------------/ DAME VACA /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_dame_vaca`;
DELIMITER $$
CREATE PROCEDURE `tsp_dame_vaca`(pIdVaca int)
SALIR: BEGIN
 	/*
    Procedimiento que sirve para instanciar una Vaca desde la base de datos.
    */
    SELECT  v.*, l.IdLote, l.Nombre Lote, s.IdSucursal, s.Nombre Sucursal, ev.Estado
    FROM    Vacas v 
    INNER JOIN EstadosVacas ev USING (IdVaca)
    INNER JOIN VacasLote vl USING (IdVaca)
    INNER JOIN Lotes l USING(IdLote)
    INNER JOIN Sucursales s USING(IdSucursal)
    WHERE	IdVaca = pIdVaca AND ev.FechaFin IS NULL;
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
    SELECT  l.*, COUNT(p.IdProduccion) Producciones, SUM(p.Produccion) Acumulada, SUM(p.Produccion) Corregida,
    TIMESTAMPDIFF(MONTH, v.FechaNac,NOW()) Meses, TIMESTAMPDIFF(DAY, l.FechaInicio ,NOW()) Dias
    FROM Lactancias l
    INNER JOIN Vacas v USING(IdVaca)
    INNER JOIN Producciones p ON l.IdVaca = p.IdVaca AND l.NroLactancia = p.NroLactancia
    WHERE v.IdVaca = pIdVaca
    ORDER BY l.NroLactancia DESC;
END$$
DELIMITER ;

-- -----------------------------------------------/ LISTAR RESUMENES COMPLETOS LACTANCIAS VACA /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_listar_resumen_completo_lactancias_vaca`;
DELIMITER $$
CREATE PROCEDURE `tsp_listar_resumen_completo_lactancias_vaca`(pIdVaca int)
SALIR: BEGIN
	/*
	Permite listar las lactancias una Vaca. 
	*/
    SELECT  l.*, COUNT(p.IdProduccion) Producciones, SUM(p.Produccion) Acumulada,
    TIMESTAMPDIFF(MONTH, v.FechaNac,NOW()) Meses, TIMESTAMPDIFF(DAY, l.FechaInicio ,NOW()) Dias,
    st.Datos 'Data', st.Etiquetas 'Labels'
    FROM (
        SELECT  JSON_ARRAYAGG(tt.Produccion) Datos, JSON_ARRAYAGG(tt.Fecha) Etiquetas
        FROM (
            SELECT p.Produccion, so.Fecha
            FROM Producciones p
            INNER JOIN SesionesOrdeño so USING(IdSesionOrdeño)
            INNER JOIN Lactancias l ON p.IdVaca = l.IdVaca AND p.NroLactancia=l.NroLactancia
            INNER JOIN Vacas v ON v.IdVaca = l.IdVaca
            WHERE   v.IdVaca = pIdVaca
            ORDER BY Fecha DESC
        ) tt
    ) st
    ,Lactancias l
    INNER JOIN Vacas v USING(IdVaca)
    INNER JOIN Producciones p ON l.IdVaca = p.IdVaca AND l.NroLactancia = p.NroLactancia
    WHERE v.IdVaca = pIdVaca
    ORDER BY l.NroLactancia DESC;
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

-- -----------------------------------------------/ LISTAR RESUMEN PRODUCCIONES VACA /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_listar_resumen_producciones_vaca`;
DELIMITER $$
CREATE PROCEDURE `tsp_listar_resumen_producciones_vaca`(pIdVaca int, pNroLactancia tinyint)
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
        WHERE   l.IdVaca = pIdVaca
                AND l.NroLactancia = pNroLactancia
        ORDER BY Fecha DESC
    ) tt;
END$$
DELIMITER ;

-- -----------------------------------------------/ CAMBIAR ESTADO VACA /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_cambiar_estado_vaca`; 
DELIMITER $$
CREATE PROCEDURE `tsp_cambiar_estado_vaca`(pIdVaca int, pEstado varchar(15))
SALIR: BEGIN
    /*
        Permite cambiar el estado de una vaca finalidanzo el anterior, siempre que no se encuentre
        'Vendida' o 'Muerta'.
        Devuelve OK o el mensaje de error en Mensaje.
    */
    DECLARE pMensaje varchar(100);
    DECLARE pNroEstadoVaca int;
    DECLARE pFechaFin date;
    -- Manejo de error en la transacción
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		-- SHOW ERRORS;
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
	END;
    -- Controla Parámetros Vacios
    IF (pIdVaca IS NULL OR pIdVaca = 0) THEN
        SELECT 'Debe indicar la Vaca.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pEstado IS NULL OR pEstado = '') THEN
        SELECT 'Debe indicar la Estado.' Mensaje;
        LEAVE SALIR;
	END IF;
     -- Controla Parámetros Incorrectos    
    IF EXISTS(  
        SELECT v.IdVaca FROM Vacas v
        INNER JOIN EstadosVacas ev USING (IdVaca)
        WHERE   v.IdVaca = pIdVaca
                AND (ev.Estado <> 'Vendida' AND ev.Estado <> 'Muerta')
                AND ev.FechaFin IS NULL) THEN
        SELECT 'La Vaca se encuentra Vendida o Muerta, no puede cambiar de estado.' Mensaje;
        LEAVE SALIR;
	END IF;
    START TRANSACTION;
        SET pFechaFin = NULL;

        -- IF (pEstado = 'Vendida' OR pEstado = 'Muerta') THEN
        --     SET pFechaFin = NOW();
        -- END IF;

        -- Modifaca
        UPDATE EstadosVacas
        SET FechaFin = NOW()
        WHERE IdVaca = pIdVaca AND FechaFin IS NULL;

        SET pNroEstadoVaca = (SELECT COALESCE(MAX(NroEstadoVaca), 0)+1 FROM EstadosVacas WHERE IdVaca = pIdVaca);
        INSERT INTO EstadosVacas
        SELECT pIdVaca, pNroEstadoVaca, pEstado, NOW(), pFechaFin;

        SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;


-- -----------------------------------------------/ CAMBIAR LOTE VACA /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_cambiar_lote_vaca`; 
DELIMITER $$
CREATE PROCEDURE `tsp_cambiar_lote_vaca`(pIdVaca int, pIdLote int)
SALIR: BEGIN
    /*
        Permite cambiar el lote de una vaca finalidanzo el anterior, siempre que el lote solo este Activo.
        Devuelve OK o el mensaje de error en Mensaje.
    */
    DECLARE pMensaje varchar(100);
    DECLARE pNroVacaLote int;
    DECLARE pFechaFin date;
    -- Manejo de error en la transacción
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		-- SHOW ERRORS;
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
	END;
    -- Controla Parámetros Vacios
    IF (pIdVaca IS NULL OR pIdVaca = 0) THEN
        SELECT 'Debe indicar la Vaca.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pIdLote IS NULL OR pIdLote = 0) THEN
        SELECT 'Debe indicar el Lote.' Mensaje;
        LEAVE SALIR;
	END IF;
     -- Controla Parámetros Incorrectos    
    IF NOT EXISTS( SELECT IdLote FROM Lotes WHERE IdLote = pIdLote AND Estado = 'A' ) THEN
        SELECT 'El Lote indicado no es valido.' Mensaje;
        LEAVE SALIR;
	END IF;
    START TRANSACTION;
        -- Modifaca
        UPDATE VacasLote
        SET FechaFin = NOW()
        WHERE IdVaca = pIdVaca AND FechaFin IS NULL;

        SET pNroVacaLote = (SELECT COALESCE(MAX(NroVacaLote), 0)+1 FROM VacasLote WHERE IdVaca = pIdVaca);
        INSERT INTO VacasLote
        SELECT pIdVaca, pNroVacaLote, NOW(), NULL;

        SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;