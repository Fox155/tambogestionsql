DROP PROCEDURE IF EXISTS `tsp_alta_usuario`;
DELIMITER $$
CREATE PROCEDURE `tsp_alta_usuario`(pTokenAud varchar(500), pIdTipoUsuario tinyint, pUsuario varchar(100), 
pPassword varchar(255), pEmail varchar(100), pIdsSucursales text)
SALIR:BEGIN
	/*
    Permite dar de alta un Usuario controlando que el nombre del usuario no exista ya, siendo nombres y apellidos obligatorios.
    Se guarda el password hash de la contraseña. El correo electrónico no debe existir ya. El tipo de usuario debe existir. 
    Devuelve OK + Id o el mensaje de error en Mensaje.
    */
    DECLARE pIdUsuarioAud int;
    DECLARE pIdTambo int;
    DECLARE pToken varchar(500);
	DECLARE pUsuarioAud varchar(100);
    DECLARE pMensaje varchar(100);
    DECLARE pNow datetime;
	DECLARE pIdUsuario int;
	DECLARE pTipo varchar(45);
    -- Manejo de error en la transacción
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		-- SHOW ERRORS;
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
	END;
    -- Controla Parámetros Vacios
	IF (pUsuario IS NULL OR pUsuario = '') THEN
        SELECT 'Debe ingresar el usuario.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF (LENGTH(pUsuario) <> LENGTH(REPLACE(pUsuario,' ',''))) THEN
        SELECT 'Caracter de espacio no permitido en el nombre de usuario.' Mensaje;
        LEAVE SALIR;
	END IF;
    IF EXISTS(SELECT Usuario FROM Usuarios WHERE Usuario = pUsuario) THEN
		SELECT 'El nombre del usuario ya existe.' Mensaje;
		LEAVE SALIR;
	END IF;
    IF (pEmail IS NULL OR pEmail = '') THEN
        SELECT 'Debe ingresar el correo electrónico del usuario.' Mensaje;
        LEAVE SALIR;
	END IF;
	IF EXISTS(SELECT Email FROM Usuarios WHERE Email = pEmail) THEN
		SELECT 'El correo electrónico del usuario ya existe.' Mensaje;
		LEAVE SALIR;
	END IF;
	IF (pIdTipoUsuario IS NULL OR pIdTipoUsuario = 0) THEN
        SELECT 'Debe ingresar el tipo de usuario.' Mensaje;
        LEAVE SALIR;
	END IF;

	-- Controla Parámetros Incorrectos
    IF NOT EXISTS(SELECT IdTipoUsuario FROM TiposUsuarios WHERE IdTipoUsuario = pIdTipoUsuario) THEN
        SELECT 'El tipo de usuario seleccionado es inexistente.' Mensaje;
        LEAVE SALIR;
	END IF;

	SET pTipo = (SELECT Tipo FROM TiposUsuarios WHERE IdTipoUsuario = pIdTipoUsuario);

	SELECT IdUsuario INTO pIdUsuarioAud
	FROM Usuarios u INNER JOIN Tambos t USING(IdTambo)
	INNER JOIN	TiposUsuarios tu USING(IdTipoUsuario)
    WHERE		u.Token = pTokenAud AND u.Estado = 'A'
	LIMIT		1;

	IF (pIdUsuarioAud IS NULL) THEN
		SELECT 'Usted no posee permisos para realizar esta acción.' Mensaje;
        LEAVE SALIR;
	END IF;

	IF NOT EXISTS(SELECT tu.IdTipoUsuario FROM TiposUsuarios tu
		INNER JOIN Usuarios u USING(IdTipoUsuario) WHERE u.IdUsuario = pIdUsuarioAud AND tu.Tipo = 'Administrador') THEN
        SELECT 'Usted no posee permisos para realizar esta acción.' Mensaje;
        LEAVE SALIR;
	END IF;

	IF NOT EXISTS (SELECT IdTambo FROM Tambos t INNER JOIN Usuarios u USING(IdTambo) WHERE t.Estado = 'A' AND u.IdUsuario = pIdUsuarioAud) THEN
		SELECT 'Usted no posee permisos para realizar esta acción, su tambo no está habilitada.' Mensaje;
		LEAVE SALIR;
    END IF;

	IF (pTipo != 'Administrador') THEN
		IF NOT EXISTS (SELECT tt.IdSucursal
			FROM (SELECT 
				JSON_EXTRACT(pIdsSucursales, CONCAT('$[', B._row, ']')) IdSucursal
				FROM (SELECT pIdsSucursales AS B) AS A
				INNER JOIN t_list_row AS B ON B._row < JSON_LENGTH(pIdsSucursales)
			) tt
			INNER JOIN Sucursales USING(IdSucursal) ) THEN
			SELECT 'Sucursales invalidas.' Mensaje;
			LEAVE SALIR;
		END IF;

		-- IF NOT EXISTS (SELECT tt.IdListaPrecio
		-- 	FROM JSON_TABLE(pIdsListaPrecio,"$[*]"
		-- 		COLUMNS(pseudoid FOR ORDINALITY,
		-- 		IdListaPrecio VARCHAR(100) PATH "$")) tt
		-- 	INNER JOIN ListasPrecio lp USING(IdListaPrecio) WHERE lp.Estado = 'A') THEN
		-- 	SELECT 'Todas las listas de precio indicadas deben estar activas.' Mensaje;
		-- 	LEAVE SALIR;
		-- END IF;
	END IF;
	
    START TRANSACTION;
		SET pNow = NOW();

		SELECT Usuario, IdTambo INTO pUsuarioAud, pIdTambo FROM Usuarios WHERE IdUsuario = pIdUsuarioAud;
        
        SET pToken = (SELECT SHA2(RAND(), 512));
        INSERT INTO Usuarios VALUES (DEFAULT ,pIdTambo, pIdTipoUsuario, pUsuario, pEmail, pPassword, pToken, 0, pNow, 'A');

		SET pIdUsuario = LAST_INSERT_ID();

		-- Insercion de UsuariosSucursales
		IF (pTipo = 'Administrador') THEN
			INSERT INTO UsuariosSucursales
			SELECT      1, pIdUsuario, s.IdSucursal, pNow, NULL
			FROM Sucursales s WHERE IdTambo = pIdTambo;
		ELSE
			INSERT INTO UsuariosSucursales
			SELECT      1, pIdUsuario, tt.IdSucursal, pNow, NULL
			FROM (SELECT 
				JSON_EXTRACT(pIdsSucursales, CONCAT('$[', B._row, ']')) IdSucursal
				FROM (SELECT pIdsSucursales AS B) AS A
				INNER JOIN t_list_row AS B ON B._row < JSON_LENGTH(pIdsSucursales)
			) tt
			INNER JOIN Sucursales USING(IdSucursal);

			-- INSERT INTO UsuariosSucursales
			-- SELECT      1, pIdUsuario, tt.IdSucursal, pNow, NULL
			-- FROM JSON_TABLE(pIdsSucursales,"$[*]"
			-- 	COLUMNS(pseudoid FOR ORDINALITY,
			-- 	IdSucursal VARCHAR(100) PATH "$")) tt;
		END IF;       
        SELECT CONCAT('OK') Mensaje;
	COMMIT;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS `tsp_modificar_usuario`;
