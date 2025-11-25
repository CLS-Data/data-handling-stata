---
layout: default
title: Reshaping Data from Long to Wide (or Wide to Long)
nav_order: 4
parent: BCS70
format:
  gfm:
    variant: +yaml_metadata_block
jupyter: stata
---


- [Download the Stata script for this
  page](../do_files/bcs70-reshape_long_wide.do)

# Introduction

In this section, we show how to reshape data from long to wide (and vice
versa). To demonstrate this, we use data on cohort member’s height and
weight from Sweep 9 (42y) and Sweep 11 (51y).

# Reshaping Raw Data from Wide to Long

We begin by loading the data from each sweep and merging these together
into a single *wide* format data frame; see [Combining Data Across
Sweeps](https://cls-data.github.io/docs/bcs70-merging_across_sweeps.html)
for further explanation on how this is achieved. Note, the names of the
height and weight variables in Sweep 8 and Sweep 11 follow a similar
convention, which is the exception rather than the rule in BCS70 data
(at least in early sweeps). Below, we convert the variable names in the
Sweep 9 dataset to lower case so that they closely match those in the
Sweep 11 dataset. This will make reshaping easier.

``` stata
* Load 42y data
use BCSID BD9HGHTM BD9WGHTK using "42y/bcs70_2012_derived.dta", clear
rename *, lower
save "temp_42y.dta", replace

* Load 51y data
use bcsid bd11hghtm bd11wghtk using "51y/bcs11_age51_main.dta", clear
save "temp_51y.dta", replace

* Merge
use "temp_42y.dta", clear
merge 1:1 bcsid using "temp_51y.dta"
keep if _merge == 3 // Keeps matches. `merge ..., keep(3)` would also work.
drop _merge
```




    file temp_42y.dta saved


    file temp_51y.dta saved



        Result                      Number of obs
        -----------------------------------------
        Not matched                         3,509
            from master                     2,667  (_merge==1)
            from using                        842  (_merge==2)

        Matched                             7,174  (_merge==3)
        -----------------------------------------

    (3,509 observations deleted)

We can reshape the dataset into wide format using `reshape long`. This
requires variables to be named in a specific format: `stub` + `suffix`.
Here, we want our stubs to be `hghtm` and `wghtk`, and our suffixes to
be the sweep numbers (9 and 11). We can do this using `rename` with the
`*` wildcard operator. Then in the `reshape long` command, we specify
the stubs in the main command, with the identifier and suffix variables
specified in the `i()` and `j()` command options respectively. Note the
identifier (`i()`) exists in the data, while the suffix variable (`j()`)
is created during the reshape process.

``` stata
* Rename
rename bd9* *9
rename bd11* *11

* Reshape Long
reshape long hghtm wghtk, i(bcsid) j(sweep)
list * in 1/10
```




    (j = 9 11)

    Data                               Wide   ->   Long
    -----------------------------------------------------------------------------
    Number of observations            7,174   ->   14,348      
    Number of variables                   5   ->   4           
    j variable (2 values)                     ->   sweep
    xij variables:
                             hghtm9 hghtm11   ->   hghtm
                             wghtk9 wghtk11   ->   wghtk
    -----------------------------------------------------------------------------


         +---------------------------------------------+
         |   bcsid   sweep         hghtm         wghtk |
         |---------------------------------------------|
      1. | B10001N       9   1.549403071   55.79181671 |
      2. | B10001N      11          1.55          50.8 |
      3. | B10003Q       9   1.854203701   82.55374146 |
      4. | B10003Q      11          1.85         83.46 |
      5. | B10004R       9   1.600203156   57.15259171 |
         |---------------------------------------------|
      6. | B10004R      11           1.6         57.15 |
      7. | B10009W       9   1.625603199   54.88463211 |
      8. | B10009W      11          1.63         60.33 |
      9. | B10011Q       9   1.625603199   76.20345306 |
     10. | B10011Q      11          1.65         82.55 |
         +---------------------------------------------+

# Reshaping Raw Data from Long to Wide

We can reshape the data from long to wide format using the
`reshape wide` command. We again specify the stubs in the main command,
and the identifier and suffix variables in `i()` and `j()`,
respectively. The suffix variable exists in the data, but the value of
this are used to create new variable names during the reshape process.

``` stata
reshape wide hghtm wghtk, i(bcsid) j(sweep)
list * in 1/10
```


    (j = 9 11)

    Data                               Long   ->   Wide
    -----------------------------------------------------------------------------
    Number of observations           14,348   ->   7,174       
    Number of variables                   4   ->   5           
    j variable (2 values)             sweep   ->   (dropped)
    xij variables:
                                      hghtm   ->   hghtm9 hghtm11
                                      wghtk   ->   wghtk9 wghtk11
    -----------------------------------------------------------------------------


         +---------------------------------------------------------+
         |   bcsid        hghtm9        wghtk9   hghtm11   wghtk11 |
         |---------------------------------------------------------|
      1. | B10001N   1.549403071   55.79181671      1.55      50.8 |
      2. | B10003Q   1.854203701   82.55374146      1.85     83.46 |
      3. | B10004R   1.600203156   57.15259171       1.6     57.15 |
      4. | B10009W   1.625603199   54.88463211      1.63     60.33 |
      5. | B10011Q   1.625603199   76.20345306      1.65     82.55 |
         |---------------------------------------------------------|
      6. | B10013S   1.625603199    63.5028801      1.63     66.68 |
      7. | B10015U   1.828803658   77.56423187       1.8     82.55 |
      8. | B10016V   1.879603744   114.3051834      1.88       118 |
      9. | B10018X   1.727203488   88.90402985       1.7      88.9 |
     10. | B10020R   1.498602986   73.02831268      1.47     82.55 |
         +---------------------------------------------------------+
