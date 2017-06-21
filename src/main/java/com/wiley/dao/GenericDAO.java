package com.wiley.dao;

import com.wiley.service.UtilService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

/**
 * Created by ravuri on 6/9/17.
 */
@Service
public abstract class GenericDAO {
    private JdbcTemplate jdbcTemplate;
    private UtilService utilService;

    JdbcTemplate getJdbcTemplate() {
        return jdbcTemplate;
    }

    UtilService getUtilService() {
        return utilService;
    }
    @Autowired
    public void setUtilService(UtilService utilService) {
        this.utilService = utilService;
    }

    @Autowired
    public void setJdbcTemplate(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

}
