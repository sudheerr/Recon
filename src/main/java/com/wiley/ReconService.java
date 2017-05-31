package com.wiley;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ReconService {

    @Autowired
    private JdbcTemplate jdbcTemplate;
    private static String reconResults = "select id, wricef, source, target, start_date, end_date, service_name, interface_name, source_total, source_success, source_errors," +
            " eis_total, eis_success, eis_errors, sap_total, sap_success, sap_errors, flow_direction from recon_results";

    private static String FETCH_RESULTS = "SELECT * FROM (select id, wricef, source, target, start_date, end_date, service_name, interface_name, source_total, source_success, source_errors," +
            " eis_total, eis_success, eis_errors, sap_total, sap_success, sap_errors, flow_direction,  RANK() OVER (PARTITION BY WRICEF ORDER BY ID DESC) RANK  from recon_results  " +
            " where START_DATE =TO_DATE(?,'YYYYMMDD') and END_DATE = TO_DATE(?,'YYYYMMDD'))  WHERE RANK=1";


    public List<ReconResult> fetchResults(String startDate, String endDate){

        Object[] args = new Object[2];
        args[0]=startDate;
        args[1]= endDate;

        List<ReconResult> results = jdbcTemplate.query(FETCH_RESULTS, args, new ResultsMapper());

//      List<ReconResult> results = jdbcTemplate.query(reconResults, new ResultsMapper());

        return results;
    }
}
