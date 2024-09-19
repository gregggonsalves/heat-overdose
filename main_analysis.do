capture log close
clear all
set more off, perm

* Set directories

cd "<working directory>"

local data "<Analytic data>"

local out "<Output>"
local figout "<Figure output>"
local tempfig "<Temporary files>"

* Log file

log using "`out'\main_analysis.log", replace

* Load data

use "`data'\analytic_data.dta", clear
tab year, missing

******************************************* Main Results

* REGRESSIONS:

*** All drug overdoses
*** By select types of drugs
*** Single vs polysubstance use

foreach outcome in rate_drugod_all ///
	///
	rate_drugod_opioids rate_drugod_natsemisyn rate_drugod_heroin rate_drugod_synth ///
	rate_drugod_cocaine rate_drugod_psychostim ///
	///
	rate_drugod_only_opioids rate_drugod_only_cocaine rate_drugod_only_psy ///
	rate_drugod_comb_op_coc rate_drugod_comb_op_psy rate_drugod_comb_coc_psy rate_drugod_comb_all {

	reghdfe `outcome' avg_heatindex [aw=pop_total], ///
		absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
	estimates store M`outcome'
	
}


* FIGURE:

coefplot (Mrate_drugod_all \ ///
	///
	Mrate_drugod_opioids \ Mrate_drugod_natsemisyn \ Mrate_drugod_heroin \ Mrate_drugod_synth \ ///
	Mrate_drugod_cocaine \ Mrate_drugod_psychostim \ ///
	///
	Mrate_drugod_only_opioids \ Mrate_drugod_only_cocaine \ Mrate_drugod_only_psy \  ///
	Mrate_drugod_comb_op_coc \ Mrate_drugod_comb_op_psy \ Mrate_drugod_comb_coc_psy \ Mrate_drugod_comb_all ///
	), ///
	keep(avg_heatindex) ///
	aseq swapnames ///
	coeflabels(Mrate_drugod_all = "All drug overdoses" ///	
		///
		Mrate_drugod_opioids = "Any opioid"  ///
		Mrate_drugod_natsemisyn = "Natural and semisynthetic opioids" ///
		Mrate_drugod_heroin = "Heroin"  ///
		Mrate_drugod_synth = "Synthetic opioids" ///
		Mrate_drugod_cocaine = "Cocaine"  ///
		Mrate_drugod_psychostim = "Psychostimulants" ///
		///
		Mrate_drugod_only_opioids = "Opioids only" ///
		Mrate_drugod_only_cocaine = "Cocaine only"  ///
		Mrate_drugod_only_psy = "Psychostimulants only"  ///
		///
		Mrate_drugod_comb_op_coc = "Opioids + Cocaine" ///
		Mrate_drugod_comb_op_psy = "Opioids + Psychostimulants"  ///
		Mrate_drugod_comb_coc_psy = "Cocaine + Psychostimulants"  ///
		Mrate_drugod_comb_all = "Opioids + Cocaine + Psychostimulants" ///
		) ///
	xline(0, lcolor(black)) ///
	xtitle("Effect of one degree C increase on deaths per 100,000") ///
	headings(Mrate_drugod_all = "{bf:Main results:}" ///
		Mrate_drugod_opioids = "{bf:By select drug types:}" ///
		Mrate_drugod_only_opioids = "{bf:Single drugs:}" ///
		Mrate_drugod_comb_op_coc = "{bf:Polysubstance use:}" ///
		) ///
	mcolor(black) ciopts(lcolor(black))
graph export "`figout'\fig_main.svg", replace
graph export "`figout'\Figure1.tif", replace



******************************************* Overdose rates of demographic subgroups

* REGRESSIONS:
foreach outcome in rate_drugod_all ///
	rate_drugod_dem_male rate_drugod_dem_female ///
	rate_drugod_dem_age0to29 rate_drugod_dem_age30to59 rate_drugod_dem_age60plus ///
	rate_drugod_dem_nhblack rate_drugod_dem_hisp rate_drugod_dem_nhwhite ///
	{

	reghdfe `outcome' avg_heatindex [aw=pop_total], ///
		absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
	estimates store D`outcome'
	
}

