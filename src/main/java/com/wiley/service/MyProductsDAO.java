package com.wiley.service;

import com.wiley.ReconDetailResponse;

/**
 * Created by ravuri on 6/9/17.
 */
public class MyProductsDAO extends GenericDAO {

    @Override
    public ReconDetailResponse getDetails() {

        getJdbcTemplate();
        return null;
    }
}
