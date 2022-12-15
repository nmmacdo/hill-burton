* Project: Hill-Burton
* Topic: Data exploration
* Date Created: December 7, 2022
* Last Edited: December 14, 2022
* Name: Noah MacDonald

* Defining global directory variable (Change this line if you're not Noah)
global root "C:\Users\noahm\OneDrive - Emory University\Grad\ideas\hill-burton"

*** Comparing diff versions of the AHA data
// use "$root/data/raw/aha_1948_1969.dta", clear
// describe
// use "$root/data/raw/aha_clean48_06.dta", clear
// describe

*** Messing with the more recent version (last edited 2022-07-26)
use "$root/data/raw/aha_1948_1969.dta", clear
* Creating common fips codes
tostring fcounty1, replace
replace fcounty1 = "0" + fcounty1 if strlen(fcounty1)==4
* Saving processed AHA file
save "$root/data/processed/aha_48_69.dta", replace
* Note: Still need to interpolate values for 1954: no AHA pub that year

*** Looking at how we might merge with the Hill-Burton funding data
use "$root/data/raw/hbprtemp.dta", clear
* Creating common fips codes
replace fcounty1 = "0" + fcounty1 if strlen(fcounty1)==4
* Keeping data for our clean AHA years
keep if year >= 1948 & year <= 1969
* Replacing missing values with 0s
replace hbfund_np = 0 if missing(hbfund_np)
replace hbfund_pb = 0 if missing(hbfund_pb)
replace hbbeds_np = 0 if missing(hbbeds_np)
replace hbbeds_pb = 0 if missing(hbbeds_pb)
replace totalcost_np = 0 if missing(totalcost_np)
replace totalcost_pb = 0 if missing(totalcost_pb)
* Creating common variables for HB funds, beds, and total costs
gen hbfund = hbfund_np + hbfund_pb
gen hbbeds = hbbeds_np + hbbeds_pb
gen totalcost = totalcost_np + totalcost_pb
drop hbfund_np hbfund_pb hbbeds_np hbbeds_pb totalcost_np totalcost_pb
* Saving processed HBPR file
save "$root/data/processed/hbpr.dta", replace
* Note: Says we have 2172 funded counties, 66 more than the paper reports

*** And the area resource files
use "$root/data/raw/arftemp.dta", clear
* Creating common fips codes
tostring fcounty1, replace
replace fcounty1 = "0" + fcounty1 if strlen(fcounty1)==4
* Keeping data for our clean AHA years
keep if year >= 1948 & year <= 1969
* Dropping data that was already used to interpolate
drop pop nfmd POP65 employm nwpop fam urbpop POPLT5 popdens medfaminc iemploy
save "$root/data/processed/arf.dta", replace

*** Merge attempt #1
// use "$root/data/processed/aha_48_69.dta", clear
// merge m:1 fcounty1 year using "$root/data/processed/arf.dta", keep(match) ///
// nogen
// /* Note: No ARF data for Weston County, Wyoming. 18 obs dropped. Also, 17,553
// ARF obs dropped that were not present in the AHA data. */ 
// sort fcounty1 newid year
// merge m:1 fcounty1 year using "$root/data/processed/hbpr.dta", gen(merge2)
// /* Note: Of 90540 obs, 89833 in master only, 18895 matched, and 677 in hbpr 
// only. The 677 in hbpr only are likely funds meant for building the first 
// hospital in a county */ 
// sort fcounty1 newid year
// * 109,405 obs

*** Fun new variables!
// gen pct_nw = inwpop / ipop // Problem: No race data for the initial funding obs

*** Merge attempt #2 (Trying to keep more data this time around)
// use "$root/data/processed/aha_48_69.dta", clear
// merge m:1 fcounty1 year using "$root/data/processed/hbpr.dta", gen(merge1)
// sort fcounty1 newid year
// merge m:1 fcounty1 year using "$root/data/processed/arf.dta", gen(merge2)
// sort fcounty1 newid year
// * 126,407 obs
// count if merge1==2 & merge2==1
// * There are 128 obs that are initial hospital funds w/o demographic data

*** Merge attempt #3 (County-level this time around)
use "$root/data/processed/aha_48_69.dta", clear
* Collapsing data to the county level
collapse (sum) bdtot admtot paytot fte exptot (mean) rural, by(fcounty1 year)
/* Note: No idea what we lost by not using cntrl as a by variable, and I 
couldn't replicate the count of hospitals command that they used? This is the 
step we'd like to avoid down the line to get hospital-level data */
merge 1:1 fcounty1 year using "$root/data/processed/hbpr.dta", gen(merge1)
sort fcounty1 year
replace hbfund = 0 if missing(hbfund)
replace hbbeds = 0 if missing(hbbeds)
replace totalcost = 0 if missing(totalcost)
* There are 675 obs in hbpr that aren't in AHA: Probably new hospital funds?
merge 1:1 fcounty1 year using "$root/data/processed/arf.dta", gen(merge2) ///
keep(master matched)
/* Note: Only keeping counties that have a hospital at some point in the data. 
This brings us from 3080 counties to 2601. */ 
sort fcounty1 year

*** Creating variables for analysis
* Creating indicator for if a county is ever allocated Hill-Burton funds
by fcounty1: gen treat_ever = 1 if sum(hbfund) > 0
replace treat_ever = 0 if missing(treat_ever)
* Creating indicator for the year(s) a county recieves Hill-Burton funds
by fcounty1 year: gen treat_year = 1 if hbfund > 0 & !missing(hbfund)
replace treat_year = 0 if missing(treat_year)
* Creating running total of Hill-Burton funds by county
by fcounty1: gen hbfund_run = sum(hbfund) if treat_ever==1
replace hbfund_run = 0 if missing(hbfund_run)
* Creating percentage of county population that is nonwhite
gen pct_nw = inwpop/ipop

*** Saving for US map graphs in R
* County-level funding data
preserve
keep if year==1969
keep fcounty1 hbfund pct_nw ipop
rename fcounty1 fips
gen hbfund_pc = hbfund/ipop
export delimited using "$root/data/final/county_plot_data.csv", replace quote
restore
* State-level funding data
preserve
gen fips_state = substr(fcounty1, 1, 2)
keep if year==1969
keep fips_state hbfund pct_nw ipop
rename fips_state fips
collapse (sum) hbfund ipop (mean) pct_nw, by(fips)
gen hbfund_pc = hbfund/ipop
export delimited using "$root/data/final/state_plot_data.csv", replace quote
restore
* Another look at state-level funding using only the Hill-Burton register
use "$root/data/raw/hbprtemp.dta", clear
replace fcounty1 = "0" + fcounty1 if strlen(fcounty1)==4
replace hbfund_np = 0 if missing(hbfund_np)
replace hbfund_pb = 0 if missing(hbfund_pb)
replace hbbeds_np = 0 if missing(hbbeds_np)
replace hbbeds_pb = 0 if missing(hbbeds_pb)
replace totalcost_np = 0 if missing(totalcost_np)
replace totalcost_pb = 0 if missing(totalcost_pb)
gen hbfund = hbfund_np + hbfund_pb
gen hbbeds = hbbeds_np + hbbeds_pb
gen totalcost = totalcost_np + totalcost_pb
gen fips_state = substr(fcounty1, 1, 2)
rename fips_state fips // to fit the usmap package in R
collapse (sum) hbfund hbbeds totalcost, by(fips year)
collapse (sum) hbfund hbbeds totalcost, by(fips)
export delimited using "$root/data/final/state_funding_totals.csv", replace ///
quote

* Using only the ARF files to get nonwhite population data for 1948
// use "$root/data/raw/arftemp.dta", clear
// tostring fcounty1, replace
// replace fcounty1 = "0" + fcounty1 if strlen(fcounty1)==4
// keep if year==1948
// keep year fcounty1 inwpop ipop 
// rename fcounty1 fips
// gen pct_nw = inwpop/ipop
// export delimited using "$root/data/final/county_nonwhite_pop.csv", replace ///
// quote
// gen fips_state = substr(fips, 1, 2)
// drop fips
// rename fips_state fips // to fit the usmap package in R
// collapse (sum) inwpop ipop, by(fips)
// gen pct_nw = inwpop/ipop
* Apparently there are some crazy outliers in inwpop so just disregard all this


*** Looking only at counties that recieved Hill-Burton funds
// use "$root/data/processed/hbpr.dta", clear
// merge 1:1 fcounty1 year using "$root/data/processed/arf.dta", ///
// keep(master match) gen(merge1)
* 130 obs from master not matched: 112 in 1954 (no 1954 obs from arf)
* Remaining 18 are from VA (excluded) and Weston County, Wyoming (missing?)

*** Looking at raw ARF files downloaded from ICPSR
// import delimited using "$root/data/raw/ahrf2021.asc", clear ///
// delimiters("\t") 