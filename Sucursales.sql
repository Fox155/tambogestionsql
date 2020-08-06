-- -----------------------------------------------/ ALTA SUCURSAL /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_alta_sucursal`;
DELIMITER $$
CREATE PROCEDURE `tsp_alta_sucursal`(pIdTambo int , pNombre varchar (45), pDatos json)
SALIR: BEGIN
	/*
	Permite dar de alta una Sucursal, siempre el nombre de la misma no este repetido dentro del mismo tambo.
    Devuelve OK+Id o el mensaje de error en Mensaje.
	*/
    DECLARE pMensaje varchar(100);
    DECLARE pIdSucursal int ;
    DECLARE pIdRegistroLeche bigint;
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
    IF (pNombre IS NULL OR pNombre = '') THEN
        SELECT 'Debe ingresar el Nombre de la Sucursal.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pDatos IS NULL) THEN
        SELECT 'Debe indicar Datos de la sucursal.' Mensaje;
        LEAVE SALIR;
    END IF;
    -- Controla Parametros Incorrectos
    IF NOT EXISTS(SELECT IdTambo FROM Tambos WHERE IdTambo = pIdTambo) THEN
        SELECT 'El Tambo seleccionado es inexistente.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF EXISTS(SELECT Nombre FROM  Sucursales  WHERE  IdTambo= pIdTambo and Nombre=pNombre) THEN
		SELECT 'El nombre de la Sucursal ya existe dentro del Tambo.' Mensaje;
		LEAVE SALIR;
	END IF;

    START TRANSACTION;
        -- Insercion en Sucursales
	    INSERT INTO `Sucursales` 
        SELECT 0, pIdTambo, pNombre, pDatos, 0;

        SET pIdSucursal = LAST_INSERT_ID(); 

        -- Insercion de Usuarios administradores en las sucursales
        INSERT INTO UsuariosSucursales
        SELECT  u.IdUsuario, pIdSucursal, 1, NOW(), NULL
        FROM Usuarios u INNER JOIN TiposUsuarios t
        WHERE t.Tipo = 'Administrador' AND u.IdTambo = pIdTambo;

        SET pIdRegistroLeche = (SELECT COALESCE(MAX(IdRegistroLeche), 0)+1 FROM RegistrosLeche);
        -- Insercion del primer registro de la sucursal
        INSERT INTO RegistrosLeche
        SELECT pIdSucursal, pIdRegistroLeche, 0, NOW();

        SELECT CONCAT ('OK', pIdSucursal) Mensaje;
	COMMIT;
END$$
DELIMITER ;
-- -----------------------------------------------/ MODIFICAR SUCURSAL /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_modificar_sucursal`; 
DELIMITER $$
CREATE PROCEDURE `tsp_modificar_sucursal`(pIdSucursal int , pNombre varchar (45), pDatos json)
SALIR: BEGIN
/*
Permite modificar el nombre y/o los datos de una Sucursal, siempre que el nombre de la misma no este repetido dentro del mismo tambo .
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
    IF (pIdSucursal IS NULL) THEN
        SELECT 'El Id de la Sucursal no puede estar vacío.' Mensaje;
        LEAVE SALIR;
	END IF;
	IF (pNombre IS NULL OR pNombre = '') THEN
        SELECT 'El nombre de la sucursal no puede estar vacío.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (pDatos IS NULL) THEN
        SELECT 'Debe indicar Datos de la sucursal.' Mensaje;
        LEAVE SALIR;
    END IF;
    -- Control de Parámetros incorrectos
    IF NOT EXISTS(SELECT Nombre FROM  Sucursales  WHERE IdSucursal = pIdSucursal) THEN
		SELECT 'La sucursal indicada no existe.' Mensaje;
		LEAVE SALIR;
	END IF;
    SET pIdTambo = (SELECT IdTambo FROM Sucursales WHERE IdSucursal = pIdSucursal);
	IF EXISTS(SELECT Nombre FROM  Sucursales  WHERE IdTambo= pIdTambo and Nombre=pNombre and IdSucursal != pIdSucursal) THEN
		SELECT 'El nombre de la Sucursal ya existe dentro del tambo.' Mensaje;
		LEAVE SALIR;
	END IF;       
	START TRANSACTION;  
			UPDATE  Sucursales
			SET     Nombre = pNombre, Datos = pDatos
			WHERE   IdSucursal = pIdSucursal;
     SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;

-- -----------------------------------------------/ DAME SUCURSAL /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_dame_sucursal`;
DELIMITER $$
CREATE PROCEDURE `tsp_dame_sucursal`(pIdSucursal int)
SALIR: BEGIN
	/*
    Procedimiento que sirve para instanciar una Sucursal desde la base de datos.
    */
	SELECT	*, Datos->>"$.Direccion" Direccion, Datos->>"$.Telefono" Telefono, Datos->>"$.ApiKey" ApiKey
    FROM	Sucursales
    WHERE	IdSucursal = pIdSucursal;
