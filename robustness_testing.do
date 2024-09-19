capture log close
clear all
set more off, perm

* Set directories

cd "<working directory>"

local data "<Analytic data>"

local out "<Output>"
local figout "<Figure output>"
local tempfig "<Temporary output>"

* Log file

log using "`out'\robustness_testing.log", replace

* Load data

use "`data'\analytic_data.dta", clear
tab year, missing

******************************************* Different Exposure Variables

* REGRESSIONS:

*** Different exposure variables

foreach outcome in rate_drugod_all {

	foreach expvar in avg_heatindex ///
		tmean ///
		avgtemp maxtemp mintemp ///
		Zavg_heatindex Ztmean Zavgtemp {

		reghdfe `outcome' `expvar' [aw=pop_total], ///
			absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
		estimates store Exp_`expvar'
		
	}
	
}


*** Different exposure variables with controls for precipitation

gen avg_heatindex_wppt = avg_heatindex
gen avg_heatindex_wprec = avg_heatindex
gen tmean_wppt = tmean
gen avgtemp_wprec = avgtemp

foreach outcome in rate_drugod_all {

	foreach expvar in avg_heatindex_wppt tmean_wppt {
	
		reghdfe `outcome' `expvar' ppt [aw=pop_total], ///
			absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
		estimates store Exp_`expvar'
		
	}
	
	foreach expvar in avg_heatindex_wprec avgtemp_wprec {
	
		reghdfe `outcome' `expvar' prec [aw=pop_total], ///
			absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
		estimates store Exp_`expvar'
		
	}	
			
	
}


*** Controls for pollution

gen avg_heatindex_02to20 = avg_heatindex
gen avg_heatindex_wozone = avg_heatindex
gen avg_heatindex_wpm25 = avg_heatindex
gen avg_heatindex_wboth = avg_heatindex

reghdfe rate_drugod_all avg_heatindex_02to20 ///
	if year>=2002&year<=2020 [aw=pop_total], ///
	absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
estimates store Exp_Pmain
		
reghdfe rate_drugod_all avg_heatindex_wozone ///
	mean_ozone ///
	if year>=2002&year<=2020 [aw=pop_total], ///
	absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
estimates store Exp_Pozone
	
reghdfe rate_drugod_all avg_heatindex_wpm25 ///
	mean_pm25 ///
	if year>=2002&year<=2020 [aw=pop_total], ///
	absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
estimates store Exp_Ppm25
	
reghdfe rate_drugod_all avg_heatindex_wboth ///
	mean_ozone mean_pm25 ///
	if year>=2002&year<=2020 [aw=pop_total], ///
	absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
estimates store Exp_Pboth




* FIGURE:
coefplot (Exp_avg_heatindex \ ///
	Exp_avg_heatindex_wppt \ Exp_avg_heatindex_wprec \ ///
	Exp_tmean \ Exp_tmean_wppt \ ///
	Exp_avgtemp \ Exp_avgtemp_wprec \ /// 
	Exp_maxtemp \ Exp_mintemp \ ///
	Exp_Pmain \ Exp_Pozone \ Exp_Ppm25 \ Exp_Pboth ///
	), ///
	keep(avg_heatindex* ///
		tmean* avgtemp* maxtemp mintemp) ///
	aseq swapnames noeqlabels ///
	coeflabels(Exp_avg_heatindex = "Heat index" ///	
		Exp_avg_heatindex_wppt = "w/ prec. control (PL/PRISM)" ///
		Exp_avg_heatindex_wprec = "w/ prec. control (NOAA)" ///
		///
		Exp_tmean = "Avg. temperature"  ///
		Exp_tmean_wppt = "w/ prec. control" ///
		///
		Exp_avgtemp = "Avg. temperature"  ///
		Exp_avgtemp_wprec = "w/ prec. control" ///
		Exp_maxtemp = "Max. temperature" ///
		Exp_mintemp = "Min. temperature"  ///
		///
		Exp_Pmain = "Heat index (2002-2020 only)"  ///
		Exp_Pozone = "w/ ozone control" ///
		Exp_Ppm25 = "w/ PM 2.5 control"  ///
		Exp_Pboth = "w/ ozone and PM 2.5 controls" ///
		) ///	
	xline(0, lcolor(black)) ///
	xtitle("Effect of one degree C increase on deaths per 100,000") ///
	subtitle("{bf:Panel A: Alternative exposure variables}") ///
	headings(Exp_avg_heatindex = "{bf:Main result:}" ///
		Exp_tmean = "{bf: PL/PRISM data:}" ///
		Exp_avgtemp = "{bf: NOAA data:}" ///
		Exp_Pmain = "{bf: Pollutants as controls:}" ///
	) ///
	mcolor(black) ciopts(lcolor(black)) ///
	xscale(range(-0.0025)) xlabel(0(0.005)0.025)
graph export "`figout'\fig_supp_exposures.svg", replace		
	
coefplot (Exp_Zavg_heatindex \ Exp_Ztmean \ Exp_Zavgtemp \ ///
	), ///
	keep(Zavg_heatindex Ztmean Zavgtemp) ///
	aseq swapnames noeqlabels ///
	coeflabels(Exp_Zavg_heatindex = "Z-score heat index" ///	
		Exp_Ztmean = "Z-score avg. temperature (PL/PRISM)" ///
		Exp_Zavgtemp = "Z-score avg. temperature (NOAA)" ///
	) ///
	xline(0, lcolor(black)) ///
	xtitle("Effect of one standard deviation increase on deaths per 100,000") ///
	subtitle("{bf:Panel B: Within county-month standardized exposures}") ///	
	mcolor(black) ciopts(lcolor(black)) ///
	xscale(range(-0.0025)) xlabel(0(0.005)0.03)
graph export "`figout'\fig_supp_Zscoreexp.svg", replace	



******************************************* Regression specification changes robustness tests
/*Includes "quasi-lag dependent" model: 
Account for possibility that noise in temperature increases are correlated with unrelated periods
of elevated deaths (spurious correlations).
(e.g. include total deaths in spring that year plus previous month) */


* REGRESSIONS:

foreach outcome in rate_drugod_all {

	*** Main Spec (StateXYear, CountyXMonth clustering, weighted by pop)
	reghdfe `outcome' avg_heatindex [aw=pop_total], ///
		absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
	estimates store SPEC_Main
	
	*** Different FE's: Year shocks
	reghdfe `outcome' avg_heatindex [aw=pop_total], ///
		absorb(i.fips_county#i.month i.year) vce(cluster i.fips_county#i.month)
	estimates store SPEC_Year
	
	*** Different FE's: Year shocks w SSLTT
	reghdfe `outcome' avg_heatindex [aw=pop_total], ///
		absorb(i.fips_county#i.month i.year c.year#i.state) vce(cluster i.fips_county#i.month)
	estimates store SPEC_YearwSSLTT
		
	*** Different FE's: Year-Month shocks
	reghdfe `outcome' avg_heatindex [aw=pop_total], ///
		absorb(i.fips_county#i.month i.yearmonth) vce(cluster i.fips_county#i.month)
	estimates store SPEC_YearMonth
		
	*** Different FE's: Year shocks and seasonal month shocks
	reghdfe `outcome' avg_heatindex [aw=pop_total], ///
		absorb(i.fips_county#i.month i.year i.month) vce(cluster i.fips_county#i.month)
	estimates store SPEC_Year_Month	
	
	*** No weighting
	reghdfe `outcome' avg_heatindex, ///
		absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
	estimates store SPEC_NoWeight
	
	*** Clustering: countyXyear
	reghdfe `outcome' avg_heatindex [aw=pop_total], ///
		absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.year)
	estimates store SPEC_ClusterCountyYear
	
	*** Clustering: county only
	reghdfe `outcome' avg_heatindex [aw=pop_total], ///
		absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county)
	estimates store SPEC_ClusterCounty
	
	*** Clustering: stateXmonth
	reghdfe `outcome' avg_heatindex [aw=pop_total], ///
		absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.state#i.month)
	estimates store SPEC_ClusterStateMonth

	*** Clustering: stateXyear
	reghdfe `outcome' avg_heatindex [aw=pop_total], ///
		absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.state#i.year)
	estimates store SPEC_ClusterStateYear	
	
	*** Clustering: state only
	reghdfe `outcome' avg_heatindex [aw=pop_total], ///
		absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.state)
	estimates store SPEC_ClusterState
	
	*** Quasi-lag dependent model - one month lag
	reghdfe `outcome' avg_heatindex ///
		lag_`outcome' [aw=pop_total], ///
		absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
	estimates store SPEC_QuasiLagMonth	
	
	*** Quasi-lag dependent model - March-May OD lag
	reghdfe `outcome' avg_heatindex ///
		totsp_`outcome' [aw=pop_total], ///
		absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
	estimates store SPEC_QuasiLagSpring
	
	*** Quasi-lag dependent model - Both
	reghdfe `outcome' avg_heatindex ///
		lag_`outcome' totsp_`outcome' [aw=pop_total], ///
		absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
	estimates store SPEC_QuasiLagBoth		
	
}



* FIGURE:

coefplot (SPEC_Main \ ///
	///
	SPEC_Year \ SPEC_YearwSSLTT \ SPEC_YearMonth \ SPEC_Year_Month \ ///
	///
	SPEC_NoWeight \ ///
	///
	SPEC_ClusterCountyYear \ SPEC_ClusterCounty \ SPEC_ClusterStateMonth ///
	SPEC_ClusterStateYear \ SPEC_ClusterState \ ///
	///
	SPEC_QuasiLagMonth \SPEC_QuasiLagSpring \ SPEC_QuasiLagBoth ///
	), ///
	keep(avg_heatindex) ///
	aseq swapnames ///
	coeflabels(SPEC_Main = "Main specification" ///
		///
		SPEC_Year = "Year FEs"  ///
		SPEC_YearwSSLTT = "Year FEs with SSLTT" ///
		SPEC_YearMonth = "Year-month FEs"  ///
		SPEC_Year_Month = "Year FEs and month FEs" ///
		///
		SPEC_NoWeight = "Unweighted" ///
		///
		SPEC_ClusterCountyYear = "County by year" ///		
		SPEC_ClusterCounty = "County only"  ///
		SPEC_ClusterStateMonth = "State by month" ///
		SPEC_ClusterStateYear = "State by year" ///
		SPEC_ClusterState = "State only" ///
		///
		SPEC_QuasiLagMonth = "Lagged one month" ///		
		SPEC_QuasiLagSpring = "Lagged March-May total" ///				
		SPEC_QuasiLagBoth = "Both" ///
		) ///
	xline(0, lcolor(black)) ///
	xtitle("Effect of one degree C increase on deaths per 100,000") ///
	headings(SPEC_Main = "{bf:Main results:}" ///
		SPEC_Year = "{bf: Time fixed effects}" ///
		SPEC_NoWeight = "{bf: Weighting:}" ///
		SPEC_ClusterCountyYear = "{bf:Standard error clustering:}" ///
		SPEC_QuasiLagMonth = "{bf:Overdose rates as controls:}" ///		
		) ///
	mcolor(black) ciopts(lcolor(black))
graph export "`figout'\fig_supp_specrob.svg", replace



******************************************* Placebo tests

* REGRESSIONS:

*** Lagged

foreach outcome in rate_drugod_all {

	***  Main results
	gen main_avg_heatindex=avg_heatindex
	label var main_avg_heatindex "Heat index"
	
	reghdfe `outcome' main_avg_heatindex [aw=pop_total], ///
		absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
	estimates store PL_MainResult
		
	*** Lagged heat index only
	gen lagonly_avg_heatindex_lag1=avg_heatindex_lag1
	label var lagonly_avg_heatindex_lag1 "Lagged heat index"
	
	reghdfe `outcome' lagonly_avg_heatindex_lag1 ///
		[aw=pop_total], ///
		absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
	estimates store PL_Lagged_Only
	
	*** Current and Lagged heat index "horse race" 
	gen comb_avg_heatindex=avg_heatindex
	gen comb_avg_heatindex_lag1=avg_heatindex_lag1
	label var comb_avg_heatindex "Heat index"
	label var comb_avg_heatindex_lag1 "Lagged heat index"
	
	reghdfe `outcome' comb_avg_heatindex comb_avg_heatindex_lag1 ///
		[aw=pop_total], ///
		absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
	estimates store PL_CurrandLag	

}



*** Cancers

foreach outcome in rate_drugod_all {

	reghdfe `outcome' avg_heatindex [aw=pop_total], ///
		absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
	estimates store PC_MainResult

}

foreach outcome in rate_placcanc_mel rate_placcanc_breast rate_placcanc_colon {

	reghdfe `outcome' avg_heatindex [aw=pop_total], ///
		absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
	estimates store PC_`outcome'
		
}


* FIGURE:
	
coefplot (PL_MainResult \ PL_CurrandLag \ PL_Lagged_Only \ ///
	), ///
	keep(main_avg_heatindex lagonly_avg_heatindex_lag1 comb_avg_heatindex comb_avg_heatindex_lag1) ///
	xline(0, lcolor(black)) ///
	xtitle("Effect of one degree C increase on deaths per 100,000") ///
	headings(main_avg_heatindex = "{bf: Main result:}" ///
		comb_avg_heatindex = "{bf: Current and lagged exposure:}" ///	
		lagonly_avg_heatindex_lag1 = "{bf: Lagged exposure only:}" ///		
		) ///
	mcolor(black) ciopts(lcolor(black)) ///
	subtitle("{bf:Panel A: Lagged heat exposure}")	
graph export "`figout'\fig_supp_placebo_lag.svg", replace	
	
coefplot (PC_MainResult \ ///
	///
	PC_rate_placcanc_mel \ PC_rate_placcanc_breast \ PC_rate_placcanc_colon \ ///
	), ///
	keep(avg_heatindex) ///
	aseq swapnames ///
	coeflabels(PC_MainResult = "All drug overdoses" ///
		///
		PC_rate_placcanc_mel = "Melanoma of the skin" ///
		PC_rate_placcanc_breast = "Breast cancer"  ///
		PC_rate_placcanc_colon = "Colon cancer" ///
		) ///
	xline(0, lcolor(black)) ///
	xtitle("Effect of one degree C increase on deaths per 100,000") ///
	headings(PC_MainResult = "{bf: Main result:}" ///	
		PC_rate_placcanc_mel = "{bf: Cancer deaths:}" ///	
		) ///
	mcolor(black) ciopts(lcolor(black)) ///
	subtitle("{bf:Panel B: Cancer deaths}")
graph export "`figout'\fig_supp_placebo_cancer.svg", replace
	
	

******************************************* Is any single Census Divison driving results?

* REGRESSIONS:

foreach outcome in rate_drugod_all {

	reghdfe `outcome' avg_heatindex [aw=pop_total], ///
		absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
	estimates store D_Main_divall
	
	forvalues d=1/9 {

		preserve
	
		drop if divisioncode==`d'
	
		reghdfe `outcome' avg_heatindex [aw=pop_total], ///
			absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)

		estimates store D_dropdiv`d'
		
		restore
		
	}


}
	
* FIGURE:

coefplot (D_Main_divall \ ///
	///
	D_dropdiv1 \ D_dropdiv2 \ D_dropdiv3 \ D_dropdiv4 \ ///
	D_dropdiv5 \ D_dropdiv6 \ D_dropdiv7 \ D_dropdiv8 \ D_dropdiv9 ///
	), ///
	keep(avg_heatindex) ///
	aseq swapnames ///
	coeflabels(D_Main_divall = "All Census divisions" ///
		///
		D_dropdiv1 = "New England"  ///
		D_dropdiv2 = "Middle Atlantic" ///
		D_dropdiv3 = "East North Central"  ///
		D_dropdiv4 = "West North Central" ///
		D_dropdiv5 = "South Atlantic" ///
		D_dropdiv6 = "East South Central" ///		
		D_dropdiv7 = "West South Central"  ///
		D_dropdiv8 = "Mountain" ///
		D_dropdiv9 = "Pacific" ///
		) ///
	xline(0, lcolor(black)) ///
	xtitle("Effect of one degree C increase on deaths per 100,000") ///
	headings(D_Main_divall = "{bf: Main results:}" ///
		D_dropdiv1 = "{bf: Dropped Census division:}" ///
		) ///
	xscale(range(-0.001)) xlabel(0(0.004)0.016) ///
	mcolor(black) ciopts(lcolor(black))
graph export "`figout'\fig_supp_dropdiv.svg", replace




******************************************* OUTPUT ABOVE ESTIMATE VALUES

esttab Exp_* SPEC_* PL_* PC_* D_* using table_robust_estimates.csv, replace ///
		se ///
		star(* 0.05 ** 0.01 *** 0.001) ///
		order(avg_heatindex) ///
		mlabels(,notitles)
estimates clear

preserve
insheet using "`tempfig'\table_robust_estimates.csv", clear
export excel "`figout'\table_robust_estimates.xlsx", replace sheet("Robust estimates")
restore


******************************************* Residualized Bin Scatters

preserve

* Obtain Y (outcome) residuals

foreach outcome in rate_drugod_all {

	reghdfe `outcome' [aw=pop_total], ///
		absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month) ///
		residuals(YRSD_`outcome')
	replace YRSD_`outcome'=. if e(sample)!=1
	
}

* Obtain X (Avg temperature) residuals:
reghdfe avg_heatindex [aw=pop_total], ///
	absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month) ///
	residuals(XRSD)
replace XRSD=. if e(sample)!=1

* Divide observations into ventiles based on residualized avg temp
xtile ventXRSD = XRSD, nq(20)

* Plot the average residuzalized outcome for each ventile (on the Y-axis) against the avg temp residuals:
*** Note: have to weight each observation to match regression
*** See discussion: https://www.statalist.org/forums/forum/general-stata-discussion/general/329653-regress-postestimation-with-weights

collapse (mean) YRSD_* XRSD [aw=pop_total], by(ventXRSD)

label var YRSD_rate_drugod_all "All overdose deaths per 100,000"
label var XRSD "Mean residualized heat index"
label var ventXRSD "Ventile of residualized heat index"

foreach outcome in rate_drugod_all {

	***> Ventile number on the x-axis
	twoway (scatter YRSD_`outcome' ventXRSD) ///
		(lfit YRSD_`outcome' ventXRSD, lpattern(dash)), ///
		ytitle("Mean residualized drug overdose mortality") ///
		legend(off)
	graph export "`figout'\fig_supp_resids_`outcome'vsventXRSD.svg", replace

	***> Mean residualized flu mortality of the observations in the ventile on the x-axis
	twoway (scatter YRSD_`outcome' XRSD) ///
		(lfit YRSD_`outcome' XRSD, lpattern(dash)), ///
		ytitle("Mean residualized drug overdose mortality") ///
		legend(off)
	graph export "`figout'\fig_supp_resids_`outcome'vsXRSD.svg", replace

}

restore

	
log close
