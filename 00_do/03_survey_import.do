/*******************************************************************************

Project Name		: 	Project Nourish
Purpose				:	import raw data into dta format 				
Author				:	Nicholus Tint Zaw
Date				: 	11/24/2022
Modified by			:


*******************************************************************************/

********************************************************************************
** Directory Settings **
********************************************************************************

do "00_dir_setting.do"

********************************************************************************
* import Sample Size Data *
********************************************************************************

import delimited using "$result/pn_2_samplelist.csv", clear 
 
rename fieldnamevillagetracteho  	geo_eho_vt_name
rename villagenameeho 				geo_eho_vill_name
rename townshippcode 				geo_town
rename vt_sir_num 					geo_vt
rename vill_sir_num 				geo_vill 

local mainvar township_name geo_eho_vt_name geo_eho_vill_name stratum num_cluster vill_samplesize sample_check

tempfile dfsamplesize
save `dfsamplesize', replace 
clear 



********************************************************************************
* import villages survey *
********************************************************************************
/*
import delimited using "$raw/pnourish_village_svy.csv", clear

* rename variable for proper data processing
rename _* *
//rename enu_end_note  enu_svyend_note 

* date/time formatting
lookfor _start _end starttime endtime submission

foreach var in `r(varlist)' {
    
	di "`var'"
	replace `var' = subinstr(`var', "T", " ", 1)
	split `var', p("+" ".")
	
	if "`var'" != "submission_time" {
	    drop `var'2
	} 
	
	gen double `var'_c = clock(`var'1, "20YMDhms" )
	format `var'_c %tc 
	order `var'_c, after(`var')
	
	capture drop `var'1
	capture drop `var'2
	capture drop `var'3
}

gen svy_date = dofc(starttime_c)
format svy_date %td
order svy_date, before(starttime_c)

* labeling  
gen org_name = "KEHOC" if org_team == 1
replace org_name = "YSDA" if org_team == 2

tostring superv_name, replace 
replace superv_name = "Thiri Aung" 			if superv_name == "1"
replace superv_name = "Saw Than Naing" 		if superv_name == "2"
replace superv_name = "Man Win Htwe" 		if superv_name == "3"
replace superv_name = "Nan Khin Hnin Thaw" 	if superv_name == "4"
replace superv_name = "Ma Nilar Tun" 		if superv_name == "5"
replace superv_name = "Saw Ku Mu Kay Htoo" 	if superv_name == "6"

// keep only final data colletion data 
keep if svy_date >= td(19dec2022) & !mi(svy_date)

save "$dta/pnourish_village_svy.dta", replace 
*/


********************************************************************************
* import household survey *
********************************************************************************

//import delimited using "$raw/pnourish_hh_svy.csv", clear

import excel using "$raw/pnourish_hh_svy.xlsx", describe

forvalue x = 1/`r(N_worksheet)' {
	
	local sheet_`x' `r(worksheet_`x')'
}

forvalue x = 1/`r(N_worksheet)' {
	
	import excel using "$raw/pnourish_hh_svy.xlsx", sheet("`sheet_`x''") firstrow clear 
	
	if `x' == 1 {
		
		* rename variable for proper data processing
		rename _* *
		rename enu_end_note  enu_svyend_note 
		lab var enu_svyend_note "enumerator survey end note"

		lookfor _start _end /*starttime endtime submission*/

		foreach var in `r(varlist)' {
			
			di "`var'"
			replace `var' = subinstr(`var', "T", " ", 1)
			split `var', p("+" ".")
			
			if "`var'" != "submission_time" {
				drop `var'2
			} 
			
			gen double `var'_c = clock(`var'1, "20YMDhms" )
			format `var'_c %tc 
			order `var'_c, after(`var')
			
			capture drop `var'1
			capture drop `var'2
			capture drop `var'3
		}

		gen svy_date = dofc(starttime)
		format svy_date %td
		order svy_date, before(starttime)


		* labeling  
		gen org_name = "KEHOC" if org_team == 1
		replace org_name = "YSDA" if org_team == 2

		tostring superv_name, replace 
		replace superv_name = "Thiri Aung" 			if superv_name == "1"
		replace superv_name = "Saw Than Naing" 		if superv_name == "2"
		replace superv_name = "Man Win Htwe" 		if superv_name == "3"
		replace superv_name = "Nan Khin Hnin Thaw" 	if superv_name == "4"
		replace superv_name = "Ma Nilar Tun" 		if superv_name == "5"
		replace superv_name = "Saw Ku Mu Kay Htoo" 	if superv_name == "6"

		* add village name and sample size info
		merge m:1 geo_town geo_vt geo_vill using `dfsamplesize', keepusing(`mainvar')

		drop if _merge == 2
		drop _merge 

		// keep only final data colletion data 
		keep if svy_date >= td(19dec2022) & !mi(svy_date)
		
		rename index _parent_index
		
		preserve 
		
			keep _parent_index
			
			tempfile _parent_index
			save `_parent_index', replace 
		
		restore 
		
	}
	else {
		
		merge m:1 _parent_index using `_parent_index'
		
		keep if _merge == 3
		
		drop _merge 
		
		
	}
	
	save "$dta/`sheet_`x''.dta", replace 
}


