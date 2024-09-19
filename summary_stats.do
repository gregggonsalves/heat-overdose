capture log close
clear all
set more off, perm

* Set directories

cd "<working directory>"

local data "<Analytic data>"
local temp "<Temporary files>"

local out "<Output>"
local figout "<Figure output>"

* Log file

log using "`out'\summary_stats.log", replace

********************************* Analytic sample summary characteristics

* Load data

use "`data'\analytic_data.dta", clear
tab year, missing

* FIGURE: Average temperature in analytic sample over time

preserve

collapse (mean) avg_heatindex [aw=pop_total], by(year)

label var avg_heatindex "degrees C"
label var year "Year"

twoway (connected avg_heatindex year) ///
	(lfit avg_heatindex year), ///
	legend(ring(0) pos(5))
graph export "`figout'\appendix_heatindex_byyear.svg", replace

restore


* Nearly-balanced panel observation numbers

display "Number of observations:"
count

preserve
gen n=1
collapse (mean) n, by(fips_county)
display "Number of counties:"
count
restore

preserve
gen n=1
collapse (mean) n, by(year)
display "Number of years:"
count
restore

preserve
gen n=1
collapse (mean) n, by(month)
display "Number of months:"
count
restore



********************************* Analytic sample-level calculations

* Load data

use "`data'\analytic_data.dta", clear
tab year, missing

* Define variable lists into tables (main and appendix)

*** Exposure
local varlist_exp avg_heatindex ///
	tmean ppt ///
	avgtemp maxtemp mintemp prec
	
local varlist_poll mean_ozone mean_pm25

*** Outcomes
local varlist_outcomes rate_drugod_all ///
	///
	rate_drugod_opioids rate_drugod_natsemisyn rate_drugod_heroin rate_drugod_synth ///
	rate_drugod_cocaine rate_drugod_psychostim ///
	///
	rate_drugod_only_opioids rate_drugod_only_cocaine rate_drugod_only_psy ///
	rate_drugod_comb_op_coc rate_drugod_comb_op_psy rate_drugod_comb_coc_psy rate_drugod_comb_all ///
	///
	rate_drugod_dem_male rate_drugod_dem_female ///
	rate_drugod_dem_age0to29 rate_drugod_dem_age30to59 rate_drugod_dem_age60plus ///
	rate_drugod_dem_nhblack rate_drugod_dem_hisp rate_drugod_dem_nhwhite ///
	///
	rate_any_death ///
	rate_drugodoth_natheat rate_drugodoth_dehyd ///
	rate_drugodoth_cardiovasc rate_drugodoth_clrd ///
	rate_drugoddesp_suicide rate_drugoddesp_asslt ///
	///
	rate_placcanc_mel rate_placcanc_breast rate_placcanc_colon

* Label all variables

*** Exposure
label var avg_heatindex "Avg. max. heat index (degC)"
label var tmean "Avg. temperature PL/PRISM (degC)"
label var ppt "Total precipitation PL/PRISM (cm)"
label var avgtemp "Avg. temperature NOAA (degC)"
label var maxtemp "Max. temperature NOAA (degC)"
label var mintemp "Min. temperature NOAA (degC)"
label var prec "Total precipitation NOAA (inches)"
label var mean_ozone "Avg. max. ozone (ppb)"
label var mean_pm25 "Avg. PM 2.5 (ug/m3)"

*** Outcomes
label var rate_drugod_all "All overdoses"
label var rate_drugod_opioids "Any opioid"
label var rate_drugod_natsemisyn "Natural and semisynthetic opioids"
label var rate_drugod_heroin "Heroin"
label var rate_drugod_synth "Synthetic opioids"
label var rate_drugod_cocaine "Cocaine"
label var rate_drugod_psychostim "Psychostimulants"
label var rate_drugod_only_opioids "Opioids only"
label var rate_drugod_only_cocaine "Cocaine only"
label var rate_drugod_only_psy "Psychostimulants only"
label var rate_drugod_comb_op_coc "Opioids + Cocaine"
label var rate_drugod_comb_op_psy "Opioids + Psychostimulants"
label var rate_drugod_comb_coc_psy "Cocaine + Psychostimulants"
label var rate_drugod_comb_all "Opioids + Cocaine + Psychostimulants"
label var rate_drugod_dem_male "Male"
label var rate_drugod_dem_female "Female"
label var rate_drugod_dem_age0to29 "Aged 0 to 29"
label var rate_drugod_dem_age30to59 "Aged 30 to 59"
label var rate_drugod_dem_age60plus "Aged 60 and older"
label var rate_drugod_dem_nhblack "Black (non-Hispanic)"
label var rate_drugod_dem_hisp "Hispanic (any race)"
label var rate_drugod_dem_nhwhite "White (non-Hispanic)"	
label var rate_any_death "All-cause mortality"
label var rate_drugodoth_natheat "Natural heat-related causes"
label var rate_drugodoth_dehyd "Dehydration-related causes"
label var rate_drugodoth_cardiovasc "All cardiovascular causes"
label var rate_drugodoth_clrd "Chronic lower respiratory causes"
label var rate_drugoddesp_suicide "Suicide"
label var rate_drugoddesp_asslt "Assault"
label var rate_placcanc_mel "Melanoma of the skin"
label var rate_placcanc_breast "Breast cancer"
label var rate_placcanc_colon "Colon cancer" 

