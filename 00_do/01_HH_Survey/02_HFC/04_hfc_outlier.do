/*******************************************************************************

Project Name		: 	Project Nourish
Purpose				:	2nd round data collection: missing check 			
Author				:	Nicholus Tint Zaw
Date				: 	11/24/2022
Modified by			:


*******************************************************************************/

********************************************************************************
** Directory Settings **
********************************************************************************

do "$do/00_dir_setting.do"

********************************************************************************
* household survey *
********************************************************************************

*Adding title table 1
clear
set obs 1
gen title = ""
replace title = "TABLE 1: % OUTLIER ISSUES" in 1
export excel title using "$out/03_hfc_hh_outlier.xlsx", sheet("01_SUMMARY") sheetreplace cell(A1) 

*Adding title table 2
clear
set obs 1
gen title = ""
replace title = "TABLE 2:  % OUTLIER BY ENUMERATOR" in 1
export excel title using "$out/03_hfc_hh_outlier.xlsx", sheet("01_SUMMARY") sheetmodify cell(A6) 
		
		
use "$dta/pnourish_hh_svy_wide.dta", clear 

gen tot_obs = _N
bysort org_name svy_team enu_name: gen enu_tot_obs = _N 


// outlier per variables 

global interestedvar 	respd_age respd_1stpreg_age respd_chid_num hh_tot_num ///
						hh_mem_age_* hh_mem_u5num_* hh_mem_u2num_* ///
						child_eibf_hrs_* child_eibf_days_* ///
						child_bms_freq_* child_milk_freq_* child_mproduct_freq_* ///
						child_yogurt_num_* child_food_freq_* ///
						child_diarrh_notice_* child_cough_notice_* child_fever_notice_* ///
						child_birthwt_kg_* child_birthwt_lb_* child_birthwt_oz_* ///
						mom_meal_freq_* anc_*_visit_* anc_iron_count_* anc_rion_length_oth_* ///
						pnc_checktime_* pnc_*_visit_* pnc_bone_months_* pnc_bone_weeks_* ///
						nbc_*_visit_* ///
						mom_covid_doses ///
						house_room water_time* d3_inc_lmth prgexp_freq_* ///
						child_muac_1 child_muac_2 child_muac_3 child_muac_4 child_muac_5 ///
						child_muac_6 child_muac_7 child_muac_8 child_muac_9 child_muac_10 ///
						child_muac_11 child_muac_12

    
foreach v of varlist $interestedvar {
	//capture confirm numeric variable `v'
	
	destring `v', replace 
	
	//if !_rc {
			sum `v', d
			
			if `r(N)' > 0 {
				
				gen `v'_mean = `r(mean)'
			    
				gen `v'_sd = 3 * `r(sd)'
				gen `v'_ts = (`r(mean)' + `v'_sd)
				
				gen `v'_ol = (`v' > `v'_ts)
				replace `v'_ol = .m if mi(`v')
				drop `v'_ts `v'_sd
				tab `v'_ol
				
				order `v'_ol, after(`v')
				gen var_`v' = `v'
				drop `v'
			}
	//}
}

egen tot_ol = rowtotal(*ol)

keep if tot_ol > 0 

// export table 
* overall figure 
gen tot_flag 			= _N
gen tot_flag_shared 	= round(tot_flag/tot_obs, 0.001)

preserve

keep if _n == 1
keep tot_obs tot_flag tot_flag_shared 
order tot_obs tot_flag tot_flag_shared

lab var tot_obs 			"Total obs"
lab var tot_flag 			"Total outlier obs"
lab var tot_flag_shared		"Outlier shared"

export excel using "$out/03_hfc_hh_outlier.xlsx", sheet("01_SUMMARY") firstrow(varlabels) cell(A2) keepcellfmt sheetmodify

restore 



* by enumerator figure 
preserve 

bysort org_name svy_team enu_name: gen enu_flag_num = _N 
bysort org_name svy_team enu_name: keep if _n == 1

gen enu_flag_shared = round(enu_flag_num/enu_tot_obs, 0.001)

keep enu_flag_num enu_flag_shared enu_tot_obs enu_name svy_team org_name

rename enu_flag_* *_enu_flag
rename enu_tot_obs tot_obs_enu_flag

gen sir = _n 

reshape long num_ tot_obs_ shared_ , i(sir) j(var) string  

replace sir = _n 
drop var 

order org_name svy_team enu_name tot_obs_ num_ shared_ 

lab var org_name 	"Organization Name"
lab var svy_team 	"Survey Team Number"
lab var enu_name 	"Enumerator Name"
lab var tot_obs_ 	"Total survey by enumerator"
lab var num_ 		"Total outlier obs by enumerator"
lab var shared_ 	"Shared of outlier obs by enumerator"

export excel using "$out/03_hfc_hh_outlier.xlsx", sheet("01_SUMMARY") firstrow(varlabels) cell(A2) keepcellfmt sheetmodify

restore 

* detail figure 
preserve 
gen sir = _n

keep *_ol *_mean var_* sir uuid enu_name svy_team org_name

rename *_ol ol_*
rename *_mean mean_*

reshape long ol_ mean_ var_ , i(sir) j(var_name) string 

drop sir 

rename var_ 	values
rename ol_ 		outlier_yes
rename mean_ 	mean

keep if outlier_yes == 1

order org_name svy_team enu_name uuid var_name values mean outlier_yes

lab var org_name 		"Organization name"
lab var svy_team 		"Survey Team"
lab var enu_name 		"Enumerator"
lab var uuid 			"Sruvey key - uuid"
lab var var_name 		"Variable name"
lab var values 			"Response values"
lab var mean 			"Mean value"
lab var outlier_yes		"Outlier (yes)"

// export table
if _N > 0 {
	
	export excel using "$out/03_hfc_hh_outlier.xlsx", sheet("02_DETAILED_OBS") firstrow(varlabels) keepcellfmt sheetreplace
}

 
restore 

* END here 

