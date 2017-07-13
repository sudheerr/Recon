package com.wiley.dao;

import com.wiley.model.ColumnType;
import com.wiley.model.UIColumn;
import com.wiley.model.UIRow;
import com.wiley.model.ReconDetailResponse;
import oracle.jdbc.OracleTypes;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.core.SqlOutParameter;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Service;

import java.sql.Date;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

import static com.wiley.ApplicationConstants.*;

/**
 * Created by sravuri on 6/1/17.
 * WRICEF
 * I0230.6  EEP,
 * I0230.7  PQ,
 * I0230.8  CSS
 */
@Service
public class OrdersDAO extends GenericDAO{
    private static final Logger LOGGER = LoggerFactory.getLogger(OrdersDAO.class);

    public ReconDetailResponse getOrderDetails(Timestamp startDate, Timestamp endDate, final String errorSrc, String wricef, String currencyCode){

        LOGGER.info("parameters passed : startDate = [" + startDate + "], endDate = [" + endDate + "], errorSrc = [" + errorSrc + "]");
        String interfaceName, source, srcSystem;

        if (wricef.equals("I0212.17")) {
            srcSystem = "0301";// WOL Bookstore
            interfaceName = "UpdateSalesOrderFromWOLBook";
            source = "WOL Bookstore";
        }else if (wricef.equals("I0230.6")) {
            srcSystem = "0205";// EEP
            interfaceName = "UpdateSubscriptionOrderFromInfoPoems";
            source = "InfoPoems/Essential Evidence Plus";
        } else if (wricef.equals("I0230.7")) {
            srcSystem = "PQ";
            interfaceName = "UpdateSubscriptionOrderFromPriceQuote";
            source = "Price Quote";
        } else if (wricef.equals("I0230.8")) {
            srcSystem = "CSS";
            interfaceName = "UpdateSubscriptionOrderFromCSS";
            source = "CSS";
        } else if (wricef.equals("I0343")) {
            srcSystem = "PDMS";
            interfaceName = "UpdateOrderFromPDMicroSites";
            source = "PD Microsites";
        } else {
            return null;
        }

        final String temperrorSrc =  errorSrc.equals("MW_MISS")?"SRC":errorSrc.equals("TGT_MISS")?"MW":errorSrc;

        SimpleJdbcCall simpleJdbcCall = new SimpleJdbcCall(getJdbcTemplate());
        simpleJdbcCall.withSchemaName(EISRECON).withCatalogName("recon_order_pkg").withProcedureName("recon_order_errors");

        simpleJdbcCall.declareParameters(new SqlParameter(START_DATE, OracleTypes.TIMESTAMP));
        simpleJdbcCall.declareParameters(new SqlParameter(END_DATE, OracleTypes.TIMESTAMP));
        simpleJdbcCall.declareParameters(new SqlParameter(ERROR_CODE, OracleTypes.VARCHAR));
        simpleJdbcCall.declareParameters(new SqlParameter("srcSystem", OracleTypes.VARCHAR));
        simpleJdbcCall.declareParameters(new SqlParameter("currencyCode", OracleTypes.VARCHAR));

        simpleJdbcCall.declareParameters(new SqlOutParameter("c_results", OracleTypes.CURSOR, new RowMapper<UIRow>() {
            public UIRow mapRow(ResultSet rs, int i) throws SQLException {
                Date createDate = rs.getDate("CORE_CREATED_DATE");
                String createDateStr = createDate != null ? SDF.format(createDate) : "";

                return new UIRow(rs.getString("SRC_ORDNUM"),
                        createDateStr,
                        rs.getString("CURRENCY_CODE"),
                        rs.getString("TOTAL_PRICE"),
                        rs.getString(temperrorSrc+"_STATUS_CODE"),
                        rs.getString(temperrorSrc+"_STATUS_MSG"),
                        null,
                        rs.getString("CURRENCY_CODE")
                );
            }
        }));

        MapSqlParameterSource in = new MapSqlParameterSource();
        in.addValue(START_DATE, startDate);
        in.addValue(END_DATE, endDate);
        in.addValue(ERROR_CODE, errorSrc);
        in.addValue("srcSystem", srcSystem);
        in.addValue("currencyCode", currencyCode);

        List<UIRow> rows = simpleJdbcCall.executeObject(List.class, in);
        List<UIColumn> columns = new ArrayList<>();
        columns.add(new UIColumn("Sub Order Ref Number","field1",""));
        columns.add(new UIColumn("Posted Date","field2",""));
        columns.add(new UIColumn("Currency Code","field3",""));
        columns.add(new UIColumn("Total Order Value","field4","dt-right", ColumnType.CURRENCY));
        columns.add(new UIColumn("Status Code","field5",""));
        columns.add(new UIColumn("Status Message","field6",""));

        return getUtilService().createResponse(columns, rows, SDF.format(startDate),
                SDF.format(endDate), interfaceName,
                source, "SAP", wricef);
    }

}