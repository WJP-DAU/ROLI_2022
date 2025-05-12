/*=================================================================================================================
Project:		QRQ 2022
Routine:		QRQ Data Cleaning and Harmonization 2022 (master do file)
Author(s):		Natalia Rodriguez (nrodriguez@worldjusticeproject.org)
Dependencies:  	World Justice Project
Creation Date:	May, 2025

Description:
Master dofile for the cleaning and analyzing the QRQ data for the Global Index. 
This do file takes the calculations from 2022 and develops new calculations for experts (outliers)

=================================================================================================================*/


clear
cls
set maxvar 120000


/*=================================================================================================================
					Pre-settings
=================================================================================================================*/


*--- Stata Version
*version 15

*--- Required packages:
* NONE

*--- Years of analysis

global year_current "2022"
global year_previous "2021"

*--- Defining paths to SharePoint & your local Git Repo copy:

*------ (a) Natalia Rodriguez:
if (inlist("`c(username)'", "nrodriguez")) {
	global path2SP "C:\Users\nrodriguez\OneDrive - World Justice Project\Programmatic\Data Analytics\7. WJP ROLI\\ROLI_${year_current}\\1. Cleaning\QRQ"
	global path2GH "C:\Users\nrodriguez\OneDrive - World Justice Project\Natalia\GitHub\\ROLI_${year_current}\\1. Cleaning\QRQ"
	

*--- Defining path to Data and DoFiles:

*Path2data: Path to original exports from Alchemer by QRQ team. 
global path2data "${path2SP}\\1. Data"

*Path 2dos: Path to do-files (Routines). This will include the importing routine for 2023 ONLY
global path2dos22 "${path2GH}\\2. Code"

*Path 2dos: Path to do-files (Routines). THESE ARE THE SAME ROUTINES AS 2024
global path2dos  "C:\Users\nrodriguez\OneDrive - World Justice Project\Natalia\GitHub\ROLI_2024\1. Cleaning\QRQ\2. Code"

/*=================================================================================================================
					I. Cleaning the data
=================================================================================================================*/

cls
do "${path2dos22}\\Routines\\data_import_all.do"

/*=================================================================================================================
					II. Appending the data
=================================================================================================================*/

clear
use "${path2data}\\1. Original\cc_final.dta"
append using "${path2data}\\1. Original\cj_final.dta"
append using "${path2data}\\1. Original\lb_final.dta"
append using "${path2data}\\1. Original\ph_final.dta"

save "${path2data}\\1. Original\\qrq_${year_current}.dta", replace


/*=================================================================================================================
					III. Re-scaling the data
=================================================================================================================*/

do "${path2dos22}\\Routines\\normalization.do"


/*=================================================================================================================
					IV. Creating variables common in various questionnaires
=================================================================================================================*/

do "${path2dos22}\\Routines\\common_q.do"

sort country question id_alex

save "${path2data}\\1. Original\\qrq_${year_current}.dta", replace


/*=================================================================================================================
					V. Merging with 2021 data and previous years
=================================================================================================================*/

/*----------------------------------------------*/
/* VI. Merging with 2021 data and previous years */
/*----------------------------------------------*/
/* Responded in 2021 */
clear
use "$path2data\\1. Original\\qrq_original_${year_previous}.dta"
keep wjp_login
duplicates drop
sort wjp_login
save "$path2data\\1. Original\\qrq_${year_previous}_login.dta", replace

/* Responded longitudinal survey in 2022 */ 
clear
use "$path2data\\1. Original\\qrq_${year_current}.dta"
keep wjp_login
duplicates drop
sort wjp_login
save "$path2data\\1. Original\\qrq_login.dta", replace 

/* Only answered in 2021 (and not in 2022) (Login) */
clear
use "$path2data\\1. Original\\qrq_${year_previous}_login.dta"
merge 1:1 wjp_login using "$path2data\\1. Original\\qrq_login.dta"
keep if _merge==1
drop _merge
sort wjp_login
save "$path2data\\1. Original\\qrq_${year_previous}_login_unique.dta", replace 

/* Only answered in 2021 (and not in 2022) (Full data) */
clear
use "$path2data\\1. Original\\qrq_original_${year_previous}.dta"
sort wjp_login
merge m:1 wjp_login using "$path2data\\1. Original\\qrq_${year_previous}_login_unique.dta"
keep if _merge==3
drop _merge
gen aux="2021"
egen id_alex_1=concat(id_alex aux), punct(_)
replace id_alex=id_alex_1
drop id_alex_1 aux
sort wjp_login
save "$path2data\\1. Original\\qrq_${year_previous}.dta", replace

erase "$path2data\\1. Original\\qrq_${year_previous}_login.dta"
erase "$path2data\\1. Original\\qrq_login.dta"
erase "$path2data\\1. Original\\qrq_${year_previous}_login_unique.dta"

/* Merging with 2021 data and older regular data*/
clear
use "$path2data\\1. Original\\qrq_${year_current}.dta"
append using "$path2data\\1. Original\\qrq_${year_previous}.dta"
*Observations are no longer longitudinal because the database we're appending only includes people that only answered in 2021 or before
replace longitudinal=0 if year==2021 | year==2019
drop total_score total_n f_1* f_2* f_3* f_4* f_6* f_7* f_8* N total_score_mean total_score_sd outlier outlier_CO
drop cc_q6a_usd cc_q6a_gni dup true_dup dup_alex true_dup_alex true_dup_question true_dup_question_year


/* Change names of countries according to new MAP (for the 2021 and older data) */
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
replace country="Czechia" if country=="Czech Republic"
replace country="Turkiye" if country=="Turkey"

/* Merging with Cost of Lawyers 2023 clean data for new countries */
/* 
sort id_alex

merge 1:1 id_alex using "cost of lawyers_2023.dta"
tab _merge
drop if _merge==2
drop _merge 
save qrq.dta, replace
*/


/*=================================================================================================================
					VI. Checks
=================================================================================================================*/


/* 1.Averages */
egen total_score=rowmean(cc_q1_norm- ph_q14_norm)
drop if total_score==.

/* 2.Duplicates */

// Duplicates by login (can show duplicates for years and surveys. Ex: An expert that answered three qrq's one year)
duplicates tag wjp_login, generate(dup)
tab dup
br if dup>0

// Duplicates by login and score (shows duplicates of year and expert, that SHOULD be removed)
duplicates tag wjp_login total_score, generate(true_dup)
tab true_dup
br if true_dup>0

// Duplicates by id and year (Doesn't show the country)
duplicates tag id_alex, generate (dup_alex)
tab dup_alex
br if dup_alex>0

//Duplicates by id, year and score (Should be removed)
duplicates tag id_alex total_score, generate(true_dup_alex)
tab true_dup_alex
br if true_dup_alex>0

//Duplicates by login and questionnaire. They should be removed if the country and year are the same.
duplicates tag question wjp_login, generate(true_dup_question)
tab true_dup_question
br if true_dup_question>0

//Duplicates by login, questionnaire and year. They should be removed if the country and year are the same.
duplicates tag question wjp_login year, generate(true_dup_question_year)
tab true_dup_question_year
br if true_dup_question_year>0
count

//Duplicates from 2018

merge 1:1 question year country wjp_login country using "C:\Users\nrodriguez\OneDrive - World Justice Project\Natalia\Index\2022\QRQ\qrq 2018 with password.dta"
*merge 1:1 question year country wjp_login country using "C:\Users\poncea\Downloads\Scores\QRQ\qrq 2018 with password.dta"
drop if _merge==2
replace wjp_password=wjp_password_2018 if _merge==3
drop _merge

//Duplicates from 2019
merge 1:1 question year country wjp_login country using "C:\Users\nrodriguez\OneDrive - World Justice Project\Natalia\Index\2022\QRQ\qrq 2019 with password.dta"
*merge 1:1 question year country wjp_login country using "C:\Users\poncea\Downloads\Scores\QRQ\qrq 2019 with password.dta"
drop if _merge==2
replace wjp_password=wjp_password_2019 if _merge==3
drop _merge

//Duplicates by password and questionnaire. Some experts have changed their emails and our check with id_alex doesn't catch them. 
duplicates tag question country wjp_password, gen(dup_password)
tab dup_password
tab dup_password if wjp_password!=.

*Check the year and keep the most recent one
tab year if dup_password>0 & wjp_password!=.

sort wjp_password
br if dup_password>0 & wjp_password!=.

bys question country wjp_password: egen year_max=max(year) if dup_password>0 & dup_password!=. & wjp_password!=.
gen dup_mark=1 if year!=year_max & dup_password>0 & dup_password!=. & wjp_password!=.
drop if dup_mark==1

drop id_alex_2018 wjp_password_2018 id_alex_2019 wjp_password_2019 dup_password year_max dup_mark

tab year

//Duplicates by login (lowercases) and questionnaire. 
/*This check drops experts that have emails with uppercases and are included 
from two different years of the same questionnaire and country (consecutive years). We should remove the 
old responses that we are including as "regular" that we think are regular because of the 
upper and lower cases. */

gen wjp_login_lower=ustrlower(wjp_login)
duplicates tag question wjp_login_lower country, generate(true_dup_question_lower)
tab true_dup_question_lower

sort wjp_login_lower year
br if true_dup_question_lower>0

bys wjp_login_lower country question country: egen year_max=max(year) if true_dup_question_lower>0

gen dup_mark=1 if year!=year_max & true_dup_question_lower>0
drop if dup_mark==1

*Test it again
drop true_dup_question_lower
duplicates tag question wjp_login_lower country, generate(true_dup_question_lower)
tab true_dup_question_lower
sort wjp_login_lower year
br if true_dup_question_lower>0

drop dup true_dup dup_alex true_dup_alex true_dup_question true_dup_question_year wjp_login_lower year_max dup_mark true_dup_question_lower


/* 3. Drop questionnaires with very few observations */

egen total_n=rownonmiss(cc_q1_norm- ph_q14_norm)

*Total number of experts by country
bysort country: gen N=_N

*Number of questions per QRQ
*CC: 162
*CJ: 197
*LB: 134
*PH: 49

*Drops surveys with less than 25 nonmissing values. Erin cleaned empty suveys and surveys with low responses
*There are countries with low total_n because we removed the DN/NA at the beginning of the do file
br if total_n<25
drop if total_n<=25 & N>=10

********************************************************
				 /* 4. Factor scores */
********************************************************

qui do "${path2dos}\\Routines\\scores.do"


********************************************************
		/* 5. Expert counts (original scenario)*/
********************************************************

*Counting the number of experts per discipline
foreach x in cc cj lb ph {
gen count_`x'=1 if question=="`x'"
}

drop N
 
 
********************************************************
				 /* 6. Outliers */
********************************************************

*Total number of experts by country
bysort country: gen N=_N

*Total number of experts by country and discipline
bysort country question: gen N_questionnaire=_N

*Average score and standard deviation (for outliers)
bysort country: egen total_score_mean=mean(total_score)
bysort country: egen total_score_sd=sd(total_score)

*Define global for norm variables
do "${path2dos}\\Routines\\globals.do"


*----- Aggregate Scores - NO DELETIONS (scenario 0)

preserve

collapse (mean) $norm (sum) count_cc count_cj count_lb count_ph, by(country)

qui do "${path2dos}\\Routines\scores.do"

save "$path2data\\2. Scenarios\qrq_country_averages_s0.dta", replace

keep country count_cc count_cj count_lb count_ph
egen total_counts=rowtotal(count_cc count_cj count_lb count_ph)

save "$path2data\\2. Scenarios\country_counts_s0.dta", replace

restore



*----- Aggregate Scores - Removing general outliers (scenario 1)

preserve

*Outliers routine (scenario 1)
qui do "${path2dos}\\Routines\outliers_gen.do"

*Dropping general outliers
drop if outlier==1 & N>20 & N_questionnaire>5

collapse (mean) $norm, by(country)

qui do "${path2dos}\\Routines\scores.do"

save "${path2data}\\2. Scenarios\qrq_country_averages_s1.dta", replace

restore


*----- Aggregate Scores - Removing general outliers + outliers by discipline (highest/lowest) (scenario 2)

preserve

*Outliers routine (scenario 1)
qui do "${path2dos}\\Routines\outliers_gen.do"

*Dropping general outliers
drop if outlier==1 & N>20 & N_questionnaire>5

*Outliers routine (scenario 2)
qui do "${path2dos}\\Routines\outliers_dis.do"

*Dropping outliers by disciplines (IQR)
foreach x in cc cj lb ph {
	drop if outlier_iqr_`x'_hi==1
	drop if outlier_iqr_`x'_lo==1
}

collapse (mean) $norm, by(country)

qui do "${path2dos}\\Routines\scores.do"

save "${path2data}\\2. Scenarios\qrq_country_averages_s2.dta", replace

restore


*----- Aggregate Scores - Removing question outliers + general outliers + discipline outliers (scenario 3)


***** POSITIVE OUTLIERS
preserve

*Outliers routine (scenario 1)
qui do "${path2dos}\\Routines\outliers_gen.do"

*Dropping general outliers
drop if outlier==1 & N>20 & N_questionnaire>5

*Outliers routine (scenario 2)
qui do "${path2dos}\\Routines\outliers_dis.do"

*Dropping outliers by disciplines (IQR)
foreach x in cc cj lb ph {
	drop if outlier_iqr_`x'_hi==1
	drop if outlier_iqr_`x'_lo==1
}

*Outliers routine (scenario 3) - This routine defines the outliers by question
qui do "${path2dos}\\Routines\outliers_ques.do"

*This routine defines the globals for each sub-factor (all questions included in the sub-factor)
qui do "${path2dos}\\Routines\subfactor_questions.do"

*Outliers routine (scenario 4) - This routine defines the sub-factor outliers 
qui do "${path2dos}\\Routines\outliers_sub.do"

*Dropping questions that are outliers (max-min values with a proportion of less than 15% only for the experts who have the extreme values in questions & sub-factor)
foreach v in f_1_2 f_1_3 f_1_4 f_1_5 f_1_6 f_1_7 f_2_1 f_2_2 f_2_3 f_2_4 f_3_1 f_3_2 f_3_3 f_3_4 f_4_1 f_4_2 f_4_3 f_4_4 f_4_5 f_4_6 f_4_7 f_4_8 f_5_3 f_6_1 f_6_2 f_6_3 f_6_4 f_6_5 f_7_1 f_7_2 f_7_3 f_7_4 f_7_5 f_7_6 f_7_7 f_8_1 f_8_2 f_8_3 f_8_4 f_8_5 f_8_6 f_8_7 {
	display as result "`v'"
	foreach x of global `v' {
		display as error "`x'" 
		replace `x'=. if `x'==`x'_max & `x'_hi_p<0.15 & `x'_c>5 & `x'!=. & outlier_`v'_iqr_hi==1		
}
}

collapse (mean) $norm, by(country)

qui do "${path2dos}\\Routines\scores.do"

save "${path2data}\\2. Scenarios\qrq_country_averages_s3_p.dta", replace

restore


***** NEGATIVE OUTLIERS
preserve

*Outliers routine (scenario 1)
qui do "${path2dos}\\Routines\outliers_gen.do"

*Dropping general outliers
drop if outlier==1 & N>20 & N_questionnaire>5

*Outliers routine (scenario 2)
qui do "${path2dos}\\Routines\outliers_dis.do"

*Dropping outliers by disciplines (IQR)
foreach x in cc cj lb ph {
	drop if outlier_iqr_`x'_hi==1
	drop if outlier_iqr_`x'_lo==1
}

*Outliers routine (scenario 3) - This routine defines the outliers by question
qui do "${path2dos}\\Routines\outliers_ques.do"

*Outliers routine (scenario 4) - This routine defines the sub-factor outliers 
qui do "${path2dos}\\Routines\outliers_sub.do"

*This routine defines the globals for each sub-factor (all questions included in the sub-factor)
qui do "${path2dos}\\Routines\subfactor_questions.do"

*Dropping questions that are outliers (max-min values with a proportion of less than 15% only for the experts who have the extreme values in questions & sub-factor)
foreach v in f_1_2 f_1_3 f_1_4 f_1_5 f_1_6 f_1_7 f_2_1 f_2_2 f_2_3 f_2_4 f_3_1 f_3_2 f_3_3 f_3_4 f_4_1 f_4_2 f_4_3 f_4_4 f_4_5 f_4_6 f_4_7 f_4_8 f_5_3 f_6_1 f_6_2 f_6_3 f_6_4 f_6_5 f_7_1 f_7_2 f_7_3 f_7_4 f_7_5 f_7_6 f_7_7 f_8_1 f_8_2 f_8_3 f_8_4 f_8_5 f_8_6 f_8_7 {
	display as result "`v'"
	foreach x of global `v' {
		display as error "`x'" 		
		replace `x'=. if `x'==`x'_min & `x'_lo_p<0.15 & `x'_c>5 & `x'!=. & outlier_`v'_iqr_lo==1
		
}
}

collapse (mean) $norm, by(country)

qui do "${path2dos}\\Routines\scores.do"

save "${path2data}\\2. Scenarios\qrq_country_averages_s3_n.dta", replace

restore


*----- Aggregate Scores - Removing question outliers + general outliers + discipline outliers (scenario 3) ALTERNATIVE


***** POSITIVE OUTLIERS
preserve

*Outliers routine (scenario 1)
qui do "${path2dos}\\Routines\outliers_gen.do"

*Dropping general outliers
drop if outlier==1 & N>20 & N_questionnaire>5

*Outliers routine (scenario 3) - This routine defines the outliers by question
qui do "${path2dos}\\Routines\outliers_ques.do"

*This routine defines the globals for each sub-factor (all questions included in the sub-factor)
qui do "${path2dos}\\Routines\subfactor_questions.do"

*Outliers routine (scenario 4) - This routine defines the sub-factor outliers 
qui do "${path2dos}\\Routines\outliers_sub.do"

*Dropping questions that are outliers (max-min values with a proportion of less than 15% only for the experts who have the extreme values in questions & sub-factor)
foreach v in f_1_2 f_1_3 f_1_4 f_1_5 f_1_6 f_1_7 f_2_1 f_2_2 f_2_3 f_2_4 f_3_1 f_3_2 f_3_3 f_3_4 f_4_1 f_4_2 f_4_3 f_4_4 f_4_5 f_4_6 f_4_7 f_4_8 f_5_3 f_6_1 f_6_2 f_6_3 f_6_4 f_6_5 f_7_1 f_7_2 f_7_3 f_7_4 f_7_5 f_7_6 f_7_7 f_8_1 f_8_2 f_8_3 f_8_4 f_8_5 f_8_6 f_8_7 {
	display as result "`v'"
	foreach x of global `v' {
		display as error "`x'" 
		replace `x'=. if `x'==`x'_max & `x'_hi_p<0.15 & `x'_c>5 & `x'!=. & outlier_`v'_iqr_hi==1		
}
}

collapse (mean) $norm, by(country)

qui do "${path2dos}\\Routines\scores.do"

save "${path2data}\\2. Scenarios\qrq_country_averages_s3_p_alt.dta", replace

restore


***** NEGATIVE OUTLIERS
preserve

*Outliers routine (scenario 1)
qui do "${path2dos}\\Routines\outliers_gen.do"

*Dropping general outliers
drop if outlier==1 & N>20 & N_questionnaire>5

*Outliers routine (scenario 3) - This routine defines the outliers by question
qui do "${path2dos}\\Routines\outliers_ques.do"

*Outliers routine (scenario 4) - This routine defines the sub-factor outliers 
qui do "${path2dos}\\Routines\outliers_sub.do"

*This routine defines the globals for each sub-factor (all questions included in the sub-factor)
qui do "${path2dos}\\Routines\subfactor_questions.do"

*Dropping questions that are outliers (max-min values with a proportion of less than 15% only for the experts who have the extreme values in questions & sub-factor)
foreach v in f_1_2 f_1_3 f_1_4 f_1_5 f_1_6 f_1_7 f_2_1 f_2_2 f_2_3 f_2_4 f_3_1 f_3_2 f_3_3 f_3_4 f_4_1 f_4_2 f_4_3 f_4_4 f_4_5 f_4_6 f_4_7 f_4_8 f_5_3 f_6_1 f_6_2 f_6_3 f_6_4 f_6_5 f_7_1 f_7_2 f_7_3 f_7_4 f_7_5 f_7_6 f_7_7 f_8_1 f_8_2 f_8_3 f_8_4 f_8_5 f_8_6 f_8_7 {
	display as result "`v'"
	foreach x of global `v' {
		display as error "`x'" 		
		replace `x'=. if `x'==`x'_min & `x'_lo_p<0.15 & `x'_c>5 & `x'!=. & outlier_`v'_iqr_lo==1
		
}
}

collapse (mean) $norm, by(country)

qui do "${path2dos}\\Routines\scores.do"

save "${path2data}\\2. Scenarios\qrq_country_averages_s3_n_alt.dta", replace

restore


*----- Aggregate Scores - Removing sub-factor outliers + general outliers + discipline outliers (scenario 4)


***** POSITIVE OUTLIERS
preserve

*Outliers routine (scenario 1)
qui do "${path2dos}\\Routines\outliers_gen.do"

*Dropping general outliers
drop if outlier==1 & N>20 & N_questionnaire>5

*Outliers routine (scenario 2)
qui do "${path2dos}\\Routines\outliers_dis.do"

*Dropping outliers by disciplines (IQR)
foreach x in cc cj lb ph {
	drop if outlier_iqr_`x'_hi==1
	drop if outlier_iqr_`x'_lo==1
}

*Outliers routine (scenario 3) - This routine defines the outliers by question
qui do "${path2dos}\\Routines\outliers_ques.do"

*Outliers routine (scenario 4) - This routine defines the sub-factor outliers 
qui do "${path2dos}\\Routines\outliers_sub.do"

*This routine defines the globals for each sub-factor (all questions included in the sub-factor)
qui do "${path2dos}\\Routines\subfactor_questions.do"

*Dropping ALL questions in sub-factor if the expert is an outlier for this indicator
#delimit ;
foreach v in 
f_1_2 f_1_3 f_1_4 f_1_5 f_1_6 f_1_7 
f_2_1 f_2_2 f_2_3 f_2_4
f_3_1 f_3_2 f_3_3 f_3_4
f_4_1 f_4_2 f_4_3 f_4_4 f_4_5 f_4_6 f_4_7 f_4_8
f_5_3
f_6_1 f_6_2 f_6_3 f_6_4 f_6_5
f_7_1 f_7_2 f_7_3  f_7_4 f_7_5 f_7_6 f_7_7
f_8_1 f_8_2 f_8_3 f_8_4 f_8_5 f_8_6 f_8_7
{;
	display as result "`v'"	;
	foreach x of global `v' {;
		display as error "`x'" ;
		replace `x'=. if `x'_c>5 & `x'!=. & outlier_`v'_iqr_hi==1 ;	
};
};
#delimit cr

collapse (mean) $norm, by(country)

qui do "${path2dos}\\Routines\scores.do"

save "${path2data}\\2. Scenarios\qrq_country_averages_s4_p.dta", replace

restore


***** NEGATIVE OUTLIERS
preserve

*Outliers routine (scenario 1)
qui do "${path2dos}\\Routines\outliers_gen.do"

*Dropping general outliers
drop if outlier==1 & N>20 & N_questionnaire>5

*Outliers routine (scenario 2)
qui do "${path2dos}\\Routines\outliers_dis.do"

*Dropping outliers by disciplines (IQR)
foreach x in cc cj lb ph {
	drop if outlier_iqr_`x'_hi==1
	drop if outlier_iqr_`x'_lo==1
}

*Outliers routine (scenario 3) - This routine defines the outliers by question
qui do "${path2dos}\\Routines\outliers_ques.do"

*Outliers routine (scenario 4) - This routine defines the sub-factor outliers 
qui do "${path2dos}\\Routines\outliers_sub.do"

*This routine defines the globals for each sub-factor (all questions included in the sub-factor)
qui do "${path2dos}\\Routines\subfactor_questions.do"

*Dropping ALL questions in sub-factor if the expert is an outlier for this indicator
#delimit ;
foreach v in 
f_1_2 f_1_3 f_1_4 f_1_5 f_1_6 f_1_7 
f_2_1 f_2_2 f_2_3 f_2_4
f_3_1 f_3_2 f_3_3 f_3_4
f_4_1 f_4_2 f_4_3 f_4_4 f_4_5 f_4_6 f_4_7 f_4_8
f_5_3
f_6_1 f_6_2 f_6_3 f_6_4 f_6_5
f_7_1 f_7_2 f_7_3  f_7_4 f_7_5 f_7_6 f_7_7
f_8_1 f_8_2 f_8_3 f_8_4 f_8_5 f_8_6 f_8_7
{;
	display as result "`v'"	;
	foreach x of global `v' {;
		display as error "`x'" ;
		replace `x'=. if `x'_c>5 & `x'!=. & outlier_`v'_iqr_lo==1 ;	
};
};
#delimit cr

collapse (mean) $norm, by(country)

qui do "${path2dos}\\Routines\scores.do"

save "${path2data}\\2. Scenarios\qrq_country_averages_s4_n.dta", replace

restore


*----- Aggregate Scores - Removing sub-factor outliers + general outliers + discipline outliers (scenario 4) ALTERNATIVE


***** POSITIVE OUTLIERS
preserve

*Outliers routine (scenario 1)
qui do "${path2dos}\\Routines\outliers_gen.do"

*Dropping general outliers
drop if outlier==1 & N>20 & N_questionnaire>5

*Outliers routine (scenario 3) - This routine defines the outliers by question
qui do "${path2dos}\\Routines\outliers_ques.do"

*Outliers routine (scenario 4) - This routine defines the sub-factor outliers 
qui do "${path2dos}\\Routines\outliers_sub.do"

*This routine defines the globals for each sub-factor (all questions included in the sub-factor)
qui do "${path2dos}\\Routines\subfactor_questions.do"

*Dropping ALL questions in sub-factor if the expert is an outlier for this indicator
#delimit ;
foreach v in 
f_1_2 f_1_3 f_1_4 f_1_5 f_1_6 f_1_7 
f_2_1 f_2_2 f_2_3 f_2_4
f_3_1 f_3_2 f_3_3 f_3_4
f_4_1 f_4_2 f_4_3 f_4_4 f_4_5 f_4_6 f_4_7 f_4_8
f_5_3
f_6_1 f_6_2 f_6_3 f_6_4 f_6_5
f_7_1 f_7_2 f_7_3  f_7_4 f_7_5 f_7_6 f_7_7
f_8_1 f_8_2 f_8_3 f_8_4 f_8_5 f_8_6 f_8_7
{;
	display as result "`v'"	;
	foreach x of global `v' {;
		display as error "`x'" ;
		replace `x'=. if `x'_c>5 & `x'!=. & outlier_`v'_iqr_hi==1 ;	
};
};
#delimit cr

collapse (mean) $norm, by(country)

qui do "${path2dos}\\Routines\scores.do"

save "${path2data}\\2. Scenarios\qrq_country_averages_s4_p_alt.dta", replace

restore


***** NEGATIVE OUTLIERS
preserve

*Outliers routine (scenario 1)
qui do "${path2dos}\\Routines\outliers_gen.do"

*Dropping general outliers
drop if outlier==1 & N>20 & N_questionnaire>5

*Outliers routine (scenario 3) - This routine defines the outliers by question
qui do "${path2dos}\\Routines\outliers_ques.do"

*Outliers routine (scenario 4) - This routine defines the sub-factor outliers 
qui do "${path2dos}\\Routines\outliers_sub.do"

*This routine defines the globals for each sub-factor (all questions included in the sub-factor)
qui do "${path2dos}\\Routines\subfactor_questions.do"

*Dropping ALL questions in sub-factor if the expert is an outlier for this indicator
#delimit ;
foreach v in 
f_1_2 f_1_3 f_1_4 f_1_5 f_1_6 f_1_7 
f_2_1 f_2_2 f_2_3 f_2_4
f_3_1 f_3_2 f_3_3 f_3_4
f_4_1 f_4_2 f_4_3 f_4_4 f_4_5 f_4_6 f_4_7 f_4_8
f_5_3
f_6_1 f_6_2 f_6_3 f_6_4 f_6_5
f_7_1 f_7_2 f_7_3  f_7_4 f_7_5 f_7_6 f_7_7
f_8_1 f_8_2 f_8_3 f_8_4 f_8_5 f_8_6 f_8_7
{;
	display as result "`v'"	;
	foreach x of global `v' {;
		display as error "`x'" ;
		replace `x'=. if `x'_c>5 & `x'!=. & outlier_`v'_iqr_lo==1 ;	
};
};
#delimit cr

collapse (mean) $norm, by(country)

qui do "${path2dos}\\Routines\scores.do"

save "${path2data}\\2. Scenarios\qrq_country_averages_s4_n_alt.dta", replace

restore


