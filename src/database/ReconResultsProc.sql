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
  v_tempId numeric(10);
  v_source varchar2(10);
  v_tempInterface varchar2(100);
  v_tempWricef varchar2(10);
  v_tempSrc varchar2(100);

  BEGIN
    user_name := 'Admin';
    log := 'Begin Populate ' || startDate || ' ' || endDate;
    INSERT INTO svc_logs( APPLICATION,LOG_LEVEL, LOG_LINE, log_text, create_user, create_date) VALUES ('ServiceCatalog', 'INFO', '1.1', log, user_name, current_date);

    --out_error_code := '00';
        SELECT COUNT(*),
        SUM(CASE WHEN SENT_TO_TIBCO = 'Y' THEN 1 ELSE 0 END ),
        SUM(CASE WHEN SENT_TO_TIBCO != 'Y' THEN 1 ELSE 0 END ),

        SUM(CASE WHEN SAP_EIS_MATNUM is not null THEN 1 ELSE 0 END ),
        SUM(CASE WHEN STATUS='FoundInSAP' THEN 1 ELSE 0 END ),
        SUM(CASE WHEN STATUS='MissingInSAP' and SAP_EIS_MATNUM is not null THEN 1 ELSE 0 END ),  -- Do we have to use Error Code in Tibco

        SUM(CASE WHEN STATUS='FoundInSAP' THEN 1 ELSE 0 END ),
        SUM(CASE WHEN STATUS_CODE = 53 THEN 1 ELSE 0 END ),
        SUM(CASE WHEN STATUS_CODE != 53 THEN 1 ELSE 0 END )
        INTO v_c_total, v_c_success, v_c_failure,
          v_e_total, v_e_success, v_e_failure,
          v_s_total, v_s_success, v_s_failure
        FROM (
        SELECT 'FoundInSAP' as STATUS, CORE_PRODUCT.SAP_MATERIAL_NUMBER AS CORE_MATNUM, SAP_PRODUCT.SAP_MATERIAL_NUMBER AS SAP_EIS_MATNUM, CORE_PRODUCT.EVENT, SAP_PRODUCT.STATUS_CODE, CORE_PRODUCT.SENT_TO_TIBCO FROM (
        SELECT * FROM (SELECT  ID, SAP_MATERIAL_NUMBER, EVENT, CORE_DATE_LOAD, ERROR_CODE, SENT_TO_TIBCO,
            RANK() OVER(PARTITION BY SAP_MATERIAL_NUMBER ORDER BY ID DESC ) AS RANK2
        FROM RECON_CORE_PRODUCT_TXN WHERE CORE_CREATE_DATE >= startDate and CORE_CREATE_DATE <= endDate) WHERE  RANK2 =1) CORE_PRODUCT
        JOIN (
        SELECT * FROM (SELECT ID, SAP_MATERIAL_NUMBER, EVENT, STATUS_CODE, SAP_CREATE_DATE,
        RANK() OVER(PARTITION BY SAP_MATERIAL_NUMBER ORDER BY ID DESC ) AS RANK3 FROM RECON_SAP_PRODUCT_TXN
        WHERE SAP_CREATE_DATE >= startDate and SAP_CREATE_DATE <= endDate  ) WHERE RANK3=1) SAP_PRODUCT
        ON CORE_PRODUCT.SAP_MATERIAL_NUMBER = SAP_PRODUCT.SAP_MATERIAL_NUMBER
        UNION
        SELECT 'MissingInSAP' as STATUS, CORE_SAP_FINAL.SAP_MATERIAL_NUMBER AS CORE_MATNUM, EIS_PRODUCT.SAP_MATERIAL_NUMBER AS SAP_EIS_MATNUM,CORE_SAP_FINAL.EVENT, CORE_SAP_FINAL.STATUS_CODE, CORE_SAP_FINAL.SENT_TO_TIBCO FROM (
        SELECT * FROM (
        SELECT CORE_PRODUCT.SAP_MATERIAL_NUMBER,SAP_PRODUCT.SAP_MATERIAL_NUMBER AS SAP_MAT_NUM, CORE_PRODUCT.EVENT, SAP_PRODUCT.STATUS_CODE, CORE_PRODUCT.SENT_TO_TIBCO FROM (
        SELECT * FROM (SELECT  ID, SAP_MATERIAL_NUMBER, EVENT, CORE_DATE_LOAD, ERROR_CODE, SENT_TO_TIBCO,
            RANK() OVER(PARTITION BY SAP_MATERIAL_NUMBER ORDER BY ID DESC ) AS RANK2
        FROM RECON_CORE_PRODUCT_TXN WHERE CORE_CREATE_DATE >=  startDate and CORE_CREATE_DATE <=  endDate) WHERE  RANK2 =1) CORE_PRODUCT
        LEFT OUTER JOIN (
        SELECT * FROM (SELECT ID, SAP_MATERIAL_NUMBER, EVENT, STATUS_CODE,
        RANK() OVER(PARTITION BY SAP_MATERIAL_NUMBER ORDER BY ID DESC ) AS RANK3 FROM RECON_SAP_PRODUCT_TXN
        WHERE SAP_CREATE_DATE >= startDate and SAP_CREATE_DATE <=  endDate) WHERE RANK3=1) SAP_PRODUCT
        ON CORE_PRODUCT.SAP_MATERIAL_NUMBER = SAP_PRODUCT.SAP_MATERIAL_NUMBER) CORE_SAP WHERE CORE_SAP.SAP_MAT_NUM is null) CORE_SAP_FINAL
        LEFT OUTER JOIN (
        SELECT * FROM (SELECT ID, SAP_MATERIAL_NUMBER, EVENT,
        RANK() OVER(PARTITION BY SAP_MATERIAL_NUMBER ORDER BY ID DESC ) AS RANK3 FROM RECON_EIS_PRODUCT_TXN
        WHERE TIBCO_CREATE_DATE >= startDate and TIBCO_CREATE_DATE <=  endDate) WHERE RANK3=1) EIS_PRODUCT
        ON EIS_PRODUCT.SAP_MATERIAL_NUMBER = CORE_SAP_FINAL.SAP_MATERIAL_NUMBER) ;

        SELECT coalesce(MAX(ID)+1, 1) INTO v_tempId FROM RECON_RESULTS;

        Insert into RECON_RESULTS (ID,WRICEF,SOURCE,TARGET,START_DATE,END_DATE,SERVICE_NAME,
        INTERFACE_NAME,SOURCE_TOTAL,SOURCE_SUCCESS,SOURCE_ERRORS,EIS_TOTAL,EIS_SUCCESS,
        EIS_ERRORS,SAP_TOTAL,SAP_SUCCESS,SAP_ERRORS,CREATED_TS,FLOW_DIRECTION)
        values
        (v_temp,'I0203.1','JANIS','SAP', to_date(to_char(startDate,'YYYY-MM-DD'),'YYYY-MM-DD'), to_date(to_char(endDate,'YYYY-MM-DD'),'YYYY-MM-DD'),'PDMProductMaster01','UpdateProductMasterFromJANIS',
          v_c_total, v_c_success, v_c_failure,
          v_e_total, v_e_success, v_e_failure,
          v_s_total, v_s_success, v_s_failure, sysdate, 'I');

        FOR TEMP_RESULTS IN (
        SELECT SOURCE_SYSTEM AS SOURCE_SYSTEM,
        COUNT(*) AS CORE_TOTAL, COUNT(*) AS CORE_SUCCESS, 0 AS CORE_FAILURE,
        SUM(CASE WHEN SAP_EIS_ORDER is not null THEN 1 ELSE 0 END ) TIBCO_TOTAL,
        SUM(CASE WHEN STATUS='FoundInSAP' THEN 1 ELSE 0 END ) TIBCO_SUCCESS,
        SUM(CASE WHEN STATUS='MissingInSAP' and SAP_EIS_ORDER is not null THEN 1 ELSE 0 END ) TIBCO_FAILURE,

        SUM(CASE WHEN STATUS='FoundInSAP' THEN 1 ELSE 0 END ) SAP_TOTAL,
        SUM(CASE WHEN STATUS='FoundInSAP' and STATUS_CODE = 53 THEN 1 ELSE 0 END ) SAP_SUCCESS,
        SUM(CASE WHEN STATUS='FoundInSAP' and STATUS_CODE <> 53 THEN 1 ELSE 0 END ) SAP_FAILURE
        FROM (
        SELECT 'FoundInSAP' AS STATUS, SAP_ORDER.SUB_ORD_REF_NUM, SAP_ORDER.STATUS_CODE, SOURCE_SYSTEM, SAP_ORDER.LINE_ITEM_COUNT, SAP_ORDER.TOTAL_PRICE, SAP_ORDER.SUB_ORD_REF_NUM AS SAP_EIS_ORDER,
        CORE_ORDER.CORE_CREATE_DATE FROM (
        SELECT SUB_ORD_REF_NUM, COUNT(PRODUCT_SEQUENCE) AS LIST_COUNT, MAX(SOURCE_SYSTEM) AS SOURCE_SYSTEM, SUM(LIST_PRICE) AS TOTAL_PRICE, MAX(CORE_CREATE_DATE)AS CORE_CREATE_DATE FROM (
        SELECT ID, SUB_ORD_REF_NUM, SOURCE_SYSTEM, PRODUCT_SEQUENCE, LIST_PRICE, RANK() OVER (PARTITION BY SUB_ORD_REF_NUM,  PRODUCT_SEQUENCE ORDER BY ID DESC) AS CORE_RNK, CORE_CREATE_DATE FROM recon_core_order_txn
        WHERE CORE_CREATE_DATE>= startDate and CORE_CREATE_DATE <= endDate) WHERE CORE_RNK =1
        GROUP BY SUB_ORD_REF_NUM) CORE_ORDER
        JOIN (
        SELECT SUB_ORD_REF_NUM, STATUS_CODE,  TOTAL_PRICE, LINE_ITEM_COUNT,  CREATED_TS FROM (
        select SUB_ORD_REF_NUM, STATUS_CODE, TOTAL_PRICE, LINE_ITEM_COUNT,  CREATED_TS, RANK() OVER (PARTITION BY SUB_ORD_REF_NUM ORDER BY ID DESC)
        AS SAP_RNK from recon_sap_order_txn WHERE ORDER_TS>= startDate and ORDER_TS <= endDate )  WHERE SAP_RNK=1) SAP_ORDER
        ON CORE_ORDER.SUB_ORD_REF_NUM = SAP_ORDER.SUB_ORD_REF_NUM
        UNION
        SELECT 'MissingInSAP', CORE_SAP.SUB_ORD_REF_NUM, null, SOURCE_SYSTEM, CORE_SAP.LIST_COUNT, CORE_SAP.TOTAL_PRICE, EIS_ORDER.SUB_ORD_REF_NUM, EIS_ORDER.TIBCO_CREATE_DATE FROM (
        SELECT CORE_ORDER.SUB_ORD_REF_NUM, CORE_ORDER.LIST_COUNT, SOURCE_SYSTEM, CORE_ORDER.TOTAL_PRICE FROM (
        SELECT SUB_ORD_REF_NUM, COUNT(PRODUCT_SEQUENCE) AS LIST_COUNT, MAX(SOURCE_SYSTEM) AS SOURCE_SYSTEM,SUM(LIST_PRICE) AS TOTAL_PRICE FROM (
        SELECT ID, SUB_ORD_REF_NUM, PRODUCT_SEQUENCE, SOURCE_SYSTEM, LIST_PRICE, RANK() OVER (PARTITION BY SUB_ORD_REF_NUM,  PRODUCT_SEQUENCE ORDER BY ID DESC) AS CORE_RNK, CORE_CREATE_DATE FROM recon_core_order_txn
        WHERE CORE_CREATE_DATE>= startDate and CORE_CREATE_DATE <= endDate) WHERE CORE_RNK =1
        GROUP BY SUB_ORD_REF_NUM) CORE_ORDER
        LEFT JOIN (
        SELECT SUB_ORD_REF_NUM, TOTAL_PRICE, LINE_ITEM_COUNT,  CREATED_TS FROM (
        select SUB_ORD_REF_NUM, TOTAL_PRICE, LINE_ITEM_COUNT,  CREATED_TS, RANK() OVER (PARTITION BY SUB_ORD_REF_NUM ORDER BY ID DESC)
        AS SAP_RNK from recon_sap_order_txn WHERE ORDER_TS>= startDate and ORDER_TS <= endDate )  WHERE SAP_RNK=1) SAP_ORDER
        ON CORE_ORDER.SUB_ORD_REF_NUM = SAP_ORDER.SUB_ORD_REF_NUM
        WHERE SAP_ORDER.SUB_ORD_REF_NUM is null
        ) CORE_SAP
        LEFT JOIN
        (SELECT SUB_ORD_REF_NUM, LINE_ITEM_COUNT, TOTAL_PRICE, TIBCO_CREATE_DATE  FROM(
        select SUB_ORD_REF_NUM , TOTAL_PRICE, LINE_ITEM_COUNT,  CREATED_TS, TIBCO_CREATE_DATE, RANK() OVER (PARTITION BY SUB_ORD_REF_NUM ORDER BY ID DESC)
        AS TIB_RNK from recon_eis_order_txn WHERE TIBCO_CREATE_DATE>= startDate and TIBCO_CREATE_DATE <= endDate )  WHERE TIB_RNK=1) EIS_ORDER
        ON CORE_SAP.SUB_ORD_REF_NUM = EIS_ORDER.SUB_ORD_REF_NUM ) TEMP GROUP BY SOURCE_SYSTEM )
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
            ELSIF v_source = 'SOE' THEN
               v_tempInterface:= 'UpdateSubscriptionOrderFromInfoPoems';
               v_tempSrc:= 'InfoPoems/Essential Evidence Plus';
               v_tempWricef:= 'I0230.6';
            END IF;

            if v_tempWricef <> 'null' THEN
                SELECT coalesce(MAX(ID)+1, 1) INTO v_tempId FROM RECON_RESULTS;

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
        INSERT INTO svc_logs( APPLICATION,LOG_LEVEL, LOG_LINE, log_text, create_user, create_date) VALUES ('ServiceCatalog', 'INFO', '1.3', 'proc completed', user_name, current_date);
  END recon_populate_results;
