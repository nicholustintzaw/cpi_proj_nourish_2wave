/*******************************************************************************

Project Name		: 	Project Nourish
Purpose				:	2nd round data collection: MASTER 			
Author				:	Nicholus Tint Zaw
Date				: 	03/01/2023
Modified by			:


*******************************************************************************/

********************************************************************************
** Directory Settings **
********************************************************************************

do "$do/00_dir_setting.do"



	****************************************************************************
	* (1): HH Roster *
	****************************************************************************

	do "$hhcleaning/00_HH_Roster.do"

	****************************************************************************
	* (2): HH Level Data *
	****************************************************************************

	do "$hhcleaning/01_HH_cleaning.do"


	****************************************************************************
	* (3): Child IYCF Data *
	****************************************************************************

	do "$hhcleaning/02_Child_IYCF_cleaning.do"
	
	****************************************************************************
	* (4): Child Health Data *
	****************************************************************************

	do "$hhcleaning/03_Child_Health_cleaning.do"
	
	****************************************************************************
	* (5): Child MUAC Module *
	****************************************************************************
	
	do "$hhcleaning/04_Child_MUAC_cleaning.do"
	
	****************************************************************************
	* (6): Mom Health Module *
	****************************************************************************
	
	do "$hhcleaning/05_Mom_Health_cleaning.do"
	
// END HERE 
