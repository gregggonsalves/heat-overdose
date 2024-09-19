capture log close
clear all
set more off, perm

* Set directories

cd "<working directory>"
local maindir "<working directory>"

local data "<Analytic data>"

local excessheat "<Heat index data, 1979-1998">
	/*** Note: Calculate mean heat index values 1979-1998, by county and month */

local out "<Output>"
local figout "<Figure output>"

* Log file

log using "`out'\excess_deaths.log", replace

* Load data

use "`data'\analytic_data.dta", clear
tab year, missing

* Obtain coefficient and 95% CI values from regression

*** DRUG OVERDOSES:

*** Main regression
reghdfe rate_drugod_all avg_heatindex [aw=pop_total], ///
	absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)

*** Store main estimate (number deaths per 100k pop in county per degrees Celsius increase) and standard errors
gen beta_od = _b[avg_heatindex]
gen se_od = _se[avg_heatindex]

*** Calculate 95% CI values
gen lowci_od = beta_od - 1.96*se_od
gen highci_od = beta_od + 1.96*se_od


*** ALL DEATHS:

*** Main regression
reghdfe rate_any_death avg_heatindex [aw=pop_total], ///
	absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)

*** Store main estimate (number deaths per 100k pop in county per degrees Celsius increase) and standard errors
gen beta_any = _b[avg_heatindex]

* Transfer to string county variable
rename fips_county fips_county_notstring
rename fips_county_string fips_county

* Merge in mean heat index values 1979-1998, by county and month
sort fips_county month year
merge m:1 fips_county month using "`excessheat'\clean_meanHI_79to98.dta"
drop _merge

* Keep relevant variables
keep fips_county year month pop_total avg_heatindex beta* se* lowci* highci* meanHI_79to98
order fips_county
sum
sort fips_county year month

* Convert to number of deaths in each county per degree Celsius increase using county population

gen num_od_county_beta = pop_total * (beta_od/100000)
gen num_od_county_lowci = pop_total * (lowci_od/100000)
gen num_od_county_highci = pop_total * (highci_od/100000)

gen num_any_county_beta = pop_total * (beta_any/100000)


* Calculate excess degrees Celsius above mean for each county

*** Calculate deviation from mean heat index value within county-month in original sample
gen devfrommeanHI = avg_heatindex-meanHI_79to98

*** Sum total deviations from the mean by county/year
sort fips_county year month 
collapse (sum) devfrommeanHI (mean) num_od* num_any*, by(fips_county year)


* Calculate total excess death estimates for each county/year

gen exdeaths_od_beta = num_od_county_beta*devfrommeanHI
gen exdeaths_od_lowci = num_od_county_lowci*devfrommeanHI
gen exdeaths_od_highci = num_od_county_highci*devfrommeanHI

gen exdeaths_any_beta = num_any_county_beta*devfrommeanHI

* Calculate national excess deaths (coeff and 95% CIs)
preserve
collapse (sum) exdeaths*
list
restore

* Plot national excess deaths by year

preserve

*** Calculate and list values
collapse (sum) exdeaths*, by(year)
list

*** Identify mean values for sample period
egen meanval_beta=mean(exdeaths_od_beta)
egen meanval_lowci=mean(exdeaths_od_lowci) 
egen meanval_highci=mean(exdeaths_od_highci) 
list year meanval*

*** Plot
twoway (rarea exdeaths_od_highci exdeaths_od_lowci year, color(midblue%50) lwidth(none)) ///
	(connected exdeaths_od_beta year, msize(small) lcolor(midblue) mcolor(midblue) lwidth(medium)) ///
	, ///
	yline(0, lcolor(black) lpattern(dash)) ///
	xlabel(1999(1)2020, angle(45)) ///
	xtitle("Year") ytitle("Number of excess deaths") ///
	legend(off)
graph export "`figout'\excess_deaths_byyear.svg", replace
graph export "`figout'\Figure4.tif", replace


restore



log close



