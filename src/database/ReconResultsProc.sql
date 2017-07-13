CREATE OR REPLACE PACKAGE recon_pkg  AS
  PROCEDURE recon_populate_results (
  startDate IN  Timestamp,
  endDate IN Timestamp
  );
END recon_pkg;


CREATE OR REPLACE PACKAGE BODY recon_pkg AS
  PROCEDURE recon_populate_results 
  (
	startDate IN  Timestamp,
    endDate IN Timestamp
	)
  AS
  log varchar2(1000);
  user_name varchar2(20);
  v_s_total numeric(10);
  v_s_success numeric(10);
  v_s_failure numeric(10);
  v_e_total numeric(10);
  v_e_success numeric(10);
  v_e_failure numeric(10);
  v_t_total numeric(10);
  v_t_success numeric(10);
  v_t_failure numeric(10);
  v_temp numeric(10);
  v_source varchar2(10);
  v_tempInterface varchar2(100);
  v_tempWricef varchar2(10);
  v_tempSrc varchar2(100);
  v_currency varchar2(4);

  BEGIN
    user_name := 'Admin';
    log := 'Begin Populate ' || startDate || ' ' || endDate;
    INSERT INTO svc_logs( APPLICATION,LOG_LEVEL, LOG_LINE, log_text, create_user, create_date) VALUES ('ReconView', 'INFO', '1.1', log, user_name, current_date);

        SELECT COUNT(*),
        SUM(CASE WHEN SRC_STATUS = 'SUCCESS' THEN 1 ELSE 0 END ),
        SUM(CASE WHEN SRC_STATUS != 'SUCCESS' THEN 1 ELSE 0 END ),
        SUM(CASE WHEN EIS_MATNUM is not null THEN 1 ELSE 0 END ),
        SUM(CASE WHEN EIS_MATNUM is not null and EIS_STATUS = 'SUCCESS' THEN 1 ELSE 0 END ),
        SUM(CASE WHEN EIS_MATNUM is not null and EIS_STATUS != 'SUCCESS' THEN 1 ELSE 0 END ),
        SUM(CASE WHEN SAP_MATNUM is not null  THEN 1 ELSE 0 END ),
        SUM(CASE WHEN SAP_MATNUM is not null  and TGT_STATUS = 'SUCCESS' THEN 1 ELSE 0 END ),
        SUM(CASE WHEN SAP_MATNUM is not null  and TGT_STATUS != 'SUCCESS' THEN 1 ELSE 0 END )
        INTO v_s_total, v_s_success, v_s_failure,
        v_e_total, v_e_success, v_e_failure,
        v_t_total, v_t_success, v_t_failure
        FROM (
        SELECT * FROM (
        SELECT * FROM (
        SELECT * FROM (SELECT SAP_MATERIAL_NUMBER AS CORE_MATNUM, EVENT, PRODUCT_TYPE, CORE_DATE_LOAD, STATUS AS SRC_STATUS,
        RANK() OVER(PARTITION BY SAP_MATERIAL_NUMBER ORDER BY CREATED_TS DESC, CORE_CREATED_DATE DESC ) AS RANK1 FROM RECON_CORE_PRODUCT_TXN
        WHERE CORE_CREATED_DATE >=  startDate and CORE_CREATED_DATE <= endDate) WHERE  RANK1 =1) CORE_PRODUCT
        LEFT OUTER JOIN (
        SELECT * FROM (SELECT SAP_MATERIAL_NUMBER AS EIS_MATNUM, STATUS AS EIS_STATUS, STATUS_MSG AS EIS_STATUS_MSG,
        RANK() OVER(PARTITION BY SAP_MATERIAL_NUMBER ORDER BY CREATED_TS DESC, TIBCO_CREATED_DATE DESC ) AS RANK2 FROM RECON_EIS_PRODUCT_TXN
        WHERE TIBCO_CREATED_DATE >= startDate and TIBCO_CREATED_DATE <= endDate) WHERE RANK2=1) EIS_PRODUCT
        ON EIS_PRODUCT.EIS_MATNUM = CORE_PRODUCT.CORE_MATNUM) CORE_EIS
        LEFT OUTER JOIN (
        SELECT * FROM (SELECT SAP_MATERIAL_NUMBER AS SAP_MATNUM, STATUS AS TGT_STATUS, STATUS_MSG AS TGT_STATUS_MSG,
        RANK() OVER(PARTITION BY SAP_MATERIAL_NUMBER ORDER BY CREATED_TS DESC, SAP_CREATED_DATE DESC ) AS RANK3 FROM RECON_SAP_PRODUCT_TXN
        WHERE SAP_CREATED_DATE >= startDate and SAP_CREATED_DATE <= endDate) WHERE RANK3=1) SAP_PRODUCT
        ON CORE_EIS.CORE_MATNUM = SAP_PRODUCT.SAP_MATNUM);


        SELECT coalesce(MAX(ID)+1, 1) INTO v_temp FROM RECON_RESULTS;

        Insert into RECON_RESULTS (ID,WRICEF,SOURCE,TARGET,START_DATE,END_DATE,SERVICE_NAME,
        INTERFACE_NAME,SOURCE_TOTAL,SOURCE_SUCCESS,SOURCE_ERRORS,EIS_TOTAL,EIS_SUCCESS,
        EIS_ERRORS,TGT_TOTAL,TGT_SUCCESS,TGT_ERRORS,CREATED_TS,FLOW_DIRECTION)
        values
        (v_temp,'I0203.1','JANIS','SAP', to_date(to_char(startDate,'YYYY-MM-DD'),'YYYY-MM-DD'), to_date(to_char(endDate,'YYYY-MM-DD'),'YYYY-MM-DD'),'PDMProductMaster01','UpdateProductMasterFromJANIS',
          v_s_total, v_s_success, v_s_failure,
          v_e_total, v_e_success, v_e_failure,
          v_t_total, v_t_success, v_t_failure, sysdate, 'I');


        FOR TEMP_RESULTS IN (
        SELECT SOURCE_SYSTEM AS SOURCE_SYSTEM, COUNT(*) AS CORE_TOTAL, 
        SUM(CASE WHEN SRC_STATUS = 'SUCCESS' THEN 1 ELSE 0 END ) AS CORE_SUCCESS,
        SUM(CASE WHEN SRC_STATUS != 'SUCCESS' THEN 1 ELSE 0 END ) AS CORE_FAILURE, 
        SUM(CASE WHEN (EIS_STATUS is not null or TGT_STATUS is not null ) THEN 1 ELSE 0 END ) AS TIBCO_TOTAL,
        SUM(CASE WHEN (EIS_STATUS = 'SUCCESS' or TGT_STATUS = 'SUCCESS') THEN 1 ELSE 0 END ) AS TIBCO_SUCCESS,
        SUM(CASE WHEN (NVL(EIS_STATUS,'-') != 'SUCCESS' AND NVL(TGT_STATUS,'-') != 'SUCCESS' AND (EIS_STATUS IS NOT NULL OR TGT_STATUS IS NOT NULL)) THEN 1 ELSE 0 END ) AS TIBCO_FAILURE,
        SUM(CASE WHEN SAP_ORDNUM is not null  THEN 1 ELSE 0 END ) AS TGT_TOTAL,
        SUM(CASE WHEN SAP_ORDNUM is not null  and TGT_STATUS = 'SUCCESS' THEN 1 ELSE 0 END ) AS TGT_SUCCESS,
        SUM(CASE WHEN SAP_ORDNUM is not null  and TGT_STATUS != 'SUCCESS' THEN 1 ELSE 0 END ) AS TGT_FAILURE
        FROM (
        SELECT * FROM (
        SELECT * FROM (
        SELECT * FROM (
        SELECT SUB_ORD_REF_NUM AS CORE_ORDNUM, SOURCE_SYSTEM, CURRENCY_CODE, TOTAL_PRICE, CORE_CREATED_DATE, ORDER_TS,
        STATUS AS SRC_STATUS,
        RANK() OVER (PARTITION BY SUB_ORD_REF_NUM ORDER BY CREATED_TS DESC, CORE_CREATED_DATE DESC ) AS RANK1 FROM RECON_CORE_ORDER_TXN
        WHERE CORE_CREATED_DATE>= startDate and CORE_CREATED_DATE <= endDate) WHERE RANK1 =1) CORE_ORDER
        LEFT OUTER JOIN (
        SELECT * FROM (SELECT SUB_ORD_REF_NUM AS EIS_ORDNUM, STATUS AS EIS_STATUS, STATUS_MSG AS EIS_STATUS_MSG,
        RANK() OVER (PARTITION BY SUB_ORD_REF_NUM ORDER BY CREATED_TS DESC, TIBCO_CREATED_DATE DESC ) AS RANK2 FROM RECON_EIS_ORDER_TXN
        WHERE TIBCO_CREATED_DATE >= startDate and TIBCO_CREATED_DATE <= endDate) WHERE RANK2=1) EIS_ORDER
        ON EIS_ORDER.EIS_ORDNUM =CORE_ORDER.CORE_ORDNUM) CORE_EIS
        LEFT OUTER JOIN (
        SELECT * FROM (SELECT SUB_ORD_REF_NUM AS SAP_ORDNUM, STATUS AS TGT_STATUS, STATUS_MSG AS TGT_STATUS_MSG,
        RANK() OVER (PARTITION BY SUB_ORD_REF_NUM ORDER BY CREATED_TS DESC, SAP_CREATED_DATE DESC ) AS RANK3 FROM RECON_SAP_ORDER_TXN
        WHERE SAP_CREATED_DATE >= startDate and SAP_CREATED_DATE <= endDate) WHERE RANK3=1) SAP_ORDER
        ON CORE_EIS.CORE_ORDNUM =SAP_ORDER.SAP_ORDNUM) GROUP BY SOURCE_SYSTEM)
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
                EIS_ERRORS,TGT_TOTAL,TGT_SUCCESS,TGT_ERRORS,CREATED_TS,FLOW_DIRECTION)
                values
                (v_temp,v_tempWricef,v_tempSrc,'SAP', to_date(to_char(startDate,'YYYY-MM-DD'),'YYYY-MM-DD'), to_date(to_char(endDate,'YYYY-MM-DD'),'YYYY-MM-DD'),
                'QTCOrderManagement01',v_tempInterface,
                  TEMP_RESULTS.CORE_TOTAL, TEMP_RESULTS.CORE_SUCCESS, TEMP_RESULTS.CORE_FAILURE,
                  TEMP_RESULTS.TIBCO_TOTAL, TEMP_RESULTS.TIBCO_SUCCESS, TEMP_RESULTS.TIBCO_FAILURE,
                  TEMP_RESULTS.TGT_TOTAL, TEMP_RESULTS.TGT_SUCCESS, TEMP_RESULTS.TGT_FAILURE, sysdate, 'I');
            END IF;
        END LOOP;



        FOR TEMP_RESULTS IN (
        SELECT SOURCE_SYSTEM AS SOURCE_SYSTEM, CURRENCY_CODE AS CURRENCY_CODE, COUNT(*) AS SRC_COUNT,
        SUM(TOTAL_PRICE) AS CORE_TOTAL,
        SUM(CASE WHEN SRC_STATUS = 'SUCCESS' THEN TOTAL_PRICE ELSE 0 END ) AS CORE_SUCCESS,
        SUM(CASE WHEN SRC_STATUS != 'SUCCESS' THEN TOTAL_PRICE ELSE 0 END ) AS CORE_FAILURE, 
        SUM(CASE WHEN (EIS_STATUS is not null or TGT_STATUS is not null ) THEN TOTAL_PRICE ELSE 0 END ) AS TIBCO_TOTAL,
        SUM(CASE WHEN (EIS_STATUS = 'SUCCESS' or TGT_STATUS = 'SUCCESS') THEN TOTAL_PRICE ELSE 0 END ) AS TIBCO_SUCCESS,
        SUM(CASE WHEN (NVL(EIS_STATUS,'-') != 'SUCCESS' AND NVL(TGT_STATUS,'-') != 'SUCCESS' AND (EIS_STATUS IS NOT NULL OR TGT_STATUS IS NOT NULL)) THEN TOTAL_PRICE ELSE 0 END ) AS TIBCO_FAILURE,
        SUM(CASE WHEN SAP_ORDNUM is not null  THEN TOTAL_PRICE ELSE 0 END ) AS TGT_TOTAL,
        SUM(CASE WHEN SAP_ORDNUM is not null  and TGT_STATUS = 'SUCCESS' THEN TOTAL_PRICE ELSE 0 END ) AS TGT_SUCCESS,
        SUM(CASE WHEN SAP_ORDNUM is not null  and TGT_STATUS != 'SUCCESS' THEN TOTAL_PRICE ELSE 0 END ) AS TGT_FAILURE
        FROM (
        SELECT * FROM (
        SELECT * FROM (
        SELECT * FROM (
        SELECT SUB_ORD_REF_NUM AS CORE_ORDNUM, SOURCE_SYSTEM, CURRENCY_CODE, TOTAL_PRICE, CORE_CREATED_DATE, ORDER_TS,
        STATUS AS SRC_STATUS,
        RANK() OVER (PARTITION BY SUB_ORD_REF_NUM ORDER BY CREATED_TS DESC, CORE_CREATED_DATE DESC ) AS RANK1 FROM RECON_CORE_ORDER_TXN
        WHERE CORE_CREATED_DATE>= startDate and CORE_CREATED_DATE <= endDate) WHERE RANK1 =1) CORE_ORDER
        LEFT OUTER JOIN (
        SELECT * FROM (SELECT SUB_ORD_REF_NUM AS EIS_ORDNUM, STATUS AS EIS_STATUS, STATUS_MSG AS EIS_STATUS_MSG,
        RANK() OVER (PARTITION BY SUB_ORD_REF_NUM ORDER BY CREATED_TS DESC, TIBCO_CREATED_DATE DESC ) AS RANK2 FROM RECON_EIS_ORDER_TXN
        WHERE TIBCO_CREATED_DATE >= startDate and TIBCO_CREATED_DATE <= endDate) WHERE RANK2=1) EIS_ORDER
        ON EIS_ORDER.EIS_ORDNUM =CORE_ORDER.CORE_ORDNUM) CORE_EIS
        LEFT OUTER JOIN (
        SELECT * FROM (SELECT SUB_ORD_REF_NUM AS SAP_ORDNUM, STATUS AS TGT_STATUS, STATUS_MSG AS TGT_STATUS_MSG,
        RANK() OVER (PARTITION BY SUB_ORD_REF_NUM ORDER BY CREATED_TS DESC, SAP_CREATED_DATE DESC ) AS RANK3 FROM RECON_SAP_ORDER_TXN
        WHERE SAP_CREATED_DATE >= startDate and SAP_CREATED_DATE <= endDate) WHERE RANK3=1) SAP_ORDER
        ON CORE_EIS.CORE_ORDNUM =SAP_ORDER.SAP_ORDNUM) GROUP BY SOURCE_SYSTEM, CURRENCY_CODE)
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
                EIS_ERRORS,TGT_TOTAL,TGT_SUCCESS,TGT_ERRORS,CREATED_TS)
                values
                (v_temp, v_tempWricef, v_tempSrc, 'SAP', v_currency, to_date(to_char(startDate,'YYYY-MM-DD'),'YYYY-MM-DD'), to_date(to_char(endDate,'YYYY-MM-DD'),'YYYY-MM-DD'),
                'QTCOrderManagement01',v_tempInterface, TEMP_RESULTS.SRC_COUNT,
                TEMP_RESULTS.CORE_TOTAL, TEMP_RESULTS.CORE_SUCCESS, TEMP_RESULTS.CORE_FAILURE,
                TEMP_RESULTS.TIBCO_TOTAL, TEMP_RESULTS.TIBCO_SUCCESS, TEMP_RESULTS.TIBCO_FAILURE,
                TEMP_RESULTS.TGT_TOTAL, TEMP_RESULTS.TGT_SUCCESS, TEMP_RESULTS.TGT_FAILURE, sysdate );
            END IF;
        END LOOP;

