/*
================================================================

            Stored Procedure: Load Bronze Layer

================================================================

Usage:
  EXEC bronze.load_bronze;

===============================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT '---------------------------------------------';
		PRINT '          LOADING BRONZE LAYER';
		PRINT '---------------------------------------------';
		PRINT '---------------------------------------------';
		PRINT '           LOADING CRM TABLES';
		PRINT '---------------------------------------------';

		TRUNCATE TABLE bronze.crm_cust_info;
		SET @start_time = GETDATE();
		BULK INSERT bronze.crm_cust_info 
		FROM 'C:\Users\Me\Desktop\dw_files\cust_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT 'LOAD TIME: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '---------------------------------------------';

		TRUNCATE TABLE bronze.crm_prd_info;
		SET @start_time = GETDATE();
		BULK INSERT bronze.crm_prd_info 
		FROM 'C:\Users\Me\Desktop\dw_files\prd_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT 'LOAD TIME: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '---------------------------------------------';

		TRUNCATE TABLE bronze.crm_sales_details;
		SET @start_time = GETDATE();
		BULK INSERT bronze.crm_sales_details 
		FROM 'C:\Users\Me\Desktop\dw_files\sales_details.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT 'LOAD TIME: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '---------------------------------------------';

		PRINT '---------------------------------------------';
		PRINT '            LOADING ERP TABLES';
		PRINT '---------------------------------------------';

		TRUNCATE TABLE bronze.erp_cust_az12;
		SET @start_time = GETDATE();
		BULK INSERT bronze.erp_cust_az12 
		FROM 'C:\Users\Me\Desktop\dw_files\CUST_AZ12.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT 'LOAD TIME: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '---------------------------------------------';

		TRUNCATE TABLE bronze.erp_loc_a101;
		SET @start_time = GETDATE();
		BULK INSERT bronze.erp_loc_a101
		FROM 'C:\Users\Me\Desktop\dw_files\LOC_A101.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT 'LOAD TIME: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '---------------------------------------------';

		TRUNCATE TABLE bronze.erp_px_cat_g1v2;
		SET @start_time = GETDATE();
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'C:\Users\Me\Desktop\dw_files\PX_CAT_G1V2.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
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
		PRINT '          ERROR OCCURED DURING LOAD';
		PRINT '---------------------------------------------';
	END CATCH
END