DELIMITER $$
CREATE PROCEDURE `tsp_modificar_usuario`(pToken varchar(500), pIdUsuario bigint,
pIdTipoUsuario tinyint, pEmail varchar(100))
SALIR: BEGIN
	/*
	Permite modificar un Usuario existente. No se puede cambiar el nombre de usuario, ni la contraseña.
	Los nombres y apellidos son obligatorios. El correo electrónico no debe existir ya.
	Devuelve OK o el mensaje de error en Mensaje.
	*/
	DECLARE pIdUsuarioGestion int;
    DECLARE pUsuario varchar(100);
	DECLARE pUsuarioAud varchar(100);
    DECLARE pMensaje varchar(100);
	-- Manejo de error en la transacción
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		-- SHOW ERRORS;
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
	END;
    -- Controla Parámetros Vacios
	IF (pEmail IS NULL OR pEmail = '') THEN
        SELECT 'Debe ingresar un valor para el campo email.' Mensaje;
        LEAVE SALIR;
	END IF;
	IF (pIdTipoUsuario IS NULL OR pIdTipoUsuario = 0) THEN
        SELECT 'Debe ingresar el tipo de usuario.' Mensaje;
        LEAVE SALIR;
	END IF;
	-- Control de Parámetros incorrectos
	IF EXISTS (SELECT IdUsuario FROM Usuarios WHERE Email = pEmail AND IdUsuario != pIdUsuario) THEN
        SELECT 'Otro usuario tiene el mismo email.' Mensaje;
        LEAVE SALIR;
	END IF;
	IF NOT EXISTS(SELECT u.IdUsuario FROM Usuarios u
	INNER JOIN TiposUsuarios tu WHERE Token = pToken AND tu.Tipo = 'Administrador') THEN
		SELECT 'Usted no posee permisos para realizar esta acción.' Mensaje;
		LEAVE SALIR; 
	END IF;

    START TRANSACTION;
		SET pUsuarioAud = (SELECT Usuario FROM Usuarios WHERE IdUsuario = pIdUsuarioGestion);
		-- Modifica
        UPDATE Usuarios 
		SET		Email=pEmail,
				IdTipoUsuario=pIdTipoUsuario
		WHERE	IdUsuario=pIdUsuario;
        SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS `tsp_borra_usuario`;