*** Label and store labels
foreach var of varlist `varlist_exp' `varlist_poll' `varlist_outcomes' `varlist_cnty' {
	local l`var': variable label `var'
}

* Keep relevant variables
keep fips_county year month pop_total ///
	`varlist_exp' `varlist_poll' `varlist_outcomes'


* GENERATE OVERALL MEANS	
	
*** Unit count
sum `varlist_exp' `varlist_poll' `varlist_outcomes'

preserve

*** Generate means
sum `varlist_exp' `varlist_poll' `varlist_outcomes' [aw=pop_total]
mean `varlist_exp' `varlist_outcomes' [aw=pop_total]
mean `varlist_poll' [aw=pop_total]
collapse (mean) `varlist_exp' `varlist_poll' `varlist_outcomes' [aw=pop_total]
list

*** Tranpose data set for output and relabel
xpose, clear varname promote	
gen varlabel=""
local varsforlabel `varlist_exp' `varlist_poll' `varlist_outcomes'
foreach var in `varsforlabel' {
	replace varlabel="`l`var''" if _varname=="`var'"
}

drop _varname

*** Output
gen tableorder=_n
rename v1 mean
order varlabel
save "`temp'\means_analyticsample.dta", replace

restore


* GENERATE OVERALL SD	
	
preserve

*** Generate sd
sum `varlist_exp' `varlist_poll' `varlist_outcomes' [aw=pop_total]
collapse (sd) `varlist_exp' `varlist_poll' `varlist_outcomes' [aw=pop_total]
list

*** Tranpose data set for output and relabel
xpose, clear varname promote	
gen varlabel=""
local varsforlabel `varlist_exp' `varlist_poll' `varlist_outcomes'
foreach var in `varsforlabel' {
	replace varlabel="`l`var''" if _varname=="`var'"
}

drop _varname

*** Output
rename v1 sd
order varlabel
save "`temp'\sd_analyticsample.dta", replace

restore


* COMBINE OVERALL MEAN AND SD
preserve
use "`temp'\means_analyticsample.dta", clear
merge 1:1 varlabel using "`temp'\sd_analyticsample.dta"
drop _merge
order tableorder varlabel mean sd
sort tableorder
drop tableorder
list
save "`temp'\sumstats_analyticsample.dta", replace
restore


* CALCULATE MEDIAN HEAT INDEX VALUE

*** Identify median heat index value
sum avg_heatindex, detail
local hi_median = r(p50)
local hi_median_round = round(r(p50),0.01)
display "Median heat index: `hi_median'"
display "Rounded: `hi_median_round'"

*** Create indicator for above and below indicator
gen abovemedianheatindex=.
replace abovemedianheatindex=1 if avg_heatindex>`hi_median'&avg_heatindex!=.
replace abovemedianheatindex=0 if avg_heatindex<=`hi_median'
sum avg_heatindex if abovemedianheatindex==0
sum avg_heatindex if abovemedianheatindex==1

*** Unit count
sum `varlist_exp' `varlist_poll' `varlist_outcomes' if abovemedianheatindex==0
sum `varlist_exp' `varlist_poll' `varlist_outcomes' if abovemedianheatindex==1


* GENERATE MEANS ABOVE AND BELOW MEDIAN HEAT INDEX

preserve

*** Generate means
bysort abovemedianheatindex: sum `varlist_exp' `varlist_outcomes' [aw=pop_total]
mean `varlist_exp' `varlist_outcomes' [aw=pop_total], over(abovemedianheatindex)
mean `varlist_poll' [aw=pop_total], over(abovemedianheatindex)
collapse (mean) `varlist_exp' `varlist_poll' `varlist_outcomes' [aw=pop_total], by(abovemedianheatindex)
list

*** Tranpose data set for output and relabel
xpose, clear varname promote	
gen varlabel=""
local varsforlabel `varlist_exp' `varlist_poll' `varlist_outcomes'
foreach var in `varsforlabel' {
	replace varlabel="`l`var''" if _varname=="`var'"
}
replace varlabel="Above median heat index (`hi_median_round' degC)" if _varname=="abovemedianheatindex"
drop _varname

