package com.wiley;

import com.wiley.filter.WebAuthenticationFilter;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.boot.web.support.SpringBootServletInitializer;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
// Uncomment when generating war
public class ReconViewApplication extends SpringBootServletInitializer{

	@Override
	protected SpringApplicationBuilder configure(SpringApplicationBuilder builder) {
		return builder.sources(ReconViewApplication.class);
	}

	public static void main(String[] args) {
		SpringApplication.run(ReconViewApplication.class, args);
	}

	@Bean
	public FilterRegistrationBean filterRegistrationBean() {
		FilterRegistrationBean registrationBean = new FilterRegistrationBean();
		WebAuthenticationFilter uploadFilter = new WebAuthenticationFilter();
		registrationBean.setFilter(uploadFilter);
		registrationBean.addUrlPatterns("/webapi/*");

		return registrationBean;
	}
}
//public class ReconViewApplication {
//
//	public static void main(String[] args) {
//		SpringApplication.run(ReconViewApplication.class, args);
//	}
//}