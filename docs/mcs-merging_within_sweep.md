---
layout: default
title: Combining Data Within A Sweep
nav_order: 6
parent: MCS
format:
  gfm:
    variant: +yaml_metadata_block
jupyter: stata
---


- [Download the Stata script for this
  page](../do_files/mcs-merging_within_sweep.do)

# Introduction

In this section, we show how to merge, collapse and reshape the various
data structures within a given sweep of the Millennium Cohort Study
(MCS) to create a dataset at the cohort member-level (i.e., one row per
cohort member). This is likely to be the most useful data structure for
most analyses, but similar principles can be applied to create other
structures as needed (e.g., family-level datasets).

We use the following commands:

``` stata
clear all
set more off
```

# Data Cleaning

We create a small dataset that contains information from Sweep 2 on:
family country of residence, cohort member’s ethnicity, whether any
parent reads to the child, the warmth of the relationship between the
parent and the child, family social class (National Statistics
Socio-economic Classification; NS-SEC), and mother’s highest education
level. Constructing and combining these variables involves restructing
the data in various ways, and spans the most common data engineering
tasks involved in bringing together information from a single sweep.

We begin with the simplest variables: cohort member’s ethnicity and
family country of residence. Cohort member’s ethnicity is stored in a
cohort-member level dataset already (`mcs2_cm_derived`), so it does not
need further processing. Below we rename the relevant variables and
select it along with the cohort member identifiers, `MCSID` and
`BCNUM00`.

``` stata
use MCSID BCNUM00 BDC08E00 using "3y/mcs2_cm_derived.dta", clear
rename BDC08E00 ethnic_group
save "df_ethnic_group.dta", replace
```




    (file df_ethnic_group.dta not found)
    file df_ethnic_group.dta saved

Family country of residence is stored in a family-level dataset
(`mcs2_family_derived`). This also does not need any further processing
at this stage. Later when we merging this data with `df_ethnic_group`,
we perform a many-to-1 merge, so the data will be automatically repeated
for cases where there are multiple cohort members in a family.

``` stata
use MCSID BACTRY00 using "3y/mcs2_family_derived.dta", clear
rename BACTRY00 country
save "df_country.dta", replace
```




    (file df_country.dta not found)
    file df_country.dta saved

Next, we create a variable that indicates whether *any* parent reads to
the cohort member; in other words, we create a summary variable using
data from individual parents. The `mcs2_parent_cm_interview` dataset
contains a variable for the parent’s reading habit to a given child
(`BPOFRE00`). We first create a binary variable that indicates whether
the parent reads to the cohort member at least once a week, and then
create a summary variable indicating whether any (interviewed) parent
reads (`(max) parent_reads`) by collapsing the data using `collapse`
with the `by()` option to ensure this is calculated per cohort member
(`by(MCSID BCNUM00)`).

``` stata
use MCSID BPNUM00 BCNUM00 BPOFRE00 using "3y/mcs2_parent_cm_interview.dta", clear
gen parent_reads = 1 if inrange(BPOFRE00, 1, 3)
replace parent_reads = 0 if inrange(BPOFRE00, 4, 6)
drop if missing(parent_reads)
collapse (max) parent_reads, by(MCSID BCNUM00)
save "df_reads.dta", replace
```



    (3,562 missing values generated)

    (3,543 real changes made)

    (19 observations deleted)


    (file df_reads.dta not found)
    file df_reads.dta saved

