capture log close
clear all
set more off, perm

* Set directories

cd "<working directory>"
local maindir "<working directory>"

local data "<Analytic data>"

local out "<Output>"
local figout "<Figure output>"
local tempfig "<Temporary files>"

* Log file

log using "`out'\county_char.log", replace

* Load data

use "`data'\analytic_data.dta", clear
tab year, missing

******************************************* By County Characteristics (Stratified)

* REGRESSIONS:

foreach outcome in rate_drugod_all {

	*** Main Results
	reghdfe `outcome' avg_heatindex [aw=pop_total], ///
		absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
	estimates store Est_main

	*** Time: Pre vs. post third wave of opioid epidemic (fentanyl), begins 2013
	reghdfe `outcome' avg_heatindex if year2013plus==0 [aw=pop_total], ///
		absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
	estimates store Est_pre2013

	reghdfe `outcome' avg_heatindex if year2013plus==1 [aw=pop_total], ///
		absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
	estimates store Est_2013plus

	*** Geography: East vs. west of the Mississippi River	
	reghdfe `outcome' avg_heatindex if divEastMSRiver==0 ///
		[aw=pop_total], ///
		absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
	estimates store Est_WestMS

	reghdfe `outcome' avg_heatindex if divEastMSRiver==1 ///
		[aw=pop_total], ///
		absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
	estimates store Est_EastMS
	
	*** 2000 Median household income
	forvalues t=1/2 {
		reghdfe `outcome' avg_heatindex if med_hhi_2000_xtile==`t' [aw=pop_total], ///
			absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
		estimates store Est_hhi2000_xtile`t'
	}
	
	*** 2000 SVI
	forvalues t=1/2 {		
		reghdfe `outcome' avg_heatindex if svi_2000_xtile==`t' [aw=pop_total], ///
			absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
		estimates store Est_svi2000_xtile`t'
	}
	
	*** 2006 Urbanicity
	foreach t in rural suburban urban {
		reghdfe `outcome' avg_heatindex if urbancode2006=="`t'" [aw=pop_total], ///
			absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
		estimates store Est_urban2006_`t'
	}
	
}

* FIGURE:

coefplot (Est_main \ ///
	Est_pre2013 \ Est_2013plus \ ///
	Est_WestMS \ Est_EastMS \ ///
	Est_hhi2000_xtile1 \ Est_hhi2000_xtile2 \ ///
	Est_svi2000_xtile1 \ Est_svi2000_xtile2 \ ///
	Est_urban2006_rural \ Est_urban2006_suburban \ Est_urban2006_urban \ ///	
	), ///
	keep(avg_heatindex) ///
	aseq swapnames ///
	coeflabels(Est_main = "All counties and years" ///
		///
		Est_pre2013 = "Years pre-2013"  ///
		Est_2013plus = "Years 2013+" ///
		///
		Est_WestMS = "West of MS River" ///		
		Est_EastMS = "East of MS River" ///
		///
		Est_hhi2000_xtile1 = "Below median"  ///
		Est_hhi2000_xtile2 = "Above median"  ///
		///
		Est_svi2000_xtile1 = "Least vulnerable" ///
		Est_svi2000_xtile2 = "Most vulnerable" ///
		///
		Est_urban2006_rural = "Rural" ///		
		Est_urban2006_suburban = "Suburban" ///
		Est_urban2006_urban = "Urban"  ///		
		) ///
	xline(0, lcolor(black)) ///
	xtitle("Effect of one degree C increase on deaths per 100,000") ///
	headings(Est_main = "{bf:Main results:}" /// 
		Est_pre2013 = "{bf:By time period:}" ///
		Est_WestMS = "{bf:By geography:}" ///
		Est_hhi2000_xtile1 = "{bf:By 2000 income:}" ///
		Est_svi2000_xtile1 = "{bf:By 2000 SVI:}" ///
		Est_urban2006_rural = "{bf:By 2006 urbanicity:}" ///		
		) ///
	mcolor(black) ciopts(lcolor(black))
graph export "`figout'\fig_cntychars.svg", replace
graph export "`figout'\Figure3.tif", replace



******************************* Later definition of county characteristics (Stratified)

* REGRESSIONS:
foreach outcome in rate_drugod_all {

	display "Main Results"
	reghdfe `outcome' avg_heatindex [aw=pop_total], ///
		absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
	estimates store Est2_main
	
	forvalues t=1/2 {
		display "2020 Median household income, quantile `t'"
		reghdfe `outcome' avg_heatindex if med_hhi_2020_xtile==`t' [aw=pop_total], ///
			absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
		estimates store Est_hhi2020_xtile`t'
	}
	
	forvalues t=1/2 {
		display "2020 SVI, quantile `t'"		
		reghdfe `outcome' avg_heatindex if svi_2020_xtile==`t' [aw=pop_total], ///
			absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
		estimates store Est_svi2020_xtile`t'
	}
	
	foreach t in rural suburban urban {
		display "2013 Urbanicity, category `t'"		
		reghdfe `outcome' avg_heatindex if urbancode2013=="`t'" [aw=pop_total], ///
			absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
		estimates store Est_urban2013_`t'
	}
	
}



* FIGURE:
coefplot (Est2_main \ ///
	Est_hhi2020_xtile1 \ Est_hhi2020_xtile2 \ ///
	Est_svi2020_xtile1 \ Est_svi2020_xtile2 \ ///
	Est_urban2013_rural \ Est_urban2013_suburban \ Est_urban2013_urban \ ///
	), ///
	keep(avg_heatindex) ///
	aseq swapnames ///
	coeflabels(Est2_main = "All counties" ///
		///
		Est_hhi2020_xtile1 = "Below median"  ///
		Est_hhi2020_xtile2 = "Above median"  ///
		///
		Est_svi2020_xtile1 = "Least vulnerable" ///
		Est_svi2020_xtile2 = "Most vulnerable" ///
		///
		Est_urban2013_rural = "Rural" ///		
		Est_urban2013_suburban = "Suburban" ///
		Est_urban2013_urban = "Urban"  ///
		) ///
	xline(0, lcolor(black)) ///
	xtitle("Effect of one degree C increase on deaths per 100,000") ///
	headings(Est2_main = "{bf:Main results:}" /// 
		Est_hhi2020_xtile1 = "{bf:By 2020 income:}" ///
		Est_svi2020_xtile1 = "{bf:By 2020 SVI:}" ///
		Est_urban2013_rural = "{bf:By 2013 urbanicity:}" ///
		) ///
	mcolor(black) ciopts(lcolor(black))
graph export "`figout'\fig_supp_latercntydefs.svg", replace






* ALL STRATIFIED ESTIMATES OUTPUT

cd `tempfig'
esttab Est* using table_cntychar_estimates.csv, replace ///
		se ///
		star(* 0.05 ** 0.01 *** 0.001) ///
		order(avg_heatindex) ///
		mlabels(,notitles)
estimates clear

cd `maindir'




******************************************* Statistically significant differences by county (interaction)

* REGRESSIONS:

*** Main results
eststo: reghdfe rate_drugod_all avg_heatindex [aw=pop_total], ///
	absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
	
*** Pre vs Post 2013
eststo: reghdfe rate_drugod_all avg_heatindex i.year2013plus#c.avg_heatindex [aw=pop_total], ///
	absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)

*** East vs West of MS River
eststo: reghdfe rate_drugod_all avg_heatindex i.divEastMSRiver#c.avg_heatindex [aw=pop_total], ///
	absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
	
*** Household income xtiles
eststo: reghdfe rate_drugod_all avg_heatindex i.med_hhi_2000_xtile#c.avg_heatindex [aw=pop_total], ///
	absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)

