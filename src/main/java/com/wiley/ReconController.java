package com.wiley;


import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.sql.Date;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;

import static com.wiley.ApplicationConstants.sdf_other;

@RestController
@RequestMapping("/webapi")
public class ReconController {
    private static final Logger LOGGER = LoggerFactory.getLogger(ReconController.class);

    ReconService reconService;

    ProductsService productsService;

    @Autowired
    public ReconController(ReconService reconService, ProductsService productsService) {
        this.reconService = reconService;
        this.productsService = productsService;
    }

    @RequestMapping(value = "/user", method = RequestMethod.GET)
    @ResponseBody
    public UserDTO getUser() {

        return null;
    }

    /**
     * @param startDate YYYYMMDD
     * @param endDate   YYYYMMDD
     * @return
     */
    @RequestMapping(value = "/results/startDate/{startDate}/endDate/{endDate}", method = RequestMethod.GET)
    @ResponseBody
    public List<ReconResult> getResults(@PathVariable("startDate") String startDate,
                                        @PathVariable("endDate") String endDate) {

        //TODO Send Error Details on Exception
        try {
            sdf_other.parse(startDate);
            sdf_other.parse(endDate);
        } catch (ParseException e) {
            e.printStackTrace();
            return null;
        }

        return reconService.fetchResults(startDate, endDate);
    }

    @RequestMapping(value = "/details/{wricef}/{errorsSrc}/startDate/{startDate}/endDate/{endDate}", method = RequestMethod.GET)
    @ResponseBody
    public ReconDetailResponse getDetails(@PathVariable("wricef") String wricef,
                                           @PathVariable("errorsSrc") String errorsSrc,
                                           @PathVariable("startDate") String startDate,
                                           @PathVariable("endDate") String endDate){
        LOGGER.info("Input Parameters. WRICEF: "+wricef+", errorSrc: "+errorsSrc+", startDate: "+startDate+", endDate: "+endDate);

        Timestamp sDate, eDate;
        ReconDetailResponse response = new ReconDetailResponse();

        try {
            sDate = new Timestamp(sdf_other.parse(startDate).getTime());

            //Fetching records till end of day.
            Calendar cal = Calendar.getInstance();
            cal.setTime(sdf_other.parse(endDate));
            cal.set(Calendar.HOUR_OF_DAY,cal.getMaximum(Calendar.HOUR_OF_DAY));
            cal.set(Calendar.MINUTE,cal.getMaximum(Calendar.MINUTE));
            cal.set(Calendar.SECOND,cal.getMaximum(Calendar.SECOND));
            cal.set(Calendar.MILLISECOND,cal.getMaximum(Calendar.MILLISECOND));

            eDate = new Timestamp(cal.getTimeInMillis());

        } catch (ParseException e) {
            LOGGER.error(e.getMessage());

            response.setErrorFlag(true);
            response.setErrorMsg("Start and End Date not properly formatted. Proper format: YYYYMMDD.");
            return response;
        }

        if(wricef.equals("I0203.1")){
            try {
                return productsService.getProductDetails(sDate, eDate, errorsSrc);
            } catch (SQLException e) {
                LOGGER.error(e.getMessage());

                response.setErrorFlag(true);
                response.setErrorMsg("Internal Exception Occurred while fetching the details.");
                return response;
            }
        }else{
            response.setErrorFlag(true);
            response.setErrorMsg("Unsupported WRICEF : "+wricef);
            return response;
        }
    }
}
