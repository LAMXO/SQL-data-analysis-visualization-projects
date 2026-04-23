-- 1. Tạo Database
--CREATE DATABASE SEA_EconomicDB;
-- GO
--USE SEA_EconomicDB;
-- GO

-- Xóa bảng cũ nếu đã tồn tại
IF OBJECT_ID('economic_indicators', 'U') IS NOT NULL DROP TABLE economic_indicators;
IF OBJECT_ID('population_data', 'U') IS NOT NULL DROP TABLE population_data;
IF OBJECT_ID('gdp_data', 'U') IS NOT NULL DROP TABLE gdp_data;
IF OBJECT_ID('countries', 'U') IS NOT NULL DROP TABLE countries;
IF OBJECT_ID('decades', 'U') IS NOT NULL DROP TABLE decades;
GO

-- ==============================================================================
-- 1. TẠO MASTER TABLES
-- ==============================================================================

-- Bảng lookup thập kỷ
CREATE TABLE decades (
    decade_start INT PRIMARY KEY,
    decade_end INT NOT NULL,
    decade_name NVARCHAR(20) NOT NULL
);

-- Bảng Master Quốc gia (Phiên bản Toàn cầu)
CREATE TABLE countries (
    country_code VARCHAR(5) PRIMARY KEY, 
    country_name NVARCHAR(255) NOT NULL, 
    region NVARCHAR(150),                
    income_group NVARCHAR(150)          
);
GO

-- ==============================================================================
-- 2. TẠO FACT TABLES (Bảng dữ liệu giao dịch)
-- ==============================================================================

-- Bảng GDP Toàn cầu
CREATE TABLE gdp_data (
    country_code VARCHAR(5) NOT NULL,
    year INT NOT NULL,
    gdp_usd DECIMAL(24, 2),           
    gdp_per_capita_usd DECIMAL(18, 2),
    PRIMARY KEY (country_code, year),
    FOREIGN KEY (country_code) REFERENCES countries(country_code) ON DELETE CASCADE
);

-- Bảng Dân số Toàn cầu
CREATE TABLE population_data (
    country_code VARCHAR(5) NOT NULL,
    year INT NOT NULL,
    population BIGINT,       
    PRIMARY KEY (country_code, year),
    FOREIGN KEY (country_code) REFERENCES countries(country_code) ON DELETE CASCADE
);

-- Bảng Chỉ số kinh tế Toàn cầu
CREATE TABLE economic_indicators (
    country_code VARCHAR(5) NOT NULL,
    year INT NOT NULL,
    inflation_rate DECIMAL(10, 4),
    unemployment_rate DECIMAL(10, 4),
    fdi_usd DECIMAL(24, 2),
    PRIMARY KEY (country_code, year),
    FOREIGN KEY (country_code) REFERENCES countries(country_code) ON DELETE CASCADE
);
GO

-- ==============================================================================
-- 3. INSERT DỮ LIỆU LOOKUP
-- ==============================================================================
INSERT INTO decades (decade_start, decade_end, decade_name)
VALUES 
    (2000, 2009, '2000s'),
    (2010, 2019, '2010s'),
    (2020, 2029, '2020s');
GO

PRINT N'Đã khởi tạo xong Schema Toàn cầu!';