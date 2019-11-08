-- -----------------------------------------------/ ALTA LISTA DE PRECIOS /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_alta_listaprecio`;
DELIMITER $$
CREATE PROCEDURE `tsp_alta_listaprecio`(pIdTambo int ,pLista varchar(45), pPrecio decimal(12,2))
SALIR: BEGIN
	/*
	Permite dar de alta una lista de precio, siempre que la lista no este repetido dentro del mismo tambo.
    Devuelve OK+Id o el mensaje de error en Mensaje.
	*/
    DECLARE pMensaje varchar(100);
    DECLARE pIdListaPrecio int;
    -- Manejo de error en la transacción
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		-- SHOW ERRORS;
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
	END;
    -- Controla Parámetros Vacios
     IF (pIdTambo IS NULL OR pIdTambo = 0) THEN
        SELECT 'Debe indicar el tambo.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pLista IS NULL OR pLista = '') THEN
        SELECT 'Debe ingresar el Nombre de la Lista de precios.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pPrecio IS NULL OR pPrecio = 0) THEN
        SELECT 'Debe indicar el precio.' Mensaje;
        LEAVE SALIR;
	END IF;
    -- Controla Parametros Incorrectos
    IF NOT EXISTS(SELECT IdTambo FROM Tambos WHERE IdTambo = pIdTambo) THEN
        SELECT 'El Tambo seleccionado es inexistente.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF EXISTS(SELECT Lista FROM  ListasPrecio  WHERE  IdTambo= pIdTambo and Lista=pLista) THEN
		SELECT 'El nombre de la lista de precios ya existe dentro del Tambo.' Mensaje;
		LEAVE SALIR;
	END IF;

    START TRANSACTION;
        -- Inserto
	    INSERT INTO `ListasPrecio`
        SELECT 0, pIdTambo, pLista, pPrecio, 'A';

        SET pIdListaPrecio = LAST_INSERT_ID();

        -- Historico
	    INSERT INTO HistoricoListasPrecio
        SELECT 0, pIdListaPrecio, pPrecio, NOW(), NULL;

        SELECT CONCAT ('OK', pIdListaPrecio) Mensaje;
	COMMIT;
END$$
DELIMITER ;

-- -----------------------------------------------/ MODIFICAR LISTA DE PRECIOS /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_modificar_listaprecio`; 
DELIMITER $$
CREATE PROCEDURE `tsp_modificar_listaprecio`(pIdListaPrecio int ,pLista varchar(45), pPrecio decimal(12,2))
SALIR: BEGIN
    /*
    Permite modificar el nombre de la lista y/o el precio de una lista de precio, siempre que el nombre de la misma no este repetido dentro del mismo tambo .
    Devuelve OK o el mensaje de error en Mensaje.
    */
    DECLARE pMensaje varchar(100);
    DECLARE pIdTambo int;
    DECLARE pPrecioAntiguo decimal(12,2);
    -- Manejo de error en la transacción
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		-- SHOW ERRORS;
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
	END;
    -- Controla Parámetros Vacios
    IF (pIdListaPrecio IS NULL OR pIdListaPrecio = 0 ) THEN
        SELECT 'El Id de la listaprecio no puede estar vacío.' Mensaje;
        LEAVE SALIR;
	END IF;
	IF (pLista IS NULL OR pLista = '') THEN
        SELECT 'La listaprecios no puede estar vacío.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pPrecio IS NULL OR pPrecio = 0) THEN
        SELECT 'Debe indicar el precio de la lista de precios.' Mensaje;
        LEAVE SALIR;
    END IF;
    -- Control de Parámetros incorrectos
    IF NOT EXISTS(SELECT Lista FROM  ListasPrecio  WHERE IdListaPrecio = pIdListaPrecio) THEN
		SELECT 'La lista de precio indicada no existe.' Mensaje;
		LEAVE SALIR;
	END IF;
    SET pIdTambo = (SELECT IdTambo FROM ListasPrecio WHERE IdListaPrecio = pIdListaPrecio);
	IF EXISTS(SELECT Lista FROM  ListasPrecio  WHERE IdTambo= pIdTambo and Lista=pLista and IdListaPrecio <> pIdListaPrecio) THEN
		SELECT 'La Lista de precio ya existe dentro del tambo.' Mensaje;
		LEAVE SALIR;
	END IF;       
	START TRANSACTION;
        SET pPrecioAntiguo = (SELECT Precio FROM ListasPrecio WHERE IdListaPrecio = pIdListaPrecio);
        -- Modifico
        UPDATE  ListasPrecio
        SET     Lista = pLista,
                Precio = pPrecio
        WHERE   IdListaPrecio = pIdListaPrecio;

        IF (pPrecio != pPrecioAntiguo) THEN
            -- Modifico Historico
            UPDATE  HistoricoListasPrecio
            SET     FechaFin = NOW()
            WHERE   IdListaPrecio = pIdListaPrecio;

            -- Inserto Historico
            INSERT INTO HistoricoListasPrecio
            SELECT 0, pIdListaPrecio, pPrecio, NOW(), NULL;
        END IF;

     SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;

-- -----------------------------------------------/ DAME LISTA DE PRECIOS /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_dame_listaprecio`;
DELIMITER $$
CREATE PROCEDURE `tsp_dame_listaprecio`(pIdListaPrecio int)
SALIR: BEGIN
	/*
    Procedimiento que sirve para instanciar una lista de precio desde la base de datos.
    */
	SELECT	*
    FROM	ListasPrecio
    WHERE	IdListaPrecio = pIdListaPrecio;
END$$
DELIMITER ;

-- -----------------------------------------------/ LISTAR HISTORICO LISTA DE PRECIOS /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_listar_historico_listaprecio`;
DELIMITER $$
CREATE PROCEDURE `tsp_listar_historico_listaprecio`(pIdListaPrecio int)
SALIR: BEGIN
	/*
    Procedimiento que sirve para listar el historico de todos los precios de una lista de precio.
    */
	SELECT	*
    FROM	HistoricoListasPrecio
    WHERE	IdListaPrecio = pIdListaPrecio
    ORDER BY IdHistoricoListaPrecio DESC, FechaInicio DESC, FechaFin DESC;
