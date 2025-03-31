
SET UNIQUE_CHECKS = 0;
SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

DELETE FROM `gestion_restauranteonline`.`detallepedidos`;
DELETE FROM `gestion_restauranteonline`.`pagos`;
DELETE FROM `gestion_restauranteonline`.`nomina`;
DELETE FROM `gestion_restauranteonline`.`pedidos`;
DELETE FROM `gestion_restauranteonline`.`productos`;
DELETE FROM `gestion_restauranteonline`.`empleados`;
DELETE FROM `gestion_restauranteonline`.`clientes`;
DELETE FROM `gestion_restauranteonline`.`sucursales`;
-- -----------------------------------------------------
-- Schema gestion_restauranteonline
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `gestion_restauranteonline` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE `gestion_restauranteonline`;

-- -----------------------------------------------------
-- Table `gestion_restauranteonline`.`clientes`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `gestion_restauranteonline`.`clientes` (
  `id_cliente` INT NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(100) NOT NULL,
  `telefono` VARCHAR(15) NULL DEFAULT NULL,
  `email` VARCHAR(100) NULL DEFAULT NULL,
  `direccion` TEXT NULL DEFAULT NULL,
  PRIMARY KEY (`id_cliente`)
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- -----------------------------------------------------
-- Table `gestion_restauranteonline`.`sucursales`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `gestion_restauranteonline`.`sucursales` (
  `id_sucursal` INT NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(100) NOT NULL,
  `direccion` TEXT NULL DEFAULT NULL,
  `telefono` VARCHAR(15) NULL DEFAULT NULL,
  PRIMARY KEY (`id_sucursal`)
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- -----------------------------------------------------
-- Table `gestion_restauranteonline`.`empleados`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `gestion_restauranteonline`.`empleados` (
  `id_empleado` INT NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(100) NOT NULL,
  `puesto` ENUM('Cajero', 'Cocinero', 'Repartidor', 'Gerente') NOT NULL,
  `salario` DECIMAL(10,2) NULL DEFAULT NULL,
  `id_sucursal` INT NULL DEFAULT NULL,
  PRIMARY KEY (`id_empleado`),
  INDEX `id_sucursal` (`id_sucursal` ASC),
  CONSTRAINT `empleados_ibfk_1`
    FOREIGN KEY (`id_sucursal`)
    REFERENCES `gestion_restauranteonline`.`sucursales` (`id_sucursal`)
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- -----------------------------------------------------
-- Table `gestion_restauranteonline`.`pedidos`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `gestion_restauranteonline`.`pedidos` (
  `id_pedido` INT NOT NULL AUTO_INCREMENT,
  `id_cliente` INT NULL DEFAULT NULL,
  `id_empleado` INT NULL DEFAULT NULL,
  `id_sucursal` INT NULL DEFAULT NULL,
  `fecha_pedido` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `estado` ENUM('En preparación', 'Listo', 'Entregado', 'Cancelado') NULL DEFAULT 'En preparación',
  `total` DECIMAL(10,2) NULL DEFAULT NULL,
  `metodo_pago` ENUM('Efectivo', 'Tarjeta', 'Transferencia') NULL DEFAULT NULL,
  PRIMARY KEY (`id_pedido`),
  INDEX `id_cliente` (`id_cliente` ASC),
  INDEX `id_empleado` (`id_empleado` ASC),
  INDEX `id_sucursal` (`id_sucursal` ASC),
  CONSTRAINT `pedidos_ibfk_1`
    FOREIGN KEY (`id_cliente`)
    REFERENCES `gestion_restauranteonline`.`clientes` (`id_cliente`),
  CONSTRAINT `pedidos_ibfk_2`
    FOREIGN KEY (`id_empleado`)
    REFERENCES `gestion_restauranteonline`.`empleados` (`id_empleado`),
  CONSTRAINT `pedidos_ibfk_3`
    FOREIGN KEY (`id_sucursal`)
    REFERENCES `gestion_restauranteonline`.`sucursales` (`id_sucursal`)
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- -----------------------------------------------------
-- Table `gestion_restauranteonline`.`productos`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `gestion_restauranteonline`.`productos` (
  `id_producto` INT NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(100) NOT NULL,
  `descripcion` TEXT NULL DEFAULT NULL,
  `precio` DECIMAL(10,2) NOT NULL,
  `tipo_producto` TEXT NOT NULL,
  `stock` INT NULL DEFAULT '0',
  PRIMARY KEY (`id_producto`)
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- -----------------------------------------------------
-- Table `gestion_restauranteonline`.`detallepedidos`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `gestion_restauranteonline`.`detallepedidos` (
  `id_detalle` INT NOT NULL AUTO_INCREMENT,
  `id_pedido` INT NULL DEFAULT NULL,
  `id_producto` INT NULL DEFAULT NULL,
  `cantidad` INT NOT NULL,
  `precio_unitario` DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (`id_detalle`),
  INDEX `id_pedido` (`id_pedido` ASC),
  INDEX `id_producto` (`id_producto` ASC),
  CONSTRAINT `detallepedidos_ibfk_1`
    FOREIGN KEY (`id_pedido`)
    REFERENCES `gestion_restauranteonline`.`pedidos` (`id_pedido`),
  CONSTRAINT `detallepedidos_ibfk_2`
    FOREIGN KEY (`id_producto`)
    REFERENCES `gestion_restauranteonline`.`productos` (`id_producto`)
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- -----------------------------------------------------
-- Table `gestion_restauranteonline`.`nomina`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `gestion_restauranteonline`.`nomina` (
  `id_empleado` INT NOT NULL,
  `mes_año` VARCHAR(7) NOT NULL,
  `horas_trabajadas` INT NOT NULL,
  `salario` int not null,
  `fecha_pago` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_empleado`, `mes_año`),
  CONSTRAINT `nomina_ibfk_1`
    FOREIGN KEY (`id_empleado`)
    REFERENCES `gestion_restauranteonline`.`empleados` (`id_empleado`)
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- -----------------------------------------------------
-- Table `gestion_restauranteonline`.`pagos`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `gestion_restauranteonline`.`pagos` (
  `id_pago` INT NOT NULL AUTO_INCREMENT,
  `id_pedido` INT NULL DEFAULT NULL,
  `monto` DECIMAL(10,2) NOT NULL,
  `metodo_pago` ENUM('Efectivo', 'Tarjeta', 'Transferencia', 'En línea') NOT NULL,
  `fecha_pago` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_pago`),
  INDEX `id_pedido` (`id_pedido` ASC),
  CONSTRAINT `pagos_ibfk_1`
    FOREIGN KEY (`id_pedido`)
    REFERENCES `gestion_restauranteonline`.`pedidos` (`id_pedido`)
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

SET UNIQUE_CHECKS = 1;
SET FOREIGN_KEY_CHECKS = 1;
