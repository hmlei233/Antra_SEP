-- Lillian Lei
-- 1.
DROP TABLE IF EXISTS #result1
DROP TABLE IF EXISTS #result_temp

SELECT P.PersonID, P.FullName, P.FaxNumber, P.PhoneNumber, 
	S.PhoneNumber AS CompanyPhoneNumber,
	S.FaxNumber AS CompanyFaxNumber
INTO #result1
FROM Application.People P 
inner JOIN Purchasing.Suppliers S
ON P.PersonID = S.PrimaryContactPersonID 
OR P.PersonID = S.AlternateContactPersonID

INSERT INTO #result1
SELECT P.PersonID, P.FullName, P.FaxNumber, P.PhoneNumber, 
	C.PhoneNumber AS CompanyPhoneNumber, 
	C.FaxNumber AS CompanyFaxNumber
FROM Sales.Customers C 
INNER JOIN Application.People P 
ON C.PrimaryContactPersonID = P.PersonID 
WHERE (C.CustomerName LIKE 'Tailspin%' 
		OR C.CustomerName LIKE 'Wingtip%')

SELECT P.PersonID, P.FullName, P.FaxNumber, P.PhoneNumber, R.CompanyPhoneNumber, R.CompanyFaxNumber
FROM Application.People P
LEFT JOIN #result1 R
ON P.PersonID = R.PersonID

-- 2. ----
SELECT DISTINCT C.CustomerName AS CustomerCompany
FROM Sales.Customers C 
INNER JOIN Application.People P 
ON C.PrimaryContactPersonID = P.PersonID 
WHERE C.PhoneNumber = P.PhoneNumber 
	AND (C.CustomerName LIKE 'Tailspin%' 
		OR C.CustomerName LIKE 'Wingtip%')

-- 3.
SELECT DISTINCT C.CustomerName
FROM Sales.Orders O 
INNER JOIN Sales.Customers C
ON O.CustomerID = C.CustomerID 
WHERE O.CustomerID NOT IN (SELECT O2.CustomerID
							FROM Sales.Orders O2
							WHERE O2.OrderDate >= '2016-01-01')

-- 4.
SELECT S.StockItemName, SUM(X.Quantity) AS TotalQuantity
FROM (SELECT T.StockItemID, T.Quantity
	FROM Purchasing.PurchaseOrders O 
	INNER JOIN Warehouse.StockItemTransactions T
	ON O.PurchaseOrderID = T.PurchaseOrderID
	WHERE YEAR(O.OrderDate) = 2013
) X
INNER JOIN Warehouse.StockItems S
ON X.StockItemID = S.StockItemID
GROUP BY S.StockItemName

-- 5.
SELECT S.StockItemName
FROM Warehouse.StockItems S
WHERE S.StockItemID IN (SELECT DISTINCT L.StockItemID 
						FROM sales.OrderLines L
						WHERE LEN(L.Description) >= 10)

-- 6.
SELECT DISTINCT S.StockItemName
FROM Warehouse.StockItems S
INNER JOIN Sales.OrderLines L
ON S.StockItemID = L.StockItemID
INNER JOIN (SELECT O.OrderID, O.CustomerID
			FROM Sales.Orders O
			WHERE YEAR(O.OrderDate) = 2014) O2
ON L.OrderID = O2.OrderID
INNER JOIN Sales.Customers C
ON O2.CustomerID = C.CustomerID
INNER JOIN Application.Cities CT
ON C.DeliveryCityID = CT.CityID
INNER JOIN (SELECT P.StateProvinceID, P.StateProvinceName 
			FROM Application.StateProvinces P
			WHERE P.StateProvinceName != 'Alabama' 
			AND P.StateProvinceName != 'Georgia') P2
ON CT.StateProvinceID = P2.StateProvinceID


-- 7.
SELECT P.StateProvinceName, 
	AVG(DATEDIFF(DAY, O2.OrderDate, I2.ConfirmedDeliveryTime)) AS AverageProcessingByDay
FROM Application.StateProvinces P
INNER JOIN (SELECT C.CityID, C.StateProvinceID
			FROM Application.Cities C) C2
ON P.StateProvinceID = C2.StateProvinceID
INNER JOIN (SELECT S.CustomerID, S.DeliveryCityID
			FROM Sales.Customers S) S2
ON C2.CityID = S2.DeliveryCityID
INNER JOIN (SELECT O.OrderID, O.OrderDate, O.CustomerID
			FROM Sales.Orders O) O2
ON S2.CustomerID = O2.CustomerID
INNER JOIN (SELECT I.OrderID, I.ConfirmedDeliveryTime
			FROM Sales.Invoices I) I2
