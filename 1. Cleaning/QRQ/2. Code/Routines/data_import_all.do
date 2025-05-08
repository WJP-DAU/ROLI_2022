/*=================================================================================================================
Project:		QRQ importing 
Routine:		QRQ Data Cleaning and Harmonization 2022 (master do file)
Author(s):		Natalia Rodriguez (nrodriguez@worldjusticeproject.org)
Dependencies:  	World Justice Project
Creation Date:	May, 2025

Description:
This do file imports the original datasets for 2022.

=================================================================================================================*/

/*=================================================================================================================
					I. Importing the data
=================================================================================================================*/

/*-----------*/
/* 1. Civil  */
/*-----------*/

import delimited using "$path2data/1. Original/CC long.csv"
drop *_2021
gen longitudinal=1
order sg_id
save "$path2data/1. Original/cc_final_long.dta", replace

clear
import delimited using "$path2data/1. Original/CC reg.csv"
rename (cc_g34a cc_35g) (cc_q34a cc_q35g)
gen longitudinal=0

// Append the regular and the longitudinal databases
append using "$path2data/1. Original/cc_final_long.dta"
drop cc_leftout-cc_referral3_language ivstatus
gen question="cc"

* Check for experts without id
count if sg_id==.

rename sg_id id_original
rename vlanguage language
rename wjp_country country

* Create ID
egen id=concat(language longitudinal id_original), punct(_)
egen id_alex=concat(question id), punct(_)
drop id id_original

/* These 3 lines are for incorporating 2021 data */
gen year=2022
gen regular=0
drop if language=="Last_Year"

order question year regular longitudinal id_alex language country wjp_login

/* Drop new variables for Andrei added in 2017 (Not used for the Index) */
drop cc_q17a cc_q17b cc_q18a cc_q18b


/* Recoding question 26 */
foreach var of varlist cc_q26a-cc_q26k {
	replace `var'=. if `var'==99
}

/* Recoding questions */
foreach var of varlist cc_q20a cc_q20b cc_q21 {
	replace `var'=1 if `var'==0
	replace `var'=2 if `var'==5
	replace `var'=3 if `var'==25
	replace `var'=4 if `var'==50
	replace `var'=5 if `var'==75
	replace `var'=6 if `var'==100
}
/* Changing 9 for missing */
foreach var of varlist cc_q1- cc_q5e {
	replace `var'=. if `var'==9
}

foreach var of varlist cc_q7a-cc_q25  {
	replace `var'=. if `var'==9
}

foreach var of varlist cc_q27- cc_q40b{
	replace `var'=. if `var'==9
}

/* Change names to match the MAP file and the GPP */

drop if country=="Burundi"

replace country="Congo, Rep." if country=="Republic of Congo"
replace country="Korea, Rep." if country=="Republic of Korea"
replace country="Egypt, Arab Rep." if country=="Egypt"
replace country="Iran, Islamic Rep." if country=="Iran"
replace country="St. Kitts and Nevis" if country=="Saint Kitts and Nevis"		
replace country="St. Lucia" if country=="Saint Lucia"
replace country="St. Vincent and the Grenadines" if country=="Saint Vincent and the Grenadines"
replace country="Cote d'Ivoire" if country=="Ivory Coast"
replace country="Congo, Dem. Rep." if country=="Democratic Republic of Congo"
replace country="Gambia" if country=="The Gambia"

replace country="Kyrgyz Republic" if country=="Kyrgyzstan"
replace country="North Macedonia" if country=="Macedonia, FYR"
replace country="Russian Federation" if country=="Russia"
replace country="Venezuela, RB" if country=="Venezuela"

save "$path2data/1. Original/cc_final.dta", replace
erase "$path2data/1. Original/cc_final_long.dta"

/*--------------*/
/* 2. Criminal  */
/*--------------*/

clear
import delimited using "$path2data/1. Original/CJ long.csv"
drop *_2021
gen longitudinal=1
order sg_id
drop cj_leftout-cj_referral3_language ivstatus
save "$path2data/1. Original/cj_final_long.dta", replace

