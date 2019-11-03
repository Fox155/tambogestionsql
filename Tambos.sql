DROP PROCEDURE IF EXISTS `tsp_dame_tambo`;
DELIMITER $$
CREATE PROCEDURE `tsp_dame_tambo`(pIdTambo int)
PROC: BEGIN
	/*
    Permite instanciar un tambo desde la base de datos.
    */
    SELECT	t.*
    FROM 	Tambos t
    WHERE	t.IdTambo = pIdTambo;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS `tsp_resumen_producciones_tambo`;
DELIMITER $$
CREATE PROCEDURE `tsp_resumen_producciones_tambo`(pIdTambo int)
SALIR: BEGIN
	/*
	Permite listar las producciones del ultimo mes de un Tambo. 
	*/
    SELECT  JSON_ARRAYAGG(tt.Litros) 'Data', JSON_ARRAYAGG(tt.Fecha) 'Labels', JSON_ARRAYAGG(tt.Ids) 'Participantes', DATE_FORMAT(NOW(), '%d de %M %Y a las %T') 'Footer'
    FROM (
        SELECT SUM(rl.Litros) Litros, rl.Fecha Fecha, JSON_ARRAYAGG(s.IdSucursal) Ids
        FROM RegistrosLeche rl
        INNER JOIN Sucursales s USING(IdSucursal)
        WHERE   s.IdTambo = pIdTambo
            AND rl.Fecha BETWEEN DATE_SUB(NOW(), INTERVAL 30 DAY) AND NOW()
        GROUP BY rl.Fecha
        ORDER BY Fecha ASC
    ) tt;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS `tsp_resumen_ventas_tambo`;
DELIMITER $$
CREATE PROCEDURE `tsp_resumen_ventas_tambo`(pIdTambo int)
SALIR: BEGIN
	/*
	Permite listar las montos de los pagos del ultimo mes de un Tambo. 
	*/
    SELECT  JSON_ARRAYAGG(tt.Monto) 'Data', JSON_ARRAYAGG(tt.Fecha) 'Labels', JSON_ARRAYAGG(tt.Ids) 'Participantes', DATE_FORMAT(NOW(), '%d de %M %Y a las %T') 'Footer'
    FROM (
        SELECT SUM(p.Monto) Monto, DATE(p.Fecha) Fecha, s.IdSucursal Ids
        FROM Pagos p
        INNER JOIN Ventas v USING(IdVenta)
        INNER JOIN Sucursales s USING(IdSucursal)
        WHERE   s.IdTambo = pIdTambo
            AND p.Estado = 'A'
            AND p.Fecha BETWEEN DATE_SUB(NOW(), INTERVAL 30 DAY) AND NOW()
        GROUP BY DATE(p.Fecha)
        ORDER BY Fecha ASC
    ) tt;
END$$
DELIMITER ;