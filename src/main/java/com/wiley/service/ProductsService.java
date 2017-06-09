package com.wiley.service;

import com.wiley.DynamicRow;
import com.wiley.ReconDetailResponse;
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

import static com.wiley.ApplicationConstants.SDF;

/**
 * Created by sravuri on 5/30/17.
 */
@Service
public class ProductsService {

    private JdbcTemplate jdbcTemplate;
    private UtilService utilService;

    private static final Logger LOGGER = LoggerFactory.getLogger(ProductsService.class);

    @Autowired
    private ProductsService(JdbcTemplate jdbcTemplate, UtilService utilService) {
        this.jdbcTemplate = jdbcTemplate;
        this.utilService = utilService;
    }


    public ReconDetailResponse getProductDetails(Timestamp startDate, Timestamp endDate, String errorSrc){

        LOGGER.info("parameters passed : startDate = [" + startDate + "], endDate = [" + endDate + "], errorSrc = [" + errorSrc + "]");

        SimpleJdbcCall simpleJdbcCall = new SimpleJdbcCall(jdbcTemplate);
        simpleJdbcCall.withSchemaName("eisadmin").withCatalogName("recon_product_pkg").withProcedureName("recon_product_errors");

        simpleJdbcCall.declareParameters(new SqlParameter("startDate", OracleTypes.TIMESTAMP));
        simpleJdbcCall.declareParameters(new SqlParameter("endDate", OracleTypes.TIMESTAMP));
        simpleJdbcCall.declareParameters(new SqlParameter("errcode", OracleTypes.VARCHAR));

        simpleJdbcCall.declareParameters(new SqlOutParameter("c_results", OracleTypes.CURSOR, new RowMapper<DynamicRow>() {
            public DynamicRow mapRow(ResultSet rs, int i) throws SQLException {
                Date createDate = rs.getDate("CORE_CREATE_DATE");
                String createDate_S = createDate != null ? SDF.format(createDate) : "";

                return new DynamicRow(rs.getString("CORE_MATNUM"),
                        rs.getString("PRODUCT_TYPE"),
                        createDate_S,
                        rs.getString("STATUS_CODE"),
                        rs.getString("STATUS_MSG"),
                        null,
                        null
                );
            }
        }));



        MapSqlParameterSource in = new MapSqlParameterSource();
        in.addValue("startDate", startDate);
        in.addValue("endDate", endDate);
        in.addValue("errcode", errorSrc);

        List<DynamicRow> rows = simpleJdbcCall.executeObject(List.class, in);

        List<String> columns = new ArrayList<>();
        columns.add("Material Number");
        columns.add("Product Type");
        columns.add("Posted Date");
        columns.add("Error Code");
        columns.add("Error Message");

        return  utilService.createResponse(columns, rows, SDF.format(startDate), SDF.format(endDate),
                        "UpdateProductMasterInbound", "JANIS", "SAP", "I0203.1");
    }

}