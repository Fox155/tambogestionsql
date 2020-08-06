SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

-- -----------------------------------------------------
-- Schema TamboGestion
-- -----------------------------------------------------
DROP SCHEMA IF EXISTS `TamboGestion` ;

-- -----------------------------------------------------
-- Schema TamboGestion
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `TamboGestion` DEFAULT CHARACTER SET utf8 ;
USE `TamboGestion` ;

-- -----------------------------------------------------
-- Table `TamboGestion`.`Tambos`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `TamboGestion`.`Tambos` (
  `IdTambo` INT NOT NULL AUTO_INCREMENT,
  `Nombre` VARCHAR(45) NOT NULL,
  `CUIT` INT NOT NULL,
  `Estado` CHAR(1) NOT NULL,
  PRIMARY KEY (`IdTambo`),
  UNIQUE INDEX `CUIT_unq` (`CUIT` ASC),
  UNIQUE INDEX `Nombre_unq` (`Nombre` ASC))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `TamboGestion`.`Sucursales`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `TamboGestion`.`Sucursales` (
  `IdSucursal` INT NOT NULL AUTO_INCREMENT,
  `IdTambo` INT NOT NULL,
  `Nombre` VARCHAR(45) NOT NULL,
  `Datos` JSON NOT NULL,
  `Litros` DECIMAL(12,2) UNSIGNED NOT NULL,
  PRIMARY KEY (`IdSucursal`),
  INDEX `fk_Tambos_idx` (`IdTambo` ASC),
  UNIQUE INDEX `TamboNombre_unq` (`IdTambo` ASC, `Nombre` ASC),
  CONSTRAINT `fk_Sucursales_Tambos`
    FOREIGN KEY (`IdTambo`)
    REFERENCES `TamboGestion`.`Tambos` (`IdTambo`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `TamboGestion`.`TiposUsuarios`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `TamboGestion`.`TiposUsuarios` (
  `IdTipoUsuario` TINYINT NOT NULL AUTO_INCREMENT,
  `Tipo` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`IdTipoUsuario`),
  UNIQUE INDEX `TipoTambo_unq` (`Tipo` ASC))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `TamboGestion`.`Usuarios`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `TamboGestion`.`Usuarios` (
  `IdUsuario` INT NOT NULL AUTO_INCREMENT,
  `IdTambo` INT NOT NULL,
  `IdTipoUsuario` TINYINT NOT NULL,
  `Usuario` VARCHAR(100) NOT NULL,
  `Email` VARCHAR(100) NOT NULL,
  `Password` VARCHAR(255) NOT NULL,
  `Token` VARCHAR(500) NOT NULL,
  `IntentosPass` TINYINT NOT NULL,
  `FechaAlta` DATETIME NOT NULL,
  `Estado` CHAR(1) NOT NULL,
  PRIMARY KEY (`IdUsuario`),
  UNIQUE INDEX `Email_UNIQUE` (`Email` ASC),
  UNIQUE INDEX `Usuario_UNIQUE` (`Usuario` ASC),
  INDEX `fk_Tambos_idx` (`IdTambo` ASC),
  INDEX `fk_TiposUsuarios_idx` (`IdTipoUsuario` ASC),
  CONSTRAINT `fk_Usuarios_Tambos1`
    FOREIGN KEY (`IdTambo`)
    REFERENCES `TamboGestion`.`Tambos` (`IdTambo`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Usuarios_TiposUsuarios1`
    FOREIGN KEY (`IdTipoUsuario`)
    REFERENCES `TamboGestion`.`TiposUsuarios` (`IdTipoUsuario`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `TamboGestion`.`Vacas`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `TamboGestion`.`Vacas` (
  `IdVaca` INT NOT NULL,
  `IdCaravana` BIGINT NOT NULL,
  `IdRFID` BIGINT NOT NULL,
  `Nombre` VARCHAR(45) NULL,
  `Raza` VARCHAR(45) NULL,
  `Peso` TINYINT NULL COMMENT 'Peso expresado en KG',
  `FechaNac` DATE NULL,
  `Observaciones` TEXT NULL,
  PRIMARY KEY (`IdVaca`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `TamboGestion`.`Lotes`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `TamboGestion`.`Lotes` (
  `IdLote` INT NOT NULL AUTO_INCREMENT,
  `IdSucursal` INT NOT NULL,
  `Nombre` VARCHAR(45) NOT NULL,
  `Estado` CHAR(1) NOT NULL,
  PRIMARY KEY (`IdLote`),
  INDEX `fk_Sucursales_idx` (`IdSucursal` ASC),
  UNIQUE INDEX `NombreSucursal_unq` (`Nombre` ASC, `IdSucursal` ASC),
  CONSTRAINT `fk_Lotes_Sucursales1`
    FOREIGN KEY (`IdSucursal`)
    REFERENCES `TamboGestion`.`Sucursales` (`IdSucursal`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `TamboGestion`.`EstadosVacas`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `TamboGestion`.`EstadosVacas` (
  `IdVaca` INT NOT NULL,
  `NroEstadoVaca` INT NOT NULL,
  `Estado` CHAR(10) NOT NULL,
  `FechaInicio` DATE NOT NULL,
  `FechaFin` DATE NULL,
  INDEX `fk_Vacas_idx` (`IdVaca` ASC),
  PRIMARY KEY (`IdVaca`, `NroEstadoVaca`),
  INDEX `Estado_idx` (`Estado` ASC),
  CONSTRAINT `fk_Estados_has_Vacas_Vacas1`
    FOREIGN KEY (`IdVaca`)
    REFERENCES `TamboGestion`.`Vacas` (`IdVaca`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `TamboGestion`.`Lactancias`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `TamboGestion`.`Lactancias` (
  `IdVaca` INT NOT NULL,
  `NroLactancia` TINYINT NOT NULL,
  `FechaInicio` DATE NOT NULL,
  `FechaFin` DATE NULL,
  `Observaciones` TEXT NULL,
  PRIMARY KEY (`IdVaca`, `NroLactancia`),
  INDEX `fk_Vacas_idx` (`IdVaca` ASC),
  CONSTRAINT `fk_Lactancias_Vacas1`
    FOREIGN KEY (`IdVaca`)
    REFERENCES `TamboGestion`.`Vacas` (`IdVaca`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `TamboGestion`.`SesionesOrdeño`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `TamboGestion`.`SesionesOrdeño` (
  `IdSesionOrdeño` BIGINT NOT NULL,
  `IdSucursal` INT NOT NULL,
  `Fecha` DATE NOT NULL,
  `Observaciones` TEXT NULL,
  PRIMARY KEY (`IdSesionOrdeño`),
  INDEX `fk_Sucursales_idx` (`IdSucursal` ASC),
  CONSTRAINT `fk_SesionesOrdeño_Sucursales1`
    FOREIGN KEY (`IdSucursal`)
    REFERENCES `TamboGestion`.`Sucursales` (`IdSucursal`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `TamboGestion`.`Producciones`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `TamboGestion`.`Producciones` (
  `IdProduccion` BIGINT NOT NULL,
  `IdSesionOrdeño` BIGINT NOT NULL,
  `IdVaca` INT NOT NULL,
  `NroLactancia` TINYINT NOT NULL,
  `Produccion` DECIMAL(12,2) NOT NULL,
  `FechaInicio` DATETIME NOT NULL,
  `FechaFin` DATETIME NOT NULL,
  `Medidor` JSON NOT NULL,
  PRIMARY KEY (`IdProduccion`),
  INDEX `fk_Lactancias_idx` (`IdVaca` ASC, `NroLactancia` ASC),
  INDEX `fk_SesionesOrdeño_idx` (`IdSesionOrdeño` ASC),
  CONSTRAINT `fk_Producciones_Lactancias1`
    FOREIGN KEY (`IdVaca` , `NroLactancia`)
    REFERENCES `TamboGestion`.`Lactancias` (`IdVaca` , `NroLactancia`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Producciones_SesionesOrdeño1`
    FOREIGN KEY (`IdSesionOrdeño`)
    REFERENCES `TamboGestion`.`SesionesOrdeño` (`IdSesionOrdeño`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `TamboGestion`.`VacasLote`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `TamboGestion`.`VacasLote` (
  `IdVaca` INT NOT NULL,
  `IdLote` INT NOT NULL,
  `NroVacaLote` INT NOT NULL,
  `FechaIngreso` DATE NOT NULL,
  `FechaEgreso` DATE NULL,
  PRIMARY KEY (`IdVaca`, `IdLote`, `NroVacaLote`),
  INDEX `fk_Lotes_idx` (`IdLote` ASC),
  INDEX `fk_Vacas_idx` (`IdVaca` ASC),
  CONSTRAINT `fk_Vacas`
    FOREIGN KEY (`IdVaca`)
    REFERENCES `TamboGestion`.`Vacas` (`IdVaca`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Lotes`
    FOREIGN KEY (`IdLote`)
    REFERENCES `TamboGestion`.`Lotes` (`IdLote`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `TamboGestion`.`UsuariosSucursales`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `TamboGestion`.`UsuariosSucursales` (
  `IdUsuario` INT NOT NULL,
  `IdSucursal` INT NOT NULL,
  `NroUsuarioSucursal` INT NOT NULL,
  `FechaDesde` DATE NOT NULL,
  `FechaHasta` DATE NULL,
  PRIMARY KEY (`IdUsuario`, `IdSucursal`, `NroUsuarioSucursal`),
  INDEX `fk_Sucursales_idx` (`IdSucursal` ASC),
  INDEX `fk_Usuarios_idx` (`IdUsuario` ASC),
  CONSTRAINT `fk_Usuarios_has_Sucursales_Usuarios1`
    FOREIGN KEY (`IdUsuario`)
    REFERENCES `TamboGestion`.`Usuarios` (`IdUsuario`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Usuarios_has_Sucursales_Sucursales1`
    FOREIGN KEY (`IdSucursal`)
    REFERENCES `TamboGestion`.`Sucursales` (`IdSucursal`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `TamboGestion`.`ListasPrecio`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `TamboGestion`.`ListasPrecio` (
  `IdListaPrecio` INT NOT NULL AUTO_INCREMENT,
  `IdTambo` INT NOT NULL,
  `Lista` VARCHAR(45) NOT NULL,
  `Precio` DECIMAL(12,2) NOT NULL,
  `Estado` CHAR(1) NOT NULL,
  PRIMARY KEY (`IdListaPrecio`),
  INDEX `fk_Tambos_idx` (`IdTambo` ASC),
  UNIQUE INDEX `TamboLista_unq` (`IdTambo` ASC, `Lista` ASC),
  CONSTRAINT `fk_ListasPrecio_Tambos1`
    FOREIGN KEY (`IdTambo`)
    REFERENCES `TamboGestion`.`Tambos` (`IdTambo`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `TamboGestion`.`Clientes`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `TamboGestion`.`Clientes` (
  `IdCliente` INT NOT NULL,
  `IdTambo` INT NOT NULL,
  `IdListaPrecio` INT NOT NULL,
  `Apellido` VARCHAR(45) NOT NULL,
  `Nombre` VARCHAR(45) NULL,
  `TipoDoc` CHAR(5) NOT NULL,
  `NroDoc` VARCHAR(45) NOT NULL,
  `Estado` CHAR(1) NOT NULL,
  `Datos` JSON NOT NULL,
  `Observaciones` TEXT NULL,
  PRIMARY KEY (`IdCliente`),
  INDEX `fk_Tambos_idx` (`IdTambo` ASC),
  INDEX `fk_ListasPrecio_idx` (`IdListaPrecio` ASC),
  CONSTRAINT `fk_Clientes_Tambos1`
    FOREIGN KEY (`IdTambo`)
    REFERENCES `TamboGestion`.`Tambos` (`IdTambo`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Clientes_ListasPrecio1`
    FOREIGN KEY (`IdListaPrecio`)
    REFERENCES `TamboGestion`.`ListasPrecio` (`IdListaPrecio`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `TamboGestion`.`Ventas`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `TamboGestion`.`Ventas` (
  `IdVenta` BIGINT NOT NULL,
  `IdSucursal` INT NOT NULL,
  `IdCliente` INT NOT NULL,
  `MontoPres` DECIMAL(12,2) NOT NULL,
  `MontoPagar` DECIMAL(12,2) NULL,
  `NroPagos` TINYINT NOT NULL,
  `Litros` DECIMAL(12,2) NOT NULL,
  `Fecha` DATETIME NOT NULL,
  `Estado` CHAR(1) NOT NULL,
  `Datos` JSON NULL,
  `Observaciones` TEXT NULL,
  PRIMARY KEY (`IdVenta`),
  INDEX `fk_Sucursales_idx` (`IdSucursal` ASC),
  INDEX `fk_Clientes_idx` (`IdCliente` ASC),
  CONSTRAINT `fk_Ventas_Sucursales1`
    FOREIGN KEY (`IdSucursal`)
    REFERENCES `TamboGestion`.`Sucursales` (`IdSucursal`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Ventas_Clientes1`
    FOREIGN KEY (`IdCliente`)
    REFERENCES `TamboGestion`.`Clientes` (`IdCliente`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `TamboGestion`.`RegistrosLeche`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `TamboGestion`.`RegistrosLeche` (
  `IdSucursal` INT NOT NULL,
  `IdRegistroLeche` BIGINT NOT NULL,
  `Litros` DECIMAL(12,2) NOT NULL,
  `Fecha` DATETIME NOT NULL,
  PRIMARY KEY (`IdSucursal`, `IdRegistroLeche`),
  INDEX `fk_RegistroLeche_Sucursales1_idx` (`IdSucursal` ASC),
  UNIQUE INDEX `Fecha_UNIQUE` (`Fecha` ASC, `IdSucursal` ASC),
  CONSTRAINT `fk_RegistroLeche_Sucursales1`
    FOREIGN KEY (`IdSucursal`)
    REFERENCES `TamboGestion`.`Sucursales` (`IdSucursal`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `TamboGestion`.`Pagos`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `TamboGestion`.`Pagos` (
  `IdVenta` BIGINT NOT NULL,
  `NroPago` TINYINT NOT NULL,
  `TipoComp` VARCHAR(10) NOT NULL,
  `NroComp` CHAR(30) NOT NULL,
  `Monto` DECIMAL(12,2) NOT NULL,
  `Fecha` DATETIME NOT NULL,
  PRIMARY KEY (`IdVenta`, `NroPago`),
  INDEX `fk_Ventas_idx` (`IdVenta` ASC),
  CONSTRAINT `fk_Pagos_Ventas1`
    FOREIGN KEY (`IdVenta`)
    REFERENCES `TamboGestion`.`Ventas` (`IdVenta`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `TamboGestion`.`HistoricoListasPrecio`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `TamboGestion`.`HistoricoListasPrecio` (
  `IdHistoricoListaPrecio` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `IdListaPrecio` INT NOT NULL,
  `Precio` DECIMAL(12,2) NOT NULL,
  `FechaInicio` DATE NOT NULL,
  `FechaFin` DATE NULL,
  PRIMARY KEY (`IdHistoricoListaPrecio`),
  INDEX `fk_ListasPrecio_idx` (`IdListaPrecio` ASC),
  CONSTRAINT `fk_HistoricoListasPrecio_ListasPrecio1`
    FOREIGN KEY (`IdListaPrecio`)
    REFERENCES `TamboGestion`.`ListasPrecio` (`IdListaPrecio`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