ON O2.OrderID = I2.OrderID
GROUP BY P.StateProvinceName

-- 8.
SELECT P.StateProvinceName, MONTH(O2.ORDERDATE) AS Month,
	AVG(DATEDIFF(DAY, O2.OrderDate, I2.ConfirmedDeliveryTime)) AS AverageProcessingDay
FROM Application.StateProvinces P
INNER JOIN (SELECT C.CityID, C.StateProvinceID
			FROM Application.Cities C) C2
ON P.StateProvinceID = C2.StateProvinceID
INNER JOIN (SELECT S.CustomerID, S.DeliveryCityID
			FROM Sales.Customers S) S2
ON C2.CityID = S2.DeliveryCityID
INNER JOIN (SELECT O.OrderID, O.OrderDate, O.CustomerID
			FROM Sales.Orders O) O2
ON S2.CustomerID = O2.CustomerID
INNER JOIN (SELECT I.OrderID, I.ConfirmedDeliveryTime
			FROM Sales.Invoices I) I2
ON O2.OrderID = I2.OrderID
GROUP BY P.StateProvinceName, MONTH(O2.ORDERDATE)
ORDER BY P.StateProvinceName, MONTH(O2.ORDERDATE) ASC

-- 9.
SELECT I.StockItemName, ExceedingAmount
FROM Warehouse.StockItems I
INNER JOIN (SELECT T.StockItemID, SUM(T.Quantity) AS ExceedingAmount
			FROM Warehouse.StockItemTransactions T
			WHERE YEAR(T.TransactionOccurredWhen) = 2015
			GROUP BY T.StockItemID
			HAVING SUM(T.Quantity) > 0) T2
ON T2.StockItemID = I.StockItemID

-- 10.
SELECT C.CustomerName, SUM(L.Quantity)
FROM (SELECT I.StockItemID, I.StockItemName 
		FROM Warehouse.StockItems I 
		WHERE I.StockItemName LIKE '%Mug%') I2
INNER JOIN Sales.InvoiceLines L
ON I2.StockItemID = L.StockItemID
INNER JOIN Sales.Invoices V
ON L.InvoiceID = V.InvoiceID
INNER JOIN Sales.Customers C
ON V.CustomerID = C.CustomerID
GROUP BY C.CustomerName
HAVING SUM(L.Quantity) <= 10

-- 11.
SELECT C.CityName
FROM Application.Cities C
WHERE C.ValidFrom > '2015-01-01'

-- 12.
SELECT O2.OrderID,
	C.CustomerName, C.PhoneNumber, P.FullName AS CustomerContactPersonName,
	C.DeliveryAddressLine1 + C.DeliveryAddressLine2 AS DeliveryAddress,
	T.CityName AS DeliveryCity, 
	SP.StateProvinceName AS DeliveryState,
	S.StockItemName, 
	L.Quantity
FROM (SELECT * 
		FROM Sales.Orders O
		WHERE O.OrderDate = '2014-07-01') O2
LEFT JOIN Sales.Invoices I
ON O2.OrderID = I.OrderID
INNER JOIN Sales.InvoiceLines L
ON I.InvoiceID = L.InvoiceID
INNER JOIN Warehouse.StockItems S
ON L.StockItemID = S.StockItemID
INNER JOIN Sales.Customers C
ON C.CustomerID = O2.CustomerID
INNER JOIN Application.People P
ON C.PrimaryContactPersonID = P.PersonID
INNER JOIN Application.Cities T
ON C.DeliveryCityID = T.CityID
INNER JOIN Application.StateProvinces SP
ON T.StateProvinceID = SP.StateProvinceID
ORDER BY O2.OrderID

-- 13.
WITH Purchased(StockGroupName, TotalQuantityPurchased)
AS(
	SELECT G.StockGroupName, COUNT(*) AS TotalQuantityPurchased
	FROM Warehouse.StockGroups G
	INNER JOIN Warehouse.StockItemStockGroups IG
	ON G.StockGroupID = IG.StockGroupID
	INNER JOIN Warehouse.StockItemTransactions T
	ON IG.StockItemID = T.StockItemID
	WHERE T.PurchaseOrderID IS NOT NULL
	GROUP BY G.StockGroupName),
Sold(StockGroupName, TotalQuantitySold)
AS(SELECT G.StockGroupName, COUNT(*) AS TotalQuantitySold
	FROM Warehouse.StockGroups G
	INNER JOIN Warehouse.StockItemStockGroups IG
	ON G.StockGroupID = IG.StockGroupID
	INNER JOIN Warehouse.StockItemTransactions T
	ON IG.StockItemID = T.StockItemID
	WHERE T.InvoiceID IS NOT NULL
	GROUP BY G.StockGroupName)

