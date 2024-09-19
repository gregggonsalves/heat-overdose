capture log close
clear all
set more off, perm

* Set directories

cd "<working directory>"

local data "<Analytic data>"
local temp "<Temporary files>"
local map "<Mapping data - cb_2020_us_county_20m>"

local out "<Output>"
local figout "<Figure output>"

* Log file

log using "`out'\mapping.log", replace

* Load data

use "`data'\analytic_data.dta", clear
tab year, missing

********************************* Mapping heat index

* Average for analytic sample

preserve

*** Collapse and get means by county
*** Unweighted (aka NOT weighted by annual population within county)
rename fips_county fips_county_notstring
rename fips_county_string fips_county
collapse (mean) avg_heatindex, by(fips_county)

*** Merge in map file
gen GEOID=fips_county
sort GEOID
merge 1:1 GEOID using "`map'/countydb_clean.dta"
drop _merge

*** Map for continental US
format avg_heatindex %12.1f
spmap avg_heatindex using "`map'\countycoord.dta", id(id) ///
	fcolor(Reds) title("Means of the heat index by county")
graph export "`figout'\map_avg_heatindex.svg", replace

restore


* Standard deviation for analytic sample

preserve

*** Collapse and get standard deviation by county and month
*** Unweighted (aka NOT weighted by annual population within county)
rename fips_county fips_county_notstring
rename fips_county_string fips_county
collapse (sd) avg_heatindex, by(fips_county month)

*** Collapse over four months
collapse (mean) avg_heatindex, by(fips_county)

*** Merge in map file
gen GEOID=fips_county
sort GEOID
merge m:1 GEOID using "`map'/countydb_clean.dta"
drop _merge

* Generate map - continental US

format avg_heatindex %12.1f
spmap avg_heatindex using "`map'\countycoord.dta", id(id) ///
		fcolor(Greens) title("Variation in the heat index by county")
graph export "`figout'\map_avg_heatindex_sd.svg", replace

restore



log close