DELIMITER $$
CREATE PROCEDURE `tsp_borra_usuario`(pToken varchar(500), pIdUsuario int)
SALIR: BEGIN
	/*
    Permite borrar un Usuario existente controlando que no existan Sucursales asociadas.
    No puede borrar el usuario 1, administrador.
	Devuelve OK o el mensaje de error en Mensaje.
    */
    DECLARE pIdUsuarioAud int;
	DECLARE pUsuarioAud varchar(100);
    DECLARE pMensaje varchar(100);
    -- Manejo de error en la transacción
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
	END;
    -- Controla parámetros
	IF pIdUsuario = 1 THEN
		SELECT 'No puede borrar el usuario administrador.' Mensaje;
		LEAVE SALIR;
	END IF;
    -- Control de parámetros incorrectos
	IF EXISTS(SELECT IdUsuario FROM UsuariosSucursales WHERE IdUsuario = pIdUsuario) THEN
		SELECT 'No se puede borrar el usuario, se encuentra asociado a sucursales.' Mensaje;
		LEAVE SALIR; 
	END IF;
	IF NOT EXISTS(SELECT u.IdUsuario FROM Usuarios u
	INNER JOIN TiposUsuarios tu WHERE Token = pToken AND tu.Tipo = 'Administrador') THEN
		SELECT 'Usted no posee permisos para realizar esta acción.' Mensaje;
		LEAVE SALIR; 
	END IF;
    -- Borra el usuario
    START TRANSACTION;
        DELETE FROM Usuarios WHERE IdUsuario = pIdUsuario;
        
        SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS `tsp_dame_usuario`;
DELIMITER $$
CREATE PROCEDURE `tsp_dame_usuario`(pIdUsuario int)
PROC: BEGIN
	/*
    Permite instanciar un usuario desde la base de datos.
    */
    SELECT	u.*, tu.Tipo TipoUsuario, JSON_ARRAYAGG(us.IdSucursal) IdsSucursales
    FROM 	Usuarios u
	INNER JOIN TiposUsuarios tu USING(IdTipoUsuario)
    LEFT JOIN UsuariosSucursales us USING(IdUsuario)
    WHERE	u.IdUsuario = pIdUsuario;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS `tsp_buscar_usuarios`;
DELIMITER $$
CREATE PROCEDURE `tsp_buscar_usuarios`(pIdTambo int, pCadena varchar(30), pEstado char(1), pIdTipoUsuario tinyint)
BEGIN
	/*
    Permite buscar los usuarios de un tambo dada una cadena de búsqueda, estado (T: todos los estados),
    Tipo de Usuario (0: para listar todos). Si la cadena de búsqueda es un texto, busca por usuario o email.
	Para listar todos, cadena vacía.
    */
	SELECT		u.*, tu.Tipo TipoUsuario
    FROM		Usuarios u
    INNER JOIN	Tambos t USING(IdTambo)
    INNER JOIN	TiposUsuarios tu USING(IdTipoUsuario)
    WHERE		t.IdTambo = pIdTambo
				AND (u.Estado = pEstado OR pEstado = 'T')
                AND (tu.IdTipoUsuario = pIdTipoUsuario OR pIdTipoUsuario = 0)
                AND (
						u.Usuario LIKE CONCAT('%', pCadena, '%') OR
                        u.Email LIKE CONCAT('%', pCadena, '%')
					)
	ORDER BY	u.Usuario;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS `tsp_activar_usuario`;
