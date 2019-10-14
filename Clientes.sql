-- -----------------------------------------------/ ALTA CLIENTE /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_alta_cliente`;
DELIMITER $$
CREATE PROCEDURE `tsp_alta_cliente`(pIdTambo int,pIdListaPrecio int, pApellido varchar(45),pNombre varchar (45),pTipoDoc char(5),pNroDoc varchar(45),pDatos json,pObservaciones text)
SALIR: BEGIN
	/*
	Permite dar de alta un Cliente, siempre que el NroDoc(de un mismo tipo de Doc)no este repetido dentro del mismo tambo.
    Devuelve OK+Id o el mensaje de error en Mensaje.
	*/
    DECLARE pMensaje varchar(100);
    DECLARE pIdCliente int ;
    DECLARE pEstado char(1);
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
    IF (pIdListaPrecio IS NULL OR pIdListaPrecio = 0) THEN
        SELECT 'Debe indicar una lista de precio.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pApellido IS NULL OR pApellido = '') THEN
        SELECT 'Debe ingresar el apellido del Cliente.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pTipoDoc IS NULL OR pTipoDoc = '') THEN
        SELECT 'Debe ingresar el Tipo de Doc del Cliente.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pNroDoc IS NULL OR pNroDoc = 0) THEN
        SELECT 'Debe ingresar el Nro Doc del Cliente.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pDatos IS NULL) THEN
        SELECT 'Debe indicar Datos del Cliente.' Mensaje;
        LEAVE SALIR;
    END IF;
    -- Controla Parametros Incorrectos
    IF NOT EXISTS(SELECT IdTambo FROM Tambos WHERE IdTambo = pIdTambo) THEN
        SELECT 'El Tambo seleccionado es inexistente.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF NOT EXISTS(SELECT IdListaPrecio FROM ListasPrecio WHERE IdListaPrecio = pIdListaPrecio) THEN
        SELECT 'La lista de precio seleccionada es inexistente.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF EXISTS(SELECT NroDoc FROM  Clientes WHERE  IdTambo= pIdTambo AND TipoDoc=pTipoDoc AND NroDoc=pNroDoc) THEN
		SELECT 'Ya existe dentro del Tambo un cliente con ese TipoDoc y NroDoc.' Mensaje;
		LEAVE SALIR;
	END IF;

    START TRANSACTION;
        SET pEstado = 'A';
        SET pIdCliente = (SELECT COALESCE(MAX(IdCliente), 0)+1 FROM Clientes);
	    INSERT INTO `Clientes` VALUES (pIdCliente,pIdTambo,pIdListaPrecio,pApellido,pNombre,pTipoDoc,pNroDoc,pEstado,pDatos,pObservaciones);
        SELECT CONCAT ('OK', pIdCliente) Mensaje;
	COMMIT;
END$$
DELIMITER ;
-- -----------------------------------------------/ MODIFICAR CLIENTE/----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_modificar_cliente`; 
DELIMITER $$
CREATE PROCEDURE `tsp_modificar_cliente`(pIdCliente int,pIdListaPrecio int,pApellido varchar(45),pNombre varchar (45),pTipoDoc char(5),pNroDoc varchar(45),pDatos json,pObservaciones text)
SALIR: BEGIN
/*
Permite modificar los datos de un Cliente, teniendo en cuenta que el NroDoc(de un mismo tipo de Doc)no este repetido dentro del mismo tambo .
Devuelve OK o el mensaje de error en Mensaje.
*/
DECLARE pMensaje varchar(100);
DECLARE pIdTambo int;
    -- Manejo de error en la transacción
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		-- SHOW ERRORS;
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
	END;
    -- Controla Parámetros Vacios
    IF (pIdCliente IS NULL OR pIdCliente = 0) THEN
        SELECT 'Debe indicar el IdCliente.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pIdListaPrecio IS NULL OR pIdListaPrecio = 0) THEN
        SELECT 'Debe indicar una lista de precio.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pApellido IS NULL OR pApellido = '') THEN
        SELECT 'Debe ingresar el apellido del Cliente.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pTipoDoc IS NULL OR pTipoDoc = '') THEN
        SELECT 'Debe ingresar el Tipo de Doc del Cliente.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pNroDoc IS NULL OR pNroDoc = '') THEN
        SELECT 'Debe ingresar el Nro Doc del Cliente.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pDatos IS NULL) THEN
        SELECT 'Debe indicar Datos del Cliente.' Mensaje;
        LEAVE SALIR;
    END IF;
    -- Control de Parámetros incorrectos
    IF NOT EXISTS(SELECT IdCliente FROM  Clientes  WHERE IdCliente = pIdCliente) THEN
		SELECT 'El Cliente indicado no existe.' Mensaje;
		LEAVE SALIR;
	END IF;
    SET pIdTambo = (SELECT IdTambo FROM Clientes WHERE IdCliente = pIdCliente);
	IF EXISTS(SELECT TipoDoc FROM Clientes WHERE IdTambo=pIdTambo AND TipoDoc=pTipoDoc AND NroDoc=pNroDoc AND IdCliente <> pIdCliente) THEN
		SELECT 'Ya existe otro Cliente con ese nro de doc(de un tipo de Doc)dentro del tambo.' Mensaje;
		LEAVE SALIR;
	END IF;       
	START TRANSACTION;  
			UPDATE  Clientes
			SET     IdListaPrecio = pIdListaPrecio, Apellido = pApellido, Nombre = pNombre, TipoDoc = pTipoDoc, NroDoc = pNroDoc, Datos = pDatos, Observaciones = pObservaciones
			WHERE   IdCliente = pIdCliente;
     SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;

