DROP PROCEDURE IF EXISTS `tsp_login`;
DELIMITER $$
CREATE PROCEDURE `tsp_login`(pUsuario varchar(120), pEsPassValido char(1), pToken varchar(500), pApp varchar(50))
PROC: BEGIN
	/*
    Permite realizar el login de un usuario indicando la aplicación a la que desea acceder en 
    pApp= A: Administración. Recibe como parámetro la autenticidad del par Usuario - Password 
    en pEsPassValido [S | N]. Controla que el usuario no haya superado el límite de login's 
    erroneos posibles indicado en MAXINTPASS, caso contrario se cambia El estado de la cuenta a
    S: Suspendido. Un intento exitoso de inicio de sesión resetea el contador de intentos fallidos.
    Devuelve un mensaje con el resultado del login y un objeto usuario en caso de login exitoso.
    */
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
    IF NOT EXISTS (SELECT IdUsuario FROM Usuarios WHERE Usuario = pUsuario AND Estado = 'A') THEN
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
                    -- Antes
					-- INSERT INTO aud_Usuarios
					-- SELECT 0, NOW(), CONCAT(pIdUsuario,'@',pUsuario), pIP, pUserAgent, pApp, 'PASS#INVALIDO', 'A', Usuarios.* 
					-- FROM Usuarios WHERE IdUsuario = pIdUsuario;
                    
					UPDATE	Usuarios 
					SET		IntentosPass = IntentosPass + 1
					WHERE	IdUsuario = pIdUsuario;
                    
                    -- Después
					-- INSERT INTO aud_Usuarios
					-- SELECT 0, NOW(), CONCAT(pIdUsuario,'@',pUsuario), pIP, pUserAgent, pApp, 'PASS#INVALIDO', 'D', Usuarios.* 
					-- FROM Usuarios WHERE IdUsuario = pIdUsuario;
					
					SELECT 'Usuario y/o contraseña incorrectos. Ante repetidos intentos fallidos de inicio de sesión, la cuenta se suspenderá.' Mensaje;
					COMMIT;
					LEAVE PROC;
				END IF;
				
				IF (SELECT IntentosPass FROM Usuarios WHERE Usuario = pUsuario) >= 3 THEN
				
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
            
				-- Antes
				-- INSERT INTO aud_Usuarios
				-- SELECT 0, NOW(), CONCAT(pIdUsuario,'@',pUsuario), pIP, pUserAgent, pApp, 'LOGIN', 'A', Usuarios.* 
				-- FROM Usuarios WHERE IdUsuario = pIdUsuario;
                
                UPDATE	Usuarios
                SET		Token = pToken,
                        IntentosPass = 0
				WHERE	IdUsuario = pIdUsuario;
                
                -- Después
				-- INSERT INTO aud_Usuarios 
				-- SELECT 0, NOW(), CONCAT(pIdUsuario,'@',pUsuario), pIP, pUserAgent, pApp, 'LOGIN', 'D', Usuarios.* 
				-- FROM Usuarios WHERE IdUsuario = pIdUsuario;
                
                -- INSERT INTO	SesionesUsuarios
                -- SELECT		0, pIdUsuario, NOW(), NULL, pIP, pApp, pUserAgent;
                
                COMMIT;
            END;
        END CASE;     
	CASE pApp
		WHEN 'A' THEN
			SELECT 		'OK' Mensaje, u.IdUsuario, u.IdTipoUsuario, u.Usuario, u.Token, u.Email,
						u.Estado, tu.Tipo TipoUsuario
			FROM 		Usuarios u
            INNER JOIN 	TiposUsuarios tu USING(IdTipoUsuario)
			-- LEFT JOIN 	(SELECT * FROM UsuariosPuntosVenta WHERE IdUsuario = pIdUsuario AND Estado = 'A') upv USING(IdUsuario)
			WHERE		Usuario = pUsuario;
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

DROP PROCEDURE IF EXISTS `tsp_dame_usuario`;
DELIMITER $$
CREATE PROCEDURE `tsp_dame_usuario`(pIdUsuario int)
PROC: BEGIN
	/*
    Permite instanciar un usuario desde la base de datos.
    */
    SELECT	u.*, tu.IdTipoUsuario, tu.Tipo
    FROM 	Usuarios u
	INNER JOIN TiposUsuarios tu USING(IdTipoUsuario)
    WHERE	u.IdUsuario = pIdUsuario;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS `tsp_dame_permisos_usuario`;
DELIMITER $$
CREATE PROCEDURE `tsp_dame_permisos_usuario`(pToken varchar(500))
BEGIN
	/*
    Permite devolver en un resultset la lista de variables de permiso que el
	usuario tiene habilitados. Se valida con el token de sesión.
    */
    SELECT	Permiso
    FROM	Permisos p INNER JOIN TiposUsuarios tu USING(IdTipoUsuario)
    WHERE	IdTipoUsuario = (SELECT	IdTipoUsuario FROM Usuarios WHERE Token = pToken);
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