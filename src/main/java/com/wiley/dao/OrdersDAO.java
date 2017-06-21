package com.wiley.dao;

import com.wiley.model.DynamicRow;
import com.wiley.model.ReconDetailResponse;
import com.wiley.service.UtilService;
import oracle.jdbc.OracleTypes;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
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
    private final UtilService utilService;

    private static final Logger LOGGER = LoggerFactory.getLogger(OrdersDAO.class);

    @Autowired
    public OrdersDAO(UtilService utilService) {
        this.utilService = utilService;
    }

    public ReconDetailResponse getOrderDetails(Timestamp startDate, Timestamp endDate, String errorSrc, String wricef){

        LOGGER.info("parameters passed : startDate = [" + startDate + "], endDate = [" + endDate + "], errorSrc = [" + errorSrc + "]");
        String interfaceName, source, srcSystem;

        if (wricef.equals("I0230.6")) {
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
            srcSystem = "PDM";
            interfaceName = "UpdateOrderFromPDMicroSites";
            source = "PD Microsites";
        } else {
            return null;
        }

        SimpleJdbcCall simpleJdbcCall = new SimpleJdbcCall(getJdbcTemplate());
        simpleJdbcCall.withSchemaName(EISADMIN).withCatalogName("recon_order_pkg").withProcedureName("recon_order_errors");

        simpleJdbcCall.declareParameters(new SqlParameter(START_DATE, OracleTypes.TIMESTAMP));
        simpleJdbcCall.declareParameters(new SqlParameter(END_DATE, OracleTypes.TIMESTAMP));
        simpleJdbcCall.declareParameters(new SqlParameter(ERROR_CODE, OracleTypes.VARCHAR));
        simpleJdbcCall.declareParameters(new SqlParameter("srcSystem", OracleTypes.VARCHAR));

        simpleJdbcCall.declareParameters(new SqlOutParameter("c_results", OracleTypes.CURSOR, new RowMapper<DynamicRow>() {
            public DynamicRow mapRow(ResultSet rs, int i) throws SQLException {
                Date createDate = rs.getDate("CORE_LOAD_DATE_TIME");
                String createDateStr = createDate != null ? SDF.format(createDate) : "";

                return new DynamicRow(rs.getString("SUB_ORD_REF_NUM"),
                        createDateStr,
                        rs.getString("CURRENCY_CODE"),
                        rs.getString("TOTAL_PRICE"),
                        rs.getString("STATUS_CODE"),
                        rs.getString("STATUS_MSG"),
                        null
                );
            }
        }));

        MapSqlParameterSource in = new MapSqlParameterSource();
        in.addValue(START_DATE, startDate);
        in.addValue(END_DATE, endDate);
        in.addValue(ERROR_CODE, errorSrc);
        in.addValue("srcSystem", srcSystem);

        List<DynamicRow> rows = simpleJdbcCall.executeObject(List.class, in);

        List<String> columns = new ArrayList<>();

        columns.add("Sub Order Ref Number");
        columns.add("Posted Date");
        columns.add("Currency Code");
        columns.add("Total Order Price");
        columns.add("Error Code");
        columns.add("Error Message");

        return utilService.createResponse(columns, rows, SDF.format(startDate),
                SDF.format(endDate), interfaceName,
                source, "SAP", wricef);
    }

}