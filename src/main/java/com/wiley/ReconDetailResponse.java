package com.wiley;

import java.util.List;

/**
 * Created by ravuri on 5/26/17.
 */
public class ReconDetailResponse {

    public List<DynamicColumn> columns;
    public List<DynamicRow> data;
    public String startDate;
    public String endDate;
    public String source;
    public String target;
    public String interfaceName;
    public String wricef;

    public boolean errorFlag;
    public String errorMsg;

    public void setErrorMsg(String errorMsg) {
        this.errorMsg = errorMsg;
    }
}