*** Output
gen tableorder=_n
rename v1 mean0
rename v2 mean1
order varlabel
save "`temp'\means_analyticsample_bymedheat.dta", replace

restore



* GENERATE SD ABOVE AND BELOW MEDIAN HEAT INDEX

preserve

*** Generate sd
bysort abovemedianheatindex: sum `varlist_exp' `varlist_outcomes' [aw=pop_total]
collapse (sd) `varlist_exp' `varlist_poll' `varlist_outcomes' [aw=pop_total], by(abovemedianheatindex)
list

*** Tranpose data set for output and relabel
xpose, clear varname promote	
gen varlabel=""
local varsforlabel `varlist_exp' `varlist_poll' `varlist_outcomes'
foreach var in `varsforlabel' {
	replace varlabel="`l`var''" if _varname=="`var'"
}
replace varlabel="Above median heat index (`hi_median_round' degC)" if _varname=="abovemedianheatindex"
drop _varname

*** Output
rename v1 sd0
rename v2 sd1
order varlabel
save "`temp'\sd_analyticsample_bymedheat.dta", replace

restore



*** COMBINE MEAN AND SD  ABOVE AND BELOW MEDIAN HEAT INDEX
use "`temp'\means_analyticsample_bymedheat.dta", clear
merge 1:1 varlabel using "`temp'\sd_analyticsample_bymedheat.dta"
drop _merge
order tableorder varlabel mean0 sd0 mean1 sd1
sort tableorder
drop tableorder
list
save "`temp'\sumstats_analyticsample_bymedheat.dta", replace



********************************* County-level calculations

* Load data

use "`data'\analytic_data.dta", clear
tab year, missing

* Binarize urban codes
foreach y in 2006 2013 {
	tab urbancode`y', gen(ucode`y'_)
	rename ucode`y'_1 ucode`y'_rural
	rename ucode`y'_2 ucode`y'_suburban
	rename ucode`y'_3 ucode`y'_urban
}


* Define variable lists into tables (main and appendix)

*** County-level mean variables (non-pop)
local varlist_cntymean med_hhi_2000 med_hhi_2020 svi_2000 svi_2020 ///
	
*** County-level mean variables (pop)
local varlist_cntymeanpop pop_male pop_female pop_age0to29 pop_age30to59 pop_age60plus pop_nhwhite pop_nhblack pop_hisp

*** County-level count/pct variables		
local varlist_cntycountpct divEastMSRiver ///
	ucode2006_rural ucode2013_rural ucode2006_suburban ucode2013_suburban ucode2006_urban ucode2013_urban

*** Table order
local tableorder divEastMSRiver ///
	med_hhi_2000 med_hhi_2020 svi_2000 svi_2020 ///
	ucode2006_rural ucode2013_rural ucode2006_suburban ucode2013_suburban ucode2006_urban ucode2013_urban ///
	pct_pop_male pct_pop_female ///
	pct_pop_age0to29 pct_pop_age30to59 pct_pop_age60plus ///
	pct_pop_nhwhite pct_pop_nhblack pct_pop_hisp
	
* Keep relevant variables
keep fips_county year month pop_total ///
	`varlist_cntymean' `varlist_cntymeanpop' `varlist_cntycountpct' ///
	avg_heatindex
	
* Check units - before county-level
sum `varlist_cntymean' `varlist_cntymeanpop' `varlist_cntycountpct' avg_heatindex

* Collapse data to county-year-level (over months)
*** All variables fixed over county, except pop by county & year, and heat index (used below)
collapse (mean) `varlist_cntymean' `varlist_cntymeanpop' `varlist_cntycountpct' ///
	pop_total avg_heatindex, by(fips_county year)
	
* Collapse to county-level (over years)
collapse (mean) `varlist_cntymean' `varlist_cntycountpct' avg_heatindex ///
	mean_pop_total=pop_total ///
	(sum) `varlist_cntymeanpop' ///
	tot_pop_total=pop_total, ///
	by(fips_county)
gen county_totcnt=1
	
* Calculate population percents (rescaled by 100)
foreach dem in male female ///
	age0to29 age30to59 age60plus ///
	nhwhite nhblack hisp {
		
	gen pct_pop_`dem'=(pop_`dem'/tot_pop_total)*100

}
drop pop* tot_pop_total
local varlist_cntymeanPCTPOP pct_pop_male pct_pop_female ///
	pct_pop_age0to29 pct_pop_age30to59 pct_pop_age60plus ///
	pct_pop_nhwhite pct_pop_nhblack pct_pop_hisp


