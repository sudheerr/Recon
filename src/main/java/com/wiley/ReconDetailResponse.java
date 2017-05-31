package com.wiley;

import java.util.List;

/**
 * Created by ravuri on 5/26/17.
 */
public class ReconDetailResponse {

    private List<DynamicColumn> columns;
    private List<DynamicRow> data;
    private String startDate;
    private String endDate;
    private String source;
    private String target;
    private String interfaceName;
    private String wricef;

    private boolean errorFlag;
    private String errorMsg;

    public String getErrorMsg() {
        return errorMsg;
    }

    public void setErrorMsg(String errorMsg) {
        this.errorMsg = errorMsg;
    }

    public boolean isErrorFlag() {
        return errorFlag;
    }

    public void setErrorFlag(boolean errorFlag) {
        this.errorFlag = errorFlag;
    }

    public String getStartDate() {
        return startDate;
    }

    public void setStartDate(String startDate) {
        this.startDate = startDate;
    }

    public String getEndDate() {
        return endDate;
    }

    public void setEndDate(String endDate) {
        this.endDate = endDate;
    }

    public String getSource() {
        return source;
    }

    public void setSource(String source) {
        this.source = source;
    }

    public String getTarget() {
        return target;
    }

    public void setTarget(String target) {
        this.target = target;
    }

    public String getInterfaceName() {
        return interfaceName;
    }

    public void setInterfaceName(String interfaceName) {
        this.interfaceName = interfaceName;
    }

    public String getWricef() {
        return wricef;
    }

    public void setWricef(String wricef) {
        this.wricef = wricef;
    }

    public List<DynamicColumn> getColumns() {
        return columns;
    }

    public void setColumns(List<DynamicColumn> columns) {
        this.columns = columns;
    }

    public List<DynamicRow> getData() {
        return data;
    }

    public void setData(List<DynamicRow> data) {
        this.data = data;
    }
}
