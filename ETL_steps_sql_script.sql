select @@servername
--SQLBI-1\OLAPG3
--TODO:CREATE DATABASE Jim_Zhu
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = N'KoreAssignment_Jim_Zhu')
BEGIN
	CREATE DATABASE[KoreAssignment_Jim_Zhu];
END
GO

USE [KoreAssignment_Jim_Zhu]
GO

--Check and create stg schema if it dose not exist
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'stg')
BEGIN
	EXEC('CREATE SCHEMA stg')
END

--Check and create prod schema if it does not exist
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'prod')
BEGIN
	EXEC('CREATE SCHEMA prod')
END

SELECT * FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME in ('stg','prod')  --list all schemas
/*
CATALOG_NAME	SCHEMA_NAME	SCHEMA_OWNER	DEFAULT_CHARACTER_SET_CATALOG	DEFAULT_CHARACTER_SET_SCHEMA	DEFAULT_CHARACTER_SET_NAME
KoreAssignment_Jim_Zhu	prod	dbo	NULL	NULL	iso_1
KoreAssignment_Jim_Zhu	stg	dbo	NULL	NULL	iso_1
*/

--Check and create stg.Users table if it does not exist
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'stg.Users1') AND type in (N'U'))
BEGIN
	CREATE TABLE stg.Users1 (
		StgID INT IDENTITY(11,1) PRIMARY KEY,
		UserID INT,
		FullName NVARCHAR(255),
		Age INT,
		Email NVARCHAR(255),
		RegistrationDate DATE,
		LastLoginDate DATE,
		PurchaseTotal FLOAT
	);
END
GO


--select * from stg.Users1
--DROP TABLE stg.Users1

--Check and create prod.Users table if it does not exist
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'prod.Users') AND type in (N'U'))
BEGIN
	CREATE TABLE prod.Users (
		ID INT IDENTITY(1,1) PRIMARY KEY,
		UserID INT,
		FullName NVARCHAR(255),
		Age INT,
		Email NVARCHAR(255),
		RegistrationDate DATE,
		LastLoginDate DATE,
		PurchaseTotal FLOAT,
		ProdStgID INT,
		RecordLastUpdated DATETIME DEFAULT GETDATE()
	);
END
GO
--DROP TABLE prod.Users
--select *  from prod.Users
IF (SELECT COUNT(*) FROM prod.Users) = 0
BEGIN
	INSERT INTO prod.Users (UserID, FullName, Age, Email, RegistrationDate, LastLoginDate, PurchaseTotal, ProdStgID)
	VALUES
	(101, 'John Doe', 30, 'johndoe@example.com', '2021-01-10', '2023-03-01', 150.00, NULL),
	(102, 'Jane Smith', 25, 'janesmith@example.com', '2020-05-15', '2023-02-25', 200.00, NULL),
	(103, 'Emily Johnson', 22, 'emilyjohnson@example.com', '2019-03-23', '2023-01-30', 120.50, NULL),
	(104, 'Michael Brown', 35, 'michaelbrown@example.com', '2018-07-18', '2023-02-20', 300.75, NULL),
	(105, 'Jessica Garcia', 28, 'jessicagarcia@example.com', '2022-08-05', '2023-02-18', 180.25, NULL),
	(106, 'David Miller', 40, 'davidmiller@example.com', '2017-12-12', '2023-02-15', 220.40, NULL),
	(107, 'Sarah Martinez', 33, 'sarahmartinez@example.com', '2018-11-30', '2023-02-10', 140.60, NULL),
	(108, 'James Taylor', 29, 'jamestaylor@example.com', '2019-06-22', '2023-02-05', 210.00, NULL),
	(109, 'Linda Anderson', 27, 'lindaanderson@example.com', '2021-04-16', '2023-01-25', 165.95, NULL),
	(110, 'Robert Wilson', 31, 'robertwilson@example.com', '2020-02-20', '2023-01-20', 175.00, NULL);
END
UPDATE prod.Users SET RecordLastUpdated = GETDATE()
GO

/*
SELECT fullname, COUNT(*) as cnt
FROM stg.users
GROUP BY fullname
HAVING COUNT(*) > 1;
*/

--Run SSIS package  'Extract Data flow task' to load csv flat file to stg.User1 table
--Perform stg.User1 table cleaning after data is loaded in stg.User1 table:

UPDATE stg.Users1 SET Age = ISNULL(Age, -1) WHERE Age IS NULL  --cleanse null age value to -1
UPDATE stg.Users1 SET Age = -1 WHERE Age = 0  --cleanse 0 age value to -1
UPDATE stg.Users1 SET Email = '-1' WHERE Email=''  --cleanse empty email value to '-1'
UPDATE stg.Users1 SET Email = '-1'  where CHARINDEX('@', Email) = 0  --verify email format and set value '-1' to email address without '@'
UPDATE stg.Users1 SET RegistrationDate =  ISNULL(RegistrationDate, '1900-01-01')  --cleanse null date to '1900-01-01'
UPDATE stg.Users1 SET LastLoginDate =  ISNULL(LastLoginDate, '1900-01-01')  --cleanse null date to '1900-01-01'
UPDATE stg.Users1 SET PurchaseTotal =  ISNULL(PurchaseTotal, -1)  --cleanse null PruchaseTotal value to float value -1
GO
--select * from stg.Users1
--Remove duplicate records if any by self join
DELETE t2
FROM stg.users1 t1
INNER JOIN stg.users1 t2
ON t1.FullName = t2.FullName AND t1.LastLoginDate = t2.LastLoginDate AND t1.Email = t2.Email 
	AND t1.PurchaseTotal = t2.PurchaseTotal AND t1.Age = t2.Age AND t1.RegistrationDate = t2.RegistrationDate
	AND t1.LastLoginDate = t2.LastLoginDate
	AND t1.stgid < t2.stgid
GO

--Load staging table to Production Table prod.Users
--Now run SSIS data flow--'Load User Data flow task' of project package, it is to load stg.Users1 table to prod.Users table
select * from prod.Users
