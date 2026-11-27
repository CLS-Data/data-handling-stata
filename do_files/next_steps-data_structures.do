clear all
set more off

* Missing Values
capture program drop negative_to_na
program define negative_to_na
	syntax varlist(numeric) [, GENerate(name)]
	if "`generate'" != "" {
		clonevar `generate' = `varlist'
		local varlist `generate'
	}
	recode `varlist' (min/-1 = .)
end

use NSID W1alceverYP using "safeguarded_eul/wave_one_lsype_young_person_2020.dta", clear
numlabel, add // Adds numeric values to value labels
tabulate W1alceverYP, missing // Raw variable
negative_to_na W1alceverYP, generate(alcever) // Stores the cleaned values in a new variable
tabulate alcever, missing // Cleaned variable
