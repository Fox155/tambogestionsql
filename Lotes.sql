-- -----------------------------------------------/ ALTA LOTE /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_alta_lote`;
DELIMITER $$
CREATE PROCEDURE `tsp_alta_lote`(pIdSucursal int , pNombre varchar (45))
SALIR: BEGIN
	/*
	Permite dar de alta una lote,siempre que el nombre del mismo no este repetido dentro de la misma sucursal.
    Devuelve OK+Id o el mensaje de error en Mensaje.
	*/
    DECLARE pMensaje varchar(100);
    DECLARE pIdlote varchar(100);
    DECLARE pEstado char(1);
    	-- Manejo de error en la transacción
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		-- SHOW ERRORS;
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
	END;
    -- Controla Parámetros Vacios
    IF (pIdSucursal IS NULL OR pIdSucursal = 0) THEN
        SELECT 'Debe indicar al Sucursal' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pNombre IS NULL OR pNombre = '') THEN
        SELECT 'Debe ingresar el Nombre del lote.' Mensaje;
        LEAVE SALIR;
	END IF;
    -- Controla Parámetros Incorrectos
    IF NOT EXISTS(SELECT IdSucursal FROM Sucursales WHERE IdSucursal = pIdSucursal) THEN
        SELECT 'La Sucursal seleccionada es inexistente.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF EXISTS(SELECT Nombre FROM  Lotes  WHERE  IdSucursal= pIdSucursal and Nombre=pNombre) THEN
		SELECT 'El nombre del lote ya existe.' Mensaje;
		LEAVE SALIR;
	END IF;
    START TRANSACTION;
        -- Insercion
        SET pEstado = 'A';
        INSERT INTO `Lotes` VALUES (DEFAULT,pIdSucursal,pNombre,pEstado);
        SET pIdlote = (select last_insert_id());
        SELECT CONCAT ('OK', pIdlote) Mensaje;
	COMMIT;
END$$
DELIMITER ;
-- -----------------------------------------------/ MODIFICAR LOTE /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_modificar_lote`;
DELIMITER $$
CREATE PROCEDURE `tsp_modificar_lote`(pIdlote int , pNombre varchar (45))
/*
Permite modificar el nombre de un lote, siempre que el nombre del mismo no este repetido dentro de la misma sucursal.
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
    IF (pIdlote IS NULL OR pIdlote = 0) THEN
        SELECT 'Debe indicar el lote.' Mensaje;
        LEAVE SALIR;
	END IF;
	IF (pNombre IS NULL OR pNombre = '') THEN
        SELECT 'El nombre del lote no puede estar vacío.' Mensaje;
        LEAVE SALIR;
	END IF;
    -- Control de Parámetros incorrectos
    IF NOT EXISTS(SELECT Nombre FROM  Lotes  WHERE Idlote = pIdlote) THEN
		SELECT 'El lote indicado no existe.' Mensaje;
		LEAVE SALIR;
	END IF;
    SET pIdSucursal = (SELECT IdSucursal FROM Lotes WHERE Idlote = pIdlote);
	IF EXISTS(SELECT Nombre FROM  Lotes  WHERE  IdSucursal = pIdSucursal and IdLote != pIdlote and Nombre=pNombre) THEN
		SELECT 'El nombre del lote ya existe dentro de la sucursal.' Mensaje;
		LEAVE SALIR;
	END IF;
    START TRANSACTION;
			UPDATE  Lotes
			SET     Nombre = pNombre
			WHERE   IdLote = pIdlote;
     SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;

-- -----------------------------------------------/ DAME LOTE /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_dame_lote`;
DELIMITER $$
CREATE PROCEDURE `tsp_dame_lote`(pIdlote int)
SALIR: BEGIN
	/*
    Procedimiento que sirve para instanciar un lote desde la base de datos.
    */
	SELECT	*
    FROM	Lotes
    WHERE	Idlote = pIdlote;
