CREATE OR REPLACE PACKAGE recon_pkg  AS
  PROCEDURE recon_populate_results (
  startDate IN  Timestamp,
  endDate IN Timestamp
  );
END recon_pkg;


CREATE OR REPLACE PACKAGE BODY recon_pkg AS
  PROCEDURE recon_populate_results (
      startDate IN  Timestamp,
      endDate IN Timestamp)
  AS
  log varchar2(1000);
  user_name varchar2(20);
  v_c_total numeric(10);
  v_c_success numeric(10);
  v_c_failure numeric(10);
  v_e_total numeric(10);
  v_e_success numeric(10);
  v_e_failure numeric(10);
  v_s_total numeric(10);
  v_s_success numeric(10);
  v_s_failure numeric(10);
  v_temp numeric(10);
  v_source varchar2(10);
  v_tempInterface varchar2(100);
  v_tempWricef varchar2(10);
  v_tempSrc varchar2(100);
  v_currency varchar2(4);

  BEGIN
    user_name := 'Admin';
    log := 'Begin Populate ' || startDate || ' ' || endDate;
    INSERT INTO svc_logs( APPLICATION,LOG_LEVEL, LOG_LINE, log_text, create_user, create_date) VALUES ('ServiceCatalog', 'INFO', '1.1', log, user_name, current_date);

    --out_error_code := '00';
    -- Products
        SELECT COUNT(*),
        SUM(CASE WHEN SENT_TO_TIBCO = 'Y' THEN 1 ELSE 0 END ),
        SUM(CASE WHEN SENT_TO_TIBCO != 'Y' THEN 1 ELSE 0 END ),

        SUM(CASE WHEN SAP_EIS_MATNUM is not null THEN 1 ELSE 0 END ),
        SUM(CASE WHEN STATUS_FOUND='FoundInSAP' THEN 1 ELSE 0 END ),
        SUM(CASE WHEN STATUS_FOUND='MissingInSAP' and SAP_EIS_MATNUM is not null THEN 1 ELSE 0 END ),  -- Do we have to use Error Code in Tibco

        SUM(CASE WHEN STATUS_FOUND='FoundInSAP' THEN 1 ELSE 0 END ),
        SUM(CASE WHEN STATUS_FOUND='FoundInSAP' and STATUS = 'SUCCESS' THEN 1 ELSE 0 END ),
        SUM(CASE WHEN STATUS_FOUND='FoundInSAP' and STATUS != 'SUCCESS' THEN 1 ELSE 0 END )
        INTO v_c_total, v_c_success, v_c_failure,
          v_e_total, v_e_success, v_e_failure,
          v_s_total, v_s_success, v_s_failure
        FROM (
        SELECT 'FoundInSAP' as STATUS_FOUND, CORE_PRODUCT.SAP_MATERIAL_NUMBER AS CORE_MATNUM, SAP_PRODUCT.SAP_MATERIAL_NUMBER AS SAP_EIS_MATNUM, CORE_PRODUCT.EVENT, SAP_PRODUCT.STATUS, CORE_PRODUCT.SENT_TO_TIBCO FROM (
        SELECT * FROM (SELECT  ID, SAP_MATERIAL_NUMBER, EVENT, CORE_DATE_LOAD, SENT_TO_TIBCO,
            RANK() OVER(PARTITION BY SAP_MATERIAL_NUMBER
            ORDER BY ID DESC ) AS RANK2
        FROM RECON_CORE_PRODUCT_TXN WHERE CORE_CREATE_DATE >= startDate and CORE_CREATE_DATE <= endDate) WHERE  RANK2 =1) CORE_PRODUCT
        JOIN (
        SELECT * FROM (SELECT ID, SAP_MATERIAL_NUMBER, STATUS, SAP_CREATED_DATE,
        RANK() OVER(PARTITION BY SAP_MATERIAL_NUMBER ORDER BY ID DESC ) AS RANK3 FROM RECON_SAP_PRODUCT_TXN
        WHERE SAP_CREATED_DATE >= startDate and SAP_CREATED_DATE <= endDate  ) WHERE RANK3=1) SAP_PRODUCT
        ON CORE_PRODUCT.SAP_MATERIAL_NUMBER = SAP_PRODUCT.SAP_MATERIAL_NUMBER

        UNION
        SELECT 'MissingInSAP' as STATUS_FOUND, CORE_SAP_FINAL.SAP_MATERIAL_NUMBER AS CORE_MATNUM, EIS_PRODUCT.SAP_MATERIAL_NUMBER AS SAP_EIS_MATNUM, CORE_SAP_FINAL.EVENT, EIS_PRODUCT.STATUS, CORE_SAP_FINAL.SENT_TO_TIBCO FROM (
        SELECT * FROM (
        SELECT CORE_PRODUCT.SAP_MATERIAL_NUMBER,SAP_PRODUCT.SAP_MATERIAL_NUMBER AS SAP_MAT_NUM, CORE_PRODUCT.EVENT, CORE_PRODUCT.SENT_TO_TIBCO FROM (
        SELECT * FROM (SELECT  ID, SAP_MATERIAL_NUMBER, EVENT, CORE_DATE_LOAD,  SENT_TO_TIBCO,
            RANK() OVER(PARTITION BY SAP_MATERIAL_NUMBER ORDER BY ID DESC ) AS RANK2
        FROM RECON_CORE_PRODUCT_TXN WHERE CORE_CREATE_DATE >=  startDate and CORE_CREATE_DATE <=  endDate) WHERE  RANK2 =1) CORE_PRODUCT
        LEFT OUTER JOIN (
        SELECT * FROM (SELECT ID, SAP_MATERIAL_NUMBER, RANK() OVER(PARTITION BY SAP_MATERIAL_NUMBER ORDER BY ID DESC ) AS RANK3 FROM RECON_SAP_PRODUCT_TXN
        WHERE SAP_CREATED_DATE >= startDate and SAP_CREATED_DATE <=  endDate) WHERE RANK3=1) SAP_PRODUCT
        ON CORE_PRODUCT.SAP_MATERIAL_NUMBER = SAP_PRODUCT.SAP_MATERIAL_NUMBER
        ) CORE_SAP WHERE CORE_SAP.SAP_MAT_NUM is null) CORE_SAP_FINAL
        LEFT OUTER JOIN (
        SELECT * FROM (SELECT ID, SAP_MATERIAL_NUMBER, STATUS,
        RANK() OVER(PARTITION BY SAP_MATERIAL_NUMBER ORDER BY ID DESC ) AS RANK3 FROM RECON_EIS_PRODUCT_TXN
        WHERE TIBCO_CREATE_DATE >= startDate and TIBCO_CREATE_DATE <=  endDate) WHERE RANK3=1) EIS_PRODUCT
        ON EIS_PRODUCT.SAP_MATERIAL_NUMBER = CORE_SAP_FINAL.SAP_MATERIAL_NUMBER
        ) ;

        SELECT coalesce(MAX(ID)+1, 1) INTO v_temp FROM RECON_RESULTS;

        Insert into RECON_RESULTS (ID,WRICEF,SOURCE,TARGET,START_DATE,END_DATE,SERVICE_NAME,
        INTERFACE_NAME,SOURCE_TOTAL,SOURCE_SUCCESS,SOURCE_ERRORS,EIS_TOTAL,EIS_SUCCESS,
        EIS_ERRORS,SAP_TOTAL,SAP_SUCCESS,SAP_ERRORS,CREATED_TS,FLOW_DIRECTION)
        values
        (v_temp,'I0203.1','JANIS','SAP', to_date(to_char(startDate,'YYYY-MM-DD'),'YYYY-MM-DD'), to_date(to_char(endDate,'YYYY-MM-DD'),'YYYY-MM-DD'),'PDMProductMaster01','UpdateProductMasterFromJANIS',
          v_c_total, v_c_success, v_c_failure,
          v_e_total, v_e_success, v_e_failure,
          v_s_total, v_s_success, v_s_failure, sysdate, 'I');

    -- Orders
        FOR TEMP_RESULTS IN (
         SELECT SOURCE_SYSTEM AS SOURCE_SYSTEM,
        COUNT(*) AS CORE_TOTAL, COUNT(*) AS CORE_SUCCESS, 0 AS CORE_FAILURE,
        SUM(CASE WHEN SAP_EIS_ORDER is not null THEN 1 ELSE 0 END ) TIBCO_TOTAL,
        SUM(CASE WHEN STATUS_FOUND='FoundInSAP' THEN 1 ELSE 0 END ) TIBCO_SUCCESS,
        SUM(CASE WHEN STATUS_FOUND='MissingInSAP' and SAP_EIS_ORDER is not null THEN 1 ELSE 0 END ) TIBCO_FAILURE,

        SUM(CASE WHEN STATUS_FOUND='FoundInSAP' THEN 1 ELSE 0 END ) SAP_TOTAL,
        SUM(CASE WHEN STATUS_FOUND='FoundInSAP' and STATUS = 'SUCCESS' THEN 1 ELSE 0 END ) SAP_SUCCESS,
        SUM(CASE WHEN STATUS_FOUND='FoundInSAP' and STATUS <> 'SUCCESS' THEN 1 ELSE 0 END ) SAP_FAILURE
        FROM (
 SELECT 'FoundInSAP' AS STATUS_FOUND, CORE_ORDER.SUB_ORD_REF_NUM, CORE_ORDER.SOURCE_SYSTEM, CORE_ORDER.CURRENCY_CODE, CORE_ORDER.TOTAL_PRICE,
        SAP_ORDER.SUB_ORD_REF_NUM AS SAP_EIS_ORDER, CORE_LOAD_DATE_TIME, STATUS, STATUS_MSG  FROM (
        SELECT SUB_ORD_REF_NUM, SOURCE_SYSTEM, CURRENCY_CODE, TOTAL_PRICE, CORE_LOAD_DATE_TIME, ORDER_TS FROM (
        SELECT RECON_CORE_ORDER_TXN.*, RANK() OVER (PARTITION BY SUB_ORD_REF_NUM ORDER BY ID DESC ) AS CORE_RNK FROM RECON_CORE_ORDER_TXN
        WHERE CORE_LOAD_DATE_TIME>= startDate and CORE_LOAD_DATE_TIME <= endDate) WHERE CORE_RNK =1) CORE_ORDER
        JOIN (
        SELECT SUB_ORD_REF_NUM,  SOURCE_SYSTEM, CURRENCY_CODE, TOTAL_PRICE, SAP_CREATED_DATE, STATUS, STATUS_MSG FROM (
        SELECT RECON_SAP_ORDER_TXN.*, RANK() OVER (PARTITION BY SUB_ORD_REF_NUM ORDER BY ID DESC ) AS SAP_RNK  FROM RECON_SAP_ORDER_TXN
        WHERE SAP_CREATED_DATE>= startDate and SAP_CREATED_DATE <= endDate) WHERE SAP_RNK =1
        ) SAP_ORDER
        ON SAP_ORDER.SUB_ORD_REF_NUM = CORE_ORDER.SUB_ORD_REF_NUM
        UNION
        SELECT 'MissingInSAP' AS STATUS_FOUND, CORE_SAP.SUB_ORD_REF_NUM,  CORE_SAP.SOURCE_SYSTEM, CORE_SAP.CURRENCY_CODE, CORE_SAP.TOTAL_PRICE,
        EIS_ORDER.SUB_ORD_REF_NUM, CORE_LOAD_DATE_TIME, EIS_ORDER.STATUS, EIS_ORDER.STATUS_MSG  FROM (
        SELECT  CORE_ORDER.SUB_ORD_REF_NUM, CORE_ORDER.SOURCE_SYSTEM, CORE_ORDER.CURRENCY_CODE, CORE_ORDER.TOTAL_PRICE, CORE_LOAD_DATE_TIME, STATUS_MSG  FROM (
        SELECT SUB_ORD_REF_NUM, SOURCE_SYSTEM, CURRENCY_CODE, TOTAL_PRICE, CORE_LOAD_DATE_TIME, ORDER_TS FROM (
        SELECT RECON_CORE_ORDER_TXN.*, RANK() OVER (PARTITION BY SUB_ORD_REF_NUM ORDER BY ID DESC ) AS CORE_RNK FROM RECON_CORE_ORDER_TXN
        WHERE CORE_LOAD_DATE_TIME>= startDate and CORE_LOAD_DATE_TIME <= endDate) WHERE CORE_RNK =1) CORE_ORDER
        LEFT JOIN (
        SELECT SUB_ORD_REF_NUM,  SOURCE_SYSTEM, CURRENCY_CODE, TOTAL_PRICE, SAP_CREATED_DATE, STATUS_MSG FROM (
        SELECT RECON_SAP_ORDER_TXN.*, RANK() OVER (PARTITION BY SUB_ORD_REF_NUM ORDER BY ID DESC ) AS SAP_RNK  FROM RECON_SAP_ORDER_TXN
        WHERE SAP_CREATED_DATE>= startDate and SAP_CREATED_DATE <= endDate) WHERE SAP_RNK =1
        ) SAP_ORDER
        ON SAP_ORDER.SUB_ORD_REF_NUM = CORE_ORDER.SUB_ORD_REF_NUM
        WHERE SAP_ORDER.SUB_ORD_REF_NUM IS NULL) CORE_SAP
        LEFT JOIN(
        SELECT SUB_ORD_REF_NUM,  SOURCE_SYSTEM, CURRENCY_CODE, TOTAL_PRICE, TIBCO_CREATED_DATE, STATUS, STATUS_MSG FROM(
        SELECT RECON_EIS_ORDER_TXN.*, RANK() OVER (PARTITION BY SUB_ORD_REF_NUM ORDER BY ID DESC ) AS EIS_RNK FROM RECON_EIS_ORDER_TXN
        WHERE TIBCO_CREATED_DATE>= startDate and TIBCO_CREATED_DATE <= endDate) WHERE EIS_RNK =1
        )EIS_ORDER
        ON CORE_SAP.SUB_ORD_REF_NUM = EIS_ORDER.SUB_ORD_REF_NUM) GROUP BY SOURCE_SYSTEM )
        LOOP
            v_source := TRIM(TEMP_RESULTS.SOURCE_SYSTEM);
            v_tempInterface:= '';
            v_tempSrc:= '';
            v_tempWricef:= 'null';

            IF v_source = 'PQ' THEN
                v_tempInterface:= 'UpdateSubscriptionOrderFromPriceQuote';
                v_tempSrc:= 'Price Quote';
                v_tempWricef:= 'I0230.7';
            ELSIF v_source = 'CSS' THEN
               v_tempInterface:= 'UpdateSubscriptionOrderFromCSS';
               v_tempSrc:= 'CSS';
               v_tempWricef:= 'I0230.8';
            ELSIF v_source = '0205' THEN
               v_tempInterface:= 'UpdateSubscriptionOrderFromInfoPoems';
               v_tempSrc:= 'InfoPoems/Essential Evidence Plus';
               v_tempWricef:= 'I0230.6';
            ELSIF v_source = 'PDMS' THEN
               v_tempInterface:= 'UpdateOrderFromPDMicroSites';
               v_tempSrc:= 'PD Microsites';
               v_tempWricef:= 'I0343';
            ELSIF v_source = '0301' THEN
              v_tempInterface:= 'UpdateSalesOrderFromWOLBook';
              v_tempSrc:= 'WOL Bookstore';
              v_tempWricef:= 'I0212.17';
            END IF;

            if v_tempWricef <> 'null' THEN
                SELECT coalesce(MAX(ID)+1, 1) INTO v_temp FROM RECON_RESULTS;

                Insert into RECON_RESULTS (ID,WRICEF,SOURCE,TARGET,START_DATE,END_DATE,SERVICE_NAME,
                INTERFACE_NAME,SOURCE_TOTAL,SOURCE_SUCCESS,SOURCE_ERRORS,EIS_TOTAL,EIS_SUCCESS,
                EIS_ERRORS,SAP_TOTAL,SAP_SUCCESS,SAP_ERRORS,CREATED_TS,FLOW_DIRECTION)
                values
                (v_temp,v_tempWricef,v_tempSrc,'SAP', to_date(to_char(startDate,'YYYY-MM-DD'),'YYYY-MM-DD'), to_date(to_char(endDate,'YYYY-MM-DD'),'YYYY-MM-DD'),
                'QTCOrderManagement01',v_tempInterface,
                  TEMP_RESULTS.CORE_TOTAL, TEMP_RESULTS.CORE_SUCCESS, TEMP_RESULTS.CORE_FAILURE,
                  TEMP_RESULTS.TIBCO_TOTAL, TEMP_RESULTS.TIBCO_SUCCESS, TEMP_RESULTS.TIBCO_FAILURE,
                  TEMP_RESULTS.SAP_TOTAL, TEMP_RESULTS.SAP_SUCCESS, TEMP_RESULTS.SAP_FAILURE, sysdate, 'I');
            END IF;
        END LOOP;

        FOR TEMP_RESULTS IN (
        SELECT SOURCE_SYSTEM AS SOURCE_SYSTEM,
        CURRENCY_CODE AS CURRENCY_CODE, COUNT(*) AS SRC_COUNT,
        SUM(TOTAL_PRICE) AS CORE_TOTAL, SUM(TOTAL_PRICE) AS CORE_SUCCESS, 0 AS CORE_FAILURE,
        SUM(CASE WHEN SAP_EIS_ORDER is not null THEN TOTAL_PRICE ELSE 0 END ) TIBCO_TOTAL,
        SUM(CASE WHEN STATUS_FOUND='FoundInSAP' THEN TOTAL_PRICE ELSE 0 END ) TIBCO_SUCCESS,
        SUM(CASE WHEN STATUS_FOUND='MissingInSAP' and SAP_EIS_ORDER is not null THEN TOTAL_PRICE ELSE 0 END ) TIBCO_FAILURE,

        SUM(CASE WHEN STATUS_FOUND='FoundInSAP' THEN TOTAL_PRICE ELSE 0 END ) SAP_TOTAL,
        SUM(CASE WHEN STATUS_FOUND='FoundInSAP' and STATUS = 'SUCCESS' THEN TOTAL_PRICE ELSE 0 END ) SAP_SUCCESS,
        SUM(CASE WHEN STATUS_FOUND='FoundInSAP' and STATUS <> 'SUCCESS' THEN TOTAL_PRICE ELSE 0 END ) SAP_FAILURE
        FROM (
        SELECT 'FoundInSAP' AS STATUS_FOUND, CORE_ORDER.SUB_ORD_REF_NUM, CORE_ORDER.SOURCE_SYSTEM, CORE_ORDER.CURRENCY_CODE, CORE_ORDER.TOTAL_PRICE,
        SAP_ORDER.SUB_ORD_REF_NUM AS SAP_EIS_ORDER, CORE_LOAD_DATE_TIME, STATUS, STATUS_MSG  FROM (
        SELECT SUB_ORD_REF_NUM, SOURCE_SYSTEM, CURRENCY_CODE, TOTAL_PRICE, CORE_LOAD_DATE_TIME, ORDER_TS FROM (
        SELECT RECON_CORE_ORDER_TXN.*, RANK() OVER (PARTITION BY SUB_ORD_REF_NUM ORDER BY ID DESC ) AS CORE_RNK FROM RECON_CORE_ORDER_TXN
        WHERE CORE_LOAD_DATE_TIME>= startDate and CORE_LOAD_DATE_TIME <= endDate) WHERE CORE_RNK =1) CORE_ORDER
        JOIN (
        SELECT SUB_ORD_REF_NUM,  SOURCE_SYSTEM, CURRENCY_CODE, TOTAL_PRICE, SAP_CREATED_DATE, STATUS, STATUS_MSG FROM (
        SELECT RECON_SAP_ORDER_TXN.*, RANK() OVER (PARTITION BY SUB_ORD_REF_NUM ORDER BY ID DESC ) AS SAP_RNK  FROM RECON_SAP_ORDER_TXN
        WHERE SAP_CREATED_DATE>= startDate and SAP_CREATED_DATE <= endDate) WHERE SAP_RNK =1
        ) SAP_ORDER
        ON SAP_ORDER.SUB_ORD_REF_NUM = CORE_ORDER.SUB_ORD_REF_NUM
        UNION
        SELECT 'MissingInSAP' AS STATUS_FOUND, CORE_SAP.SUB_ORD_REF_NUM,  CORE_SAP.SOURCE_SYSTEM, CORE_SAP.CURRENCY_CODE, CORE_SAP.TOTAL_PRICE,
        EIS_ORDER.SUB_ORD_REF_NUM, CORE_LOAD_DATE_TIME, EIS_ORDER.STATUS, EIS_ORDER.STATUS_MSG  FROM (
        SELECT  CORE_ORDER.SUB_ORD_REF_NUM, CORE_ORDER.SOURCE_SYSTEM, CORE_ORDER.CURRENCY_CODE, CORE_ORDER.TOTAL_PRICE, CORE_LOAD_DATE_TIME, STATUS_MSG  FROM (
        SELECT SUB_ORD_REF_NUM, SOURCE_SYSTEM, CURRENCY_CODE, TOTAL_PRICE, CORE_LOAD_DATE_TIME, ORDER_TS FROM (
        SELECT RECON_CORE_ORDER_TXN.*, RANK() OVER (PARTITION BY SUB_ORD_REF_NUM ORDER BY ID DESC ) AS CORE_RNK FROM RECON_CORE_ORDER_TXN
        WHERE CORE_LOAD_DATE_TIME>= startDate and CORE_LOAD_DATE_TIME <= endDate) WHERE CORE_RNK =1) CORE_ORDER
        LEFT JOIN (
        SELECT SUB_ORD_REF_NUM,  SOURCE_SYSTEM, CURRENCY_CODE, TOTAL_PRICE, SAP_CREATED_DATE, STATUS_MSG FROM (
        SELECT RECON_SAP_ORDER_TXN.*, RANK() OVER (PARTITION BY SUB_ORD_REF_NUM ORDER BY ID DESC ) AS SAP_RNK  FROM RECON_SAP_ORDER_TXN
        WHERE SAP_CREATED_DATE>= startDate and SAP_CREATED_DATE <= endDate) WHERE SAP_RNK =1
        ) SAP_ORDER
        ON SAP_ORDER.SUB_ORD_REF_NUM = CORE_ORDER.SUB_ORD_REF_NUM
        WHERE SAP_ORDER.SUB_ORD_REF_NUM IS NULL) CORE_SAP
        LEFT JOIN(
        SELECT SUB_ORD_REF_NUM,  SOURCE_SYSTEM, CURRENCY_CODE, TOTAL_PRICE, TIBCO_CREATED_DATE, STATUS, STATUS_MSG FROM(
        SELECT RECON_EIS_ORDER_TXN.*, RANK() OVER (PARTITION BY SUB_ORD_REF_NUM ORDER BY ID DESC ) AS EIS_RNK FROM RECON_EIS_ORDER_TXN
        WHERE TIBCO_CREATED_DATE>= startDate and TIBCO_CREATED_DATE <= endDate) WHERE EIS_RNK =1
        )EIS_ORDER
        ON CORE_SAP.SUB_ORD_REF_NUM = EIS_ORDER.SUB_ORD_REF_NUM) GROUP BY SOURCE_SYSTEM, CURRENCY_CODE )
        LOOP
            v_source := TRIM(TEMP_RESULTS.SOURCE_SYSTEM);
            v_currency := TRIM(TEMP_RESULTS.CURRENCY_CODE);
            v_tempInterface:= '';
            v_tempSrc:= '';
            v_tempWricef:= 'null';

            IF v_source = 'PQ' THEN
                v_tempInterface:= 'UpdateSubscriptionOrderFromPriceQuote';
                v_tempSrc:= 'Price Quote';
                v_tempWricef:= 'I0230.7';
            ELSIF v_source = 'CSS' THEN
               v_tempInterface:= 'UpdateSubscriptionOrderFromCSS';
               v_tempSrc:= 'CSS';
               v_tempWricef:= 'I0230.8';
            ELSIF v_source = '0205' THEN
               v_tempInterface:= 'UpdateSubscriptionOrderFromInfoPoems';
               v_tempSrc:= 'InfoPoems/Essential Evidence Plus';
               v_tempWricef:= 'I0230.6';
            ELSIF v_source = 'PDMS' THEN
               v_tempInterface:= 'UpdateOrderFromPDMicroSites';
               v_tempSrc:= 'PD Microsites';
               v_tempWricef:= 'I0343';
            ELSIF v_source = '0301' THEN
               v_tempInterface:= 'UpdateSalesOrderFromWOLBook';
               v_tempSrc:= 'WOL Bookstore';
               v_tempWricef:= 'I0212.17';
            END IF;

            if v_tempWricef <> 'null' THEN
                SELECT coalesce(MAX(ID)+1, 1) INTO v_temp FROM ORDER_RESULTS;

                Insert into ORDER_RESULTS (ID,WRICEF,SOURCE,TARGET,CURRENCY,START_DATE,END_DATE,SERVICE_NAME,
                INTERFACE_NAME, SRC_COUNT, SOURCE_TOTAL, SOURCE_SUCCESS,SOURCE_ERRORS,EIS_TOTAL,EIS_SUCCESS,
                EIS_ERRORS,SAP_TOTAL,SAP_SUCCESS,SAP_ERRORS,CREATED_TS)
                values
                (v_temp, v_tempWricef, v_tempSrc, 'SAP', v_currency, to_date(to_char(startDate,'YYYY-MM-DD'),'YYYY-MM-DD'), to_date(to_char(endDate,'YYYY-MM-DD'),'YYYY-MM-DD'),
                'QTCOrderManagement01',v_tempInterface, TEMP_RESULTS.SRC_COUNT,
                TEMP_RESULTS.CORE_TOTAL, TEMP_RESULTS.CORE_SUCCESS, TEMP_RESULTS.CORE_FAILURE,
                TEMP_RESULTS.TIBCO_TOTAL, TEMP_RESULTS.TIBCO_SUCCESS, TEMP_RESULTS.TIBCO_FAILURE,
                TEMP_RESULTS.SAP_TOTAL, TEMP_RESULTS.SAP_SUCCESS, TEMP_RESULTS.SAP_FAILURE, sysdate );
            END IF;
        END LOOP;


        INSERT INTO svc_logs( APPLICATION,LOG_LEVEL, LOG_LINE, log_text, create_user, create_date) VALUES ('ServiceCatalog', 'INFO', '1.3', 'proc completed', user_name, current_date);
  END recon_populate_results;
END recon_pkg;

--call recon_pkg.recon_populate_results(TO_TIMESTAMP ('2017/06/01 00:00:00', 'YYYY/MM/DD HH24:MI:SS'), sysdate-1);
--commit;