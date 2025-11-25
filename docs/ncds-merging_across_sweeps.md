---
layout: default
title: Combining Data Across Sweeps
nav_order: 3
parent: NCDS
format:
  gfm:
    variant: +yaml_metadata_block
jupyter: stata
---


- [Download the Stata script for this
  page](../do_files/ncds-merging_across_sweeps.do)

# Introduction

In this section, we show how to combine NCDS data across sweeps.

As an example, we use data on cohort members’ weight. These are
contained in files which have one row per cohort-member. As a reminder,
we have organised the data files so that each sweep [has its own folder,
which is named according to the age of
follow-up](https://cls-data.github.io/docs/ncds-sweep_folders.html)
(e.g., 55y for the ninth major sweep).

We begin by combining data from the Sweeps 4 (23y) and Sweep 8 (50y),
showing how to combine these datasets in **wide** (one row per
observational unit) and **long** (multiple rows per observational unit)
formats by *merging* and *appending*, respectively. Because variable
names change between sweeps in unpredictable ways, it is not
straightforwardly possible to combine data from multiple sweeps
*programmatically* (as we are able to do for, e.g., the
[MCS](https://cls-data.github.io/docs/mcs-merging_across_sweeps.html)).

# Merging Across Sweeps

The variables `dvwt23` and `DVWT50` contains the weight of the cohort
member at Sweeps 4 (23y) and Sweep 8 (50y), respectively. Note, these
are derived variable which convert raw weight measurements into
kilograms. The variable names follow the same convention (with the
exception that at age 23y, lower case is used). This bucks the more
general case where conceptually similar variables have different
(potentially, non-descriptive) names, when combining data including
early sweeps.

We will use the `use ... using` command to read in the data from the two
sweeps, keeping only the variables we need (the identifier and weight
variables). We also rename the variables to upper case in the Sweep 4
(23y) dataset to ensure consistency.

``` stata
* Load 23y data
use ncdsid dvwt23 using "23y/ncds4.dta", clear
rename *, upper
save "temp_23y.dta", replace

* Load 50y data
use NCDSID DVWT50 using "50y/ncds_2008_followup.dta", clear
save "temp_50y.dta", replace
```




    (file temp_23y.dta not found)
    file temp_23y.dta saved


    (file temp_50y.dta not found)
    file temp_50y.dta saved

We can merge these datasets by row using the `merge` command. We specify
`1:1` to indicate a one-to-one merge on the identifier `NCDSID` - i.e.,
there is only one observation per cohort member (`NCDSID`) in each
dataset.

``` stata
use "temp_23y.dta", clear
merge 1:1 NCDSID using "temp_50y.dta"
list * in 1/10
```




        Result                      Number of obs
        -----------------------------------------
        Not matched                         5,701
            from master                     4,224  (_merge==1)
            from using                      1,477  (_merge==2)

        Matched                             8,313  (_merge==3)
        -----------------------------------------


         +------------------------------------------------+
         |  NCDSID      DVWT23   DVWT50            _merge |
         |------------------------------------------------|
      1. | N10001N    59.42099    66.67       Matched (3) |
      2. | N10002P   73.482986    79.37       Matched (3) |
      3. | N10004R   76.203995        .   Master only (1) |
      4. | N10007U   52.163986    72.11       Matched (3) |
      5. | N10009W   66.678986       78       Matched (3) |
         |------------------------------------------------|
      6. | N10011Q   63.503998       95       Matched (3) |
      7. | N10012R     114.306   133.33       Matched (3) |
      8. | N10013S    83.46199    95.24       Matched (3) |
      9. | N10014T      57.153    63.49       Matched (3) |
     10. | N10015U   73.028992       78       Matched (3) |
         +------------------------------------------------+

The `_merge` variable indicates the result of the merge: `1` means the
observation was only in the master dataset (23y), `2` means it was only
in the using dataset (50y), and `3` means it was in both.
`keep if _merge ...` can be used to keep certain observations if
required (e.g., `keep if _merge == 3` will retain a balance panel of
individuals appearing in both datasets). Alternatively,
`merge ..., keep(...)` can be used to achieve the same result.

# Appending Sweeps

To put the data into long format, we can use the `append` command. (In
this case, the data will have one row per cohort-member x sweep
combination.) To work properly, we need to name the variables
consistently across sweeps, which here means removing the age-specific
suffixes (e.g., the number `23` from `dvwt23`). We also need to add a
variable to identify the sweep the data comes from. Below, we use
`rename` to remove the suffixes and `gen` (short for `generate`) to
create a `sweep` variable.

``` stata
use "temp_23y.dta", clear
rename DVWT23 DVWT
gen sweep = 23
save "temp_23y_long.dta", replace

use "temp_50y.dta", clear
rename DVWT50 DVWT
gen sweep = 50
save "temp_50y_long.dta", replace
```





    (file temp_23y_long.dta not found)
    file temp_23y_long.dta saved




    (file temp_50y_long.dta not found)
    file temp_50y_long.dta saved

Now the data have been prepared, we can use `append` to stack the
datasets.

``` stata
use "temp_23y_long.dta", clear
append using "temp_50y_long.dta"
sort NCDSID sweep
list * in 1/10
```






         +-----------------------------+
         |  NCDSID        DVWT   sweep |
         |-----------------------------|
      1. | N10001N    59.42099      23 |
      2. | N10001N       66.67      50 |
      3. | N10002P   73.482986      23 |
      4. | N10002P       79.37      50 |
      5. | N10004R   76.203995      23 |
         |-----------------------------|
      6. | N10007U   52.163986      23 |
      7. | N10007U       72.11      50 |
      8. | N10008V       69.84      50 |
      9. | N10009W   66.678986      23 |
     10. | N10009W          78      50 |
         +-----------------------------+

Notice that with `append` a cohort member has only as many rows of data
as the times they appeared in Sweeps 4 and 8. The `fillin` command can
be used to create missing rows, which can be useful if you need to
generate a balanced panel of observations.

``` stata
fillin NCDSID sweep
list * in 1/10
```




         +---------------------------------------+
         |  NCDSID        DVWT   sweep   _fillin |
         |---------------------------------------|
      1. | N10001N    59.42099      23         0 |
      2. | N10001N       66.67      50         0 |
      3. | N10002P   73.482986      23         0 |
      4. | N10002P       79.37      50         0 |
      5. | N10004R   76.203995      23         0 |
         |---------------------------------------|
      6. | N10004R           .      50         1 |
      7. | N10007U   52.163986      23         0 |
      8. | N10007U       72.11      50         0 |
      9. | N10008V           .      23         1 |
     10. | N10008V       69.84      50         0 |
         +---------------------------------------+
