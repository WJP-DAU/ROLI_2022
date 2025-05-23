clear
set more off, perm

*cd "C:\Users\nrodriguez\OneDrive - World Justice Project\Programmatic\Index Data & Analysis\2022\Data & Analysis\QRQ\csv files"
*cd "C:\Users\poncea\Downloads\Scores\QRQ\csv files"

/*=================================================================================================================
					Pre-settings
=================================================================================================================*/

*--- Required packages:
* NONE

*--- Years of analysis
global year_current "2022"
global year_previous "2021"


*--- Defining paths to SharePoint & your local Git Repo copy:

*------ (a) Natalia Rodriguez:
if (inlist("`c(username)'", "nrodriguez")) {
	global path2SP "C:\Users\nrodriguez\OneDrive - World Justice Project\Programmatic\Data Analytics\7. WJP ROLI\ROLI_${year_current}\1. Cleaning\QRQ"
	global path2GH "C:\Users\nrodriguez\OneDrive - World Justice Project\Natalia\GitHub\ROLI_${year_current}\\1. Cleaning\QRQ"
}


*--- Defining path to Data and DoFiles:
global path2data "${path2SP}/1. Data"
global path2dos  "${path2SP}/2. Code"

*Path 2dos: Path to do-files (Routines). This will include the importing, normalization from 2023
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

erase "$path2data/1. Original/cc_final.dta"
erase "$path2data/1. Original/cj_final.dta"
erase "$path2data/1. Original/lb_final.dta"
erase "$path2data/1. Original/ph_final.dta"

/*=================================================================================================================
					III. Re-scaling the data
=================================================================================================================*/

do "${path2dos22}\\Routines\\normalization.do"

/*=================================================================================================================
					IV. Creating variables common in various questionnaires
=================================================================================================================*/

do "${path2dos22}/Routines/common_q.do"

sort country question id_alex

save "$path2data\1. Original\qrq_${year_current}.dta", replace


/*----------------------------------------------*/
/* VI. Merging with 2021 data and previous years */
/*----------------------------------------------*/
/* Responded in 2021 */
clear
use "$path2data/1. Original/qrq_original_${year_previous}.dta"
keep wjp_login
duplicates drop
sort wjp_login
save "$path2data/1. Original/qrq_${year_previous}_login.dta", replace

/* Responded longitudinal survey in 2022 */ 
clear
use "$path2data/1. Original/qrq_${year_current}.dta"
keep wjp_login
duplicates drop
sort wjp_login
save "$path2data/1. Original/qrq_login.dta", replace 

/* Only answered in 2021 (and not in 2022) (Login) */
clear
use "$path2data/1. Original/qrq_${year_previous}_login.dta"
merge 1:1 wjp_login using "$path2data/1. Original/qrq_login.dta"
keep if _merge==1
drop _merge
sort wjp_login
save "$path2data/1. Original/qrq_${year_previous}_login_unique.dta", replace 

/* Only answered in 2021 (and not in 2022) (Full data) */
clear
use "$path2data/1. Original/qrq_original_${year_previous}.dta"
sort wjp_login
merge m:1 wjp_login using "$path2data/1. Original/qrq_${year_previous}_login_unique.dta"
keep if _merge==3
drop _merge
gen aux="2021"
egen id_alex_1=concat(id_alex aux), punct(_)
replace id_alex=id_alex_1
drop id_alex_1 aux
sort wjp_login
save "$path2data/1. Original/qrq_${year_previous}.dta", replace

erase "$path2data/1. Original/qrq_${year_previous}_login.dta"
erase "$path2data/1. Original/qrq_login.dta"
erase "$path2data/1. Original/qrq_${year_previous}_login_unique.dta"

/* Merging with 2021 data and older regular data*/
clear
use "$path2data/1. Original/qrq_${year_current}.dta"
append using "$path2data/1. Original/qrq_${year_previous}.dta"
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

/*
/* Merging with Cost of Lawyers 2021 clean data for new countries */
 
sort id_alex

merge id_alex using "cost of lawyers_2021.dta"
tab _merge
drop if _merge==2
drop _merge 
save qrq.dta, replace
*/

/*-----------*/
/* V. Checks */
/*-----------*/

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

/* 4.Outliers */
bysort country: egen total_score_mean=mean(total_score)
bysort country: egen total_score_sd=sd(total_score)
gen outlier=0
replace outlier=1 if total_score>=(total_score_mean+2.5*total_score_sd) & total_score~=.
replace outlier=1 if total_score<=(total_score_mean-2.5*total_score_sd) & total_score~=.
bysort country: egen outlier_CO=max(outlier)

*Shows the number of experts of low count countries have and if the country has outliers
tab country outlier_CO if N<=20

*Shows the number of outlies per each low count country
tab country outlier if N<=20

drop if outlier==1 & N>20
*drop if outlier==1

sort country id_alex

********************************************************
				 /* 4. Factor scores */
********************************************************

qui do "${path2dos}/Routines/scores.do"


*----- Saving original dataset BEFORE adjustments

save "C:\Users\nrodriguez\OneDrive - World Justice Project\Programmatic\Data Analytics\8. Data\QRQ\QRQ_${year_current}_raw.dta", replace


/* Adjustments */

sort country question year total_score


drop if id_alex=="cc_English_0_379" //Afghanistan
replace all_q96_norm=. if id_alex=="lb_English_1_486" //Afghanistan
replace lb_q17e_norm=. if id_alex=="lb_English_1_486" //Afghanistan
replace lb_q17c_norm=. if id_alex=="lb_English_1_486" //Afghanistan
replace lb_q17b_norm=. if id_alex=="lb_English_1_321" //Afghanistan
replace cc_q27_norm=. if id_alex=="cc_English_1_979" //Afghanistan
replace cc_q27_norm=. if id_alex=="cc_English_0_1536" //Afghanistan
replace all_q97_norm=. if id_alex=="lb_English_1_486" //Afghanistan
replace all_q97_norm=. if id_alex=="cc_English_1_693" //Afghanistan
replace all_q97_norm=. if id_alex=="cc_English_1_1120" //Afghanistan
replace all_q97_norm=. if id_alex=="lb_English_0_655" //Afghanistan
replace all_q97_norm=. if id_alex=="lb_English_1_321" //Afghanistan
replace lb_q17c_norm=. if id_alex=="lb_English_0_67_2018_2019_2021" //Afghanistan
replace ph_q9d_norm=. if country=="Afghanistan" //Afghanistan
replace all_q57_norm=. if id_alex=="cc_English_0_1618_2021" //Afghanistan
replace all_q57_norm=. if id_alex=="cc_French_1_1324" //Afghanistan
replace all_q57_norm=. if id_alex=="lb_English_0_290_2021" //Afghanistan
replace all_q58_norm=. if id_alex=="cc_French_1_1324" //Afghanistan
replace all_q59_norm=. if id_alex=="cc_English_1_616_2018_2019_2021" //Afghanistan
replace all_q60_norm=. if id_alex=="cj_English_0_356_2019_2021" //Afghanistan
replace all_q60_norm=. if id_alex=="cj_English_1_1238_2021" //Afghanistan
replace all_q60_norm=. if id_alex=="cj_English_0_515" //Afghanistan
replace cc_q26h_norm=. if id_alex=="cc_English_0_136" //Afghanistan
replace all_q76_norm=. if id_alex=="lb_English_1_532_2016_2017_2018_2019_2021" //Afghanistan
replace all_q77_norm=. if id_alex=="lb_English_1_532_2016_2017_2018_2019_2021" //Afghanistan
replace all_q78_norm=. if id_alex=="lb_English_1_532_2016_2017_2018_2019_2021" //Afghanistan
replace all_q79_norm=. if id_alex=="lb_English_1_532_2016_2017_2018_2019_2021" //Afghanistan
replace all_q80_norm=. if id_alex=="lb_English_1_532_2016_2017_2018_2019_2021" //Afghanistan
replace all_q81_norm=. if id_alex=="lb_English_1_532_2016_2017_2018_2019_2021" //Afghanistan
replace all_q82_norm=. if id_alex=="lb_English_1_532_2016_2017_2018_2019_2021" //Afghanistan
replace all_q76_norm=. if id_alex=="cc_French_1_1324" //Afghanistan
replace all_q77_norm=. if id_alex=="cc_French_1_1324" //Afghanistan
replace all_q77_norm=. if id_alex=="lb_English_1_788" //Afghanistan
replace all_q77_norm=. if id_alex=="lb_English_1_403" //Afghanistan
drop if id_alex=="cc_English_0_136" //Afghanistan
drop if id_alex=="cc_English_1_1633_2019_2021" //Afghanistan
drop if id_alex=="cj_English_1_1238_2021" //Afghanistan
drop if id_alex=="lb_English_1_788" //Afghanistan
replace cc_q33_norm=0 if id_alex=="cc_English_1_693" //Afghanistan
replace cj_q38_norm=0 if id_alex=="cj_English_1_73_2021" //Afghanistan
replace cj_q38_norm=0 if id_alex=="cj_English_0_1017_2018_2019_2021" //Afghanistan
replace cj_q38_norm=. if id_alex=="cj_English_0_850_2019_2021" //Afghanistan
replace all_q24_norm=. if id_alex=="cj_English_0_356_2019_2021" //Afghanistan
replace all_q27_norm=. if id_alex=="cj_English_0_356_2019_2021" //Afghanistan
replace all_q22_norm=0 if id_alex=="cc_English_0_240_2018_2019_2021" //Afghanistan
replace all_q23_norm=0 if id_alex=="cc_English_0_240_2018_2019_2021" //Afghanistan
replace all_q24_norm=0 if id_alex=="cc_English_0_240_2018_2019_2021" //Afghanistan
replace all_q25_norm=0 if id_alex=="cc_English_0_240_2018_2019_2021" //Afghanistan
replace all_q26_norm=0 if id_alex=="cc_English_0_240_2018_2019_2021" //Afghanistan
replace all_q27_norm=0 if id_alex=="cc_English_0_240_2018_2019_2021" //Afghanistan
replace all_q8_norm=0 if id_alex=="cc_English_0_240_2018_2019_2021" //Afghanistan
replace cc_q14a_norm=. if id_alex=="cc_English_0_1536" //Afghanistan
replace cc_q14b_norm=. if id_alex=="cc_English_0_1536" //Afghanistan
replace cc_q16b_norm=. if id_alex=="cc_English_0_1536" //Afghanistan
replace cc_q16c_norm=. if id_alex=="cc_English_0_1536" //Afghanistan
replace cc_q16d_norm=. if id_alex=="cc_English_0_1536" //Afghanistan
replace cc_q16e_norm=. if id_alex=="cc_English_0_1536" //Afghanistan
replace cc_q16f_norm=. if id_alex=="cc_English_0_1536" //Afghanistan
replace cc_q16g_norm=. if id_alex=="cc_English_0_1536" //Afghanistan
replace cc_q16e_norm=. if id_alex=="cc_English_1_202_2017_2018_2019_2021" //Afghanistan
replace cc_q16e_norm=. if id_alex=="cc_English_0_242_2018_2019_2021" //Afghanistan
replace cc_q16e_norm=. if id_alex=="cc_English_0_240_2018_2019_2021" //Afghanistan
replace cc_q16e_norm=0 if id_alex=="cc_English_1_618_2018_2019_2021" //Afghanistan
replace cc_q16e_norm=0 if id_alex=="cc_English_1_616_2018_2019_2021" //Afghanistan
replace all_q84_norm=. if id_alex=="cc_English_1_202_2017_2018_2019_2021" //Afghanistan
replace all_q84_norm=. if id_alex=="cc_English_0_242_2018_2019_2021" //Afghanistan
replace all_q84_norm=. if id_alex=="cc_English_0_240_2018_2019_2021" //Afghanistan
replace all_q84_norm=. if id_alex=="cc_English_1_618_2018_2019_2021" //Afghanistan
replace cc_q13_norm=. if id_alex=="cc_English_1_202_2017_2018_2019_2021" //Afghanistan
replace cc_q13_norm=. if id_alex=="cc_English_0_242_2018_2019_2021" //Afghanistan
replace cc_q13_norm=. if id_alex=="cc_English_0_240_2018_2019_2021" //Afghanistan
replace cc_q13_norm=. if id_alex=="cc_English_1_618_2018_2019_2021" //Afghanistan
replace all_q84_norm=0 if id_alex=="cc_English_0_1618_2021" //Afghanistan
replace all_q85_norm=0 if id_alex=="cc_English_0_1618_2021" //Afghanistan
replace cj_q28_norm=. if id_alex=="cj_English_0_119" //Albania
replace cj_q21g_norm=. if id_alex=="cj_English_0_119" //Albania
drop if id_alex=="cj_English_0_198_2021" //Albania
drop if id_alex=="cc_English_0_897_2017_2018_2019_2021" //Albania
replace cj_q7a_norm=. if id_alex=="cj_English_0_1059" //Albania
replace cj_q7b_norm=. if id_alex=="cj_English_0_1059" //Albania
replace cj_q20a_norm=. if id_alex=="cj_English_0_1059" //Albania
replace cj_q20b_norm=. if id_alex=="cj_English_0_1059" //Albania
replace cj_q7c_norm=. if id_alex=="cj_English_0_266" //Albania
replace cj_q20b_norm=. if id_alex=="cj_English_0_119" //Albania
replace cj_q7c_norm=. if id_alex=="cj_English_1_1124_2019_2021" //Albania
replace cj_q7b_norm=. if id_alex=="cj_English_1_18" //Albania
replace cj_q27b_norm=. if id_alex=="cj_English_1_1147_2019_2021" //Albania
replace all_q84_norm=. if id_alex=="cc_English_1_165" //Albania
replace all_q85_norm=. if id_alex=="cc_English_1_165" //Albania
replace cc_q13_norm=. if id_alex=="cc_English_1_165" //Albania
replace cc_q26a_norm=. if country=="Algeria" //Algeria
replace all_q76_norm=. if id_alex=="cc_French_1_1402" //Algeria 
replace all_q77_norm=. if id_alex=="cc_French_1_1402" //Algeria
replace all_q78_norm=. if id_alex=="cc_French_1_1402" //Algeria 
replace all_q79_norm=. if id_alex=="cc_French_1_1402" //Algeria
replace all_q80_norm=. if id_alex=="cc_French_1_1402" //Algeria
replace all_q81_norm=. if id_alex=="cc_French_1_1402" //Algeria
replace all_q82_norm=. if id_alex=="cc_French_1_1402" //Algeria
replace all_q76_norm=. if id_alex=="lb_French_0_327" //Algeria
replace all_q77_norm=. if id_alex=="lb_French_0_327" //Algeria
replace all_q78_norm=. if id_alex=="lb_French_0_327" //Algeria
replace all_q79_norm=. if id_alex=="lb_French_0_327" //Algeria
replace all_q80_norm=. if id_alex=="lb_French_0_327" //Algeria
replace all_q81_norm=. if id_alex=="lb_French_0_327" //Algeria
replace all_q82_norm=. if id_alex=="lb_French_0_327" //Algeria
replace cj_q21a_norm=. if id_alex=="cj_French_0_318" //Algeria
replace cj_q21e_norm=. if id_alex=="cj_French_0_318" //Algeria
replace cj_q21e_norm=. if id_alex=="cj_Arabic_0_796" //Algeria
replace cj_q21g_norm=. if id_alex=="cj_French_0_318" //Algeria
replace cj_q21g_norm=. if id_alex=="cj_Arabic_0_796" //Algeria
replace cj_q40b_norm=. if id_alex=="cj_French_0_461" //Algeria
replace cj_q40c_norm=. if id_alex=="cj_French_0_461" //Algeria
replace cj_q38_norm=. if id_alex=="cj_Arabic_0_796" //Algeria
replace cj_q36c_norm=. if id_alex=="cj_French_0_596_2018_2019_2021" //Algeria
drop if id_alex=="cj_English_0_1083" //Algeria
drop if id_alex=="cc_French_1_264" //Algeria
drop if id_alex=="lb_French_0_327" //Algeria
drop if id_alex=="cj_Arabic_0_618_2021" //Algeria
replace all_q49_norm=. if id_alex=="cc_French_1_824" //Algeria
replace lb_q19a_norm=. if id_alex=="lb_French_0_259_2018_2019_2021" //Algeria
replace all_q84_norm=. if id_alex=="lb_French_1_174" //Algeria
replace cc_q13_norm=. if id_alex=="cc_English_0_915_2019_2021" //Algeria
replace cc_q13_norm=. if id_alex=="cc_French_1_202_2021" //Algeria
replace cj_q40b_norm=. if id_alex=="cj_French_0_596_2018_2019_2021" //Algeria
replace cj_q40c_norm=. if id_alex=="cj_French_0_596_2018_2019_2021" //Algeria
replace cj_q20m_norm=. if id_alex=="cj_French_0_596_2018_2019_2021" //Algeria
replace all_q87_norm=0.5 if id_alex=="cc_French_1_824" //Algeria
replace cc_q40a_norm=. if id_alex=="cc_French_0_255_2018_2019_2021" //Algeria
replace cc_q40a_norm=. if id_alex=="cc_English_0_915_2019_2021" //Algeria
replace lb_q3d_norm=. if id_alex=="lb_French_0_259_2018_2019_2021" //Algeria
drop if id_alex=="cc_Portuguese_0_1151" //Angola
drop if id_alex=="cc_Portuguese_0_325" //Angola
replace all_q76_norm=. if id_alex=="lb_Portuguese_0_699_2018_2019_2021" //Angola 
replace all_q77_norm=. if id_alex=="lb_Portuguese_0_699_2018_2019_2021" //Angola
replace all_q78_norm=. if id_alex=="lb_Portuguese_0_699_2018_2019_2021" //Angola 
replace all_q79_norm=. if id_alex=="lb_Portuguese_0_699_2018_2019_2021" //Angola
replace all_q80_norm=. if id_alex=="lb_Portuguese_0_699_2018_2019_2021" //Angola
replace all_q81_norm=. if id_alex=="lb_Portuguese_0_699_2018_2019_2021" //Angola
replace all_q82_norm=. if id_alex=="lb_Portuguese_0_699_2018_2019_2021" //Angola
replace all_q76_norm=. if id_alex=="lb_Portuguese_0_153_2018_2019_2021" //Angola 
replace all_q77_norm=. if id_alex=="lb_Portuguese_0_153_2018_2019_2021" //Angola
replace all_q78_norm=. if id_alex=="lb_Portuguese_0_153_2018_2019_2021" //Angola 
replace all_q79_norm=. if id_alex=="lb_Portuguese_0_153_2018_2019_2021" //Angola
replace all_q80_norm=. if id_alex=="lb_Portuguese_0_153_2018_2019_2021" //Angola
replace all_q81_norm=. if id_alex=="lb_Portuguese_0_153_2018_2019_2021" //Angola
replace all_q82_norm=. if id_alex=="lb_Portuguese_0_153_2018_2019_2021" //Angola
replace cj_q12a_norm=. if id_alex=="cj_English_0_527_2018_2019_2021" //Angola 
replace cj_q12b_norm=. if id_alex=="cj_English_0_527_2018_2019_2021" //Angola 
replace cj_q12c_norm=. if id_alex=="cj_English_0_527_2018_2019_2021" //Angola 
replace cj_q12d_norm=. if id_alex=="cj_English_0_527_2018_2019_2021" //Angola 
replace cj_q12e_norm=. if id_alex=="cj_English_0_527_2018_2019_2021" //Angola 
replace cj_q12f_norm=. if id_alex=="cj_English_0_527_2018_2019_2021" //Angola 
replace all_q76_norm=. if id_alex=="lb_Portuguese_0_617_2021" //Angola 
replace all_q77_norm=. if id_alex=="lb_Portuguese_0_617_2021" //Angola
replace all_q78_norm=. if id_alex=="lb_Portuguese_0_617_2021" //Angola 
replace all_q79_norm=. if id_alex=="lb_Portuguese_0_617_2021" //Angola
replace all_q80_norm=. if id_alex=="lb_Portuguese_0_617_2021" //Angola
replace all_q81_norm=. if id_alex=="lb_Portuguese_0_617_2021" //Angola
replace all_q82_norm=. if id_alex=="lb_Portuguese_0_617_2021" //Angola
replace all_q76_norm=. if id_alex=="lb_Portuguese_0_798_2021" //Angola 
replace all_q77_norm=. if id_alex=="lb_Portuguese_0_798_2021" //Angola
replace all_q78_norm=. if id_alex=="lb_Portuguese_0_798_2021" //Angola 
replace all_q79_norm=. if id_alex=="lb_Portuguese_0_798_2021" //Angola
replace all_q80_norm=. if id_alex=="lb_Portuguese_0_798_2021" //Angola
replace all_q81_norm=. if id_alex=="lb_Portuguese_0_798_2021" //Angola
replace all_q82_norm=. if id_alex=="lb_Portuguese_0_798_2021" //Angola
replace cj_q10_norm=. if country=="Angola" //Angola
drop if id_alex=="lb_Portuguese_0_699_2018_2019_2021" //Angola
replace cc_q9c_norm=. if id_alex=="cc_English_0_449" //Austria
replace cc_q9c_norm=. if id_alex=="cc_English_0_42" //Austria
replace cc_q9c_norm=. if id_alex=="cc_English_0_167" //Austria
replace cc_q9c_norm=. if id_alex=="cc_English_0_1760_2017_2018_2019_2021" //Austria
drop if id_alex=="cc_English_1_207_2016_2017_2018_2019_2021"  //Austria
replace cj_q31g_norm=. if id_alex=="cj_English_0_739" //Austria
replace cj_q42d_norm=. if id_alex=="cj_English_0_942" //Austria
drop if id_alex=="cc_English_0_470" //Bangladesh
drop if id_alex=="cc_English_1_886" //Bangladesh
replace cj_q31f_norm=. if id_alex=="cj_English_0_151" //Bangladesh
replace cj_q42c_norm=. if id_alex=="cj_English_0_199_2017_2018_2019_2021" //Bangladesh
replace cj_q42c_norm=. if id_alex=="cj_English_1_447_2019_2021" //Bangladesh
replace cj_q42d_norm=. if id_alex=="cj_English_0_176_2016_2017_2018_2019_2021" //Bangladesh
replace cj_q42d_norm=. if id_alex=="cj_English_1_553_2019_2021" //Bangladesh
replace all_q48_norm=. if id_alex=="lb_English_0_640" //Bangladesh
replace all_q49_norm=. if id_alex=="lb_English_0_640" //Bangladesh
replace all_q50_norm=. if id_alex=="lb_English_0_640" //Bangladesh
replace lb_q19a_norm=. if id_alex=="lb_English_0_640" //Bangladesh
replace cj_q15_norm=. if id_alex=="cj_English_0_384" //Bangladesh
drop if id_alex=="cj_English_0_50" //Bangladesh
drop if id_alex=="cj_English_0_380" //Bangladesh
replace cj_q20o_norm=. if id_alex=="cj_English_0_784" //Bangladesh
replace cj_q12a_norm=. if id_alex=="cj_English_1_1066" //Bangladesh
replace cj_q12b_norm=. if id_alex=="cj_English_1_1066" //Bangladesh
replace cj_q12c_norm=. if id_alex=="cj_English_1_1066" //Bangladesh
replace cj_q12d_norm=. if id_alex=="cj_English_1_1066" //Bangladesh
replace cj_q12e_norm=. if id_alex=="cj_English_1_1066" //Bangladesh
replace cj_q12f_norm=. if id_alex=="cj_English_1_1066" //Bangladesh
replace cj_q20o_norm=. if id_alex=="cj_English_1_1066" //Bangladesh
drop if id_alex=="cc_English_1_318" //Bangladesh
drop if id_alex=="cj_English_0_784" //Bangladesh
replace cj_q15_norm=0 if id_alex=="cj_English_0_151" //Bangladesh
replace all_q49_norm=. if id_alex=="cc_English_0_260_2016_2017_2018_2019_2021" //Bangladesh
replace all_q49_norm=. if id_alex=="lb_English_1_676_2019_2021" //Bangladesh
replace all_q49_norm=. if id_alex=="cc_English_0_1080" //Bangladesh
replace lb_q19a_norm=. if id_alex=="lb_English_0_335" //Bangladesh
replace all_q84_norm=. if country=="Belarus" //Belarus
replace all_q85_norm=. if country=="Belarus" //Belarus
replace cc_q26a_norm=. if country=="Belarus" //Belarus
drop if id_alex=="cc_Russian_0_1755" //Belarus
drop if id_alex=="cc_Russian_0_1507" //Belarus
drop if id_alex=="ph_Russian_0_358_2018_2019_2021" //Belarus
drop if id_alex=="ph_English_0_510_2018_2019_2021" //Belarus
drop if id_alex=="ph_Russian_0_501_2021" //Belarus
drop if id_alex=="ph_Russian_1_393_2019_2021" //Belarus
drop if id_alex=="ph_Russian_1_673" //Belarus
replace cj_q21h_norm=. if country=="Belarus" //Belarus
drop if id_alex=="cc_Russian_0_1261_2019_2021" //Belarus
drop if id_alex=="cj_Russian_1_478_2018_2019_2021" //Belarus
replace all_q50_norm=. if id_alex=="cc_Russian_0_1493_2021" //Belarus
replace all_q50_norm=. if id_alex=="cc_Russian_1_1370_2021" //Belarus
drop if id_alex=="ph_French_0_182_2014_2016_2017_2018_2019_2021" //Belgium
drop if id_alex=="cj_French_0_210_2021" //Belgium
drop if id_alex=="lb_French_0_14_2013_2014_2016_2017_2018_2019_2021" //Belgium
drop if id_alex=="cc_French_0_870" //Belgium
drop if id_alex=="cj_English_1_1134" //Belize
replace all_q87_norm=. if country=="Belize" //Belize
replace cc_q14b_norm=. if country=="Belize" //Belize
replace cj_q21h_norm=. if country=="Belize" //Belize
replace cj_q15_norm=. if country=="Belize" //Belize
drop if id_alex=="lb_English_0_485_2014_2016_2017_2018_2019_2021" //Belize
drop if id_alex=="cc_English_0_574_2017_2018_2019_2021" //Belize
replace all_q55_norm=. if id_alex=="cc_English_0_1247_2016_2017_2018_2019_2021" //Belize
replace all_q55_norm=. if id_alex=="cc_English_1_86" //Belize
drop if id_alex=="ph_French_1_345_2021" //Benin
drop if id_alex=="cj_French_1_779" //Benin
drop if id_alex=="cc_French_1_156" //Benin
drop if id_alex=="lb_French_0_525" //Benin
drop if id_alex=="ph_French_0_170_2021" //Benin
replace cj_q8_norm=. if country=="Benin"
replace cj_q11b_norm=. if country=="Benin"
drop if id_alex=="cc_French_0_704" //Benin
drop if id_alex=="ph_French_0_48_2021" //Benin
drop if id_alex=="ph_French_1_358" //Benin
drop if id_alex=="ph_French_0_25" //Benin
drop if id_alex=="ph_French_0_306" //Benin
replace lb_q19a_norm=. if country=="Benin" //Benin
replace cc_q10_norm=. if id_alex=="cc_English_1_1600_2021" //Benin
replace cc_q11a_norm=. if id_alex=="cc_English_1_1600_2021" //Benin
replace cc_q16a_norm=. if id_alex=="cc_English_1_1600_2021" //Benin 
replace cc_q14a_norm=. if id_alex=="cc_English_1_1600_2021" //Benin
replace cc_q14b_norm=. if id_alex=="cc_English_1_1600_2021" //Benin
replace cc_q16b_norm=. if id_alex=="cc_English_1_1600_2021" //Benin
replace cc_q16c_norm=. if id_alex=="cc_English_1_1600_2021" //Benin
replace cc_q16d_norm=. if id_alex=="cc_English_1_1600_2021" //Benin
replace cc_q16e_norm=. if id_alex=="cc_English_1_1600_2021" //Benin
replace cc_q16f_norm=. if id_alex=="cc_English_1_1600_2021" //Benin
replace cc_q16g_norm=. if id_alex=="cc_English_1_1600_2021" //Benin
replace all_q78_norm=. if country=="Benin" //Benin
replace cc_q11a_norm=. if country=="Benin" //Benin
replace all_q90_norm=. if country=="Benin" //Benin
replace cj_q40b_norm=. if id_alex=="cj_French_0_1068_2018_2019_2021" //Benin
replace cj_q40c_norm=. if id_alex=="cj_French_0_1068_2018_2019_2021" //Benin
replace cj_q20m_norm=. if id_alex=="cj_French_0_1068_2018_2019_2021" //Benin
replace cj_q12c_norm=. if country=="Benin" //Benin
drop if id_alex=="cc_French_0_928" //Benin
replace cc_q14a_norm=. if id_alex=="cc_French_0_160_2021" //Benin
replace cc_q14b_norm=. if id_alex=="cc_French_0_160_2021" //Benin
replace cc_q14a_norm=. if id_alex=="cc_English_1_720_2021" //Benin
replace cc_q14b_norm=. if id_alex=="cc_English_1_720_2021" //Benin
replace cj_q21h_norm=. if id_alex=="cj_French_0_363_2018_2019_2021" //Benin
replace cj_q20o_norm=. if id_alex=="cj_French_0_363_2018_2019_2021" //Benin
replace cj_q40b_norm=. if id_alex=="cj_French_0_1097_2018_2019_2021" //Benin
replace cj_q40c_norm=. if id_alex=="cj_French_1_1096" //Benin
replace lb_q2d_norm=. if country=="Bosnia and Herzegovina" /*Bosnia and Herzegovina*/ 
replace lb_q3d_norm=. if country=="Bosnia and Herzegovina" /*Bosnia and Herzegovina*/ 
replace all_q59_norm=. if country=="Bosnia and Herzegovina" /*Bosnia and Herzegovina*/ 
replace cj_q20m_norm=. if id_alex=="cj_English_1_30" //Bosnia and Herzegovina
replace cj_q40c_norm=. if id_alex=="cj_English_1_961_2021" //Bosnia and Herzegovina
drop if id_alex=="cc_English_1_963" //Botswana
drop if id_alex=="lb_English_0_246" //Botswana
drop if id_alex=="ph_English_0_562_2018_2019_2021" //Botswana
drop if id_alex=="cj_English_1_696" //Botswana
drop if id_alex=="lb_English_1_289" //Botswana
drop if id_alex=="lb_English_0_351" //Botswana
drop if id_alex=="cc_English_0_1451_2019_2021" //Botswana
drop if id_alex=="lb_English_0_606_2017_2018_2019_2021" //Botswana
drop if id_alex=="cj_English_1_393_2016_2017_2018_2019_2021" //Botswana
replace cj_q21h_norm=. if id_alex=="cj_English_0_544_2021" //Botswana
replace cj_q28_norm=. if id_alex=="cj_English_0_544_2021" //Botswana
drop if id_alex=="lb_English_1_110" //Bulgaria
drop if id_alex=="cc_English_0_1687" //Bulgaria
drop if id_alex=="ph_English_1_568" //Bulgaria
drop if id_alex=="cc_English_1_198_2016_2017_2018_2019_2021" //Bulgaria
replace cj_q11b_norm=. if country=="Burkina Faso" //Burkina Faso
drop if id_alex=="lb_French_1_224" //Burkina Faso
drop if id_alex=="ph_French_0_173" //Burkina Faso
drop if id_alex=="cc_French_1_567" //Burkina Faso
drop if id_alex=="cj_French_0_911" //Burkina Faso
replace all_q87_norm=. if id_alex=="lb_English_0_809_2019_2021" //Burkina Faso
replace all_q86_norm=. if id_alex=="lb_English_0_809_2019_2021" //Burkina Faso
drop if id_alex=="cj_French_1_607_2021" //Burkina Faso
drop if id_alex=="cc_French_1_734" //Burkina Faso
replace cc_q40a_norm=1 if id_alex=="cc_French_0_420_2021" //Burkina Faso
replace cc_q40b_norm=. if id_alex=="cc_French_0_420_2021" //Burkina Faso
replace all_q22_norm=. if id_alex=="cj_French_1_835_2021" //Burkina Faso
replace all_q23_norm=. if id_alex=="cj_French_1_835_2021" //Burkina Faso
replace all_q24_norm=. if id_alex=="cj_French_1_835_2021" //Burkina Faso
replace all_q25_norm=. if id_alex=="cj_French_1_835_2021" //Burkina Faso
replace all_q26_norm=. if id_alex=="cj_French_1_835_2021" //Burkina Faso
replace all_q27_norm=. if id_alex=="cj_French_1_835_2021" //Burkina Faso
replace all_q8_norm=. if id_alex=="cj_French_1_835_2021" //Burkina Faso
replace all_q22_norm=. if id_alex=="lb_French_1_420_2021" //Burkina Faso
replace all_q23_norm=. if id_alex=="lb_French_1_420_2021" //Burkina Faso
replace all_q24_norm=. if id_alex=="lb_French_1_420_2021" //Burkina Faso
replace all_q25_norm=. if id_alex=="lb_French_1_420_2021" //Burkina Faso
replace all_q26_norm=. if id_alex=="lb_French_1_420_2021" //Burkina Faso
replace all_q27_norm=. if id_alex=="lb_French_1_420_2021" //Burkina Faso
replace all_q8_norm=. if id_alex=="lb_French_1_420_2021" //Burkina Faso
replace all_q19_norm=. if id_alex=="cj_French_1_905_2021" //Burkina Faso
replace all_q31_norm=. if id_alex=="cj_French_1_905_2021" //Burkina Faso
replace all_q32_norm=. if id_alex=="cj_French_1_905_2021" //Burkina Faso
replace all_q14_norm=. if id_alex=="cj_French_1_905_2021" //Burkina Faso
replace all_q19_norm=. if id_alex=="cj_English_1_889_2017_2018_2019_2021" //Burkina Faso
replace all_q31_norm=. if id_alex=="cj_English_1_889_2017_2018_2019_2021" //Burkina Faso
replace all_q32_norm=. if id_alex=="cj_English_1_889_2017_2018_2019_2021" //Burkina Faso
replace all_q14_norm=. if id_alex=="cj_English_1_889_2017_2018_2019_2021" //Burkina Faso
replace cc_q9c_norm=. if id_alex=="cc_English_0_835" //Cambodia
replace cc_q40a_norm=. if id_alex=="cc_English_0_835" //Cambodia
replace cc_q40b_norm=. if id_alex=="cc_English_0_835" //Cambodia
replace cc_q9c_norm=. if id_alex=="cc_English_1_1220_2018_2019_2021" //Cambodia
replace cc_q40a_norm=. if id_alex=="cc_English_1_1220_2018_2019_2021" //Cambodia
replace cc_q40b_norm=. if id_alex=="cc_English_1_1220_2018_2019_2021" //Cambodia
replace all_q17_norm=. if id_alex=="lb_English_1_490_2016_2017_2018_2019_2021" //Cambodia
replace all_q16_norm=. if id_alex=="cj_English_1_863_2017_2018_2019_2021" //Cambodia
replace ph_q6b_norm=. if country=="Cameroon" /*Cameroon*/
replace ph_q6d_norm=. if country=="Cameroon" /*Cameroon*/
replace ph_q6e_norm=. if country=="Cameroon" /*Cameroon*/
drop if id_alex=="cc_French_0_1537" //Cameroon
drop if id_alex=="cj_English_0_742" //Cameroon
drop if id_alex=="lb_French_0_287" //Cameroon
replace ph_q5a_norm=. if country=="Cameroon" /*Cameroon*/
replace cc_q27_norm=. if country=="Cameroon" /*Cameroon*/
drop if id_alex=="lb_English_0_611" //Cameroon
replace all_q62_norm=. if id_alex=="cc_English_0_1491_2018_2019_2021" //Cameroon
replace all_q63_norm=. if id_alex=="cc_English_0_1491_2018_2019_2021" //Cameroon
replace all_q62_norm=. if id_alex=="cc_English_0_144" //Cameroon
replace all_q63_norm=. if id_alex=="cc_English_0_144" //Cameroon
replace all_q62_norm=. if id_alex=="lb_French_1_153_2019_2021" //Cameroon
replace all_q63_norm=. if id_alex=="lb_French_1_153_2019_2021" //Cameroon
replace lb_q2d_norm=. if id_alex=="lb_English_0_490_2021" //Cameroon
replace lb_q3d_norm=. if id_alex=="lb_English_0_490_2021" //Cameroon
replace all_q62_norm=. if id_alex=="lb_English_0_490_2021" //Cameroon
replace all_q63_norm=. if id_alex=="lb_English_0_490_2021" //Cameroon
replace lb_q2d_norm=. if id_alex=="lb_English_0_17" //Cameroon
replace lb_q3d_norm=. if id_alex=="lb_English_0_17" //Cameroon
replace all_q62_norm=. if id_alex=="lb_English_0_17" //Cameroon
replace all_q63_norm=. if id_alex=="lb_English_0_17" //Cameroon
drop if id_alex=="cj_English_0_992" //Cameroon
drop if id_alex=="lb_French_0_589_2021" //Cameroon 
replace cc_q9c_norm=. if id_alex=="cc_English_1_364_2018_2019_2021" //Cameroon
replace cc_q40a_norm=. if id_alex=="cc_English_1_364_2018_2019_2021" //Cameroon
replace cc_q40b_norm=. if id_alex=="cc_English_1_364_2018_2019_2021" //Cameroon
replace all_q80_norm=. if country=="Canada" //Canada
replace all_q33_norm=. if id_alex=="lb_English_0_191" //Canada
replace all_q34_norm=. if id_alex=="lb_English_0_191" //Canada
replace all_q35_norm=. if id_alex=="lb_English_0_191" //Canada
replace all_q36_norm=. if id_alex=="lb_English_0_191" //Canada
replace all_q37_norm=. if id_alex=="lb_English_0_191" //Canada
replace all_q38_norm=. if id_alex=="lb_English_0_191" //Canada
replace all_q34_norm=. if id_alex=="cc_French_1_251_2016_2017_2018_2019_2021" //Canada
replace all_q35_norm=. if id_alex=="cc_French_1_251_2016_2017_2018_2019_2021" //Canada
replace all_q36_norm=. if id_alex=="cc_French_1_251_2016_2017_2018_2019_2021" //Canada
replace all_q37_norm=. if id_alex=="cc_French_1_251_2016_2017_2018_2019_2021" //Canada
replace all_q38_norm=. if id_alex=="cc_French_1_251_2016_2017_2018_2019_2021" //Canada
replace all_q86_norm=. if id_alex=="cc_Spanish_1_118" //Chile
drop if id_alex=="cj_English_1_525" //China
drop if id_alex=="ph_English_0_533_2019_2021" //China
drop if id_alex=="ph_English_1_620_2021" //China
drop if id_alex=="ph_English_0_256" //China
drop if id_alex=="cc_English_0_423" //China
drop if id_alex=="cc_English_0_121_2021" //China
drop if id_alex=="cc_English_0_1629" //China
drop if id_alex=="cj_English_0_370_2019_2021" //China
drop if id_alex=="cj_English_0_116_2021" //China
drop if id_alex=="cj_English_0_86" //China
replace cj_q10_norm=. if country=="China" /* China */
replace cj_q28_norm=. if country=="China" /* China */
replace all_q29_norm=. if country=="China" /* China */
replace cj_q38_norm=. if country=="China" /* China */
replace cj_q8_norm=. if country=="China" /* China */
replace cc_q33_norm=. if country=="China" //China
replace cj_q31e_norm=. if country=="China" //China
replace cj_q31f_norm=. if id_alex=="cj_English_0_973" //China
replace cj_q31g_norm=. if id_alex=="cj_English_0_973" //China
replace cj_q42c_norm=. if id_alex=="cj_English_0_973" //China
replace cj_q42d_norm=. if id_alex=="cj_English_0_973" //China
replace cj_q12d_norm=0 if id_alex=="cj_English_0_375_2013_2014_2016_2017_2018_2019_2021" //China
replace cj_q12e_norm=0 if id_alex=="cj_English_0_375_2013_2014_2016_2017_2018_2019_2021" //China
replace cj_q12f_norm=0 if id_alex=="cj_English_0_375_2013_2014_2016_2017_2018_2019_2021" //China
replace cj_q20m_norm=0 if id_alex=="cj_English_0_973" //China
replace cj_q40b_norm=. if id_alex=="cj_English_0_973" //China
replace all_q30_norm=. if id_alex=="cc_English_0_1921_2018_2019_2021" //China
replace cj_q12f_norm=. if id_alex=="cj_English_1_714" //China
replace cj_q12a_norm=. if id_alex=="cj_English_1_714" //China
replace cj_q12c_norm=. if id_alex=="cj_English_1_714" //China
replace cj_q12d_norm=. if id_alex=="cj_English_1_714" //China
replace cj_q12e_norm=. if id_alex=="cj_English_1_714" //China
replace cj_q12a_norm=. if id_alex=="cj_English_1_116" //China
replace lb_q3d_norm=0.333333333 if id_alex=="lb_English_0_632" //China
replace cj_q34a_norm=. if id_alex=="cj_English_0_973" //China
replace cj_q34c_norm=. if id_alex=="cj_English_0_973" //China
replace cj_q34d_norm=. if id_alex=="cj_English_0_973" //China
replace cj_q34e_norm=. if id_alex=="cj_English_0_973" //China
replace cj_q31f_norm=. if id_alex=="cj_English_0_375_2013_2014_2016_2017_2018_2019_2021" //China
replace cj_q15_norm=. if id_alex=="cj_English_1_116" //China
replace cj_q15_norm=. if id_alex=="cj_English_0_973" //China
replace cc_q28e_norm=. if id_alex=="cc_English_1_472_2016_2017_2018_2019_2021" //China
replace cc_q26h_norm=. if id_alex=="cc_English_1_468" //China
replace cj_q20e_norm=. if id_alex=="cj_English_1_116" //China
replace all_q84_norm=. if id_alex=="cc_English_1_468" //China
replace all_q85_norm=. if id_alex=="cc_English_1_468" //China
replace cj_q21a_norm=. if id_alex=="cj_English_0_973" //China
drop if id_alex=="cc_Spanish_0_1048" //Colombia
drop if id_alex=="cc_Spanish_0_156" //Colombia
drop if id_alex=="lb_Spanish_0_122" //Colombia
replace cj_q12e_norm=. if id_alex=="cj_Spanish_0_548" //Colombia
replace cj_q12f_norm=. if id_alex=="cj_Spanish_0_548" //Colombia
replace cj_q12e_norm=. if id_alex=="cj_Spanish_0_371_2016_2017_2018_2019_2021" //Colombia
replace lb_q3d_norm=. if id_alex=="lb_Spanish_0_465_2021" //Colombia
replace cj_q34c_norm=. if id_alex=="cj_Spanish_0_100_2016_2017_2018_2019_2021" //Colombia
replace cj_q34e_norm=. if id_alex=="cj_Spanish_0_100_2016_2017_2018_2019_2021" //Colombia
drop if id_alex=="cc_French_0_899" //Congo, Dem. Rep.
drop if id_alex=="ph_French_1_509" //Congo, Dem. Rep.
drop if id_alex=="cj_French_1_1078" //Congo, Dem. Rep.
drop if id_alex=="ph_French_0_310" //Congo, Dem. Rep.
drop if id_alex=="ph_French_1_211" //Congo, Dem. Rep.
drop if id_alex=="cc_French_0_289" //Congo, Dem. Rep.
drop if id_alex=="lb_French_0_279_2018_2019_2021" //Congo, Dem. Rep.
drop if id_alex=="cj_French_1_934_2021" //Congo, Dem. Rep.
drop if id_alex=="cc_French_1_365_2019_2021" //Congo, Dem. Rep.
replace cj_q11b_norm=0 if id_alex=="cj_French_1_177_2019_2021" //Congo, Dem. Rep.
replace cj_q42c_norm=0 if id_alex=="cj_French_1_177_2019_2021" //Congo, Dem. Rep.
replace cj_q42d_norm=0 if id_alex=="cj_French_1_177_2019_2021" //Congo, Dem. Rep.
replace cj_q11b_norm=0 if id_alex=="cj_English_0_585" //Congo, Dem. Rep.
replace cj_q11b_norm=. if id_alex=="cj_French_0_693" //Congo, Dem. Rep.
replace cj_q42c_norm=. if id_alex=="cj_French_0_693" //Congo, Dem. Rep.
replace cj_q42d_norm=. if id_alex=="cj_French_0_693" //Congo, Dem. Rep.
replace all_q19_norm=0 if id_alex=="cj_French_0_693" //Congo, Dem. Rep.
replace all_q31_norm=0 if id_alex=="cj_French_0_693" //Congo, Dem. Rep.
replace all_q32_norm=0 if id_alex=="cj_French_0_693" //Congo, Dem. Rep.
replace all_q14_norm=0 if id_alex=="cj_French_0_693" //Congo, Dem. Rep.
replace all_q19_norm=0 if id_alex=="cj_English_0_694" //Congo, Dem. Rep.
replace all_q31_norm=0 if id_alex=="cj_English_0_694" //Congo, Dem. Rep.
replace all_q32_norm=0 if id_alex=="cj_English_0_694" //Congo, Dem. Rep.
replace all_q14_norm=0 if id_alex=="cj_English_0_694" //Congo, Dem. Rep.
replace all_q19_norm=0 if id_alex=="cc_French_0_1455_2019_2021" //Congo, Dem. Rep.
replace all_q31_norm=0 if id_alex=="cc_French_0_1455_2019_2021" //Congo, Dem. Rep.
replace all_q32_norm=0 if id_alex=="cc_French_0_1455_2019_2021" //Congo, Dem. Rep.
replace all_q14_norm=0 if id_alex=="cc_French_0_1455_2019_2021" //Congo, Dem. Rep.
drop if id_alex=="ph_French_1_632" //Congo, Rep.
drop if id_alex=="cc_French_1_1113" //Congo, Rep.
drop if id_alex=="cc_French_0_930_2021" //Congo, Rep.
drop if id_alex=="ph_French_0_498_2021" //Congo, Rep.
replace cj_q11b_norm=. if id_alex=="cj_French_0_631" //Congo, Rep.
replace cj_q31e_norm=. if id_alex=="cj_English_0_241" //Congo, Rep.
replace cj_q42d_norm=. if id_alex=="cj_French_0_421_2021" //Congo, Rep.
replace cj_q42c_norm=. if id_alex=="cj_French_0_631" //Congo, Rep.
replace lb_q16d_norm=. if id_alex=="lb_French_0_114" //Congo, Rep.
replace lb_q16e_norm=. if id_alex=="lb_French_0_114" //Congo, Rep.
replace all_q86_norm=. if id_alex=="cc_French_0_1668_2021" //Congo, Rep.
replace all_q86_norm=. if id_alex=="cc_English_0_329" //Congo, Rep.
replace all_q87_norm=. if id_alex=="cc_French_0_1668_2021" //Congo, Rep.
replace all_q87_norm=. if id_alex=="cc_English_0_329" //Congo, Rep.
replace all_q89_norm=. if id_alex=="cc_French_0_71" //Congo, Rep.
replace all_q90_norm=. if id_alex=="cc_French_0_71" //Congo, Rep.
replace all_q91_norm=. if id_alex=="cc_French_0_71" //Congo, Rep.
replace all_q89_norm=. if id_alex=="cc_French_0_294_2021" //Congo, Rep.
replace all_q90_norm=. if id_alex=="cc_French_0_294_2021" //Congo, Rep.
replace all_q91_norm=. if id_alex=="cc_French_0_294_2021" //Congo, Rep.
replace cc_q14b_norm=. if id_alex=="cc_French_0_71" //Congo, Rep.
replace cc_q14b_norm=. if id_alex=="cc_French_0_121" //Congo, Rep.
replace all_q90_norm=. if id_alex=="lb_English_0_108" //Congo, Rep.
replace lb_q23e_norm=. if  country=="Congo, Rep." //Congo, Rep.
replace cj_q31e_norm=. if id_alex=="cj_French_0_631" //Congo, Rep.
replace all_q96_norm=. if id_alex=="cc_French_0_963_2021" //Congo, Rep.
replace all_q96_norm=. if id_alex=="cc_French_0_1668_2021" //Congo, Rep.
replace all_q84_norm=. if id_alex=="cc_French_0_1668_2021" //Congo, Rep.
replace all_q85_norm=. if id_alex=="cc_French_0_1668_2021" //Congo, Rep.
replace all_q84_norm=. if id_alex=="cc_French_0_904" //Congo, Rep.
replace all_q96_norm=. if id_alex=="lb_Spanish_0_358_2019_2021" //Costa Rica
replace all_q96_norm=. if id_alex=="lb_Spanish_0_228_2016_2017_2018_2019_2021" //Costa Rica
replace all_q96_norm=. if id_alex=="cj_Spanish_0_1078_2017_2018_2019_2021" //Costa Rica
replace all_q76_norm=. if id_alex=="cc_Spanish_0_552" //Costa Rica
replace all_q77_norm=. if id_alex=="cc_Spanish_0_552" //Costa Rica
replace all_q78_norm=. if id_alex=="cc_Spanish_0_552" //Costa Rica
replace all_q79_norm=. if id_alex=="cc_Spanish_0_552" //Costa Rica
replace all_q80_norm=. if id_alex=="cc_Spanish_0_552" //Costa Rica
replace all_q81_norm=. if id_alex=="cc_Spanish_0_552" //Costa Rica
drop if id_alex=="cc_French_1_1343" //Cote d'Ivoire
replace all_q81_norm=. if id_alex=="cc_French_0_562" //Cote d'Ivoire
replace all_q81_norm=. if id_alex=="cc_French_0_1649" //Cote d'Ivoire
replace all_q81_norm=. if id_alex=="cc_French_1_224" //Cote d'Ivoire
drop if id_alex=="ph_English_1_368_2016_2017_2018_2019_2021" //Croatia
drop if id_alex=="ph_English_1_262" //Croatia
drop if id_alex=="ph_English_1_762_2021" //Croatia
drop if id_alex=="cj_English_0_407" //Croatia
drop if id_alex=="cj_English_0_357" //Croatia
replace cj_q21a_norm=. if id_alex=="cj_English_0_1028" //Croatia
replace cj_q21e_norm=. if id_alex=="cj_English_0_1028" //Croatia
replace cj_q21g_norm=. if id_alex=="cj_English_0_1028" //Croatia
replace cj_q21h_norm=. if id_alex=="cj_English_0_1028" //Croatia
replace cj_q12a_norm=. if id_alex=="cj_English_1_357" //Croatia
replace cj_q12b_norm=. if id_alex=="cj_English_1_357" //Croatia
replace cj_q12c_norm=. if id_alex=="cj_English_1_357" //Croatia
replace cj_q12d_norm=. if id_alex=="cj_English_1_357" //Croatia
replace cj_q12e_norm=. if id_alex=="cj_English_1_357" //Croatia
replace cj_q12f_norm=. if id_alex=="cj_English_1_357" //Croatia
drop if id_alex=="cc_English_0_953" //Cyprus
drop if id_alex=="cj_English_0_546" //Cyprus
replace all_q62_norm=. if country=="Cyprus" //Cyprus
replace all_q63_norm=. if country=="Cyprus" //Cyprus
replace cc_q26a_norm=. if country=="Cyprus" //Cyprus
replace cc_q26b_norm=. if country=="Cyprus" //Cyprus
replace all_q84_norm=. if country=="Cyprus" //Cyprus
replace cc_q13_norm=. if country=="Cyprus" //Cyprus
replace cc_q16a_norm=. if id_alex=="cc_English_0_698" //Cyprus
replace cc_q16b_norm=. if id_alex=="cc_English_0_698" //Cyprus
replace cc_q16c_norm=. if id_alex=="cc_English_0_698" //Cyprus
replace cc_q16d_norm=. if id_alex=="cc_English_0_698" //Cyprus
replace cc_q16e_norm=. if id_alex=="cc_English_0_698" //Cyprus
replace cc_q16f_norm=. if id_alex=="cc_English_0_698" //Cyprus
replace cc_q16g_norm=. if id_alex=="cc_English_0_698" //Cyprus
replace cc_q16a_norm=. if id_alex=="cc_English_0_672" //Cyprus
replace cc_q16b_norm=. if id_alex=="cc_English_0_672" //Cyprus
replace cc_q16c_norm=. if id_alex=="cc_English_0_672" //Cyprus
replace cc_q16d_norm=. if id_alex=="cc_English_0_672" //Cyprus
replace cc_q16e_norm=. if id_alex=="cc_English_0_672" //Cyprus
replace cc_q16f_norm=. if id_alex=="cc_English_0_672" //Cyprus
replace cc_q16g_norm=. if id_alex=="cc_English_0_672" //Cyprus
replace all_q88_norm=. if id_alex=="cc_English_0_886_2021" //Cyprus
replace all_q88_norm=. if id_alex=="cc_English_0_432_2021" //Cyprus
replace cc_q14b_norm=. if id_alex=="cc_English_0_1330" //Cyprus
replace cc_q14b_norm=. if id_alex=="cc_English_0_698" //Cyprus
replace cc_q14a_norm=. if id_alex=="cc_English_0_1330" //Cyprus
replace cc_q14a_norm=. if id_alex=="cc_English_0_698" //Cyprus
replace all_q76_norm=. if id_alex=="lb_English_0_594" //Cyprus
replace all_q77_norm=. if id_alex=="lb_English_0_594" //Cyprus
replace all_q78_norm=. if id_alex=="lb_English_0_594" //Cyprus
replace all_q79_norm=. if id_alex=="lb_English_0_594" //Cyprus
replace all_q80_norm=. if id_alex=="lb_English_0_594" //Cyprus
replace all_q81_norm=. if id_alex=="lb_English_0_594" //Cyprus
replace all_q82_norm=. if id_alex=="lb_English_0_594" //Cyprus
replace all_q88_norm=. if id_alex=="lb_English_0_57_2021" //Cyprus
replace all_q88_norm=. if id_alex=="lb_English_0_674_2021" //Cyprus
replace all_q89_norm=. if id_alex=="cc_English_0_1330" //Cyprus
replace all_q89_norm=. if id_alex=="cc_English_0_698" //Cyprus
replace all_q88_norm=. if id_alex=="cc_English_1_1427_2021" //Czech Republic
replace all_q78_norm=. if country=="Denmark" /*Denmark*/
replace lb_q16c_norm=. if country=="Denmark" /*Denmark*/
replace all_q79_norm=. if country=="Denmark" /*Denmark*/
replace lb_q16d_norm=. if country=="Denmark" /*Denmark*/
replace ph_q6d_norm=. if country=="Denmark" /*Denmark*/
replace lb_q16e_norm=. if country=="Denmark" /*Denmark*/
replace all_q29_norm=. if country=="Denmark" /*Denmark*/
drop if id_alex=="ph_Spanish_0_68_2013_2014_2016_2017_2018_2019_2021" //Dominican Republic
drop if id_alex=="cc_Spanish (Mexico)_0_1068_2019_2021" //Dominican Republic
drop if id_alex=="cj_Spanish_0_1110_2019_2021" //Dominican Republic
replace cj_q10_norm=. if id_alex=="cj_Spanish_1_1086" //Dominican Republic
replace cj_q10_norm=. if id_alex=="cj_Spanish_1_1087" //Dominican Republic
replace all_q76_norm=. if id_alex=="cc_Spanish_0_696_2016_2017_2018_2019_2021" //Dominican Republic
replace all_q77_norm=. if id_alex=="cc_Spanish_0_696_2016_2017_2018_2019_2021" //Dominican Republic
replace all_q78_norm=. if id_alex=="cc_Spanish_0_696_2016_2017_2018_2019_2021" //Dominican Republic
replace all_q79_norm=. if id_alex=="cc_Spanish_0_696_2016_2017_2018_2019_2021" //Dominican Republic
replace all_q80_norm=. if id_alex=="cc_Spanish_0_696_2016_2017_2018_2019_2021" //Dominican Republic
replace all_q81_norm=. if id_alex=="cc_Spanish_0_696_2016_2017_2018_2019_2021" //Dominican Republic
replace all_q82_norm=. if id_alex=="cc_Spanish_0_696_2016_2017_2018_2019_2021" //Dominican Republic
replace all_q76_norm=. if id_alex=="cc_Spanish_0_787_2021" //Dominican Republic
replace all_q77_norm=. if id_alex=="cc_Spanish_0_787_2021" //Dominican Republic
replace all_q78_norm=. if id_alex=="cc_Spanish_0_787_2021" //Dominican Republic
replace all_q79_norm=. if id_alex=="cc_Spanish_0_787_2021" //Dominican Republic
replace all_q80_norm=. if id_alex=="cc_Spanish_0_787_2021" //Dominican Republic
replace all_q81_norm=. if id_alex=="cc_Spanish_0_787_2021" //Dominican Republic
replace all_q82_norm=. if id_alex=="cc_Spanish_0_787_2021" //Dominican Republic
drop if id_alex=="cc_Arabic_0_1373" //Egypt  
drop if id_alex=="cc_Arabic_0_320" //Egypt
drop if id_alex=="lb_English_0_633" //Egypt
drop if id_alex=="ph_English_0_325_2021" //Egypt
drop if id_alex=="ph_English_1_76" //Egypt
drop if id_alex=="cj_English_1_268" //Egypt
drop if id_alex=="cc_Arabic_0_1711" //Egypt
drop if id_alex=="cc_English_0_935_2019_2021" //Egypt
drop if id_alex=="lb_English_0_555_2019_2021" //Egypt
drop if id_alex=="cj_English_0_378" //Egypt
replace lb_q3d_norm=0.4 if id_alex=="lb_Arabic_0_28" //Egypt
replace lb_q19a_norm=. if id_alex=="lb_English_0_240_2018_2019_2021" //Egypt
replace all_q62_norm=. if id_alex=="cc_English_1_543" //Egypt
replace all_q63_norm=. if id_alex=="cc_English_1_543" //Egypt
replace all_q63_norm=. if id_alex=="cc_Arabic_0_1010_2021" //Egypt
replace all_q96_norm=. if id_alex=="cc_English_0_901" //Egypt 
replace all_q62_norm=0 if id_alex=="cc_English_0_938_2019_2021" //Egypt
drop if id_alex=="cj_English_0_438" //Estonia
drop if id_alex=="cj_English_1_125" //Estonia
drop if id_alex=="cc_English_1_919" //Estonia
replace cj_q21g_norm=. if id_alex=="cj_English_0_553" //Estonia
replace cj_q21h_norm=. if id_alex=="cj_English_0_553" //Estonia
replace cj_q21g_norm=. if id_alex=="cj_English_0_141_2016_2017_2018_2019_2021" //Estonia
replace cj_q21h_norm=. if id_alex=="cj_English_0_141_2016_2017_2018_2019_2021" //Estonia
replace cj_q21g_norm=. if id_alex=="cj_English_0_753" //Estonia
replace cj_q21h_norm=. if id_alex=="cj_English_0_753" //Estonia
replace cj_q15_norm=. if id_alex=="cj_English_0_553" //Estonia
replace cj_q15_norm=. if id_alex=="cj_Spanish_0_706" // El Salvador
replace cj_q28_norm=. if id_alex=="cj_Spanish_1_1131" //El Salvador
replace cj_q28_norm=. if id_alex=="cj_Spanish_1_27" //El Salvador
replace cj_q10_norm=. if country=="El Salvador" //El Salvador
drop if id_alex=="cj_Spanish_1_1131" //El Salvador 
drop if id_alex=="cj_English_1_770" //Ethiopia
drop if id_alex=="cj_English_1_725" //Ethiopia
drop if id_alex=="lb_English_1_508" //Ethiopia
drop if id_alex=="cc_English_0_1499" //Ethiopia
drop if id_alex=="cc_English_1_1190_2021" //Ethiopia
replace all_q18_norm=0 if id_alex=="cc_English_0_858" //Ethiopia
replace all_q16_norm=0 if id_alex=="cc_English_0_858" //Ethiopia
replace all_q16_norm=0 if id_alex=="cc_English_0_493_2018_2019_2021" //Ethiopia
replace all_q16_norm=0 if id_alex=="cc_English_0_725_2018_2019_2021" //Ethiopia
replace all_q19_norm=0 if id_alex=="cc_English_1_1397" //Ethiopia
replace all_q20_norm=0 if id_alex=="cc_English_1_1397" //Ethiopia
replace all_q21_norm=0 if id_alex=="cc_English_1_1397" //Ethiopia
replace cj_q31e_norm=. if id_alex=="cj_English_0_437_2021" //Ethiopia
replace cj_q42c_norm=. if id_alex=="cj_English_0_437_2021" //Ethiopia
replace cj_q42d_norm=. if id_alex=="cj_English_0_437_2021" //Ethiopia
replace cj_q10_norm=. if id_alex=="cj_English_0_437_2021" //Ethiopia
replace cj_q42c_norm=0 if id_alex=="cj_English_0_824" //Ethiopia
replace cj_q42d_norm=0 if id_alex=="cj_English_0_824" //Ethiopia
replace cj_q31e_norm=. if id_alex=="cj_English_1_1166_2021" //Ethiopia
replace lb_q16a_norm=. if id_alex=="lb_English_1_447" //Ethiopia
replace lb_q16b_norm=. if id_alex=="lb_English_1_447" //Ethiopia
replace lb_q16c_norm=. if id_alex=="lb_English_1_447" //Ethiopia
replace lb_q16d_norm=. if id_alex=="lb_English_1_447" //Ethiopia
replace lb_q16e_norm=. if id_alex=="lb_English_1_447" //Ethiopia
replace all_q88_norm=. if id_alex=="cc_English_0_1452" //Finland
replace cc_q26a_norm=. if id_alex=="cc_English_0_1452" //Finland
replace all_q88_norm=. if id_alex=="cc_English_1_597" //Finland
replace cj_q42c_norm=. if id_alex=="cj_English_1_295" //Finland 
replace cj_q42d_norm=. if id_alex=="cj_English_1_295" //Finland 
drop if id_alex=="cj_French_1_429" //France
replace all_q48_norm=. if id_alex=="cc_English_0_827" //France
replace all_q49_norm=. if id_alex=="cc_English_0_827" //France
replace all_q50_norm=. if id_alex=="cc_English_0_827" //France
replace all_q76_norm=. if id_alex=="cc_English_0_827" //France
replace all_q77_norm=. if id_alex=="cc_English_0_827" //France
replace all_q78_norm=. if id_alex=="cc_English_0_827" //France
replace all_q79_norm=. if id_alex=="cc_English_0_827" //France
replace all_q80_norm=. if id_alex=="cc_English_0_827" //France
replace all_q81_norm=. if id_alex=="cc_English_0_827" //France
replace all_q48_norm=. if id_alex=="lb_French_0_450" //France
replace cj_q40b_norm=. if id_alex=="cj_French_0_111" //France
replace cj_q40c_norm=. if id_alex=="cj_French_0_111" //France
replace cj_q20m_norm=. if id_alex=="cj_French_0_111" //France
drop if id_alex=="cj_English_0_52" //The Gambia
replace cj_q38_norm=. if country=="Gambia" //The Gambia
replace cc_q40a_norm=. if id_alex=="cc_English_0_559" //The Gambia
replace cc_q40a_norm=. if id_alex=="cc_English_0_141" //The Gambia
replace cc_q40b_norm=. if id_alex=="cc_English_0_559" //The Gambia
replace cc_q40b_norm=. if id_alex=="cc_English_0_141" //The Gambia
replace cc_q9c_norm=. if id_alex=="cc_English_0_141" //The Gambia
replace cj_q31e_norm=. if id_alex=="cj_English_1_397" //The Gambia
replace cj_q42c_norm=. if id_alex=="cj_English_0_628_2019_2021" //The Gambia
replace cj_q42c_norm=. if id_alex=="cj_English_0_52" //The Gambia
replace cj_q42d_norm=. if id_alex=="cj_English_0_628_2019_2021" //The Gambia
replace cj_q10_norm=. if id_alex=="cj_English_0_270" //The Gambia
replace cj_q21d_norm=. if country=="Gambia" //The Gambia
replace cj_q6d_norm=. if country=="Gambia" //The Gambia
replace cj_q22a_norm=. if country=="Gambia" //The Gambia
replace cj_q21g_norm=. if id_alex=="cj_English_0_270" //The Gambia
replace cj_q21g_norm=. if id_alex=="cj_English_1_211" //The Gambia
replace cj_q28_norm=. if id_alex=="cj_English_1_397" //The Gambia
replace cj_q20o_norm=. if id_alex=="cj_English_1_397" //The Gambia
replace lb_q16b_norm=. if id_alex=="lb_English_1_331" //The Gambia
replace lb_q16d_norm=. if id_alex=="lb_English_1_331" //The Gambia
replace lb_q16f_norm=. if id_alex=="lb_English_1_331" //The Gambia
replace all_q77_norm=. if id_alex=="lb_English_1_331" //The Gambia
replace all_q81_norm=. if id_alex=="lb_English_1_331" //The Gambia
replace all_q48_norm=. if id_alex=="lb_English_1_786" //The Gambia
replace all_q49_norm=. if id_alex=="lb_English_1_786" //The Gambia
replace all_q50_norm=. if id_alex=="lb_English_1_786" //The Gambia
replace lb_q19a_norm=. if id_alex=="lb_English_1_786" //The Gambia
replace all_q76_norm=. if id_alex=="cc_English_0_141" //The Gambia
replace all_q77_norm=. if id_alex=="cc_English_0_141" //The Gambia
replace all_q78_norm=. if id_alex=="cc_English_0_141" //The Gambia
replace all_q79_norm=. if id_alex=="cc_English_0_141" //The Gambia
replace all_q80_norm=. if id_alex=="cc_English_0_141" //The Gambia
replace all_q81_norm=. if id_alex=="cc_English_0_141" //The Gambia
replace lb_q16b_norm=. if id_alex=="lb_English_1_786" //The Gambia
replace lb_q16f_norm=. if id_alex=="lb_English_1_331" //The Gambia
replace lb_q23c_norm=. if id_alex=="lb_English_1_331" //The Gambia
replace lb_q23f_norm=. if id_alex=="lb_English_1_331" //The Gambia
replace all_q53_norm=. if id_alex=="lb_English_0_646_2019_2021" //The Gambia
replace all_q12_norm=. if id_alex=="cc_English_0_1646_2021" //The Gambia
replace all_q76_norm=. if id_alex=="cc_English_0_559" //The Gambia
replace all_q77_norm=. if id_alex=="cc_English_0_559" //The Gambia
replace all_q78_norm=. if id_alex=="cc_English_0_559" //The Gambia
replace all_q79_norm=. if id_alex=="cc_English_0_559" //The Gambia
replace all_q80_norm=. if id_alex=="cc_English_0_559" //The Gambia
replace all_q81_norm=. if id_alex=="cc_English_0_559" //The Gambia
replace cj_q20o_norm=. if id_alex=="cj_English_0_1164_2019_2021" //The Gambia
replace cc_q26b_norm=. if id_alex=="cc_English_0_1273" //The Gambia
replace all_q22_norm=. if id_alex=="cj_English_0_270" //The Gambia
replace all_q24_norm=. if id_alex=="cj_English_0_270" //The Gambia
replace all_q25_norm=. if id_alex=="cj_English_0_270" //The Gambia
replace all_q23_norm=. if id_alex=="cc_English_0_141" //The Gambia
replace lb_q16e_norm=. if id_alex=="lb_English_1_331" //The Gambia
replace lb_q16f_norm=. if id_alex=="lb_English_1_786" //The Gambia
replace lb_q23f_norm=. if id_alex=="lb_English_0_646_2019_2021" //The Gambia
drop if id_alex=="cc_English_0_639" //Georgia
drop if id_alex=="cc_English_0_864" //Germany
drop if id_alex=="cc_English_0_959" //Germany
drop if id_alex=="cc_English_0_118" //Ghana
drop if id_alex=="cj_English_0_998" //Ghana
replace cj_q25c_norm=. if country=="Ghana" //Ghana
replace cj_q20e_norm=. if id_alex=="cj_English_0_993" //Ghana
replace cj_q20e_norm=. if id_alex=="cj_English_0_150" //Ghana
replace all_q76_norm=. if id_alex=="cc_English_1_142" //Ghana
replace all_q77_norm=. if id_alex=="cc_English_1_142" //Ghana
replace all_q78_norm=. if id_alex=="cc_English_1_142" //Ghana
replace all_q79_norm=. if id_alex=="cc_English_1_142" //Ghana
replace all_q80_norm=. if id_alex=="cc_English_1_142" //Ghana
replace all_q81_norm=. if id_alex=="cc_English_1_142" //Ghana
replace all_q82_norm=. if id_alex=="cc_English_1_142" //Ghana
replace lb_q19a_norm=. if country=="Greece" //Greece
drop if id_alex=="cj_English_0_724" //Greece
drop if id_alex=="cj_English_0_610" //Greece
drop if id_alex=="cj_English_0_704" //Greece
drop if id_alex=="cj_English_1_830" //Greece
replace cj_q31f_norm=. if id_alex=="cj_English_1_199" //Greece
replace cj_q31g_norm=. if id_alex=="cj_English_1_199" //Greece
replace cj_q42c_norm=. if id_alex=="cj_English_1_199" //Greece
replace cj_q42d_norm=. if id_alex=="cj_English_1_199" //Greece
drop if id_alex=="cc_English_1_793" //Greece
replace cc_q9c_norm=. if id_alex=="cc_English_1_605" //Greece
replace cc_q40b_norm=. if id_alex=="cc_English_0_861_2021" //Greece
replace all_q13_norm=. if id_alex=="cj_English_1_901" //Greece
replace all_q16_norm=. if id_alex=="cj_English_1_901" //Greece
replace all_q17_norm=. if id_alex=="cj_English_1_901" //Greece
replace all_q19_norm=. if id_alex=="cj_English_1_901" //Greece
replace all_q16_norm=. if id_alex=="cc_English_0_823_2018_2019_2021" //Greece
replace all_q19_norm=. if id_alex=="cc_English_0_823_2018_2019_2021" //Greece
replace cc_q11a_norm=. if id_alex=="cc_English_0_1585_2021" //Greece
replace cc_q16a_norm=. if id_alex=="cc_English_0_1585_2021" //Greece
replace cc_q10_norm=. if id_alex=="cc_English_0_1572" //Greece
replace cc_q16a_norm=. if id_alex=="cc_English_0_1572" //Greece
replace all_q50_norm=. if id_alex=="cc_English_0_861_2021" //Greece
replace cj_q42c_norm=. if id_alex=="cj_English_0_792" //Greece
replace cj_q42d_norm=. if id_alex=="cj_English_0_792" //Greece
drop if id_alex=="cj_Spanish_1_236" //Guatemala
drop if id_alex=="cc_Spanish_0_171" //Guatemala
replace cc_q40a_norm=. if id_alex=="cc_English_1_1110" //Guatemala
replace cc_q40a_norm=. if id_alex=="cc_Spanish_1_289" //Guatemala
replace cc_q32h_norm=. if id_alex=="cc_Spanish_0_66" //Guatemala
replace cc_q39a_norm=. if id_alex=="cc_English_1_769_2021" //Guatemala
replace cc_q39a_norm=. if id_alex=="cc_Spanish_0_1160" //Guatemala
replace cc_q39b_norm=. if id_alex=="cc_English_1_769_2021" //Guatemala
replace cc_q39c_norm=. if id_alex=="cc_English_1_769_2021" //Guatemala
replace cc_q39e_norm=. if id_alex=="cc_English_1_769_2021" //Guatemala
replace cc_q39b_norm=. if id_alex=="cc_Spanish_0_561_2016_2017_2018_2019_2021" //Guatemala
replace cc_q39c_norm=. if id_alex=="cc_Spanish_0_561_2016_2017_2018_2019_2021" //Guatemala
replace cc_q39e_norm=. if id_alex=="cc_Spanish_0_561_2016_2017_2018_2019_2021" //Guatemala
drop if id_alex=="cc_French_1_365" //Guinea
drop if id_alex=="ph_French_0_166" //Guinea
replace cj_q38_norm=. if country=="Guinea" //Guinea
replace cj_q36c_norm=. if id_alex=="cj_English_1_1167" //Guinea
replace cj_q8_norm=. if id_alex=="cj_English_1_1167" //Guinea
replace all_q29_norm=. if id_alex=="cj_English_1_1167" //Guinea
replace all_q30_norm=. if id_alex=="cj_English_1_1167" //Guinea
replace all_q29_norm=. if id_alex=="cj_French_0_1007" //Guinea
replace all_q30_norm=. if id_alex=="cj_French_0_1007" //Guinea
replace all_q29_norm=. if id_alex=="cc_French_1_808_2019_2021" //Guinea
replace all_q30_norm=. if id_alex=="cc_French_1_808_2019_2021" //Guinea
drop if id_alex=="cc_French_0_1070_2021" //Haiti
drop if id_alex=="cc_French_0_1628" //Haiti
drop if id_alex=="lb_French_0_643" //Haiti
drop if id_alex=="ph_English_0_222_2021" //Haiti
drop if id_alex=="cj_French_0_912_2021" //Haiti
drop if id_alex=="cj_French_0_1054" //Haiti
replace cj_q15_norm=. if id_alex=="cj_French_0_916" //Haiti
replace lb_q2d_norm=. if id_alex=="lb_French_0_76_2021" //Haiti
replace all_q63_norm=. if id_alex=="cc_French_0_1193_2021" //Haiti
replace all_q90_norm=. if country=="Haiti" //Haiti
replace all_q89_norm=. if country=="Haiti" //Haiti
replace cc_q14b_norm=. if country=="Haiti" //Haiti
replace cc_q9c_norm=. if id_alex=="cc_French_0_1567" //Haiti
replace cc_q40a_norm=. if id_alex=="cc_French_0_1567" //Haiti
replace cc_q40b_norm=. if id_alex=="cc_French_0_1567" //Haiti
replace cj_q31f_norm=. if id_alex=="cj_French_0_849_2021" //Haiti
replace cj_q31g_norm=. if id_alex=="cj_French_0_849_2021" //Haiti
replace all_q1_norm=. if id_alex=="cc_English_0_1119" //Haiti
replace all_q1_norm=. if id_alex=="lb_English_0_310_2021" //Haiti
replace all_q2_norm=. if id_alex=="cc_English_1_292" //Haiti
replace all_q20_norm=. if id_alex=="cc_English_0_1119" //Haiti
replace all_q1_norm=. if id_alex=="lb_English_1_411" //Haiti
replace all_q2_norm=. if id_alex=="lb_English_1_411" //Haiti
replace all_q20_norm=. if id_alex=="lb_English_1_411" //Haiti
replace all_q21_norm=. if id_alex=="lb_English_1_411" //Haiti
replace all_q15_norm=. if id_alex=="cc_English_0_1119" //Haiti
replace all_q16_norm=. if id_alex=="cc_English_0_1119" //Haiti
replace all_q18_norm=. if id_alex=="cc_English_0_1119" //Haiti
replace all_q19_norm=. if id_alex=="cc_English_0_1119" //Haiti
replace all_q21_norm=. if id_alex=="cc_English_0_1119" //Haiti
drop if id_alex=="cc_Spanish_0_294" // Honduras
drop if id_alex=="cj_Spanish_0_425_2017_2018_2019_2021" // Honduras
drop if id_alex=="lb_Spanish_0_243_2018_2019_2021" // Honduras
drop if id_alex=="ph_Spanish_0_228_2019_2021" // Honduras
replace cj_q11a_norm=. if id_alex=="cj_Spanish_0_1126_2019_2021" //Honduras
replace cj_q11b_norm=. if id_alex=="cj_Spanish_0_1126_2019_2021" //Honduras
replace cj_q15_norm=. if id_alex=="cj_Spanish_0_910" //Honduras
replace cj_q15_norm=. if id_alex=="cj_Spanish_0_288" //Honduras
replace cj_q31e_norm=. if id_alex=="cj_Spanish_0_313_2017_2018_2019_2021" //Honduras
replace cj_q42c_norm=. if id_alex=="cj_Spanish_0_313_2017_2018_2019_2021" //Honduras
replace cj_q42d_norm=. if id_alex=="cj_Spanish_0_313_2017_2018_2019_2021" //Honduras



drop if id_alex=="cc_English_0_475_2018_2019_2021" // Honduras New
drop if id_alex=="cc_es-mx_0_1962_2018_2019_2021" // Honduras New
drop if id_alex=="lb_English_1_210_2019_2021" // Honduras New
drop if id_alex=="cj_English_0_1309_2018_2019_2021" // Honduras New
drop if id_alex=="cj_Spanish_1_53_2019_2021" // Honduras New
replace all_q96_norm=. if id_alex=="cc_English_0_141_2017_2018_2019_2021" // Honduras New
replace all_q96_norm=. if id_alex=="cc_es-mx_1_679_2018_2019_2021" // Honduras New
replace all_q96_norm=. if id_alex=="cj_Spanish_0_240_2019_2021" // Honduras New
replace all_q96_norm=. if id_alex=="lb_Spanish_1_396_2016_2017_2018_2019_2021" // Honduras New
replace all_q96_norm=. if id_alex=="cj_Spanish_0_821_2018_2019_2021" // Honduras New
replace all_q96_norm=. if id_alex=="cj_English_0_122_2018_2019_2021" // Honduras New
replace all_q96_norm=. if id_alex=="cc_English_1_1521_2019_2021" // Honduras New
replace cj_q15_norm=. if id_alex=="cj_Spanish_1_288_2021" // Honduras New
replace cj_q15_norm=. if id_alex=="cj_Spanish_0_651_2018_2019_2021" // Honduras New
replace cj_q15_norm=. if id_alex=="cj_Spanish_0_821_2018_2019_2021" // Honduras New
replace cj_q15_norm=. if id_alex=="cj_Spanish_1_678_2019_2021" // Honduras New
replace all_q59_norm=. if id_alex=="cc_Spanish_1_642" // Honduras New
replace all_q91_norm=. if id_alex=="cc_English_0_1086_2016_2017_2018_2019_2021" // Honduras New
replace all_q89_norm=. if id_alex=="cc_English_1_1521_2019_2021" // Honduras New
replace all_q49_norm=. if id_alex=="cc_English_0_287_2016_2017_2018_2019_2021" // Honduras New
replace all_q59_norm=. if id_alex=="cc_Spanish_1_338_2016_2017_2018_2019_2021" // Honduras New
replace  cc_q14a_norm=. if id_alex=="cc_Spanish_1_338_2016_2017_2018_2019_2021" // Honduras New
replace  cc_q14b_norm=. if id_alex=="cc_Spanish_1_338_2016_2017_2018_2019_2021" // Honduras New
replace  cc_q26b_norm=. if id_alex=="cc_English_0_287_2016_2017_2018_2019_2021" // Honduras New
 


drop if id_alex=="cc_English_0_610" //Hong Kong SAR, China
drop if id_alex=="cj_English_0_536" //Hong Kong SAR, China
drop if id_alex=="cc_English_1_980_2019_2021" //Hong Kong SAR, China
drop if id_alex=="cj_English_0_176" //Hong Kong SAR, China
drop if id_alex=="cc_English_0_830_2021" //Hong Kong SAR, China
replace all_q62_norm=. if id_alex=="lb_English_1_506" //Hong Kong SAR, China
replace all_q63_norm=. if id_alex=="lb_English_1_506" //Hong Kong SAR, China
replace lb_q2d_norm=. if id_alex=="lb_English_1_698" //Hong Kong SAR, China
replace lb_q3d_norm=. if id_alex=="lb_English_1_698" //Hong Kong SAR, China
replace all_q48_norm=. if id_alex=="lb_English_1_698" //Hong Kong SAR, China
replace all_q49_norm=. if id_alex=="lb_English_1_698" //Hong Kong SAR, China
replace all_q50_norm=. if id_alex=="lb_English_1_698" //Hong Kong SAR, China
replace lb_q19a_norm=. if id_alex=="lb_English_1_698" //Hong Kong SAR, China
replace all_q89_norm=. if id_alex=="cc_English_1_1015" //Hong Kong SAR, China
replace all_q90_norm=. if id_alex=="cc_English_1_1015" //Hong Kong SAR, China
replace all_q91_norm=. if id_alex=="cc_English_0_438_2017_2018_2019_2021" //Hong Kong SAR, China
replace all_q89_norm=. if id_alex=="cc_English_1_798" //Hong Kong SAR, China
replace all_q90_norm=. if id_alex=="cc_English_1_798" //Hong Kong SAR, China
replace all_q91_norm=. if id_alex=="cc_English_1_798" //Hong Kong SAR, China
replace all_q89_norm=. if id_alex=="cc_English_0_798" //Hong Kong SAR, China
replace all_q90_norm=. if id_alex=="cc_English_0_798" //Hong Kong SAR, China
replace all_q91_norm=. if id_alex=="cc_English_0_798" //Hong Kong SAR, China
replace cj_q40b_norm=. if id_alex=="cj_English_1_1035" //Hong Kong SAR, China
replace cj_q40c_norm=. if id_alex=="cj_English_1_1035" //Hong Kong SAR, China
replace cj_q20m_norm=. if id_alex=="cj_English_1_1035" //Hong Kong SAR, China
replace all_q62_norm=. if id_alex=="cc_English_0_1092_2021" //Hong Kong SAR, China
replace all_q63_norm=. if id_alex=="cc_English_0_1092_2021" //Hong Kong SAR, China
replace lb_q2d_norm=. if id_alex=="lb_English_1_63_2018_2019_2021" //Hong Kong SAR, China
replace all_q84_norm=. if id_alex=="cc_English_0_1003" //Hong Kong SAR, China
replace all_q85_norm=. if id_alex=="cc_English_0_1003" //Hong Kong SAR, China
replace cc_q13_norm=. if id_alex=="cc_English_0_1003" //Hong Kong SAR, China
replace all_q88_norm=. if id_alex=="cc_English_0_1003" //Hong Kong SAR, China
replace cc_q26a_norm=. if id_alex=="cc_English_0_1003" //Hong Kong SAR, China
replace all_q90_norm=. if id_alex=="cc_English_0_1481_2021" //Hong Kong SAR, China
replace all_q91_norm=. if id_alex=="cc_English_0_1481_2021" //Hong Kong SAR, China
replace all_q89_norm=. if id_alex=="cc_English_0_791" //Hong Kong SAR, China
drop if id_alex=="cj_English_1_705" //Hungary
drop if id_alex=="cj_English_1_86" //Hungary
drop if id_alex=="cj_English_1_463" //Hungary
drop if id_alex=="cc_English_0_1691_2018_2019_2021" 
replace cj_q32d_norm=. if country=="Hungary" //Hungary
replace cj_q31e_norm=. if country=="Hungary" //Hungary
replace cj_q11b_norm=. if country=="Hungary" //Hungary
replace cj_q12b_norm=. if country=="Hungary" //Hungary
replace cj_q12d_norm=. if country=="Hungary" //Hungary
replace cj_q34a_norm=. if country=="Hungary" //Hungary
replace cj_q34b_norm=. if country=="Hungary" //Hungary
replace cj_q34e_norm=. if country=="Hungary" //Hungary
replace cj_q33a_norm=. if country=="Hungary" //Hungary
replace cj_q33b_norm=. if country=="Hungary" //Hungary
replace cj_q22e_norm=. if country=="Hungary" //Hungary
replace cj_q31c_norm=. if country=="Hungary" //Hungary
replace cj_q6c_norm=. if country=="Hungary" //Hungary
replace cj_q22a_norm=. if country=="Hungary" //Hungary
replace all_q85_norm=. if country=="Hungary" //Hungary
replace all_q62_norm=. if id_alex=="cc_English_1_809" //Hungary
replace all_q63_norm=. if id_alex=="cc_English_1_809" //Hungary
replace all_q77_norm=. if country=="Hungary" //Hungary
replace cc_q26a_norm=. if country=="Hungary" //Hungary
replace cc_q40b_norm=. if id_alex=="cc_English_1_1552_2019_2021" //Hungary
drop if id_alex=="cc_English_0_1691_2018_2019_2021" //Hungary
drop if id_alex=="lb_English_0_120_2021" //Hungary
replace all_q29_norm=. if id_alex=="cj_English_1_90" //Hungary
replace all_q30_norm=. if id_alex=="cj_English_1_90" //Hungary
replace all_q29_norm=. if id_alex=="cc_English_1_809" //Hungary
replace all_q30_norm=. if id_alex=="cc_English_1_809" //Hungary
replace all_q29_norm=. if id_alex=="cj_English_1_354_2021" //Hungary
replace all_q30_norm=. if id_alex=="cj_English_1_354_2021" //Hungary
replace cc_q40b_norm=. if id_alex=="cc_English_1_1154" //Hungary
replace cc_q40a_norm=. if id_alex=="cc_English_1_1022_2019_2021" //Hungary
replace cc_q40b_norm=. if id_alex=="cc_English_1_1022_2019_2021" //Hungary
replace all_q3_norm=. if id_alex=="lb_English_0_398_2021" //Hungary
replace all_q4_norm=. if id_alex=="lb_English_0_398_2021" //Hungary
replace all_q7_norm=. if id_alex=="lb_English_0_398_2021" //Hungary
replace cc_q13_norm=. if id_alex=="cc_English_1_1050" //Hungary
replace all_q88_norm=. if id_alex=="cc_English_1_1050" //Hungary
replace all_q71_norm=. if id_alex=="cc_English_1_95" //Hungary
replace all_q72_norm=. if id_alex=="cc_English_1_95" //Hungary
replace all_q71_norm=. if id_alex=="cc_English_1_1154" //Hungary
replace all_q72_norm=. if id_alex=="cc_English_1_1154" //Hungary

drop if id_alex=="cc_English_0_485" //India
drop if id_alex=="cc_English_1_506" //India
drop if id_alex=="cj_English_0_937" //India
drop if id_alex=="lb_English_0_452" //India
drop if id_alex=="cc_English_0_1280_2016_2017_2018_2019_2021" //India
drop if id_alex=="cc_English_1_1583_2021" //India
drop if id_alex=="cc_English_0_1541" //India
drop if id_alex=="cc_English_0_505" //India
drop if id_alex=="cj_English_0_352" //India
drop if id_alex=="lb_English_0_188" //India
drop if id_alex=="ph_English_0_482_2018_2019_2021" //India
replace cj_q20o_norm=. if id_alex=="cj_English_0_475_2018_2019_2021" //India
replace cj_q20o_norm=. if id_alex=="cj_English_0_705_2019_2021" //India
replace cj_q20o_norm=. if id_alex=="cj_English_1_1122_2021" //India
drop if id_alex=="cj_English_1_1122_2021" //India 
replace all_q14_norm=. if id_alex=="cc_English_1_1063_2021" //India
replace all_q15_norm=. if id_alex=="cc_English_1_1063_2021" //India
replace all_q16_norm=. if id_alex=="cc_English_1_1063_2021" //India
replace all_q18_norm=. if id_alex=="cc_English_1_1063_2021" //India
replace all_q19_norm=. if id_alex=="cc_English_1_1063_2021" //India
replace all_q20_norm=. if id_alex=="cc_English_1_1063_2021" //India
replace all_q21_norm=. if id_alex=="cc_English_1_1063_2021" //India
replace all_q14_norm=0 if id_alex=="cc_English_1_1261" //India
replace all_q15_norm=0 if id_alex=="cc_English_1_1261" //India
replace all_q16_norm=0 if id_alex=="cc_English_1_1261" //India
replace all_q18_norm=0 if id_alex=="cc_English_1_1261" //India
replace all_q19_norm=0 if id_alex=="cc_English_1_1261" //India
replace all_q20_norm=0 if id_alex=="cc_English_1_1261" //India
replace all_q21_norm=0 if id_alex=="cc_English_1_1261" //India
replace cj_q11b_norm=0 if id_alex=="cj_English_1_538_2019_2021" //India
replace cj_q31e_norm=0 if id_alex=="cj_English_1_538_2019_2021" //India
replace cj_q42c_norm=0 if id_alex=="cj_English_1_538_2019_2021" //India
replace all_q14_norm=. if id_alex=="cc_English_1_573_2017_2018_2019_2021" //India
replace all_q15_norm=. if id_alex=="cc_English_1_573_2017_2018_2019_2021" //India
replace all_q16_norm=. if id_alex=="cc_English_1_573_2017_2018_2019_2021" //India
replace all_q18_norm=. if id_alex=="cc_English_1_573_2017_2018_2019_2021" //India
replace all_q19_norm=. if id_alex=="cc_English_1_573_2017_2018_2019_2021" //India
replace all_q20_norm=. if id_alex=="cc_English_1_573_2017_2018_2019_2021" //India
replace all_q13_norm=. if id_alex=="cj_English_0_583_2019_2021" //India
replace all_q14_norm=. if id_alex=="cj_English_0_583_2019_2021" //India
replace all_q15_norm=. if id_alex=="cj_English_0_583_2019_2021" //India
replace all_q16_norm=. if id_alex=="cj_English_0_583_2019_2021" //India
replace all_q18_norm=. if id_alex=="cj_English_0_583_2019_2021" //India
replace all_q19_norm=. if id_alex=="cj_English_0_583_2019_2021" //India
replace all_q20_norm=. if id_alex=="cj_English_0_583_2019_2021" //India
replace all_q21_norm=. if id_alex=="cj_English_0_583_2019_2021" //India
replace all_q94_norm=. if id_alex=="cj_English_0_583_2019_2021" //India
replace cj_q40b_norm=. if id_alex=="cj_English_0_666" //Indonesia
replace cj_q40c_norm=. if id_alex=="cj_English_0_666" //Indonesia 
replace cj_q31f_norm=. if id_alex=="cj_English_0_666" //Indonesia
replace cj_q31g_norm=. if id_alex=="cj_English_0_666" //Indonesia
replace cj_q31f_norm=. if id_alex=="cj_English_0_647" //Indonesia
replace cj_q31g_norm=. if id_alex=="cj_English_0_647" //Indonesia
replace cj_q31f_norm=. if id_alex=="cj_English_0_873" //Indonesia
replace cj_q31g_norm=. if id_alex=="cj_English_0_873" //Indonesia
replace cj_q40b_norm=. if id_alex=="cj_English_0_947" //Indonesia
replace cj_q40c_norm=. if id_alex=="cj_English_0_947" //Indonesia
replace cj_q20m_norm=. if id_alex=="cj_English_0_947" //Indonesia
replace cj_q40b_norm=. if id_alex=="cj_English_0_873" //Indonesia
replace cj_q40c_norm=. if id_alex=="cj_English_0_873" //Indonesia
replace cj_q20m_norm=. if id_alex=="cj_English_0_873" //Indonesia
replace all_q29_norm=. if id_alex=="cc_English_0_1519" //Indonesia
replace all_q30_norm=. if id_alex=="cc_English_0_1519" //Indonesia
replace all_q29_norm=. if id_alex=="cc_English_0_1251" //Indonesia
replace all_q30_norm=. if id_alex=="cc_English_0_1251" //Indonesia
replace cj_q31f_norm=. if id_alex=="cj_English_1_831_2016_2017_2018_2019_2021" //Indonesia
replace cj_q31g_norm=. if id_alex=="cj_English_1_831_2016_2017_2018_2019_2021" //Indonesia
replace cj_q36c_norm=. if id_alex=="cj_English_0_947" //Indonesia
replace cj_q36c_norm=. if id_alex=="cj_English_0_144" //Indonesia
replace cj_q31e_norm=. if id_alex=="cj_English_0_666" //Indonesia
replace cj_q42c_norm=. if id_alex=="cj_English_0_666" //Indonesia
replace all_q84_norm=. if id_alex=="lb_English_0_80" //Iran, Islamic Rep.
replace all_q88_norm=. if id_alex=="lb_English_0_80" //Iran, Islamic Rep.
replace all_q84_norm=. if id_alex=="cc_English_0_1461_2019_2021" //Iran, Islamic Rep.
replace all_q85_norm=. if id_alex=="cc_English_0_1461_2019_2021" //Iran, Islamic Rep.
replace cc_q13_norm=. if id_alex=="cc_English_0_1461_2019_2021" //Iran, Islamic Rep.
replace cc_q26a_norm=. if id_alex=="cc_English_0_446" //Iran, Islamic Rep.
replace cc_q13_norm=. if id_alex=="cc_English_0_463_2013_2014_2016_2017_2018_2019_2021" //Iran, Islamic Rep.
replace all_q86_norm=. if id_alex=="lb_English_1_283_2017_2018_2019_2021" //Iran, Islamic Rep.
replace all_q87_norm=. if id_alex=="lb_English_1_283_2017_2018_2019_2021" //Iran, Islamic Rep.
replace all_q86_norm=. if id_alex=="lb_English_1_692_2019_2021" //Iran, Islamic Rep.
replace all_q87_norm=. if id_alex=="lb_English_1_692_2019_2021" //Iran, Islamic Rep.
replace cc_q26b_norm=. if id_alex=="cc_English_0_1506_2016_2017_2018_2019_2021" //Iran, Islamic Rep.
replace all_q13_norm=. if id_alex=="lb_English_1_692_2019_2021" //Iran, Islamic Rep.
replace all_q13_norm=. if id_alex=="lb_English_0_254_2017_2018_2019_2021" //Iran, Islamic Rep.
replace all_q13_norm=. if id_alex=="cj_English_1_416_2016_2017_2018_2019_2021" //Iran, Islamic Rep.
replace cj_q31f_norm=. if id_alex=="cj_English_1_416_2016_2017_2018_2019_2021" //Iran, Islamic Rep.
replace cj_q31f_norm=. if id_alex=="cj_English_1_550_2016_2017_2018_2019_2021" //Iran, Islamic Rep.
replace cj_q31f_norm=. if id_alex=="cj_English_1_472_2017_2018_2019_2021" //Iran, Islamic Rep.
drop if id_alex=="cj_English_0_412" //Ireland
drop if id_alex=="ph_English_0_181" //Ireland
replace cj_q15_norm=. if country=="Ireland" //Ireland
replace cc_q26a_norm=. if id_alex=="cc_English_0_389" //Ireland
replace all_q85_norm=. if id_alex=="cc_English_0_481" //Ireland
replace cc_q13_norm=. if id_alex=="cc_English_0_1201_2021" //Ireland
replace cc_q13_norm=. if id_alex=="cc_English_0_481" //Ireland
replace all_q89_norm=. if id_alex=="cc_English_0_603" //Ireland
replace cj_q7a_norm=. if country=="Ireland" //Ireland
replace all_q96_norm=. if id_alex=="cj_English_1_720" //Ireland
replace all_q96_norm=. if id_alex=="cj_English_0_412" //Ireland
replace all_q29_norm=. if id_alex=="cc_English_0_481" //Ireland
replace all_q30_norm=. if id_alex=="cc_English_0_481" //Ireland
replace all_q29_norm=. if id_alex=="cc_English_0_603" //Ireland
replace all_q30_norm=. if id_alex=="cc_English_0_603" //Ireland
replace cj_q31f_norm=. if id_alex=="cj_English_0_331" //Ireland
replace cj_q31g_norm=. if id_alex=="cj_English_0_331" //Ireland
replace cj_q42c_norm=. if id_alex=="cj_English_0_331" //Ireland
replace cj_q42d_norm=. if id_alex=="cj_English_0_331" //Ireland
replace all_q29_norm=. if id_alex=="cj_English_0_1144" //Ireland
replace all_q30_norm=. if id_alex=="cj_English_0_1144" //Ireland
replace cj_q31f_norm=. if id_alex=="cj_English_0_1144" //Ireland
replace cj_q31g_norm=. if id_alex=="cj_English_0_1144" //Ireland
replace cj_q42c_norm=. if id_alex=="cj_English_0_1144" //Ireland
replace cj_q42d_norm=. if id_alex=="cj_English_0_1144" //Ireland
replace all_q29_norm=. if id_alex=="cj_English_0_519" //Ireland
replace all_q30_norm=. if id_alex=="cj_English_0_519" //Ireland
replace cj_q31f_norm=. if id_alex=="cj_English_0_519" //Ireland
replace cj_q31g_norm=. if id_alex=="cj_English_0_519" //Ireland
replace cj_q42c_norm=. if id_alex=="cj_English_0_519" //Ireland
replace cj_q42d_norm=. if id_alex=="cj_English_0_519" //Ireland
replace cj_q40b_norm=. if id_alex=="cj_English_0_800_2021" //Ireland
replace cj_q40c_norm=. if id_alex=="cj_English_0_800_2021" //Ireland
replace cj_q20m_norm=. if id_alex=="cj_English_0_800_2021" //Ireland
replace cj_q40b_norm=. if id_alex=="cj_English_0_289" //Ireland
replace cj_q40c_norm=. if id_alex=="cj_English_0_289" //Ireland
replace cj_q20m_norm=. if id_alex=="cj_English_0_289" //Ireland
replace cj_q40b_norm=. if id_alex=="cj_English_1_720" //Ireland
replace cj_q40c_norm=. if id_alex=="cj_English_1_720" //Ireland
replace cj_q20m_norm=. if id_alex=="cj_English_1_720" //Ireland
replace cj_q40b_norm=.6666667 if id_alex=="cj_English_0_1144" //Ireland
replace lb_q15a_norm=.6666667 if id_alex=="lb_English_0_204_2021" //Ireland
replace lb_q15b_norm=.6666667 if id_alex=="lb_English_0_204_2021" //Ireland
replace lb_q15c_norm=.6666667 if id_alex=="lb_English_0_204_2021" //Ireland
replace lb_q15d_norm=.6666667 if id_alex=="lb_English_0_204_2021" //Ireland
replace lb_q15e_norm=.6666667 if id_alex=="lb_English_0_204_2021" //Ireland
drop if id_alex=="ph_English_0_368" //Ireland
drop if id_alex=="cc_English_0_481" //Ireland
replace all_q96_norm=. if id_alex=="cc_English_0_389" //Ireland
replace all_q96_norm=. if id_alex=="cc_English_0_386" //Ireland
replace all_q96_norm=. if id_alex=="cj_English_0_519" //Ireland
replace all_q76_norm=. if id_alex=="cc_English_0_386" //Ireland
replace all_q77_norm=. if id_alex=="cc_English_0_386" //Ireland
replace all_q78_norm=. if id_alex=="cc_English_0_386" //Ireland
replace all_q79_norm=. if id_alex=="cc_English_0_386" //Ireland
replace all_q80_norm=. if id_alex=="cc_English_0_386" //Ireland
replace all_q81_norm=. if id_alex=="cc_English_0_386" //Ireland
replace cj_q25a_norm=. if id_alex=="cj_English_0_427" //Ireland
replace cj_q40b_norm=. if id_alex=="cj_English_0_427" //Ireland
replace cj_q40c_norm=. if id_alex=="cj_English_0_427" //Ireland
replace all_q80_norm=. if country=="Italy" // Italy
drop if id_alex=="cc_English_0_298" // Italy
replace cc_q26b_norm=. if id_alex=="cc_English_1_1333_2021" //Italy
replace all_q86_norm=. if id_alex=="cc_English_1_1333_2021" //Italy
replace all_q62_norm=. if id_alex=="cc_English_1_579" //Italy
replace all_q63_norm=. if id_alex=="cc_English_1_579" //Italy
replace cj_q10_norm=. if id_alex=="cj_English_1_712_2017_2018_2019_2021" //Italy
replace cj_q10_norm=0 if id_alex=="cj_English_0_1118_2017_2018_2019_2021" //Italy
replace cj_q10_norm=0 if id_alex=="cj_English_1_817_2017_2018_2019_2021" //Italy
replace cj_q10_norm=0 if id_alex=="cj_English_0_324_2016_2017_2018_2019_2021" //Italy
replace cj_q10_norm=0 if id_alex=="cj_English_0_955_2021" //Italy
replace all_q94_norm=0 if id_alex=="cc_English_1_1547_2021" //Italy
replace all_q94_norm=0 if id_alex=="lb_English_0_694_2018_2019_2021" //Italy
replace all_q94_norm=. if id_alex=="cj_English_1_737_2016_2017_2018_2019_2021" //Italy
replace cj_q10_norm=0 if id_alex=="cj_Spanish_0_487_2021" //Italy
replace all_q14_norm=. if id_alex=="cc_English_1_869_2016_2017_2018_2019_2021" //Italy
replace all_q14_norm=. if id_alex=="cc_English_0_1656_2018_2019_2021" //Italy
drop if id_alex=="cc_English_0_1417" //Japan
drop if id_alex=="cj_English_0_501" //Japan
drop if id_alex=="cj_English_1_310" //Japan
drop if id_alex=="lb_English_1_558" //Japan
replace cj_q12a_norm=. if id_alex=="cj_English_0_359" //Japan
replace cj_q12b_norm=. if id_alex=="cj_English_0_359" //Japan
replace cj_q12c_norm=. if id_alex=="cj_English_0_359" //Japan
replace cj_q12d_norm=. if id_alex=="cj_English_0_359" //Japan
replace cj_q12e_norm=. if id_alex=="cj_English_0_359" //Japan
replace cj_q12f_norm=. if id_alex=="cj_English_0_359" //Japan
drop if id_alex=="cc_English_0_1330_2019_2021" //Jordan
drop if id_alex=="cj_English_0_651" //Jordan
drop if id_alex=="ph_English_0_482_2021" //Jordan
drop if id_alex=="cc_Arabic_0_316" //Jordan
drop if id_alex=="ph_English_1_420_2018_2019_2021" //Jordan
drop if id_alex=="cj_English_0_440" //Jordan
replace lb_q23f_norm=. if country=="Jordan" //Jordan
replace lb_q23g_norm=. if country=="Jordan" //Jordan
replace cc_q33_norm=. if country=="Jordan" //Jordan
replace lb_q2d_norm=. if country=="Jordan" //Jordan
replace lb_q3d_norm=. if country=="Jordan" //Jordan
replace cj_q12f_norm=. if id_alex=="cj_English_0_544_2017_2018_2019_2021" //Jordan
replace cj_q12f_norm=. if id_alex=="cj_Arabic_1_697_2021" //Jordan
replace cj_q7c_norm=. if country=="Jordan" //Jordan
replace cj_q40b_norm=. if id_alex=="cj_English_0_417" //Jordan
replace cj_q40c_norm=. if id_alex=="cj_English_0_417" //Jordan
replace cj_q20m_norm=. if id_alex=="cj_English_0_417" //Jordan
replace cj_q40b_norm=. if id_alex=="cj_English_0_820_2016_2017_2018_2019_2021" //Jordan
replace cj_q40c_norm=. if id_alex=="cj_English_0_820_2016_2017_2018_2019_2021" //Jordan
replace cj_q20m_norm=. if id_alex=="cj_English_0_820_2016_2017_2018_2019_2021" //Jordan
replace all_q96_norm=. if id_alex=="cj_English_1_1062" //Jordan
replace all_q96_norm=. if id_alex=="cj_Arabic_0_120" //Jordan
drop if id_alex=="cj_English_0_417" //Jordan
drop if id_alex=="lb_English_0_518" //Jordan
drop if id_alex=="ph_English_0_169" //Jordan

*---- FIXED BY NRC: Originally labelled as "Jordan". These four edits are for Iran. The Map doesn't have these changes. 
/*
replace all_q1_norm=. if id_alex=="cc_English_1_424_2018_2019_2021" //Jordan
replace all_q1_norm=. if id_alex=="cc_English_1_355_2019_2021" //Jordan
replace all_q1_norm=. if id_alex=="lb_English_0_400_2016_2017_2018_2019_2021" //Jordan
replace all_q1_norm=. if id_alex=="lb_English_1_283_2017_2018_2019_2021" //Jordan
*/

*---- 

replace all_q19_norm=. if id_alex=="cj_English_0_557_2014_2016_2017_2018_2019_2021" //Jordan
replace all_q19_norm=. if id_alex=="cj_English_0_466_2014_2016_2017_2018_2019_2021" //Jordan
replace all_q49_norm=. if id_alex=="cc_English_1_761" //Jordan
replace all_q50_norm=. if id_alex=="cc_English_1_761" //Jordan
replace all_q20_norm=. if id_alex=="lb_Arabic_0_18" //Jordan
replace all_q21_norm=. if id_alex=="lb_Arabic_0_18" //Jordan
replace all_q18_norm=. if id_alex=="cc_English_1_176" //Jordan
replace all_q20_norm=. if id_alex=="lb_English_1_581" //Jordan
drop if id_alex=="cc_Russian_1_480_2021" //Kazakhstan
drop if id_alex=="cc_Russian_0_154" //Kazakhstan
drop if id_alex=="cj_Russian_0_936" //Kazakhstan
drop if id_alex=="lb_Russian_0_606" //Kazakhstan
drop if id_alex=="ph_Russian_0_318_2021" //Kazakhstan
drop if id_alex=="cj_Russian_0_577" //Kazakhstan
drop if id_alex=="ph_Russian_1_119" //Kazakhstan
replace cj_q8_norm=. if country=="Kazakhstan" //Kazakhstan
replace cc_q9c_norm=. if id_alex=="cc_Russian_1_1360_2021" //Kazakhstan
replace cc_q40a_norm=. if id_alex=="cc_Russian_1_1360_2021" //Kazakhstan
replace cc_q40b_norm=. if id_alex=="cc_Russian_1_1360_2021" //Kazakhstan
replace cj_q20m_norm=. if id_alex=="cj_Russian_0_329" //Kazakhstan
replace cj_q20o_norm=. if id_alex=="cj_English_0_886" //Kenya
replace cj_q12c_norm=. if country=="Kenya" //Kenya
replace cj_q12d_norm=. if country=="Kenya" //Kenya
drop if id_alex=="cc_English_1_553" //Korea, Rep.
replace all_q88_norm=. if id_alex=="cc_English_0_1494" //Korea, Rep.
replace all_q88_norm=. if id_alex=="cc_English_0_738" //Korea, Rep.
replace cc_q33_norm=. if id_alex=="cc_English_0_853" //Korea, Rep.
replace cc_q33_norm=. if id_alex=="cc_English_0_1494" //Korea, Rep.
replace all_q88_norm=. if id_alex=="lb_English_0_516_2016_2017_2018_2019_2021" //Korea, Rep.
replace all_q84_norm=. if id_alex=="cc_English_0_738" //Korea, Rep.
replace all_q84_norm=. if id_alex=="cc_English_0_1627" //Korea, Rep.
replace cj_q21a_norm=. if id_alex=="cj_English_0_563" //Korea, Rep.
replace cj_q21g_norm=. if id_alex=="cj_English_0_1047_2017_2018_2019_2021" //Korea, Rep.
replace all_q88_norm=. if id_alex=="cc_English_0_96_2019_2021" //Korea, Rep.
replace cc_q26a_norm=. if id_alex=="cc_English_0_96_2019_2021" //Korea, Rep.
drop if id_alex=="cc_English_0_925" //Kosovo
drop if id_alex=="cj_English_0_629" //Kosovo
replace all_q10_norm=. if id_alex=="cc_English_0_1360" //Kosovo
replace all_q10_norm=. if id_alex=="lb_English_1_560" //Kosovo
replace all_q11_norm=. if id_alex=="lb_English_1_560" //Kosovo
replace all_q12_norm=. if id_alex=="cc_English_0_1360" //Kosovo
replace all_q12_norm=. if id_alex=="lb_English_1_560" //Kosovo
replace cj_q36a_norm=. if id_alex=="cj_English_1_554_2021" //Kosovo
replace cj_q36a_norm=. if id_alex=="cj_English_1_1151" //Kosovo
replace cj_q36b_norm=. if id_alex=="cj_English_1_554_2021" //Kosovo
replace cj_q36b_norm=. if id_alex=="cj_English_1_1151" //Kosovo
replace cc_q39c_norm=. if id_alex=="cc_English_0_472" //Kosovo
replace cc_q39c_norm=. if id_alex=="cc_English_0_440" //Kosovo
replace cc_q39c_norm=. if id_alex=="cc_English_0_1360" //Kosovo
replace cj_q10_norm=. if id_alex=="cj_English_1_476" //Kosovo
replace cj_q10_norm=. if id_alex=="cj_English_1_182" //Kosovo
replace cj_q10_norm=. if id_alex=="cj_English_0_810" //Kosovo
replace cj_q10_norm=. if id_alex=="cj_English_0_173" //Kosovo
replace cj_q31f_norm=. if id_alex=="cj_English_1_554_2021" //Kosovo
replace cj_q31f_norm=. if id_alex=="cj_English_0_173" //Kosovo
replace cj_q31f_norm=. if id_alex=="cj_English_0_963" //Kosovo
replace all_q48_norm=. if id_alex=="cc_English_0_321" //Kosovo
replace all_q49_norm=. if id_alex=="cc_English_0_321" //Kosovo
replace all_q49_norm=. if id_alex=="cc_English_0_643_2019_2021" //Kosovo
replace all_q50_norm=. if id_alex=="cc_English_0_321" //Kosovo
replace cj_q11a_norm=. if id_alex=="cj_English_1_182" //Kosovo
replace cj_q11b_norm=. if id_alex=="cj_English_1_182" //Kosovo
replace cj_q31e_norm=. if id_alex=="cj_English_1_182" //Kosovo
replace cj_q42c_norm=. if id_alex=="cj_English_1_182" //Kosovo
replace cj_q42d_norm=. if id_alex=="cj_English_1_182" //Kosovo
replace cj_q10_norm=. if id_alex=="cj_English_1_182" //Kosovo
replace cj_q12a_norm=. if id_alex=="cj_English_0_365" //Kosovo
replace cj_q12b_norm=. if id_alex=="cj_English_0_365" //Kosovo
replace cj_q12c_norm=. if id_alex=="cj_English_0_365" //Kosovo
replace cj_q12d_norm=. if id_alex=="cj_English_0_365" //Kosovo
replace cj_q12e_norm=. if id_alex=="cj_English_0_365" //Kosovo
replace cj_q12f_norm=. if id_alex=="cj_English_0_365" //Kosovo
replace cj_q11a_norm=. if id_alex=="cj_English_0_173" //Kosovo
replace cj_q31e_norm=. if id_alex=="cj_English_0_173" //Kosovo
replace cj_q42c_norm=. if id_alex=="cj_English_0_173" //Kosovo
replace cj_q42d_norm=. if id_alex=="cj_English_0_173" //Kosovo
replace cj_q11b_norm=. if id_alex=="cj_English_0_963" //Kosovo
replace cj_q11a_norm=. if id_alex=="cj_English_0_262_2019_2021" //Kosovo
replace cj_q40b_norm=. if id_alex=="cj_English_1_394" //Kosovo
replace cj_q40c_norm=. if id_alex=="cj_English_1_394" //Kosovo
replace cj_q20m_norm=. if id_alex=="cj_English_1_394" //Kosovo
replace cc_q40a_norm=. if country=="Kyrgyz Republic" //Kyrgyz Republic
replace all_q62_norm=. if id_alex=="cc_Russian_0_957" //Kyrgyz Republic
replace all_q62_norm=. if id_alex=="cc_Russian_0_747" //Kyrgyz Republic
replace all_q62_norm=. if id_alex=="cc_Russian_0_746" //Kyrgyz Republic
replace all_q63_norm=. if id_alex=="cc_Russian_0_957" //Kyrgyz Republic
replace all_q63_norm=. if id_alex=="cc_Russian_0_747" //Kyrgyz Republic
replace all_q63_norm=. if id_alex=="cc_Russian_0_746" //Kyrgyz Republic
drop if id_alex=="cj_Russian_0_37" //Kyrgyz Republic
drop if id_alex=="cc_Russian_0_957" //Kyrgyz Republic
replace cc_q9b_norm=. if id_alex=="cc_English_0_1413_2019_2021" //Kyrgyz Republic
replace cc_q39a_norm=. if id_alex=="cc_English_0_929_2017_2018_2019_2021" //Kyrgyz Republic
replace cc_q39b_norm=. if id_alex=="cc_English_0_929_2017_2018_2019_2021" //Kyrgyz Republic
replace cc_q39c_norm=. if id_alex=="cc_English_0_454_2017_2018_2019_2021" //Kyrgyz Republic
drop if id_alex=="cj_English_0_481" //Latvia
drop if id_alex=="cj_English_1_543" //Latvia
replace ph_q6c_norm=. if country=="Latvia" //Latvia
replace ph_q6e_norm=. if country=="Latvia" //Latvia
replace ph_q6f_norm=. if country=="Latvia" //Latvia
replace cj_q12f_norm=. if country=="Latvia" //Latvia
replace all_q49_norm=. if country=="Latvia" //Latvia
replace cj_q15_norm=. if id_alex=="cj_English_0_512" //Latvia
drop if id_alex=="cj_English_0_888" //Latvia
replace all_q89_norm=. if country=="Lebanon" //Lebanon
drop if id_alex=="cc_Arabic_0_1096" //Lebanon
replace all_q92_norm=. if id_alex=="cc_English_0_1053" //Lebanon
replace all_q92_norm=. if id_alex=="lb_English_1_129" //Lebanon
replace all_q75_norm=. if id_alex=="lb_English_0_359" //Lebanon
replace all_q74_norm=. if id_alex=="lb_English_0_359" //Lebanon
replace all_q77_norm=. if country=="Lebanon" //Lebanon
replace lb_q3d_norm=. if country=="Lebanon" //Lebanon
replace all_q59_norm=. if id_alex=="lb_English_1_696" //Lebanon
replace all_q90_norm=. if id_alex=="lb_English_1_696" //Lebanon
replace all_q91_norm=. if id_alex=="lb_English_1_696" //Lebanon
replace cc_q16b_norm=. if id_alex=="cc_English_0_1378" //Lebanon
replace cc_q16f_norm=. if id_alex=="cc_English_1_480" //Lebanon
replace cc_q16g_norm=. if id_alex=="cc_English_1_480" //Lebanon
replace all_q96_norm=. if id_alex=="lb_English_1_129" //Lebanon
drop if id_alex=="lb_English_0_618" //Lebanon
replace cc_q9c_norm=. if id_alex=="cc_English_0_1378" //Lebanon
replace cc_q40a_norm=. if id_alex=="cc_English_0_1378" //Lebanon
replace cc_q40b_norm=. if id_alex=="cc_English_0_1378" //Lebanon
replace cc_q40a_norm=0 if id_alex=="cc_French_0_1231" //Lebanon
replace cc_q40a_norm=0 if id_alex=="lb_English_0_310_2019_2021" //Lebanon
replace lb_q19a_norm=0 if id_alex=="lb_English_0_113" //Lebanon
replace cc_q40a_norm=0 if id_alex=="cc_English_1_308_2018_2019_2021" //Lebanon
replace cc_q9c_norm=. if id_alex=="cc_English_0_1053" //Lebanon
replace cc_q40a_norm=. if id_alex=="cc_English_0_1053" //Lebanon
replace cc_q40b_norm=. if id_alex=="cc_English_0_1053" //Lebanon
replace cc_q14b_norm=. if id_alex=="cc_English_0_612_2021" //Lebanon
replace cc_q16b_norm=. if id_alex=="cc_English_0_612_2021" //Lebanon
replace cc_q16c_norm=. if id_alex=="cc_English_0_612_2021" //Lebanon
replace cc_q16d_norm=. if id_alex=="cc_English_0_612_2021" //Lebanon
replace cc_q16e_norm=. if id_alex=="cc_English_0_612_2021" //Lebanon
replace cc_q16f_norm=. if id_alex=="cc_English_0_612_2021" //Lebanon
replace cc_q16g_norm=. if id_alex=="cc_English_0_612_2021" //Lebanon
replace cc_q16c_norm=. if id_alex=="cc_English_0_1378" //Lebanon
replace cc_q14b_norm=. if id_alex=="cc_English_1_480" //Lebanon
replace cc_q10_norm=. if id_alex=="cc_English_0_1378" //Lebanon
replace cc_q11a_norm=. if id_alex=="cc_English_0_1378" //Lebanon
replace cc_q16a_norm=. if id_alex=="cc_English_0_1378" //Lebanon
replace cj_q8_norm=. if id_alex=="cj_English_0_846" //Liberia
replace cj_q8_norm=. if id_alex=="cj_English_0_707" //Liberia
replace cj_q8_norm=. if id_alex=="cj_English_0_1127" //Liberia
replace cj_q38_norm=. if id_alex=="cj_English_0_846" //Liberia
replace cj_q38_norm=. if id_alex=="cj_English_0_707" //Liberia
replace cj_q38_norm=. if id_alex=="cj_English_0_1127" //Liberia
replace cj_q38_norm=. if id_alex=="cj_English_0_1072_2019_2021" //Liberia
replace all_q59_norm=. if id_alex=="cc_English_0_1297_2019_2021" //Liberia
replace all_q59_norm=. if id_alex=="cc_English_0_885" //Liberia
replace all_q59_norm=. if id_alex=="lb_English_0_423_2013_2014_2016_2017_2018_2019_2021" //Liberia
replace all_q51_norm=. if id_alex=="cc_English_0_885" //Liberia
replace cj_q27b_norm=. if country=="Liberia" //Liberia
replace cj_q12f_norm=. if id_alex=="cj_English_0_851_2021" //Liberia
replace cj_q12c_norm=. if country=="Liberia" //Liberia
replace all_q62_norm=. if id_alex=="cc_English_1_1392" //Liberia
replace all_q63_norm=. if id_alex=="cc_English_1_1392" //Liberia
replace all_q62_norm=. if id_alex=="cc_English_0_885" //Liberia
replace all_q63_norm=. if id_alex=="cc_English_0_885" //Liberia
replace all_q62_norm=. if id_alex=="cc_English_0_1297_2019_2021" //Liberia
replace all_q63_norm=. if id_alex=="cc_English_0_1297_2019_2021" //Liberia
replace all_q62_norm=. if id_alex=="cc_English_0_204_2016_2017_2018_2019_2021" //Liberia
replace all_q63_norm=. if id_alex=="cc_English_0_204_2016_2017_2018_2019_2021" //Liberia
replace all_q62_norm=. if id_alex=="cc_English_0_856_2017_2018_2019_2021" //Liberia
replace all_q63_norm=. if id_alex=="cc_English_0_856_2017_2018_2019_2021" //Liberia
drop if id_alex=="cj_English_0_771" //Lithuania
replace all_q72_norm=. if id_alex=="cc_English_0_1315" //Lithuania
replace all_q72_norm=. if id_alex=="cc_English_0_1227" //Lithuania
replace all_q92_norm=. if id_alex=="lb_English_0_383" //Lithuania
replace lb_q15d_norm=. if id_alex=="lb_English_0_383" //Lithuania
replace lb_q15e_norm=. if id_alex=="lb_English_0_383" //Lithuania
replace cc_q16a_norm=. if id_alex=="cc_English_0_1709" //Lithuania
replace cc_q16f_norm=. if country=="Lithuania" //Lithuania
replace cj_q42c_norm=. if id_alex=="cj_English_0_734" //Lithuania
replace cj_q42d_norm=. if id_alex=="cj_English_0_734" //Lithuania
replace cj_q42c_norm=. if id_alex=="cj_English_0_684" //Lithuania
replace cj_q42d_norm=. if id_alex=="cj_English_0_684" //Lithuania
replace cj_q31f_norm=. if id_alex=="cj_English_0_1141_2021" //Lithuania
replace cj_q31g_norm=. if id_alex=="cj_English_0_1141_2021" //Lithuania
replace cj_q11b_norm=. if id_alex=="cj_English_0_221_2021" //Lithuania
replace cj_q31e_norm=. if id_alex=="cj_English_0_221_2021" //Lithuania
replace cj_q42c_norm=. if id_alex=="cj_English_0_1094_2021" //Lithuania
replace cj_q42d_norm=. if id_alex=="cj_English_0_1094_2021" //Lithuania
replace cj_q11a_norm=. if id_alex=="cj_English_0_1165_2021" //Lithuania
replace cj_q11b_norm=. if id_alex=="cj_English_0_1165_2021" //Lithuania
replace cj_q31e_norm=. if id_alex=="cj_English_0_1165_2021" //Lithuania
replace cj_q42c_norm=. if id_alex=="cj_English_0_1165_2021" //Lithuania
replace cj_q42d_norm=. if id_alex=="cj_English_0_1165_2021" //Lithuania
replace cj_q10_norm=. if id_alex=="cj_English_0_1165_2021" //Lithuania
replace cj_q11a_norm=. if id_alex=="cj_Russian_0_490" //Lithuania
replace cj_q11b_norm=. if id_alex=="cj_Russian_0_490" //Lithuania
replace cj_q31e_norm=. if id_alex=="cj_Russian_0_490" //Lithuania
replace cj_q42c_norm=. if id_alex=="cj_Russian_0_490" //Lithuania
replace cj_q42d_norm=. if id_alex=="cj_Russian_0_490" //Lithuania
replace cj_q10_norm=. if id_alex=="cj_Russian_0_490" //Lithuania
replace cj_q7a_norm=. if country=="Luxembourg" //Luxembourg
drop if id_alex=="cj_English_0_831" //Luxembourg
drop if id_alex=="ph_French_1_282" //Luxembourg
replace all_q62_norm=. if id_alex=="lb_English_0_224" //Luxembourg
replace all_q63_norm=. if id_alex=="lb_English_0_224" //Luxembourg
replace cj_q15_norm=0.6666667 if id_alex=="cj_French_0_573_2021" //Luxembourg
replace lb_q19a_norm=. if id_alex=="lb_French_0_117" //Madagascar
replace cc_q16a_norm=. if id_alex=="cc_French_0_239" //Madagascar
replace cc_q16a_norm=. if id_alex=="cc_English_0_1287" //Madagascar
replace all_q80_norm=. if id_alex=="lb_French_0_534_2017_2018_2019_2021" //Madagascar
replace all_q80_norm=. if id_alex=="lb_French_0_643_2019_2021" //Madagascar
replace all_q55_norm=. if id_alex=="lb_French_0_534_2017_2018_2019_2021" //Madagascar
replace all_q55_norm=. if id_alex=="lb_French_0_117" //Madagascar
replace cc_q10_norm=. if id_alex=="cc_French_0_239" //Madagascar
drop if id_alex=="cc_French_0_1675" //Madagascar
replace all_q88_norm=. if id_alex=="cc_English_0_318_2021" //Madagascar
replace all_q88_norm=. if id_alex=="cc_French_1_688" //Madagascar
replace all_q88_norm=. if id_alex=="cc_French_0_933" //Madagascar
replace all_q88_norm=. if id_alex=="cc_French_0_239" //Madagascar
replace all_q88_norm=. if id_alex=="cc_English_1_1455" //Madagascar
replace all_q88_norm=. if id_alex=="cc_French_0_239" //Madagascar
replace cc_q26a_norm=. if id_alex=="cc_English_1_1455" //Madagascar
replace cc_q26a_norm=. if id_alex=="cc_French_0_239" //Madagascar
replace all_q76_norm=. if country=="Malawi" //Malawi
replace all_q77_norm=. if country=="Malawi" //Malawi
replace all_q59_norm=. if country=="Malawi" //Malawi
replace cc_q25_norm=. if country=="Malawi" //Malawi
replace cj_q38_norm=. if country=="Malawi" //Malawi
drop if id_alex=="cj_English_0_1112" //Malaysia
drop if id_alex=="cj_English_1_1024" //Malaysia
drop if id_alex=="ph_English_1_523_2019_2021" //Malaysia
replace cj_q15_norm=. if id_alex=="cj_English_0_71_2013_2014_2016_2017_2018_2019_2021" //Malaysia
replace cj_q28_norm=. if country=="Malaysia" //Malaysia
replace all_q50_norm=. if id_alex=="cc_English_0_112" //Malaysia
replace all_q48_norm=. if id_alex=="cc_English_0_112" //Malaysia
replace all_q49_norm=. if id_alex=="cc_English_0_235_2018_2019_2021" //Malaysia
replace all_q49_norm=. if id_alex=="cc_English_0_1757" //Malaysia
replace all_q81_norm=. if id_alex=="cc_English_0_1450_2016_2017_2018_2019_2021" //Malaysia
replace all_q81_norm=. if id_alex=="cc_English_0_112" //Malaysia
replace all_q81_norm=. if id_alex=="lb_English_0_62" //Malaysia
replace all_q77_norm=. if id_alex=="cc_English_1_709_2016_2017_2018_2019_2021" //Malaysia
replace all_q78_norm=. if id_alex=="cc_English_1_709_2016_2017_2018_2019_2021" //Malaysia
replace cc_q9c_norm=. if id_alex=="cc_English_0_860" //Malaysia
replace cc_q40a_norm=. if id_alex=="cc_English_0_860" //Malaysia
replace cc_q40b_norm=. if id_alex=="cc_English_0_860" //Malaysia
replace cc_q9c_norm=. if id_alex=="cc_English_0_1529_2018_2019_2021" //Malaysia
replace cc_q40a_norm=. if id_alex=="cc_English_0_112" //Malaysia
replace cc_q33_norm=. if country=="Mali" //Mali
replace all_q24_norm=. if country=="Mali" //Mali 
replace all_q2_norm=. if country=="Mali" //Mali
replace cj_q15_norm=. if id_alex=="cj_French_1_1104_2021" //Mali
replace cj_q15_norm=. if id_alex=="cj_French_0_829" //Mali
replace cj_q42c_norm=. if id_alex=="cj_French_0_371_2021" //Mali
replace cj_q42d_norm=. if id_alex=="cj_French_0_829" //Mali
drop if id_alex=="cc_French_1_1149" //Mali
drop if id_alex=="cc_English_0_421_2018_2019_2021" //Mali
replace cj_q38_norm=. if id_alex=="cj_French_0_1348_2018_2019_2021" //Mali
replace cj_q38_norm=. if id_alex=="cj_French_0_458_2018_2019_2021" //Mali
replace cc_q9b_norm=. if id_alex=="cc_French_0_207" //Mali
replace cc_q9b_norm=. if id_alex=="cc_French_1_1309_2021" //Mali
replace cc_q39a_norm=. if id_alex=="cc_French_1_1309_2021" //Mali
replace cc_q39b_norm=. if id_alex=="cc_French_1_1309_2021" //Mali
replace cc_q39a_norm=. if id_alex=="cc_French_0_56_2018_2019_2021" //Mali
replace cc_q39b_norm=. if id_alex=="cc_French_0_56_2018_2019_2021" //Mali
replace cc_q39c_norm=. if id_alex=="cc_French_0_56_2018_2019_2021" //Mali
replace cc_q39d_norm=. if id_alex=="cc_French_0_56_2018_2019_2021" //Mali
replace cc_q39e_norm=. if id_alex=="cc_French_0_56_2018_2019_2021" //Mali
replace lb_q2d_norm=. if id_alex=="lb_French_0_311" //Mali
replace lb_q3d_norm=. if id_alex=="lb_French_0_311" //Mali

replace cc_q16a_norm=. if country=="Malta" //Malta
replace all_q88_norm=. if country=="Malta" //Malta
drop if id_alex=="cc_English_0_861" //Malta
replace cj_q10_norm=. if id_alex=="cj_English_1_716" //Malta
replace lb_q19a_norm=. if country=="Malta" //Malta
replace all_q3_norm=. if id_alex=="cc_English_0_263" //Malta
replace all_q6_norm=. if id_alex=="cc_English_0_905" //Malta
replace all_q59_norm=. if country=="Malta" //Malta
drop if id_alex=="cj_English_0_786" //Malta
replace cj_q42c_norm=. if id_alex=="cj_English_1_716" //Malta
replace cj_q42d_norm=. if id_alex=="cj_English_1_716" //Malta
replace cc_q9c_norm=. if id_alex=="cc_English_0_1335_2021" //Malta
replace all_q48_norm=. if id_alex=="lb_English_0_315" //Malta
replace all_q49_norm=. if id_alex=="lb_English_0_315" //Malta
replace all_q50_norm=. if id_alex=="lb_English_0_315" //Malta
replace all_q62_norm=. if id_alex=="lb_English_1_108" //Malta
replace all_q63_norm=. if id_alex=="lb_English_1_108" //Malta
replace cj_q42d_norm=. if id_alex=="cj_English_0_550_2021" //Malta
replace all_q29_norm=. if id_alex=="cj_English_0_550_2021" //Malta
replace all_q30_norm=. if id_alex=="cj_English_0_550_2021" //Malta
replace all_q6_norm=. if id_alex=="cc_English_0_40" //Malta
replace cc_q11a_norm=. if id_alex=="cc_English_0_40" //Malta
replace all_q3_norm=. if id_alex=="cc_English_0_40" //Malta
replace all_q4_norm=. if id_alex=="cc_English_0_40" //Malta
replace all_q7_norm=. if id_alex=="cc_English_0_40" //Malta
replace cj_q12a_norm=. if id_alex=="cj_English_1_716" //Malta
replace cj_q12b_norm=. if id_alex=="cj_English_1_716" //Malta
replace cj_q12c_norm=. if id_alex=="cj_English_1_716" //Malta
replace cj_q12d_norm=. if id_alex=="cj_English_1_716" //Malta
replace cj_q12e_norm=. if id_alex=="cj_English_1_716" //Malta
replace cj_q12f_norm=. if id_alex=="cj_English_1_716" //Malta
replace cj_q20o_norm=. if id_alex=="cj_English_1_716" //Malta
replace cj_q40b_norm=. if id_alex=="cj_English_1_716" //Malta
replace cj_q40c_norm=. if id_alex=="cj_English_1_716" //Malta
replace all_q48_norm=. if id_alex=="lb_English_0_38" //Malta
replace all_q49_norm=. if id_alex=="lb_English_0_38" //Malta
replace all_q50_norm=. if id_alex=="lb_English_0_38" //Malta
replace lb_q2d_norm=0.5 if id_alex=="lb_English_0_326" //Malta
replace lb_q3d_norm=0.5 if id_alex=="lb_English_0_326" //Malta
replace cj_q18a_norm=. if id_alex=="cj_English_1_716" //Malta
replace cj_q25c_norm=. if id_alex=="cj_English_0_550_2021" //Malta
replace cj_q15_norm=. if id_alex=="cj_English_1_716" //Malta
replace cj_q20m_norm=. if id_alex=="cj_English_1_716" //Malta
replace cc_q10_norm=. if id_alex=="cc_English_0_40" //Malta
replace cc_q10_norm=. if id_alex=="cc_English_0_1335_2021" //Malta
replace cc_q16f_norm=. if id_alex=="cc_English_0_40" //Malta
replace all_q76_norm=. if id_alex=="cc_English_0_40" //Malta
replace all_q77_norm=. if id_alex=="cc_English_0_40" //Malta
replace all_q78_norm=. if id_alex=="cc_English_0_40" //Malta
replace all_q79_norm=. if id_alex=="cc_English_0_40" //Malta
replace all_q80_norm=. if id_alex=="cc_English_0_40" //Malta
replace all_q81_norm=. if id_alex=="cc_English_0_40" //Malta
replace all_q82_norm=. if id_alex=="cc_English_0_40" //Malta
replace all_q4_norm=. if id_alex=="cc_English_0_905" //Malta
replace all_q7_norm=. if id_alex=="cc_English_0_905" //Malta
replace all_q9_norm=. if id_alex=="cj_English_0_550_2021" //Malta
replace all_q9_norm=. if id_alex=="lb_English_1_108" //Malta
replace cc_q26b_norm=. if id_alex=="cc_English_0_263" //Malta
replace all_q86_norm=. if id_alex=="cc_English_0_905" //Malta
replace all_q90_norm=. if id_alex=="cc_English_0_263" //Malta
replace all_q6_norm=. if id_alex=="lb_English_0_38" //Malta
replace all_q90_norm=. if country=="Mauritania" //Mauritania
drop if id_alex=="cc_English_0_1774" //Mauritania
replace all_q88_norm=. if id_alex=="cc_French_0_1089" //Mauritania
replace cc_q13_norm=. if id_alex=="cc_French_0_1555" //Mauritania
replace all_q89_norm=. if id_alex=="cc_English_0_302_2019_2021" //Mauritania
replace all_q3_norm=. if id_alex=="cc_French_0_1681_2018_2019_2021" //Mauritania
replace all_q4_norm=. if id_alex=="cc_French_0_1681_2018_2019_2021" //Mauritania
replace all_q7_norm=. if id_alex=="cc_French_0_1681_2018_2019_2021" //Mauritania
replace all_q3_norm=. if id_alex=="cc_French_0_1089" //Mauritania
replace all_q4_norm=. if id_alex=="cc_French_0_1089" //Mauritania
replace all_q7_norm=. if id_alex=="cc_French_0_1089" //Mauritania
replace cc_q25_norm=. if id_alex=="cc_French_0_111_2018_2019_2021" //Mauritania
replace cc_q25_norm=. if id_alex=="cc_French_0_1681_2018_2019_2021" //Mauritania
drop if id_alex=="cj_English_1_135" //Mauritius
drop if id_alex=="lb_English_0_318" //Mauritius
drop if id_alex=="cj_English_0_671" //Mauritius
replace cj_q11a_norm=. if id_alex=="cj_English_1_1121" //Mauritius
replace cj_q11b_norm=. if id_alex=="cj_English_1_1121" //Mauritius
replace cj_q31e_norm=. if id_alex=="cj_English_1_1121" //Mauritius
replace cj_q42c_norm=. if id_alex=="cj_English_1_1121" //Mauritius
replace cj_q42d_norm=. if id_alex=="cj_English_1_1121" //Mauritius
replace cj_q10_norm=. if id_alex=="cj_English_1_1121" //Mauritius
replace cj_q15_norm=. if id_alex=="cj_English_1_1121" //Mauritius
replace cj_q40b_norm=. if id_alex=="cj_English_0_880_2021" //Mauritius
replace cj_q40c_norm=. if id_alex=="cj_English_0_880_2021" //Mauritius
replace cj_q20m_norm=. if id_alex=="cj_English_0_880_2021" //Mauritius
replace cj_q29a_norm=. if country=="Mexico" //Mexico
replace cj_q29b_norm=. if country=="Mexico" //Mexico
replace all_q78_norm=. if country=="Mexico" //Mexico
replace all_q86_norm=. if country=="Mexico" //Mexico
replace all_q85_norm=. if country=="Mexico" //Mexico
replace all_q96_norm=. if id_alex=="cj_Spanish_1_48" //Mexico
replace all_q96_norm=. if id_alex=="cj_Spanish_0_570" //Mexico
replace all_q96_norm=. if id_alex=="cj_English_0_271" //Mexico
replace all_q29_norm=. if id_alex=="cc_Spanish_1_1123" //Mexico
replace all_q29_norm=. if id_alex=="cc_English_1_1596_2019_2021" //Mexico
drop if id_alex=="cj_Spanish_0_350" //Mexico
replace cj_q12a_norm=. if id_alex=="cj_Spanish_1_732" //Mexico
replace cj_q12b_norm=. if id_alex=="cj_Spanish_1_732" //Mexico
replace cj_q12c_norm=. if id_alex=="cj_Spanish_1_732" //Mexico
replace cj_q12d_norm=. if id_alex=="cj_Spanish_1_732" //Mexico
replace cj_q12e_norm=. if id_alex=="cj_Spanish_1_732" //Mexico
replace cj_q12f_norm=. if id_alex=="cj_Spanish_1_732" //Mexico
replace cj_q20o_norm=. if id_alex=="cj_Spanish_0_224" //Mexico
replace cj_q12a_norm=. if id_alex=="cj_Spanish_1_259" //Mexico
replace cj_q12b_norm=. if id_alex=="cj_Spanish_1_259" //Mexico
replace cj_q12c_norm=. if id_alex=="cj_Spanish_1_259" //Mexico
replace cj_q12d_norm=. if id_alex=="cj_Spanish_1_259" //Mexico
replace cj_q12e_norm=. if id_alex=="cj_Spanish_1_259" //Mexico
replace cj_q12f_norm=. if id_alex=="cj_Spanish_1_259" //Mexico
replace cj_q20o_norm=. if id_alex=="cj_Spanish_1_259" //Mexico
replace cc_q40a_norm=. if id_alex=="cc_English_1_1071_2018_2019_2021" //Mexico
replace cc_q40b_norm=. if id_alex=="cc_English_1_1071_2018_2019_2021" //Mexico
drop if id_alex=="ph_Russian_1_317" //Moldova
drop if id_alex=="cj_English_0_386" //Moldova
replace cj_q20m_norm=. if id_alex=="cj_English_1_831" //Moldova
drop if id_alex=="cc_English_0_1561" //Mongolia
replace all_q62_norm=. if id_alex=="cc_English_0_1214" //Mongolia
replace all_q63_norm=. if id_alex=="cc_English_0_1214" //Mongolia
replace cc_q26b_norm=. if id_alex=="cc_English_0_1217" //Mongolia
replace all_q86_norm=. if id_alex=="cc_English_0_1217" //Mongolia
replace all_q87_norm=. if id_alex=="cc_English_0_1217" //Mongolia
replace cj_q42c_norm=. if id_alex=="cj_English_1_701" //Mongolia
replace cj_q42d_norm=. if id_alex=="cj_English_1_701" //Mongolia
replace cj_q10_norm=. if id_alex=="cj_English_1_701" //Mongolia
drop if id_alex=="cc_English_0_1148_2021" //Mongolia
drop if id_alex=="cj_English_0_1263_2018_2019_2021" //Mongolia
drop if id_alex=="cc_English_0_700" //Mongolia
replace cj_q10_norm=. if id_alex=="cj_English_0_1162_2018_2019_2021" //Mongolia
replace cj_q42c_norm=. if id_alex=="cj_English_0_1119_2017_2018_2019_2021" //Mongolia
replace cj_q11a_norm=. if id_alex=="cj_English_1_701" //Mongolia
replace all_q62_norm=. if id_alex=="lb_English_0_386_2013_2014_2016_2017_2018_2019_2021" //Mongolia
replace all_q62_norm=. if id_alex=="lb_English_1_648_2021" //Mongolia
replace all_q63_norm=. if id_alex=="lb_English_1_648_2021" //Mongolia
replace cc_q26b_norm=. if id_alex=="cc_English_1_1190_2019_2021" //Mongolia
replace cc_q26b_norm=. if id_alex=="cc_English_0_525_2017_2018_2019_2021" //Mongolia
replace all_q86_norm=. if id_alex=="cc_English_0_525_2017_2018_2019_2021" //Mongolia
replace cj_q20o_norm=. if id_alex=="cj_English_1_626_2019_2021" //Mongolia
drop if id_alex=="cc_French_1_154" //Morocco
drop if id_alex=="cj_French_1_777" //Morocco
drop if id_alex=="lb_French_1_502" //Morocco
replace cj_q27b_norm=. if country=="Morocco" //Morocco
replace all_q1_norm=. if country=="Morocco" //Morocco
replace all_q48_norm=. if id_alex=="cc_English_0_974" //Morocco
replace all_q49_norm=. if id_alex=="cc_English_0_974" //Morocco
replace all_q49_norm=. if id_alex=="cc_French_0_1683" //Morocco
replace all_q86_norm=. if id_alex=="cc_English_0_974" //Morocco
replace cj_q21a_norm=. if id_alex=="cj_French_0_774" //Morocco
replace cj_q8_norm=. if id_alex=="cj_French_0_1091" //Morocco
replace cj_q36c_norm=. if id_alex=="cj_English_1_998_2017_2018_2019_2021" //Morocco
replace cj_q36c_norm=. if id_alex=="cj_Arabic_1_763" //Morocco
replace all_q11_norm=. if id_alex=="cj_Arabic_1_574_2021" //Morocco
replace all_q11_norm=. if id_alex=="lb_French_1_371" //Morocco
drop if id_alex=="cj_French_0_1091" //Morocco
replace cj_q42c_norm=. if id_alex=="cj_French_0_774" //Morocco
replace cj_q42d_norm=. if id_alex=="cj_French_0_774" //Morocco
replace cj_q10_norm=. if id_alex=="cj_French_0_774" //Morocco
replace cj_q10_norm=. if id_alex=="cj_French_0_530" //Morocco
replace all_q29_norm=. if id_alex=="cc_English_0_974" //Morocco
replace all_q30_norm=. if id_alex=="cc_English_0_974" //Morocco
replace cj_q42c_norm=. if id_alex=="cj_Arabic_0_172" //Morocco
replace cj_q42d_norm=. if id_alex=="cj_Arabic_0_172" //Morocco
replace cj_q10_norm=. if id_alex=="cj_Arabic_0_172" //Morocco
replace all_q96_norm=. if id_alex=="cc_French_0_589_2016_2017_2018_2019_2021" //Morocco
replace all_q96_norm=. if id_alex=="cc_French_1_319_2017_2018_2019_2021" //Morocco
replace all_q61_norm=. if id_alex=="cc_Arabic_0_269" //Morocco
replace cj_q32c_norm=. if id_alex=="cj_French_0_530" //Morocco
replace cj_q32d_norm=. if id_alex=="cj_French_0_530" //Morocco
replace cj_q34d_norm=. if id_alex=="cj_French_0_530" //Morocco
replace cj_q32b_norm=. if id_alex=="cj_French_0_530" //Morocco
replace cj_q32b_norm=. if id_alex=="cc_French_0_589_2016_2017_2018_2019_2021" //Morocco
replace cj_q32b_norm=. if id_alex=="cc_French_0_651_2016_2017_2018_2019_2021" //Morocco
replace all_q95_norm=. if id_alex=="cj_French_0_530" //Morocco
replace all_q95_norm=. if id_alex=="cj_English_1_998_2017_2018_2019_2021" //Morocco
replace cj_q34a_norm=. if id_alex=="cj_Arabic_0_172" //Morocco
replace cj_q34b_norm=. if id_alex=="cj_Arabic_0_172" //Morocco
replace cj_q34c_norm=. if id_alex=="cj_Arabic_0_172" //Morocco
replace cj_q34d_norm=. if id_alex=="cj_Arabic_0_172" //Morocco
replace cj_q34e_norm=. if id_alex=="cj_Arabic_0_172" //Morocco
replace cj_q22e_norm=. if country=="Mozambique" //Mozambique
replace cj_q3b_norm=. if country=="Mozambique" //Mozambique
replace cj_q3c_norm=. if country=="Mozambique" //Mozambique
replace cj_q19e_norm=. if country=="Mozambique" //Mozambique
replace cj_q22a_norm=. if country=="Mozambique" //Mozambique
replace cj_q6d_norm=. if country=="Mozambique" //Mozambique
replace cj_q21h_norm=. if country=="Mozambique" //Mozambique
replace all_q1_norm=. if country=="Mozambique" //Mozambique
replace cj_q20m_norm=. if country=="Mozambique" //Mozambique
replace all_q86_norm=. if id_alex=="cc_English_1_416_2019_2021" //Mozambique
replace all_q50_norm=. if id_alex=="lb_English_1_147_2019_2021" //Mozambique
replace lb_q19a_norm=. if id_alex=="lb_English_1_147_2019_2021" //Mozambique
replace all_q50_norm=. if id_alex=="lb_Portuguese_1_276" //Mozambique
replace lb_q19a_norm=. if id_alex=="lb_Portuguese_1_276" //Mozambique
replace all_q85_norm=. if id_alex=="cc_Portuguese_1_308" //Mozambique
replace cc_q13_norm=. if id_alex=="cc_Portuguese_1_308" //Mozambique
replace cj_q11a_norm=. if country=="Myanmar" //Myanmar
replace cj_q11b_norm=. if country=="Myanmar" //Myanmar
replace cj_q6b_norm=. if country=="Myanmar" //Myanmar
replace cj_q6c_norm=. if country=="Myanmar" //Myanmar
replace cj_q6d_norm=. if country=="Myanmar" //Myanmar
replace lb_q6c_norm=. if id_alex=="lb_English_0_31" //Myanmar
replace all_q59_norm=. if country=="Myanmar" //Myanmar
replace cj_q33a_norm=. if id_alex=="cj_English_0_682" //Myanmar
replace cj_q33b_norm=. if country=="Myanmar" //Myanmar
replace lb_q16d_norm=. if id_alex=="lb_English_1_218" //Myanmar
replace lb_q23d_norm=. if id_alex=="lb_English_0_31" //Myanmar
replace lb_q23a_norm=. if id_alex=="lb_English_0_31" //Myanmar
drop if id_alex=="cj_English_0_431" //Myanmar
replace cj_q38_norm=. if id_alex=="cj_English_0_301_2018_2019_2021" //Myanmar
replace cj_q36c_norm=. if id_alex=="cj_English_0_301_2018_2019_2021" //Myanmar
replace cj_q38_norm=. if id_alex=="cj_English_0_207_2019_2021" //Myanmar
replace cj_q36c_norm=. if id_alex=="cj_English_0_207_2019_2021" //Myanmar
drop if id_alex=="cc_English_0_986" // Namibia
drop if id_alex=="cc_English_0_974_2019_2021" // Namibia
drop if id_alex=="cc_English_0_848_2021" // Namibia
drop if id_alex=="cj_English_0_672" // Namibia
drop if id_alex=="cj_English_0_806_2019_2021" // Namibia
replace lb_q16a_norm=. if id_alex=="lb_English_0_212" // Namibia
replace all_q78_norm=. if id_alex=="lb_English_0_648" // Namibia
replace all_q78_norm=. if id_alex=="lb_English_1_832" // Namibia
replace all_q79_norm=. if id_alex=="lb_English_0_648" // Namibia
replace all_q80_norm=. if id_alex=="cc_English_0_319" // Namibia
replace all_q81_norm=. if id_alex=="lb_English_0_648" // Namibia
replace all_q82_norm=. if id_alex=="cc_English_0_144_2019_2021" // Namibia
replace all_q82_norm=. if id_alex=="cc_English_0_319" // Namibia
replace all_q76_norm=. if country=="Namibia" // Namibia
replace all_q62_norm=. if id_alex=="cc_English_0_811" // Namibia
replace all_q62_norm=. if id_alex=="cc_English_0_319" // Namibia
replace all_q63_norm=. if id_alex=="cc_English_0_811" // Namibia
replace all_q63_norm=. if id_alex=="lb_English_0_648" // Namibia
replace all_q89_norm=. if id_alex=="cc_English_0_1040" // Namibia
replace all_q89_norm=. if id_alex=="cc_English_0_811" // Namibia
replace cj_q21a_norm=. if id_alex=="cj_English_0_574_2021" // Namibia
replace cj_q21e_norm=. if id_alex=="cj_English_0_574_2021" // Namibia
replace all_q71_norm=. if id_alex=="cc_English_0_811" // Namibia
replace all_q72_norm=. if id_alex=="cc_English_0_811" // Namibia
replace all_q71_norm=. if id_alex=="cc_English_0_144_2018_2019_2021" // Namibia
replace cj_q28_norm=. if id_alex=="cj_English_0_1024" // Namibia
drop if id_alex=="cj_English_1_888_2019_2021" //Nepal
drop if id_alex=="cj_English_1_526_2021" //Nepal
drop if id_alex=="cj_English_0_1080" //Nepal
replace cj_q42d_norm=. if id_alex=="cj_English_0_858" //Nepal 
replace cj_q28_norm=. if id_alex=="cj_English_0_1141" //Nepal
replace cj_q21g_norm=. if id_alex=="cj_English_0_858" //Nepal
replace cj_q20o_norm=. if id_alex=="cj_English_1_486" //Nepal
replace cj_q20o_norm=. if id_alex=="cj_English_0_858" //Nepal
replace cj_q36c_norm=. if id_alex=="cj_English_0_243" //Nepal
replace cj_q38_norm=. if id_alex=="cj_English_0_858" //Nepal
replace cc_q33_norm=. if id_alex=="cc_English_0_1350" //Nepal
replace all_q9_norm=. if id_alex=="cc_English_0_1350" //Nepal
replace cj_q8_norm=. if id_alex=="cj_English_0_858" //Nepal
replace cj_q15_norm=. if id_alex=="cj_English_0_243" //Nepal
replace cj_q27a_norm=. if id_alex=="cj_English_0_360_2019_2021" //Nepal
replace cj_q27b_norm=. if id_alex=="cj_English_0_360_2019_2021" //Nepal
replace all_q10_norm=. if id_alex=="cc_English_0_1350" //Nepal
replace all_q12_norm=. if id_alex=="cc_English_0_1350" //Nepal
replace all_q52_norm=. if id_alex=="cc_English_0_384" //Nepal
replace all_q53_norm=. if id_alex=="cc_English_0_384" //Nepal
replace all_q76_norm=. if id_alex=="cc_English_0_1144_2021" //Nepal
replace all_q77_norm=. if id_alex=="cc_English_0_1144_2021" //Nepal
replace all_q78_norm=. if id_alex=="cc_English_0_1144_2021" //Nepal
replace all_q79_norm=. if id_alex=="cc_English_0_1144_2021" //Nepal
replace all_q80_norm=. if id_alex=="cc_English_0_1144_2021" //Nepal
replace all_q81_norm=. if id_alex=="cc_English_0_1144_2021" //Nepal
replace all_q82_norm=. if id_alex=="cc_English_0_1144_2021" //Nepal
replace all_q76_norm=. if id_alex=="cc_English_0_1350" //Nepal
replace all_q77_norm=. if id_alex=="cc_English_0_1350" //Nepal
replace all_q78_norm=. if id_alex=="cc_English_0_1350" //Nepal
replace all_q79_norm=. if id_alex=="cc_English_0_1350" //Nepal
replace all_q80_norm=. if id_alex=="cc_English_0_1350" //Nepal
replace all_q81_norm=. if id_alex=="cc_English_0_1350" //Nepal
replace all_q82_norm=. if id_alex=="cc_English_0_1350" //Nepal
replace cj_q10_norm=. if id_alex=="cj_English_0_530_2016_2017_2018_2019_2021" //Netherlands
replace cj_q10_norm=. if id_alex=="cj_English_0_773_2016_2017_2018_2019_2021" //Netherlands
replace cj_q10_norm=. if id_alex=="cj_English_1_786_2016_2017_2018_2019_2021" //Netherlands
replace cj_q10_norm=. if id_alex=="cj_English_0_1013_2018_2019_2021" //Netherlands
replace all_q15_norm=. if id_alex=="cc_English_0_1502_2016_2017_2018_2019_2021" //Netherlands
replace all_q16_norm=. if id_alex=="cc_English_0_1502_2016_2017_2018_2019_2021" //Netherlands
replace all_q15_norm=. if id_alex=="cc_English_1_725_2018_2019_2021" //Netherlands
replace all_q16_norm=. if id_alex=="cc_English_1_725_2018_2019_2021" //Netherlands
replace all_q20_norm=. if id_alex=="cc_English_0_1502_2016_2017_2018_2019_2021" //Netherlands
replace all_q94_norm=. if id_alex=="cc_English_0_1502_2016_2017_2018_2019_2021" //Netherlands
replace all_q94_norm=. if id_alex=="cc_English_1_947_2017_2018_2019_2021" //Netherlands
replace all_q14_norm=. if id_alex=="cc_English_0_1502_2016_2017_2018_2019_2021" //Netherlands
replace all_q14_norm=. if id_alex=="cc_English_1_725_2018_2019_2021" //Netherlands
drop if id_alex=="cc_English_1_1173" // New Zealand
drop if id_alex=="cc_es-mx_0_346_2017_2018_2019_2021" //Nicaragua
drop if id_alex=="lb_Spanish_0_46_2013_2014_2016_2017_2018_2019_2021" //Nicaragua
drop if id_alex=="cj_English_0_377_2014_2016_2017_2018_2019_2021" //Nicaragua
drop if id_alex=="cj_English_0_377_2014_2016_2017_2018_2019_2021" //Nicaragua
drop if id_alex=="lb_Spanish_1_465_2017_2018_2019_2021" //Nicaragua
drop if id_alex=="ph_Spanish_0_41_2019_2021" //Nicaragua
drop if id_alex=="ph_Spanish_0_100_2019_2021" //Nicaragua
drop if id_alex=="cc_English_0_686_2018_2019_2021" //Nicaragua
replace all_q96_norm=. if id_alex=="lb_Spanish_1_742_2019_2021" // Nicaragua
replace cc_q10_norm=. if id_alex=="cc_Spanish_0_476" // Nicaragua
replace cc_q10_norm=. if id_alex=="cc_Spanish_0_1770" // Nicaragua
replace cc_q16a_norm=. if id_alex=="cc_Spanish (Mexico)_0_652_2019_2021" // Nicaragua
replace cc_q16a_norm=. if id_alex=="cc_Spanish_0_1770" // Nicaragua
replace cc_q14a_norm=. if id_alex=="cc_Spanish_0_1770" //Nicaragua
replace cc_q14b_norm=. if id_alex=="cc_Spanish_0_1770" //Nicaragua
replace cc_q16b_norm=. if id_alex=="cc_Spanish_0_1770" //Nicaragua
replace cc_q16c_norm=. if id_alex=="cc_Spanish_0_1770" //Nicaragua
replace cc_q16d_norm=. if id_alex=="cc_Spanish_0_1770" //Nicaragua
replace cc_q16e_norm=. if id_alex=="cc_Spanish_0_1770" //Nicaragua
replace cc_q16f_norm=. if id_alex=="cc_Spanish_0_1770" //Nicaragua
replace cc_q16g_norm=. if id_alex=="cc_Spanish_0_1770" //Nicaragua
replace cc_q16a_norm=. if id_alex=="cc_Spanish (Mexico)_0_652_2019_2021" // Nicaragua
replace cc_q14a_norm=. if id_alex=="cc_Spanish (Mexico)_0_652_2019_2021" //Nicaragua
replace cc_q14b_norm=. if id_alex=="cc_Spanish (Mexico)_0_652_2019_2021" //Nicaragua
replace cc_q16b_norm=. if id_alex=="cc_Spanish (Mexico)_0_652_2019_2021" //Nicaragua
replace cc_q16c_norm=. if id_alex=="cc_Spanish (Mexico)_0_652_2019_2021" //Nicaragua
replace cc_q16d_norm=. if id_alex=="cc_Spanish (Mexico)_0_652_2019_2021" //Nicaragua
replace cc_q16e_norm=. if id_alex=="cc_Spanish (Mexico)_0_652_2019_2021" //Nicaragua
replace cc_q16f_norm=. if id_alex=="cc_Spanish (Mexico)_0_652_2019_2021" //Nicaragua
replace cc_q16g_norm=. if id_alex=="cc_Spanish (Mexico)_0_652_2019_2021" //Nicaragua
replace cj_q12a_norm=. if id_alex=="cj_Spanish_0_1043" //Nicaragua
replace cj_q12b_norm=. if id_alex=="cj_Spanish_0_1043" //Nicaragua
replace cj_q12c_norm=. if id_alex=="cj_Spanish_0_1043" //Nicaragua
replace cj_q12d_norm=. if id_alex=="cj_Spanish_0_1043" //Nicaragua
replace cj_q12e_norm=. if id_alex=="cj_Spanish_0_1043" //Nicaragua
replace cj_q12f_norm=. if id_alex=="cj_Spanish_0_1043" //Nicaragua
drop if id_alex=="ph_French_1_158" //Niger
drop if id_alex=="ph_French_0_193" //Niger
replace cj_q8_norm=. if id_alex=="cj_French_0_590" //Niger
replace cj_q8_norm=. if id_alex=="cj_French_1_1158" //Niger
replace lb_q19a_norm=. if country=="Niger" /*Niger*/ 
replace cc_q11a_norm=. if country=="Niger" /*Niger*/
replace all_q84_norm=. if country=="Niger"  /*Niger*/
replace all_q85_norm=. if country=="Niger" /*Niger*/
replace cc_q25_norm=. if country=="Niger"  /*Niger*/
replace all_q2_norm=. if country=="Niger"  /*Niger*/
replace cc_q25_norm=. if country=="Niger"  /*Niger*/
replace all_q6_norm=. if country=="Niger"  /*Niger*/
replace all_q46_norm=. if country=="Niger"  /*Niger*/
replace all_q47_norm=. if country=="Niger"  /*Niger*/
replace all_q40_norm=. if id_alex=="cc_French_0_1527_2019_2021" //Niger
replace all_q40_norm=. if id_alex=="cc_French_0_210" //Niger
replace all_q42_norm=. if id_alex=="lb_French_0_162_2019_2021" //Niger
replace all_q42_norm=. if id_alex=="lb_French_1_92" //Niger
replace all_q43_norm=. if id_alex=="lb_French_0_162_2019_2021" //Niger
replace all_q43_norm=. if id_alex=="lb_French_1_92" //Niger
replace cc_q9c_norm=. if id_alex=="cc_French_1_1276_2021" //Niger
replace cc_q9c_norm=. if id_alex=="cc_French_0_210" //Niger
replace cc_q40a_norm=. if id_alex=="cc_French_1_1276_2021" //Niger
replace cc_q40a_norm=. if id_alex=="cc_French_1_1068_2021" //Niger
replace lb_q3d_norm=. if id_alex=="lb_French_1_92" //Niger
replace lb_q2d_norm=. if country=="Niger" //Niger
replace cc_q16a_norm=. if id_alex=="cc_French_1_1276_2021" //Niger
replace cc_q16a_norm=. if id_alex=="cc_French_0_1471" //Niger
replace cc_q16a_norm=. if id_alex=="cc_French_0_210" //Niger
replace cc_q16b_norm=. if country=="Niger" //Niger
replace cc_q16e_norm=. if country=="Niger" //Niger
replace all_q88_norm=. if id_alex=="cc_French_0_1471" //Niger
replace cc_q13_norm=. if id_alex=="cc_French_1_1276_2021" //Niger 
replace cc_q13_norm=. if id_alex=="cc_French_1_904_2021" //Niger
replace cc_q16a_norm=. if id_alex=="cc_French_0_1471" // Niger
replace cc_q14a_norm=. if id_alex=="cc_French_0_1471" //Niger
replace cc_q14b_norm=. if id_alex=="cc_French_0_1471" //Niger
replace cc_q16b_norm=. if id_alex=="cc_French_0_1471" //Niger
replace cc_q16c_norm=. if id_alex=="cc_French_0_1471" //Niger
replace cc_q16d_norm=. if id_alex=="cc_French_0_1471" //Niger
replace cc_q16e_norm=. if id_alex=="cc_French_0_1471" //Niger
replace cc_q16f_norm=. if id_alex=="cc_French_0_1471" //Niger
replace cc_q16g_norm=. if id_alex=="cc_French_0_1471" //Niger
replace cc_q16a_norm=. if id_alex=="cc_French_0_210" // Niger
replace cc_q14a_norm=. if id_alex=="cc_French_0_210" //Niger
replace cc_q14b_norm=. if id_alex=="cc_French_0_210" //Niger
replace cc_q16b_norm=. if id_alex=="cc_French_0_210" //Niger
replace cc_q16c_norm=. if id_alex=="cc_French_0_210" //Niger
replace cc_q16d_norm=. if id_alex=="cc_French_0_210" //Niger
replace cc_q16e_norm=. if id_alex=="cc_French_0_210" //Niger
replace cc_q16f_norm=. if id_alex=="cc_French_0_210" //Niger
replace cc_q16g_norm=. if id_alex=="cc_French_0_210" //Niger
replace all_q49_norm=. if id_alex=="lb_French_0_162_2019_2021" //Niger
replace all_q48_norm=. if id_alex=="lb_French_1_628_2021" //Niger
replace all_q50_norm=. if id_alex=="lb_French_1_628_2021" //Niger
replace lb_q3d_norm=. if id_alex=="lb_French_1_628_2021" //Niger
replace all_q62_norm=. if id_alex=="lb_French_1_628_2021" //Niger
replace all_q63_norm=. if id_alex=="lb_French_1_628_2021" //Niger
replace cj_q12a_norm=. if id_alex=="cj_French_1_546" //Niger
replace cj_q12b_norm=. if id_alex=="cj_French_1_546" //Niger
replace cj_q12c_norm=. if id_alex=="cj_French_1_546" //Niger
replace cj_q12d_norm=. if id_alex=="cj_French_1_546" //Niger
replace cj_q12e_norm=. if id_alex=="cj_French_1_546" //Niger
replace cj_q12f_norm=. if id_alex=="cj_French_1_546" //Niger
replace cj_q20o_norm=. if id_alex=="cj_French_0_858_2019_2021" //Niger
replace cj_q31f_norm=. if id_alex=="cj_French_0_858_2019_2021" //Niger
replace cj_q31g_norm=. if id_alex=="cj_French_0_858_2019_2021" //Niger
replace cj_q42c_norm=. if id_alex=="cj_English_0_718_2019_2021" //Niger
replace cj_q42d_norm=. if id_alex=="cj_English_1_1245_2019_2021" //Niger
drop if id_alex=="cc_English_0_271" //Nigeria
replace all_q29_norm=. if id_alex=="cc_English_0_403" //Nigeria
replace all_q29_norm=. if id_alex=="cc_English_0_1311" //Nigeria
replace all_q29_norm=. if id_alex=="cc_English_0_967_2021" //Nigeria
replace all_q30_norm=. if id_alex=="cc_English_0_967_2021" //Nigeria
replace all_q29_norm=. if id_alex=="cj_English_0_196_2019_2021" //Nigeria
replace all_q18_norm=. if id_alex=="cc_English_0_1409_2016_2017_2018_2019_2021" //Nigeria
replace all_q18_norm=. if id_alex=="cc_English_0_360_2016_2017_2018_2019_2021" //Nigeria
replace all_q18_norm=. if id_alex=="cc_English_1_1326_2018_2019_2021" //Nigeria
replace all_q18_norm=0 if id_alex=="cc_English_0_1579_2018_2019_2021" //Nigeria
replace all_q18_norm=. if id_alex=="cc_English_1_1459_2019_2021" //Nigeria
replace all_q18_norm=. if id_alex=="cc_English_1_1461_2019_2021" //Nigeria
replace all_q18_norm=. if id_alex=="cj_English_1_316_2016_2017_2018_2019_2021" //Nigeria
replace all_q18_norm=. if id_alex=="cj_English_0_1044_2017_2018_2019_2021" //Nigeria
replace all_q18_norm=0 if id_alex=="cj_English_1_257" //Nigeria
replace all_q18_norm=0 if id_alex=="cc_English_1_857_2021" //Nigeria
replace all_q18_norm=0 if id_alex=="cc_English_1_1498_2021" //Nigeria
replace all_q18_norm=0 if id_alex=="cc_English_0_1814_2018_2019_2021" //Nigeria
replace cj_q20o_norm=. if id_alex=="cj_English_0_528" //Nigeria
replace cj_q20o_norm=. if id_alex=="cj_English_0_948" //Nigeria
drop if id_alex=="cj_English_1_271" //North Macedonia
drop if id_alex=="cj_English_0_720" //North Macedonia
drop if id_alex=="cc_English_0_374" //North Macedonia
drop if id_alex=="lb_English_1_719" //North Macedonia
replace all_q96_norm=. if id_alex=="cc_English_1_403_2017_2018_2019_2021" //North Macedonia
replace all_q96_norm=. if id_alex=="cj_English_0_619_2017_2018_2019_2021" //North Macedonia
drop if id_alex=="cj_English_0_609" //Norway
replace all_q89_norm=. if country=="Norway" /*Norway*/
replace all_q62_norm=. if id_alex=="cc_English_0_1499_2017_2018_2019_2021" //Norway
replace all_q63_norm=. if id_alex=="cc_English_0_1499_2017_2018_2019_2021" //Norway
replace all_q62_norm=. if id_alex=="cc_English_0_781" //Norway
replace all_q63_norm=. if id_alex=="cc_English_0_781" //Norway
replace cj_q40b_norm=. if id_alex=="cj_English_1_434_2018_2019_2021" //Norway
replace cc_q10_norm=. if id_alex=="cc_English_0_1499_2017_2018_2019_2021" //Norway
replace cc_q11a_norm=. if id_alex=="cc_English_0_1499_2017_2018_2019_2021" //Norway
replace cc_q16a_norm=. if id_alex=="cc_English_0_1499_2017_2018_2019_2021" //Norway
drop if id_alex=="cj_English_0_843" //Pakistan
replace cj_q31e_norm=. if id_alex=="cj_English_0_879" //Pakistan
replace cj_q31e_norm=. if id_alex=="cj_English_0_1152" //Pakistan
replace cj_q11b_norm=. if id_alex=="cj_English_0_879" //Pakistan
replace cj_q11b_norm=. if id_alex=="cj_English_0_1152" //Pakistan
replace cj_q11b_norm=. if id_alex=="cj_English_0_700" //Pakistan
replace cj_q10_norm=. if id_alex=="cj_English_0_879" //Pakistan
replace lb_q16a_norm=. if id_alex=="lb_English_1_284_2018_2019_2021" //Pakistan
replace lb_q16b_norm=. if id_alex=="lb_English_1_598" //Pakistan
replace lb_q16e_norm=. if id_alex=="lb_English_0_470" //Pakistan
replace lb_q16f_norm=. if id_alex=="lb_English_1_226" //Pakistan
replace lb_q16f_norm=. if id_alex=="lb_English_0_470" //Pakistan
replace lb_q23g_norm=. if id_alex=="lb_English_1_800" //Pakistan
replace cc_q13_norm=. if id_alex=="cc_English_1_1301_2019_2021" //Pakistan
replace all_q88_norm=. if id_alex=="cc_English_1_1301_2019_2021" //Pakistan
replace cc_q26a_norm=. if id_alex=="cc_English_1_1301_2019_2021" //Pakistan
replace cc_q26b_norm=. if id_alex=="cc_English_1_1301_2019_2021" //Pakistan
replace all_q86_norm=. if id_alex=="cc_English_1_1301_2019_2021" //Pakistan
replace all_q87_norm=. if id_alex=="cc_English_1_1301_2019_2021" //Pakistan
replace all_q88_norm=. if id_alex=="lb_English_1_158" //Pakistan
replace all_q88_norm=. if id_alex=="lb_English_1_800" //Pakistan
replace cc_q13_norm=. if id_alex=="cc_English_0_1036_2021" //Pakistan
replace all_q88_norm=. if id_alex=="cc_English_0_1036_2021" //Pakistan
replace cc_q26a_norm=. if id_alex=="cc_English_0_1036_2021" //Pakistan
replace all_q88_norm=. if id_alex=="lb_English_0_531_2016_2017_2018_2019_2021" //Pakistan
replace cj_q11b_norm=. if id_alex=="cj_English_0_437_2016_2017_2018_2019_2021" //Pakistan
replace cj_q31e_norm=. if id_alex=="cj_English_0_437_2016_2017_2018_2019_2021" //Pakistan
replace cj_q42c_norm=. if id_alex=="cj_English_0_437_2016_2017_2018_2019_2021" //Pakistan
replace cc_q25_norm=. if id_alex=="cc_English_1_1301_2019_2021" //Pakistan
replace all_q3_norm=. if id_alex=="cc_English_1_1301_2019_2021" //Pakistan
replace all_q4_norm=. if id_alex=="cc_English_1_1301_2019_2021" //Pakistan
replace all_q3_norm=. if id_alex=="cj_English_1_795_2021" //Pakistan
replace all_q4_norm=. if id_alex=="cj_English_1_795_2021" //Pakistan
replace all_q7_norm=. if id_alex=="cj_English_1_795_2021" //Pakistan
replace cj_q40b_norm=. if id_alex=="cj_English_1_795_2021" //Pakistan
replace cj_q40c_norm=. if id_alex=="cj_English_1_795_2021" //Pakistan
replace cj_q20m_norm=. if id_alex=="cj_English_1_795_2021" //Pakistan
replace cc_q25_norm=. if id_alex=="cc_English_0_846" //Pakistan
replace cc_q25_norm=. if id_alex=="cc_English_0_1670" //Pakistan
replace all_q3_norm=. if id_alex=="cc_English_0_1670" //Pakistan
replace all_q4_norm=. if id_alex=="cc_English_0_1670" //Pakistan
replace all_q3_norm=. if id_alex=="cc_English_0_801_2021" //Pakistan
replace all_q4_norm=. if id_alex=="cc_English_0_801_2021" //Pakistan
replace all_q3_norm=. if id_alex=="lb_English_1_705_2021" //Pakistan
replace all_q4_norm=. if id_alex=="lb_English_1_705_2021" //Pakistan
replace all_q7_norm=. if id_alex=="lb_English_1_705_2021" //Pakistan
replace all_q3_norm=. if id_alex=="cj_English_1_539_2019_2021" //Pakistan
replace all_q4_norm=. if id_alex=="cj_English_1_539_2019_2021" //Pakistan
replace all_q7_norm=. if id_alex=="cj_English_1_539_2019_2021" //Pakistan
replace cc_q25_norm=. if id_alex=="cc_English_1_1301_2019_2021" //Pakistan
replace all_q3_norm=. if id_alex=="cc_English_1_369_2019_2021" //Pakistan
replace all_q4_norm=. if id_alex=="cc_English_1_369_2019_2021" //Pakistan
replace all_q7_norm=. if id_alex=="cc_English_1_369_2019_2021" //Pakistan
replace all_q2_norm=. if id_alex=="cc_English_0_39" //Pakistan
replace all_q3_norm=. if id_alex=="cc_English_0_39" //Pakistan
replace all_q2_norm=. if id_alex=="cj_English_0_444_2017_2018_2019_2021" //Pakistan
replace all_q2_norm=. if id_alex=="lb_English_1_622_2017_2018_2019_2021" //Pakistan
replace all_q2_norm=. if id_alex=="cc_English_0_668_2018_2019_2021" //Pakistan
replace all_q76_norm=. if id_alex=="lb_English_1_622_2017_2018_2019_2021" //Pakistan
replace all_q77_norm=. if id_alex=="lb_English_1_622_2017_2018_2019_2021" //Pakistan
replace all_q79_norm=. if id_alex=="lb_English_1_622_2017_2018_2019_2021" //Pakistan
replace all_q76_norm=. if id_alex=="cc_English_1_1191_2018_2019_2021" //Pakistan
replace all_q77_norm=. if id_alex=="cc_English_1_1191_2018_2019_2021" //Pakistan
replace all_q78_norm=. if id_alex=="cc_English_1_1191_2018_2019_2021" //Pakistan
replace all_q79_norm=. if id_alex=="cc_English_1_1191_2018_2019_2021" //Pakistan
replace all_q80_norm=. if id_alex=="cc_English_1_1191_2018_2019_2021" //Pakistan
replace all_q81_norm=. if id_alex=="cc_English_1_1191_2018_2019_2021" //Pakistan
replace all_q76_norm=. if id_alex=="lb_English_1_620" //Pakistan
replace all_q77_norm=. if id_alex=="lb_English_1_620" //Pakistan
replace all_q78_norm=. if id_alex=="lb_English_1_620" //Pakistan
replace all_q79_norm=. if id_alex=="lb_English_1_620" //Pakistan
replace all_q80_norm=. if id_alex=="lb_English_1_620" //Pakistan
replace all_q81_norm=. if id_alex=="lb_English_1_620" //Pakistan
replace all_q82_norm=. if id_alex=="lb_English_1_620" //Pakistan
replace all_q84_norm=. if id_alex=="cc_English_0_39" //Pakistan
replace all_q85_norm=. if id_alex=="cc_English_0_39" //Pakistan
replace cc_q13_norm=. if id_alex=="cc_English_0_39" //Pakistan
replace all_q88_norm=. if id_alex=="cc_English_0_39" //Pakistan
replace cc_q26a_norm=. if id_alex=="cc_English_0_39" //Pakistan
replace all_q48_norm=. if id_alex=="lb_English_1_622_2017_2018_2019_2021" //Pakistan
replace all_q49_norm=. if id_alex=="lb_English_1_622_2017_2018_2019_2021" //Pakistan
replace all_q50_norm=. if id_alex=="lb_English_1_622_2017_2018_2019_2021" //Pakistan
replace lb_q19a_norm=. if id_alex=="lb_English_1_622_2017_2018_2019_2021" //Pakistan
replace all_q12_norm=. if id_alex=="cc_English_1_1301_2019_2021" //Pakistan
replace all_q12_norm=. if id_alex=="cc_English_1_369_2019_2021" //Pakistan
replace all_q85_norm=. if id_alex=="cc_English_0_1285_2017_2018_2019_2021" //Pakistan
replace all_q88_norm=. if id_alex=="cc_English_0_1285_2017_2018_2019_2021" //Pakistan
replace cc_q26a_norm=. if id_alex=="cc_English_0_1285_2017_2018_2019_2021" //Pakistan
replace all_q87_norm=. if id_alex=="cc_English_0_1285_2017_2018_2019_2021" //Pakistan
replace cc_q26a_norm=. if id_alex=="cc_English_1_397_2017_2018_2019_2021" //Pakistan
replace cc_q26b_norm=. if id_alex=="cc_English_1_397_2017_2018_2019_2021" //Pakistan
replace all_q82_norm=. if id_alex=="lb_English_1_591_2018_2019_2021" //Pakistan
replace all_q59_norm=. if country=="Panama" //Panama
replace cj_q20o_norm=. if id_alex=="cj_Spanish_0_572_2021" //Panama
replace cc_q40a_norm=. if id_alex=="cc_English_1_241" //Panama
replace cc_q40b_norm=. if id_alex=="cc_English_1_241" //Panama
replace all_q10_norm=. if id_alex=="lb_Spanish_0_272_2021" //Panama
replace all_q11_norm=. if id_alex=="lb_Spanish_0_272_2021" //Panama
replace all_q12_norm=. if id_alex=="lb_Spanish_0_272_2021" //Panama
replace all_q10_norm=. if id_alex=="lb_Spanish_1_483" //Panama
replace all_q11_norm=. if id_alex=="lb_Spanish_1_483" //Panama
replace all_q12_norm=. if id_alex=="lb_Spanish_1_483" //Panama
replace all_q29_norm=. if id_alex=="cj_Spanish_0_888_2018_2019_2021" //Panama
replace all_q30_norm=. if id_alex=="cj_Spanish_0_888_2018_2019_2021" //Panama
replace all_q29_norm=. if id_alex=="cj_English_1_654" //Panama
replace all_q29_norm=. if id_alex=="cj_Spanish_1_984" //Panama
replace cj_q42c_norm=. if country=="Paraguay" /*Paraguay*/
replace cj_q42d_norm=. if country=="Paraguay" /*Paraguay*/
replace cj_q6d_norm=. if country=="Paraguay" /*Paraguay*/
replace all_q59_norm=. if id_alex=="lb_Spanish_0_219" //Paraguay
replace all_q59_norm=. if id_alex=="lb_Spanish_0_105" //Paraguay
replace all_q84_norm=. if id_alex=="cc_Spanish_0_56" //Paraguay
replace all_q85_norm=. if id_alex=="cc_Spanish_0_1399" //Paraguay
replace all_q85_norm=. if id_alex=="lb_Spanish_0_219" //Paraguay
replace cj_q12f_norm=. if id_alex=="cj_Spanish_0_88" //Paraguay
replace cj_q20o_norm=. if id_alex=="cj_Spanish_1_299" //Paraguay
replace lb_q2d_norm=. if country=="Paraguay" //Paraguay
replace all_q62_norm=. if id_alex=="cc_English_1_366" //Paraguay
replace all_q63_norm=. if id_alex=="cc_English_1_366" //Paraguay
replace cc_q14b_norm=. if country=="Paraguay" /*Paraguay*/
replace cj_q21g_norm=. if id_alex=="cj_Spanish_0_88" //Paraguay
replace cj_q28_norm=. if id_alex=="cj_Spanish_0_901_2021" //Paraguay
replace cj_q40b_norm=. if id_alex=="cj_Spanish_0_88" //Paraguay
replace cj_q40c_norm=. if id_alex=="cj_Spanish_0_88" //Paraguay
replace all_q88_norm=. if id_alex=="cc_Spanish_0_940" //Paraguay
replace cc_q26a_norm=. if id_alex=="cc_Spanish_0_940" //Paraguay
replace all_q88_norm=. if id_alex=="cc_Spanish_0_1690" //Paraguay
replace cc_q26a_norm=. if id_alex=="cc_Spanish_0_1690" //Paraguay
replace cc_q33_norm=. if id_alex=="cc_Spanish_0_392" //Paraguay
replace all_q9_norm=. if id_alex=="lb_Spanish_0_807_2021" //Paraguay
drop if id_alex=="cc_Spanish_0_553" //Paraguay
replace cj_q10_norm=0.6666667 if id_alex=="cj_Spanish_0_88" //Paraguay
replace cj_q21e_norm=. if id_alex=="cj_Spanish_0_901_2021" //Paraguay
replace cj_q21h_norm=. if id_alex=="cj_Spanish_0_901_2021" //Paraguay
replace cj_q40b_norm=. if id_alex=="cj_Spanish_0_901_2021" //Paraguay
replace all_q88_norm=. if country=="Philippines" /*Philippines*/
replace cc_q26a_norm=. if country=="Philippines" /*Philippines*/
drop if id_alex=="ph_English_1_94" //Philippines
drop if id_alex=="ph_English_1_186" //Philippines 
drop if id_alex=="ph_English_1_626" //Philippines
replace lb_q16a_norm=. if id_alex=="lb_English_1_438" //Philippines
replace lb_q16a_norm=. if id_alex=="lb_English_1_488" //Philippines
replace lb_q16b_norm=. if id_alex=="lb_English_1_438" //Philippines
replace lb_q16b_norm=. if id_alex=="lb_English_1_488" //Philippines
replace lb_q16c_norm=. if id_alex=="lb_English_1_438" //Philippines
replace lb_q16c_norm=. if id_alex=="lb_English_1_488" //Philippines
replace lb_q16d_norm=. if id_alex=="lb_English_1_438" //Philippines
replace lb_q16d_norm=. if id_alex=="lb_English_1_488" //Philippines
replace lb_q16e_norm=. if id_alex=="lb_English_1_438" //Philippines
replace lb_q16e_norm=. if id_alex=="lb_English_1_488" //Philippines
replace lb_q16f_norm=. if id_alex=="lb_English_1_438" //Philippines
replace lb_q16f_norm=. if id_alex=="lb_English_1_488" //Philippines
replace cj_q11a_norm=. if id_alex=="cj_English_0_491_2016_2017_2018_2019_2021" //Philippines
replace cj_q11a_norm=. if id_alex=="cj_English_0_857" //Philippines
replace cj_q31e_norm=. if id_alex=="cj_English_0_619" //Philippines
replace all_q40_norm=. if id_alex=="cc_English_0_606_2017_2018_2019_2021" //Philippines
replace all_q40_norm=. if id_alex=="cc_English_1_781" //Philippines
replace all_q45_norm=. if id_alex=="cc_English_1_898" //Philippines
replace cc_q9b_norm=. if country=="Philippines" //Philippines
replace all_q46_norm=. if country=="Philippines" //Philippines
replace all_q47_norm=. if country=="Philippines" //Philippines
drop if id_alex=="cc_English_1_146" //Philippines
drop if id_alex=="ph_English_0_353_2018_2019_2021" //Philippines
drop if id_alex=="cc_English_0_947"  //Philippines
replace all_q52_norm=. if id_alex=="cc_English_0_1213_2017_2018_2019_2021" //Philippines
replace all_q52_norm=. if id_alex=="cc_English_0_1570_2021" //Philippines
replace cj_q8_norm=. if id_alex=="cj_English_0_619" //Philippines
replace all_q12_norm=. if id_alex=="cc_English_1_1367_2021" //Philippines
replace cc_q39b_norm=. if id_alex=="cc_English_0_1255" //Philippines
replace cc_q26b_norm=. if id_alex=="cc_English_1_841" //Philippines
replace all_q86_norm =. if id_alex=="lb_English_1_151" //Philippines
replace cc_q11a_norm =. if id_alex=="cc_English_1_164" //Philippines
replace cj_q31e_norm =. if id_alex=="cj_English_1_697" //Philippines
replace cj_q42c_norm =. if id_alex=="cj_English_1_697" //Philippines
replace cj_q42d_norm =. if id_alex=="cj_English_1_697" //Philippines
replace cj_q42d_norm =. if id_alex=="cj_English_1_109_2019_2021" //Philippines
replace cj_q42c_norm =. if id_alex=="cj_English_0_956_2018_2019_2021" //Philippines
replace cj_q42d_norm =. if id_alex=="cj_English_0_956_2018_2019_2021" //Philippines

replace cc_q39b_norm=. if country=="Philippines" //Philippines

drop if id_alex=="cc_English_0_213" //Poland
drop if id_alex=="cc_English_0_1250" //Poland
drop if id_alex=="cc_English_0_292" //Poland
drop if id_alex=="ph_English_1_141" //Poland
replace cc_q40a_norm=. if country=="Poland" /*Poland*/
replace all_q89_norm=. if country=="Poland" /*Poland*/
replace cc_q25_norm=. if country=="Poland" /* Poland */
replace all_q2_norm=. if id_alex=="cc_English_1_1462" //Poland
replace all_q2_norm=. if id_alex=="cj_English_0_305_2019_2021" //Poland
replace all_q21_norm=. if id_alex=="cc_English_1_1462" //Poland
replace all_q21_norm=. if id_alex=="cc_English_1_1147" //Poland
replace all_q21_norm=. if id_alex=="lb_English_0_656" //Poland
replace all_q5_norm=. if id_alex=="cc_English_1_1462" //Poland
replace all_q5_norm=. if id_alex=="cc_English_0_1260" //Poland
replace cj_q8_norm=. if country=="Poland" //Poland
replace cc_q33_norm=. if id_alex=="cc_Enlish_1_1147" //Poland
replace cc_q33_norm=. if id_alex=="cc_English_1_1462" //Poland
replace cc_q9b_norm=. if id_alex=="cc_English_0_802_2016_2017_2018_2019_2021" //Poland
replace cc_q39b_norm=. if id_alex=="cc_English_0_812" //Poland
replace all_q42_norm=. if country=="Poland" //Poland
replace all_q80_norm=. if country=="Poland" //Poland
replace all_q59_norm=. if id_alex=="cc_English_0_812" //Poland
replace all_q59_norm=. if id_alex=="cc_English_0_1260" //Poland
replace all_q59_norm=. if id_alex=="lb_English_0_656" //Poland
replace all_q59_norm=. if id_alex=="lb_English_0_449" //Poland
replace all_q59_norm=. if id_alex=="lb_English_1_731" //Poland
replace cc_q14b_norm=. if id_alex=="cc_English_0_1260" //Poland
replace all_q88_norm=. if id_alex=="cc_English_0_802_2016_2017_2018_2019_2021" //Poland
replace cc_q26a_norm=. if id_alex=="cc_English_0_802_2016_2017_2018_2019_2021" //Poland
replace all_q88_norm=. if id_alex=="cc_English_0_559_2019_2021" //Poland
replace all_q12_norm=. if id_alex=="lb_English_0_533_2017_2018_2019_2021" //Poland
replace all_q12_norm=. if id_alex=="lb_English_1_334_2021" //Poland
drop if id_alex=="cc_Portuguese_1_1055" //Portugal
drop if id_alex=="cj_Portuguese_1_558" //Portugal
drop if id_alex=="ph_Portuguese_1_190" //Portugal
drop if id_alex=="cc_Portuguese_1_268" //Portugal
drop if id_alex=="lb_Portuguese_0_296" //Portugal
replace all_q76_norm=. if id_alex=="cc_Portuguese_0_744_2018_2019_2021" //Portugal
replace all_q77_norm=. if id_alex=="cc_Portuguese_0_744_2018_2019_2021" //Portugal
replace all_q78_norm=. if id_alex=="cc_Portuguese_0_744_2018_2019_2021" //Portugal
replace all_q79_norm=. if id_alex=="cc_Portuguese_0_744_2018_2019_2021" //Portugal
replace all_q80_norm=. if id_alex=="cc_Portuguese_0_744_2018_2019_2021" //Portugal
replace all_q81_norm=. if id_alex=="cc_Portuguese_0_744_2018_2019_2021" //Portugal
replace all_q82_norm=. if id_alex=="cc_Portuguese_0_744_2018_2019_2021" //Portugal
replace all_q19_norm=. if id_alex=="cc_Portuguese_0_1454_2018_2019_2021" //Portugal
replace all_q31_norm=. if id_alex=="cc_Portuguese_0_1454_2018_2019_2021" //Portugal
replace all_q14_norm=. if id_alex=="cc_Portuguese_0_1454_2018_2019_2021" //Portugal
replace all_q19_norm=. if id_alex=="cc_Portuguese_1_1252_2018_2019_2021" //Portugal
replace all_q31_norm=. if id_alex=="cc_Portuguese_1_1252_2018_2019_2021" //Portugal
replace all_q14_norm=. if id_alex=="cc_Portuguese_1_1252_2018_2019_2021" //Portugal
replace all_q19_norm=. if id_alex=="cc_Portuguese_0_1186_2019_2021" //Portugal
replace all_q31_norm=. if id_alex=="cc_Portuguese_0_1186_2019_2021" //Portugal
replace all_q14_norm=. if id_alex=="cc_Portuguese_0_1186_2019_2021" //Portugal
replace all_q19_norm=. if id_alex=="cc_Portuguese_1_1249_2019_2021" //Portugal
replace all_q31_norm=. if id_alex=="cc_Portuguese_1_1249_2019_2021" //Portugal
replace all_q14_norm=. if id_alex=="cc_Portuguese_1_1249_2019_2021" //Portugal 
replace all_q19_norm=. if id_alex=="cj_English_1_395_2016_2017_2018_2019_2021" //Portugal
replace all_q31_norm=. if id_alex=="cj_English_1_395_2016_2017_2018_2019_2021" //Portugal
replace all_q14_norm=. if id_alex=="cj_English_1_395_2016_2017_2018_2019_2021" //Portugal 
replace all_q19_norm=. if id_alex=="cj_English_0_664_2016_2017_2018_2019_2021" //Portugal
replace all_q31_norm=. if id_alex=="cj_English_0_664_2016_2017_2018_2019_2021" //Portugal
replace all_q14_norm=. if id_alex=="cj_English_0_664_2016_2017_2018_2019_2021" //Portugal 
replace all_q19_norm=. if id_alex=="cj_English_0_784_2017_2018_2019_2021" //Portugal
replace all_q31_norm=. if id_alex=="cj_English_0_784_2017_2018_2019_2021" //Portugal
replace all_q14_norm=. if id_alex=="cj_English_0_784_2017_2018_2019_2021" //Portugal 
replace all_q19_norm=. if id_alex=="cj_Portuguese_1_373_2018_2019_2021" //Portugal
replace all_q31_norm=. if id_alex=="cj_Portuguese_1_373_2018_2019_2021" //Portugal
replace all_q14_norm=. if id_alex=="cj_Portuguese_1_373_2018_2019_2021" //Portugal 
drop if id_alex=="cc_English_1_767" //Romania
drop if id_alex=="lb_English_1_392" //Romania
drop if id_alex=="ph_English_0_316_2019_2021" //Romania
drop if id_alex=="ph_English_0_330_2021" //Romania
drop if id_alex=="cc_Russian_0_786" //Russia
drop if id_alex=="lb_Russian_0_248" //Russia
drop if id_alex=="ph_English_1_286" //Russia
replace cj_q21h_norm=. if country=="Russian Federation" /* Russia */
replace all_q59_norm=. if country=="Russian Federation" /* Russia */
replace lb_q19a_norm=. if id_alex=="lb_Russian_0_88" /* Russia */
replace all_q50_norm=. if id_alex=="cc_English_1_1006_2017_2018_2019_2021" /* Russia */
replace all_q50_norm=. if id_alex=="lb_Russian_1_757_2019_2021" /* Russia */
replace all_q50_norm=. if id_alex=="lb_Russian_0_88" /* Russia */
drop if id_alex=="cc_Russian_1_678" 
replace cj_q11b_norm=. if id_alex=="cj_English_1_1114" /* Russia */
replace cj_q31e_norm=. if id_alex=="cj_English_1_1114" /* Russia */
replace cj_q42c_norm=. if id_alex=="cj_English_1_1114" /* Russia */
replace cj_q42d_norm=. if id_alex=="cj_English_1_1114" /* Russia */
replace cj_q42c_norm=. if id_alex=="cj_English_0_931_2017_2018_2019_2021" /* Russia */
replace lb_q23a_norm=. if id_alex=="lb_English_0_584_2021" /* Russia */
replace lb_q23b_norm=. if id_alex=="lb_English_0_584_2021" /* Russia */
replace lb_q23c_norm=. if id_alex=="lb_English_0_584_2021" /* Russia */
replace lb_q23d_norm=. if id_alex=="lb_English_0_584_2021" /* Russia */
replace lb_q23e_norm=. if id_alex=="lb_English_0_584_2021" /* Russia */
replace all_q18_norm=. if id_alex=="cc_Russian_0_1183" /* Russia */
drop if id_alex=="cc_English_1_867" //Rwanda
drop if id_alex=="cc_English_1_1341" //Rwanda
drop if id_alex=="cc_English_1_258" //Rwanda
drop if id_alex=="cc_English_1_231" //Rwanda
drop if id_alex=="cc_English_1_1369_2021" //Rwanda
drop if id_alex=="cj_English_0_336" //Rwanda
drop if id_alex=="cj_English_0_801" //Rwanda
drop if id_alex=="cj_English_0_1122" //Rwanda
drop if id_alex=="lb_English_0_164" //Rwanda
drop if id_alex=="ph_English_0_408_2021" //Rwanda
drop if id_alex=="ph_English_1_147" //Rwanda
replace cc_q33_norm=. if country=="Rwanda" /* Rwanda */
replace all_q9_norm=. if country=="Rwanda" /* Rwanda */
replace all_q58_norm=. if country=="Rwanda" /* Rwanda */
replace all_q59_norm=. if country=="Rwanda" /* Rwanda */
replace all_q60_norm=. if country=="Rwanda" /* Rwanda */
replace all_q28_norm=. if id_alex=="lb_English_1_740" /* Rwanda */
replace cc_q13_norm=. if country=="Rwanda" /* Rwanda */
replace cc_q26a_norm=. if country=="Rwanda" /* Rwanda */
replace cc_q39c_norm=. if id_alex=="cc_French_0_998_2021" /* Rwanda */
replace cc_q39c_norm=. if id_alex=="cc_English_0_1678" /* Rwanda */
replace cc_q39e_norm=. if id_alex=="cc_English_0_1678" /* Rwanda */
replace cc_q9b_norm=. if id_alex=="cc_French_1_984_2019_2021" /* Rwanda */
replace cc_q9b_norm=. if id_alex=="cc_English_0_1043" /* Rwanda */
replace cc_q9c_norm=. if country=="Rwanda" /* Rwanda */
replace all_q29_norm=. if country=="Rwanda" /* Rwanda */
replace all_q45_norm=. if country=="Rwanda" /* Rwanda */
replace all_q46_norm=. if country=="Rwanda" /* Rwanda */
replace all_q48_norm=. if id_alex=="cc_English_0_286_2019_2021" /* Rwanda */
replace all_q48_norm=. if id_alex=="lb_English_0_143" /* Rwanda */
replace all_q48_norm=. if id_alex=="lb_English_1_363" /* Rwanda */
replace all_q50_norm=. if id_alex=="cc_English_0_286_2019_2021" /* Rwanda */
replace all_q50_norm=. if id_alex=="lb_English_0_143" /* Rwanda */
replace all_q50_norm=. if id_alex=="lb_English_1_363" /* Rwanda */
replace all_q51_norm=. if id_alex=="lb_English_1_755_2021" /* Rwanda */
replace all_q51_norm=. if id_alex=="lb_English_0_306_2021" /* Rwanda */
replace all_q54_norm=. if country=="Rwanda" /* Rwanda */
replace all_q78_norm=. if country=="Rwanda" /* Rwanda */
replace all_q79_norm=. if country=="Rwanda" /* Rwanda */
replace all_q80_norm=. if country=="Rwanda" /* Rwanda */
replace all_q81_norm=. if country=="Rwanda" /* Rwanda */
replace all_q82_norm=. if country=="Rwanda" /* Rwanda */
replace all_q85_norm=. if country=="Rwanda" /* Rwanda */
replace all_q90_norm=. if country=="Rwanda" /* Rwanda */
replace all_q91_norm=. if id_alex=="lb_English_1_363" /* Rwanda */
replace cj_q33b_norm=. if country=="Rwanda" /* Rwanda */
replace cj_q40b_norm=. if id_alex=="cj_English_1_1230_2019_2021" /* Rwanda */
replace cj_q40b_norm=. if id_alex=="cj_French_0_924" /* Rwanda */	 
replace cj_q40c_norm=. if id_alex=="cj_French_0_924" /* Rwanda */
replace lb_q6c_norm=. if country=="Rwanda" /* Rwanda */
replace lb_q16e_norm=. if country=="Rwanda" /* Rwanda */
replace lb_q16f_norm=. if country=="Rwanda" /* Rwanda */
replace lb_q23a_norm=. if id_alex=="lb_English_1_363" /* Rwanda */
replace lb_q23b_norm=. if id_alex=="lb_English_1_363" /* Rwanda */
replace lb_q23d_norm=. if id_alex=="lb_English_1_363" /* Rwanda */
replace lb_q23e_norm=. if id_alex=="lb_English_1_363" /* Rwanda */
replace all_q96_norm=. if id_alex=="cc_English_0_286_2019_2021" /* Rwanda */
replace all_q96_norm=. if id_alex=="cc_English_0_1555_2021" /* Rwanda */
replace all_q96_norm=. if id_alex=="cc_French_0_998_2021" /* Rwanda */
replace cc_q39b_norm=. if id_alex=="cc_English_0_1935_2018_2019_2021" /* Rwanda */
replace cc_q39b_norm=. if id_alex=="cc_French_1_984_2019_2021" /* Rwanda */
replace cc_q39b_norm=. if id_alex=="cc_English_0_1043" /* Rwanda */
replace cc_q9b_norm=. if id_alex=="cc_English_0_1935_2018_2019_2021" /* Rwanda */
replace cc_q39c_norm=. if id_alex=="cc_English_0_1935_2018_2019_2021" /* Rwanda */
replace cc_q40a_norm =. if id_alex=="cc_English_0_339_2019_2021" /* Rwanda */
replace cc_q40b_norm =. if id_alex=="cc_English_0_339_2019_2021" /* Rwanda */
replace cc_q40b_norm =. if id_alex=="cc_English_0_1043" /* Rwanda */
replace cj_q11b_norm =. if id_alex=="cj_French_1_1202_2021" /* Rwanda */
replace cj_q31e_norm =. if id_alex=="cj_French_1_1202_2021" /* Rwanda */
replace cj_q42c_norm =. if id_alex=="cj_French_1_1202_2021" /* Rwanda */
replace cj_q42d_norm =. if id_alex=="cj_French_1_1202_2021" /* Rwanda */
replace lb_q16a_norm =. if id_alex=="lb_English_1_363" /* Rwanda */
replace lb_q16b_norm =. if id_alex=="lb_English_1_363" /* Rwanda */
replace lb_q16c_norm =. if id_alex=="lb_English_1_363" /* Rwanda */
replace lb_q16d_norm =. if id_alex=="lb_English_1_363" /* Rwanda */
replace lb_q23f_norm =. if id_alex=="lb_English_1_363" /* Rwanda */
replace lb_q23g_norm =. if id_alex=="lb_English_1_363" /* Rwanda */
replace lb_q17b_norm =. if id_alex=="lb_English_0_143" /* Rwanda */
replace lb_q17c_norm =. if id_alex=="lb_English_0_143" /* Rwanda */
replace lb_q17e_norm =. if id_alex=="lb_English_0_143" /* Rwanda */
replace lb_q17b_norm =. if id_alex=="lb_English_1_740" /* Rwanda */
replace lb_q17c_norm =. if id_alex=="lb_English_1_740" /* Rwanda */
replace lb_q17e_norm =. if id_alex=="lb_English_1_740" /* Rwanda */
replace all_q56_norm =. if id_alex=="lb_English_1_363" /* Rwanda */
replace all_q55_norm =. if id_alex=="cc_English_0_1043" /* Rwanda */
replace all_q89_norm =. if id_alex=="lb_English_0_374_2019_2021" /* Rwanda */
replace all_q89_norm =. if id_alex=="lb_English_0_143" /* Rwanda */
replace all_q89_norm =. if id_alex=="cc_English_0_1935_2018_2019_2021" /* Rwanda */
replace cc_q14a_norm =. if id_alex=="cc_English_0_1043" /* Rwanda */
replace cc_q14a_norm =. if id_alex=="cc_English_0_1678" /* Rwanda */
replace ph_q8a_norm =0.6666667 if id_alex=="ph_French_0_135_2018_2019_2021" /* Rwanda */
replace ph_q8b_norm =0.6666667 if id_alex=="ph_French_0_135_2018_2019_2021" /* Rwanda */
replace ph_q8c_norm =0.6666667 if id_alex=="ph_French_0_135_2018_2019_2021" /* Rwanda */
replace ph_q8e_norm =0.6666667 if id_alex=="ph_French_0_135_2018_2019_2021" /* Rwanda */
replace ph_q8f_norm =0.6666667 if id_alex=="ph_French_0_135_2018_2019_2021" /* Rwanda */
replace ph_q8g_norm =0.6666667 if id_alex=="ph_French_0_135_2018_2019_2021" /* Rwanda */
replace ph_q9d_norm =0.6666667 if id_alex=="ph_French_0_135_2018_2019_2021" /* Rwanda */
replace ph_q11a_norm =0.6666667 if id_alex=="ph_French_0_135_2018_2019_2021" /* Rwanda */
replace ph_q12c_norm =0.6666667 if id_alex=="ph_French_0_135_2018_2019_2021" /* Rwanda */
replace ph_q8d_norm =0.6666667 if id_alex=="ph_French_0_135_2018_2019_2021" /* Rwanda */
replace lb_q17e_norm =. if id_alex=="lb_English_0_306_2021" /* Rwanda */
replace lb_q17c_norm =. if id_alex=="lb_English_0_374_2019_2021" /* Rwanda */
replace lb_q17b_norm =0.6666667 if id_alex=="lb_English_0_222_2018_2019_2021" /* Rwanda */
replace cc_q40b_norm =. if id_alex=="cc_French_1_984_2019_2021" /* Rwanda */
drop if id_alex=="cj_French_0_174" //Senegal
replace lb_q2d_norm=. if id_alex=="lb_French_1_658" //Senegal
replace lb_q2d_norm=. if id_alex=="lb_French_0_257" //Senegal
replace lb_q2d_norm=. if id_alex=="lb_French_0_300" //Senegal
replace cj_q28_norm=. if country=="Senegal" //Senegal
replace cj_q20m_norm=. if id_alex=="cj_English_0_77" //Senegal
drop if id_alex=="cc_French_0_160" //Senegal
drop if id_alex=="cc_French_0_232_2018_2019_2021" //Senegal
replace all_q2_norm=. if id_alex=="cc_French_0_669_2016_2017_2018_2019_2021" //Senegal
replace all_q2_norm=. if id_alex=="cj_French_0_27_2013_2014_2016_2017_2018_2019_2021" //Senegal
replace all_q2_norm=. if id_alex=="lb_English_1_363_2017_2018_2019_2021" //Senegal
replace all_q2_norm=. if id_alex=="cj_French_1_686_2016_2017_2018_2019_2021" //Senegal
replace all_q20_norm=. if id_alex=="cc_French_1_1352" //Senegal
replace all_q21_norm=. if id_alex=="cc_French_0_1553" //Senegal
replace all_q21_norm=. if id_alex=="cj_French_1_686_2016_2017_2018_2019_2021" //Senegal
replace all_q22_norm=. if id_alex=="lb_French_1_337_2021" //Senegal
replace all_q23_norm=. if id_alex=="lb_French_1_337_2021" //Senegal
replace all_q24_norm=. if id_alex=="lb_French_1_337_2021" //Senegal
replace all_q25_norm=. if id_alex=="lb_French_1_337_2021" //Senegal
replace all_q26_norm=. if id_alex=="lb_French_1_337_2021" //Senegal
replace all_q27_norm=. if id_alex=="lb_French_1_337_2021" //Senegal
replace all_q8_norm=. if id_alex=="lb_French_1_337_2021" //Senegal
replace all_q22_norm=. if id_alex=="lb_English_1_363_2017_2018_2019_2021" //Senegal
replace all_q23_norm=. if id_alex=="lb_English_1_363_2017_2018_2019_2021" //Senegal
replace all_q24_norm=. if id_alex=="lb_English_1_363_2017_2018_2019_2021" //Senegal
replace all_q25_norm=. if id_alex=="lb_English_1_363_2017_2018_2019_2021" //Senegal
replace all_q26_norm=. if id_alex=="lb_English_1_363_2017_2018_2019_2021" //Senegal
replace all_q27_norm=. if id_alex=="lb_English_1_363_2017_2018_2019_2021" //Senegal
replace all_q8_norm=. if id_alex=="lb_English_1_363_2017_2018_2019_2021" //Senegal
replace all_q22_norm=. if id_alex=="cc_French_0_206_2017_2018_2019_2021" //Senegal
replace all_q23_norm=. if id_alex=="cc_French_0_206_2017_2018_2019_2021" //Senegal
replace all_q24_norm=. if id_alex=="cc_French_0_206_2017_2018_2019_2021" //Senegal
replace all_q25_norm=. if id_alex=="cc_French_0_206_2017_2018_2019_2021" //Senegal
replace all_q26_norm=. if id_alex=="cc_French_0_206_2017_2018_2019_2021" //Senegal
replace all_q27_norm=. if id_alex=="cc_French_0_206_2017_2018_2019_2021" //Senegal
replace all_q8_norm=. if id_alex=="cc_French_0_206_2017_2018_2019_2021" //Senegal
replace all_q19_norm=. if id_alex=="cj_French_1_686_2016_2017_2018_2019_2021" //Senegal
replace all_q31_norm=. if id_alex=="cj_French_1_686_2016_2017_2018_2019_2021" //Senegal
replace all_q32_norm=. if id_alex=="cj_French_1_686_2016_2017_2018_2019_2021" //Senegal
replace all_q14_norm=. if id_alex=="cj_French_1_686_2016_2017_2018_2019_2021" //Senegal
replace all_q29_norm=. if id_alex=="cj_French_1_686_2016_2017_2018_2019_2021" //Senegal
replace all_q30_norm=. if id_alex=="cj_French_1_686_2016_2017_2018_2019_2021" //Senegal
replace all_q29_norm=. if id_alex=="cj_English_0_1027_2017_2018_2019_2021" //Senegal
replace all_q30_norm=. if id_alex=="cj_English_0_1027_2017_2018_2019_2021" //Senegal
replace all_q29_norm=. if id_alex=="cj_French_1_171" //Senegal
replace all_q30_norm=. if id_alex=="cj_French_1_171" //Senegal
replace all_q29_norm=. if id_alex=="cj_English_0_77" //Senegal
replace all_q30_norm=. if id_alex=="cj_English_0_77" //Senegal
replace all_q13_norm=. if id_alex=="cj_French_1_686_2016_2017_2018_2019_2021" //Senegal
replace all_q15_norm=. if id_alex=="cj_French_1_686_2016_2017_2018_2019_2021" //Senegal
replace all_q16_norm=. if id_alex=="cj_French_1_686_2016_2017_2018_2019_2021" //Senegal
replace all_q17_norm=. if id_alex=="cj_French_1_686_2016_2017_2018_2019_2021" //Senegal
replace all_q18_norm=. if id_alex=="cj_French_1_686_2016_2017_2018_2019_2021" //Senegal
replace all_q15_norm=. if id_alex=="cc_English_1_1283_2021" //Senegal
replace all_q16_norm=. if id_alex=="cc_English_1_1283_2021" //Senegal
replace all_q18_norm=. if id_alex=="cc_English_1_1283_2021" //Senegal
replace all_q19_norm=. if id_alex=="cc_English_1_1283_2021" //Senegal
replace all_q94_norm=. if id_alex=="lb_French_1_337_2021" //Senegal
replace all_q94_norm=. if id_alex=="cc_French_0_1674_2019_2021" //Senegal
replace all_q13_norm=. if id_alex=="cj_French_0_32_2013_2014_2016_2017_2018_2019_2021" //Senegal
drop if id_alex=="cj_French_1_171" //Senegal
replace cj_q31f_norm=. if id_alex=="cj_English_0_77" //Senegal
replace cj_q10_norm=. if id_alex=="cj_French_1_686_2016_2017_2018_2019_2021" //Senegal
replace cj_q15_norm=. if id_alex=="cj_French_1_686_2016_2017_2018_2019_2021" //Senegal
replace cj_q21a_norm=. if id_alex=="cj_French_0_1083_2021" //Senegal
replace cj_q21e_norm=. if id_alex=="cj_French_0_1083_2021" //Senegal
replace cj_q21g_norm=. if id_alex=="cj_French_0_1083_2021" //Senegal
drop if id_alex=="cj_English_1_1146" //Serbia
drop if id_alex=="ph_English_1_70" //Serbia
replace cj_q15_norm=. if country=="Serbia" /*Serbia*/
replace all_q89_norm=. if id_alex=="cc_English_1_1016_2016_2017_2018_2019_2021" //Serbia
replace all_q89_norm=. if id_alex=="cc_English_1_899" //Serbia
replace all_q89_norm=. if id_alex=="cc_English_0_281" //Serbia
replace all_q9_norm=. if id_alex=="cc_English_0_140_2021" //Serbia
replace all_q9_norm=. if id_alex=="cc_English_1_1371_2021" //Serbia
replace cc_q9c_norm=. if id_alex=="cc_English_1_710_2017_2018_2019_2021" //Serbia
replace cc_q40a_norm=. if id_alex=="cc_English_1_710_2017_2018_2019_2021" //Serbia
replace cc_q40b_norm=. if id_alex=="cc_English_1_710_2017_2018_2019_2021" //Serbia
replace cc_q39b_norm=. if id_alex=="cc_English_0_1277" //Serbia
replace cj_q36c_norm=. if id_alex=="cj_English_0_403" //Serbia
replace cj_q40b_norm=. if id_alex=="cj_English_1_932_2018_2019_2021" //Serbia
replace cj_q40c_norm=. if id_alex=="cj_English_1_932_2018_2019_2021" //Serbia
replace cj_q20m_norm=. if id_alex=="cj_English_1_932_2018_2019_2021" //Serbia
replace all_q9_norm=. if id_alex=="cj_English_1_932_2018_2019_2021" //Serbia
replace all_q9_norm=. if id_alex=="cj_English_0_148_2018_2019_2021" //Serbia
replace all_q9_norm=. if id_alex=="lb_English_0_791_2018_2019_2021" //Serbia
replace cj_q36c_norm=. if id_alex=="cj_English_1_932_2018_2019_2021" //Serbia
replace cj_q21h_norm=. if country=="Sierra Leone" /*Sierra Leone*/
replace cj_q31g_norm=. if id_alex=="cj_English_0_267" //Sierra Leone
replace cc_q40a_norm=. if id_alex=="cc_English_0_1678_2019_2021" //Sierra Leone
replace cc_q40a_norm=. if id_alex=="cc_English_0_1493_2016_2017_2018_2019_2021" //Sierra Leone
drop if id_alex=="cc_English_1_1372" //Singapore
drop if id_alex=="ph_English_1_194_2016_2017_2018_2019_2021" //Singapore
drop if id_alex=="ph_English_0_60" //Singapore
replace cj_q36c_norm=. if id_alex=="cj_English_0_184" //Singapore
replace cj_q36c_norm=. if id_alex=="cj_English_0_698" //Singapore
replace all_q17_norm=. if country=="Singapore" //Singapore
replace cj_q10_norm=. if country=="Singapore" //Singapore
replace all_q6_norm=. if country=="Singapore" //Singapore
replace all_q31_norm=. if id_alex=="cc_English_0_1548" //Singapore
replace all_q32_norm=. if id_alex=="cc_English_0_1548" //Singapore
replace all_q14_norm=. if id_alex=="cc_English_0_1548" //Singapore
replace all_q19_norm=. if id_alex=="cj_English_1_335" //Singapore
replace all_q1_norm=0 if id_alex=="cc_English_1_990_2019_2021" //Singapore
replace all_q1_norm=0 if id_alex=="cc_English_0_976_2021" //Singapore
replace all_q1_norm=0 if id_alex=="lb_English_1_119_2016_2017_2018_2019_2021" //Singapore
drop if id_alex=="cj_English_0_435" //Slovak Republic
replace cj_q32d_norm=. if country=="Slovak Republic" //Slovak Republic
replace cj_q34a_norm=. if country=="Slovak Republic" //Slovak Republic
replace cj_q34e_norm=. if country=="Slovak Republic" //Slovak Republic
replace cj_q34b_norm=. if id_alex=="cj_English_0_885" //Slovak Republic
replace all_q78_norm=. if country=="Slovak Republic" //Slovak Republic
replace all_q80_norm=. if country=="Slovak Republic" //Slovak Republic
replace all_q51_norm=. if id_alex=="cc_English_0_504" //Slovak Republic
replace all_q51_norm=. if id_alex=="lb_English_0_387" //Slovak Republic
replace all_q59_norm=. if id_alex=="cc_English_0_504" //Slovak Republic
replace lb_q6c_norm=. if id_alex=="lb_English_0_387" //Slovak Republic
replace all_q28_norm=. if id_alex=="cc_English_0_504" //Slovak Republic
replace cc_q26b_norm=. if id_alex=="cc_English_0_643" //Slovak Republic
replace all_q86_norm=. if id_alex=="cc_English_0_1595_2021" //Slovak Republic
replace all_q86_norm=. if id_alex=="cc_English_0_504" //Slovak Republic
replace cj_q7c_norm=. if country=="Slovak Republic" //Slovak Republic
replace cj_q12a_norm=. if id_alex=="cj_English_0_19" //Slovak Republic
replace cj_q12b_norm=. if country=="Slovak Republic"  //Slovak Republic
replace cj_q20m_norm=. if id_alex=="cj_English_0_48" //Slovak Republic
replace cj_q40b_norm=. if id_alex=="cj_English_0_587_2021" //Slovak Republic
replace all_q96_norm=0 if id_alex=="cc_English_0_70" //Slovak Republic
replace all_q96_norm=0 if id_alex=="cc_English_0_1011" //Slovak Republic
replace all_q96_norm=0 if id_alex=="lb_English_0_346" //Slovak Republic
replace cj_q15_norm=. if id_alex=="cj_English_0_745_2021" //Slovak Republic
drop if id_alex=="cj_English_1_391" /* Slovenia */
drop if id_alex=="cc_English_0_1191" /* Slovenia */
drop if id_alex=="cj_English_1_81" /* Slovenia */
replace lb_q2d_norm=. if country=="Slovenia" /* Slovenia */
replace cc_q39b_norm=. if id_alex=="cc_English_1_1205" /* Slovenia */
replace cc_q39b_norm=. if id_alex=="cc_English_0_363" /* Slovenia */
replace cc_q39b_norm=. if id_alex=="cc_English_1_932" /* Slovenia */
replace cc_q40a_norm=. if country=="Slovenia" /* Slovenia */
replace all_q29_norm=. if id_alex=="cc_English_0_363" /* Slovenia */
replace all_q30_norm=. if id_alex=="cc_English_0_363" /* Slovenia */
replace all_q29_norm=. if id_alex=="cc_English_0_60" /* Slovenia */
replace all_q30_norm=. if id_alex=="cc_English_0_60" /* Slovenia */
replace all_q29_norm=. if id_alex=="cc_English_0_225" /* Slovenia */
replace all_q30_norm=. if id_alex=="cc_English_0_225" /* Slovenia */
replace cj_q42c_norm=. if id_alex=="cj_English_1_911_2018_2019_2021" /* Slovenia */
replace cj_q42d_norm=. if id_alex=="cj_English_1_911_2018_2019_2021" /* Slovenia */
replace cj_q31f_norm=. if id_alex=="cj_English_0_524_2018_2019_2021" /* Slovenia */
replace cj_q31g_norm=. if id_alex=="cj_English_0_524_2018_2019_2021" /* Slovenia */
replace cc_q14a_norm=. if id_alex=="cc_English_1_93_2021" /* Slovenia */
replace cc_q14b_norm=. if id_alex=="cc_English_1_93_2021" /* Slovenia */
replace cc_q16b_norm=. if id_alex=="cc_English_1_93_2021" /* Slovenia */
replace cc_q16c_norm=. if id_alex=="cc_English_1_93_2021" /* Slovenia */
replace all_q15_norm=. if id_alex=="cc_English_1_960" /* Slovenia */
replace all_q16_norm=. if id_alex=="cc_English_1_960" /* Slovenia */
replace all_q18_norm=. if id_alex=="cc_English_1_960" /* Slovenia */
replace all_q19_norm=. if id_alex=="cc_English_1_960" /* Slovenia */
replace all_q94_norm=. if id_alex=="cc_English_1_1205" /* Slovenia */
replace all_q14_norm=. if id_alex=="cc_English_1_960" /* Slovenia */
replace all_q14_norm=. if id_alex=="cj_English_1_304" /* Slovenia */
replace all_q15_norm=. if id_alex=="cj_English_1_304" /* Slovenia */
replace all_q16_norm=. if id_alex=="cj_English_1_304" /* Slovenia */
replace all_q17_norm=. if id_alex=="cj_English_1_304" /* Slovenia */
replace all_q18_norm=. if id_alex=="cj_English_1_304" /* Slovenia */
replace all_q19_norm=. if id_alex=="cj_English_1_304" /* Slovenia */
replace all_q19_norm=. if id_alex=="cc_English_1_932" /* Slovenia */
replace all_q20_norm=. if id_alex=="cc_English_1_932" /* Slovenia */
replace all_q21_norm=. if id_alex=="cc_English_1_932" /* Slovenia */
replace all_q15_norm=. if id_alex=="cj_English_0_905" /* Slovenia */
replace all_q16_norm=. if id_alex=="cj_English_0_905" /* Slovenia */
replace all_q17_norm=. if id_alex=="cj_English_0_905" /* Slovenia */
replace all_q18_norm=. if id_alex=="cj_English_0_905" /* Slovenia */
replace all_q15_norm=. if id_alex=="cc_English_0_225" /* Slovenia */
replace all_q16_norm=. if id_alex=="cc_English_0_225" /* Slovenia */
replace all_q18_norm=. if id_alex=="cc_English_0_225" /* Slovenia */
replace all_q13_norm=. if id_alex=="cj_English_1_566_2014_2016_2017_2018_2019_2021" /* Slovenia */
replace all_q14_norm=. if id_alex=="cj_English_1_566_2014_2016_2017_2018_2019_2021" /* Slovenia */
replace all_q31_norm=. if id_alex=="cj_English_0_905" /* Slovenia */
replace all_q32_norm=. if id_alex=="cj_English_0_905" /* Slovenia */
replace all_q14_norm=. if id_alex=="cj_English_0_905" /* Slovenia */
replace all_q31_norm=. if id_alex=="cj_English_1_304" /* Slovenia */
replace all_q32_norm=. if id_alex=="cj_English_1_304" /* Slovenia */
replace all_q31_norm=. if id_alex=="cc_English_1_93_2021" /* Slovenia */
replace all_q32_norm=. if id_alex=="cc_English_1_93_2021" /* Slovenia */
replace all_q31_norm=. if id_alex=="cc_English_0_225" /* Slovenia */
replace all_q32_norm=. if id_alex=="cc_English_0_225" /* Slovenia */
replace all_q31_norm=. if id_alex=="cc_English_0_363" /* Slovenia */
replace all_q32_norm=. if id_alex=="cc_English_0_363" /* Slovenia */
replace all_q14_norm=. if id_alex=="cc_English_0_363" /* Slovenia */
replace all_q6_norm=. if id_alex=="cc_English_1_33" /* Slovenia */
replace cc_q11a_norm=. if id_alex=="cc_English_1_33" /* Slovenia */
replace all_q3_norm=. if id_alex=="cc_English_1_33" /* Slovenia */
replace all_q4_norm=. if id_alex=="cc_English_1_33" /* Slovenia */
replace all_q7_norm=. if id_alex=="cc_English_1_33" /* Slovenia */
replace all_q6_norm=. if id_alex=="lb_English_1_77" /* Slovenia */
replace all_q3_norm=. if id_alex=="lb_English_1_77" /* Slovenia */
replace all_q4_norm=. if id_alex=="lb_English_1_77" /* Slovenia */
replace all_q7_norm=. if id_alex=="lb_English_1_77" /* Slovenia */
replace cj_q40b_norm=. if id_alex=="cj_English_1_795" /* Slovenia */
replace cj_q40c_norm=. if id_alex=="cj_English_1_795" /* Slovenia */
replace cc_q14a_norm=. if id_alex=="cc_English_0_1594_2017_2018_2019_2021" /* Slovenia */
replace cc_q14b_norm=. if id_alex=="cc_English_0_1594_2017_2018_2019_2021" /* Slovenia */
replace cc_q16b_norm=. if id_alex=="cc_English_0_1594_2017_2018_2019_2021" /* Slovenia */
replace cc_q16c_norm=. if id_alex=="cc_English_0_1594_2017_2018_2019_2021" /* Slovenia */
replace cc_q16d_norm=. if id_alex=="cc_English_0_1594_2017_2018_2019_2021" /* Slovenia */
replace cc_q16e_norm=. if id_alex=="cc_English_0_1594_2017_2018_2019_2021" /* Slovenia */
replace cc_q16f_norm=. if id_alex=="cc_English_0_1594_2017_2018_2019_2021" /* Slovenia */
replace cc_q16g_norm=. if id_alex=="cc_English_0_1594_2017_2018_2019_2021" /* Slovenia */
replace cc_q14a_norm=. if id_alex=="cc_English_1_1205" /* Slovenia */
replace cc_q14b_norm=. if id_alex=="cc_English_1_1205" /* Slovenia */
replace cc_q16b_norm=. if id_alex=="cc_English_1_1205" /* Slovenia */
replace cc_q16c_norm=. if id_alex=="cc_English_1_1205" /* Slovenia */
replace cc_q16d_norm=. if id_alex=="cc_English_1_1205" /* Slovenia */
replace cc_q16e_norm=. if id_alex=="cc_English_1_1205" /* Slovenia */
replace cc_q16f_norm=. if id_alex=="cc_English_1_1205" /* Slovenia */
replace cc_q16g_norm=. if id_alex=="cc_English_1_1205" /* Slovenia */
drop if id_alex=="cc_English_1_1103_2019_2021" //South Africa
drop if id_alex=="ph_English_0_220_2016_2017_2018_2019_2021" //South Africa
drop if id_alex=="ph_English_0_662_2018_2019_2021" //South Africa
replace cc_q9c_norm=. if id_alex=="cc_English_0_2004_2018_2019_2021" // South Africa
replace cc_q40a_norm=. if id_alex=="cc_English_0_2004_2018_2019_2021" // South Africa
replace cc_q40b_norm=. if id_alex=="cc_English_0_2004_2018_2019_2021" // South Africa
replace cc_q9c_norm=. if id_alex=="cc_English_1_328_2021" // South Africa
replace cc_q40a_norm=. if id_alex=="cc_English_1_328_2021" // South Africa
replace cc_q40b_norm=. if id_alex=="cc_English_1_328_2021" // South Africa
replace cj_q31f_norm=. if id_alex=="cj_English_1_709" // South Africa
replace cj_q31g_norm=. if id_alex=="cj_English_1_709" // South Africa
replace cj_q31f_norm=. if id_alex=="cj_English_1_623_2016_2017_2018_2019_2021" // South Africa
replace cj_q31g_norm=. if id_alex=="cj_English_1_623_2016_2017_2018_2019_2021" // South Africa
drop if id_alex=="cc_Spanish_0_688_2016_2017_2018_2019_2021" //Spain
drop if id_alex=="cj_Spanish_1_403_2017_2018_2019_2021" //Spain
drop if id_alex=="ph_Spanish_1_108_2017_2018_2019_2021" //Spain
drop if id_alex=="cj_Spanish_0_667_2021" //Spain 
replace cj_q15_norm=. if id_alex=="cj_Spanish_0_297_2021" // Spain
replace cj_q15_norm=. if id_alex=="cj_Spanish_1_332_2018_2019_2021" // Spain
drop if id_alex=="cc_English_0_173" //Sri Lanka
drop if id_alex=="ph_English_0_246_2021" //Sri Lanka
drop if id_alex=="cc_English_0_1486_2021" //Sri Lanka
drop if id_alex=="lb_English_1_700_2019_2021" //Sri Lanka
replace all_q87_norm=. if country=="Sri Lanka" /* Sri Lanka */
replace cc_q33_norm=. if country=="Sri Lanka" /* Sri Lanka */
replace cj_q11b_norm=. if country=="Sri Lanka" /* Sri Lanka */
replace all_q29_norm=. if id_alex=="cc_English_1_702_2021" /* Sri Lanka */
replace all_q29_norm=. if id_alex=="cc_English_0_1358" /* Sri Lanka */
replace all_q29_norm=. if id_alex=="cj_English_0_245_2021" /* Sri Lanka */
replace all_q30_norm=. if id_alex=="cc_English_0_289_2021" /* Sri Lanka */
replace all_q30_norm=. if id_alex=="cc_English_1_1249" /* Sri Lanka */
replace all_q30_norm=. if id_alex=="cj_English_1_1139" /* Sri Lanka */
replace cj_q31f_norm=. if id_alex=="cj_English_0_758" /* Sri Lanka */
replace cj_q31f_norm=. if id_alex=="cj_English_1_626" /* Sri Lanka */
replace cj_q42c_norm=. if id_alex=="cj_English_0_758" /* Sri Lanka */
replace cj_q42c_norm=. if id_alex=="cj_English_1_626" /* Sri Lanka */
replace cj_q42d_norm=. if id_alex=="cj_English_0_758" /* Sri Lanka */
replace cc_q39b_norm=. if id_alex=="cc_English_1_587_2019_2021" /* Sri Lanka */
replace cc_q39b_norm=. if id_alex=="cc_English_1_1006" /* Sri Lanka */
replace cc_q9c_norm=. if id_alex=="cc_English_0_1017_2019_2021" /* Sri Lanka */
replace cc_q40a_norm=. if id_alex=="cc_English_0_1017_2019_2021" /* Sri Lanka */
replace cc_q40b_norm=. if id_alex=="cc_English_0_1017_2019_2021" /* Sri Lanka */
replace cc_q9c_norm=. if id_alex=="cc_English_0_1088" /* Sri Lanka */
replace cc_q40a_norm=. if id_alex=="cc_English_0_1088" /* Sri Lanka */
replace cc_q40b_norm=. if id_alex=="cc_English_0_1088" /* Sri Lanka */
replace lb_q23a_norm=. if id_alex=="lb_English_0_322" /* Sri Lanka */
replace lb_q23b_norm=. if id_alex=="lb_English_0_322" /* Sri Lanka */
replace lb_q23c_norm=. if id_alex=="lb_English_0_322" /* Sri Lanka */
replace lb_q23d_norm=. if id_alex=="lb_English_0_322" /* Sri Lanka */
replace lb_q23e_norm=. if id_alex=="lb_English_0_322" /* Sri Lanka */
replace lb_q23f_norm=. if id_alex=="lb_English_0_322" /* Sri Lanka */
replace lb_q23g_norm=. if id_alex=="lb_English_0_322" /* Sri Lanka */
replace lb_q23f_norm=. if id_alex=="lb_English_0_416_2019_2021" /* Sri Lanka */
replace lb_q23g_norm=. if id_alex=="lb_English_0_416_2019_2021" /* Sri Lanka */
replace cj_q8_norm=. if id_alex=="cj_English_1_1002" /* Sri Lanka */
replace cj_q38_norm=. if id_alex=="cj_English_1_1002" /* Sri Lanka */
replace all_q19_norm=. if id_alex=="cc_English_1_587_2019_2021" /* Sri Lanka */
replace all_q31_norm=. if id_alex=="cc_English_1_587_2019_2021" /* Sri Lanka */
replace all_q32_norm=. if id_alex=="cc_English_1_587_2019_2021" /* Sri Lanka */
replace all_q14_norm=. if id_alex=="cc_English_1_587_2019_2021" /* Sri Lanka */
replace all_q19_norm=. if id_alex=="cc_English_0_1088" /* Sri Lanka */
replace all_q31_norm=. if id_alex=="cc_English_0_1088" /* Sri Lanka */
replace all_q32_norm=. if id_alex=="cc_English_0_1088" /* Sri Lanka */
replace all_q14_norm=. if id_alex=="cc_English_0_1088" /* Sri Lanka */
drop if id_alex=="lb_English_1_208" //Sudan
replace cc_q12_norm=. if country=="Sudan" /* Sudan */
replace all_q71_norm=. if country=="Sudan" /* Sudan */
replace all_q72_norm=. if country=="Sudan" /* Sudan */
replace all_q93_norm=. if country=="Sudan" /* Sudan */
replace cj_q27b_norm=. if country=="Sudan" /* Sudan */
replace cj_q7c_norm=. if country=="Sudan" /* Sudan */
replace all_q6_norm=. if country=="Sudan" /* Sudan */
replace cc_q14b_norm=. if country=="Sudan" /* Sudan */
replace cc_q16g_norm=. if country=="Sudan" /* Sudan */
replace all_q89_norm=. if country=="Sudan" /* Sudan */
replace all_q22_norm=. if country=="Sudan" /* Sudan */
replace all_q23_norm=. if country=="Sudan" /* Sudan */
replace cj_q42c_norm=. if country=="Sudan" /* Sudan */
replace cj_q42d_norm=. if country=="Sudan" /* Sudan */
replace all_q30_norm=. if id_alex=="cj_English_0_117" //Sudan
replace lb_q23f_norm=. if id_alex=="lb_English_0_61" //Sudan
replace lb_q23g_norm=. if id_alex=="lb_English_0_61" //Sudan
replace lb_q19a_norm=. if id_alex=="lb_English_0_61" //Sudan
replace all_q48_norm=. if id_alex=="lb_English_0_61" //Sudan	
replace all_q49_norm=. if id_alex=="lb_English_0_61" //Sudan	 
replace all_q50_norm=. if id_alex=="lb_English_0_61" //Sudan
replace cj_q21a_norm=. if country=="Sudan" //Sudan
replace cj_q20o_norm=. if country=="Sudan" //Sudan
replace all_q96_norm=. if id_alex=="cj_English_0_971_2021" //Sudan
replace all_q96_norm=. if id_alex=="cj_Arabic_0_309" //Sudan
replace all_q29_norm=. if id_alex=="cj_English_0_117" //Sudan
replace all_q29_norm=. if id_alex=="cj_Arabic_0_309" //Sudan
replace all_q30_norm=. if id_alex=="cj_Arabic_0_309" //Sudan
replace all_q2_norm=0 if id_alex=="cc_English_1_1207" //Sudan
replace all_q2_norm=0 if id_alex=="cj_English_0_145" //Sudan
replace cc_q25_norm=0 if id_alex=="cc_English_0_383" //Sudan
replace cc_q33_norm=0 if id_alex=="cc_English_0_383" //Sudan
replace cj_q34a_norm=. if id_alex=="cj_English_1_151" //Sudan
replace cj_q34b_norm=. if id_alex=="cj_English_1_151" //Sudan
replace cj_q34c_norm=. if id_alex=="cj_English_1_151" //Sudan
replace cj_q34d_norm=. if id_alex=="cj_English_1_151" //Sudan
replace all_q96_norm=. if id_alex=="lb_English_0_61" //Sudan
replace all_q96_norm=. if id_alex=="cc_English_1_451" //Sudan
replace all_q29_norm=. if id_alex=="cc_English_1_1207" //Sudan
replace cj_q15_norm=. if id_alex=="cj_English_0_117" //Sudan
replace cc_q26h_norm=0.5555556 if id_alex=="cc_English_1_451" //Sudan
replace cj_q31g_norm=. if id_alex=="cj_English_0_145" //Sudan
replace all_q50_norm=. if id_alex=="cc_English_0_383" //Sudan
replace lb_q3d_norm=. if id_alex=="lb_Arabic_0_451_2021" //Sudan
replace all_q62_norm=. if id_alex=="cc_English_0_383" //Sudan
replace all_q63_norm=. if id_alex=="cc_English_0_383" //Sudan
replace all_q62_norm=. if id_alex=="cc_English_1_1207" //Sudan
replace all_q63_norm=. if id_alex=="cc_English_1_1207" //Sudan
replace cj_q12a_norm=. if id_alex=="cj_English_0_971_2021" //Sudan
replace cj_q12b_norm=. if id_alex=="cj_English_0_971_2021" //Sudan
replace cj_q12c_norm=. if id_alex=="cj_English_0_971_2021" //Sudan
replace cj_q12d_norm=. if id_alex=="cj_English_0_971_2021" //Sudan
replace cj_q12e_norm=. if id_alex=="cj_English_0_971_2021" //Sudan
replace cj_q12f_norm=. if id_alex=="cj_English_0_971_2021" //Sudan
replace cj_q12a_norm=. if id_alex=="cj_English_0_339" //Sudan
replace cj_q12b_norm=. if id_alex=="cj_English_0_339" //Sudan
replace cj_q12c_norm=. if id_alex=="cj_English_0_339" //Sudan
replace cj_q12d_norm=. if id_alex=="cj_English_0_339" //Sudan
replace cj_q12e_norm=. if id_alex=="cj_English_0_339" //Sudan
replace cj_q12f_norm=. if id_alex=="cj_English_0_339" //Sudan
replace cc_q10_norm=. if id_alex=="cc_English_1_1207" //Sudan
replace cc_q11a_norm=. if id_alex=="cc_English_1_1207" //Sudan
replace cc_q16a_norm=. if id_alex=="cc_English_1_1207" //Sudan
replace cc_q16b_norm=. if id_alex=="cc_English_0_383" //Sudan
replace cc_q16c_norm=. if id_alex=="cc_English_0_383" //Sudan
replace cc_q16d_norm=. if id_alex=="cc_English_0_383" //Sudan
replace cc_q16e_norm=. if id_alex=="cc_English_0_383" //Sudan
replace cc_q16e_norm=. if id_alex=="cc_English_0_383" //Sudan
replace cc_q28e_norm=. if id_alex=="cc_English_1_1207" //Sudan
drop if id_alex=="cj_English_0_1021" //Suriname
replace cj_q31f_norm=. if country=="Suriname" /* Suriname */
replace all_q1_norm=. if id_alex=="cc_English_0_731" //Suriname
replace all_q2_norm=. if id_alex=="cc_English_1_853" //Suriname
replace all_q2_norm=. if id_alex=="cc_English_0_944" //Suriname
replace all_q2_norm=. if id_alex=="cj_English_0_814_2018_2019_2021" //Suriname
replace all_q21_norm=. if id_alex=="cc_English_1_195" //Suriname
replace all_q21_norm=. if id_alex=="cc_English_1_276" //Suriname
replace all_q84_norm=. if id_alex=="lb_English_0_157_2016_2017_2018_2019_2021" //Suriname
replace all_q85_norm=. if id_alex=="lb_English_0_157_2016_2017_2018_2019_2021" //Suriname
replace all_q84_norm=. if id_alex=="lb_English_0_575" //Suriname
replace all_q85_norm=. if id_alex=="lb_English_0_575" //Suriname
replace cc_q13_norm=. if id_alex=="cc_English_0_731" //Suriname
replace all_q85_norm=0 if id_alex=="cc_English_0_284_2016_2017_2018_2019_2021" //Suriname
replace cc_q13_norm=0 if id_alex=="cc_English_0_284_2016_2017_2018_2019_2021" //Suriname
drop if id_alex=="cc_English_0_334" //Tanzania
replace cc_q9c_norm=. if id_alex=="cc_English_0_794_2019_2021" //Tanzania
replace cc_q40a_norm=. if id_alex=="cc_English_0_794_2019_2021" //Tanzania
replace cc_q40b_norm=. if id_alex=="cc_English_0_794_2019_2021" //Tanzania
replace cc_q11a_norm=. if id_alex=="cc_English_0_1231_2016_2017_2018_2019_2021" //Tanzania
replace all_q3_norm=. if id_alex=="cc_English_0_1231_2016_2017_2018_2019_2021" //Tanzania
replace all_q4_norm=. if id_alex=="cc_English_0_1231_2016_2017_2018_2019_2021" //Tanzania
replace all_q7_norm=. if id_alex=="cc_English_0_1231_2016_2017_2018_2019_2021" //Tanzania
replace all_q3_norm=. if id_alex=="cj_English_0_469_2013_2014_2016_2017_2018_2019_2021" //Tanzania
replace all_q4_norm=. if id_alex=="cj_English_0_469_2013_2014_2016_2017_2018_2019_2021" //Tanzania
replace all_q7_norm=. if id_alex=="cj_English_0_469_2013_2014_2016_2017_2018_2019_2021" //Tanzania
drop if id_alex=="cc_English_1_951" //Thailand
drop if id_alex=="cc_English_1_1062" //Thailand
drop if id_alex=="cc_English_1_922" //Thailand
drop if id_alex=="cc_English_1_409" //Thailand
drop if id_alex=="ph_English_0_308_2018_2019_2021" //Thailand
drop if id_alex=="ph_English_0_559_2019_2021" //Thailand
drop if id_alex=="ph_English_1_704_2021" //Thailand
drop if id_alex=="ph_English_0_126" //Thailand
replace all_q59_norm=. if country=="Thailand" //Thailand
replace all_q89_norm=. if country=="Thailand" //Thailand
replace all_q90_norm=. if country=="Thailand" //Thailand
replace cj_q21a_norm=. if country=="Thailand" //Thailand
replace cj_q21h_norm=. if country=="Thailand" //Thailand
replace all_q85_norm=. if country=="Thailand" //Thailand
replace all_q29_norm=. if country=="Thailand" //Thailand
replace cc_q33_norm=. if id_alex=="cc_English_0_842_2018_2019_2021" //Thailand
replace all_q9_norm=. if id_alex=="lb_English_0_459_2021" //Thailand
replace cj_q15_norm=. if id_alex=="cj_English_0_914" //Thailand
replace cc_q26b_norm=. if id_alex=="cc_English_0_842_2018_2019_2021" //Thailand
replace all_q91_norm=. if id_alex=="lb_English_0_380" //Thailand
drop if id_alex=="cc_French_1_710" //Togo
drop if id_alex=="cc_French_0_128" //Togo
drop if id_alex=="cj_French_0_856" //Togo
drop if id_alex=="lb_French_0_308" //Togo
drop if id_alex=="ph_French_0_101_2021" //Togo
drop if id_alex=="ph_French_1_184" //Togo
drop if id_alex=="ph_French_0_145" //Togo
replace cj_q15_norm=. if id_alex=="cj_French_0_168" //Togo
replace cj_q15_norm=. if id_alex=="cj_French_0_856" //Togo
replace cj_q15_norm=. if id_alex=="cj_French_1_431" //Togo
replace all_q84_norm=. if id_alex=="cc_French_0_831" //Togo
replace all_q85_norm=. if id_alex=="cc_French_0_831" //Togo
replace all_q84_norm=. if id_alex=="cc_French_0_1723" //Togo
replace all_q85_norm=. if id_alex=="cc_French_0_1723" //Togo
replace all_q84_norm=. if id_alex=="lb_French_0_485_2019_2021" //Togo
replace all_q85_norm=. if id_alex=="lb_French_0_485_2019_2021" //Togo
replace all_q84_norm=. if id_alex=="cc_English_0_1297_2018_2019_2021" //Togo
replace all_q85_norm=. if id_alex=="cc_English_0_1297_2018_2019_2021" //Togo
replace all_q84_norm=. if id_alex=="cc_English_0_638" //Togo
replace all_q85_norm=. if id_alex=="cc_English_0_638" //Togo
replace cc_q26a_norm=. if id_alex=="cc_French_0_1367" //Togo
replace cc_q33_norm=. if id_alex=="cc_French_0_831" //Togo
replace cj_q38_norm=. if id_alex=="cj_French_0_455_2021" //Togo
replace all_q22_norm=. if country=="Togo" //Togo
replace all_q24_norm=. if country=="Togo" //Togo
replace cj_q8_norm=. if id_alex=="cj_French_1_431" //Togo
replace cj_q8_norm=. if id_alex=="cj_French_1_596" //Togo
replace all_q2_norm=. if country=="Togo" //Togo
replace all_q5_norm=. if id_alex=="cc_French_0_1306" //Togo
replace all_q33_norm=. if country=="Togo" //Togo
replace all_q47_norm=. if country=="Togo" //Togo
replace cj_q20o_norm=. if id_alex=="cj_French_0_875_2018_2019_2021" //Togo
replace cj_q20o_norm=. if id_alex=="cj_French_0_1105_2019_2021" //Togo
replace cj_q20o_norm=. if id_alex=="cj_French_1_152_2021" //Togo
replace cj_q20o_norm=. if id_alex=="cj_French_0_168" //Togo
replace cj_q20o_norm=. if country=="Togo" //Togo
replace lb_q23a_norm=. if id_alex=="lb_French_0_503_2018_2019_2021" //Togo
replace lb_q23c_norm=. if id_alex=="lb_French_1_531" //Togo
drop if id_alex=="lb_English_0_216_2016_2017_2018_2019_2021" //Trinidad and Tobago
drop if id_alex=="cj_English_0_938" //Trinidad and Tobago
drop if id_alex=="cj_English_0_255" //Trinidad and Tobago
drop if id_alex=="cj_English_0_608_2016_2017_2018_2019_2021" //Trinidad and Tobago
drop if id_alex=="cj_English_1_1236_2021" //Trinidad and Tobago
replace cj_q38_norm=. if id_alex=="cj_English_0_938" //Trinidad and Tobago
replace cj_q24c_norm=. if country=="Trinidad and Tobago" //Trinidad and Tobago
replace cj_q33a_norm=. if country=="Trinidad and Tobago" //Trinidad and Tobago
replace cj_q33b_norm=. if country=="Trinidad and Tobago" //Trinidad and Tobago
replace cj_q33c_norm=. if country=="Trinidad and Tobago" //Trinidad and Tobago
replace cj_q33d_norm=. if country=="Trinidad and Tobago" //Trinidad and Tobago
replace cj_q33e_norm=. if country=="Trinidad and Tobago" //Trinidad and Tobago
replace cj_q32b_norm=. if id_alex=="cj_English_1_1199_2021" //Trinidad and Tobago
replace cj_q24b_norm=. if country=="Trinidad and Tobago" //Trinidad and Tobago
replace all_q57_norm=. if country=="Trinidad and Tobago" //Trinidad and Tobago
replace cc_q26h_norm=. if country=="Trinidad and Tobago" //Trinidad and Tobago
replace cc_q28e_norm=. if country=="Trinidad and Tobago" //Trinidad and Tobago
replace lb_q6c_norm=. if country=="Trinidad and Tobago" //Trinidad and Tobago
replace cj_q24b_norm=. if country=="Trinidad and Tobago" //Trinidad and Tobago
replace cj_q42c_norm=. if country=="Trinidad and Tobago" //Trinidad and Tobago
replace cj_q18a_norm=. if country=="Trinidad and Tobago" //Trinidad and Tobago
replace cj_q31e_norm=. if id_alex=="cj_English_1_1250_2019_2021" //Trinidad and Tobago
replace cj_q42d_norm=. if id_alex=="cj_English_1_1250_2019_2021" //Trinidad and Tobago
replace cj_q42d_norm=. if id_alex=="cj_English_1_1199_2021" //Trinidad and Tobago
replace all_q29_norm=. if id_alex=="cj_English_1_1250_2019_2021" //Trinidad and Tobago
replace all_q30_norm=. if id_alex=="cj_English_1_1250_2019_2021" //Trinidad and Tobago
replace all_q29_norm=. if id_alex=="cj_English_1_132_2021" //Trinidad and Tobago
replace all_q30_norm=. if id_alex=="cj_English_1_132_2021" //Trinidad and Tobago
replace all_q29_norm=. if id_alex=="cj_English_1_1199_2021" //Trinidad and Tobago
replace all_q30_norm=. if id_alex=="cj_English_1_1199_2021" //Trinidad and Tobago
replace cj_q18a_norm=. if country=="Trinidad and Tobago" //Trinidad and Tobago
replace cj_q18c_norm=. if country=="Trinidad and Tobago" //Trinidad and Tobago
replace cj_q20o_norm=0.4444444 if id_alex=="cj_English_1_1199_2021" //Trinidad and Tobago
replace cj_q20o_norm=. if id_alex=="cj_English_1_1250_2019_2021" //Trinidad and Tobago
replace cj_q20o_norm=. if id_alex=="cj_English_1_132_2021" //Trinidad and Tobago
replace all_q96_norm=. if id_alex=="cc_English_0_1085_2018_2019_2021" //Trinidad and Tobago
replace all_q96_norm=. if id_alex=="cc_English_1_1158_2018_2019_2021" //Trinidad and Tobago
replace all_q96_norm=. if id_alex=="cc_English_0_70_2016_2017_2018_2019_2021" //Trinidad and Tobago
replace all_q96_norm=. if id_alex=="cc_English_0_1310_2019_2021" //Trinidad and Tobago
drop if id_alex=="cc_French_0_141_2019_2021" //Tunisia
drop if id_alex=="lb_French_1_186" //Tunisia
replace cj_q42c_norm=. if id_alex=="cj_Arabic_0_22" //Tunisia
replace cj_q42d_norm=. if id_alex=="cj_Arabic_0_22" //Tunisia
replace all_q86_norm=. if id_alex=="cc_French_0_87" //Tunisia
replace all_q87_norm=. if id_alex=="cc_French_0_87" //Tunisia
replace all_q89_norm=. if id_alex=="cc_French_0_87" //Tunisia
replace all_q59_norm=. if id_alex=="cc_French_0_87" //Tunisia
replace all_q90_norm=. if id_alex=="cc_French_0_87" //Tunisia
replace all_q91_norm=. if id_alex=="cc_French_0_87" //Tunisia
replace all_q59_norm=. if id_alex=="cc_French_0_650" //Tunisia
replace cc_q14a_norm=. if id_alex=="cc_French_0_87" //Tunisia
replace cc_q14b_norm=. if id_alex=="cc_French_0_87" //Tunisia
replace cc_q14a_norm=. if id_alex=="cc_French_0_660" //Tunisia
replace cc_q14b_norm=. if id_alex=="cc_French_0_660" //Tunisia
drop if id_alex=="cc_French_0_650" //Tunisia
drop if id_alex=="cj_French_1_953_2017_2018_2019_2021" //Tunisia
replace all_q2_norm=. if id_alex=="lb_French_1_563_2018_2019_2021" //Tunisia
replace all_q3_norm=. if id_alex=="lb_French_1_563_2018_2019_2021" //Tunisia
replace all_q4_norm=. if id_alex=="lb_French_1_563_2018_2019_2021" //Tunisia
replace all_q1_norm=0 if id_alex=="cc_French_1_135_2017_2018_2019_2021" //Tunisia
replace all_q2_norm=0 if id_alex=="cc_French_0_1274_2019_2021" //Tunisia
replace all_q8_norm=. if id_alex=="cj_French_1_294_2019_2021" //Tunisia
replace all_q2_norm=0 if id_alex=="cc_French_0_1304" //Tunisia
replace all_q2_norm=0 if id_alex=="cc_French_0_87" //Tunisia
replace all_q2_norm=0 if id_alex=="cc_French_0_985" //Tunisia
replace all_q19_norm=. if id_alex=="cc_French_0_1274_2019_2021" //Tunisia
replace all_q20_norm=. if id_alex=="cc_French_0_1274_2019_2021" //Tunisia
replace all_q21_norm=. if id_alex=="cc_French_0_1274_2019_2021" //Tunisia
replace all_q19_norm=. if id_alex=="cc_French_0_87" //Tunisia
replace all_q20_norm=. if id_alex=="cc_French_0_87" //Tunisia
replace all_q21_norm=. if id_alex=="cc_French_0_87" //Tunisia
replace all_q19_norm=. if id_alex=="cc_French_0_1304" //Tunisia
replace all_q20_norm=. if id_alex=="cc_French_0_1304" //Tunisia
replace all_q21_norm=. if id_alex=="cc_French_0_1304" //Tunisia
replace all_q19_norm=. if id_alex=="cj_French_0_628" //Tunisia
replace all_q20_norm=. if id_alex=="cj_French_0_628" //Tunisia
replace all_q21_norm=. if id_alex=="cj_French_0_628" //Tunisia
replace cj_q38_norm=. if id_alex=="cj_French_1_726_2018_2019_2021" //Tunisia
replace cj_q38_norm=. if id_alex=="cj_Arabic_0_22" //Tunisia
replace all_q9_norm=. if id_alex=="cc_French_0_1031" //Tunisia
replace all_q96_norm=. if id_alex=="cc_French_1_1426_2019_2021" //Tunisia
replace all_q96_norm=. if id_alex=="cc_French_0_1616_2021" //Tunisia
replace all_q96_norm=. if id_alex=="cj_French_0_491_2017_2018_2019_2021" //Tunisia
replace all_q29_norm=. if id_alex=="cj_French_0_1409_2018_2019_2021" //Tunisia
replace all_q30_norm=. if id_alex=="cj_French_0_1409_2018_2019_2021" //Tunisia
replace all_q29_norm=. if id_alex=="cj_French_1_294_2019_2021" //Tunisia
replace all_q30_norm=. if id_alex=="cj_French_1_294_2019_2021" //Tunisia
drop if id_alex=="cj_English_0_260" //Turkey
drop if id_alex=="ph_English_1_628" //Turkey
drop if id_alex=="cj_English_0_604" //Turkey
drop if id_alex=="cj_English_0_276" //Turkey
drop if id_alex=="lb_English_1_564" //Turkey
replace all_q20_norm=. if id_alex=="cc_English_0_404" //Turkey
replace all_q20_norm=. if id_alex=="cj_English_0_296" //Turkey
replace cc_q33_norm=. if id_alex=="cc_English_0_123_2019_2021" //Turkey
replace cj_q8_norm=. if country=="Turkey" //Turkey
replace all_q29_norm=. if id_alex=="cc_English_1_259_2019_2021" //Turkey
replace all_q29_norm=. if id_alex=="cc_French_0_142_2021" //Turkey
replace all_q29_norm=. if id_alex=="cj_English_0_128" //Turkey
replace all_q30_norm=. if id_alex=="cc_French_0_142_2021" //Turkey
replace all_q30_norm=. if id_alex=="cj_English_1_263_2019_2021" //Turkey
replace all_q30_norm=. if id_alex=="cj_English_0_128" //Turkey
replace lb_q19a_norm=. if id_alex=="lb_English_0_463" //Turkey	
replace all_q48_norm=. if id_alex=="lb_English_0_463" //Turkey	
replace all_q49_norm=. if id_alex=="lb_English_0_463" //Turkey
replace all_q50_norm=. if id_alex=="lb_English_0_463" //Turkey
replace all_q62_norm=. if id_alex=="cc_English_1_182" //Turkey
replace all_q63_norm=. if id_alex=="cc_English_1_182" //Turkey
replace all_q62_norm=. if id_alex=="cc_English_0_1147" //Turkey
replace all_q63_norm=. if id_alex=="cc_English_0_1147" //Turkey
replace all_q76_norm=. if id_alex=="cc_English_0_948" //Turkey
replace all_q77_norm=. if id_alex=="cc_English_0_948" //Turkey
replace all_q78_norm=. if id_alex=="cc_English_0_948" //Turkey
replace all_q79_norm=. if id_alex=="cc_English_0_948" //Turkey
replace all_q80_norm=. if id_alex=="cc_English_0_948" //Turkey
replace all_q81_norm=. if id_alex=="cc_English_0_948" //Turkey
replace all_q82_norm=. if id_alex=="cc_English_0_948" //Turkey
replace all_q76_norm=. if id_alex=="lb_English_0_463" //Turkey
replace all_q77_norm=. if id_alex=="lb_English_0_463" //Turkey
replace all_q78_norm=. if id_alex=="lb_English_0_463" //Turkey
replace all_q79_norm=. if id_alex=="lb_English_0_463" //Turkey
replace all_q80_norm=. if id_alex=="lb_English_0_463" //Turkey
replace all_q81_norm=. if id_alex=="lb_English_0_463" //Turkey
replace all_q57_norm=. if id_alex=="cc_English_0_948" //Turkey
replace all_q58_norm=. if id_alex=="cc_English_0_948" //Turkey
replace all_q59_norm=. if id_alex=="cc_English_0_948" //Turkey
replace all_q83_norm=. if id_alex=="cc_English_0_806_2019_2021" //Turkey
replace cc_q26h_norm=. if id_alex=="cc_English_1_259_2019_2021" //Turkey
replace cc_q28e_norm=. if id_alex=="cc_English_1_259_2019_2021" //Turkey
replace lb_q2d_norm=0.5 if id_alex=="lb_English_1_604" //Turkey
replace all_q48_norm=. if id_alex=="cc_English_0_1459_2016_2017_2018_2019_2021" //Turkey
replace all_q49_norm=0 if id_alex=="cc_English_0_1459_2016_2017_2018_2019_2021" //Turkey
replace all_q50_norm=. if id_alex=="cc_English_0_1459_2016_2017_2018_2019_2021" //Turkey
replace all_q85_norm=. if country=="Uganda" /* Uganda */
drop if id_alex=="cc_English_0_615" //Uganda
drop if id_alex=="cc_English_0_1721" //Uganda
drop if id_alex=="cc_English_1_965" //Uganda
drop if id_alex=="lb_English_0_340" //Uganda
drop if id_alex=="cj_English_1_710" //Uganda
replace cj_q11b_norm=. if id_alex=="cj_English_0_24" //Uganda
replace cj_q11b_norm=. if id_alex=="cj_English_1_287" //Uganda
replace cj_q11b_norm=. if id_alex=="cj_English_1_907" //Uganda
replace ph_q9a_norm=. if country=="Uganda" //Uganda
replace ph_q9b_norm=. if country=="Uganda" //Uganda
replace lb_q19a_norm=. if id_alex=="lb_English_0_338" //Uganda  
replace all_q48_norm=. if id_alex=="lb_English_0_338" //Uganda  
replace all_q50_norm=. if id_alex=="lb_English_0_338" //Uganda  
replace all_q62_norm=. if id_alex=="cc_English_0_829" //Uganda
replace all_q63_norm=. if id_alex=="cc_English_0_829" //Uganda
replace lb_q2d_norm=. if id_alex=="lb_English_0_338" //Uganda
replace lb_q3d_norm=. if id_alex=="lb_English_0_338" //Uganda
replace all_q62_norm=. if id_alex=="lb_English_0_338" //Uganda
replace all_q63_norm=. if id_alex=="lb_English_0_338" //Uganda
replace all_q48_norm=. if id_alex=="lb_English_0_338" //Uganda
replace all_q49_norm=. if id_alex=="lb_English_0_338" //Uganda
replace all_q50_norm=. if id_alex=="lb_English_0_338" //Uganda
replace lb_q19a_norm=. if id_alex=="lb_English_0_338" //Uganda
replace all_q49_norm=. if id_alex=="cc_English_0_1896_2018_2019_2021" //Uganda
replace all_q49_norm=. if id_alex=="cc_English_1_1335_2018_2019_2021" //Uganda
replace cj_q42c_norm=. if id_alex=="cj_English_1_808_2016_2017_2018_2019_2021" //Uganda
replace cj_q42c_norm=. if id_alex=="cj_English_0_385_2016_2017_2018_2019_2021" //Uganda
replace cj_q42c_norm=. if id_alex=="cj_English_1_872_2016_2017_2018_2019_2021" //Uganda
replace cj_q31e_norm=. if id_alex=="cj_Russian_0_413_2019_2021" //Ukraine
replace cj_q42c_norm=. if id_alex=="cj_Russian_0_413_2019_2021" //Ukraine
replace cj_q42d_norm=. if id_alex=="cj_Russian_0_413_2019_2021" //Ukraine
replace cj_q31e_norm=. if id_alex=="cj_English_1_303_2021" //Ukraine
replace cj_q42c_norm=. if id_alex=="cj_English_1_303_2021" //Ukraine
replace cj_q42d_norm=. if id_alex=="cj_English_1_303_2021" //Ukraine
drop if id_alex=="cc_English_0_1092_2017_2018_2019_2021" //Ukraine
replace all_q59_norm=. if id_alex=="cc_Russian_1_1323_2019_2021" //Ukraine
replace cc_q14a_norm=. if id_alex=="cc_English_1_1586_2019_2021" //Ukraine
replace cc_q14b_norm=. if id_alex=="cc_Russian_0_637_2019_2021" //Ukraine
replace all_q87_norm=. if id_alex=="lb_Russian_1_607_2018_2019_2021" //Ukraine
drop if id_alex=="cj_English_1_546_2016_2017_2018_2019_2021" //Ukraine
replace cj_q12c_norm=. if id_alex=="cj_Russian_1_854_2019_2021" //Ukraine
replace cj_q12d_norm=. if id_alex=="cj_Russian_1_854_2019_2021" //Ukraine
replace cj_q12e_norm=. if id_alex=="cj_Russian_1_854_2019_2021" //Ukraine
drop if id_alex=="cc_Arabic_0_1645" //UAE
drop if id_alex=="cj_Arabic_1_791" //UAE
drop if id_alex=="lb_Arabic_0_183" //UAE
drop if id_alex=="ph_English_0_162" //UAE
drop if id_alex=="ph_English_1_339" //UAE
drop if id_alex=="cc_English_1_1098" //UAE
replace lb_q3d_norm=. if country=="United Arab Emirates" //UAE
replace cc_q39b_norm=. if id_alex=="cc_English_1_788_2016_2017_2018_2019_2021" //UAE
replace cc_q39b_norm=. if id_alex=="cc_English_0_606" //UAE
replace cc_q26a_norm=. if country=="United Arab Emirates" /*UAE*/
replace cj_q36c_norm=. if id_alex=="cj_French_0_805" /*UAE*/
replace cc_q33_norm=. if country=="United Arab Emirates" //UAE
replace all_q21_norm=. if id_alex=="cj_French_0_805" //UAE
replace all_q20_norm=. if id_alex=="cj_French_0_805" //UAE
replace all_q20_norm=. if id_alex=="lb_Arabic_0_183" //UAE
foreach v of varlist all_q8_norm all_q22_norm all_q23_norm all_q24_norm	all_q25_norm all_q26_norm all_q27_norm {
replace `v'=. if id_alex=="cc_Arabic_0_1645" //UAE
replace `v'=. if id_alex=="lb_Arabic_0_183" //UAE
}
replace cj_q11a_norm=. if country=="United Arab Emirates" //UAE
replace cj_q11b_norm=. if country=="United Arab Emirates" //UAE
replace cj_q31e_norm=. if country=="United Arab Emirates" //UAE
replace cj_q42c_norm=. if id_alex=="cj_French_0_805" //UAE  
replace cj_q42d_norm=. if id_alex=="cj_French_0_805" //UAE
replace all_q19_norm=. if id_alex=="cc_English_0_162_2021" //UAE
replace all_q19_norm=. if id_alex=="cc_Arabic_0_1645" //UAE
replace all_q19_norm=. if id_alex=="cj_French_0_805" //UAE
replace all_q31_norm =. if id_alex=="cc_Arabic_0_1645" //UAE
replace all_q31_norm =. if id_alex=="cj_French_0_805" //UAE
replace cj_q15_norm=. if id_alex=="cj_French_0_805" //UAE
replace cj_q25a_norm=. if id_alex=="cj_English_0_1089" //UAE
replace cj_q25b_norm=. if id_alex=="cj_English_0_1089" //UAE
replace cj_q25c_norm=. if id_alex=="cj_English_0_1089" //UAE
replace cj_q25a_norm=. if id_alex=="cj_French_0_805" //UAE
replace cj_q25b_norm=. if id_alex=="cj_French_0_805" //UAE
replace cj_q25c_norm=. if id_alex=="cj_French_0_805" //UAE
replace cj_q27a_norm=. if country=="United Arab Emirates" //UAE
replace cj_q27b_norm=. if country=="United Arab Emirates" //UAE
replace cj_q7c_norm=. if country=="United Arab Emirates" //UAE
foreach v of varlist cj_q12a_norm cj_q12b_norm cj_q12c_norm cj_q12d_norm cj_q12e_norm cj_q12f_norm {
replace `v'=. if id_alex=="cc_Arabic_0_1645" //UAE
replace `v'=. if id_alex=="lb_Arabic_0_183" //UAE
}
replace cj_q20o_norm=. if id_alex=="cj_English_1_438_2017_2018_2019_2021" //UAE
replace cj_q20o_norm=. if id_alex=="cj_English_0_1089" //UAE
replace cj_q24c_norm=. if country=="United Arab Emirates" //UAE
replace cj_q40b_norm=. if id_alex=="cj_French_0_805" //UAE
replace cj_q40c_norm=. if id_alex=="cj_French_0_805" //UAE
replace cj_q20m_norm=. if id_alex=="cj_English_1_438_2017_2018_2019_2021" //UAE
replace cj_q20m_norm=. if id_alex=="cj_English_0_1089" //UAE
replace all_q29_norm=0 if id_alex=="cc_English_0_606" //UAE
replace all_q30_norm=0 if id_alex=="cc_English_0_606" //UAE
replace all_q29_norm=. if id_alex=="cj_Arabic_0_402" //UAE
replace all_q30_norm=. if id_alex=="cj_Arabic_0_402" //UAE
replace cj_q31f_norm=0 if id_alex=="cj_Arabic_0_1124" //UAE
replace cj_q31g_norm=0 if id_alex=="cj_Arabic_0_1124" //UAE
replace cj_q31f_norm=0 if id_alex=="cj_English_0_1089" //UAE
replace cj_q31g_norm=0 if id_alex=="cj_English_0_1089" //UAE
replace cj_q31f_norm=0 if id_alex=="cj_English_0_745" //UAE
replace cj_q31g_norm=0 if id_alex=="cj_English_0_745" //UAE
replace cj_q40b_norm=0 if id_alex=="cj_English_0_745" //UAE
replace cj_q40c_norm=0 if id_alex=="cj_English_0_745" //UAE
replace cj_q40c_norm=0 if id_alex=="cj_English_0_745" //UAE
replace all_q13_norm=. if country=="United Arab Emirates" //UAE
replace cj_q31f_norm=. if id_alex=="cj_English_1_438_2017_2018_2019_2021" //UAE
replace cj_q42c_norm=. if id_alex=="cj_English_1_438_2017_2018_2019_2021" //UAE
replace all_q22_norm=. if id_alex=="cj_English_0_745" //UAE
replace all_q23_norm=. if id_alex=="cj_English_0_745" //UAE
replace all_q24_norm=. if id_alex=="cj_English_0_745" //UAE
replace all_q25_norm=. if id_alex=="cj_English_0_745" //UAE
replace all_q26_norm=. if id_alex=="cj_English_0_745" //UAE
replace all_q27_norm=. if id_alex=="cj_English_0_745" //UAE
replace all_q8_norm=. if id_alex=="cj_English_0_745" //UAE
replace all_q32_norm=. if id_alex=="cj_French_0_805" //UAE
replace all_q14_norm=. if id_alex=="cj_French_0_805" //UAE
replace cj_q2_norm=. if country=="United Arab Emirates" //UAE
replace cj_q31d_norm=. if country=="United Arab Emirates" //UAE
replace lb_q23f_norm=.3333333 if id_alex=="lb_English_1_535" //UAE
replace cj_q31g_norm=. if id_alex=="cj_English_1_935_2018_2019_2021" //UAE
replace lb_q3d_norm =. if country=="United Kingdom" /* UK */
drop if id_alex=="cc_English_0_1106" //UK
drop if id_alex=="cj_English_1_397_2016_2017_2018_2019_2021" //UK
drop if id_alex=="lb_English_0_662_2021" //UK
drop if id_alex=="cc_English_1_787_2016_2017_2018_2019_2021" //USA
drop if id_alex=="cj_French_1_195" //USA
replace all_q21_norm=. if country=="United States" /* USA */
replace cj_q20o_norm=. if id_alex=="cj_English_0_162_2019_2021" /* USA */
replace cj_q20o_norm=. if id_alex=="cj_English_0_584" /* USA */
replace cj_q20o_norm=. if id_alex=="cj_English_0_1068" /* USA */
replace cj_q31e_norm=. if id_alex=="cj_English_0_166_2016_2017_2018_2019_2021" /* USA */
replace cj_q10_norm=. if id_alex=="cj_English_0_166_2016_2017_2018_2019_2021" /* USA */
replace cj_q11a_norm=. if id_alex=="cj_English_0_166_2016_2017_2018_2019_2021" /* USA */
replace cj_q31e_norm=. if id_alex=="cj_English_0_181_2017_2018_2019_2021" /* USA */
replace cj_q10_norm=. if id_alex=="cj_English_0_181_2017_2018_2019_2021" /* USA */
replace cj_q31e_norm=. if id_alex=="cj_English_0_652_2018_2019_2021" /* USA */
replace cj_q10_norm=. if id_alex=="cj_English_0_652_2018_2019_2021" /* USA */
replace cj_q31e_norm=. if id_alex=="cj_English_0_989_2021" /* USA */
replace cj_q10_norm=. if id_alex=="cj_English_0_989_2021" /* USA */
replace cj_q31f_norm=. if id_alex=="cj_English_0_166_2016_2017_2018_2019_2021" /* USA */
replace cj_q31g_norm=. if id_alex=="cj_English_0_166_2016_2017_2018_2019_2021" /* USA */
drop if id_alex=="cj_Russian_0_254" //Uzbekistan
drop if id_alex=="cc_English_1_267_2016_2017_2018_2019_2021" //Uzbekistan
replace cj_q32b_norm=. if country=="Uzbekistan" /* Uzbekistan */
replace all_q87_norm=. if country=="Uzbekistan" /* Uzbekistan */
replace all_q78_norm=. if country=="Uzbekistan" /* Uzbekistan */
replace cj_q20o_norm=. if id_alex=="cj_Russian_0_305_2018_2019_2021" /* Uzbekistan */
replace lb_q23f_norm=. if id_alex=="lb_Russian_0_130_2021" /* Uzbekistan */
replace lb_q16a_norm=. if id_alex=="lb_Russian_1_246" /* Uzbekistan */
replace lb_q16b_norm=. if id_alex=="lb_Russian_1_246" /* Uzbekistan */
replace lb_q16c_norm=. if id_alex=="lb_Russian_1_246" /* Uzbekistan */
replace lb_q16d_norm=. if id_alex=="lb_Russian_1_246" /* Uzbekistan */
replace lb_q16e_norm=. if id_alex=="lb_Russian_1_246" /* Uzbekistan */
replace lb_q16f_norm=. if id_alex=="lb_Russian_1_246" /* Uzbekistan */
replace cj_q42c_norm=. if id_alex=="cj_Russian_0_305_2018_2019_2021" /* Uzbekistan */
replace cj_q42d_norm=. if id_alex=="cj_Russian_0_305_2018_2019_2021" /* Uzbekistan */
replace cj_q42d_norm=. if id_alex=="cj_Russian_1_118" /* Uzbekistan */
replace all_q50_norm=. if id_alex=="cc_English_0_1582" /* Uzbekistan */
replace all_q49_norm=. if id_alex=="cc_English_0_232" /* Uzbekistan */
replace cj_q28_norm=. if country=="Vietnam" /* Vietnam */
drop if id_alex=="cc_English_0_1550" /* Vietnam */
drop if id_alex=="cj_English_0_698_2021" /* Vietnam */
drop if id_alex=="cj_English_0_1370_2018_2019_2021" /* Vietnam */
drop if id_alex=="lb_English_0_498" /* Vietnam */
drop if id_alex=="ph_English_0_46" /* Vietnam */
drop if id_alex=="ph_English_1_230" /* Vietnam */
replace all_q29_norm=. if id_alex=="cc_English_0_495" /* Vietnam */
replace all_q29_norm=. if id_alex=="cj_English_0_639" /* Vietnam */
replace all_q30_norm=. if id_alex=="cc_English_1_184_2017_2018_2019_2021" /* Vietnam */
replace all_q30_norm=. if id_alex=="cc_English_1_1307" /* Vietnam */
replace all_q30_norm=. if id_alex=="cc_English_0_495" /* Vietnam */
replace all_q30_norm=. if id_alex=="cc_English_1_1233" /* Vietnam */
replace ph_q9a_norm=. if country=="Vietnam" /* Vietnam */
replace lb_q3d_norm=. if country=="Vietnam" /* Vietnam */
replace all_q48_norm=. if id_alex=="cc_English_0_495" /* Vietnam */
replace all_q49_norm=. if id_alex=="cc_English_0_495" /* Vietnam */ 
replace all_q50_norm=. if id_alex=="cc_English_0_495" /* Vietnam */
replace lb_q19a_norm=. if id_alex=="lb_English_0_594_2018_2019_2021" /* Vietnam */
replace all_q48_norm=. if id_alex=="lb_English_0_594_2018_2019_2021" /* Vietnam */
replace all_q49_norm=. if id_alex=="lb_English_0_594_2018_2019_2021" /* Vietnam */
replace all_q50_norm=. if id_alex=="lb_English_0_594_2018_2019_2021" /* Vietnam */
replace lb_q19a_norm=. if id_alex=="lb_English_0_595_2017_2018_2019_2021" /* Vietnam */
replace all_q48_norm=. if id_alex=="lb_English_0_595_2017_2018_2019_2021" /* Vietnam */
replace all_q49_norm=. if id_alex=="lb_English_0_595_2017_2018_2019_2021" /* Vietnam */
replace all_q50_norm=. if id_alex=="lb_English_0_595_2017_2018_2019_2021" /* Vietnam */
replace cj_q21h_norm=. if country=="Vietnam" /* Vietnam */
replace cj_q20o_norm=. if id_alex=="cj_English_0_857_2014_2016_2017_2018_2019_2021" /* Vietnam */
replace cj_q20o_norm=. if id_alex=="cj_English_1_685_2017_2018_2019_2021" /* Vietnam */
replace cj_q20o_norm=. if id_alex=="cj_English_0_639" /* Vietnam */
replace cj_q15_norm=. if id_alex=="cj_English_0_639" /* Vietnam */
replace cj_q15_norm=. if id_alex=="cj_English_0_1027" /* Vietnam */
replace all_q48_norm=. if id_alex=="cc_English_1_1385_2019_2021" /* Vietnam */
replace all_q49_norm=. if id_alex=="cc_English_1_1385_2019_2021" /* Vietnam */
replace cc_q16b_norm=. if id_alex=="cc_English_1_90_2016_2017_2018_2019_2021" /* Vietnam */
replace cc_q16c_norm=. if id_alex=="cc_English_1_90_2016_2017_2018_2019_2021" /* Vietnam */
replace cc_q16d_norm=. if id_alex=="cc_English_1_90_2016_2017_2018_2019_2021" /* Vietnam */
drop if id_alex=="cc_English_1_591" //Zambia
drop if id_alex=="cj_English_1_1271_2021" //Zambia
drop if id_alex=="ph_English_1_594_2021" //Zambia
drop if id_alex=="ph_English_0_161_2021" //Zambia
replace cc_q14b_norm=. if country=="Zambia" /* Zambia */
replace all_q90_norm=. if country=="Zambia" /* Zambia */
replace all_q91_norm=. if country=="Zambia" /* Zambia */
replace lb_q19a_norm=. if country=="Zambia" /* Zambia */
replace cc_q12_norm=. if country=="Zambia" /* Zambia */
replace cj_q40c_norm=. if country=="Zambia" /* Zambia */
replace all_q23_norm=. if country=="Zambia" /* Zambia */
replace all_q24_norm=. if country=="Zambia" /* Zambia */
replace all_q25_norm=. if country=="Zambia" /* Zambia */
replace all_q1_norm=. if id_alex=="cc_English_1_1425" /* Zambia */
replace all_q1_norm=. if id_alex=="cj_English_0_669_2019_2021" /* Zambia */
replace all_q2_norm=. if id_alex=="cc_English_1_1425" /* Zambia */
replace all_q2_norm=. if id_alex=="cj_English_1_1023_2019_2021" /* Zambia */
replace all_q2_norm=. if id_alex=="lb_English_0_491" /* Zambia */
replace all_q20_norm=. if id_alex=="cc_English_0_1186_2014_2016_2017_2018_2019_2021" /* Zambia */
replace all_q21_norm=. if id_alex=="cc_English_0_888" /* Zambia */
replace all_q21_norm=. if id_alex=="lb_English_0_734_2021" /* Zambia */
replace all_q27_norm=. if id_alex=="cc_English_0_1702_2017_2018_2019_2021" /* Zambia */
replace all_q27_norm=. if id_alex=="cj_English_0_449" /* Zambia */
replace all_q29_norm=. if id_alex=="cc_English_1_796" /* Zambia */
replace all_q30_norm=. if id_alex=="cj_English_1_375_2021" /* Zambia */
replace all_q30_norm=. if id_alex=="cj_English_0_449" /* Zambia */
replace all_q96_norm=. if id_alex=="lb_English_0_389_2013_2014_2016_2017_2018_2019_2021" /* Zambia */
replace all_q96_norm=. if id_alex=="lb_English_1_463_2017_2018_2019_2021" /* Zambia */
replace all_q96_norm=. if id_alex=="lb_English_1_742" /* Zambia */
replace cj_q42c_norm=. if id_alex=="cj_English_1_375_2021" /* Zambia */
replace cj_q42d_norm=. if id_alex=="cj_English_1_375_2021" /* Zambia */
replace all_q29_norm=. if id_alex=="cj_English_0_449" /* Zambia */
replace cj_q15_norm=. if id_alex=="cj_English_0_449" /* Zambia */
replace cj_q28_norm=. if id_alex=="cj_English_0_1151" /* Zambia */
drop if id_alex=="cc_English_0_1685_2019_2021" //Zimbabmwe 
drop if id_alex=="cj_English_0_897" //Zimbabmwe
drop if id_alex=="lb_English_1_583" //Zimbabmwe
replace cc_q40a_norm=. if country=="Zimbabwe" /* Zimbabwe */
replace cj_q21h_norm=. if id_alex=="cj_English_1_595" /* Zimbabwe */
replace cj_q21h_norm=. if id_alex=="cj_English_1_1041" /* Zimbabwe */
replace cc_q26b_norm=. if id_alex=="cc_English_1_243_2017_2018_2019_2021" /* Zimbabwe */
replace all_q86_norm=. if id_alex=="cc_English_1_243_2017_2018_2019_2021" /* Zimbabwe */
replace all_q87_norm=. if id_alex=="cc_English_1_243_2017_2018_2019_2021" /* Zimbabwe */
replace cc_q25_norm=. if id_alex=="cc_English_1_243_2017_2018_2019_2021" /* Zimbabwe */
replace all_q29_norm=. if id_alex=="cj_English_0_1019" /* Zimbabwe */
replace lb_q23a_norm=. if id_alex=="lb_English_1_320_2018_2019_2021" /* Zimbabwe */
replace cc_q26h_norm=. if id_alex=="cc_English_0_1023_2017_2018_2019_2021" /* Zimbabwe */
replace cc_q28e_norm=. if id_alex=="cc_English_0_1023_2017_2018_2019_2021" /* Zimbabwe */
replace cc_q26h_norm=. if id_alex=="cc_English_1_243_2017_2018_2019_2021" /* Zimbabwe */
replace cc_q28e_norm=. if id_alex=="cc_English_1_243_2017_2018_2019_2021" /* Zimbabwe */
replace lb_q23f_norm=. if id_alex=="lb_English_0_350" /* Zimbabwe */
replace lb_q23g_norm=. if id_alex=="lb_English_0_350" /* Zimbabwe */
replace ph_q6a_norm=. if id_alex=="ph_English_1_153_2014_2016_2017_2018_2019_2021" /* Zimbabwe */
replace ph_q6b_norm=. if id_alex=="ph_English_1_153_2014_2016_2017_2018_2019_2021" /* Zimbabwe */
replace ph_q6c_norm=. if id_alex=="ph_English_1_153_2014_2016_2017_2018_2019_2021" /* Zimbabwe */
replace ph_q6d_norm=. if id_alex=="ph_English_1_153_2014_2016_2017_2018_2019_2021" /* Zimbabwe */
replace ph_q6e_norm=. if id_alex=="ph_English_1_153_2014_2016_2017_2018_2019_2021" /* Zimbabwe */
replace ph_q6f_norm=. if id_alex=="ph_English_1_153_2014_2016_2017_2018_2019_2021" /* Zimbabwe */
drop if id_alex=="cc_Spanish_0_618" //Argentina
replace cj_q10_norm=. if id_alex=="cj_Spanish_0_693_2016_2017_2018_2019_2021" //Argentina
replace cj_q10_norm=. if id_alex=="cj_Spanish_1_567_2018_2019_2021" //Argentina
replace all_q88_norm=. if country=="Argentina" /* Argentina */
replace cj_q11a_norm=. if id_alex=="cj_Spanish_0_416" //Argentina
replace all_q77_norm=. if id_alex=="cc_Spanish_0_418" //Argentina
replace all_q78_norm=. if id_alex=="cc_Spanish (Mexico)_0_625_2019_2021" //Argentina
replace all_q78_norm=. if id_alex=="cc_Spanish_0_418" //Argentina
replace all_q96_norm=. if id_alex=="cc_Spanish_0_134" //Argentina
replace all_q96_norm=. if id_alex=="cc_Spanish_0_157" //Argentina
replace all_q96_norm=. if id_alex=="lb_English_1_417_2016_2017_2018_2019_2021" //Argentina
replace cj_q21a_norm=. if country=="Antigua and Barbuda" /*Antigua and Barbuda*/
replace cj_q38_norm=. if country=="Antigua and Barbuda" /*Antigua and Barbuda*/
replace cc_q33_norm=. if id_alex=="cc_English_0_768" /*Antigua and Barbuda*/
replace cc_q33_norm=. if id_alex=="cc_English_0_851" /*Antigua and Barbuda*/
replace cj_q10_norm=. if country=="Antigua and Barbuda" /*Antigua and Barbuda*/
replace cj_q31e_norm=. if country=="Antigua and Barbuda" /*Antigua and Barbuda*/
replace cj_q42d_norm=. if country=="Antigua and Barbuda" /*Antigua and Barbuda*/
replace all_q80_norm=. if country=="Antigua and Barbuda" /*Antigua and Barbuda*/
replace cj_q20o_norm=. if id_alex=="cj_English_0_685_2021" /*Antigua and Barbuda*/
replace all_q28_norm=. if country=="Antigua and Barbuda" /*Antigua and Barbuda*/
replace all_q1_norm=1 if id_alex=="lb_English_0_309_2021" /*Antigua and Barbuda*/
replace all_q1_norm=1 if id_alex=="cc_English_1_444_2018_2019_2021" /*Antigua and Barbuda*/
replace all_q96_norm=. if id_alex=="cj_English_0_700_2016_2017_2018_2019_2021" /*Antigua and Barbuda*/
replace all_q96_norm=. if id_alex=="cc_English_1_1572_2021" /*Antigua and Barbuda*/
replace cc_q39b_norm=. if id_alex=="cc_English_0_1030_2019_2021" /*Antigua and Barbuda*/
replace cc_q9b_norm=. if id_alex=="cc_English_0_1030_2019_2021" /*Antigua and Barbuda*/
replace cj_q11a_norm=. if id_alex=="cj_English_1_1033" /*Antigua and Barbuda*/
replace cj_q11b_norm=. if id_alex=="cj_English_1_1033" /*Antigua and Barbuda*/
replace cc_q10_norm=. if id_alex=="cc_English_0_768" /*Antigua and Barbuda*/
replace cc_q16d_norm=. if id_alex=="cc_English_0_768" /*Antigua and Barbuda*/
replace cj_q20b_norm=. if id_alex=="cj_English_1_958_2018_2019_2021" /*Antigua and Barbuda*/
replace cj_q20b_norm=0.5 if id_alex=="cj_English_0_685_2021" /*Antigua and Barbuda*/
replace cj_q20b_norm=0 if id_alex=="cc_English_0_818_2021" /*Antigua and Barbuda*/
replace cj_q33d_norm=. if id_alex=="cj_English_1_1033" /*Antigua and Barbuda*/
replace cj_q33e_norm=. if id_alex=="cj_English_1_1033" /*Antigua and Barbuda*/
drop if id_alex=="cc_English_1_999" //Bahamas 
drop if id_alex=="cc_English_0_1754" //Bahamas
drop if id_alex=="cc_English_1_1173_2018_2019_2021" //Bahamas
replace all_q96_norm=. if id_alex=="cc_English_0_1163_2016_2017_2018_2019_2021" //Bahamas
replace all_q96_norm=. if id_alex=="cc_English_0_103_2016_2017_2018_2019_2021" //Bahamas
replace all_q76_norm=. if id_alex=="cc_English_0_187" //Bahamas
replace all_q77_norm=. if id_alex=="cc_English_0_187" //Bahamas
replace all_q78_norm=. if id_alex=="cc_English_0_187" //Bahamas
replace all_q79_norm=. if id_alex=="cc_English_0_187" //Bahamas
replace all_q80_norm=. if id_alex=="cc_English_0_187" //Bahamas
replace all_q81_norm=. if id_alex=="cc_English_0_187" //Bahamas
replace all_q82_norm=. if id_alex=="cc_English_0_187" //Bahamas
replace all_q76_norm=. if id_alex=="cc_English_1_286" //Bahamas
replace all_q77_norm=. if id_alex=="cc_English_1_286" //Bahamas
replace all_q78_norm=. if id_alex=="cc_English_1_286" //Bahamas
replace all_q79_norm=. if id_alex=="cc_English_1_286" //Bahamas
replace all_q80_norm=. if id_alex=="cc_English_1_286" //Bahamas
replace all_q81_norm=. if id_alex=="cc_English_1_286" //Bahamas
replace all_q82_norm=. if id_alex=="cc_English_1_286" //Bahamas
replace cj_q12b_norm=. if id_alex=="cj_English_0_1153" //Bahamas
replace cj_q12c_norm=. if id_alex=="cj_English_0_1153" //Bahamas
replace cj_q12d_norm=. if id_alex=="cj_English_0_1153" //Bahamas
replace cj_q12a_norm=. if id_alex=="cj_English_1_949_2018_2019_2021" //Bahamas
replace cj_q12b_norm=. if id_alex=="cj_English_1_949_2018_2019_2021" //Bahamas
replace cj_q12c_norm=. if id_alex=="cj_English_1_949_2018_2019_2021" //Bahamas
replace cj_q12d_norm=. if id_alex=="cj_English_1_949_2018_2019_2021" //Bahamas
replace cj_q12e_norm=. if id_alex=="cj_English_1_949_2018_2019_2021" //Bahamas
replace cj_q12f_norm=. if id_alex=="cj_English_1_949_2018_2019_2021" //Bahamas
replace cj_q20e_norm=. if id_alex=="cj_English_1_949_2018_2019_2021" //Bahamas
replace cj_q20e_norm=. if id_alex=="cj_English_0_1032_2018_2019_2021" //Bahamas
replace cj_q20e_norm=. if id_alex=="cj_English_1_949_2018_2019_2021" //Bahamas
replace cj_q21h_norm=. if id_alex=="cj_English_0_1032_2018_2019_2021" //Bahamas
replace cj_q7c_norm=. if id_alex=="cj_English_0_1153" //Bahamas
replace cj_q20a_norm=. if id_alex=="cj_English_0_1153" //Bahamas
replace all_q94_norm=. if id_alex=="cc_English_0_658_2018_2019_2021" //Bahamas
replace all_q94_norm=. if id_alex=="cj_English_0_232" //Bahamas
replace all_q94_norm=. if id_alex=="lb_English_0_568" //Bahamas
replace all_q13_norm=. if id_alex=="lb_English_0_901_2021" //Bahamas
replace cj_q42c_norm=. if country=="Bahamas" /*The Bahamas*/
replace cj_q42d_norm=. if country=="Bahamas" /*The Bahamas*/
replace all_q30_norm=. if id_alex=="cj_English_0_232" //Bahamas
replace cj_q31f_norm=. if id_alex=="cj_English_1_949_2018_2019_2021" //Bahamas
replace cj_q21g_norm=. if id_alex=="cj_English_0_232" //Bahamas
replace cj_q21a_norm=. if id_alex=="cj_English_0_1153" //Bahamas
replace cj_q20o_norm=. if id_alex=="cj_English_0_232" //Bahamas
replace cj_q20o_norm=. if id_alex=="cj_English_1_1155" //Bahamas
drop if id_alex=="cc_English_0_993_2019_2021" //Barbados
drop if id_alex=="cc_English_0_441_2021" //Barbados
drop if id_alex=="cc_English_0_1393" //Barbados
drop if id_alex=="ph_English_0_488_2019_2021" //Barbados
drop if id_alex=="ph_English_1_683" //Barbados
drop if id_alex=="cc_English_0_1270_2018_2019_2021"  //Barbados
replace cj_q8_norm=. if id_alex=="cj_English_0_562" //Barbados
replace cj_q15_norm=. if id_alex=="cj_English_0_514" //Barbados
replace all_q1_norm=. if id_alex=="cc_English_1_1197_2019_2021" //Barbados
replace all_q2_norm=. if id_alex=="cc_English_1_1197_2019_2021" //Barbados
replace all_q20_norm=. if id_alex=="cc_English_1_1197_2019_2021" //Barbados
replace all_q21_norm=. if id_alex=="cc_English_1_1197_2019_2021" //Barbados
replace all_q2_norm=. if id_alex=="cc_English_1_1197_2019_2021" //Barbados
replace all_q3_norm=. if id_alex=="cc_English_1_1197_2019_2021" //Barbados
replace all_q4_norm=. if id_alex=="cc_English_1_1197_2019_2021" //Barbados
replace all_q5_norm=. if id_alex=="cc_English_1_1197_2019_2021" //Barbados
replace all_q7_norm=. if id_alex=="cc_English_1_1197_2019_2021" //Barbados
replace all_q8_norm=. if id_alex=="cc_English_1_1197_2019_2021" //Barbados
replace all_q1_norm=. if id_alex=="cc_English_0_80_2019_2021" //Barbados
replace all_q2_norm=. if id_alex=="cc_English_0_80_2019_2021" //Barbados
replace all_q20_norm=. if id_alex=="cc_English_0_80_2019_2021" //Barbados
replace all_q21_norm=. if id_alex=="cc_English_0_80_2019_2021" //Barbados
replace all_q2_norm=. if id_alex=="cc_English_0_80_2019_2021" //Barbados
replace all_q3_norm=. if id_alex=="cc_English_0_80_2019_2021" //Barbados
replace all_q4_norm=. if id_alex=="cc_English_0_80_2019_2021" //Barbados
replace all_q5_norm=. if id_alex=="cc_English_0_80_2019_2021" //Barbados
replace all_q7_norm=. if id_alex=="cc_English_0_80_2019_2021" //Barbados
replace all_q8_norm=. if id_alex=="cc_English_0_80_2019_2021" //Barbados
replace cc_q25_norm=. if id_alex=="cc_English_0_80_2019_2021" //Barbados
replace all_q1_norm=. if id_alex=="cc_English_1_557_2017_2018_2019_2021" //Barbados
replace all_q2_norm=. if id_alex=="cc_English_1_557_2017_2018_2019_2021" //Barbados
replace all_q20_norm=. if id_alex=="cc_English_1_557_2017_2018_2019_2021" //Barbados
replace all_q21_norm=. if id_alex=="cc_English_1_557_2017_2018_2019_2021" //Barbados
replace all_q2_norm=. if id_alex=="cc_English_1_557_2017_2018_2019_2021" //Barbados
replace all_q3_norm=. if id_alex=="cc_English_1_557_2017_2018_2019_2021" //Barbados
replace all_q4_norm=. if id_alex=="cc_English_1_557_2017_2018_2019_2021" //Barbados
replace all_q5_norm=. if id_alex=="cc_English_1_557_2017_2018_2019_2021" //Barbados
replace all_q7_norm=. if id_alex=="cc_English_1_557_2017_2018_2019_2021" //Barbados
replace all_q8_norm=. if id_alex=="cc_English_1_557_2017_2018_2019_2021" //Barbados
replace all_q8_norm=. if id_alex=="cj_English_1_962_2018_2019_2021" //Barbados
replace all_q1_norm=. if id_alex=="cj_English_1_676_2017_2018_2019_2021" //Barbados
replace all_q2_norm=. if id_alex=="cj_English_1_676_2017_2018_2019_2021" //Barbados
replace all_q3_norm=. if id_alex=="cj_English_1_676_2017_2018_2019_2021" //Barbados
replace all_q1_norm=. if id_alex=="cj_English_0_586_2018_2019_2021" //Barbados
replace all_q2_norm=. if id_alex=="cj_English_0_586_2018_2019_2021" //Barbados
replace all_q3_norm=. if id_alex=="cj_English_0_586_2018_2019_2021" //Barbados
drop if id_alex=="cc_English_0_83_2016_2017_2018_2019_2021" //Barbados
replace cc_q25_norm=. if id_alex=="cc_English_1_1412" //Barbados
replace cc_q25_norm=. if id_alex=="cc_English_0_891" //Barbados
replace all_q96_norm=. if id_alex=="cj_English_0_514" //Barbados
replace all_q96_norm=. if id_alex=="cj_English_0_744_2019_2021" //Barbados
replace all_q29_norm=1 if id_alex=="cj_English_0_272_2021" //Barbados
replace cj_q38_norm=0.5 if id_alex=="cj_English_0_562" //Barbados
replace cj_q38_norm=0.5 if id_alex=="cj_English_0_892" //Barbados
drop if id_alex=="cc_Spanish_0_220" //Bolivia
drop if id_alex=="cc_Spanish_0_400" //Bolivia
replace cj_q15_norm=. if id_alex=="cj_Spanish_0_107" //Bolivia
replace cj_q15_norm=. if id_alex=="cj_English_0_702" //Bolivia
replace cj_q15_norm=. if id_alex=="cj_Spanish_1_54" //Bolivia
replace cj_q15_norm=0 if id_alex=="cj_Spanish_0_228" //Bolivia
replace all_q29_norm=. if id_alex=="cc_English_1_521" //Bolivia
replace all_q30_norm=. if id_alex=="cc_English_1_521" //Bolivia
replace all_q29_norm=. if id_alex=="cc_Spanish_1_267" //Bolivia
replace all_q30_norm=. if id_alex=="cc_Spanish_1_267" //Bolivia
replace all_q29_norm=. if id_alex=="cj_Spanish_0_228" //Bolivia
replace all_q30_norm=. if id_alex=="cj_Spanish_0_228" //Bolivia
replace all_q29_norm=. if id_alex=="cc_English_1_1151_2017_2018_2019_2021" //Bolivia
replace all_q30_norm=. if id_alex=="cc_English_1_1151_2017_2018_2019_2021" //Bolivia
replace all_q22_norm=. if id_alex=="lb_Spanish_0_174_2021" //Bolivia
replace all_q23_norm=. if id_alex=="lb_Spanish_0_174_2021" //Bolivia
replace all_q24_norm=. if id_alex=="lb_Spanish_0_174_2021" //Bolivia
replace all_q25_norm=. if id_alex=="lb_Spanish_0_174_2021" //Bolivia
replace all_q26_norm=. if id_alex=="lb_Spanish_0_174_2021" //Bolivia
replace all_q27_norm=. if id_alex=="lb_Spanish_0_174_2021" //Bolivia
replace all_q8_norm=. if id_alex=="lb_Spanish_0_174_2021" //Bolivia
replace all_q22_norm=. if id_alex=="cc_Spanish_1_555" //Bolivia
replace all_q23_norm=. if id_alex=="cc_Spanish_1_555" //Bolivia
replace all_q24_norm=. if id_alex=="cc_Spanish_1_555" //Bolivia
replace all_q25_norm=. if id_alex=="cc_Spanish_1_555" //Bolivia
replace all_q26_norm=. if id_alex=="cc_Spanish_1_555" //Bolivia
replace all_q27_norm=. if id_alex=="cc_Spanish_1_555" //Bolivia
replace all_q8_norm=. if id_alex=="cc_Spanish_1_555" //Bolivia




drop if id_alex=="cc_English_0_1196_2016_2017_2018_2019_2021" //Brazil
drop if id_alex=="cc_English_0_960_2016_2017_2018_2019_2021" //Brazil
drop if id_alex=="cc_Portuguese_1_1219_2018_2019_2021" //Brazil
drop if id_alex=="cc_English_0_1079_2016_2017_2018_2019_2021" //Brazil
replace cc_q40a_norm=. if country=="Brazil" //Brazil
replace cj_q40b_norm=. if country=="Brazil" /* Brazil */
drop if id_alex=="cc_English_1_1332" //Dominica
replace cj_q28_norm=. if country=="Dominica" /*Dominica*/
replace cj_q20m_norm=. if country=="Dominica" /*Dominica*/
replace cj_q12b_norm=. if country=="Dominica" /*Dominica*/
replace cj_q12c_norm=. if country=="Dominica" /*Dominica*/
replace cj_q15_norm=. if id_alex=="cj_English_0_908" //Dominica
replace cj_q38_norm=. if country=="Dominica" /*Dominica*/
replace all_q1_norm=0 if id_alex=="cc_English_0_381_2018_2019_2021" //Dominica
replace cj_q42c_norm=. if id_alex=="cj_English_0_836_2016_2017_2018_2019_2021" //Dominica
replace cj_q42d_norm=. if id_alex=="cj_English_0_836_2016_2017_2018_2019_2021" //Dominica
replace cj_q15_norm=. if id_alex=="cj_English_0_908" //Dominica
replace cj_q15_norm=. if id_alex=="cj_English_0_412_2021" //Dominica
replace cc_q9c_norm=. if country=="Ecuador" //Ecuador
drop if id_alex=="cc_Spanish_0_513_2016_2017_2018_2019_2021" //Ecuador
drop if id_alex=="cc_English_1_676_2021" //Ecuador
drop if id_alex=="cj_Spanish_1_8_2013_2014_2016_2017_2018_2019_2021" //Ecuador
drop if id_alex=="lb_Spanish_0_318_2016_2017_2018_2019_2021" //Ecuador
drop if id_alex=="cc_Spanish_0_391_2016_2017_2018_2019_2021" //Ecuador
drop if id_alex=="cc_English_0_1150_2017_2018_2019_2021" //Ecuador
drop if id_alex=="ph_English_1_643_2019_2021" //Ecuador
replace all_q1_norm=. if id_alex=="cc_Spanish_1_155" //Ecuador
replace all_q2_norm=. if id_alex=="cc_Spanish_1_155" //Ecuador
replace all_q20_norm=. if id_alex=="cc_Spanish_1_155" //Ecuador
replace all_q21_norm=. if id_alex=="cc_Spanish_1_155" //Ecuador
replace all_q1_norm=. if id_alex=="cj_Spanish_0_124_2018_2019_2021" //Ecuador
replace all_q2_norm=. if id_alex=="cj_Spanish_0_124_2018_2019_2021" //Ecuador
replace all_q20_norm=. if id_alex=="cj_Spanish_0_124_2018_2019_2021" //Ecuador
replace all_q21_norm=. if id_alex=="cj_Spanish_0_124_2018_2019_2021" //Ecuador
replace all_q96_norm=. if id_alex=="cc_English_1_122_2017_2018_2019_2021" //Ecuador
replace all_q96_norm=. if id_alex=="mx_0_1404_2017_2018_2019_2021" //Ecuador
replace all_q96_norm=. if id_alex=="cc_Spanish_0_693" //Ecuador
replace all_q96_norm=. if id_alex=="lb_Spanish_1_700_2021" //Ecuador
replace all_q96_norm=. if id_alex=="lb_Spanish_1_637_2021" //Ecuador
replace all_q96_norm=. if id_alex=="lb_Spanish_1_460" //Ecuador
replace cj_q15_norm=. if id_alex=="cj_Spanish_1_636" //Ecuador
replace cj_q15_norm=. if id_alex=="cj_Spanish_1_494" //Ecuador
replace cj_q15_norm=. if id_alex=="cj_Spanish_1_287_2021" //Ecuador
replace all_q82_norm=. if id_alex=="cc_es-mx_0_1404_2017_2018_2019_2021" //Ecuador
replace all_q76_norm=. if id_alex=="lb_Spanish_1_460" //Ecuador
replace all_q77_norm=. if id_alex=="lb_Spanish_1_460" //Ecuador
replace cj_q12a_norm=. if id_alex=="cj_Spanish_0_1098_2017_2018_2019_2021" //Ecuador
replace cj_q12b_norm=. if id_alex=="cj_Spanish_0_1098_2017_2018_2019_2021" //Ecuador
replace cj_q12c_norm=. if id_alex=="cj_Spanish_0_1098_2017_2018_2019_2021" //Ecuador
replace cj_q12d_norm=. if id_alex=="cj_Spanish_0_1098_2017_2018_2019_2021" //Ecuador
replace cj_q12e_norm=. if id_alex=="cj_Spanish_0_1098_2017_2018_2019_2021" //Ecuador
replace cj_q12f_norm=. if id_alex=="cj_Spanish_0_1098_2017_2018_2019_2021" //Ecuador
replace cj_q12a_norm=. if id_alex=="cj_Spanish_0_734_2019_2021" //Ecuador
replace cj_q12b_norm=. if id_alex=="cj_Spanish_0_734_2019_2021" //Ecuador
replace cj_q12c_norm=. if id_alex=="cj_Spanish_0_734_2019_2021" //Ecuador
replace cj_q12d_norm=. if id_alex=="cj_Spanish_0_734_2019_2021" //Ecuador
replace cj_q12e_norm=. if id_alex=="cj_Spanish_0_734_2019_2021" //Ecuador
replace cj_q12f_norm=. if id_alex=="cj_Spanish_0_734_2019_2021" //Ecuador
replace cj_q42c_norm=. if id_alex=="cj_Spanish_1_494" //Ecuador
replace cj_q42d_norm=. if id_alex=="cj_Spanish_1_494" //Ecuador
replace cj_q42c_norm=. if id_alex=="cj_Spanish_1_114" //Ecuador
replace cj_q42d_norm=. if id_alex=="cj_Spanish_1_114" //Ecuador
replace cc_q40a_norm=. if id_alex=="cc_Spanish_0_384_2016_2017_2018_2019_2021" //Ecuador
replace cc_q40b_norm=. if id_alex=="cc_Spanish_0_384_2016_2017_2018_2019_2021" //Ecuador
drop if id_alex=="cc_French_0_1761" //Gabon
drop if id_alex=="lb_French_0_82" //Gabon
drop if id_alex=="cc_French_0_199" //Gabon
replace cj_q15_norm=. if id_alex=="cj_French_0_476" //Gabon
replace lb_q23g_norm=. if country=="Gabon" /*Gabon*/
replace lb_q23a_norm=. if country=="Gabon" /*Gabon*/
replace lb_q16f_norm=. if country=="Gabon" /*Gabon*/
replace lb_q23f_norm=. if id_alex=="lb_French_0_601" //Gabon
replace lb_q2d_norm=. if id_alex=="lb_French_0_393" //Gabon
replace lb_q3d_norm=. if id_alex=="lb_French_0_393" //Gabon
replace all_q62_norm=. if id_alex=="lb_French_0_393" //Gabon
replace all_q63_norm=. if id_alex=="lb_French_0_393" //Gabon
replace all_q48_norm=. if id_alex=="lb_French_0_393" //Gabon
replace all_q49_norm=. if id_alex=="lb_French_0_393" //Gabon
replace all_q50_norm=. if id_alex=="lb_French_0_393" //Gabon
replace lb_q19a_norm=. if id_alex=="lb_French_0_393" //Gabon
replace all_q62_norm=. if id_alex=="cc_French_0_1532" //Gabon
replace cj_q40b_norm=.3333333 if id_alex=="cj_French_0_476" //Gabon
replace cj_q40c_norm=.3333333 if id_alex=="cj_French_0_476" //Gabon
replace cj_q40b_norm=.3333333 if id_alex=="cj_French_0_686" //Gabon
replace cj_q40c_norm=.3333333 if id_alex=="cj_French_0_686" //Gabon
drop if id_alex=="cj_English_0_226" //Grenada
drop if id_alex=="cc_English_0_900_2021" //Grenada
replace all_q62_norm=. if country=="Grenada" /*Grenada*/
replace all_q63_norm=. if country=="Grenada" /*Grenada*/
replace all_q69_norm=. if country=="Grenada" /*Grenada*/
replace all_q70_norm=. if country=="Grenada" /*Grenada*/
replace all_q84_norm=. if country=="Grenada" /*Grenada*/
replace cc_q13_norm=. if country=="Grenada" /*Grenada*/
replace cc_q10_norm=. if country=="Grenada" /*Grenada*/
replace cj_q38_norm=. if country=="Grenada" /*Grenada*/
replace cj_q22e_norm=. if country=="Grenada" /*Grenada*/
replace cj_q6b_norm=. if country=="Grenada" /*Grenada*/
replace cj_q6d_norm=. if country=="Grenada" /*Grenada*/
replace cj_q42c_norm=. if country=="Grenada" /*Grenada*/
replace cj_q42d_norm=. if country=="Grenada" /*Grenada*/
replace cj_q3a_norm=. if country=="Grenada" /*Grenada*/
replace lb_q2d_norm=. if country=="Grenada" /*Grenada*/
replace all_q76_norm=. if country=="Grenada" /*Grenada*/
replace cj_q24c_norm=. if country=="Grenada" /*Grenada*/
replace all_q1_norm=. if id_alex=="cc_English_1_1108_2018_2019_2021" //Grenada
replace all_q2_norm=. if id_alex=="cc_English_1_1108_2018_2019_2021" //Grenada
replace all_q20_norm=. if id_alex=="cc_English_1_1108_2018_2019_2021" //Grenada
replace all_q1_norm=. if id_alex=="lb_English_0_589" //Grenada
replace all_q1_norm=. if id_alex=="cc_English_1_1471" //Grenada
replace all_q2_norm=. if id_alex=="cc_English_1_1471" //Grenada
replace all_q3_norm=. if id_alex=="cc_English_1_1471" //Grenada
replace all_q4_norm=. if id_alex=="cc_English_1_1471" //Grenada
replace all_q5_norm=. if id_alex=="cc_English_1_1471" //Grenada
replace all_q6_norm=. if id_alex=="cc_English_1_1471" //Grenada
replace all_q7_norm=. if id_alex=="cc_English_1_1471" //Grenada
replace all_q8_norm=. if id_alex=="cc_English_1_1471" //Grenada
replace cc_q25_norm=. if id_alex=="cc_English_1_1471" //Grenada
replace all_q13_norm=. if id_alex=="cc_English_1_1117" //Grenada
replace all_q14_norm=. if id_alex=="cc_English_1_1117" //Grenada
replace all_q15_norm=. if id_alex=="cc_English_1_1117" //Grenada
replace all_q16_norm=. if id_alex=="cc_English_1_1117" //Grenada
replace all_q17_norm=. if id_alex=="cc_English_1_1117" //Grenada
replace all_q18_norm=. if id_alex=="cc_English_1_1117" //Grenada
replace all_q19_norm=. if id_alex=="cc_English_1_1117" //Grenada
replace all_q20_norm=. if id_alex=="cc_English_1_1117" //Grenada
replace all_q21_norm=. if id_alex=="cc_English_1_1117" //Grenada
replace all_q31_norm=. if id_alex=="cc_English_1_1117" //Grenada
replace all_q32_norm=. if id_alex=="cc_English_1_1117" //Grenada
replace all_q13_norm=. if id_alex=="cc_English_1_1108_2018_2019_2021" //Grenada
replace all_q14_norm=. if id_alex=="cc_English_1_1108_2018_2019_2021" //Grenada
replace all_q15_norm=. if id_alex=="cc_English_1_1108_2018_2019_2021" //Grenada
replace all_q16_norm=. if id_alex=="cc_English_1_1108_2018_2019_2021" //Grenada
replace all_q17_norm=. if id_alex=="cc_English_1_1108_2018_2019_2021" //Grenada
replace all_q18_norm=. if id_alex=="cc_English_1_1108_2018_2019_2021" //Grenada
replace all_q19_norm=. if id_alex=="cc_English_1_1108_2018_2019_2021" //Grenada
replace all_q20_norm=. if id_alex=="cc_English_1_1108_2018_2019_2021" //Grenada
replace all_q21_norm=. if id_alex=="cc_English_1_1108_2018_2019_2021" //Grenada
replace all_q31_norm=. if id_alex=="cc_English_1_1108_2018_2019_2021" //Grenada
replace all_q32_norm=. if id_alex=="cc_English_1_1108_2018_2019_2021" //Grenada
replace cj_q31e_norm=. if id_alex=="cj_English_1_547_2018_2019_2021" //Grenada
replace cj_q21h_norm=. if id_alex=="cj_English_0_1137" //Grenada
replace cj_q28_norm=. if id_alex=="cj_English_0_1137" //Grenada
replace cc_q9c_norm=. if id_alex=="cc_English_0_1548_2016_2017_2018_2019_2021" //Grenada
replace cc_q40a_norm=. if id_alex=="cc_English_0_1548_2016_2017_2018_2019_2021" //Grenada
replace cc_q40b_norm=. if id_alex=="cc_English_0_1548_2016_2017_2018_2019_2021" //Grenada
replace cc_q9c_norm=. if id_alex=="cc_English_1_1108_2018_2019_2021" //Grenada
replace cc_q40a_norm=. if id_alex=="cc_English_1_1108_2018_2019_2021" //Grenada
replace cc_q40b_norm=. if id_alex=="cc_English_1_1108_2018_2019_2021" //Grenada
replace cj_q31g_norm=. if id_alex=="cj_English_0_1137" //Grenada
replace cj_q10_norm=0 if id_alex=="cj_English_0_1137" //Grenada
replace all_q29_norm=. if id_alex=="cc_English_1_1377" //Grenada
replace cc_q9c_norm=. if id_alex=="cc_English_1_1145_2018_2019_2021" //Guyana
replace cc_q40b_norm=. if id_alex=="cc_English_0_834_2016_2017_2018_2019_2021" //Guyana
replace cc_q40b_norm=. if id_alex=="cc_English_0_981" //Guyana
replace cc_q14b_norm=. if country=="Guyana" //Guyana
replace cc_q10_norm=. if id_alex=="cc_English_0_1606_2019_2021" //Guayana
replace cc_q10_norm=. if id_alex=="cc_English_0_359" //Guayana
replace cc_q16a_norm=. if id_alex=="cc_English_0_359" //Guayana
replace cc_q16a_norm=. if id_alex=="cc_English_0_981" //Guayana
replace cc_q16d_norm=. if id_alex=="cc_English_1_1145_2018_2019_2021" //Guayana
replace cc_q16d_norm=. if id_alex=="cc_English_0_981" //Guayana
replace all_q70_norm=. if country=="Guyana" //Guyana
replace all_q86_norm=. if id_alex=="cc_English_1_743" //Guyana
replace all_q87_norm=. if id_alex=="cc_English_1_743" //Guyana
replace cj_q20o_norm=. if id_alex=="cj_English_0_1110_2021" //Guyana
replace cc_q26b_norm=. if id_alex=="cc_English_0_1095_2017_2018_2019_2021" //Guyana
drop if id_alex=="ph_English_1_185_2016_2017_2018_2019_2021" //Jamaica
drop if id_alex=="cj_English_0_524" //Jamaica
replace cc_q25_norm=. if country=="Jamaica" /*Jamaica*/
replace all_q5_norm=. if country=="Jamaica" /*Jamaica*/
replace all_q1_norm=. if country=="Jamaica" /*Jamaica*/
replace all_q20_norm=. if country=="Jamaica" /*Jamaica*/
replace cj_q40c_norm=. if country=="Jamaica"  /*Jamaica*/
replace cj_q20m_norm=. if country=="Jamaica"  /*Jamaica*/
replace cj_q12c_norm=. if country=="Jamaica" /*Jamaica*/
replace cj_q31f_norm=. if id_alex=="cj_English_1_1064_2021" //Jamaica
replace cj_q31g_norm=. if id_alex=="cj_English_1_1064_2021" //Jamaica
replace cj_q25c_norm=. if country=="Jamaica"
replace cj_q22e_norm=. if country=="Jamaica"
replace all_q96_norm=. if id_alex=="lb_English_1_266_2021" //Jamaica
replace all_q96_norm=. if id_alex=="lb_English_1_183" //Jamaica
replace all_q96_norm=. if id_alex=="cj_English_0_148_2021" //Jamaica
replace all_q96_norm=. if id_alex=="cj_English_0_180_2021" //Jamaica
replace all_q97_norm=. if id_alex=="cc_English_1_812_2018_2019_2021" //Jamaica
replace all_q97_norm=. if id_alex=="lb_English_1_266_2021" //Jamaica
replace all_q95_norm=. if id_alex=="lb_English_1_266_2021" //Jamaica
replace lb_q2d_norm=. if id_alex=="lb_Spanish_0_221" //Peru
replace lb_q2d_norm=. if id_alex=="lb_Spanish_1_490" //Peru
replace lb_q3d_norm=. if id_alex=="lb_Spanish_1_490" //Peru
replace cj_q20m_norm=. if id_alex=="cj_Spanish_0_506" //Peru
replace cj_q40b_norm=. if id_alex=="cj_Spanish_0_506" //Peru
replace cj_q40c_norm=. if id_alex=="cj_Spanish_0_506" //Peru
replace cj_q20m_norm=. if id_alex=="cj_Spanish_0_1026_2021" //Peru
replace cj_q40b_norm=. if id_alex=="cj_Spanish_0_1026_2021" //Peru
replace cj_q40c_norm=. if id_alex=="cj_Spanish_0_1026_2021" //Peru
replace cj_q25a_norm=. if id_alex=="cj_Spanish_0_506" //Peru
replace cj_q25b_norm=. if id_alex=="cj_Spanish_0_506" //Peru
replace cj_q25c_norm=. if id_alex=="cj_Spanish_0_506" //Peru
replace cj_q16l_norm=. if id_alex=="cj_Spanish_0_506" //Peru
replace cj_q16m_norm=. if id_alex=="cj_Spanish_0_506" //Peru

replace all_q22_norm=1 if id_alex=="lb_Spanish_0_526" //Peru
replace all_q23_norm=1 if id_alex=="lb_Spanish_0_526" //Peru
replace all_q24_norm=1 if id_alex=="lb_Spanish_0_526" //Peru
replace all_q25_norm=1 if id_alex=="lb_Spanish_0_526" //Peru
replace all_q26_norm=1 if id_alex=="lb_Spanish_0_526" //Peru
replace all_q27_norm=1 if id_alex=="lb_Spanish_0_526" //Peru
replace all_q8_norm=1 if id_alex=="lb_Spanish_0_526" //Peru
replace all_q22_norm=. if id_alex=="cj_Spanish_1_673" //Peru
replace all_q23_norm=. if id_alex=="cj_Spanish_1_673" //Peru
replace all_q24_norm=. if id_alex=="cj_Spanish_1_673" //Peru
replace all_q25_norm=. if id_alex=="cj_Spanish_1_673" //Peru
replace all_q26_norm=. if id_alex=="cj_Spanish_1_673" //Peru
replace all_q27_norm=. if id_alex=="cj_Spanish_1_673" //Peru
replace all_q8_norm=. if id_alex=="cj_Spanish_1_673" //Peru
replace all_q22_norm=. if id_alex=="cc_Spanish_1_1176" //Peru
replace all_q23_norm=. if id_alex=="cc_Spanish_1_1176" //Peru
replace all_q24_norm=. if id_alex=="cc_Spanish_1_1176" //Peru
replace all_q25_norm=. if id_alex=="cc_Spanish_1_1176" //Peru
replace all_q26_norm=. if id_alex=="cc_Spanish_1_1176" //Peru
replace all_q27_norm=. if id_alex=="cc_Spanish_1_1176" //Peru
replace all_q8_norm=. if id_alex=="cc_Spanish_1_1176" //Peru
replace all_q23_norm=. if id_alex=="cc_Spanish_1_406_2016_2017_2018_2019_2021" //Peru
drop if id_alex=="cc_English_0_586_2017_2018_2019_2021" //St. Kitts and Nevis
drop if id_alex=="cj_English_0_603" //St. Kitts and Nevis
replace all_q89_norm=. if country=="St. Kitts and Nevis" /* St. Kitts and Nevis */
replace all_q90_norm=. if country=="St. Kitts and Nevis" /* St. Kitts and Nevis */
replace all_q85_norm=. if id_alex=="lb_English_0_162_2016_2017_2018_2019_2021" //St. Kitts and Nevis
replace cc_q13_norm=. if id_alex=="cc_English_1_1114_2021" //St. Kitts and Nevis
replace all_q88_norm=. if id_alex=="lb_English_0_162_2016_2017_2018_2019_2021" //St. Kitts and Nevis
replace cc_q33_norm=. if id_alex=="cc_English_0_1777_2019_2021" //St. Kitts and Nevis
replace cc_q12_norm=. if country=="St. Kitts and Nevis" /* St. Kitts and Nevis */
drop if id_alex=="cc_English_0_1298_2016_2017_2018_2019_2021" // St. Lucia
replace cc_q29b_norm=. if country=="St. Lucia" /* St. Lucia */
replace all_q71_norm=. if id_alex=="cc_English_0_1074" /* St. Lucia */
replace all_q71_norm=. if id_alex=="lb_English_1_629_2018_2019_2021" /* St. Lucia */
replace all_q72_norm=. if id_alex=="cc_English_0_1752" /* St. Lucia */
replace cc_q22a_norm=. if id_alex=="cc_English_1_1427" /* St. Lucia */
replace cc_q22a_norm=. if id_alex=="cc_English_0_1752" /* St. Lucia */
replace cc_q22b_norm=. if id_alex=="cc_English_1_1427" /* St. Lucia */
replace cc_q14a_norm=. if id_alex=="cc_English_1_1427" /* St. Lucia */
replace cc_q14b_norm=. if id_alex=="cc_English_1_1427" /* St. Lucia */
replace all_q96_norm=. if id_alex=="cj_English_1_923_2018_2019_2021" /* St. Lucia */
replace all_q96_norm=. if id_alex=="cj_English_0_619_2019_2021" /* St. Lucia */
replace all_q96_norm=0 if id_alex=="cc_English_0_1711_2021" /* St. Lucia */
drop if id_alex=="cc_English_0_1382" /* St. Vincent and the Grenadines */
drop if id_alex=="cc_English_0_628_2016_2017_2018_2019_2021" /* St. Vincent and the Grenadines */
replace all_q90_norm=. if country=="St. Vincent and the Grenadines" /* St. Vincent and the Grenadines */
replace all_q91_norm=. if country=="St. Vincent and the Grenadines" /* St. Vincent and the Grenadines */
replace all_q78_norm=. if country=="St. Vincent and the Grenadines" /* St. Vincent and the Grenadines */
replace all_q86_norm=. if id_alex=="cc_English_0_628_2016_2017_2018_2019_2021" /* St. Vincent and the Grenadines */
replace all_q86_norm=. if id_alex=="lb_English_0_579" /* St. Vincent and the Grenadines */
replace cc_q33_norm=. if country=="St. Vincent and the Grenadines" /* St. Vincent and the Grenadines */
replace all_q23_norm=. if country=="St. Vincent and the Grenadines" /* St. Vincent and the Grenadines */
replace cj_q25c_norm=. if country=="St. Vincent and the Grenadines" /* St. Vincent and the Grenadines */
replace cj_q31d_norm=. if country=="St. Vincent and the Grenadines" /* St. Vincent and the Grenadines */
replace cj_q22c_norm=. if country=="St. Vincent and the Grenadines" /* St. Vincent and the Grenadines */
replace all_q63_norm=. if country=="St. Vincent and the Grenadines" /* St. Vincent and the Grenadines */
replace all_q48_norm=. if country=="St. Vincent and the Grenadines" /* St. Vincent and the Grenadines */
replace all_q21_norm=. if country=="St. Vincent and the Grenadines" /* St. Vincent and the Grenadines */
replace cc_q40b_norm=. if country=="St. Vincent and the Grenadines" /* St. Vincent and the Grenadines */
replace all_q19_norm=. if country=="St. Vincent and the Grenadines" /* St. Vincent and the Grenadines */
replace lb_q23f_norm=. if id_alex=="lb_English_0_579" /* St. Vincent and the Grenadines */
replace lb_q23g_norm=. if id_alex=="lb_English_0_530" /* St. Vincent and the Grenadines */
replace lb_q23c_norm=. if country=="St. Vincent and the Grenadines" /* St. Vincent and the Grenadines */
replace lb_q15b_norm=. if country=="St. Vincent and the Grenadines" /* St. Vincent and the Grenadines */
replace lb_q15c_norm=. if country=="St. Vincent and the Grenadines" /* St. Vincent and the Grenadines */
replace cc_q29a_norm=. if country=="St. Vincent and the Grenadines" /* St. Vincent and the Grenadines */
replace all_q55_norm=. if country=="St. Vincent and the Grenadines" /* St. Vincent and the Grenadines */
replace all_q77_norm=. if country=="St. Vincent and the Grenadines" /* St. Vincent and the Grenadines */
replace all_q79_norm=. if country=="St. Vincent and the Grenadines" /* St. Vincent and the Grenadines */
replace all_q96_norm=1 if id_alex=="lb_English_1_124_2017_2018_2019_2021" /* St. Vincent and the Grenadines */
replace all_q89_norm=0.6666667 if id_alex=="lb_English_0_530" /* St. Vincent and the Grenadines */
replace cj_q21a_norm=. if id_alex=="cj_English_0_250_2021" /* St. Vincent and the Grenadines */
replace cj_q21e_norm=. if id_alex=="cj_English_0_250_2021" /* St. Vincent and the Grenadines */
replace cj_q21g_norm=. if id_alex=="cj_English_0_250_2021" /* St. Vincent and the Grenadines */
replace cj_q21h_norm=. if id_alex=="cj_English_0_250_2021" /* St. Vincent and the Grenadines */
replace cj_q12d_norm=. if id_alex=="cj_English_0_250_2021" /* St. Vincent and the Grenadines */
replace cj_q12f_norm=. if id_alex=="cj_English_0_250_2021" /* St. Vincent and the Grenadines */
replace cj_q40b_norm=. if id_alex=="cj_English_0_250_2021" /* St. Vincent and the Grenadines */
replace cj_q40c_norm=. if id_alex=="cj_English_0_250_2021" /* St. Vincent and the Grenadines */
replace all_q62_norm=. if id_alex=="lb_English_0_476_2016_2017_2018_2019_2021" /* St. Vincent and the Grenadines */
replace all_q50_norm=. if id_alex=="lb_English_0_579" /* St. Vincent and the Grenadines */
replace cc_q9c_norm=. if id_alex=="cc_English_0_1475" /* St. Vincent and the Grenadines */
replace all_q96_norm=. if id_alex=="cc_English_1_1489_2019_2021" /* St. Vincent and the Grenadines */
drop if id_alex=="cc_Spanish (Mexico)_0_586_2019_2021" //Venezuela 
drop if id_alex=="cc_Spanish_1_633" //Venezuela
drop if id_alex=="cj_Spanish_1_1141" //Venezuela
replace all_q96_norm=. if id_alex=="cj_Spanish_1_838_2019_2021" //Venezuela
replace all_q96_norm=. if id_alex=="cj_Spanish_0_570_2016_2017_2018_2019_2021" //Venezuela
replace all_q96_norm=. if id_alex=="cc_English_0_1193_2016_2017_2018_2019_2021" //Venezuela

br question year country longitudinal id_alex total_score f_1 f_2 f_3 f_4 f_6 f_7 f_8 if country=="France"

*drop if year<2019 & country~="Antigua and Barbuda" & country~="Dominica" & country~="St. Lucia"

drop total_score_mean
bysort country: egen total_score_mean=mean(total_score)

save "$path2data/3. Final/qrq_${year_current}.dta", replace


/*-----------------------------------------------------*/
/* Number of surveys per discipline, year, and country */
/*-----------------------------------------------------*/
gen aux_cc=1 if question=="cc"
gen aux_cj=1 if question=="cj"
gen aux_lb=1 if question=="lb"
gen aux_ph=1 if question=="ph"

local i=2013
	while `i'<=2022 {
		gen aux_cc_`i'=1 if question=="cc" & year==`i'
		gen aux_cj_`i'=1 if question=="cj" & year==`i'
		gen aux_lb_`i'=1 if question=="lb" & year==`i'
		gen aux_ph_`i'=1 if question=="ph" & year==`i'
	local i=`i'+1 
}	

gen aux_cc_22_long=1 if question=="cc" & year==2022 & longitudinal==1
gen aux_cj_22_long=1 if question=="cj" & year==2022 & longitudinal==1
gen aux_lb_22_long=1 if question=="lb" & year==2022 & longitudinal==1
gen aux_ph_22_long=1 if question=="ph" & year==2022 & longitudinal==1

bysort country: egen cc_total=total(aux_cc)
bysort country: egen cj_total=total(aux_cj)
bysort country: egen lb_total=total(aux_lb)
bysort country: egen ph_total=total(aux_ph)

local i=2013
	while `i'<=2022 {
		bysort country: egen cc_total_`i'=total(aux_cc_`i')
		bysort country: egen cj_total_`i'=total(aux_cj_`i')
		bysort country: egen lb_total_`i'=total(aux_lb_`i')
		bysort country: egen ph_total_`i'=total(aux_ph_`i')
	local i=`i'+1 
}	

bysort country: egen cc_total_2022_long=total(aux_cc_22_long)
bysort country: egen cj_total_2022_long=total(aux_cc_22_long)
bysort country: egen lb_total_2022_long=total(aux_cc_22_long)
bysort country: egen ph_total_2022_long=total(aux_cc_22_long)

egen tag = tag(country)
br country cc_total-ph_total_2022_long if tag==1

drop  aux_cc-tag

*----- Saving original dataset AFTER adjustments

save "C:\Users\nrodriguez\OneDrive - World Justice Project\Programmatic\Data Analytics\8. Data\QRQ\QRQ_${year_current}_clean.dta", replace


/*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
/*------------------*/
/* Country Averages */
/*------------------*/
foreach var of varlist cc_q1_norm- all_q105_norm {
	bysort country: egen CO_`var'=mean(`var')
}

egen tag = tag(country)
keep if tag==1
drop cc_q1- all_q105_norm //cc_q6a_usd cc_q6a_gni

rename CO_* *
drop tag
drop question id_alex language
sort country

drop wjp_login longitudinal year regular
drop total_score- total_score_mean

drop cj_q43a_norm-cj_q43h_norm
order wjp_password, last //cc_q6a_usd cc_q6a_gni 
drop wjp_password


*Create scores
do "C:\Users\nrodriguez\OneDrive - World Justice Project\Natalia\GitHub\ROLI_2024\1. Cleaning\QRQ\2. Code\Routines\scores.do"

*Saving scores in 2022 folder for analysis
save "$path2data/3. Final/qrq_country_averages_${year_current}.dta", replace

*Saving scores in 2023 folder for analysis
save "C:\Users\nrodriguez\OneDrive - World Justice Project\Programmatic\Data Analytics\7. WJP ROLI\ROLI_2023\1. Cleaning\QRQ\1. Data\3. Final\qrq_country_averages_${year_current}.dta", replace


br





