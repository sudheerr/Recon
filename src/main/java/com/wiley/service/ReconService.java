package com.wiley.service;

import com.wiley.ReconResult;
import com.wiley.ReconResultsMapper;
import oracle.jdbc.OracleTypes;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Service;

import java.sql.Timestamp;
import java.text.ParseException;
import java.util.List;

@Service
public class ReconService {

    private JdbcTemplate jdbcTemplate;
    private UtilService utilService;

    @Autowired
    public ReconService(JdbcTemplate jdbcTemplate, UtilService utilService) {
        this.jdbcTemplate = jdbcTemplate;
        this.utilService = utilService;
    }

    private static final String FETCH_RESULTS = "SELECT * FROM (select id, wricef, source, target, start_date, end_date, service_name, interface_name, source_total, source_success, source_errors," +
            " eis_total, eis_success, eis_errors, sap_total, sap_success, sap_errors, flow_direction,  RANK() OVER (PARTITION BY WRICEF ORDER BY ID DESC) RANK  from recon_results  " +
            " where START_DATE =TO_DATE(?,'YYYYMMDD') and END_DATE = TO_DATE(?,'YYYYMMDD'))  WHERE RANK=1";


    public List<ReconResult> fetchResults(String startDate, String endDate){
        Object[] args = new Object[2];
        args[0]=startDate;
        args[1]= endDate;

        List<ReconResult> results = jdbcTemplate.query(FETCH_RESULTS, args, new ReconResultsMapper());

        if(results.size()==0){
        /*  Perform Dynamic Query
            TODO Ideally dynamic query should be handled seperately. right now we can distinguish between
            Precomputed dates (Yesterday, WTD, MTD, QTD) and  Custom Range
        */
            Timestamp sDate, eDate;
            try {
                sDate =utilService.getStartofDay(startDate);
                eDate =utilService.getEndofDay(endDate);
                loadResultsData(sDate,eDate);
                results = jdbcTemplate.query(FETCH_RESULTS, args, new ReconResultsMapper());

            }catch (ParseException e){
                //TODO Handle Error
                //At present this code is not reachable, as dates are parsed in the Reconcontroller
            }
        }
        return results;
    }

    public void loadResultsData(Timestamp startDate, Timestamp endDate){
        SimpleJdbcCall simpleJdbcCall = new SimpleJdbcCall(jdbcTemplate);
        simpleJdbcCall.withSchemaName("eisadmin").withCatalogName("recon_pkg").withProcedureName("recon_populate_results");

        simpleJdbcCall.declareParameters(new SqlParameter("startDate", OracleTypes.TIMESTAMP));
        simpleJdbcCall.declareParameters(new SqlParameter("endDate", OracleTypes.TIMESTAMP));

        MapSqlParameterSource in = new MapSqlParameterSource();
        in.addValue("startDate", startDate);
        in.addValue("endDate", endDate);

        simpleJdbcCall.execute(in);
    }
}