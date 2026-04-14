/* 
===============================================================================
PROJECT: End-to-End Logistics Data Warehouse
AUTHOR: Mateusz Wojno
TECHNOLOGIES: T-SQL, MS SQL Server, Power BI
DESCRIPTION: 
    This script contains the full DDL (Data Definition Language) for the 
    Logistics Warehouse project. It includes Star Schema architecture, 
    referential integrity (PK/FK), and advanced analytical views used 
    for the Power BI dashboard.
===============================================================================
*/

-- 1. DATABASE INITIALIZATION
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'Logistics_Analytics_DB')
BEGIN
    CREATE DATABASE Logistics_Analytics_DB;
END
GO

USE Logistics_Analytics_DB;
GO

-- 2. DIMENSION TABLES (Słowniki)

-- Product Dimension
CREATE TABLE DimProduct (
    SKU NVARCHAR(50) PRIMARY KEY,
    Product_Name NVARCHAR(255),
    Category NVARCHAR(100),
    Brand NVARCHAR(100),
    Base_Price DECIMAL(18, 2)
);

-- Carrier Dimension
CREATE TABLE DimCarrier (
    Carrier_ID INT PRIMARY KEY,
    Carrier_Name NVARCHAR(100),
    Vehicle_Type NVARCHAR(50)
);

-- Date Dimension (Standard BI Calendar)
CREATE TABLE DimDate (
    DateKey INT PRIMARY KEY,
    Date DATE,
    Year INT,
    Month INT,
    MonthName NVARCHAR(20),
    Day INT,
    Quarter INT
);

-- 3. FACT TABLES (Dane transakcyjne)

-- Fact Orders (Sales)
CREATE TABLE FactOrders (
    Order_ID INT PRIMARY KEY,
    SKU NVARCHAR(50) FOREIGN KEY REFERENCES DimProduct(SKU),
    Customer_ID INT,
    DateKey INT FOREIGN KEY REFERENCES DimDate(DateKey),
    Location_ID INT,
    Carrier_ID INT FOREIGN KEY REFERENCES DimCarrier(Carrier_ID),
    Order_Quantity INT,
    Total_Revenue DECIMAL(18, 2),
    Return_Status INT -- 1 = Returned, 0 = Finalized
);

-- Fact Shipping (Logistics)
CREATE TABLE FactShipping (
    Shipping_ID INT PRIMARY KEY,
    Order_ID INT,
    Carrier_ID INT FOREIGN KEY REFERENCES DimCarrier(Carrier_ID),
    DateKey INT FOREIGN KEY REFERENCES DimDate(DateKey),
    Lead_Time INT,
    Shipping_Costs DECIMAL(18, 2),
    Delivery_Delay INT -- Days of delay
);

-- 4. ANALYTICAL VIEWS (Warstwa logiczna pod Power BI)
GO

-- Sales Analytics View
CREATE OR ALTER VIEW v_FactOrders_Analytics AS
SELECT 
    o.*,
    CASE 
        WHEN o.Return_Status = 1 THEN 'Returned' 
        ELSE 'Finalized' 
    END AS Order_Status,
    p.Product_Name + ' (' + p.Brand + ')' AS Full_Product_Name
FROM FactOrders o
JOIN DimProduct p ON o.SKU = p.SKU;
GO

-- Logistics & Performance View
CREATE OR ALTER VIEW v_FactShipping_Analytics AS
SELECT 
    s.*,
    CASE 
        WHEN s.Delivery_Delay <= 0 THEN 'On-Time'
        WHEN s.Delivery_Delay BETWEEN 1 AND 3 THEN 'Minor Delay'
        ELSE 'Critical Delay' 
    END AS Delay_Category,
    CASE 
        WHEN o.Return_Status = 1 THEN 'Returned' 
        ELSE 'Finalized' 
    END AS Related_Order_Status
FROM FactShipping s
LEFT JOIN FactOrders o ON s.Order_ID = o.Order_ID;
GO

-- 5. DATA AUDIT QUERY (Example of analytical skill)
/*
SELECT Delay_Category, COUNT(*) as Total_Shipments
FROM v_FactShipping_Analytics
GROUP BY Delay_Category;
*/