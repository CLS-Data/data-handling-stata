---
layout: default
title: Combining Data Across Sweeps
nav_order: 3
parent: BCS70
format:
  gfm:
    variant: +yaml_metadata_block
jupyter: stata
---


- [Download the Stata script for this
  page](../do_files/bcs70-merging_across_sweeps.do)

# Introduction

In this section, we show how to combine BCS70 data across sweeps.

As an example, we use data on cohort members’ height. Variables for this
are contained in files which have one row per cohort-member. As a
reminder, we have organised the data files so that each sweep [has its
own folder, which is named according to the age of
follow-up](https://cls-data.github.io/docs/bcs70-sweep_folders.html)
(e.g., 10y for the third major sweep).

We begin by combining data from the Sweeps 9 (42y) and Sweep 11 (51y),
showing how to combine these datasets in **wide** (one row per
observational unit) and **long** (multiple rows per observational unit)
formats by *merging* and *appending*, respectively. Because variable
names change between sweeps in unpredictable ways, it is not
straightforwardly possible to combine data from multiple sweeps
*programmatically* (as we are able to do for, e.g., the
[MCS](https://cls-data.github.io/docs/mcs-merging_across_sweeps.html)).

# Merging Across Sweeps

The variables `BD9HGHTM` and `bd11hghtm` contains the height of the
cohort member at Sweep 9 (42y) and Sweep 11 (51y), respectively. Note,
these are derived variable which convert raw height measurements into
metres. The variable names follow the same convention (with the
exception that at age 51, lower case is used). This bucks the more
general case where conceptually similar variables have different
(potentially, non-descriptive) names, when combining data including
early sweeps.

We will use the `use` command to read in the data from the two sweeps,
keeping only the variables we need (the identifier and height
variables). We also rename the variables to lower case in the Sweep 9
(42y) dataset to ensure consistency.

``` stata
* Load 42y data
use BCSID BD9HGHTM using "42y/bcs70_2012_derived.dta", clear
rename *, lower
save "temp_42y.dta", replace

* Load 51y data
use bcsid bd11hghtm using "51y/bcs11_age51_main.dta", clear
save "temp_51y.dta", replace
```




    file temp_42y.dta saved


    file temp_51y.dta saved

We can merge these datasets by row using the `merge` command. We specify
`1:1` to indicate a one-to-one merge on the identifier `bcsid` - i.e.,
there is only one observation per cohort member (`bcsid`) in each
dataset.

``` stata
use "temp_42y.dta", clear
merge 1:1 bcsid using "temp_51y.dta"
list * in 1/10
```




        Result                      Number of obs
        -----------------------------------------
        Not matched                         3,509
            from master                     2,667  (_merge==1)
            from using                        842  (_merge==2)

        Matched                             7,174  (_merge==3)
        -----------------------------------------


         +-------------------------------------------------+
         |   bcsid   bd9hghtm   bd11hg~m            _merge |
         |-------------------------------------------------|
      1. | B10001N   1.549403       1.55       Matched (3) |
      2. | B10003Q   1.854204       1.85       Matched (3) |
      3. | B10004R   1.600203        1.6       Matched (3) |
      4. | B10007U   1.524003          .   Master only (1) |
      5. | B10009W   1.625603       1.63       Matched (3) |
         |-------------------------------------------------|
      6. | B10010P   1.651003          .   Master only (1) |
      7. | B10011Q   1.625603       1.65       Matched (3) |
      8. | B10013S   1.625603       1.63       Matched (3) |
      9. | B10015U   1.828804        1.8       Matched (3) |
     10. | B10016V   1.879604       1.88       Matched (3) |
         +-------------------------------------------------+

The `_merge` variable indicates the result of the merge: `1` means the
observation was only in the master dataset (42y), `2` means it was only
in the using dataset (51y), and `3` means it was in both.
`keep if _merge ...` can be used to keep certain observations if
required (e.g., `keep if _merge == 3` will retain a balance panel of
individuals appearing in both datasets). Alternatively,
`merge ..., keep(...)` can be used to achieve the same result.

# Appending Sweeps

To put the data into long format, we can use the `append` command. (In
this case, the data will have one row per cohort-member x sweep
combination.) To work properly, we need to name the variables
consistently across sweeps, which here means removing the sweep-specific
lettering (e.g., the string `BD9` from `BD9HGHTM` in `df_42y`). We also
need to add a variable to identify the sweep the data comes from. Below,
we use `rename` to remove the suffixes and `gen` (short for `generate`)
to create a `sweep` variable.

``` stata
use "temp_42y.dta", clear
rename bd9* *
gen sweep = 9
save "temp_42y_long.dta", replace

use "temp_51y.dta", clear
rename bd11* *
gen sweep = 11
save "temp_51y_long.dta", replace
```





    file temp_42y_long.dta saved




    file temp_51y_long.dta saved

Now the data have been prepared, we can use `append` to stack the
datasets.

``` stata
use "temp_42y_long.dta", clear
append using "temp_51y_long.dta"
sort bcsid sweep
list * in 1/10
```



    (variable hghtm was float, now double to accommodate using data's values)



         +----------------------------+
         |   bcsid      hghtm   sweep |
         |----------------------------|
      1. | B10001N   1.549403       9 |
      2. | B10001N       1.55      11 |
      3. | B10003Q   1.854204       9 |
      4. | B10003Q       1.85      11 |
      5. | B10004R   1.600203       9 |
         |----------------------------|
      6. | B10004R        1.6      11 |
      7. | B10007U   1.524003       9 |
      8. | B10009W   1.625603       9 |
      9. | B10009W       1.63      11 |
     10. | B10010P   1.651003       9 |
         +----------------------------+

Notice that with `append` a cohort member has only as many rows of data
as the times they appeared in Sweeps 9 and 11. The `fillin` command can
be used to create missing rows, which can be useful if you need to
generate a balanced panel of observations.

``` stata
fillin bcsid sweep
list * in 1/10
```




         +--------------------------------------+
         |   bcsid      hghtm   sweep   _fillin |
         |--------------------------------------|
      1. | B10001N   1.549403       9         0 |
      2. | B10001N       1.55      11         0 |
      3. | B10003Q   1.854204       9         0 |
      4. | B10003Q       1.85      11         0 |
      5. | B10004R   1.600203       9         0 |
         |--------------------------------------|
      6. | B10004R        1.6      11         0 |
      7. | B10007U   1.524003       9         0 |
      8. | B10007U          .      11         1 |
      9. | B10009W   1.625603       9         0 |
     10. | B10009W       1.63      11         0 |
         +--------------------------------------+
