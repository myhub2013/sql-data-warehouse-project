/*
===========================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===========================================================================
Script Purpose:
  Performes the ETL process to populate the 'silver' schema tables from the
  'bronze' tables.


Usage Example:
  EXEC silver.load_silver;
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT '---------------------------------------------';
		PRINT 'LOADING SILVER LAYER';
		PRINT '---------------------------------------------';
		PRINT '---------------------------------------------';
		PRINT 'LOADING CRM TABLES';
		PRINT '---------------------------------------------';

		TRUNCATE TABLE silver.crm_cust_info;
		PRINT '  Inserting Data Into: silver.crm_cust_info  ';

		SET @start_time = GETDATE();
		INSERT INTO silver.crm_cust_info (
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_marital_status,
			cst_gndr,
			cst_create_date
		)
		SELECT
			cst_id,
			cst_key,
			TRIM(cst_firstname) AS cst_firstname,
			TRIM(cst_lastname) AS cst_lastname,
			CASE WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Maried'
				 WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
				 ELSE 'N/A'
			END cst_marital_status,
			CASE WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
				 WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
				 ELSE 'N/A'
			END cst_gndr,
			cst_create_date
		FROM (
			SELECT 
				*,
				ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) ranking
			FROM bronze.crm_cust_info
			)t
		  WHERE ranking = 1

		SET @end_time = GETDATE();
		PRINT 'LOAD TIME: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '---------------------------------------------';
	
		IF OBJECT_ID('silver.crm_prd_info', 'U') IS NOT NULL
			DROP TABLE silver.crm_prd_info;
		CREATE TABLE silver.crm_prd_info (
			prd_id       INT,
			cat_id       NVARCHAR(50),
			prd_key      NVARCHAR(50),
			prd_nm       NVARCHAR(50),
			prd_cost     INT,
			prd_line     NVARCHAR(50),
			prd_start_dt DATE,
			prd_end_dt   DATE,
			dwh_create_date DATETIME2 DEFAULT GETDATE()
		);
	
		TRUNCATE TABLE silver.crm_prd_info;
		PRINT '  Inserting Data Into: silver.crm_prd_info  ';

		SET @start_time = GETDATE();
		INSERT INTO silver.crm_prd_info (
			prd_id,
			cat_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		)
		SELECT
			prd_id,
			REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') cat_id, -- Extracts catagory id
			SUBSTRING(prd_key, 7, LEN(prd_key)) prd_key, -- Extracts product key
			prd_nm,
			ISNULL(prd_cost, 0) prd_cost,
			CASE UPPER(TRIM(prd_line))
				WHEN 'R' THEN 'Road'
				WHEN 'S' THEN 'Other Sales'
				WHEN 'M' THEN 'Mountain'
				WHEN 'T' THEN 'Touring'
				ELSE 'N/A'
			END prd_line, -- Map codes to descriptive values
			CAST(prd_start_dt AS DATE) AS prd_start_dt,
			-- Calculate end date as one day before next start date
			CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE) AS prd_end_dt
		FROM bronze.crm_prd_info

		SET @end_time = GETDATE();
		PRINT 'LOAD TIME: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '---------------------------------------------';

		IF OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL
			DROP TABLE silver.crm_sales_details;
		CREATE TABLE silver.crm_sales_details (
			sls_ord_num  NVARCHAR(50),
			sls_prd_key  NVARCHAR(50),
			sls_cust_id  INT,
			sls_order_dt DATE,
			sls_ship_dt  DATE,
			sls_due_dt   DATE,
			sls_sales    INT,
			sls_quantity INT,
			sls_price    INT,
			dwh_create_date DATETIME2 DEFAULT GETDATE()
		);

		TRUNCATE TABLE silver.crm_sales_details;
		PRINT '  Inserting Data Into: silver.crm_sales_details  ';

		SET @start_time = GETDATE();
		INSERT INTO silver.crm_sales_details (
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
		)
		SELECT 
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
				 ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
			END sales_order_dt,
			CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
				 ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
			END sales_ship_dt,
			CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
				 ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
			END sales_due_dt,	
			CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
				THEN sls_quantity * ABS(sls_price)
				ELSE sls_sales
			END sls_sales,
			sls_quantity,
			CASE WHEN sls_price IS NULL OR sls_price <= 0
  			THEN sls_sales / NULLIF(sls_quantity, 0)
  			ELSE sls_price
			END sls_price
		FROM bronze.crm_sales_details

		SET @end_time = GETDATE();
		PRINT 'LOAD TIME: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '---------------------------------------------';

		SET @batch_end_time = GETDATE();
		PRINT '---------------------------------------------';
		PRINT 'BATCH LOAD TIME: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '---------------------------------------------';
	END TRY
	BEGIN CATCH
		PRINT '---------------------------------------------';
		PRINT 'ERROR OCCURED DURING LOAD';
		PRINT '---------------------------------------------';
  END CATCH
END