* FIGURE:
coefplot (Drate_drugod_all \ ///
	Drate_drugod_dem_male \ Drate_drugod_dem_female \ ///
	Drate_drugod_dem_age0to29 \ Drate_drugod_dem_age30to59 \ Drate_drugod_dem_age60plus \ ///
	Drate_drugod_dem_nhblack \ Drate_drugod_dem_hisp \ Drate_drugod_dem_nhwhite  ///
	), ///
	keep(avg_heatindex) ///
	aseq swapnames ///
	coeflabels(Drate_drugod_all = "All people" ///
		///
		Drate_drugod_dem_male = "Male"  ///
		Drate_drugod_dem_female = "Female" ///
		Drate_drugod_dem_age0to29 = "Aged 0 to 29"  ///
		Drate_drugod_dem_age30to59 = "Aged 30 to 59" ///
		Drate_drugod_dem_age60plus = "Aged 60 and older"  ///
		Drate_drugod_dem_nhblack = "Black (non-Hispanic)" ///
		Drate_drugod_dem_hisp = "Hispanic (any race)"  ///
		Drate_drugod_dem_nhwhite = "White (non-Hispanic)" ///		
		) ///
	xline(0, lcolor(black)) ///
	xtitle("Effect of one degree C increase on deaths per 100,000") ///
	headings(Drate_drugod_all = "{bf:Main results:}" ///
		Drate_drugod_dem_male = "{bf:By sex:}" ///
		Drate_drugod_dem_age0to29 = "{bf:By age group:}" ///
		Drate_drugod_dem_nhblack = "{bf:By race/Hispanic origin:}" ///
		) ///
	mcolor(black) ciopts(lcolor(black))
graph export "`figout'\fig_supp_demsubgroups.svg", replace




******************************************* Effect sizes compared to other causes of death

* REGRESSIONS:

foreach outcome in rate_drugod_all ///
	///
	rate_any_death ///
	rate_drugodoth_natheat rate_drugodoth_dehyd ///
	rate_drugodoth_cardiovasc rate_drugodoth_clrd ///
	rate_drugoddesp_suicide rate_drugoddesp_asslt ///
	{

	reghdfe `outcome' avg_heatindex [aw=pop_total], ///
		absorb(i.fips_county#i.month i.state#i.year) vce(cluster i.fips_county#i.month)
	estimates store O`outcome'
	
}


* FIGURE:

coefplot (Orate_drugod_all \ ///
	///
	Orate_any_death \ ///
	Orate_drugodoth_natheat \ Orate_drugodoth_dehyd \ ///
	Orate_drugodoth_cardiovasc \ Orate_drugodoth_clrd \ ///
	Orate_drugoddesp_suicide \ Orate_drugoddesp_asslt \ ///
	), ///
	keep(avg_heatindex) ///
	aseq swapnames ///
	coeflabels(Orate_drugod_all = "Drug overdose deaths" ///
		///
		Orate_any_death = "All-cause mortality" ///
		Orate_drugodoth_natheat = "Natural heat-related causes" ///	
		Orate_drugodoth_dehyd = "Dehydration-related causes" ///			
		Orate_drugodoth_cardiovasc = "All cardiovascular causes" ///
		Orate_drugodoth_clrd = "Chronic lower respiratory causes"  ///
		Orate_drugoddesp_suicide = "Suicide"  ///
		Orate_drugoddesp_asslt = "Assault" ///
		) ///
	xline(0, lcolor(black)) ///
	xtitle("Effect of one degree C increase on deaths per 100,000") ///
	headings(Orate_drugod_all = "{bf:Main results:}" ///
		Orate_any_death = "{bf: Other causes of death:}" ///
		) ///
	mcolor(black) ciopts(lcolor(black))
graph export "`figout'\fig_othercauses.svg", replace
graph export "`figout'\Figure2.tif", replace


******************************************* Output estimates into tables


cd `tempfig'
esttab M* D* O* using main_estimates.csv, replace ///
		cells(b ci(par) p(par)) ///
		level(95) ///
		star(* 0.05 ** 0.01 *** 0.001) ///
		order(avg_heatindex)
estimates clear

insheet using "`tempfig'\main_estimates.csv", clear
export excel "`figout'\main_estimates.xlsx", replace sheet("Main estimates")



log close
