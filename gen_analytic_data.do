capture log close
clear all
set more off, perm

* Set directories

cd "<working directory>"

local cdcdata "<NCHS restricted mortality data>"
local popdata "<SEER population data>"

local heatindexdata "<Heat index data>"

local prismdata "<PRISM heat data">
local weatherdata "<NOAA heat data">
local faqsddata "<FAQSD pollution data"

local hetdata "<Heterogeneity analysis data>"
	/*** Note: includes 1) binary values for above/below median household income
						2) binary values for above/below median SVI
						3) binary values for urban-suburban-rural classifications */

local xwalkdata "<cleaned crosswalk linking Census division and state codes>"
	/*** Note: available https://www.census.gov/geographies/reference-files/2014/demo/popest/2014-geocodes-all.html
				(originally downloaded 10/31/2023) */

local temp "<temporary files>"
local out "<output files>"

* Log file

log using "`out'\gen_analytic_data.log", replace


* Load data
use "`cdcdata'\clean_cdc_mort_county_monthly_extremetempOD.dta", clear

* Drop AK and HI
drop if substr(fips_county,1,2)=="02"
drop if substr(fips_county,1,2)=="15"

* Make FIPS county codes consistent across data sets/over time (changes occured over time)
* Source: https://www.ddorn.net/data/FIPS_County_Code_Changes.pdf

*** 2013: Bedford City, VA = 51515 joins Bedford County, VA = 51019
tab fips_county if fips_county=="51019"|fips_county=="51515", missing
replace fips_county="51019" if fips_county=="51515"
collapse (sum) any_death drugod*, by(fips_county year month)
tab fips_county if fips_county=="51019"|fips_county=="51515", missing

*** 1997: : Yellowstone National Park territory, MT (FIPS 30113) is merged into Gallatin (FIPS 30031) and Park (FIPS 30067) counties. Assign to Gallatin (larger population).
tab fips_county if fips_county=="30031"|fips_county=="30113"|fips_county=="30067", missing
replace fips_county="30031" if fips_county=="30113"
collapse (sum) any_death drugod*, by(fips_county year month)
tab fips_county if fips_county=="30031"|fips_county=="30113"|fips_county=="30067", missing

*** 2001: The independent city of Clifton Forge, VA (FIPS 51560) merges into Alleghany county (FIPS 51005). 
tab fips_county if fips_county=="51560"|fips_county=="51005"
replace fips_county="51005" if fips_county=="51560"
collapse (sum) any_death drugod*, by(fips_county year month)
tab fips_county if fips_county=="51560"|fips_county=="51005"

*** 1997: Dade county, FL (FIPS 12025) is renamed as Miami-Dade county, FL (FIPS 12086).
replace fips_county="12086" if fips_county=="12025"


* Create a "base" file of counties/years (since not a death in all months)

preserve

*** Keep universe of counties/years
****> Identify missing years and counties
keep fips_county year
gen monthcount=1
collapse (sum) monthcount, by(fips_county year)
sort fips_county year
gen n=1
by fips_county: egen yearcount=total(n)
*****> Counties that are missing at least one year:
*****> NOTE: FIPS county 08014: 2003-2020 only (created from other counties)
list if yearcount<22
*****> County/Years that are missing months:
tab monthcount, missing

*** Generate base file based on counties
keep fips_county
gen n=1
collapse (mean) n, by(fips_county)
drop n

