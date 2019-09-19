CREATE PROCEDURE `tsp_alta_sucursal` (pIdTambo int , pNombre varchar (45), pDatos json )
SALIR: BEGIN
	/*
	Permite dar de alta una Sucursal .
    Devuelve OK+Id o el mensaje de error en Mensaje.
	*/
	DECLARE pIdUsuarioAud int;
    DECLARE pIdTambo int;
    DECLARE pToken varchar(500);
	DECLARE pUsuarioAud varchar(100);
    DECLARE pMensaje varchar(100);
    DECLARE pNow datetime;
 -- Manejo de error en la transacción
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		-- show errors;
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
	END;
    SET pNow = now();
     -- Controla Parámetros
    -- CALL xsp_puede_ejecutar(pTokenAud, 'xsp_alta_usuario', pMensaje, pIdUsuarioAud);
    -- IF pMensaje != 'OK' THEN 
	-- 	SELECT pMensaje Mensaje;
    --     LEAVE SALIR;
	-- END IF;
    -- CONTROLES  PARA pIdTambo
      IF (pIdTambo IS NULL OR NOT EXISTS(SELECT IdTambo FROM Tambo WHERE IdTambo = pIdTambo)) THEN
        SELECT 'El Tambo seleccionado es inexistente.' Mensaje;
        LEAVE SALIR;
	END IF;
    -- CONTROLES  PARA pNombre
	IF (pNombre IS NULL OR pNombre = '') THEN
        SELECT 'Debe ingresar el Nombre de la Sucursal.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (LENGTH(pNombre) <> LENGTH(REPLACE(pNombre,' ',''))) THEN
        SELECT 'Caracter de espacio no permitido en el Nombre de la Sucursal.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF EXISTS(SELECT Nombre FROM  Sucursales WHERE Nombre = pNombre) THEN
		SELECT 'El nombre del usuario ya existe.' Mensaje;
		LEAVE SALIR;
	END IF;

 START TRANSACTION;
	INSERT INTO `TamboGestion`.`Sucursales` (`IdTambo`,`Nombre`,`Datos`) VALUES (pIdTambo,pNombre,pDatos);
    SELECT 'OK' Mensaje;
	COMMIT;
END
