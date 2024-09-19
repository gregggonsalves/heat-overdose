capture log close
clear all
set more off, perm

* Set directories

cd "<working directory>"

local data "<Analytic data>"

local out "<Output>"
local figout "<Figure output>"

* Log file

log using "`out'\alt_regressions.log", replace

* Load data

use "`data'\analytic_data.dta", clear
tab year, missing

******************************************* Binned model

*** Generate binned heat index variables
gen bin_heatindex_many=.
sum avg_heatindex, detail
*****> Bin 1 is <16 deg C (at least 1000 obs)
local min=16
replace bin_heatindex_many=1 if (avg_heatindex<(`min'))&bin_heatindex_many==.
*****> Remaining 10 bins are in 3 deg C intervals
forvalues b=2/11 {
	replace bin_heatindex_many=`b' if (avg_heatindex<(`min'+3))&bin_heatindex_many==.
	local min=`min'+3
}
*****> Check values for labels/enough obs
forvalues b=1/11 {
	display "Bin number = `b'"
	sum avg_heatindex if bin_heatindex_many==`b'
}

tab bin_heatindex_many, missing


*** Regression (omit Bin 1)
reghdfe rate_drugod_all i.bin_heatindex_many [aw=pop_total], ///
	absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)

*** Plot coefficients
coefplot, ///
	keep(*.bin_heatindex_many) baselevels noci vertical ///
	rename(1.bin_heatindex_many = "7-15" ///
		2.bin_heatindex_many = "16-18" ///
		3.bin_heatindex_many = "19-21" ///
		4.bin_heatindex_many = "22-24" ///
		5.bin_heatindex_many = "25-27" ///
		6.bin_heatindex_many = "28-30" ///
		7.bin_heatindex_many = "31-33" ///
		8.bin_heatindex_many = "34-36" ///
		9.bin_heatindex_many = "37-39" ///
		10.bin_heatindex_many = "40-42" ///
		11.bin_heatindex_many = "43-45") ///
	mcolor(black) ciopts(lcolor(black)) ///
	xtitle("Average maximum heat index (degrees Celsius)") ///
	ytitle("All drug overdose deaths per 100,000")
graph export "`figout'\supp_binned.svg", replace
	
	
log close