END$$
DELIMITER ;
-- -----------------------------------------------/ BORRAR SUCURSAL /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_borrar_sucursal` ; 
DELIMITER $$
CREATE PROCEDURE `tsp_borrar_sucursal`(pIdSucursal int)
SALIR: BEGIN
	/*
	Permite borrar una Sucursal controlando que no tenga datos asociadas.
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
    IF (pIdSucursal IS NULL OR pIdSucursal = 0 ) THEN
        SELECT 'El Id de la Sucursal no puede estar vacío.' Mensaje;
        LEAVE SALIR;
	END IF;
    -- Control de Parametros Incorrectos
    IF NOT EXISTS(SELECT IdSucursal FROM Sucursales WHERE IdSucursal = pIdSucursal) THEN
        SELECT 'La sucursal deseada es  inexistente.' Mensaje;
        LEAVE SALIR;
	END IF;
	-- Control de Datos Asociados 
    IF EXISTS (SELECT IdSucursal FROM SesionesOrdeño WHERE IdSucursal = pIdSucursal) THEN
        SELECT 'La sucursal indicada no se puede borrar, tiene sesiones de ordeño asociados.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF EXISTS (SELECT IdSucursal FROM Lotes WHERE IdSucursal = pIdSucursal) THEN
        SELECT 'La sucursal indicada no se puede borrar, tiene lotes asociados' Mensaje;
        LEAVE SALIR;
	END IF;
    START TRANSACTION;
        -- Borra 
        DELETE FROM UsuariosSucursales WHERE IdSucursal = pIdSucursal;
        DELETE FROM RegistrosLeche WHERE IdSucursal = pIdSucursal;
        DELETE FROM Sucursales WHERE IdSucursal = pIdSucursal;
        SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;

-- -----------------------------------------------/ BUSCAR  SUCURSALES /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_buscar_sucursales`;
DELIMITER $$
CREATE PROCEDURE `tsp_buscar_sucursales`(pIdTambo int, pIdUsuario int, pCadena varchar(100))
SALIR: BEGIN
	/*
	Permite buscar Sucursales dentro de un tambo , indicando una cadena de búsqueda. 
	*/
    SELECT      s.*  
    FROM        Sucursales s
    INNER JOIN  UsuariosSucursales us USING(IdSucursal)
    WHERE       Nombre LIKE CONCAT('%', pCadena, '%') 
                AND (s.IdTambo = pIdTambo)
                AND (us.IdUsuario = pIdUsuario AND us.FechaHasta IS NULL);
END$$
DELIMITER ;

-- -----------------------------------------------/ RESUMEN REGISTRO DE LECHE /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_resumen_registroleche`;
DELIMITER $$
CREATE PROCEDURE `tsp_resumen_registroleche`(pIdSucursal int, pLimite int)
SALIR: BEGIN
	/*
	Permite buscar los ultimos registros de leche dentro de una Sucursal. 
	*/
    SELECT  JSON_ARRAYAGG(tt.Litros) 'Data', JSON_ARRAYAGG(tt.Fecha) 'Labels'
    FROM    (
        SELECT Litros, Fecha
        FROM RegistrosLeche
        WHERE   IdSucursal = pIdSucursal
        ORDER BY Fecha ASC
        LIMIT pLimite
    ) tt;
END$$
DELIMITER ;

-- -----------------------------------------------/ BUSCAR  SUCURSALES /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_listar_usuarios_sucursales`;
DELIMITER $$
CREATE PROCEDURE `tsp_listar_usuarios_sucursales`(pIdSucursal int)
SALIR: BEGIN
	/*
	Permite listar los Usuarios asignados a una Sucursal. 
	*/
    SELECT  u.*, tu.Tipo
    FROM    Sucursales s
    INNER JOIN UsuariosSucursales us USING(IdSucursal)
    INNER JOIN Usuarios u USING(IdUsuario)
    INNER JOIN TiposUsuarios tu USING(IdTipoUsuario)
    WHERE   s.IdSucursal = pIdSucursal
            AND us.FechaHasta IS NULL
            AND u.Estado = 'A';
END$$
DELIMITER ;

-- -----------------------------------------------/ DAME SUCURSAL POR APIKEY /----------------------------------------
DROP PROCEDURE IF EXISTS `tsp_dame_sucursal_por_apikey`;
DELIMITER $$
CREATE PROCEDURE `tsp_dame_sucursal_por_apikey`(pApikey varchar(500))
SALIR: BEGIN
	/*
    Procedimiento que sirve para instanciar una Sucursal desde la base de datos.
    */
	SELECT	*
    FROM	Sucursales
    WHERE	Datos->"$.ApiKey" = pApikey;
END$$
DELIMITER ;