clear
import delimited using "$path2data/1. Original/CJ reg.csv"
gen longitudinal=0
drop cj_leftout-cj_referral3_language ivstatus

// Append the regular and the longitudinal databases
append using "$path2data/1. Original/cj_final_long.dta"
gen question="cj"

* Check for experts without id
count if sg_id==.

rename sg_id id_original
rename vlanguage language
rename wjp_country country

* Create ID
egen id=concat(language longitudinal id_original), punct(_)
egen id_alex=concat(question id), punct(_)
drop id id_original

/* These 3 lines are for incorporating 2021 data */
gen year=2022
gen regular=0
drop if language=="Last_Year"

order question year regular longitudinal id_alex language country wjp_login

/* Change 99 for missing */
foreach var of varlist cj_q16a- cj_q21k cj_q27a cj_q27b cj_q37a-cj_q37d cj_q43a-cj_q43h  {
	replace `var'=. if `var'==99
}

/* Changing 9 for missing */
foreach var of varlist cj_q1- cj_q15 cj_q17 {
	replace `var'=. if `var'==9
}

/* Recoding questions */
foreach var of varlist cj_q22a-cj_q25c cj_q28 {
	replace `var'=1 if `var'==0
	replace `var'=2 if `var'==5
	replace `var'=3 if `var'==25
	replace `var'=4 if `var'==50
	replace `var'=5 if `var'==75
	replace `var'=6 if `var'==100
}

foreach var of varlist cj_q22a-cj_q36d cj_q38-cj_q42h {
	replace `var'=. if `var'==9
}

/* Change names to match the MAP file and the GPP */

drop if country=="Burundi"

replace country="Congo, Rep." if country=="Republic of Congo"
replace country="Korea, Rep." if country=="Republic of Korea"
replace country="Egypt, Arab Rep." if country=="Egypt"
replace country="Iran, Islamic Rep." if country=="Iran"
replace country="St. Kitts and Nevis" if country=="Saint Kitts and Nevis"		
replace country="St. Lucia" if country=="Saint Lucia"
replace country="St. Vincent and the Grenadines" if country=="Saint Vincent and the Grenadines"
replace country="Cote d'Ivoire" if country=="Ivory Coast"
replace country="Congo, Dem. Rep." if country=="Democratic Republic of Congo"
replace country="Gambia" if country=="The Gambia"

replace country="Kyrgyz Republic" if country=="Kyrgyzstan"
replace country="North Macedonia" if country=="Macedonia, FYR"
replace country="Russian Federation" if country=="Russia"
replace country="Venezuela, RB" if country=="Venezuela"

save "$path2data/1. Original/cj_final.dta", replace
erase "$path2data/1. Original/cj_final_long.dta"

/*-----------*/
/* 3. Labor  */
/*-----------*/

clear
import delimited using "$path2data/1. Original/LB long.csv"
drop *_2021
gen longitudinal=1
order sg_id
drop lb_teach lb_leftout-lb_referral3_language ivstatus
save "$path2data/1. Original/lb_final_long.dta", replace

clear
import delimited using "$path2data/1. Original/LB reg.csv" 

gen longitudinal=0
drop lb_teach lb_leftout-lb_referral3_language ivstatus

// Append the regular and the longitudinal databases
append using "$path2data/1. Original/lb_final_long.dta"
gen question="lb"

* Check for experts without id
count if sg_id==.

rename sg_id id_original
rename vlanguage language
rename wjp_country country

* Create ID
egen id=concat(language longitudinal id_original), punct(_)
egen id_alex=concat(question id), punct(_)
drop id id_original

/* These 3 lines are for incorporating 2021 data */
gen year=2022
gen regular=0
drop if language=="Last_Year"

order question year regular longitudinal id_alex language country wjp_login

/* Recoding questions */
foreach var of varlist lb_q11a lb_q11b lb_q12 {
	replace `var'=1 if `var'==0 
	replace `var'=2 if `var'==5
	replace `var'=3 if `var'==25
	replace `var'=4 if `var'==50
	replace `var'=5 if `var'==75
	replace `var'=6 if `var'==100
}