* Label all variables

*** County Characteristics
label var divEastMSRiver "East of MS River (%)"
label var med_hhi_2000 "Median household income, 2000 ($)"
label var med_hhi_2020 "Median household income, 2020 ($)"
label var svi_2000 "SVI, 2000 (Total percentile ranking)"
label var svi_2020 "SVI, 2020 (Total percentile ranking)"
label var ucode2006_rural "Rural, 2006 (%)"
label var ucode2013_rural "Rural, 2013 (%)"
label var ucode2006_suburban "Suburban, 2006 (%)"
label var ucode2013_suburban "Suburban, 2013 (%)"
label var ucode2006_urban "Urban, 2006 (%)"
label var ucode2013_urban "Urban, 2013 (%)"

*** Demographics
label var pct_pop_male "Male (%)"
label var pct_pop_female "Female (%)"
label var pct_pop_age0to29 "Aged 0 to 29 (%)"
label var pct_pop_age30to59 "Aged 30 to 59 (%)"
label var pct_pop_age60plus "Aged 60 and older (%)"
label var pct_pop_nhblack "Black (non-Hispanic) (%)"
label var pct_pop_hisp "Hispanic (any race) (%)"
label var pct_pop_nhwhite "White (non-Hispanic) (%)"

*** Label and store labels
foreach var of varlist `varlist_cntymean' `varlist_cntycountpct' `varlist_cntymeanPCTPOP' {
	local l`var': variable label `var'
}

* County-level unit count
sum `varlist_cntymean' `varlist_cntycountpct' `varlist_cntymeanPCTPOP' 


* GENERATE OVERALL MEANS (AND COUNTS)

preserve

*** Generate means (and counts)
sum `varlist_cntymean' `varlist_cntymeanPCTPOP' [aw=mean_pop_total]
mean `varlist_cntymean' `varlist_cntymeanPCTPOP'  [aw=mean_pop_total]
collapse (mean) `varlist_cntymean' `varlist_cntymeanPCTPOP' ///
	(rawsum) `varlist_cntycountpct' county_totcnt ///
	[aw=mean_pop_total]
drop county_totcnt
order `tableorder'
list

*** Tranpose data set for output and relabel
xpose, clear varname promote	
gen varlabel=""
local varsforlabel `varlist_cntymean' `varlist_cntycountpct' `varlist_cntymeanPCTPOP'
foreach var in `varsforlabel' {
	replace varlabel="`l`var''" if _varname=="`var'"
}

drop _varname

*** Output
gen tableorder=_n
rename v1 mean_counts
order varlabel
save "`temp'\means_county.dta", replace

restore


* GENERATE OVERALL SD (AND PCT VALUES)

preserve

*** Generate sd (and percents)
sum `varlist_cntymean' `varlist_cntymeanPCTPOP' [aw=mean_pop_total]
collapse (sd) `varlist_cntymean' `varlist_cntymeanPCTPOP' ///
		(rawsum) `varlist_cntycountpct' county_totcnt /// 
		[aw=mean_pop_total]
*** Calculate county percents (rescaled by 100)
foreach cnty in divEastMSRiver ///
	ucode2006_rural ucode2013_rural ucode2006_suburban ucode2013_suburban ucode2006_urban ucode2013_urban {
		
	replace `cnty'=(`cnty'/county_totcnt)*100

}
drop county_totcnt
order `tableorder'
list


*** Tranpose data set for output and relabel
xpose, clear varname promote	
gen varlabel=""
local varsforlabel `varlist_cntymean' `varlist_cntycountpct' `varlist_cntymeanPCTPOP'
foreach var in `varsforlabel' {
	replace varlabel="`l`var''" if _varname=="`var'"
}

drop _varname

***** Output
rename v1 sd_pct
order varlabel
save "`temp'\sd_county.dta", replace

restore


* COMBINE OVERALL MEAN AND SD
preserve
use "`temp'\means_county.dta", clear
merge 1:1 varlabel using "`temp'\sd_county.dta"
drop _merge
order tableorder varlabel mean_counts sd_pct
sort tableorder
drop tableorder
list
save "`temp'\sumstats_county.dta", replace
restore



* CALCULATE MEDIAN HEAT INDEX VALUE

*** Identify median heat index value
sum avg_heatindex, detail
local hi_median = r(p50)
local hi_median_round = round(r(p50),0.01)
display "Median heat index: `hi_median'"
display "Rounded: `hi_median_round'"