DELIMITER $$
CREATE PROCEDURE `tsp_activar_usuario`(pToken varchar(500), pIdUsuario int)
SALIR: BEGIN
	/*
    Permite cambiar el estado del Usuario a Activo siempre y cuando no esté activo ya. 
    Devuelve OK o el mensaje de error en Mensaje.
    */
    DECLARE pIdUsuarioAud int;
	DECLARE pUsuarioAud varchar(100);
    DECLARE pMensaje varchar(100);
    -- Manejo de errores
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
	END;
    -- Control de parámetros vacíos
    IF (pIdUsuario IS NULL OR pIdUsuario = 0) THEN
		SELECT 'Debe indicar un usuario.' Mensaje;
        LEAVE SALIR;
	END IF;
    -- Control de parámetros incorrectos
    IF EXISTS(SELECT Estado FROM Usuarios WHERE IdUsuario = pIdUsuario AND Estado = 'A') THEN
		SELECT 'El usuario ya está activado.' Mensaje;
        LEAVE SALIR;
	END IF;
	IF NOT EXISTS(SELECT u.IdUsuario FROM Usuarios u
	INNER JOIN TiposUsuarios tu WHERE Token = pToken AND tu.Tipo = 'Administrador') THEN
		SELECT 'Usted no posee permisos para realizar esta acción.' Mensaje;
		LEAVE SALIR; 
	END IF;
    
	START TRANSACTION;
		-- Activa
		UPDATE Usuarios SET Estado = 'A' WHERE IdUsuario = pIdUsuario;
		
        SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS `tsp_dar_baja_usuario`;
DELIMITER $$
CREATE PROCEDURE `tsp_dar_baja_usuario`(pToken varchar(500), pIdUsuario int)
SALIR: BEGIN
	/*
    Permite cambiar el estado del Usuario a Baja siempre y cuando no esté dado de baja ya. 
    Devuelve OK o el mensaje de error en Mensaje.
    */
    DECLARE pIdUsuarioAud int;
	DECLARE pUsuarioAud varchar(100);
    DECLARE pMensaje varchar(100);
    -- Manejo de errores
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
	END;
    -- Control de parámetros vacíos
    IF (pIdUsuario IS NULL OR pIdUsuario = 0) THEN
		SELECT 'Debe indicar un usuario.' Mensaje;
        LEAVE SALIR;
	END IF;
    -- Control de parámetros incorrectos
    IF EXISTS(SELECT Estado FROM Usuarios WHERE IdUsuario = pIdUsuario AND Estado = 'B') THEN
		SELECT 'El usuario ya se encuentra dado de baja.' Mensaje;
        LEAVE SALIR;
	END IF;
	IF NOT EXISTS(SELECT u.IdUsuario FROM Usuarios u
	INNER JOIN TiposUsuarios tu WHERE Token = pToken AND tu.Tipo = 'Administrador') THEN
		SELECT 'Usted no posee permisos para realizar esta acción.' Mensaje;
		LEAVE SALIR; 
	END IF;
    
	START TRANSACTION;
		-- Activa
		UPDATE Usuarios SET Estado = 'B' WHERE IdUsuario = pIdUsuario;
		
        SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS `tsp_login`;
