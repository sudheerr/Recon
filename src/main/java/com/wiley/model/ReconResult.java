package com.wiley.model;

/**
 * Created by sravuri on 5/10/17.
 */
public class ReconResult {
    private int id;
    private String wricef;
    private String source;
    private String target;
    private String serviceName;
    private String interfaceName;
    private String startDate;
    private String endDate;
    private String flowDirection;
    private String currency;
    private int srcCount;
    private int srcTotal;

    private int srcSuccess;
    private int srcFailure;
    private int eisTotal;
    private int eisSuccess;
    private int eisFailure;
    private int tgtTotal;
    private int tgtSuccess;
    private int tgtFailure;
    private int eisMissing;
    private int tgtMissing;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;

        ReconResult that = (ReconResult) o;
        return id == that.id;
    }

    @Override
    public int hashCode() {
        return id;
    }

    @Override
    public String toString() {
        return "ReconResult{" +
                "id=" + id +
                ", wricef='" + wricef + '\'' +
                ", source='" + source + '\'' +
                ", target='" + target + '\'' +
                ", serviceName='" + serviceName + '\'' +
                ", srcTotal=" + srcTotal +
                ", srcSuccess=" + srcSuccess +
                ", srcFailure=" + srcFailure +
                ", eisTotal=" + eisTotal +
                ", eisSuccess=" + eisSuccess +
                ", eisFailure=" + eisFailure +
                ", sapTotal=" + tgtTotal +
                ", sapSuccess=" + tgtSuccess +
                ", sapFailure=" + tgtFailure +
                ", flowDirection=" + flowDirection +
                '}';
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getWricef() {
        return wricef;
    }

    public void setWricef(String wricef) {
        this.wricef = wricef;
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

    public String getServiceName() {
        return serviceName;
    }

    public void setServiceName(String serviceName) {
        this.serviceName = serviceName;
    }

    public String getCurrency() {
        return currency;
    }

    public void setCurrency(String currency) {
        this.currency = currency;
    }

    public int getSrcCount() {
        return srcCount;
    }

    public void setSrcCount(int srcCount) {
        this.srcCount = srcCount;
    }

    public int getSrcTotal() {
        return srcTotal;
    }

    public void setSrcTotal(int srcTotal) {
        this.srcTotal = srcTotal;
    }

    public int getSrcSuccess() {
        return srcSuccess;
    }

    public void setSrcSuccess(int srcSuccess) {
        this.srcSuccess = srcSuccess;
    }

    public int getSrcFailure() {
        return srcFailure;
    }

    public void setSrcFailure(int srcFailure) {
        this.srcFailure = srcFailure;
    }

    public int getEisTotal() {
        return eisTotal;
    }

    public void setEisTotal(int eisTotal) {
        this.eisTotal = eisTotal;
    }

    public int getEisSuccess() {
        return eisSuccess;
    }

    public void setEisSuccess(int eisSuccess) {
        this.eisSuccess = eisSuccess;
    }

    public int getEisFailure() {
        return eisFailure;
    }

    public void setEisFailure(int eisFailure) {
        this.eisFailure = eisFailure;
    }

    public int getTgtTotal() {
        return tgtTotal;
    }

    public void setTgtTotal(int sapTotal) {
        this.tgtTotal = sapTotal;
    }

    public int getTgtSuccess() {
        return tgtSuccess;
    }

    public void setTgtSuccess(int sapSuccess) {
        this.tgtSuccess = sapSuccess;
    }

    public int getTgtFailure() {
        return tgtFailure;
    }

    public void setTgtFailure(int sapFailure) {
        this.tgtFailure = sapFailure;
    }

    public String getFlowDirection() {
        return flowDirection;
    }

    public void setFlowDirection(String flowDirection) {
        this.flowDirection = flowDirection;
    }
    public String getInterfaceName() {
        return interfaceName;
    }

    public void setInterfaceName(String interfaceName) {
        this.interfaceName = interfaceName;
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

	public int getEisMissing() {
		return eisMissing;
	}

	public void setEisMissing(int eisMissing) {
		this.eisMissing = eisMissing;
	}

	public int getTgtMissing() {
		return tgtMissing;
	}

	public void setTgtMissing(int tgtMissing) {
		this.tgtMissing = tgtMissing;
	}
    

}
