package com.wiley;


import com.wiley.service.*;
import com.wiley.user.UserDTO;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.sql.Timestamp;
import java.text.ParseException;
import java.util.List;

import static com.wiley.ApplicationConstants.ORDER_WRICEFS;
import static com.wiley.ApplicationConstants.SDF_YYYYMMDD;

@RestController
@RequestMapping("/webapi")
public class ReconController {
    private static final Logger LOGGER = LoggerFactory.getLogger(ReconController.class);

    private ReconService reconService;

    private ProductsService productsService;

    private OrderService orderService;

    private PDMSOrderService pdmsOrderService;

    private UtilService utilService;

    public UtilService getUtilService() {
        return utilService;
    }
    @Autowired
    public void setUtilService(UtilService utilService) {
        this.utilService = utilService;
    }

    @Autowired
    private ReconController(ReconService reconService, ProductsService productsService, OrderService orderService,  PDMSOrderService pdmsOrderService) {
        this.reconService = reconService;
        this.productsService = productsService;
        this.orderService = orderService;
        this.pdmsOrderService = pdmsOrderService;
    }

    @RequestMapping(value = "/user", method = RequestMethod.GET)
    @ResponseBody
    public UserDTO getUser() {
        //TODO
        return null;
    }

    /**
     * @param startDate YYYYMMDD
     * @param endDate   YYYYMMDD
     * @return json (list of results)
     */
    @RequestMapping(value = "/results/startDate/{startDate}/endDate/{endDate}", method = RequestMethod.GET)
    @ResponseBody
    public List<ReconResult> getResults(@PathVariable("startDate") String startDate,
                                        @PathVariable("endDate") String endDate) {

        //TODO Send Error Details on Exception
        try {
            SDF_YYYYMMDD.parse(startDate);
            SDF_YYYYMMDD.parse(endDate);
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
                                          @PathVariable("endDate") String endDate) {
        LOGGER.info("Input Parameters. WRICEF: " + wricef + ", errorSrc: " + errorsSrc + ", startDate: " + startDate + ", endDate: " + endDate);

        Timestamp sDate, eDate;
        ReconDetailResponse response = new ReconDetailResponse();

        try {
            sDate = utilService.getStartofDay(startDate);
            eDate = utilService.getEndofDay(endDate);
        } catch (ParseException e) {
            LOGGER.error(e.getMessage());

            response.setErrorFlag(true);
            response.setErrorMsg("Start and End Date not properly formatted. Proper format: YYYYMMDD.");
            return response;
        }
//        try {
            if (wricef.equals("I0203.1")) {
                return productsService.getProductDetails(sDate, eDate, errorsSrc);
            } else if (wricef.equals("I0343")) {
                return pdmsOrderService.getOrderDetails(sDate, eDate, errorsSrc);
            } else if (ORDER_WRICEFS.contains(wricef)) {
                return orderService.getOrderDetails(sDate, eDate, errorsSrc, wricef);
            } else {
                response.setErrorFlag(true);
                response.setErrorMsg("Unsupported WRICEF : " + wricef);
                return response;
            }
//        } catch (SQLException e) {
//            LOGGER.error(e.getMessage());
//            response.setErrorFlag(true);
//            response.setErrorMsg("Internal Exception Occurred while fetching the details.");
//            return response;
//        }
    }
}
