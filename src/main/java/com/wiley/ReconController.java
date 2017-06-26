package com.wiley;


import com.wiley.dao.OrdersDAO;
//import com.wiley.dao.PDMSOrdersDAO;
import com.wiley.dao.ProductsDAO;
import com.wiley.dao.ReconDAO;
import com.wiley.model.ReconDetailResponse;
import com.wiley.model.ReconResult;
import com.wiley.service.UtilService;
import com.wiley.user.UserDTO;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;
import java.sql.Timestamp;
import java.text.ParseException;
import java.util.Date;
import java.util.List;
import java.util.Map;

import static com.wiley.ApplicationConstants.ORDER_WRICEFS;
import static com.wiley.ApplicationConstants.SDF_YYYYMMDD;

@RestController
@RequestMapping("/webapi")
public class ReconController {
    private static final Logger LOGGER = LoggerFactory.getLogger(ReconController.class);

    private ReconDAO reconDAO;

    private ProductsDAO productsDAO;

    private OrdersDAO ordersDAO;

    //private PDMSOrdersDAO pdmsOrdersDAO;

    private UtilService utilService;

    @Autowired
    public void setReconDAO(ReconDAO reconDAO) {
        this.reconDAO = reconDAO;
    }

    @Autowired
    public void setProductsDAO(ProductsDAO productsDAO) {
        this.productsDAO = productsDAO;
    }

    @Autowired
    public void setOrdersDAO(OrdersDAO ordersDAO) {
        this.ordersDAO = ordersDAO;
    }

//    @Autowired
//    public void setPdmsOrdersDAO(PDMSOrdersDAO pdmsOrdersDAO) {
//        this.pdmsOrdersDAO = pdmsOrdersDAO;
//    }

    @Autowired
    public void setUtilService(UtilService utilService) {
        this.utilService = utilService;
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
        return reconDAO.fetchResults(startDate, endDate, true);
    }

    @RequestMapping(value = "/orderResults/startDate/{startDate}/endDate/{endDate}", method = RequestMethod.GET)
    @ResponseBody
    public List<ReconResult> getOrderResults(@PathVariable("startDate") String startDate,
                                        @PathVariable("endDate") String endDate) {
        return reconDAO.fetchResults(startDate, endDate, false);
    }

    @RequestMapping(value = "/details/{wricef}/{errorsSrc}/startDate/{startDate}/endDate/{endDate}", method = RequestMethod.GET)
    @ResponseBody
    public ReconDetailResponse getDetails(@PathVariable("wricef") String wricef,
                                          @PathVariable("errorsSrc") String errorsSrc,
                                          @PathVariable("startDate") String startDate,
                                          @PathVariable("endDate") String endDate,
                                          String currencyCode) {
        LOGGER.info("Input Parameters. WRICEF: " + wricef + ", errorSrc: " + errorsSrc + ", startDate: " + startDate + ", endDate: " + endDate);

        Timestamp sDate, eDate;
        ReconDetailResponse response = new ReconDetailResponse();
        currencyCode = (currencyCode==null || currencyCode.length()==0)?"ALL":currencyCode;
        try {
            sDate = utilService.getStartofDay(startDate);
            eDate = utilService.getEndofDay(endDate);
        } catch (ParseException e) {
            LOGGER.error(e.getMessage());

            response.setErrorFlag( true);
            response.setErrorMsg("Start and End Date not properly formatted. Proper format: YYYYMMDD.");
            return response;
        }

        if (wricef.equals("I0203.1")) {
            return productsDAO.getProductDetails(sDate, eDate, errorsSrc);
        }
        /*else if (wricef.equals("I0343")) {
            return pdmsOrdersDAO.getOrderDetails(sDate, eDate, errorsSrc);
        }*/
        else if (ORDER_WRICEFS.contains(wricef)) {
            return ordersDAO.getOrderDetails(sDate, eDate, errorsSrc, wricef, currencyCode);
        } else {
            response.setErrorFlag(true);
            response.setErrorMsg("Unsupported WRICEF : " + wricef);
            return response;
        }
    }

    @RequestMapping(value = "/details/{wricef}/{errorsSrc}/startDate/{startDate}/endDate/{endDate}/currencyCode/{currencyCode}", method = RequestMethod.GET)
    @ResponseBody
    public ReconDetailResponse getOrderDetails(@PathVariable("wricef") String wricef,
                                          @PathVariable("errorsSrc") String errorsSrc,
                                          @PathVariable("startDate") String startDate,
                                          @PathVariable("endDate") String endDate,
                                          @PathVariable("currencyCode") String currencyCode
    ) {
        return getDetails(wricef, errorsSrc, startDate, endDate, currencyCode);
    }

    @RequestMapping(value = "/user", method = RequestMethod.GET)
    @ResponseBody
    public UserDTO getUserDetails(HttpServletRequest request){
        HttpSession session = request.getSession();
        return  (UserDTO) session.getAttribute(ApplicationConstants.USER_DTO);
    }
}