SELECT P.StockGroupName, P.TotalQuantityPurchased, S.TotalQuantitySold, 
		(P.TotalQuantityPurchased - S.TotalQuantitySold) AS RemainingStockQuantity
FROM Purchased P
INNER JOIN Sold S
ON P.StockGroupName = S.StockGroupName

-- 14.
DROP TABLE IF EXISTS #USCities
DROP TABLE IF EXISTS #result14
DROP TABLE IF EXISTS #result14_2
DROP TABLE IF EXISTS #result14_3
DROP TABLE IF EXISTS #result14_5

-- 37940 rows
SELECT P.StateProvinceName, CT.CityID, CT.CityName
INTO #USCities
FROM Application.Countries C
INNER JOIN Application.StateProvinces P
ON C.CountryID = P.CountryID
INNER JOIN Application.Cities CT
ON P.StateProvinceID = CT.StateProvinceID
WHERE C.CountryName = 'United States'


SELECT C.DeliveryCityID, L.StockItemID, SUM(L.Quantity) TotalQuantity
INTO #result14
FROM Sales.Customers C
LEFT JOIN Sales.Orders O
ON C.CustomerID = O.CustomerID
LEFT JOIN Sales.OrderLines L
ON L.OrderID = O.OrderID
WHERE YEAR(O.OrderDate) = 2016
GROUP BY C.DeliveryCityID, L.StockItemID
ORDER BY C.DeliveryCityID, SUM(L.Quantity) DESC

SELECT *
INTO #result14_2
FROM #USCities US
LEFT JOIN #result14 R
ON US.CityID = R.DeliveryCityID


SELECT R2.CityID, R2.StateProvinceName, R2.CityName, R2.StockItemID, R2.TotalQuantity, (CASE WHEN R2.TotalQuantity IS NOT NULL
						THEN DENSE_RANK() OVER(PARTITION BY R2.CityID 
						ORDER BY R2.TotalQuantity DESC)
					END) AS Rank
INTO #result14_5
FROM #result14_2 R2

SELECT R5.CityID, R5.StateProvinceName, R5.CityName, I.StockItemName, R5.TotalQuantity
FROM #result14_5 R5
LEFT JOIN Warehouse.StockItems I
ON R5.StockItemID = I.StockItemID
WHERE Rank = 1 OR Rank IS NULL

-- 15
WITH Delivery_JSON(OrderId, ReturnedDeliveryData)
AS
(
SELECT I.OrderID, JSON_QUERY(I.ReturnedDeliveryData, '$') ReturnedDeliveryData
FROM Sales.Invoices I
)
SELECT J.OrderID, JSON_QUERY(J.ReturnedDeliveryData, '$.Events[2]') DeliveryAttempt2
FROM Delivery_JSON J
WHERE JSON_QUERY(J.ReturnedDeliveryData, '$.Events[2]') IS NOT NULL


-- 16.
SELECT DISTINCT S.StockItemName
FROM Warehouse.StockItems S
WHERE JSON_VALUE(S.CustomFields, '$.CountryOfManufacture') = 'China'

-- 17.
WITH Orders_2015(OrderID)
AS (SELECT O.OrderID
	FROM Sales.Orders O
	WHERE YEAR(O.OrderDate) = 2015)
SELECT JSON_VALUE(S.CustomFields, '$.CountryOfManufacture') AS CountryOfManufacture, 
	SUM(L.Quantity) AS TotalQuantitySold
FROM Orders_2015 O
INNER JOIN Sales.Invoices I
ON O.OrderID = I.OrderID
INNER JOIN Sales.InvoiceLines L
ON I.InvoiceID = L.InvoiceID
INNER JOIN Warehouse.StockItems S
ON L.StockItemID = S.StockItemID
GROUP BY JSON_VALUE(S.CustomFields, '$.CountryOfManufacture')

-- 18.
SELECT StockGroupName, [2013] AS '2013', [2014] AS '2014', [2015] AS '2015', 
		[2016] AS '2016', [2017] AS '2017'
FROM (SELECT G.StockGroupName, YEAR(O.OrderDate) AS Year, L.Quantity 
	FROM Sales.Orders O
	INNER JOIN Sales.Invoices I
	ON O.OrderID = I.OrderID
	INNER JOIN Sales.InvoiceLines L
	ON I.InvoiceID = L.InvoiceID
	INNER JOIN Warehouse.StockItemStockGroups IG
	ON L.StockItemID = IG.StockItemID
	RIGHT JOIN Warehouse.StockGroups G
	ON IG.StockGroupID = G.StockGroupID) R