DELIMITER $$
CREATE PROCEDURE `tsp_login`(pUsuario varchar(100), pEsPassValido char(1), pToken varchar(500), pApp varchar(50))
PROC: BEGIN
    DECLARE pIdUsuario int;
	DECLARE pIdTambo int;
    -- Manejo de errores en la transacción
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
		BEGIN
			-- SHOW ERRORS;
			SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
            ROLLBACK;
		END;
	-- Control de parámetros vacíos
    IF pApp NOT IN ('A') OR pApp IS NULL OR pApp = '' OR pEsPassValido NOT IN ('S','N') OR pEsPassValido IS NULL OR pEsPassValido = '' THEN
		SELECT 'Parámetros incorrectos.' Mensaje;
        LEAVE PROC;
	END IF;
    IF pUsuario IS NULL OR pUsuario = '' THEN
		SELECT 'Debe indicar un usuario.' Mensaje;
        LEAVE PROC;
	END IF;
    IF NOT EXISTS (SELECT IdUsuario FROM Usuarios WHERE Usuario = pUsuario AND Estado != 'B') THEN
		SELECT 'El usuario indicado no existe en el sistema o se encuentra dado baja.' Mensaje;
        LEAVE PROC;
	END IF;
    
    IF EXISTS (SELECT IdUsuario FROM Usuarios WHERE Usuario = pUsuario AND IdTipoUsuario IS NULL) THEN
		SELECT 'No tiene permisos para acceder a esta aplicación.' Mensaje;
        LEAVE PROC;
	END IF;
    
    SET pIdTambo = (SELECT t.IdTambo FROM Usuarios u INNER JOIN Tambos t USING(IdTambo) WHERE u.Usuario = pUsuario AND t.Estado = 'A');
	IF pIdTambo IS NULL THEN
		SELECT 'El tambo al que intenta acceder se encuentra dada de baja.' Mensaje;
        LEAVE PROC;
	END IF;
    SET pIdUsuario = (SELECT IdUsuario FROM Usuarios WHERE Usuario = pUsuario AND IdTambo = pIdTambo);
    IF NOT EXISTS (SELECT IdUsuario FROM Usuarios WHERE IdUsuario = pIdUsuario 
    AND IdTipoUsuario IS NOT NULL) THEN
		SELECT 'No tiene permiso para acceder a esta aplicación.' Mensaje;
        LEAVE PROC;
	END IF;
    
	START TRANSACTION;
		CASE pEsPassValido 
        WHEN 'N' THEN 
			BEGIN
				IF (SELECT IntentosPass FROM Usuarios WHERE Usuario = pUsuario) < 3 THEN					
					UPDATE	Usuarios 
					SET		IntentosPass = IntentosPass + 1
					WHERE	IdUsuario = pIdUsuario;
					
					SELECT 'Usuario y/o contraseña incorrectos. Ante repetidos intentos fallidos de inicio de sesión, la cuenta se suspenderá.' Mensaje;
					COMMIT;
					LEAVE PROC;
				END IF;
				
				IF (SELECT IntentosPass FROM Usuarios WHERE Usuario = pUsuario) >= 5 THEN
				
					UPDATE	Usuarios
					SET		Estado = 'S'
					WHERE	Usuario = pUsuario;
					
					SELECT 'Cuenta suspendida por superar cantidad máxima de intentos de inicio de sesión.' Mensaje;
					COMMIT;
					LEAVE PROC;
				END IF;
			END;
		WHEN 'S' THEN
			BEGIN              
                UPDATE	Usuarios
                SET		Token = pToken,
                        IntentosPass = 0
				WHERE	IdUsuario = pIdUsuario;
                
                COMMIT;
            END;
        END CASE;     
	CASE pApp
		WHEN 'A' THEN
			SELECT 		'OK' Mensaje, u.IdUsuario, u.IdTipoUsuario, u.Usuario, u.Token, u.Email,
						u.Estado, tu.Tipo TipoUsuario, JSON_ARRAYAGG(us.IdSucursal) IdsSucursales
			FROM 	Usuarios u
			INNER JOIN TiposUsuarios tu USING(IdTipoUsuario)
			LEFT JOIN UsuariosSucursales us USING(IdUsuario)
			WHERE	u.IdUsuario = pIdUsuario;
	END CASE;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS `tsp_logout`;
DELIMITER $$
CREATE PROCEDURE `tsp_logout`(pToken varchar(500))
PROC: BEGIN
	/*
    Devuelve OK o el mensaje de error en Mensaje.
    */
	DECLARE pIdUsuario bigint;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		-- show errors;
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
		ROLLBACK;
	END;
    IF NOT EXISTS (SELECT IdUsuario FROM Usuarios WHERE Token = pToken) THEN
		SELECT 'OK' Mensaje;
        LEAVE PROC;
    END IF;
    SET pIdUsuario = (SELECT IdUsuario FROM Usuarios WHERE Token = pToken);
	SELECT 'OK' Mensaje;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS `tsp_cambiar_password`;