END recon_pkg;

--call recon_pkg.recon_populate_results(TO_TIMESTAMP ('2017/05/19 00:00:00', 'YYYY/MM/DD HH24:MI:SS'), TO_TIMESTAMP ('2017/05/22 23:59:59', 'YYYY/MM/DD HH24:MI:SS'));
--commit;
--
--select * from svc_logs order by log_id desc

--select * from RECON_RESULTS order by id desc ;
--
--        SELECT COUNT(*), COUNT(*),  0 ,
--        COUNT(EIS_ORDER_NUM), COUNT(EIS_ORDER_NUM), 0,
--        COUNT(EIS_ORDER_NUM),
--        SUM(CASE WHEN CORE_EIS.EIS_STATUS = 'EIS_0000' THEN 1 ELSE 0 END),
--        SUM(CASE WHEN CORE_EIS.EIS_STATUS is not null and  CORE_EIS.EIS_STATUS  <> 'EIS_0000' THEN 1 ELSE 0 END)
--        INTO v_c_total, v_c_success, v_c_failure,
--             v_e_total, v_e_success, v_e_failure,
--            v_s_total, v_s_success, v_s_failure
--        FROM (
--        SELECT CORE_ORDER.SUB_ORD_REF_NUM AS CORE_ORDER_NUM, EIS_ORDER.SUB_ORD_REF_NUM  AS EIS_ORDER_NUM, CORE_ORDER.STATUS as CORE_STATUS, EIS_ORDER.STATUS  AS EIS_STATUS FROM (
--        SELECT * FROM (
--            SELECT ID, SUB_ORD_REF_NUM,PURCHASE_ORDER_DATE,ORDER_PRICE, STATUS, RANK() OVER(PARTITION BY SUB_ORD_REF_NUM ORDER BY ID DESC) AS RANK2 FROM recon_core_order_pdms
--            WHERE CORE_REQUEST_DATE >= startDate AND  CORE_REQUEST_DATE <= endDate )  WHERE RANK2=1
--        )CORE_ORDER
--        LEFT OUTER JOIN
--        (
--        SELECT * FROM (
--        SELECT ID, SUB_ORD_REF_NUM,PURCHASE_ORDER_DATE,ORDER_PRICE, STATUS, RANK() OVER(PARTITION BY SUB_ORD_REF_NUM ORDER BY ID DESC) AS RANK2 FROM recon_eis_order_pdms
--         WHERE TIBCO_CREATE_DATE >= startDate and TIBCO_CREATE_DATE <= endDate) WHERE RANK2=1
--        ) EIS_ORDER
--        ON CORE_ORDER.SUB_ORD_REF_NUM = EIS_ORDER.SUB_ORD_REF_NUM) CORE_EIS;
--
--        SELECT coalesce(MAX(ID)+1, 1) INTO v_tempId FROM RECON_RESULTS;
--        
--        Insert into RECON_RESULTS (ID,WRICEF,SOURCE,TARGET,START_DATE,END_DATE,SERVICE_NAME,
--        INTERFACE_NAME,SOURCE_TOTAL,SOURCE_SUCCESS,SOURCE_ERRORS,EIS_TOTAL,EIS_SUCCESS,
--        EIS_ERRORS,SAP_TOTAL,SAP_SUCCESS,SAP_ERRORS,CREATED_TS,FLOW_DIRECTION)
--        values 
--        (v_temp,'I0343','PDMicroSites','SAP', to_date(to_char(startDate,'YYYY-MM-DD'),'YYYY-MM-DD'), to_date(to_char(endDate,'YYYY-MM-DD'),'YYYY-MM-DD'),'QTCOrderManagement01','UpdateOrderFromPDMicroSites',
--          v_c_total, v_c_success, v_c_failure,
--          v_e_total, v_e_success, v_e_failure,
--          v_s_total, v_s_success, v_s_failure, sysdate, 'I');
--commit;