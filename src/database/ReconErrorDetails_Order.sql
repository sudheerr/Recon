CREATE OR REPLACE PACKAGE recon_order_pkg  AS 
  PROCEDURE recon_order_errors (
  startDate IN  Timestamp,
  endDate IN Timestamp,
  errcode IN Varchar2,
  srcSystem IN Varchar2,
  c_results OUT SYS_REFCURSOR
  ); 
END recon_order_pkg;

CREATE OR REPLACE PACKAGE BODY recon_order_pkg AS
  PROCEDURE recon_order_errors (
      startDate IN  Timestamp,
      endDate IN Timestamp,
      errcode IN Varchar2,
      srcSystem IN Varchar2,
      c_results OUT SYS_REFCURSOR
      )
  AS
    log varchar2(1000);
    user_name varchar2(20);
    filterCondn varchar2(100);
    
    BEGIN
    user_name := 'Admin';
    log := 'Begin Orders Fetch errors ' || startDate || ' ' || endDate || ' ' || errcode;
    INSERT INTO svc_logs( APPLICATION,LOG_LEVEL, LOG_LINE, log_text, create_user, create_date) VALUES ('recon_order_errors', 'INFO', '1.1', log, user_name, sysdate);
    
    IF errcode = 'SAP' THEN
          filterCondn:= ' WHERE STATUS=''FoundInSAP'' and STATUS_CODE !=53';
    ELSIF errcode = 'EIS' THEN
        filterCondn:= ' WHERE STATUS=''MissingInSAP'' and SAP_EIS_ORDER is not null';
    ELSIF errcode = 'SRC' THEN
        filterCondn:= ' WHERE STATUS=''MissingInSAP'' and SAP_EIS_ORDER is null';
    ELSE
        filterCondn:= ' WHERE 1!=1';
    END IF;
    
    filterCondn:= filterCondn || ' and SOURCE_SYSTEM = '''||srcSystem||'''';
    
    INSERT INTO svc_logs( APPLICATION,LOG_LEVEL, LOG_LINE, log_text, create_user, create_date) VALUES ('recon_order_errors', 'INFO', '1.2', filterCondn, user_name, sysdate);
    
    OPEN c_results FOR 'SELECT STATUS, SUB_ORD_REF_NUM, STATUS_CODE, SOURCE_SYSTEM, LINE_ITEM_COUNT, TOTAL_PRICE, SAP_EIS_ORDER, CORE_LOAD_DATE_TIME, STATUS_MSG FROM(
    SELECT ''FoundInSAP'' AS STATUS, SAP_ORDER.SUB_ORD_REF_NUM, SAP_ORDER.STATUS_CODE, TRIM(SOURCE_SYSTEM) AS SOURCE_SYSTEM, SAP_ORDER.LINE_ITEM_COUNT, SAP_ORDER.TOTAL_PRICE, SAP_ORDER.SUB_ORD_REF_NUM AS SAP_EIS_ORDER,
    CORE_ORDER.CORE_LOAD_DATE_TIME, SAP_ORDER.STATUS_MSG FROM (
    SELECT SUB_ORD_REF_NUM, COUNT(PRODUCT_SEQUENCE) AS LIST_COUNT, MAX(SOURCE_SYSTEM) AS SOURCE_SYSTEM, SUM(LIST_PRICE) AS TOTAL_PRICE, MAX(CORE_LOAD_DATE_TIME)AS CORE_LOAD_DATE_TIME FROM (
    SELECT ID, SUB_ORD_REF_NUM, SOURCE_SYSTEM, PRODUCT_SEQUENCE, LIST_PRICE, RANK() OVER (PARTITION BY SUB_ORD_REF_NUM,  PRODUCT_SEQUENCE ORDER BY ID DESC) AS CORE_RNK, CORE_LOAD_DATE_TIME FROM recon_core_order_txn
    WHERE CORE_LOAD_DATE_TIME>= '''||startDate||''' and CORE_LOAD_DATE_TIME <= '''||endDate||''') WHERE CORE_RNK =1
    GROUP BY SUB_ORD_REF_NUM) CORE_ORDER
    JOIN (
    SELECT SUB_ORD_REF_NUM, STATUS_CODE,  TOTAL_PRICE, LINE_ITEM_COUNT,  CREATED_TS, STATUS_MSG FROM (
    select SUB_ORD_REF_NUM, STATUS_CODE, TOTAL_PRICE, LINE_ITEM_COUNT,  CREATED_TS, STATUS_MSG, RANK() OVER (PARTITION BY SUB_ORD_REF_NUM ORDER BY ID DESC) 
    AS SAP_RNK from recon_sap_order_txn WHERE ORDER_TS>= '''||startDate||''' and ORDER_TS <= '''||endDate||''' )  WHERE SAP_RNK=1) SAP_ORDER
    ON CORE_ORDER.SUB_ORD_REF_NUM = SAP_ORDER.SUB_ORD_REF_NUM
    UNION
    SELECT ''MissingInSAP'', CORE_SAP.SUB_ORD_REF_NUM, null, TRIM(SOURCE_SYSTEM) AS SOURCE_SYSTEM, CORE_SAP.LIST_COUNT, CORE_SAP.TOTAL_PRICE, EIS_ORDER.SUB_ORD_REF_NUM, EIS_ORDER.TIBCO_CREATE_DATE, STATUS_MSG FROM (
    SELECT CORE_ORDER.SUB_ORD_REF_NUM, CORE_ORDER.LIST_COUNT, SOURCE_SYSTEM, CORE_ORDER.TOTAL_PRICE, SAP_ORDER.STATUS_MSG FROM (
    SELECT SUB_ORD_REF_NUM, COUNT(PRODUCT_SEQUENCE) AS LIST_COUNT, MAX(SOURCE_SYSTEM) AS SOURCE_SYSTEM,SUM(LIST_PRICE) AS TOTAL_PRICE FROM (
    SELECT ID, SUB_ORD_REF_NUM, PRODUCT_SEQUENCE, SOURCE_SYSTEM, LIST_PRICE, RANK() OVER (PARTITION BY SUB_ORD_REF_NUM,  PRODUCT_SEQUENCE ORDER BY ID DESC) AS CORE_RNK, CORE_LOAD_DATE_TIME FROM recon_core_order_txn
    WHERE CORE_LOAD_DATE_TIME>= '''||startDate||''' and CORE_LOAD_DATE_TIME <= '''||endDate||''') WHERE CORE_RNK =1
    GROUP BY SUB_ORD_REF_NUM) CORE_ORDER
    LEFT JOIN (
    SELECT SUB_ORD_REF_NUM, TOTAL_PRICE, LINE_ITEM_COUNT,  CREATED_TS, STATUS_MSG FROM (
    select SUB_ORD_REF_NUM, TOTAL_PRICE, LINE_ITEM_COUNT,  CREATED_TS, STATUS_MSG, RANK() OVER (PARTITION BY SUB_ORD_REF_NUM ORDER BY ID DESC) 
    AS SAP_RNK from recon_sap_order_txn WHERE ORDER_TS>= '''||startDate||''' and ORDER_TS <= '''||endDate||''' )  WHERE SAP_RNK=1) SAP_ORDER
    ON CORE_ORDER.SUB_ORD_REF_NUM = SAP_ORDER.SUB_ORD_REF_NUM
    WHERE SAP_ORDER.SUB_ORD_REF_NUM is null
    ) CORE_SAP 
    LEFT JOIN 
    (SELECT SUB_ORD_REF_NUM, LINE_ITEM_COUNT, TOTAL_PRICE, TIBCO_CREATE_DATE  FROM(
    select SUB_ORD_REF_NUM , TOTAL_PRICE, LINE_ITEM_COUNT,  CREATED_TS, TIBCO_CREATE_DATE, RANK() OVER (PARTITION BY SUB_ORD_REF_NUM ORDER BY ID DESC) 
    AS TIB_RNK from recon_eis_order_txn WHERE TIBCO_CREATE_DATE>= '''||startDate||''' and TIBCO_CREATE_DATE <= '''||endDate||''' )  WHERE TIB_RNK=1) EIS_ORDER
    ON CORE_SAP.SUB_ORD_REF_NUM = EIS_ORDER.SUB_ORD_REF_NUM)' || filterCondn ;

    END recon_order_errors;
END recon_order_pkg;

--select * from svc_logs order by log_id desc;
--var results refcursor;
--exec recon_order_pkg.recon_order_errors( TO_TIMESTAMP ('2017/05/31 00:00:00', 'YYYY/MM/DD HH24:MI:SS'), TO_TIMESTAMP ('2017/05/31 23:59:59', 'YYYY/MM/DD HH24:MI:SS'), 'SAP', 'CSS', :results);
--print results
--COMMIT