We next show a different way of using `mcs2_parent_cm_interview`,
reshaping the data from long to wide so that we have one row per cohort
member. As an example, we create separate variables for whether the
responding parent has a warm relationship with the cohort member
(`BPPIAW00`), one using responses from the main carer and one from the
secondary carer. As `mcs2_parent_cm_interview` have one row per parent x
cohort member combination, we first create a variable indicating which
parent is which (using information from `BELIG00`), and then reshape the
warmth variable from [long to wide using
`reshape wide`](https://www.stata.com/manuals/dreshape.pdf).

``` stata
use MCSID BCNUM00 BELIG00 BPPIAW00 using "3y/mcs2_parent_cm_interview.dta", clear
gen warmth = 0 if inrange(BPPIAW00, 1, 6)
replace warmth = 1 if BPPIAW00 == 5
gen var_name = "main" if BELIG00 == 1
replace var_name = "secondary" if BELIG00 != 1
keep MCSID BCNUM00 var_name warmth
reshape wide warmth, i(MCSID BCNUM00) j(var_name) string
rename warmth* warmth_*
save "df_warm.dta", replace
```



    (2,153 missing values generated)

    (22,325 real changes made)

    (10,612 missing values generated)

    variable var_name was str4 now str9
    (10,612 real changes made)


    (j = main secondary)

    Data                               Long   ->   Wide
    -----------------------------------------------------------------------------
    Number of observations           26,243   ->   15,694      
    Number of variables                   4   ->   4           
    j variable (2 values)          var_name   ->   (dropped)
    xij variables:
                                     warmth   ->   warmthmain warmthsecondary
    -----------------------------------------------------------------------------


    (file df_warm.dta not found)
    file df_warm.dta saved

Next, we show an example of creating family level data using data from
individual parents; in this case, a variable for family social class
(NS-SEC) using data from `mcs2_parent_derived`. As `mcs2_parent_derived`
is a parent level dataset, we take the minimum of parents’ NS-SEC
(`BDD05S00`) within a family (lower values of `BDD05S00` indicate higher
social class).

``` stata
use MCSID BPNUM00 BDD05S00 using "3y/mcs2_parent_derived.dta", clear
rename BDD05S00 parent_nssec
replace parent_nssec = . if parent_nssec < 0
drop if missing(parent_nssec)
collapse (min) family_nssec = parent_nssec, by(MCSID)
save "df_nssec.dta", replace
```




    (11,205 real changes made, 11,205 to missing)

    (11,205 observations deleted)


    (file df_nssec.dta not found)
    file df_nssec.dta saved

Finally, we create a variable for the mother’s highest education level
using the `mcs2_parent_derived` dataset. This involves merging in
relationship information from the household grid and subsetting the rows
so we are left with data for mothers only (see [*Working with the
Household
Grid*](https://cls-data.github.io/docs/mcs-household_grid.html). We
separately filter the household grid for mothers only
(`BHCREL00 == 7 Natural Parent` and `BHPSEX00 == 2 [Female]`) and select
the highest education level variable (`BDDNVQ00`) from the
`mcs2_parent_derived` dataset. We then merge the datasets together use
`merge`.

``` stata
use MCSID BPNUM00 BHCREL00 BHPSEX00 using "3y/mcs2_hhgrid.dta", clear
keep if inrange(BPNUM00, 1, 99) & BHCREL00 == 7 & BHPSEX00 == 2
duplicates drop MCSID BPNUM00, force
bysort MCSID: gen n = _N
keep if n == 1 // Keep just one mother per family
keep MCSID BPNUM00
save "temp_mothers.dta", replace

use MCSID BPNUM00 BDDNVQ00 using "3y/mcs2_parent_derived.dta", clear
rename BDDNVQ00 mother_nvq
merge 1:1 MCSID BPNUM00 using "temp_mothers.dta", keep(using match)
drop BPNUM00
save "df_mother_edu.dta", replace
```



    (53,733 observations deleted)


    Duplicates in terms of MCSID BPNUM00

    (0 observations are duplicates)


    (2 observations deleted)


    file temp_mothers.dta saved



    (variable BPNUM00 was byte, now int to accommodate using data's values)

        Result                      Number of obs
        -----------------------------------------
        Not matched                            70
            from master                         0  (_merge==1)
            from using                         70  (_merge==2)

        Matched                            15,399  (_merge==3)
        -----------------------------------------


    (file df_mother_edu.dta not found)
    file df_mother_edu.dta saved

# Merging the Datasets

Now we have cleaned each variable, we can merge them together. The
cleaned datasets are either at the family level (`df_country`,
`df_nssec`, `df_mother_edu`) or cohort member level (`df_ethnic_group`,
`df_reads`, `df_warm`). We begin with `df_ethnic_group` as this has all
the cohort members participating at Sweep 2 in it. We then use `merge`
to merge in other data. To merge with a family-level dataset, we use
`merge m:1 MCSID` as `MCSID` is the unique identifier for each cohort
member. For the cohort member level datasets, we use
`merge 1:1 MCSID BCNUM00` as the combination of `MCSID` and `BCNUM00`
uniquely identifies cohort members. The `nogenerate` option ensures that
Stata does not create the `_merge` variable, and the
`keep(master match)` option keeps only observations from the master
(already open) dataset; note, doing this successively, means we keep all
rows in `df_ethnic_group.dta`.

``` stata
use "df_ethnic_group.dta", clear
merge m:1 MCSID using "df_country.dta", keep(master match) nogenerate
merge m:1 MCSID using "df_nssec.dta", keep(master match) nogenerate
merge m:1 MCSID using "df_mother_edu.dta", keep(master match) nogenerate
merge 1:1 MCSID BCNUM00 using "df_reads.dta", keep(master match) nogenerate
merge 1:1 MCSID BCNUM00 using "df_warm.dta", keep(master match) nogenerate
list in 1/10
```




        Result                      Number of obs
        -----------------------------------------
        Not matched                             3
            from master                         3  
            from using                          0  

        Matched                            15,775  
        -----------------------------------------


        Result                      Number of obs
        -----------------------------------------
        Not matched                         4,021
            from master                     4,021  
            from using                          0  

        Matched                            11,757  
        -----------------------------------------


        Result                      Number of obs
        -----------------------------------------
        Not matched                           112
            from master                       112  
            from using                          0  

        Matched                            15,666  
        -----------------------------------------

    (label BCNUM00 already defined)

        Result                      Number of obs
        -----------------------------------------
        Not matched                            94
            from master                        94  
            from using                          0  

        Matched                            15,684  
        -----------------------------------------

    (label BCNUM00 already defined)

        Result                      Number of obs
        -----------------------------------------
        Not matched                            84
            from master                        84  
            from using                          0  

        Matched                            15,694  
        -----------------------------------------


         +----------------------------------------------------------------+
      1. |   MCSID |  BCNUM00 | ethnic~p |  country | family~c | mother~q |
         | M10001N | 1st Coho |    White |    Wales |        3 |  None of |
         |----------------------------------------------------------------|
         |        _merge   |   parent~s   |   warmth~n    |   warmth~y    |
         |   Matched (3)   |          1   |          .    |          .    |
         +----------------------------------------------------------------+

         +----------------------------------------------------------------+
      2. |   MCSID |  BCNUM00 | ethnic~p |  country | family~c | mother~q |
         | M10002P | 1st Coho |    White |    Wales |        2 | NVQ leve |
         |----------------------------------------------------------------|
         |        _merge   |   parent~s   |   warmth~n    |   warmth~y    |
         |   Matched (3)   |          1   |          1    |          1    |
         +----------------------------------------------------------------+

         +----------------------------------------------------------------+
      3. |   MCSID |  BCNUM00 | ethnic~p |  country | family~c | mother~q |
         | M10007U | 1st Coho |    White |    Wales |        5 | NVQ leve |
         |----------------------------------------------------------------|
         |        _merge   |   parent~s   |   warmth~n    |   warmth~y    |
         |   Matched (3)   |          1   |          0    |          1    |
         +----------------------------------------------------------------+

         +----------------------------------------------------------------+
      4. |   MCSID |  BCNUM00 | ethnic~p |  country | family~c | mother~q |
         | M10008V | 1st Coho |    White |  England |        1 |  None of |
         |----------------------------------------------------------------|
         |        _merge   |   parent~s   |   warmth~n    |   warmth~y    |
         |   Matched (3)   |          1   |          1    |          1    |
         +----------------------------------------------------------------+

         +----------------------------------------------------------------+
      5. |   MCSID |  BCNUM00 | ethnic~p |  country | family~c | mother~q |
         | M10008V | 2nd Coho |    White |  England |        1 |  None of |
         |----------------------------------------------------------------|
         |        _merge   |   parent~s   |   warmth~n    |   warmth~y    |
         |   Matched (3)   |          1   |          1    |          1    |
         +----------------------------------------------------------------+

         +----------------------------------------------------------------+
      6. |   MCSID |  BCNUM00 | ethnic~p |  country | family~c | mother~q |
         | M10011Q | 1st Coho |    Mixed |  England |        5 | NVQ leve |
         |----------------------------------------------------------------|
         |        _merge   |   parent~s   |   warmth~n    |   warmth~y    |
         |   Matched (3)   |          1   |          1    |          .    |
         +----------------------------------------------------------------+

         +----------------------------------------------------------------+
      7. |   MCSID |  BCNUM00 | ethnic~p |  country | family~c | mother~q |
         | M10014T | 1st Coho |    White | Scotland |        3 | NVQ leve |
         |----------------------------------------------------------------|
         |        _merge   |   parent~s   |   warmth~n    |   warmth~y    |
         |   Matched (3)   |          1   |          1    |          1    |
         +----------------------------------------------------------------+

         +----------------------------------------------------------------+
      8. |   MCSID |  BCNUM00 | ethnic~p |  country | family~c | mother~q |
         | M10015U | 1st Coho |    White |  England |        1 | NVQ leve |
         |----------------------------------------------------------------|
         |        _merge   |   parent~s   |   warmth~n    |   warmth~y    |
         |   Matched (3)   |          1   |          1    |          1    |
         +----------------------------------------------------------------+

         +----------------------------------------------------------------+
      9. |   MCSID |  BCNUM00 | ethnic~p |  country | family~c | mother~q |
         | M10016V | 1st Coho |    White | Northern |        3 | NVQ leve |
         |----------------------------------------------------------------|
         |        _merge   |   parent~s   |   warmth~n    |   warmth~y    |
         |   Matched (3)   |          1   |          1    |          1    |
         +----------------------------------------------------------------+

         +----------------------------------------------------------------+
     10. |   MCSID |  BCNUM00 | ethnic~p |  country | family~c | mother~q |
         | M10017W | 1st Coho | Not appl |  England |        . | Not appl |
         |----------------------------------------------------------------|
         |        _merge   |   parent~s   |   warmth~n    |   warmth~y    |
         |   Matched (3)   |          1   |          .    |          .    |
         +----------------------------------------------------------------+