*** Expand for years 1999-2020
expand 22
gen year=.
sort fips_county
local y=1999
forvalues n=1/22 {
	by fips_county: replace year=`y' if _n==`n'
	local y=`y'+1
}
tab year, missing

*** Expand for months 1-12
expand 12
gen month=.
sort fips_county year
local m=1
forvalues n=1/12 {
	by fips_county year: replace month=`m' if _n==`n'
	local m=`m'+1
}
tab month, missing

*** Check balance
/* Note: strongly balanced (commented out because destrings fips_county)
gen monthyear=ym(year,month)
format monthyear %tm
destring fips_county, replace
xtset fips_county monthyear
*/

*** Drop FIPS 08014 before 2003
drop if fips_county=="08014"&year<2003

*** Output base file
sort fips_county year month
save "`temp'\county_basefile.dta", replace

restore


* Link OD data to basefile
sort fips_county year month
merge 1:1 fips_county year month using "`temp'\county_basefile.dta"
*** Check balance
/* Note: strongly balanced after dropping 1 CO county (commented out because destrings fips_county)
sort fips_county year month
tab year if fips_county=="08014"
drop if fips_county=="08014"
gen monthyear=ym(year,month)
format monthyear %tm
destring fips_county, replace
xtset fips_county monthyear
*/


* Replace mortality data = 0 if not in death data, but basefile available
sort fips_county year month
foreach var of varlist any_death drugod* {
	replace `var'=0 if `var'==.&_merge==2
}
drop _merge


* Link to SEER population data
sort fips_county year month
merge m:1 fips_county year using "`popdata'\clean_seer_pop_data.dta"
drop _merge


* Calculate outcome as rates per 100,000 population
*** Shorten some names
foreach outcomevar in all opioids psychostim cocaine {
	rename drugod_`outcomevar'_unintentional drugod_`outcomevar'_unint
	rename drugod_`outcomevar'_suicide drugod_`outcomevar'_suic
	rename drugod_`outcomevar'_undetermined drugod_`outcomevar'_undet
}
*** Calculate rates for total population denominator
foreach var of varlist any_death drugod* {
		gen rate_`var'=(`var'/pop_total)*100000
}
drop rate_drugod_dem*
*** Calculate rates for demographic-specific population denominators
*** Impute 0 if count & population = 0
foreach dem in male female ///
	age0to29 age30to59 age60plus ///
	nhwhite nhblack hisp {
		gen rate_drugod_dem_`dem'=(drugod_dem_`dem'/pop_`dem')*100000
		replace rate_drugod_dem_`dem'=0 if drugod_dem_`dem'==0&pop_`dem'==0& ///
			rate_drugod_dem_`dem'==.
}

		

* Label outcome variables
foreach outcomevar in all opioids psychostim cocaine {
	label var rate_drugod_`outcomevar' "Deaths per 100,000 pop"
	label var rate_drugod_`outcomevar'_unint "Deaths per 100,000 pop"
	label var rate_drugod_`outcomevar'_suic "Deaths per 100,000 pop"
	label var rate_drugod_`outcomevar'_undet "Deaths per 100,000 pop"
}


* Merge heat index data (main exposure)
merge 1:1 fips_county year month using "`heatindexdata'\clean_heatindex.dta"
tab month _merge, missing
drop _merge


* Merge PRISM data (for robustness checks)
merge 1:1 fips_county year month using "`prismdata'\clean_PRISM_data.dta"
tab _merge, missing
drop _merge


* Merge additional NOAA weather data (for robustness checks)

*** Average temperature
merge 1:1 fips_county year month using "`weatherdata'\clean_avgtemp.dta"
tab _merge, missing
drop _merge

*** Maximum temperature
merge 1:1 fips_county year month using "`weatherdata'\clean_maxtemp.dta"
tab _merge, missing
drop _merge

*** Minimum temperature
merge 1:1 fips_county year month using "`weatherdata'\clean_mintemp.dta"
tab _merge, missing
drop _merge

*** Precipitation
merge 1:1 fips_county year month using "`weatherdata'\clean_prec.dta"
tab _merge, missing
drop _merge


* Merge pollution data (for robustness checks) (note - only 2002+ available)
merge 1:1 fips_county year month using "`faqsddata'\clean_FAQSD_airquality.dta"
tab _merge, missing
tab year _merge, missing
drop _merge

* Merge division crosswalk
gen fipsst=substr(fips_county,1,2)
merge m:1 fipsst using "`xwalkdata'\clean_xwalk_state_division.dta"
drop _merge
drop fipsst

* Merge county-level classifier vars (for heterogeneity analysis)

*** Median Household Income (Above/below median)
merge m:1 fips_county using "`hetdata'\clean_med_hhi.dta"
tab _merge, missing
drop _merge

*** SVI  (Above/below median)
merge m:1 fips_county using "`hetdata'\clean_cdc_svi.dta"
tab _merge, missing
drop _merge

*** Urban-Suburban-Rural classification
merge m:1 fips_county using "`hetdata'\clean_nchs_urban_rural.dta"
tab _merge, missing
drop _merge

* Merge in lagged heat index data for robustness tests
forvalues leagladperiod=1/1 {

	*** Set aside original var names
	rename year origyear
	rename month origmonth
	rename avg_heatindex orig_avg_heatindex

	*** Lag before original year/month

	***** Create variables
	gen yearlag=origyear
	gen monthlag=origmonth-`leagladperiod'
	replace yearlag=origyear-1 if monthlag<=0
	replace monthlag=12+monthlag if monthlag<=0

	***** Merge in lagged month
	rename yearlag year
	rename monthlag month
	merge 1:1 fips_county year month using "`heatindexdata'\clean_heatindex.dta"
	drop if _merge==2
	drop _merge
	rename year yearlag
	rename month monthlag
	rename avg_heatindex avg_heatindex_lag`leagladperiod'

	*** Rename original variables
	rename origyear year
	rename origmonth month
	rename orig_avg_heatindex avg_heatindex 
	drop yearlag monthlag

}


* Create variables for fixed effects
gen fipscntybymonth=fips_county+"00"+string(month)
gen state=substr(fips_county,1,2)
gen statebyyear=state+"0"+string(year)
gen yearmonth=string(year)+"0"+string(month)

destring fipscntybymonth, replace
destring statebyyear, replace
gen fips_county_string=fips_county
destring fips_county, replace
destring yearmonth, replace
destring state, replace

* Create Z scores within county/month
sort fips_county month year
by fips_county month: egen Zavg_heatindex=std(avg_heatindex)
by fips_county month: egen Zavgtemp=std(avgtemp)
by fips_county month: egen Ztmean=std(tmean)

* Shorten some variable names
rename rate_drugod_natandsemisyn_op rate_drugod_natsemisyn
rename rate_drugod_synthetic_op rate_drugod_synth
rename rate_drugod_only_psychostim rate_drugod_only_psy
rename rate_drugodplacebo_canc_mel rate_placcanc_mel
rename rate_drugodplacebo_canc_breast rate_placcanc_breast
rename rate_drugodplacebo_canc_colon rate_placcanc_colon

* Set up dummy for pre vs post 2013
gen year2013plus=.
replace year2013plus=0 if year<2013
replace year2013plus=1 if year>=2013
tab year year2013plus, missing

* Gen lagged drug od rates and spring OD rates (for quasi-lag dependent model robustness testing)
foreach outcome in rate_drugod_all {
	sort fips_county year month
	by fips_county: gen lag_`outcome'=`outcome'[_n-1]
}
foreach outcome in rate_drugod_all {
	sort fips_county year month
	gen spring_`outcome'=`outcome' if month==3|month==4|month==5
	by fips_county year: egen totsp_`outcome'=total(spring_`outcome')
	drop spring_*
}

* Convert degF to degC
sum avg_heatindex avgtemp maxtemp mintemp
foreach var in avg_heatindex avgtemp maxtemp mintemp {
	gen degF_`var'=`var'
	replace `var'=(degF_`var'-32)*(5/9)
	label var `var' "Degrees Celsius"
	
}
sum avg_heatindex avgtemp maxtemp mintemp degF*

* Drop irrelevant exposures
drop max_ozone max_pm25

* Output all months (for robustness checks)
sort fips_county year month
save "`out'\analytic_data_ALLMONTHS.dta", replace

* Keep hottest months
keep if month==6|month==7|month==8|month==9

* Output
sort fips_county year month
save "`out'\analytic_data.dta", replace


* Check balance
sort fips_county year month
tab year if fips_county==8014
drop if fips_county==8014 /* Drop one CO county that isn't balanced */
gen monthyear=ym(year,month)
format monthyear %tm
xtset fips_county monthyear


log close
