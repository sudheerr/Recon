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

        SELECT COUNT(*),
        SUM(CASE WHEN SENT_TO_TIBCO = 'Y' THEN 1 ELSE 0 END ),
        SUM(CASE WHEN SENT_TO_TIBCO != 'Y' THEN 1 ELSE 0 END ),
        SUM(CASE WHEN EIS_MATNUM is not null THEN 1 ELSE 0 END ),
        SUM(CASE WHEN EIS_MATNUM is not null and EIS_STATUS = 'SUCCESS' THEN 1 ELSE 0 END ),
        SUM(CASE WHEN EIS_MATNUM is not null and EIS_STATUS != 'SUCCESS' THEN 1 ELSE 0 END ),
        SUM(CASE WHEN SAP_MATNUM is not null  THEN 1 ELSE 0 END ),
        SUM(CASE WHEN SAP_MATNUM is not null  and SAP_STATUS = 'SUCCESS' THEN 1 ELSE 0 END ),
        SUM(CASE WHEN SAP_MATNUM is not null  and SAP_STATUS != 'SUCCESS' THEN 1 ELSE 0 END )
        INTO v_c_total, v_c_success, v_c_failure,
        v_e_total, v_e_success, v_e_failure,
        v_s_total, v_s_success, v_s_failure
        FROM (
        SELECT * FROM (
        SELECT * FROM (
        SELECT * FROM (SELECT SAP_MATERIAL_NUMBER AS CORE_MATNUM, EVENT, PRODUCT_TYPE, CORE_DATE_LOAD,  SENT_TO_TIBCO,
        RANK() OVER(PARTITION BY SAP_MATERIAL_NUMBER ORDER BY CREATED_TS DESC ) AS RANK1 FROM RECON_CORE_PRODUCT_TXN
        WHERE CORE_CREATED_DATE >=  startDate and CORE_CREATED_DATE <= endDate) WHERE  RANK1 =1) CORE_PRODUCT
        LEFT OUTER JOIN (
        SELECT * FROM (SELECT SAP_MATERIAL_NUMBER AS EIS_MATNUM, STATUS AS EIS_STATUS, STATUS_MSG AS EIS_STATUS_MSG,
        RANK() OVER(PARTITION BY SAP_MATERIAL_NUMBER ORDER BY CREATED_TS DESC ) AS RANK2 FROM RECON_EIS_PRODUCT_TXN
        WHERE TIBCO_CREATED_DATE >= startDate and TIBCO_CREATED_DATE <= endDate) WHERE RANK2=1) EIS_PRODUCT
        ON EIS_PRODUCT.EIS_MATNUM = CORE_PRODUCT.CORE_MATNUM) CORE_EIS
        LEFT OUTER JOIN (
        SELECT * FROM (SELECT SAP_MATERIAL_NUMBER AS SAP_MATNUM, STATUS AS SAP_STATUS, STATUS_MSG AS SAP_STATUS_MSG,
        RANK() OVER(PARTITION BY SAP_MATERIAL_NUMBER ORDER BY CREATED_TS DESC ) AS RANK3 FROM RECON_SAP_PRODUCT_TXN
        WHERE SAP_CREATED_DATE >= startDate and SAP_CREATED_DATE <= endDate) WHERE RANK3=1) SAP_PRODUCT
        ON CORE_EIS.CORE_MATNUM = SAP_PRODUCT.SAP_MATNUM);


        SELECT coalesce(MAX(ID)+1, 1) INTO v_temp FROM RECON_RESULTS;

        Insert into RECON_RESULTS (ID,WRICEF,SOURCE,TARGET,START_DATE,END_DATE,SERVICE_NAME,
        INTERFACE_NAME,SOURCE_TOTAL,SOURCE_SUCCESS,SOURCE_ERRORS,EIS_TOTAL,EIS_SUCCESS,
        EIS_ERRORS,SAP_TOTAL,SAP_SUCCESS,SAP_ERRORS,CREATED_TS,FLOW_DIRECTION)
        values
        (v_temp,'I0203.1','JANIS','SAP', to_date(to_char(startDate,'YYYY-MM-DD'),'YYYY-MM-DD'), to_date(to_char(endDate,'YYYY-MM-DD'),'YYYY-MM-DD'),'PDMProductMaster01','UpdateProductMasterFromJANIS',
          v_c_total, v_c_success, v_c_failure,
          v_e_total, v_e_success, v_e_failure,
          v_s_total, v_s_success, v_s_failure, sysdate, 'I');


        FOR TEMP_RESULTS IN (
        SELECT SOURCE_SYSTEM AS SOURCE_SYSTEM, COUNT(*) AS CORE_TOTAL, COUNT(*) AS CORE_SUCCESS, 0 AS CORE_FAILURE,
        SUM(CASE WHEN EIS_ORDNUM is not null THEN 1 ELSE 0 END ) AS TIBCO_TOTAL,
        SUM(CASE WHEN EIS_ORDNUM is not null and EIS_STATUS = 'SUCCESS' THEN 1 ELSE 0 END ) AS TIBCO_SUCCESS,
        SUM(CASE WHEN EIS_ORDNUM is not null and EIS_STATUS != 'SUCCESS' THEN 1 ELSE 0 END ) AS TIBCO_FAILURE,
        SUM(CASE WHEN SAP_ORDNUM is not null  THEN 1 ELSE 0 END ) AS SAP_TOTAL,
        SUM(CASE WHEN SAP_ORDNUM is not null  and SAP_STATUS = 'SUCCESS' THEN 1 ELSE 0 END ) AS SAP_SUCCESS,
        SUM(CASE WHEN SAP_ORDNUM is not null  and SAP_STATUS != 'SUCCESS' THEN 1 ELSE 0 END ) AS SAP_FAILURE
        FROM (
        SELECT * FROM (
        SELECT * FROM (
        SELECT * FROM (
        SELECT SUB_ORD_REF_NUM AS CORE_ORDNUM, SOURCE_SYSTEM, CURRENCY_CODE, TOTAL_PRICE, CORE_CREATED_DATE, ORDER_TS,
        RANK() OVER (PARTITION BY SUB_ORD_REF_NUM ORDER BY CREATED_TS DESC ) AS RANK1 FROM RECON_CORE_ORDER_TXN
        WHERE CORE_CREATED_DATE>= startDate and CORE_CREATED_DATE <= endDate) WHERE RANK1 =1) CORE_ORDER
        LEFT OUTER JOIN (
        SELECT * FROM (SELECT SUB_ORD_REF_NUM AS EIS_ORDNUM, STATUS AS EIS_STATUS, STATUS_MSG AS EIS_STATUS_MSG,
        RANK() OVER (PARTITION BY SUB_ORD_REF_NUM ORDER BY CREATED_TS DESC ) AS RANK2 FROM RECON_EIS_ORDER_TXN
        WHERE TIBCO_CREATED_DATE >= startDate and TIBCO_CREATED_DATE <= endDate) WHERE RANK2=1) EIS_ORDER
        ON EIS_ORDER.EIS_ORDNUM =CORE_ORDER.CORE_ORDNUM) CORE_EIS
        LEFT OUTER JOIN (
        SELECT * FROM (SELECT SUB_ORD_REF_NUM AS SAP_ORDNUM, STATUS AS SAP_STATUS, STATUS_MSG AS SAP_STATUS_MSG,
        RANK() OVER (PARTITION BY SUB_ORD_REF_NUM ORDER BY CREATED_TS DESC ) AS RANK3 FROM RECON_SAP_ORDER_TXN
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
        SELECT SOURCE_SYSTEM AS SOURCE_SYSTEM, CURRENCY_CODE AS CURRENCY_CODE, COUNT(*) AS SRC_COUNT,
        SUM(TOTAL_PRICE) AS CORE_TOTAL, SUM(TOTAL_PRICE) AS CORE_SUCCESS, 0 AS CORE_FAILURE,
        SUM(CASE WHEN EIS_ORDNUM is not null THEN TOTAL_PRICE ELSE 0 END ) AS TIBCO_TOTAL,
        SUM(CASE WHEN EIS_ORDNUM is not null and EIS_STATUS = 'SUCCESS' THEN TOTAL_PRICE ELSE 0 END ) AS TIBCO_SUCCESS,
        SUM(CASE WHEN EIS_ORDNUM is not null and EIS_STATUS != 'SUCCESS' THEN TOTAL_PRICE ELSE 0 END ) AS TIBCO_FAILURE,
        SUM(CASE WHEN SAP_ORDNUM is not null  THEN TOTAL_PRICE ELSE 0 END ) AS SAP_TOTAL,
        SUM(CASE WHEN SAP_ORDNUM is not null  and SAP_STATUS = 'SUCCESS' THEN TOTAL_PRICE ELSE 0 END ) AS SAP_SUCCESS,
        SUM(CASE WHEN SAP_ORDNUM is not null  and SAP_STATUS != 'SUCCESS' THEN TOTAL_PRICE ELSE 0 END ) AS SAP_FAILURE
        FROM (
        SELECT * FROM (
        SELECT * FROM (
        SELECT * FROM (
        SELECT SUB_ORD_REF_NUM AS CORE_ORDNUM, SOURCE_SYSTEM, CURRENCY_CODE, TOTAL_PRICE, CORE_CREATED_DATE, ORDER_TS,
        RANK() OVER (PARTITION BY SUB_ORD_REF_NUM ORDER BY CREATED_TS DESC ) AS RANK1 FROM RECON_CORE_ORDER_TXN
        WHERE CORE_CREATED_DATE>= startDate and CORE_CREATED_DATE <= endDate) WHERE RANK1 =1) CORE_ORDER
        LEFT OUTER JOIN (
        SELECT * FROM (SELECT SUB_ORD_REF_NUM AS EIS_ORDNUM, STATUS AS EIS_STATUS, STATUS_MSG AS EIS_STATUS_MSG,
        RANK() OVER (PARTITION BY SUB_ORD_REF_NUM ORDER BY CREATED_TS DESC ) AS RANK2 FROM RECON_EIS_ORDER_TXN
        WHERE TIBCO_CREATED_DATE >= startDate and TIBCO_CREATED_DATE <= endDate) WHERE RANK2=1) EIS_ORDER
        ON EIS_ORDER.EIS_ORDNUM =CORE_ORDER.CORE_ORDNUM) CORE_EIS
        LEFT OUTER JOIN (
        SELECT * FROM (SELECT SUB_ORD_REF_NUM AS SAP_ORDNUM, STATUS AS SAP_STATUS, STATUS_MSG AS SAP_STATUS_MSG,
        RANK() OVER (PARTITION BY SUB_ORD_REF_NUM ORDER BY CREATED_TS DESC ) AS RANK3 FROM RECON_SAP_ORDER_TXN
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



CREATE OR REPLACE PACKAGE recon_product_pkg  AS
  PROCEDURE recon_product_errors (
  startDate IN  Timestamp,
  endDate IN Timestamp,
  errcode IN Varchar2,
  c_results OUT SYS_REFCURSOR
  );
END recon_product_pkg;

CREATE OR REPLACE PACKAGE BODY recon_product_pkg AS
  PROCEDURE recon_product_errors (
      startDate IN  Timestamp,
      endDate IN Timestamp,
      errcode IN Varchar2,
      c_results OUT SYS_REFCURSOR
      )
  AS
    log varchar2(1000);
    user_name varchar2(20);
    filterCondn varchar2(100);

    BEGIN

    user_name := 'Admin';
    log := 'Begin Product Fetch errors ' || startDate || ' ' || endDate || ' ' || errcode;
    INSERT INTO svc_logs( APPLICATION,LOG_LEVEL, LOG_LINE, log_text, create_user, create_date) VALUES ('recon_product_errors', 'INFO', '1.1', log, user_name, sysdate);

    IF errcode = 'SAP' THEN
        filterCondn:= ' WHERE SAP_MATNUM is not null and SAP_STATUS !=''SUCCESS''';
    ELSIF errcode = 'EIS' THEN
        filterCondn:= ' WHERE EIS_MATNUM is not null and EIS_STATUS !=''SUCCESS''';
    ELSIF errcode = 'SRC' THEN
        filterCondn:= ' WHERE SENT_TO_TIBCO !=''Y''';
    ELSIF errcode = 'EIS_MISS' THEN
        filterCondn:= ' WHERE CORE_MATNUM is not null and EIS_MATNUM is null';
    ELSE
        filterCondn:= ' WHERE 1!=1';
    END IF;

    OPEN c_results  FOR 'SELECT * FROM (
        SELECT * FROM (
        SELECT * FROM (SELECT SAP_MATERIAL_NUMBER AS CORE_MATNUM, EVENT, PRODUCT_TYPE, CORE_DATE_LOAD, CORE_CREATED_DATE,  SENT_TO_TIBCO,
        RANK() OVER(PARTITION BY SAP_MATERIAL_NUMBER ORDER BY CREATED_TS DESC ) AS RANK1 FROM RECON_CORE_PRODUCT_TXN
        WHERE CORE_CREATED_DATE >=  '''||startDate||''' and CORE_CREATED_DATE <= '''||endDate||''') WHERE  RANK1 =1) CORE_PRODUCT
        LEFT OUTER JOIN (
        SELECT * FROM (SELECT SAP_MATERIAL_NUMBER AS EIS_MATNUM, STATUS AS EIS_STATUS, STATUS_MSG AS EIS_STATUS_MSG,
        RANK() OVER(PARTITION BY SAP_MATERIAL_NUMBER ORDER BY CREATED_TS DESC ) AS RANK2 FROM RECON_EIS_PRODUCT_TXN
        WHERE TIBCO_CREATED_DATE >= '''||startDate||''' and TIBCO_CREATED_DATE <= '''||endDate||''') WHERE RANK2=1) EIS_PRODUCT
        ON EIS_PRODUCT.EIS_MATNUM = CORE_PRODUCT.CORE_MATNUM) CORE_EIS
        LEFT OUTER JOIN (
        SELECT * FROM (SELECT SAP_MATERIAL_NUMBER AS SAP_MATNUM, STATUS AS SAP_STATUS, STATUS_MSG AS SAP_STATUS_MSG,
        RANK() OVER(PARTITION BY SAP_MATERIAL_NUMBER ORDER BY CREATED_TS DESC ) AS RANK3 FROM RECON_SAP_PRODUCT_TXN
        WHERE SAP_CREATED_DATE >= '''||startDate||''' and SAP_CREATED_DATE <= '''||endDate||''') WHERE RANK3=1) SAP_PRODUCT
        ON CORE_EIS.CORE_MATNUM = SAP_PRODUCT.SAP_MATNUM' || filterCondn;
    END recon_product_errors;
END recon_product_pkg;


CREATE OR REPLACE PACKAGE recon_order_pkg  AS
  PROCEDURE recon_order_errors (
    startDate IN  Timestamp,
    endDate IN Timestamp,
    errcode IN Varchar2,
    srcSystem IN Varchar2,
    currencyCode IN Varchar2,
    c_results OUT SYS_REFCURSOR
  );
END recon_order_pkg;

create or replace PACKAGE BODY recon_order_pkg AS
  PROCEDURE recon_order_errors (
    startDate IN  Timestamp,
    endDate IN Timestamp,
    errcode IN Varchar2,
    srcSystem IN Varchar2,
    currencyCode IN Varchar2,
    c_results OUT SYS_REFCURSOR
  )
  AS
    log varchar2(1000);
    user_name varchar2(20);
    filterCondn varchar2(200);

    BEGIN
      user_name := 'Admin';
      log := 'Begin Orders Fetch errors ' || startDate || ' ' || endDate || ' ' || errcode;
      INSERT INTO svc_logs( APPLICATION,LOG_LEVEL, LOG_LINE, log_text, create_user, create_date) VALUES ('recon_order_errors', 'INFO', '1.1', log, user_name, sysdate);

      IF errcode = 'SAP' THEN
        filterCondn:= ' WHERE SAP_ORDNUM is not null and SAP_STATUS != ''SUCCESS''';
      ELSIF errcode = 'EIS' THEN
        filterCondn:= ' WHERE EIS_ORDNUM is not null and EIS_STATUS !=''SUCCESS''';
      ELSIF errcode = 'SRC' THEN
        filterCondn:= ' WHERE SAP_ORDNUM is not null and EIS_ORDNUM is null';
      ELSIF errcode = 'EIS_MISS' THEN
        filterCondn:= ' WHERE CORE_ORDNUM is not null and EIS_ORDNUM is null';
      ELSE
        filterCondn:= ' WHERE 1!=1';
      END IF;

      IF UPPER(currencyCode) != 'ALL' THEN
        filterCondn:= filterCondn || ' and CURRENCY_CODE ='''||currencyCode||'''';
      END IF;

      filterCondn:= filterCondn || ' and SOURCE_SYSTEM = '''||srcSystem||'''';

      INSERT INTO svc_logs( APPLICATION,LOG_LEVEL, LOG_LINE, log_text, create_user, create_date) VALUES ('recon_order_errors', 'INFO', '1.2', filterCondn, user_name, sysdate);

      OPEN c_results FOR 'SELECT * FROM (
        SELECT * FROM (
        SELECT * FROM (
        SELECT SUB_ORD_REF_NUM AS CORE_ORDNUM, SOURCE_SYSTEM, CURRENCY_CODE, TOTAL_PRICE, CORE_CREATED_DATE, ORDER_TS,
        RANK() OVER (PARTITION BY SUB_ORD_REF_NUM ORDER BY ID DESC ) AS RANK1 FROM RECON_CORE_ORDER_TXN
        WHERE CORE_CREATED_DATE>= '''||startDate||''' and CORE_CREATED_DATE <= '''||endDate||''') WHERE RANK1 =1) CORE_ORDER
        LEFT OUTER JOIN (
        SELECT * FROM (SELECT SUB_ORD_REF_NUM AS EIS_ORDNUM, STATUS AS EIS_STATUS, STATUS_CODE AS EIS_STATUS_CODE, STATUS_MSG AS EIS_STATUS_MSG,
        RANK() OVER (PARTITION BY SUB_ORD_REF_NUM ORDER BY ID DESC ) AS RANK2 FROM RECON_EIS_ORDER_TXN
        WHERE TIBCO_CREATED_DATE >= '''||startDate||''' and TIBCO_CREATED_DATE <= '''||endDate||''') WHERE RANK2=1) EIS_ORDER
        ON EIS_ORDER.EIS_ORDNUM =CORE_ORDER.CORE_ORDNUM) CORE_EIS
        LEFT OUTER JOIN (
        SELECT * FROM (SELECT SUB_ORD_REF_NUM AS SAP_ORDNUM, STATUS AS SAP_STATUS, STATUS_CODE AS SAP_STATUS_CODE, STATUS_MSG AS SAP_STATUS_MSG,
        RANK() OVER (PARTITION BY SUB_ORD_REF_NUM ORDER BY ID DESC ) AS RANK3 FROM RECON_SAP_ORDER_TXN
        WHERE SAP_CREATED_DATE >= '''||startDate||''' and SAP_CREATED_DATE <= '''||endDate||''') WHERE RANK3=1) SAP_ORDER
        ON CORE_EIS.CORE_ORDNUM =SAP_ORDER.SAP_ORDNUM ' || filterCondn ;

    END recon_order_errors;
END recon_order_pkg;