PIVOT
(
SUM(Quantity)
FOR Year IN
([2013], [2014], [2015], [2016], [2017])
) AS PVT
ORDER BY PVT.StockGroupName

SELECT * FROM Warehouse.StockGroups

-- 19. 
SELECT Year, [Airline Novelties] AS 'Airline Novelties', [Clothing] AS'Clothing', 
		[Computing Novelties] AS 'Computing Novelties', 
		[Furry Footwear] AS 'Furry Footwear',
		[Mugs] AS 'Mugs', [Novelty Items] AS 'Novelty Items', 
		[Packaging Materials] AS 'Packaging Materials',
		[Toys] AS 'Toys', [T-Shirts] AS 'T-Shirts', 
		[USB Novelties] AS 'USB Novelties'
FROM (SELECT YEAR(O.OrderDate) AS Year, G.StockGroupName, L.Quantity 
	FROM Sales.Orders O
	INNER JOIN Sales.Invoices I
	ON O.OrderID = I.OrderID
	INNER JOIN Sales.InvoiceLines L
	ON I.InvoiceID = L.InvoiceID
	INNER JOIN Warehouse.StockItemStockGroups IG
	ON L.StockItemID = IG.StockItemID
	INNER JOIN Warehouse.StockGroups G
	ON IG.StockGroupID = G.StockGroupID) R
PIVOT
(
SUM(Quantity)
FOR StockGroupName IN
([Airline Novelties], [Clothing], [Computing Novelties], 
		[Furry Footwear], [Mugs], [Novelty Items], [Packaging Materials],
		[Toys], [T-Shirts], [USB Novelties])
) AS PVT
ORDER BY PVT.Year

-- 20
GO
CREATE FUNCTION Sales.getTotal(@OrderID int)
RETURNS int
AS
BEGIN
	DECLARE @ret int;
	SELECT @ret = SUM(L.ExtendedPrice)
	FROM Sales.Invoices I
	INNER JOIN Sales.InvoiceLines L
	ON I.InvoiceID = L.InvoiceID
	WHERE I.OrderID = @OrderID;
	RETURN @ret;
END;
GO

SELECT Sales.getTotal(1) AS Order1Total

-- 21.
USE WideWorldImporters;
GO
CREATE SCHEMA ods
GO
DROP TABLE IF EXISTS ods.Orders
GO
CREATE TABLE ods.Orders(
	OrderID int NOT NULL, 
	CustomerID int NOT NULL,
	OrderDate date NOT NULL,
	OrderTotal decimal(18,2) NOT NULL,
	PRIMARY KEY(OrderID),
	FOREIGN KEY(CustomerID) REFERENCES Sales.Customers(CustomerID))
GO

DROP PROCEDURE IF EXISTS ods.InsertOrders
GO
	CREATE PROCEDURE ods.InsertOrders @OrderDate date
	AS
	BEGIN TRY
		INSERT INTO ods.Orders
			SELECT O.OrderID, O.CustomerID, O.OrderDate, L.ExtendedPrice
			FROM Sales.Orders O
			INNER JOIN Sales.Invoices I
			ON O.OrderID = I.OrderID
			INNER JOIN Sales.InvoiceLines L
			ON I.InvoiceID = L.InvoiceLineID
			WHERE O.OrderDate = @OrderDate
		COMMIT
	END TRY
	BEGIN CATCH
		SELECT ('The given order date is already existing in the table.' ) AS ErrorMessage
	END CATCH
GO

EXECUTE ods.InsertOrders '2013-01-01'
EXECUTE ods.InsertOrders '2013-01-02'
EXECUTE ods.InsertOrders '2013-01-03'
EXECUTE ods.InsertOrders '2013-01-04'
EXECUTE ods.InsertOrders '2013-01-05'

-- 22.
SELECT StockItemID, StockItemName, SupplierID, ColorID,
	UnitPackageID, OuterPackageID, Brand, Size, LeadTimeDays,
	QuantityPerOuter, IsChillerStock, Barcode, TaxRate,
	UnitPrice, RecommendedRetailPrice, TypicalWeightPerUnit,
	MarketingComments, InternalComments,
	JSON_VALUE(CustomFields, '$.CountryOfManufacture') AS CountryOfManufacture,
	JSON_VALUE(CustomFields, '$.Range') AS Range,
	JSON_VALUE(CustomFields, '$.ShelfLife') AS ShelfLife
INTO ods.StockItem
FROM Warehouse.StockItems