END$$
DELIMITER ;
-- -----------------------------------------------/ BORRAR LOTE /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_borrar_lote` ;
DELIMITER $$
CREATE PROCEDURE `tsp_borrar_lote`(pIdlote int)
SALIR: BEGIN
	/*
	Permite borrar un lote controlando que no tenga datos asociadas.
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
    IF (pIdlote IS NULL OR pIdlote = 0) THEN
        SELECT 'El Lote no puede estar vacio' Mensaje;
        LEAVE SALIR;
	END IF;
    -- Control de Parámetros incorrectos
    IF NOT EXISTS(SELECT Idlote FROM Lotes WHERE Idlote = pIdlote) THEN
        SELECT 'El Lote deseado es inexistente.' Mensaje;
        LEAVE SALIR;
	END IF;
	-- Control de Datos Asociados
    IF EXISTS (SELECT Idlote FROM VacasLote WHERE IdLote = pIdlote) THEN
        SELECT 'El lote indicado no se puede borrar, tiene un ganado asociados.' Mensaje;
        LEAVE SALIR;
	END IF;

    START TRANSACTION;
        -- Borra
        DELETE FROM Lotes WHERE IdLote = pIdlote;
        SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;

-- -----------------------------------------------/ BUSCAR  LOTES /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_buscar_lotes`;
DELIMITER $$
CREATE PROCEDURE `tsp_buscar_lotes`(pIdSucursal int,pIdTambo int, pIncluyeBajas char(1), pCadena varchar(100))
SALIR: BEGIN
	/*
	Permite buscar Lotes dentro de una Sucursal , indicando una cadena de búsqueda.
    Si pIdSucursal = 0 lista para todos los Lotes de todas las sucursales.
	*/
    SELECT  s.Nombre Sucursal,COUNT(vl.IdVaca) AS Ganado , l.*, CONCAT(l.Nombre, ' - ', s.Nombre) LoteSucursal
    FROM    Lotes l
    INNER JOIN VacasLote vl on vl.IdLote = l.IdLote
    INNER JOIN Sucursales s USING(IdSucursal)
    INNER JOIN Vacas v ON vl.IdVaca = v.IdVaca
    INNER JOIN EstadosVacas ev ON ev.IdVaca = v.IdVaca
    WHERE   l.Nombre LIKE CONCAT('%', pCadena, '%')
            AND vl.FechaEgreso IS NULL
            AND ev.FechaFin IS NULL
            AND (ev.Estado <> 'VENDIDA' AND ev.Estado <> 'MUERTA' AND ev.Estado <> 'BAJA')
            AND (IdTambo = pIdTambo)
            AND (IdSucursal = pIdSucursal OR pIdSucursal = 0)
            AND (pIncluyeBajas = 'S'  OR l.Estado = 'A')
    GROUP BY l.IdLote
    ORDER BY s.Nombre,l.nombre;
END$$
DELIMITER ;

