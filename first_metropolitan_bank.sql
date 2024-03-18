-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Mar 18, 2024 at 06:02 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `first metropolitan bank`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `customerPurchasesPlaces` ()   SELECT c.*
FROM Clientes c
JOIN Transacciones t ON c.ID_Cliente = t.ID_Cliente
WHERE t.Tipo_Transaccion = 'Compra'
GROUP BY c.ID_Cliente
HAVING COUNT(DISTINCT t.Localizacion) > 1$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `FindMatchingTransactions` ()   BEGIN
    SELECT t1.*, t2.*
    FROM transacciones t1
    JOIN transacciones t2 ON t1.ID_Cliente = t2.ID_Cliente
    WHERE t1.Tipo_Transaccion = 'Compra' AND t1.Credito_Debito = 'Debito'
      AND t2.Tipo_Transaccion = 'Efectivo' AND t2.Credito_Debito = 'Credito'
      AND t1.Localizacion = t2.Localizacion
      AND t1.Cantidad = t2.Cantidad;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `FindRegularTransactions` ()   BEGIN
    SELECT *
    FROM transacciones t1
    WHERE Tipo_Transaccion = 'Efectivo'
    AND EXISTS (
        SELECT *
        FROM transacciones t2
        WHERE t1.ID_Cliente = t2.ID_Cliente
        AND t1.Cantidad = t2.Cantidad
        AND DAY(t1.Fecha) = DAY(t2.Fecha)
        AND MONTH(t1.Fecha) <> MONTH(t2.Fecha) -- Different months
    )
    ORDER BY t1.ID_Cliente, t1.Cantidad, t1.Fecha;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `FindTransactionsByLocation` ()   BEGIN
    SELECT *
    FROM transacciones
    WHERE Localizacion IN ('Islas Fiji', 'Bahrein', 'Barbados');
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `GetHighFrequencyDeposits` ()   BEGIN
    SELECT DISTINCT t1.*
    FROM Transacciones t1
    JOIN Transacciones t2 ON t1.ID_Cliente = t2.ID_Cliente
    WHERE t1.Tipo_Transaccion = 'Deposito'
      AND t2.Tipo_Transaccion = 'Deposito'
      AND t1.Cantidad = t2.Cantidad
      AND t1.ID_Transaccion <> t2.ID_Transaccion
    GROUP BY t1.ID_Transaccion
    HAVING COUNT(*) >= 6;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `GetRecentTransactions` ()   BEGIN
    SELECT DISTINCT t1.*
    FROM Transacciones t1
    JOIN Transacciones t2 ON t1.ID_Cliente = t2.ID_Cliente
    WHERE t1.Fecha BETWEEN DATE_SUB(t2.Fecha, INTERVAL 2 DAY) AND DATE_ADD(t2.Fecha, INTERVAL 2 DAY)
      AND t1.ID_Transaccion <> t2.ID_Transaccion;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `HighTransactionsSum` ()   SELECT c.*
FROM Clientes c
JOIN (
    SELECT ID_Cliente, SUM(Cantidad) AS TotalTransacciones
    FROM Transacciones
    GROUP BY ID_Cliente
) t_sum ON c.ID_Cliente = t_sum.ID_Cliente
WHERE t_sum.TotalTransacciones > c.Facturacion_Anual_Cliente$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `clientes`
--

