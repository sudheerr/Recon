package com.wiley;

import oracle.jdbc.OracleTypes;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.*;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Service;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

import static com.wiley.ApplicationConstants.sdf;

/**
 * Created by ravuri on 5/30/17.
 */
@Service
public class ProductsService {
    private JdbcTemplate jdbcTemplate;
    private static final Logger LOGGER = LoggerFactory.getLogger(ProductsService.class);

    @Autowired
    public ProductsService(JdbcTemplate jdbcTemplate){
        this.jdbcTemplate =jdbcTemplate;
    }

    private String productsDetails_query = " call recon_product_pkg.recon_product_errors( ?, ?, ?, ?)";

    public ReconDetailResponse getProductDetails(Timestamp startDate, Timestamp endDate, String errorSrc) throws SQLException {

        LOGGER.info("parameters passed : startDate = [" + startDate + "], endDate = [" + endDate + "], errorSrc = [" + errorSrc + "]");

        SimpleJdbcCall simpleJdbcCall = new SimpleJdbcCall(jdbcTemplate);
        simpleJdbcCall.withSchemaName("eisadmin").withCatalogName("recon_product_pkg").withProcedureName("recon_product_errors");

        simpleJdbcCall.declareParameters(new SqlParameter("startDate", OracleTypes.TIMESTAMP));
        simpleJdbcCall.declareParameters(new SqlParameter("endDate", OracleTypes.TIMESTAMP));
        simpleJdbcCall.declareParameters(new SqlParameter("errcode", OracleTypes.VARCHAR));
        simpleJdbcCall.declareParameters(new SqlOutParameter("c_results", OracleTypes.CURSOR, new DynamicRowMapper()));

        MapSqlParameterSource in = new MapSqlParameterSource();
        in.addValue("startDate", startDate);
        in.addValue("endDate", endDate);
        in.addValue("errcode", errorSrc);

        List<DynamicRow> rows = simpleJdbcCall.executeObject(List.class, in);

        ReconDetailResponse response = new ReconDetailResponse();
        List<DynamicColumn> columns = new ArrayList<>();

        columns.add(new DynamicColumn("Material Number", "field1"));
        columns.add(new DynamicColumn("Posted Date", "field2"));
        columns.add(new DynamicColumn("Error Code", "field3"));
        columns.add(new DynamicColumn("Error Message", "field4"));

        response.setColumns(columns);
        response.setData(rows);

        response.setStartDate(sdf.format(startDate));
        response.setEndDate(sdf.format(endDate));
        response.setInterfaceName("UpdateProductMasterInbound");
        response.setSource("JANIS");
        response.setTarget("SAP");
        response.setWricef("I0203.1");

        return response;
    }
}

class DynamicRowMapper implements RowMapper<DynamicRow> {

    @Override
    public DynamicRow mapRow(ResultSet rs, int i) throws SQLException {
        Date createDate = rs.getDate("CORE_CREATE_DATE");
        String createDate_S = createDate != null ? sdf.format(createDate) : "";

        return new DynamicRow(rs.getString("CORE_MATNUM"),
                createDate_S,
                rs.getString("STATUS_CODE"),
                rs.getString("STATUS_MSG"),
                null,
                null,
                null
        );
    }
}