/* Changing 9 for missing */
foreach var of varlist lb_q1a- lb_q4d {
	replace `var'=. if `var'==9
}

foreach var of varlist lb_q6a- lb_q28b {
	replace `var'=. if `var'==9
}

/* Change names to match the MAP file and the GPP */

drop if country=="Burundi"

replace country="Congo, Rep." if country=="Republic of Congo"
replace country="Korea, Rep." if country=="Republic of Korea"
replace country="Egypt, Arab Rep." if country=="Egypt"
replace country="Iran, Islamic Rep." if country=="Iran"
replace country="St. Kitts and Nevis" if country=="Saint Kitts and Nevis"		
replace country="St. Lucia" if country=="Saint Lucia"
replace country="St. Vincent and the Grenadines" if country=="Saint Vincent and the Grenadines"
replace country="Cote d'Ivoire" if country=="Ivory Coast"
replace country="Congo, Dem. Rep." if country=="Democratic Republic of Congo"
replace country="Gambia" if country=="The Gambia"

replace country="Kyrgyz Republic" if country=="Kyrgyzstan"
replace country="North Macedonia" if country=="Macedonia, FYR"
replace country="Russian Federation" if country=="Russia"
replace country="Venezuela, RB" if country=="Venezuela"

save "$path2data/1. Original/lb_final.dta", replace
erase "$path2data/1. Original/lb_final_long.dta"

/*------------------*/
/* 4. Public Health */
/*------------------*/

clear
import delimited using "$path2data/1. Original/PH long.csv"
drop *_2021
gen longitudinal=1
order sg_id
drop ph_leftout-ph_referral3_language ivstatus
save "$path2data/1. Original/ph_final_long.dta", replace

clear
import delimited using "$path2data/1. Original/PH reg.csv"
drop ph_leftout-ph_referral3_language ivstatus
gen longitudinal=0

// Append the regular and the longitudinal databases
append using "$path2data/1. Original/ph_final_long.dta"
gen question="ph"

* Check for experts without id
count if sg_id==.

rename sg_id id_original
rename vlanguage language
rename wjp_country country

* Create ID
egen id=concat(language longitudinal id_original), punct(_)
egen id_alex=concat(question id), punct(_)
drop id id_original

/* These 3 lines are for incorporating 2021 data */
gen year=2022
gen regular=0
drop if language=="Last_Year"

order question year regular longitudinal id_alex language country wjp_login

/* Recoding questions */
foreach var of varlist ph_q5a ph_q5b ph_q5c ph_q5d {
	replace `var'=1 if `var'==0
	replace `var'=2 if `var'==5
	replace `var'=3 if `var'==25
	replace `var'=4 if `var'==50
	replace `var'=5 if `var'==75
	replace `var'=6 if `var'==100
}

/* Changing 9 for missing */
foreach var of varlist ph_q1a- ph_q6g {
	replace `var'=. if `var'==9
}

foreach var of varlist ph_q7- ph_q14 {
	replace `var'=. if `var'==9
}

/* Change names to match the MAP file and the GPP */

drop if country=="Burundi"

replace country="Congo, Rep." if country=="Republic of Congo"
replace country="Korea, Rep." if country=="Republic of Korea"
replace country="Egypt, Arab Rep." if country=="Egypt"
replace country="Iran, Islamic Rep." if country=="Iran"
replace country="St. Kitts and Nevis" if country=="Saint Kitts and Nevis"		
replace country="St. Lucia" if country=="Saint Lucia"
replace country="St. Vincent and the Grenadines" if country=="Saint Vincent and the Grenadines"
replace country="Cote d'Ivoire" if country=="Ivory Coast"
replace country="Congo, Dem. Rep." if country=="Democratic Republic of Congo"
replace country="Gambia" if country=="The Gambia"

replace country="Kyrgyz Republic" if country=="Kyrgyzstan"
replace country="North Macedonia" if country=="Macedonia, FYR"
replace country="Russian Federation" if country=="Russia"
replace country="Venezuela, RB" if country=="Venezuela"

save "$path2data/1. Original/ph_final.dta", replace
erase "$path2data/1. Original/ph_final_long.dta"