-- 23. 
-- DROP PROCEDURE IF EXISTS ods.UpdateOrders
GO
	CREATE PROCEDURE ods.UpdateOrders @OrderDate date
	AS
	BEGIN TRANSACTION
		TRUNCATE TABLE ods.Orders
		INSERT INTO ods.Orders
			SELECT O.OrderID, O.CustomerID, O.OrderDate, L.ExtendedPrice
			FROM Sales.Orders O
			INNER JOIN Sales.Invoices I
			ON O.OrderID = I.OrderID
			INNER JOIN Sales.InvoiceLines L
			ON I.InvoiceID = L.InvoiceLineID
			WHERE O.OrderDate = @OrderDate
				OR O.OrderDate = DATEADD(DAY, 1, @OrderDate)
				OR O.OrderDate = DATEADD(DAY, 2, @OrderDate)
				OR O.OrderDate = DATEADD(DAY, 3, @OrderDate)
				OR O.OrderDate = DATEADD(DAY, 4, @OrderDate)
				OR O.OrderDate = DATEADD(DAY, 5, @OrderDate)
				OR O.OrderDate = DATEADD(DAY, 6, @OrderDate)
				OR O.OrderDate = DATEADD(DAY, 6, @OrderDate)
	COMMIT TRANSACTION
GO

EXECUTE ods.UpdateOrders '2013-01-05'

-- 24.
DECLARE @JSON NVARCHAR(MAX)
SET @JSON = '{
   "PurchaseOrders":[
      {
         "StockItemName":"Panzer Video Game",
         "Supplier":"7",
         "UnitPackageId":"1",
         "OuterPackageId":[
            6,
            7
         ],
         "Brand":"EA Sports",
         "LeadTimeDays":"5",
         "QuantityPerOuter":"1",
         "TaxRate":"6",
         "UnitPrice":"59.99",
         "RecommendedRetailPrice":"69.99",
         "TypicalWeightPerUnit":"0.5",
         "CountryOfManufacture":"Canada",
         "Range":"Adult",
         "OrderDate":"2018-01-01",
         "DeliveryMethod":"Post",
         "ExpectedDeliveryDate":"2018-02-02",
         "SupplierReference":"WWI2308"
      },
      {
         "StockItemName":"Panzer Video Game",
         "Supplier":"5",
         "UnitPackageId":"1",
         "OuterPackageId":"7",
         "Brand":"EA Sports",
         "LeadTimeDays":"5",
         "QuantityPerOuter":"1",
         "TaxRate":"6",
         "UnitPrice":"59.99",
         "RecommendedRetailPrice":"69.99",
         "TypicalWeightPerUnit":"0.5",
         "CountryOfManufacture":"Canada",
         "Range":"Adult",
         "OrderDate":"2018-01-025",
         "DeliveryMethod":"Post",
         "ExpectedDeliveryDate":"2018-02-02",
         "SupplierReference":"269622390"
      }
   ]
}'

SELECT * FROM OPENJSON(@JSON, '$.PurchaseOrders')

-- 25.
SELECT Year, [Airline Novelties] AS 'Airline Novelties', [Clothing] AS'Clothing', 
		[Computing Novelties] AS 'Computing Novelties', 
		[Furry Footwear] AS 'Furry Footwear',
		[Mugs] AS 'Mugs', [Novelty Items] AS 'Novelty Items', 
		[Packaging Materials] AS 'Packaging Materials',
		[Toys] AS 'Toys', [T-Shirts] AS 'T-Shirts', 
		[USB Novelties] AS 'USB Novelties'
INTO #result_25
FROM (SELECT YEAR(O.OrderDate) AS Year, G.StockGroupName, L.Quantity 
	FROM Sales.Orders O
	INNER JOIN Sales.Invoices I
	ON O.OrderID = I.OrderID
	INNER JOIN Sales.InvoiceLines L
	ON I.InvoiceID = L.InvoiceID
	INNER JOIN Warehouse.StockItemStockGroups IG
	ON L.StockItemID = IG.StockItemID
	INNER JOIN Warehouse.StockGroups G
	ON IG.StockGroupID = G.StockGroupID) R
PIVOT
(
SUM(Quantity)
FOR StockGroupName IN
([Airline Novelties], [Clothing], [Computing Novelties], 
		[Furry Footwear], [Mugs], [Novelty Items], [Packaging Materials],
		[Toys], [T-Shirts], [USB Novelties])
) AS PVT
ORDER BY PVT.Year

SELECT * FROM #result_25 FOR JSON AUTO

-- 26.
SELECT * FROM #result_25 FOR XML AUTO