--I0229 FULFILMENT PROCEDURE

        SELECT COUNT(*),
        SUM(CASE WHEN SAP_STATUS = 'SUCCESS' THEN 1 ELSE 0 END ),
        SUM(CASE WHEN SAP_STATUS != 'SUCCESS' THEN 1 ELSE 0 END ),
		SUM(CASE WHEN (EIS_STATUS is not null or ALM_ORDNUM is not null ) THEN 1 ELSE 0 END ),
        SUM(CASE WHEN (EIS_STATUS = 'SUCCESS' or ALM_STATUS = 'SUCCESS') THEN 1 ELSE 0 END ),
        SUM(CASE WHEN (NVL(EIS_STATUS,'-') != 'SUCCESS' AND NVL(ALM_STATUS,'-') != 'SUCCESS' AND (EIS_STATUS IS NOT NULL OR ALM_STATUS IS NOT NULL)) THEN 1 ELSE 0 END ),
		SUM(CASE WHEN ALM_ORDNUM is not null  THEN 1 ELSE 0 END ),
        SUM(CASE WHEN ALM_ORDNUM is not null  and ALM_STATUS = 'SUCCESS' THEN 1 ELSE 0 END ),
        SUM(CASE WHEN ALM_ORDNUM is not null  and ALM_STATUS != 'SUCCESS' THEN 1 ELSE 0 END )
        INTO v_s_total, v_s_success, v_s_failure,
        v_e_total, v_e_success, v_e_failure,
        v_t_total, v_t_success, v_t_failure
        FROM 
                        (
                                    SELECT * FROM 
                                    (
                                                SELECT * FROM 
                                                (
                                                            SELECT * FROM (SELECT SAP_ORDER_NUMBER AS SRC_ORDNUM, IDOC_NUMBER, SAP_CREATED_DATE, STATUS AS SAP_STATUS,
                                                            RANK() OVER(PARTITION BY SAP_ORDER_NUMBER ORDER BY CREATED_TS DESC, SAP_CREATED_DATE DESC ) AS RANK1 FROM RECON_SAP_FULFLMNT_TXN
                                                            WHERE SAP_CREATED_DATE >=  startDate and SAP_CREATED_DATE <= endDate) WHERE  RANK1 =1
                                                ) SAP_FULFLMNT
                                                LEFT OUTER JOIN 
                                                (
                                                            SELECT * FROM (SELECT SAP_ORDER_NUM AS EIS_ORDNUM, LINE_ITEM_COUNT, IDOC_NUMBER, MESSAGE_FUNCTION, SUB_ORD_REF_NUM, STATUS AS EIS_STATUS, 
                                                            STATUS_MSG AS EIS_STATUS_MSG,
                                                            RANK() OVER(PARTITION BY SAP_ORDER_NUM ORDER BY CREATED_TS DESC, TIBCO_CREATED_DATE DESC ) AS RANK2 FROM RECON_EIS_FULFLMNT_TXN
                                                            WHERE TIBCO_CREATED_DATE >= startDate and TIBCO_CREATED_DATE <= endDate) WHERE RANK2=1
                                                ) EIS_FULFLMNT
                                                ON EIS_FULFLMNT.EIS_ORDNUM = SAP_FULFLMNT.SRC_ORDNUM
                                    ) SAP_EIS
                                    LEFT OUTER JOIN 
                                    (
                                                SELECT * FROM (SELECT FULFILLMENT_ID AS ALM_ORDNUM, LINE_ITEM_COUNT, STATUS AS ALM_STATUS, STATUS_MSG AS SAP_STATUS_MSG,
                                                RANK() OVER(PARTITION BY FULFILLMENT_ID ORDER BY CREATED_TS DESC, ALM_CREATED_DATE DESC ) AS RANK3 FROM RECON_ALM_FULFLMNT_TXN
                                                WHERE ALM_CREATED_DATE >= startDate and ALM_CREATED_DATE <= endDate) WHERE RANK3=1
                                    ) ALM_FULFLMNT
                                    ON SAP_EIS.SRC_ORDNUM = ALM_FULFLMNT.ALM_ORDNUM
                        );
		SELECT coalesce(MAX(ID)+1, 1) INTO v_temp FROM RECON_RESULTS;

        Insert into RECON_RESULTS (ID,WRICEF,SOURCE,TARGET,START_DATE,END_DATE,SERVICE_NAME,
        INTERFACE_NAME,SOURCE_TOTAL,SOURCE_SUCCESS,SOURCE_ERRORS,EIS_TOTAL,EIS_SUCCESS,
        EIS_ERRORS,TGT_TOTAL,TGT_SUCCESS,TGT_ERRORS,CREATED_TS,FLOW_DIRECTION)
        values
        (v_temp,'I0229.1','SAP','ALM', to_date(to_char(startDate,'YYYY-MM-DD'),'YYYY-MM-DD'), to_date(to_char(endDate,'YYYY-MM-DD'),'YYYY-MM-DD'),'QTCOrderManagement02','UpdateOutboundOrderAckToALM',
          v_s_total, v_s_success, v_s_failure,
          v_e_total, v_e_success, v_e_failure,
          v_t_total, v_t_success, v_t_failure, sysdate, 'O');

        INSERT INTO svc_logs( APPLICATION,LOG_LEVEL, LOG_LINE, log_text, create_user, create_date) VALUES ('ReconView', 'INFO', '1.3', 'proc completed', user_name, current_date);
  END recon_populate_results;
END recon_pkg;