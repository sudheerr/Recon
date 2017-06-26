package com.wiley.filter;

import com.wiley.ApplicationConstants;
import com.wiley.user.UserDTO;
import com.wiley.util.ldap.ContactDTO;
import com.wiley.util.ldap.LDAPService;
import com.wiley.util.ldap.WileyLDAPServiceImpl;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.naming.NamingException;
import javax.servlet.*;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Map;


/*
 * This filter set the user details from LDAP and sets into httpsession.
 */
public class WebAuthenticationFilter implements Filter {

    private static final Logger LOGGER = LoggerFactory
            .getLogger(WebAuthenticationFilter.class);

    private Map<String, String> headerMap = new HashMap<>();

    public void doFilter(ServletRequest request, ServletResponse response,
                         FilterChain chain) throws IOException, ServletException {

        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse resp = (HttpServletResponse) response;

        HttpSession httpSession = req.getSession();

        UserDTO userDTO = (UserDTO) httpSession.getAttribute(ApplicationConstants.USER_DTO);

        if(userDTO == null){
            ContactDTO ldapData;
            try {
                ldapData = getLDAPData(req, resp);
                LOGGER.info("LDAP DATA " + ldapData);
                if (ldapData != null) {
                    LOGGER.info("SSO Information is available");
                    userDTO = new UserDTO();
                    userDTO.setUid(ldapData.getUid());
                    userDTO.setUserName(ldapData.getName());
                    userDTO.setEmail(ldapData.getMail());
                    httpSession.setAttribute(ApplicationConstants.USER_DTO, userDTO);
//                }else{
//                    LOGGER.info("LDAP not available");
//                    userDTO = new UserDTO();
//                    userDTO.setUid("Admin");
//                    userDTO.setUserName("Admin");
//                    httpSession.setAttribute(ApplicationConstants.USER_DTO, userDTO);
                }
            } catch (IOException | NamingException e) {
                LOGGER.error(e.getMessage());
            }
        }

        chain.doFilter(req, resp);
    }

    private ContactDTO getLDAPData(HttpServletRequest req,
                                   HttpServletResponse resp) throws IOException, NamingException {

        if (isHeaderPresent(req)) {
            LOGGER.info(" user_mail is present in the HttpServletRequest Header ");
        } else {
            return null;
        }

        LDAPService ldapService = new WileyLDAPServiceImpl();
        return ldapService.getContactDetailsByMailId(headerMap
                .get(ApplicationConstants.USER_MAIL));

    }

    private boolean isHeaderPresent(HttpServletRequest req) {

        String headerName;
        String headerValue;
        int i = 0;
        boolean bAuth = false;

        @SuppressWarnings("rawtypes")
        Enumeration enumeration = req.getHeaderNames();

        while (enumeration.hasMoreElements()) {
            headerName = (String) enumeration.nextElement();
            LOGGER.info("HeaderName : " + headerName + " and value :"
                    + req.getHeader(headerName));

            if (headerName != null) {
                if (("user_dn".equalsIgnoreCase(headerName.trim()))) {

                    headerValue = req.getHeader(headerName);
                    LOGGER.info(" user_dn: [" + headerValue + "]");
                    i++;
                    bAuth = true;
                    headerMap.put(headerName, headerValue);
                }
                if (("user_ip".equalsIgnoreCase(headerName))) {
                    headerValue = req.getHeader(headerName);
                    i++;
                    headerMap.put(headerName, headerValue);
                }
                if (("user_mail".equalsIgnoreCase(headerName))) {
                    headerValue = req.getHeader(headerName);
                    LOGGER.info("user_mail: [" + headerValue + "]");
                    i++;
                    headerMap.put("user_mail", headerValue);
                }
                if (i == 3) {
                    // come out after capturing user_dn, user_ip, user_mail
                    break;
                }
            } else {
                break;
            }

        }
        LOGGER.info(" bAuth : " + bAuth);
        return bAuth;
    }

    @Override
    public void init(FilterConfig arg0) throws ServletException {
        LOGGER.info(" WebAuthenticationFilter is initialised ................");
    }

    @Override
    public void destroy() {
        LOGGER.info(" WebAuthenticationFilter destroyed ................");
    }
}
