create or replace PACKAGE recon_fulflmnt_pkg  AS
  PROCEDURE recon_fulflmnt_errors (
  startDate IN  Timestamp,
  endDate IN Timestamp,
  errcode IN Varchar2,
  c_results OUT SYS_REFCURSOR
  ); 
END recon_fulflmnt_pkg;

create or replace PACKAGE BODY recon_fulflmnt_pkg AS
  PROCEDURE recon_fulflmnt_errors (
      startDate IN  Timestamp,
      endDate IN Timestamp,
      errcode IN Varchar2,
      c_results OUT SYS_REFCURSOR
      )
  AS
    log varchar2(1000);
    user_name varchar2(20);
    filterCondn varchar2(200);

    BEGIN

    user_name := 'Admin';
    log := 'Begin Fulfillment Orders ' || startDate || ' ' || endDate || ' ' || errcode;
    INSERT INTO svc_logs( APPLICATION, LOG_LEVEL, LOG_LINE, log_text, create_user, create_date) VALUES ('recon_order_errors', 'INFO', '1.1', log, user_name, sysdate);

 IF errcode = 'SRC' THEN
      filterCondn:= ' WHERE SRC_STATUS !=''SUCCESS''';
  ELSIF errcode = 'MW' THEN
      filterCondn:= ' WHERE MW_ORDNUM is not null and MW_STATUS !=''SUCCESS''';
  ELSIF errcode = 'TGT' THEN
      filterCondn:= ' WHERE TGT_ORDNUM is not null and TGT_STATUS !=''SUCCESS''';
  ELSIF errcode = 'MW_MISS' THEN
      filterCondn:= ' WHERE SRC_STATUS = ''SUCCESS'' and MW_ORDNUM is null';
  ELSIF errcode = 'TGT_MISS' THEN
      filterCondn:= ' WHERE MW_ORDNUM is not null and TGT_ORDNUM is NULL and MW_STATUS = ''SUCCESS''';
  ELSE
      filterCondn:= ' WHERE 1!=1';
  END IF;

    OPEN c_results  FOR 'SELECT * FROM (
        SELECT * FROM (SELECT * FROM (SELECT SAP_ORDER_NUMBER AS SRC_ORDNUM, IDOC_NUMBER, SAP_CREATED_DATE, STATUS AS SRC_STATUS,
		    RANK() OVER(PARTITION BY SAP_ORDER_NUMBER ORDER BY CREATED_TS DESC, SAP_CREATED_DATE DESC ) AS RANK1 FROM RECON_SAP_FULFLMNT_TXN
        WHERE SAP_CREATED_DATE >=  '''||startDate||''' and SAP_CREATED_DATE <= '''||endDate||''') WHERE  RANK1 =1) SAP_FULFLMNT
        LEFT OUTER JOIN (
        SELECT * FROM (SELECT SAP_ORDER_NUM AS MW_ORDNUM, LINE_ITEM_COUNT, IDOC_NUMBER, MESSAGE_FUNCTION, SUB_ORD_REF_NUM, STATUS AS MW_STATUS,
        STATUS_CODE AS MW_STATUS_CODE, STATUS_MSG AS MW_STATUS_MSG,
        RANK() OVER(PARTITION BY SAP_ORDER_NUM ORDER BY CREATED_TS DESC, TIBCO_CREATED_DATE DESC ) AS RANK2 FROM RECON_EIS_FULFLMNT_TXN
        WHERE TIBCO_CREATED_DATE >= '''||startDate||''' and TIBCO_CREATED_DATE <= '''||endDate||''') WHERE RANK2=1) EIS_FULFLMNT
		    ON EIS_FULFLMNT.MW_ORDNUM = SAP_FULFLMNT.SRC_ORDNUM) SAP_EIS
        LEFT OUTER JOIN (
        SELECT * FROM (SELECT FULFILLMENT_ID AS TGT_ORDNUM, LINE_ITEM_COUNT, STATUS AS TGT_STATUS, STATUS_CODE AS TGT_STATUS_CODE,
        STATUS_MSG AS TGT_STATUS_MSG,
		    RANK() OVER(PARTITION BY FULFILLMENT_ID ORDER BY CREATED_TS DESC, ALM_CREATED_DATE DESC ) AS RANK3 FROM RECON_ALM_FULFLMNT_TXN
        WHERE ALM_CREATED_DATE >= '''||startDate||''' and ALM_CREATED_DATE <= '''||endDate||''') WHERE RANK3=1) ALM_FULFLMNT
        ON SAP_EIS.SRC_ORDNUM = ALM_FULFLMNT.TGT_ORDNUM' || filterCondn;
    END RECON_FULFLMNT_ERRORS;
END recon_fulflmnt_pkg;