*** Create indicator for above and below indicator
gen abovemedianheatindex=.
replace abovemedianheatindex=1 if avg_heatindex>`hi_median'&avg_heatindex!=.
replace abovemedianheatindex=0 if avg_heatindex<=`hi_median'
sum avg_heatindex if abovemedianheatindex==0
sum avg_heatindex if abovemedianheatindex==1

*** Unit count
sum `varlist_cntymean' `varlist_cntycountpct' `varlist_cntymeanPCTPOP' if abovemedianheatindex==0
sum `varlist_cntymean' `varlist_cntycountpct' `varlist_cntymeanPCTPOP' if abovemedianheatindex==1


* GENERATE MEANS (AND COUNTS) ABOVE AND BELOW MEDIAN HEAT INDEX

preserve

*** Generate means (and counts)
bysort abovemedianheatindex: sum `varlist_cntymean' `varlist_cntymeanPCTPOP' [aw=mean_pop_total]
mean `varlist_cntymean' `varlist_cntymeanPCTPOP' [aw=mean_pop_total], over(abovemedianheatindex)
collapse (mean) `varlist_cntymean' `varlist_cntymeanPCTPOP' ///
	(rawsum) `varlist_cntycountpct' county_totcnt ///
	[aw=mean_pop_total], by(abovemedianheatindex)
drop county_totcnt
order `tableorder'
list

*** Tranpose data set for output and relabel
xpose, clear varname promote	
gen varlabel=""
local varsforlabel `varlist_cntymean' `varlist_cntycountpct' `varlist_cntymeanPCTPOP'
foreach var in `varsforlabel' {
	replace varlabel="`l`var''" if _varname=="`var'"
}
replace varlabel="Above median heat index (`hi_median_round' degC)" if _varname=="abovemedianheatindex"
drop _varname

*** Output
gen tableorder=_n
rename v1 mean_counts0
rename v2 mean_counts1
order varlabel
save "`temp'\means_county_bymedheat.dta", replace

restore


* GENERATE SD (AND PCT VALUES)  ABOVE AND BELOW MEDIAN HEAT INDEX

preserve

*** Generate sd (and percents)
bysort abovemedianheatindex: sum `varlist_cnty' [aw=mean_pop_total]
collapse (sd) `varlist_cntymean' `varlist_cntymeanPCTPOP' ///
		(rawsum) `varlist_cntycountpct' county_totcnt /// 
		[aw=mean_pop_total], by(abovemedianheatindex)
*** Calculate county percents (rescaled by 100)
foreach cnty in divEastMSRiver ///
	ucode2006_rural ucode2013_rural ucode2006_suburban ucode2013_suburban ucode2006_urban ucode2013_urban {
		
	replace `cnty'=(`cnty'/county_totcnt)*100

}
drop county_totcnt
order `tableorder'
list


*** Tranpose data set for output and relabel
xpose, clear varname promote	
gen varlabel=""
local varsforlabel `varlist_cntymean' `varlist_cntycountpct' `varlist_cntymeanPCTPOP'
foreach var in `varsforlabel' {
	replace varlabel="`l`var''" if _varname=="`var'"
}
replace varlabel="Above median heat index (`hi_median_round' degC)" if _varname=="abovemedianheatindex"
drop _varname

***** Output
rename v1 sd_pct0
rename v2 sd_pct1
order varlabel
save "`temp'\sd_county_bymedheat.dta", replace

restore


*** COMBINE MEAN AND SD
use "`temp'\means_county_bymedheat.dta", clear
merge 1:1 varlabel using "`temp'\sd_county_bymedheat.dta"
drop _merge
order tableorder varlabel mean_counts0 sd_pct0 mean_counts1 sd_pct1
sort tableorder
drop tableorder
list
save "`temp'\sumstats_county_bymedheat.dta", replace


* Output all in Excel

*** Clear Excel file
clear
set obs 1
gen info="summary stats output file"
export excel using "`out'\summary_stats.xlsx", replace

*** Output
use "`temp'\sumstats_analyticsample.dta", clear
export excel using "`out'\summary_stats.xlsx", sheetreplace sheet("Analytic samp")
use "`temp'\sumstats_analyticsample_bymedheat.dta"	
export excel using "`out'\summary_stats.xlsx", sheetreplace sheet("Analytic samp med heat")
use "`temp'\sumstats_county.dta"	
export excel using "`out'\summary_stats.xlsx", sheetreplace sheet("County level")
use "`temp'\sumstats_county_bymedheat.dta"	
export excel using "`out'\summary_stats.xlsx", sheetreplace sheet("County level med heat")


log close
