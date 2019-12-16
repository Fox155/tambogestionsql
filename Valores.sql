INSERT INTO TiposUsuarios VALUES (default, 'Administrador');
INSERT INTO TiposUsuarios VALUES (default, 'Operador');

INSERT INTO Tambos VALUES (default, 'Tambo Administracion', '123456', 'A');

INSERT INTO Usuarios VALUES (default,
    (SELECT IdTambo FROM Tambos WHERE Nombre = 'Tambo Administracion'),
    (SELECT IdTipoUsuario FROM TiposUsuarios WHERE Tipo = 'Administrador'),
    'fox', 'mau.slgym@gmail.com', md5('fox'), SHA2(RAND(), 512), 0, NOW(), 'A');

INSERT INTO Usuarios VALUES (default,
    (SELECT IdTambo FROM Tambos WHERE Nombre = 'Tambo Administracion'),
    (SELECT IdTipoUsuario FROM TiposUsuarios WHERE Tipo = 'Administrador'),
    'enzo', 'esemola@gmail.com', md5('enzo'), SHA2(RAND(), 512), 0, NOW(), 'A');