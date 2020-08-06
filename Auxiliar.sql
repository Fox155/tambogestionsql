CREATE TABLE `t_list_row` (
`_row` int(10) unsigned NOT NULL,
PRIMARY KEY (`_row`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

DROP PROCEDURE IF EXISTS `tsp_tabla_auxiliar`;
DELIMITER $$
CREATE PROCEDURE `tsp_tabla_auxiliar`()
BEGIN
    DECLARE i int DEFAULT 0;
    WHILE i <= 65535 DO
        INSERT INTO t_list_row VALUES (i);
        SET i = i + 1;
    END WHILE;
END$$
DELIMITER ;