-- -----------------------------------------------/ DAR DE BAJA UN LOTE /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_darbaja_lote`;
DELIMITER $$
CREATE PROCEDURE `tsp_darbaja_lote`(pIdlote int)
/*
Permite dar de baja un lote, controlando que no este dado de baja ya.
 -- >Por agregar: pConfirmacion char(1) Si recibe 'S' en confirmacion dara de baja a todas las vacas del lote.
Devuelve OK o el mensaje de error en Mensaje.
*/
SALIR: BEGIN
DECLARE pMensaje varchar(100);
-- Manejo de error en la transacción
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		-- SHOW ERRORS;
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
	END;
    -- Controla Parámetros Vacios
    IF (pIdlote IS NULL OR pIdlote = 0) THEN
        SELECT 'Debe indicar el lote.' Mensaje;
        LEAVE SALIR;
	END IF;
    -- IF (pConfirmacion IS NULL OR pIdlote = 0) THEN
    --     SELECT 'Debe indicar un valor para la confirmacion de bajas de las vacas.' Mensaje;
    --     LEAVE SALIR;
	-- END IF;

    -- Control de Parámetros incorrectos
    IF NOT EXISTS(SELECT Nombre FROM  Lotes  WHERE IdLote = pIdlote) THEN
		SELECT 'El lote indicado no existe.' Mensaje;
		LEAVE SALIR;
	END IF;
	IF EXISTS(SELECT Estado FROM  Lotes  WHERE  IdLote = pIdlote AND Estado='B') THEN
		SELECT 'El Lote ya se encuentra dado de baja.' Mensaje;
		LEAVE SALIR;
	END IF;
    START TRANSACTION;
            -- Modifica el estado del lote
			UPDATE  Lotes SET  Estado = 'B' WHERE   IdLote = pIdlote;
     SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;

-- -----------------------------------------------/ ACTIVAR UN LOTE /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_activar_lote`;
DELIMITER $$
CREATE PROCEDURE `tsp_activar_lote`(pIdlote int)
/*
Permite activar un lote, controlando que no este no este activoya.
Devuelve OK o el mensaje de error en Mensaje.
*/
SALIR: BEGIN
DECLARE pMensaje varchar(100);
-- Manejo de error en la transacción
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		-- SHOW ERRORS;
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
	END;
    -- Controla Parámetros Vacios
    IF (pIdlote IS NULL OR pIdlote = 0) THEN
        SELECT 'Debe indicar el lote.' Mensaje;
        LEAVE SALIR;
	END IF;
    -- Control de Parámetros incorrectos
    IF NOT EXISTS(SELECT Nombre FROM  Lotes  WHERE IdLote = pIdlote) THEN
		SELECT 'El lote indicado no existe.' Mensaje;
		LEAVE SALIR;
	END IF;
	IF EXISTS(SELECT Estado FROM  Lotes  WHERE  IdLote = pIdlote AND Estado='A') THEN
		SELECT 'El Lote ya se encuentra dado Activo.' Mensaje;
		LEAVE SALIR;
	END IF;
    START TRANSACTION;
			UPDATE  Lotes SET Estado = 'A' WHERE   IdLote = pIdlote;
     SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;

-- -----------------------------------------------/ LISTAR RESUMEN PRODUCCIONES LOTE /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_listar_resumen_producciones_lote`;
DELIMITER $$
CREATE PROCEDURE `tsp_listar_resumen_producciones_lote`(pIdLote int, pFechaInicio date, pFechaFin date)
SALIR: BEGIN
	/*
	Permite listar las producciones de la ultima lactancia de una Vaca, en funcion de sus sesiones de ordeñe. 
	*/
    IF (pFechaInicio IS NOT NULL AND pFechaFin IS NOT NULL) THEN
        SELECT  JSON_ARRAYAGG(tt.Producciones) 'Data', JSON_ARRAYAGG(tt.Fecha) 'Labels'
        FROM (
            SELECT SUM(p.Produccion) Producciones, DATE_FORMAT(so.Fecha, '%d de %M %Y') Fecha
            FROM Producciones p
            INNER JOIN SesionesOrdeño so USING(IdSesionOrdeño)
            INNER JOIN Lactancias l ON p.IdVaca = l.IdVaca AND p.NroLactancia=l.NroLactancia
            INNER JOIN Vacas v ON v.IdVaca = l.IdVaca
            INNER JOIN VacasLote vl ON vl.IdVaca = v.IdVaca
            WHERE   vl.IdLote = pIdLote
                    AND so.Fecha BETWEEN pFechaInicio AND pFechaFin
            GROUP BY so.Fecha
            ORDER BY so.Fecha ASC
        ) tt;
    ELSE
        SELECT  JSON_ARRAYAGG(tt.Producciones) 'Data', JSON_ARRAYAGG(tt.Fecha) 'Labels'
        FROM (
            SELECT SUM(p.Produccion) Producciones, DATE_FORMAT(so.Fecha, '%d de %M %Y') Fecha
            FROM Producciones p
            INNER JOIN SesionesOrdeño so USING(IdSesionOrdeño)
            INNER JOIN Lactancias l ON p.IdVaca = l.IdVaca AND p.NroLactancia=l.NroLactancia
            INNER JOIN Vacas v ON v.IdVaca = l.IdVaca
            INNER JOIN VacasLote vl ON vl.IdVaca = v.IdVaca
            WHERE   vl.IdLote = pIdLote
                    AND so.Fecha BETWEEN DATE_SUB(NOW(), INTERVAL 30 DAY) AND NOW()
            GROUP BY so.Fecha
            ORDER BY so.Fecha ASC
        ) tt;
    END IF;
END$$
DELIMITER ;