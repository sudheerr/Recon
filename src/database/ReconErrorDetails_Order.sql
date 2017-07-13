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

      IF errcode = 'SRC' THEN
        filterCondn:= ' WHERE SRC_STATUS !=''SUCCESS''';
      ELSIF errcode = 'MW' THEN
        filterCondn:= ' WHERE MW_ORDNUM is not null and MW_STATUS !=''SUCCESS'' and (TGT_ORDNUM is null or TGT_STATUS != ''SUCCESS'')';
      ELSIF errcode = 'TGT' THEN
        filterCondn:= ' WHERE TGT_ORDNUM is not null and TGT_STATUS != ''SUCCESS''';
      ELSIF errcode = 'MW_MISS' THEN
        filterCondn:= ' WHERE SRC_STATUS =''SUCCESS'' and  MW_ORDNUM is null and (TGT_STATUS is null)';
      ELSIF errcode = 'TGT_MISS' THEN
        filterCondn:= ' WHERE MW_ORDNUM is not null and TGT_ORDNUM is NULL and MW_STATUS =''SUCCESS''';
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
        SELECT SUB_ORD_REF_NUM AS SRC_ORDNUM, SOURCE_SYSTEM, CURRENCY_CODE, TOTAL_PRICE, CORE_CREATED_DATE, ORDER_TS,
        STATUS AS SRC_STATUS, STATUS_CODE AS SRC_STATUS_CODE, STATUS_MSG AS SRC_STATUS_MSG,
        RANK() OVER (PARTITION BY SUB_ORD_REF_NUM ORDER BY CREATED_TS DESC, CORE_CREATED_DATE DESC ) AS RANK1 FROM RECON_CORE_ORDER_TXN
        WHERE CORE_CREATED_DATE>= '''||startDate||''' and CORE_CREATED_DATE <= '''||endDate||''') WHERE RANK1 =1) CORE_ORDER
        LEFT OUTER JOIN (
        SELECT * FROM (SELECT SUB_ORD_REF_NUM AS MW_ORDNUM, STATUS AS MW_STATUS, STATUS_CODE AS MW_STATUS_CODE, STATUS_MSG AS MW_STATUS_MSG,
        RANK() OVER (PARTITION BY SUB_ORD_REF_NUM ORDER BY CREATED_TS DESC, TIBCO_CREATED_DATE DESC ) AS RANK2 FROM RECON_EIS_ORDER_TXN
        WHERE TIBCO_CREATED_DATE >= '''||startDate||''' and TIBCO_CREATED_DATE <= '''||endDate||''') WHERE RANK2=1) EIS_ORDER
        ON EIS_ORDER.MW_ORDNUM =CORE_ORDER.SRC_ORDNUM) CORE_EIS
        LEFT OUTER JOIN (
        SELECT * FROM (SELECT SUB_ORD_REF_NUM AS TGT_ORDNUM, STATUS AS TGT_STATUS, STATUS_CODE AS TGT_STATUS_CODE, STATUS_MSG AS TGT_STATUS_MSG,
        RANK() OVER (PARTITION BY SUB_ORD_REF_NUM ORDER BY CREATED_TS DESC, SAP_CREATED_DATE DESC ) AS RANK3 FROM RECON_SAP_ORDER_TXN
        WHERE SAP_CREATED_DATE >= '''||startDate||''' and SAP_CREATED_DATE <= '''||endDate||''') WHERE RANK3=1) SAP_ORDER
        ON CORE_EIS.SRC_ORDNUM =SAP_ORDER.TGT_ORDNUM ' || filterCondn ;

    END recon_order_errors;
END recon_order_pkg;