END$$
DELIMITER ;

-- -----------------------------------------------/ BORRAR LISTA DE PRECIOS /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_borrar_listaprecio` ; 
DELIMITER $$
CREATE PROCEDURE `tsp_borrar_listaprecio`(pIdListaPrecio int)
SALIR: BEGIN
	/*
	Permite borrar una lista de precio controlando que no tenga clientes asociados.
    Devuelve OK o un mensaje de error en Mensaje.
	*/
    DECLARE pMensaje varchar(100);
	-- Manejo de error en la transacción
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		SHOW ERRORS;
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
	END;
    -- Control de Parametros Vacios
    IF (pIdListaPrecio IS NULL OR pIdListaPrecio = 0 ) THEN
        SELECT 'El Id de la lista de precio no puede estar vacío.' Mensaje;
        LEAVE SALIR;
	END IF;
    -- Control de Parametros Incorrectos
    IF NOT EXISTS(SELECT IdListaPrecio FROM ListasPrecio WHERE IdListaPrecio = pIdListaPrecio) THEN
        SELECT 'La lista de precio deseada es inexistente.' Mensaje;
        LEAVE SALIR;
	END IF;
	-- Control de Datos Asociados 
    IF EXISTS (SELECT IdListaPrecio FROM Clientes WHERE IdListaPrecio = pIdListaPrecio) THEN
        SELECT 'La lista de precio indicada no se puede borrar, tiene Clientes asociados.' Mensaje;
        LEAVE SALIR;
	END IF;
    START TRANSACTION;
        -- Borra la lista de precio
        DELETE FROM ListasPrecio WHERE IdListaPrecio = pIdListaPrecio;

        -- Borra Historico
        DELETE FROM HistoricoListasPrecio WHERE IdListaPrecio = pIdListaPrecio;

        SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;

-- -----------------------------------------------/ BUSCAR LISTA DE PRECIOS /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_buscar_listaprecio`;
DELIMITER $$
CREATE PROCEDURE `tsp_buscar_listaprecio`(pIdTambo int, pIncluyeBajas char(1), pCadena varchar(100))
SALIR: BEGIN
	/*
	Permite buscar listas de precios dentro de un tambo , indicando una cadena de búsqueda y si incluye o no a las bajas. 
	*/
    SELECT  *  
    FROM    ListasPrecio
    WHERE   Lista LIKE CONCAT('%', pCadena, '%') 
            AND (IdTambo = pIdTambo)
            AND (pIncluyeBajas = 'S'  OR Estado = 'A');
END$$
DELIMITER ;

-- -----------------------------------------------/ DAR DE BAJA UNA LISTA DE PRECIOS /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_darbaja_listaprecio`; 
DELIMITER $$
CREATE PROCEDURE `tsp_darbaja_listaprecio`(pIdListaPrecio  int)
    /*
    Permite dar de baja una lista de precio, controlando que no este dado de baja ya.
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
    IF (pIdListaPrecio  IS NULL OR pIdListaPrecio  = 0) THEN
        SELECT 'Debe indicar una lista de precio.' Mensaje;
        LEAVE SALIR;
	END IF;	
    -- Control de Parámetros incorrectos
    IF NOT EXISTS(SELECT Lista FROM ListasPrecio WHERE IdListaPrecio  = pIdListaPrecio) THEN
		SELECT 'La lista de precios indicada no existe.' Mensaje;
		LEAVE SALIR;
	END IF;
	IF EXISTS(SELECT Lista FROM ListasPrecio WHERE  IdListaPrecio  = pIdListaPrecio  AND Estado='B') THEN
		SELECT 'La lista de precios ya se encuentra dada de baja.' Mensaje;
		LEAVE SALIR;
	END IF; 
    START TRANSACTION; 
            -- Modifica el estado del lote
			UPDATE  ListasPrecio SET  Estado = 'B' WHERE IdListaPrecio = pIdListaPrecio ;
     SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;

-- -----------------------------------------------/ ACTIVAR UNA LISTA DE PRECIOS /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_activar_listaprecio`; 
DELIMITER $$
CREATE PROCEDURE `tsp_activar_listaprecio`(pIdListaPrecio  int)
    /*
    Permite activar una lista de precio, controlando que no este no este activa ya. 
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
    IF (pIdListaPrecio  IS NULL OR pIdListaPrecio  = 0) THEN
        SELECT 'Debe indicar una lista de precio.' Mensaje;
        LEAVE SALIR;
	END IF;	
    -- Control de Parámetros incorrectos
    IF NOT EXISTS(SELECT Lista FROM ListasPrecio WHERE IdListaPrecio  = pIdListaPrecio) THEN
		SELECT 'La lista de precios indicada no existe.' Mensaje;
		LEAVE SALIR;
	END IF;
	IF EXISTS(SELECT Lista FROM ListasPrecio WHERE  IdListaPrecio  = pIdListaPrecio  AND Estado='A') THEN
		SELECT 'La lista de precios ya se encuentra activa.' Mensaje;
		LEAVE SALIR;
	END IF; 
    START TRANSACTION;  
			UPDATE  ListasPrecio SET Estado = 'A' WHERE   IdListaPrecio  = pIdListaPrecio ;
     SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;