DELIMITER $$
CREATE PROCEDURE `tsp_cambiar_password`(pModo char(1), pToken varchar(500), pPasswordNew varchar(255))
SALIR: BEGIN
    DECLARE pIdUsuario int;
	DECLARE pUsuario varchar(120);
    -- Manejo de error en la transacción
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
	END;
    -- Controlo parámetros
    IF pModo IN ('U','A') AND NOT EXISTS(SELECT Token FROM Usuarios WHERE Token = pToken) THEN
		SELECT 'No se puede cambiar la contraseña. No es una sesión válida.' Mensaje;
        LEAVE SALIR;
    END IF;
	IF pModo IN ('U','A') AND NOT EXISTS(SELECT Token FROM Usuarios WHERE Token = pToken AND Estado != 'B') THEN
		SELECT 'No se puede cambiar la contraseña. El usuario no está activo.' Mensaje;
        LEAVE SALIR;
	END IF;

    SET pIdUsuario = (SELECT IdUsuario FROM Usuarios WHERE Token = pToken);

    START TRANSACTION;
        IF pModo = 'U' THEN
			
			SET pToken = MD5(RAND());
			
			UPDATE 	Usuarios 
            SET 	Password = pPasswordNew, 
					Estado = 'A',
					Token = pToken
			WHERE 	IdUsuario = pIdUsuario;		
			
		END IF;
		SELECT 'OK' Mensaje;
    COMMIT;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS `tsp_restablecer_password`;
DELIMITER $$
CREATE PROCEDURE `tsp_restablecer_password`(pToken varchar(500), pIdUsuario int, pPassword varchar(255))
SALIR: BEGIN
	/*
	Permite setear Estado en C y setear un nuevo Password, para un usuario indicado.
	Devuelve OK o el mensaje de error en Mensaje.
	*/
	DECLARE pIdUsuarioGestion int;
    DECLARE pUsuario varchar(30);
    DECLARE pMensaje varchar(100);
	-- Manejo de error en la transacción
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		-- SHOW ERRORS;
		SELECT 'Error en la transacción. Contáctese con el administrador.' Mensaje;
        ROLLBACK;
	END;
    -- Controla Parámetros Vacios
    IF (pIdUsuario IS NULL OR pIdUsuario = 0) THEN
        SELECT 'Debe indicar un usuario.' Mensaje;
        LEAVE SALIR;
	END IF;
	-- Control de Parámetros incorrectos
	IF NOT EXISTS (SELECT IdUsuario FROM Usuarios WHERE IdUsuario = pIdUsuario) THEN
        SELECT 'El usuario indicado no existe.' Mensaje;
        LEAVE SALIR;
	END IF;
	IF NOT EXISTS (SELECT IdUsuario FROM Usuarios WHERE IdUsuario = pIdUsuario AND Estado != 'B') THEN
        SELECT 'El usuario indicado no está activo.' Mensaje;
        LEAVE SALIR;
	END IF;
	INNER JOIN TiposUsuarios tu WHERE Token = pToken AND tu.Tipo = 'Administrador') THEN
		SELECT 'Usted no posee permisos para realizar esta acción.' Mensaje;
		LEAVE SALIR; 
	END IF;

    START TRANSACTION;
		-- Modifica
        UPDATE 	Usuarios 
		SET		Estado='C',
				Password=pPassword,
				Token=SHA2(RAND(),512)
		WHERE	IdUsuario=pIdUsuario;

        SELECT 'OK' Mensaje;
	COMMIT;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS `tsp_dame_tipo_usuario`;
DELIMITER $$
CREATE PROCEDURE `tsp_dame_tipo_usuario`(pToken varchar(500))
BEGIN
	/*
    Permite obtener el tipo de usuario de un usuario a partir de su nombre de usuario.
    */
	SELECT tu.Tipo TipoUsuario
	FROM TiposUsuarios tu INNER JOIN Usuarios u USING(IdTipoUsuario)
	WHERE u.Token = pToken;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS `tsp_dame_password_hash`;
DELIMITER $$
CREATE PROCEDURE `tsp_dame_password_hash`(pUsuario varchar(120))
BEGIN
	/*
    Permite obtener el password hash de un usuario a partir de su nombre de usuario.
    */
	IF EXISTS (SELECT Usuario FROM Usuarios WHERE Usuario = pUsuario) THEN
		SELECT	Password 
        FROM	Usuarios
        WHERE	Usuario = pUsuario;
	ELSE
		SELECT NULL Password;
	END IF;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS `tsp_listar_tipos_usuario`;
DELIMITER $$
CREATE PROCEDURE `tsp_listar_tipos_usuario`()
BEGIN
	/*
    Permite listar los tipos de usuario.
    */
	SELECT tu.*
	FROM TiposUsuarios tu;
END$$
DELIMITER ;