-- -----------------------------------------------/ DAME CLIENTE /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_dame_cliente`;
DELIMITER $$
CREATE PROCEDURE `tsp_dame_cliente`(pIdCliente int)
SALIR: BEGIN
	/*
    Procedimiento que sirve para instanciar un Cliente desde la base de datos.
    */
	SELECT	*
    FROM	Clientes
    WHERE	IdCliente = pIdCliente;
END$$
DELIMITER ;
-- -----------------------------------------------/ BORRAR CLIENTE /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_borrar_cliente` ; 
DELIMITER $$
CREATE PROCEDURE `tsp_borrar_cliente`(pIdCliente int)
SALIR: BEGIN
	/*
	Permite borrar un Cliente controlando que no tenga ventas asociadas.
    Devuelve OK o un mensaje de error en Mensaje.
	*/
    DECLARE pMensaje varchar(100);
	-- Manejo de error en la transacción
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		-- SHOW ERRORS;
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
	END;
    -- Control de Parametros Vacios
    IF (pIdCliente IS NULL OR pIdCliente = 0 ) THEN
        SELECT 'El Id del Cliente no puede estar vacío.' Mensaje;
        LEAVE SALIR;
	END IF;
    -- Control de Parametros Incorrectos
    IF NOT EXISTS(SELECT IdCliente FROM Clientes WHERE IdCliente = pIdCliente) THEN
        SELECT 'El Cliente deseado es inexistente.' Mensaje;
        LEAVE SALIR;
	END IF;
	-- Control de Datos Asociados 
    IF EXISTS (SELECT IdCliente FROM Ventas WHERE IdCliente = pIdCliente) THEN
        SELECT 'El Cliente indicado no se puede borrar, tiene ventas asociadas.' Mensaje;
        LEAVE SALIR;
	END IF;
    START TRANSACTION;
        -- Borra 
        DELETE FROM Clientes WHERE IdCliente = pIdCliente;
        SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;
-- -----------------------------------------------/ BUSCAR CLIENTE /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_buscar_cliente`;
DELIMITER $$
CREATE PROCEDURE `tsp_buscar_cliente`(pIdTambo int,pIdCliente int, pCadena varchar(45),pIncluyeBajas char(1))
SALIR: BEGIN
	/*
	Permite buscar Clientes dentro de un tambo , indicando una cadena de búsqueda.
    Si pIdCliente=0 muestra todos los clientes del tambo.
	*/
    SELECT  *  
    FROM    Clientes
    WHERE   (Apellido LIKE CONCAT('%', pCadena, '%')
            OR NroDoc LIKE CONCAT('%', pCadena, '%')) 
            AND (IdTambo = pIdTambo)
            AND (IdCliente = pIdCliente OR pIdCliente = 0)
            AND (pIncluyeBajas = 'S'  OR Estado = 'A');
END$$
DELIMITER ;

-- -----------------------------------------------/ DAR DE BAJA UN CLIENTE /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_darbaja_cliente`; 
DELIMITER $$
CREATE PROCEDURE `tsp_darbaja_cliente`(pIdCliente int)
/*
Permite dar de baja un cliente, controlando que no este dado de baja ya.
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
    IF (pIdCliente IS NULL OR pIdCliente = 0) THEN
        SELECT 'Debe indicar un cliente.' Mensaje;
        LEAVE SALIR;
	END IF;	
    -- Control de Parámetros incorrectos
    IF NOT EXISTS(SELECT Idcliente FROM Clientes WHERE Idcliente = pIdCliente) THEN
		SELECT 'El Cliente indicado no existe.' Mensaje;
		LEAVE SALIR;
	END IF;
	IF EXISTS(SELECT IdCliente FROM Clientes WHERE IdCliente = pIdCliente AND Estado='B') THEN
		SELECT 'El cliente ya se encuentra dada de baja.' Mensaje;
		LEAVE SALIR;
	END IF; 
    START TRANSACTION; 
            -- Modifica el estado del lote
			UPDATE  Clientes SET  Estado = 'B' WHERE IdCliente = pIdCliente ;
     SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;

-- -----------------------------------------------/ ACTIVAR UN CLIENTE/----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_activar_cliente`; 
DELIMITER $$
CREATE PROCEDURE `tsp_activar_cliente`(pIdCliente int)
/*
Permite activar un cliente, controlando que no este no este activo ya. 
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
    IF (pIdCliente IS NULL OR pIdCliente = 0) THEN
        SELECT 'Debe indicar un cliente.' Mensaje;
        LEAVE SALIR;
	END IF;	
    -- Control de Parámetros incorrectos
    IF NOT EXISTS(SELECT IdCliente FROM Clientes WHERE IdCliente = pIdCliente) THEN
		SELECT 'El cliente indicado no existe.' Mensaje;
		LEAVE SALIR;
	END IF;
	IF EXISTS(SELECT IdCliente FROM Clientes WHERE IdCliente = pIdCliente AND Estado='A') THEN
		SELECT 'El cliente ya se encuentra activo.' Mensaje;
		LEAVE SALIR;
	END IF; 
    START TRANSACTION;  
			UPDATE  Clientes SET Estado = 'A' WHERE   IdCliente  = pIdCliente ;
     SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;