CREATE TABLE `clientes` (
  `ID_Cliente` varchar(50) DEFAULT NULL,
  `Nombre_Cliente` varchar(100) DEFAULT NULL,
  `Fecha_Inscripcion` date DEFAULT NULL,
  `Pais_Residencia` varchar(50) DEFAULT NULL,
  `Segmento_Cliente` varchar(50) DEFAULT NULL,
  `Facturacion_Anual_Cliente` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `clientes`
--

INSERT INTO `clientes` (`ID_Cliente`, `Nombre_Cliente`, `Fecha_Inscripcion`, `Pais_Residencia`, `Segmento_Cliente`, `Facturacion_Anual_Cliente`) VALUES
('C0001', 'Juan Pérez', '2020-01-01', 'España', 'Particular', NULL),
('C0002', 'Ana Sánchez', '2020-03-20', 'España', 'Particular', NULL),
('C0003', 'Pedro Gómez', '2020-06-15', 'Alemania', 'Autónomo', 20000.00),
('C0004', 'Laura López', '2020-07-10', 'España', 'Autónomo', 30000.00),
('C0005', 'García Corp', '2019-11-25', 'Francia', 'Empresa', 5000.00);

-- --------------------------------------------------------

--
-- Table structure for table `cuentas`
--

CREATE TABLE `cuentas` (
  `ID_Cuenta` varchar(50) DEFAULT NULL,
  `ID_Cliente` varchar(50) DEFAULT NULL,
  `Fecha_Apertura` date DEFAULT NULL,
  `Tipo_Cuenta` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `cuentas`
--

INSERT INTO `cuentas` (`ID_Cuenta`, `ID_Cliente`, `Fecha_Apertura`, `Tipo_Cuenta`) VALUES
('A0001', 'C0001', '2020-01-02', 'Ahorros'),
('A0002', 'C0002', '2020-03-30', 'Ahorros'),
('A0003', 'C0002', '2020-04-10', 'Corriente'),
('A0004', 'C0003', '2019-12-20', 'Corriente'),
('A0005', 'C0004', '2021-01-10', 'Corriente'),
('A0006', 'C0005', '2019-12-01', 'Corriente'),
('A0007', 'C0005', '2020-01-15', 'Ahorros');

-- --------------------------------------------------------

--
-- Table structure for table `transacciones`
--

CREATE TABLE `transacciones` (
  `ID_Transaccion` varchar(50) DEFAULT NULL,
  `ID_Cliente` varchar(50) DEFAULT NULL,
  `ID_Cuenta` varchar(50) DEFAULT NULL,
  `Tipo_Transaccion` varchar(50) DEFAULT NULL,
  `Credito_Debito` varchar(50) DEFAULT NULL,
  `Cantidad` decimal(10,2) DEFAULT NULL,
  `Divisa` varchar(50) DEFAULT NULL,
  `Localizacion` varchar(50) DEFAULT NULL,
  `Fecha` date DEFAULT NULL,
  `Escenario` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `transacciones`
--

INSERT INTO `transacciones` (`ID_Transaccion`, `ID_Cliente`, `ID_Cuenta`, `Tipo_Transaccion`, `Credito_Debito`, `Cantidad`, `Divisa`, `Localizacion`, `Fecha`, `Escenario`) VALUES
('T0001', 'C0001', 'A0001', 'Compra', 'Debito', 1000.00, 'EUR', 'Barcelona', '2022-01-25', NULL),
('T0002', 'C0001', 'A0001', 'Efectivo', 'Credito', 1000.00, 'EUR', 'Barcelona', '2022-01-22', NULL),
('T0003', 'C0001', 'A0001', 'Compra', 'Debito', 2000.00, 'EUR', 'Madrid', '2022-01-26', NULL),
('T0004', 'C0001', 'A0001', 'Efectivo', 'Credito', 2000.00, 'EUR', 'Madrid', '2022-01-25', NULL),
('T0005', 'C0001', 'A0001', 'Compra', 'Debito', 3000.00, 'EUR', 'Valencia', '2022-01-27', NULL),
('T0006', 'C0001', 'A0001', 'Efectivo', 'Credito', 3000.00, 'EUR', 'Valencia', '2022-01-24', NULL),
('T0007', 'C0001', 'A0001', 'Compra', 'Debito', 1000.00, 'EUR', 'Barcelona', '2022-01-26', NULL),
('T0008', 'C0001', 'A0001', 'Efectivo', 'Credito', 1000.00, 'EUR', 'Barcelona', '2022-01-22', NULL),
('T0009', 'C0001', 'A0001', 'Compra', 'Debito', 2000.00, 'EUR', 'Madrid', '2022-01-26', NULL),
('T0010', 'C0001', 'A0001', 'Efectivo', 'Credito', 2000.00, 'EUR', 'Madrid', '2022-01-24', NULL),
('T0011', 'C0001', 'A0001', 'Compra', 'Debito', 3000.00, 'EUR', 'Valencia', '2022-01-26', NULL),
('T0012', 'C0001', 'A0001', 'Efectivo', 'Credito', 3000.00, 'EUR', 'Valencia', '2022-01-25', NULL),
('T0013', 'C0001', 'A0001', 'Compra', 'Debito', 1000.00, 'EUR', 'Barcelona', '2022-01-27', NULL),
('T0014', 'C0001', 'A0001', 'Efectivo', 'Credito', 1000.00, 'EUR', 'Barcelona', '2022-01-26', NULL),
('T0015', 'C0001', 'A0001', 'Compra', 'Debito', 2000.00, 'EUR', 'Madrid', '2022-01-27', NULL),
('T0016', 'C0001', 'A0001', 'Efectivo', 'Credito', 2000.00, 'EUR', 'Madrid', '2022-01-25', NULL),
('T0017', 'C0001', 'A0001', 'Compra', 'Debito', 3000.00, 'EUR', 'Valencia', '2022-01-27', NULL),
('T0018', 'C0001', 'A0001', 'Efectivo', 'Credito', 3000.00, 'EUR', 'Valencia', '2022-01-25', NULL),
('T0019', 'C0004', 'A0005', 'Efectivo', 'Credito', 1500.00, 'EUR', 'Málaga', '2022-02-03', NULL),
('T0020', 'C0004', 'A0005', 'Efectivo', 'Credito', 1500.00, 'EUR', 'Málaga', '2022-02-10', NULL),
('T0021', 'C0004', 'A0005', 'Efectivo', 'Credito', 1500.00, 'EUR', 'Málaga', '2022-02-17', NULL),
('T0022', 'C0004', 'A0005', 'Efectivo', 'Credito', 1500.00, 'EUR', 'Málaga', '2022-03-03', NULL),
('T0023', 'C0004', 'A0005', 'Efectivo', 'Credito', 1500.00, 'EUR', 'Málaga', '2022-03-10', NULL),
('T0024', 'C0004', 'A0005', 'Efectivo', 'Credito', 1500.00, 'EUR', 'Málaga', '2022-03-17', NULL),
('T0025', 'C0004', 'A0005', 'Efectivo', 'Credito', 1500.00, 'EUR', 'Málaga', '2022-04-14', NULL),
('T0026', 'C0005', 'A0006', 'Factura', 'Credito', 10000.00, 'EUR', 'Paris', '2022-02-01', NULL),
('T0027', 'C0005', 'A0006', 'Factura', 'Credito', 10000.00, 'EUR', 'Lyon', '2022-02-15', NULL),
('T0028', 'C0005', 'A0006', 'Factura', 'Credito', 10000.00, 'EUR', 'Marsella', '2022-03-01', NULL),
('T0029', 'C0005', 'A0006', 'Factura', 'Credito', 10000.00, 'EUR', 'Nantes', '2022-03-15', NULL),
('T0030', 'C0005', 'A0006', 'Factura', 'Credito', 10000.00, 'EUR', 'Burdeos', '2022-04-03', NULL),
('T0031', 'C0002', 'A0002', 'Transferencia', 'Debito', 10000.00, 'EUR', 'Islas Fiji', '2022-06-15', NULL),
('T0032', 'C0002', 'A0002', 'Transferencia', 'Debito', 20000.00, 'EUR', 'Bahrein', '2022-07-01', NULL),
('T0033', 'C0002', 'A0003', 'Factura', 'Crédito', 15000.00, 'EUR', 'Barcelona', '2022-09-15', NULL),
('T0034', 'C0002', 'A0003', 'Factura', 'Crédito', 30000.00, 'EUR', 'Valencia', '2022-10-01', NULL),
('T0035', 'C0002', 'A0002', 'Transferencia', 'Debito', 15000.00, 'EUR', 'Barbados', '2023-01-15', NULL),
('T0036', 'C0003', 'A0002', 'Compra', 'Debito', 100.00, 'EUR', 'Berlin', '2022-04-20', NULL),
('T0037', 'C0003', 'A0002', 'Factura', 'Credito', 150.00, 'EUR', 'Berlin', '2022-05-10', NULL),
('T0038', 'C0004', 'A0004', 'Compra', 'Debito', 200.00, 'EUR', 'Sevilla', '2022-04-22', NULL),
('T0039', 'C0004', 'A0004', 'Factura', 'Credito', 100.00, 'EUR', 'Sevilla', '2022-05-15', NULL),
('T0040', 'C0005', 'A0004', 'Efectivo', 'Credito', 120.00, 'EUR', 'Madrid', '2022-04-28', NULL),
('T0041', 'C0004', 'A0005', 'Compra', 'Debito', 60.00, 'EUR', 'Barcelona', '2022-05-03', NULL),
('T0042', 'C0004', 'A0005', 'Compra', 'Debito', 80.00, 'EUR', 'Valencia', '2022-05-30', NULL),
('T0043', 'C0003', 'A0002', 'Factura', 'Credito', 90.00, 'EUR', 'Berlin', '2022-06-16', NULL),
('T0044', 'C0004', 'A0004', 'Compra', 'Debito', 40.00, 'EUR', 'Sevilla', '2022-06-10', NULL),
('T0045', 'C0002', 'A0002', 'Compra', 'Debito', 50.00, 'EUR', 'Madrid', '2022-06-23', NULL),
('T0046', 'C0005', 'A0004', 'Factura', 'Credito', 120.00, 'EUR', 'Madrid', '2022-07-01', NULL),
('T0047', 'C0001', 'A0001', 'Compra', 'Debito', 30.00, 'EUR', 'Barcelona', '2022-07-15', NULL),
('T0048', 'C0004', 'A0005', 'Compra', 'Debito', 60.00, 'EUR', 'Sevilla', '2022-07-20', NULL),
('T0049', 'C0003', 'A0002', 'Compra', 'Debito', 130.00, 'EUR', 'Berlin', '2022-08-06', NULL),
('T0050', 'C0002', 'A0002', 'Factura', 'Credito', 140.00, 'EUR', 'Madrid', '2022-08-11', NULL),
('T0051', 'C0001', 'A0001', 'Compra', 'Debito', 75.00, 'EUR', 'Valencia', '2022-08-19', NULL),
('T0052', 'C0004', 'A0004', 'Factura', 'Credito', 60.00, 'EUR', 'Sevilla', '2022-09-05', NULL),
('T0053', 'C0003', 'A0002', 'Compra', 'Debito', 90.00, 'EUR', 'Berlin', '2022-09-09', NULL),
('T0054', 'C0002', 'A0002', 'Factura', 'Credito', 80.00, 'EUR', 'Madrid', '2022-09-23', NULL),
('T0055', 'C0001', 'A0001', 'Factura', 'Credito', 70.00, 'EUR', 'Barcelona', '2022-10-02', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `transacciones_sospechosas`
--

CREATE TABLE `transacciones_sospechosas` (
  `ID_Transaccion` varchar(50) DEFAULT NULL,
  `ID_Cliente` varchar(50) DEFAULT NULL,
  `ID_Cuenta` varchar(50) DEFAULT NULL,
  `Tipo_Transaccion` varchar(50) DEFAULT NULL,
  `Credito_Debito` varchar(50) DEFAULT NULL,
  `Cantidad` decimal(10,2) DEFAULT NULL,
  `Divisa` varchar(50) DEFAULT NULL,
  `Localizacion` varchar(50) DEFAULT NULL,
  `Fecha` date DEFAULT NULL,
  `Escenario` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
