---
layout: default
title: Reshaping Data from Long to Wide (or Wide to Long)
nav_order: 4
parent: NCDS
format:
  gfm:
    variant: +yaml_metadata_block
jupyter: stata
---


- [Download the Stata script for this
  page](../do_files/ncds-reshape_long_wide.do)

# Introduction

In this section, we show how to reshape data from long to wide (and vice
versa). To demonstrate, we use data from Sweeps 4 (23y) and 8 (50y) on
cohort member’s height and weight collected.

The commands we use are:

``` stata
clear all
set more off
```

# Reshaping Raw Data from Wide to Long

We begin by loading the data from each sweep and merging these together
into a single *wide* format data frame; see [Combining Data Across
Sweeps](https://cls-data.github.io/docs/ncds-merging_across_sweeps.html)
for further explanation on how this is achieved. Note, the names of the
height and weight variables in Sweep 4 and Sweep 8 follow a similar
convention, which is the exception rather than the rule in NCDS data.
Below, we convert the variable names in the Sweep 4 data frame to upper
case so that they closely match those in the Sweep 8 dataset. This will
make reshaping easier.

``` stata
* Load 23y data
use ncdsid dvwt23 dvht23 using "23y/ncds4.dta", clear
rename *, upper
save "temp_23y.dta", replace

* Load 50y data
use NCDSID DVWT50 DVHT50 using "50y/ncds_2008_followup.dta", clear
save "temp_50y.dta", replace

* Merge
use "temp_23y.dta", clear
merge 1:1 NCDSID using "temp_50y.dta"
keep if _merge == 3 // Keeps matches. `merge ..., keep(3)` would also work.
drop _merge
```




    file temp_23y.dta saved


    file temp_50y.dta saved



        Result                      Number of obs
        -----------------------------------------
        Not matched                         5,701
            from master                     4,224  (_merge==1)
            from using                      1,477  (_merge==2)

        Matched                             8,313  (_merge==3)
        -----------------------------------------

    (5,701 observations deleted)

We can reshape the dataset into wide format using `reshape long`. This
requires variables to be named in a specific format: `stub` + `suffix`.
Here, we want our stubs to be `DVWT` and `DVHT`, and our suffixes to be
the sweep numbers (23 and 50). We can do this using `rename` with the
`*` wildcard operator. Then in the `reshape long` command, we specify
the stubs in the main command, with the identifier and suffix variables
specified in the `i()` and `j()` command options respectively. Note the
identifier (`i()`) exists in the data, while the suffix variable (`j()`)
is created during the reshape process.

``` stata
reshape long DVHT DVWT, i(NCDSID) j(fup)
list * in 1/10
```


    (j = 23 50)

    Data                               Wide   ->   Long
    -----------------------------------------------------------------------------
    Number of observations            8,313   ->   16,626      
    Number of variables                   5   ->   4           
    j variable (2 values)                     ->   fup
    xij variables:
                              DVHT23 DVHT50   ->   DVHT
                              DVWT23 DVWT50   ->   DVWT
    -----------------------------------------------------------------------------


         +---------------------------------------+
         |  NCDSID   fup        DVHT        DVWT |
         |---------------------------------------|
      1. | N10001N    23   1.6259995    59.42099 |
      2. | N10001N    50           .       66.67 |
      3. | N10002P    23   1.9049997   73.482986 |
      4. | N10002P    50           .       79.37 |
      5. | N10007U    23   1.6259995   52.163986 |
         |---------------------------------------|
      6. | N10007U    50           .       72.11 |
      7. | N10009W    23   1.7269993   66.678986 |
      8. | N10009W    50         1.7          78 |
      9. | N10011Q    23   1.6759996   63.503998 |
     10. | N10011Q    50         1.7          95 |
         +---------------------------------------+

# Reshaping Raw Data from Long to Wide

We can reshape the data from long to wide format using the
`reshape wide` command. We again specify the stubs in the main command,
and the identifier and suffix variables in `i()` and `j()`,
respectively. The suffix variable exists in the data, but the value of
this are used to create new variable names during the reshape process.

``` stata
reshape wide DVHT DVWT, i(NCDSID) j(fup)
list * in 1/10
```


    (j = 23 50)

    Data                               Long   ->   Wide
    -----------------------------------------------------------------------------
    Number of observations           16,626   ->   8,313       
    Number of variables                   4   ->   5           
    j variable (2 values)               fup   ->   (dropped)
    xij variables:
                                       DVHT   ->   DVHT23 DVHT50
                                       DVWT   ->   DVWT23 DVWT50
    -----------------------------------------------------------------------------


         +---------------------------------------------------+
         |  NCDSID      DVHT23      DVWT23   DVHT50   DVWT50 |
         |---------------------------------------------------|
      1. | N10001N   1.6259995    59.42099        .    66.67 |
      2. | N10002P   1.9049997   73.482986        .    79.37 |
      3. | N10007U   1.6259995   52.163986        .    72.11 |
      4. | N10009W   1.7269993   66.678986      1.7       78 |
      5. | N10011Q   1.6759996   63.503998      1.7       95 |
         |---------------------------------------------------|
      6. | N10012R   1.9559994     114.306        .   133.33 |
      7. | N10013S   1.7779999    83.46199        .    95.24 |
      8. | N10014T   1.5489998      57.153        .    63.49 |
      9. | N10015U   1.8029995   73.028992        .       78 |
     10. | N10016V   1.7019997   63.503998        .    70.75 |
         +---------------------------------------------------+