*** SVI xtiles
eststo: reghdfe rate_drugod_all avg_heatindex i.svi_2000_xtile#c.avg_heatindex [aw=pop_total], ///
	absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)

*** Urbanicity codes
gen ucode2006=.
replace ucode2006=1 if urbancode2006=="rural"
replace ucode2006=2 if urbancode2006=="suburban"
replace ucode2006=3 if urbancode2006=="urban"
tab ucode2006 urbancode2006, missing
eststo: reghdfe rate_drugod_all avg_heatindex i.ucode2006#c.avg_heatindex [aw=pop_total], ///
	absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
	
* Output table

cd `tempfig'
esttab using table_cntychars_statsigdiff_se.csv, replace ///
		se star(* 0.05 ** 0.01 *** 0.001) ///
		level(95) ///
		order(avg_heatindex *year2013plus* *divEastMSRiver* *med_hhi* *svi* *ucode*)
esttab using table_cntychars_statsigdiff_pval.csv, replace ///
		p star(* 0.05 ** 0.01 *** 0.001) ///
		level(95) ///
		order(avg_heatindex *year2013plus* *divEastMSRiver* *med_hhi* *svi* *ucode*)
esttab using table_cntychars_statsigdiff_pval6digits.csv, replace ///
		p star(* 0.05 ** 0.01 *** 0.001) ///
		level(95) ///
		cells("p(fmt(5))") ///
		order(avg_heatindex *year2013plus* *divEastMSRiver* *med_hhi* *svi* *ucode*)
estimates clear


cd `maindir'


******************************************* Output Excel Tables

insheet using "`tempfig'\table_cntychar_estimates.csv", clear
export excel "`figout'\table_cntychar_estimates.xlsx", replace sheet("Stratify het effect")


insheet using "`tempfig'\table_cntychars_statsigdiff_se.csv", clear
export excel "`figout'\table_cntychars_statsigdiff.xlsx", replace sheet("Interaction het effect - se")
insheet using "`tempfig'\table_cntychars_statsigdiff_pval.csv", clear
export excel "`figout'\table_cntychars_statsigdiff.xlsx", sheetreplace sheet("Interaction het effect - pval")
insheet using "`tempfig'\table_cntychars_statsigdiff_pval6digits.csv", clear
export excel "`figout'\table_cntychars_statsigdiff.xlsx", sheetreplace sheet("Interaction het effect - pval5")


log close