// Prepare one Wide format dataset 

use "$dta/PN_HH_Survey_FINAL.dta", clear

** add hh roster 
preserve
	use "$dta/grp_hh.dta", clear

	drop 	_index _index _parent_table_name _submission__id _submission__uuid ///
			_submission__submission_time _submission__validation_status ///
			_submission__notes _submission__status _submission__submitted_by ///
			_submission__tags
			
	order _parent_index

	destring test, replace

	rename * *_
	rename test_ test

	reshape wide *_ , i(_parent_index) j(test)

	tempfile grp_hh
	save `grp_hh', replace 

restore

merge 1:1 _parent_index using `grp_hh'

keep if _merge == 3

drop _merge 


** add child mom info 
preserve
	use "$dta/hh_child_mom_rep.dta", clear

	drop 	_index _index _parent_table_name _submission__id _submission__uuid ///
			_submission__submission_time _submission__validation_status ///
			_submission__notes _submission__status _submission__submitted_by ///
			_submission__tags
			
	order _parent_index

	destring cal_hh_cname_id, replace

	rename * *_
	rename cal_hh_cname_id_ cal_hh_cname_id

	reshape wide *_ , i(_parent_index) j(cal_hh_cname_id)

	tempfile hh_child_mom_rep
	save `hh_child_mom_rep', replace 

restore

merge 1:1 _parent_index using `hh_child_mom_rep'

keep if _merge == 3

drop _merge 



** add child iycf info
preserve
	use "$dta/grp_q2_5_to_q2_7.dta", clear

	drop 	_index _index _parent_table_name _submission__id _submission__uuid ///
			_submission__submission_time _submission__validation_status ///
			_submission__notes _submission__status _submission__submitted_by ///
			_submission__tags
			
	order _parent_index

	destring child_id_iycf, replace

	rename * *_
	rename child_id_iycf_ child_id_iycf

	reshape wide *_ , i(_parent_index) j(child_id_iycf)

	tempfile iycf
	save `iycf', replace 

restore

merge 1:1 _parent_index using `iycf'

keep if _merge == 3

drop _merge 



** add child health info
preserve
	use "$dta/child_vc_rep.dta", clear

	drop 	_index _index _parent_table_name _submission__id _submission__uuid ///
			_submission__submission_time _submission__validation_status ///
			_submission__notes _submission__status _submission__submitted_by ///
			_submission__tags
			
	order _parent_index

	destring child_id_health, replace

	rename * *_
	rename child_id_health_ child_id_health

	reshape wide *_ , i(_parent_index) j(child_id_health)

	tempfile child_vc_rep
	save `child_vc_rep', replace 

restore

merge 1:1 _parent_index using `child_vc_rep'

keep if _merge == 3

drop _merge 


** add mom health info
preserve
	use "$dta/anc_rep.dta", clear

	drop 	_index _index _parent_table_name _submission__id _submission__uuid ///
			_submission__submission_time _submission__validation_status ///
			_submission__notes _submission__status _submission__submitted_by ///
			_submission__tags
			
	order _parent_index

	destring women_id_pregpast, replace

	rename * *_
	rename women_id_pregpast_ women_id_pregpast

	reshape wide *_ , i(_parent_index) j(women_id_pregpast)

	tempfile anc_rep
	save `anc_rep', replace 

restore

merge 1:1 _parent_index using `anc_rep'

keep if _merge == 3

drop _merge 


** add mom covid info
preserve
	use "$dta/mom_covid_rpt.dta", clear

	drop 	_index _index _parent_table_name _submission__id _submission__uuid ///
			_submission__submission_time _submission__validation_status ///
			_submission__notes _submission__status _submission__submitted_by ///
			_submission__tags
			
	order _parent_index

	destring cal_mom_covid, replace

	rename * *_
	rename cal_mom_covid_ cal_mom_covid

	reshape wide *_ , i(_parent_index) j(cal_mom_covid)

	tempfile mom_covid_rpt
	save `mom_covid_rpt', replace 

restore

merge 1:1 _parent_index using `mom_covid_rpt'

keep if _merge == 3 | _merge == 1

drop _merge 


** add child muac info
preserve
	use "$dta/child_muac_rep.dta", clear

	drop 	_index _index _parent_table_name _submission__id _submission__uuid ///
			_submission__submission_time _submission__validation_status ///
			_submission__notes _submission__status _submission__submitted_by ///
			_submission__tags
			
	order _parent_index

	destring child_id_muac, replace

	rename * *_
	rename child_id_muac_ child_id_muac

	reshape wide *_ , i(_parent_index) j(child_id_muac)

	tempfile child_muac_rep
	save `child_muac_rep', replace 

restore

merge 1:1 _parent_index using `child_muac_rep'

keep if _merge == 3

drop _merge 


save "$dta/pnourish_hh_svy_wide.dta", replace  

