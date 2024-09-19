capture log close
clear all
set more off, perm

* Set directories

cd "<working directory>"

local data "<Analytic data>"

local figout "<Figure output>"

* Log file

log using "`data'\analysis_allseasons.log", replace

* Load data

use "`data'\analytic_data_ALLMONTHS.dta", clear
tab year, missing

* Figure: seasonality in overdoses and heat index/temperature

preserve

collapse (mean) avg_heatindex ///
	tmean ///
	avgtemp maxtemp mintemp ///
	(rawsum) drugod_all pop_total ///
	[aw=pop_total], by(month)

foreach out in drugod_all {
	gen rate_`out'=(`out'/pop_total)*100000
}

label var avg_heatindex "Heat index, CDC {it:(L)}"
label var tmean "Avg. temperature, PL/PRISM {it:(L)}"
label var avgtemp "Avg. temperature, NOAA {it:(L)}"
label var maxtemp "Max. temperature, NOAA {it:(L)}"
label var mintemp "Min. temperature, NOAA {it:(L)}"

label var rate_drugod_all "All drug overdoses {it:(R)}"

label var month "Month"

graph twoway (connected avg_heatindex month, ///
				yaxis(1) ytitle("Degrees Celsius", axis(1)) ylabel(-5(10)35, axis(1)) ///
				lcolor(midgreen) mcolor(midgreen) lwidth(medium) ///
				msize(vsmall) lpattern(solid)) ///
			(connected tmean month, ///
				yaxis(1) ytitle("Degrees Celsius", axis(1)) ///
				lcolor(purple) mcolor(purple) lwidth(medium) ///
				msize(vsmall) lpattern(dash_dot)) ///				
			(connected maxtemp month, ///
				yaxis(1) ytitle("Degrees Celsius", axis(1)) ///
				lcolor(midblue) mcolor(midblue) lwidth(medium) ///
				msize(vsmall) lpattern(dot)) ///
			(connected avgtemp month, ///
				yaxis(1) ytitle("Degrees Celsius", axis(1)) ///
				lcolor(midblue) mcolor(midblue) lwidth(medium) ///
				msize(vsmall) lpattern(shortdash_dot)) ///
			(connected mintemp month, ///
				yaxis(1) ytitle("Degrees Celsius", axis(1)) ///
				lcolor(midblue) mcolor(midblue) lwidth(medium) ///
				msize(vsmall) lpattern(longdash_dot)) ///
			(connected rate_drugod_all month, ///
				yaxis(2) ytitle("Deaths per 100,000", axis(2)) ylabel(1(0.05)1.2, axis(2)) ///
				lcolor(cranberry) mcolor(cranberry) lwidth(medium) ///
				msize(vsmall) lpattern(dash)) ///			
				, ///
	xscale(range(1)) xlabel(1(1)12) xline(6 7 8 9, lcolor(gs9) lwidth(vthin)) ///
	legend(col(1) ring(0) position(6) size(vsmall))
graph export "`figout'\supp_seasonality.svg", replace


restore



log close
