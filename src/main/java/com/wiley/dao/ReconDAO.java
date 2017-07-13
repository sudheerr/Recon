package com.wiley.dao;

import com.wiley.model.ReconResult;
import com.wiley.model.mapper.ReconResultMapper;
import com.wiley.service.UtilService;
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

import static com.wiley.ApplicationConstants.EISRECON;
import static com.wiley.ApplicationConstants.END_DATE;
import static com.wiley.ApplicationConstants.START_DATE;

@Service
public class ReconDAO extends GenericDAO{

    private final UtilService utilService;

    @Autowired
    public ReconDAO(JdbcTemplate jdbcTemplate, UtilService utilService) {
        this.utilService = utilService;
    }

    private static final String FETCH_RESULTS = "SELECT * FROM (select id, wricef, source, target, start_date, end_date, service_name, interface_name, source_total, source_success, source_errors," +
            " eis_total, eis_success, eis_errors, tgt_total, tgt_success, tgt_errors, flow_direction, source_total as src_count, RANK() OVER (PARTITION BY WRICEF ORDER BY ID DESC) RANK, eis_missing, tgt_missing from recon_results  " +
            " where START_DATE =TO_DATE(?,'YYYYMMDD') and END_DATE = TO_DATE(?,'YYYYMMDD'))  WHERE RANK=1";

    private static final String FETCH_ORDER_RESULTS = "SELECT * FROM (select id, wricef, source, target, start_date, end_date, service_name, interface_name, source_total, source_success, source_errors," +
            " eis_total, eis_success, eis_errors, tgt_total, tgt_success, tgt_errors, currency, src_count,  RANK() OVER (PARTITION BY WRICEF, CURRENCY ORDER BY ID DESC) RANK, eis_missing, tgt_missing  from order_results  " +
            " where START_DATE =TO_DATE(?,'YYYYMMDD') and END_DATE = TO_DATE(?,'YYYYMMDD'))  WHERE RANK=1";

    public List<ReconResult> fetchResults(String startDate, String endDate, boolean transactions){

        Object[] args = new Object[2];
        args[0]=startDate;
        args[1]= endDate;

        List<ReconResult> results;
        if(transactions){
            results = getJdbcTemplate().query(FETCH_RESULTS, args, new ReconResultMapper());
        }else{
            results = getJdbcTemplate().query(FETCH_ORDER_RESULTS, args, new ReconResultMapper());
        }

        if(results.size()==0){
            // Perform Dynamic Query

            Timestamp sDate, eDate;
            try {
                sDate =utilService.getStartofDay(startDate);
                eDate =utilService.getEndofDay(endDate);
                loadResultsData(sDate,eDate);
                if(transactions){
                    results = getJdbcTemplate().query(FETCH_RESULTS, args, new ReconResultMapper());
                }else{
                    results = getJdbcTemplate().query(FETCH_ORDER_RESULTS, args, new ReconResultMapper());
                }

            }catch (ParseException e){
                //TODO Handle Error
                //At present this code is not reachable, as dates are parsed in the Reconcontroller
            }
        }
        return results;
    }

    public void loadResultsData(Timestamp startDate, Timestamp endDate){
        SimpleJdbcCall simpleJdbcCall = new SimpleJdbcCall(getJdbcTemplate());
        simpleJdbcCall.withSchemaName(EISRECON).withCatalogName("recon_pkg").withProcedureName("recon_populate_results");

        simpleJdbcCall.declareParameters(new SqlParameter(START_DATE, OracleTypes.TIMESTAMP));
        simpleJdbcCall.declareParameters(new SqlParameter(END_DATE, OracleTypes.TIMESTAMP));

        MapSqlParameterSource in = new MapSqlParameterSource();
        in.addValue(START_DATE, startDate);
        in.addValue(END_DATE, endDate);

        simpleJdbcCall.execute(in);
    }
}