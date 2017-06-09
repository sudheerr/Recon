package com.wiley.service;

import com.wiley.ReconDetailResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Service;

/**
 * Created by ravuri on 6/9/17.
 */
@Service
public abstract class GenericDAO {
    private JdbcTemplate jdbcTemplate;
    private UtilService utilService;

    private SimpleJdbcCall simpleJdbcCall;

    public JdbcTemplate getJdbcTemplate() {
        return jdbcTemplate;
    }

    @Autowired
    public void setJdbcTemplate(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public UtilService getUtilService() {
        return utilService;
    }
    @Autowired
    public void setUtilService(UtilService utilService) {
        this.utilService = utilService;
    }

    public abstract ReconDetailResponse getDetails();

}
