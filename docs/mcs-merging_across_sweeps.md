---
layout: default
title: Combining Data Across Sweeps
nav_order: 5
parent: MCS
format:
  gfm:
    variant: +yaml_metadata_block
jupyter: stata
---


- [Download the Stata script for this
  page](../do_files/mcs-merging_across_sweeps.do)

# Introduction

In this section, we show how to combine MCS data across sweeps, assuming
the data to be merged are in a consistent format (e.g., one row per
family); for information on munging data to have a consistent structure
see the page [*Combining Data Within a
Sweep*](https://cls-data.github.io/docs/mcs-merging_within_sweep.html)

As an example, we use data on cohort members’ height, which was recorded
in Sweeps 2-7 and is available in the `mcs[2-7]_cm_interview.dta` files.
These files contain one row per cohort-member. As a reminder, we have
organised the data files so that each sweep [has its own folder, which
is named according to the age of
follow-up](https://cls-data.github.io/docs/mcs-sweep_folders.html)
(e.g., 3y for the second sweep).

We begin by combining data from the second and third sweeps, showing how
to combine these datasets in **wide** (one row per observational unit)
and **long** (multiple rows per observational unit) formats by *merging*
and *appending*, respectively. We then show how to combine data from
multiple sweeps *programmatically* using loops and programs.

# Merging Across Sweeps

The variable `[B-G]CHTCM00` contains the height of the cohort member at
Sweep 2-7, except for Sweep 5, where the variable is called `ECHTCMA0`.
[The cohort-member identifiers are stored across two
variables](https://cls-data.github.io/docs/mcs-data_structures.html) in
the `mcs[2-7]_cm_interview.dta` files: `MCSID` and `[A-G]CNUM00`.
`MCSID` is the family identifier and `[A-G]CNUM00` identifies the cohort
member within the family. We will use the `use` command to read in the
data from the second and third sweeps, keeping only the variables we
need (the two identifier variables and height). We also rename the
cohort-member number variable to a consistent name, `CNUM00`, in both
datasets to ensure consistency as Stata requires the same variable names
to merge datasets.

``` stata
* Load 3y data
use MCSID BCNUM00 BCHTCM00 using "3y/mcs2_cm_interview.dta", clear
rename BCNUM00 CNUM00
save "temp_3y.dta", replace

* Load 5y data
use MCSID CCNUM00 CCHTCM00 using "5y/mcs3_cm_interview.dta", clear
rename CCNUM00 CNUM00
save "temp_5y.dta", replace
```




    (file temp_3y.dta not found)
    file temp_3y.dta saved



    (file temp_5y.dta not found)
    file temp_5y.dta saved

We can merge these datasets by row using the `merge` command. We specify
`1:1` to indicate a one-to-one merge on the identifiers `MCSID` and
`CNUM00` - i.e., there is only one observation per cohort member
(`bcsid`) in each dataset.

``` stata
use "temp_3y.dta", clear
merge 1:1 MCSID CNUM00 using "temp_5y.dta"
list * in 1/10
```




        Result                      Number of obs
        -----------------------------------------
        Not matched                         3,275
            from master                     1,811  (_merge==1)
            from using                      1,464  (_merge==2)

        Matched                            13,967  (_merge==3)
        -----------------------------------------


         +------------------------------------------------------------+
         |   MCSID     CNUM00   BCHTCM00   CCHTCM00            _merge |
         |------------------------------------------------------------|
      1. | M10001N   1st Coho         97      114.4       Matched (3) |
      2. | M10002P   1st Coho         96      110.5       Matched (3) |
      3. | M10007U   1st Coho        102        118       Matched (3) |
      4. | M10008V   1st Coho   No Measu          .   Master only (1) |
      5. | M10008V   2nd Coho   No Measu          .   Master only (1) |
         |------------------------------------------------------------|
      6. | M10011Q   1st Coho        106        121       Matched (3) |
      7. | M10014T   1st Coho         97          .   Master only (1) |
      8. | M10015U   1st Coho         94      110.3       Matched (3) |
      9. | M10016V   1st Coho        102      117.7       Matched (3) |
     10. | M10017W   1st Coho         99      110.2       Matched (3) |
         +------------------------------------------------------------+

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
prefixes (e.g., the letter `B` from `BCNUM00` and `BCHTCM00` in
`df_3y`). We also need to add a variable to identify the sweep the data
comes from. Below, we use `rename` to remove the prefixes and `gen`
(short for `generate`) to create a `sweep` variable.

``` stata
use "temp_3y.dta", clear
rename B* *
gen sweep = 2
save "temp_3y_long.dta", replace

use "temp_5y.dta", clear
rename C* *
gen sweep = 3
save "temp_5y_long.dta", replace
```





    (file temp_3y_long.dta not found)
    file temp_3y_long.dta saved




    (file temp_5y_long.dta not found)
    file temp_5y_long.dta saved

Now the data have been prepared, we can use `append` to stack the
datasets.

``` stata
use "temp_3y_long.dta", clear
append using "temp_5y_long.dta"
sort MCSID CNUM00 sweep
list MCSID CNUM00 sweep CHTCM00 in 1/10
```



    (variable CHTCM00 was int, now double to accommodate using data's values)



         +---------------------------------------+
         |   MCSID     CNUM00   sweep    CHTCM00 |
         |---------------------------------------|
      1. | M10001N   1st Coho       2         97 |
      2. | M10001N          .       3      114.4 |
      3. | M10002P   1st Coho       2         96 |
      4. | M10002P          .       3      110.5 |
      5. | M10007U   1st Coho       2        102 |
         |---------------------------------------|
      6. | M10007U          .       3        118 |
      7. | M10008V   1st Coho       2   No Measu |
      8. | M10008V   2nd Coho       2   No Measu |
      9. | M10011Q   1st Coho       2        106 |
     10. | M10011Q          .       3        121 |
         +---------------------------------------+

Notice that with `append` a cohort member has only as many rows of data
as the times they appeared in Sweeps 2 and 3. The `fillin` command can
be used to create missing rows, which can be useful if you need to
generate a balanced panel of observations.

``` stata
fillin MCSID CNUM00 sweep
list * in 1/10
```




         +-----------------------------------------------------------+
         |   MCSID     CNUM00   CHTCM00   sweep      NUM00   _fillin |
         |-----------------------------------------------------------|
      1. | M10001N   1st Coho        97       2          .         0 |
      2. | M10001N   1st Coho         .       3          .         1 |
      3. | M10001N   2nd Coho         .       2          .         1 |
      4. | M10001N   2nd Coho         .       3          .         1 |
      5. | M10001N          .         .       2          .         1 |
         |-----------------------------------------------------------|
      6. | M10001N          .     114.4       3   1st Coho         0 |
      7. | M10002P   1st Coho        96       2          .         0 |
      8. | M10002P   1st Coho         .       3          .         1 |
      9. | M10002P   2nd Coho         .       2          .         1 |
     10. | M10002P   2nd Coho         .       3          .         1 |
         +-----------------------------------------------------------+

# Combing Sweeps Programatically

Combining sweeps manually can become tedious when more than two sweeps
need to be combined. Instead, loops can be used automate the process.
Below we show how to merge and append multiple sweeps together with
relatively little code.

## Merging Programmatically

Before merging the datasets together, we need to load the data for each
sweep. We can do this by defining a
[`program`](https://www.stata.com/manuals/pprogram.pdf),
`load_height_wide`, which takes a single argument `sweep` and loads the
height data for that sweep. This program is written general enough that
it can be used to load data from any of the sweeps 2-7, even where a
specific height variable is not contained in the dataset (e.g., Sweep
5).

- The code begins by creating a `global` macro, `fups` which contains
  the set of ages at which MCS participants have been followed up.
  Macros contain text that are associated with a name (the global `fups`
  contains the string `0 3 5 7 11 14 17`). These are useful in Stata
  programming as an alternative way of storing data to columns in a
  dataset. Macros are either `global` or `local`. Global macros persist
  across the entire Stata session, while local macros (created with the
  `local` command) only persist within the program or do-file in which
  they are created. For more on macros, see this [Stata help
  page](https://www.stata.com/manuals/pmacro.pdf).
- `capture program drop ...` attempts to delete the program, with
  `capture` preventing an error if it does not exist.
- `args sweep` specifies that the program takes a single argument, which
  is transferred into the local macro `sweep` to be used within the
  `program` code.
- The program then creates a list of variable stubs (the parts of the
  variable names that are consistent across sweeps) and prefixes (the
  parts of the variable names that vary across sweeps). The prefix is
  determined by taking the `sweep` argument and using it to index into
  the list of letters `A-G` (stored in the built-in macro `c(ALPHA)`).
  The follow-up age is also determined by indexing into the `fups`
  global macro.
- The variable stubs are then looped over to add the prefix to each
  stub.
- The program then uses `describe ... , varlist` to get a list of
  variables in the dataset for the given sweep. The `r(varlist)` return
  value from `describe` is then stored in the local macro `varlist`.
- Next, the code uses `local in_file: list prefixed_list & varlist` (a
  macro extended function) to create a new local macro, `in_file`, which
  contains the intersection of the list of prefixed variable names and
  the list of variables in the dataset. This ensures that only variables
  which exist in the dataset are included in `in_file`.
- Finally, the program uses `` use MCSID `in_file' using ... `` to read
  in the identifier variables and the height variable from the relevant
  dataset.

``` stata
global fups 0 3 5 7 11 14 17

capture program drop load_height_wide
program define load_height_wide
    args sweep
    
    local stublist CNUM00 CHTCMA0 CHTCM00
  local prefix : word `sweep' of `c(ALPHA)'
    local fup : word `sweep' of ${fups}
    
    local prefixed_list ""
    foreach stubvar of local stublist {
        local prefixed_list "`prefixed_list' `prefix'`stubvar'"
    }
    
    describe using "`fup'y/mcs`sweep'_cm_interview.dta", varlist
    local varlist `r(varlist)'
    local in_file: list prefixed_list & varlist
    
    use MCSID `in_file' using "`fup'y/mcs`sweep'_cm_interview.dta", clear
end

load_height_wide 3
list * in 1/10
```






    Contains data                                 
     Observations:        15,431                  
        Variables:           113                  
    --------------------------------------------------------------------------------
    Variable      Storage   Display    Value
        name         type    format    label      Variable label
    --------------------------------------------------------------------------------
    MCSID           str7    %7s                   MCS Research ID - Anonymised
                                                    Family/Household Identifier
    CCNUM00         byte    %8.0g      CCNUM00    Cohort Member number within an MCS
                                                    family
    CCBCHK00        byte    %8.0g      CCBCHK00   Does child still live here
    CCBWHZ00        byte    %8.0g      CCBWHZ00   What happened to child (merged)
    CCBDCY00        byte    %8.0g      CCBDCY00   When did child die (year)
    CCBDCM00        byte    %8.0g      CCBDCM00   When did child die (month)
    CCBADD00        byte    %8.0g      CCBADD00   Ask & record on ARF address of
                                                    twin/triplet who moved
    CCBLAT00        byte    %8.0g      CCBLAT00   Will need to collect twin/triplet
                                                    later
    CCBCOR00        byte    %8.0g      CCBCOR00   Check FF child's name, sex, DOB
                                                    are all correct
    CCBENG00        byte    %8.0g      CCBENG00   Can CM understand story in English
    CCCABR00        byte    %8.0g      CCCABR00   Whether CM lived outside UK since
                                                    last interview?
    CCCABD00        byte    %8.0g      CCCABD00   Months lived outside UK since last
                                                    interview?
    CCCHIC0A        byte    %8.0g      CCCHIC0A   Consent forms for child given MC1
    CCCHIC0B        byte    %8.0g      CCCHIC0B   Consent forms for child given MC2
    CCCHIC0C        byte    %8.0g      CCCHIC0C   Consent forms for child given MC3
    CCCHIC0D        byte    %8.0g      CCCHIC0D   Consent forms for child given MC4
    CCCHIC0E        byte    %8.0g      CCCHIC0E   Consent forms for child given MC5
    CCCHIC0F        byte    %8.0g      CCCHIC0F   Consent forms for child given MC6
    CCCHIC0G        byte    %8.0g      CCCHIC0G   Consent forms for child given MC7
    CCCHIC0H        byte    %8.0g      CCCHIC0H   Consent forms for child given MC8
    CCCHIC0I        byte    %8.0g      CCCHIC0I   Consent forms for child given MC9
    CCCHIC0J        byte    %8.0g      CCCHIC0J   Consent forms for child given MC10
    CCTVNS00        byte    %8.0g      CCTVNS00   Whether background noise from TV
                                                    etc
    CCCONV00        byte    %8.0g      CCCONV00   IWR: Background noise from
                                                    conversation
    CCBACC00        byte    %8.0g      CCBACC00   IWR: Background noise from other
                                                    children
    CCENTR00        byte    %8.0g      CCENTR00   IWR: Background noise from people
                                                    entering/leaving room
    CCENTH00        byte    %8.0g      CCENTH00   IWR: Background noise from people
                                                    entering/leaving the house
    CCINTC00        byte    %8.0g      CCINTC00   IWR: Interruption of cognitive
                                                    assessments from another child
    CCINTA00        byte    %8.0g      CCINTA00   IWR: Interruption of cognitive
                                                    assessments by an adult
    CCTIRC00        byte    %8.0g      CCTIRC00   Whether cohort child tired
    CCASSC00        byte    %8.0g      CCASSC00   Circumstances of the cognitive
                                                    assessment
    CCSAOC00        byte    %8.0g      CCSAOC00   Sally Anne outcome
    CCPSOC00        byte    %8.0g      CCPSOC00   Pattern similarities outcome
    CCNVOC00        byte    %8.0g      CCNVOC00   Naming Vocab outcome
    CCPCOC00        byte    %8.0g      CCPCOC00   Pattern constuction outcome
    CCHTOC00        byte    %8.0g      CCHTOC00   Height outcome
    CCWTOC00        byte    %8.0g      CCWTOC00   Weight outcome
    CCWSOC00        byte    %8.0g      CCWSOC00   Waist outcome
    CCCMNO00        byte    %8.0g      CCCMNO00   COG: Cohort Member Number
    CCAPST00        long    %tc..                 PHYS: Start time of physical
                                                    assessments
    CCAPET00        long    %tc..                 PHYS: End time of physical
                                                    assessments
    CCAPLN00        int     %8.0g      CCAPLN00   PHYS: Length of physical
                                                    assessments
    CCAPIN00        byte    %8.0g      CCAPIN00   PHYS: Interviewer: Id now like to
                                                    measure ht, wgt and waist
    CCHTDN00        byte    %8.0g      CCHTDN00   PHYS: Whether height measured
    CCNOHT0A        byte    %8.0g      CCNOHT0A   PHYS: Reason for refusal (Final)
    CCNOHT0B        byte    %8.0g      CCNOHT0B   PHYS: Reason for refusal (Final)
    CCHTCM00        double  %12.0g     CCHTCM00   PHYS: Height in cms
    CCHTAT00        byte    %8.0g      CCHTAT00   PHYS: number of attempts at
                                                    measurement
    CCHTTM00        long    %tc..                 PHYS: Time Measurement was taken
    CCHTRLAA        byte    %8.0g      CCHTRLAA   PHYS: Height measurement
                                                    circumstances (final)
    CCHTRLAB        byte    %8.0g      CCHTRLAB   PHYS: Height measurement
                                                    circumstances (final)
    CCHTRLBA        byte    %8.0g      CCHTRLBA   PHYS: Height measurement
                                                    circumstances (final)
    CCHTRLBB        byte    %8.0g      CCHTRLBB   PHYS: Height measurement
                                                    circumstances (final)
    CCHTRLBC        byte    %8.0g      CCHTRLBC   PHYS: Height measurement
                                                    circumstances (final)
    CCHTRLBD        byte    %8.0g      CCHTRLBD   PHYS: Height measurement
                                                    circumstances (final)
    CCHTEL00        byte    %8.0g      CCHTEL00   PHYS: Whether further height
                                                    information
    CCHTEX0A        byte    %8.0g      CCHTEX0A   PHYS: Anything else about height
                                                    measurement (final)
    CCBKHT00        byte    %8.0g      CCBKHT00   PHYS: Whether looked in child
                                                    record book
    CCBKCM00        float   %9.0g      CCBKCM00   PHYS: Height in Centimetres
    CCWTDN00        byte    %8.0g      CCWTDN00   PHYS: Whether weight measured
    CCNOWT0A        byte    %8.0g      CCNOWT0A   PHYS: Reason for refusal (final)
    CCNOWT0B        byte    %8.0g      CCNOWT0B   PHYS: Reason for refusal (final)
    CCWTCM00        double  %12.0g     CCWTCM00   PHYS: Weight in Kilograms
    --more--

We can use a loop to load and merge the data for sweeps 3-7. We first
load the data for Sweep 3 (`load_height_wide 3`), then loop over Sweeps
4-7, loading each dataset in turn and merging it with the master
dataset. `preserve` and `restore` are used to temporarily save and
restore the master dataset while loading each new sweep’s data.

``` stata
load_height_wide 3
rename *CNUM00 CNUM00

tempfile next_merge
forvalues sweep = 4/7 { 
    preserve
        load_height_wide `sweep'
        rename *CNUM00 CNUM00
        save "`next_merge'", replace
    restore
    merge 1:1 MCSID CNUM00 using "`next_merge'", nogenerate
}

sort MCSID CNUM00 
list * in 1/10
```



    Contains data                                 
     Observations:        15,431                  
        Variables:           113                  
    --------------------------------------------------------------------------------
    Variable      Storage   Display    Value
        name         type    format    label      Variable label
    --------------------------------------------------------------------------------
    MCSID           str7    %7s                   MCS Research ID - Anonymised
                                                    Family/Household Identifier
    CCNUM00         byte    %8.0g      CCNUM00    Cohort Member number within an MCS
                                                    family
    CCBCHK00        byte    %8.0g      CCBCHK00   Does child still live here
    CCBWHZ00        byte    %8.0g      CCBWHZ00   What happened to child (merged)
    CCBDCY00        byte    %8.0g      CCBDCY00   When did child die (year)
    CCBDCM00        byte    %8.0g      CCBDCM00   When did child die (month)
    CCBADD00        byte    %8.0g      CCBADD00   Ask & record on ARF address of
                                                    twin/triplet who moved
    CCBLAT00        byte    %8.0g      CCBLAT00   Will need to collect twin/triplet
                                                    later
    CCBCOR00        byte    %8.0g      CCBCOR00   Check FF child's name, sex, DOB
                                                    are all correct
    CCBENG00        byte    %8.0g      CCBENG00   Can CM understand story in English
    CCCABR00        byte    %8.0g      CCCABR00   Whether CM lived outside UK since
                                                    last interview?
    CCCABD00        byte    %8.0g      CCCABD00   Months lived outside UK since last
                                                    interview?
    CCCHIC0A        byte    %8.0g      CCCHIC0A   Consent forms for child given MC1
    CCCHIC0B        byte    %8.0g      CCCHIC0B   Consent forms for child given MC2
    CCCHIC0C        byte    %8.0g      CCCHIC0C   Consent forms for child given MC3
    CCCHIC0D        byte    %8.0g      CCCHIC0D   Consent forms for child given MC4
    CCCHIC0E        byte    %8.0g      CCCHIC0E   Consent forms for child given MC5
    CCCHIC0F        byte    %8.0g      CCCHIC0F   Consent forms for child given MC6
    CCCHIC0G        byte    %8.0g      CCCHIC0G   Consent forms for child given MC7
    CCCHIC0H        byte    %8.0g      CCCHIC0H   Consent forms for child given MC8
    CCCHIC0I        byte    %8.0g      CCCHIC0I   Consent forms for child given MC9
    CCCHIC0J        byte    %8.0g      CCCHIC0J   Consent forms for child given MC10
    CCTVNS00        byte    %8.0g      CCTVNS00   Whether background noise from TV
                                                    etc
    CCCONV00        byte    %8.0g      CCCONV00   IWR: Background noise from
                                                    conversation
    CCBACC00        byte    %8.0g      CCBACC00   IWR: Background noise from other
                                                    children
    CCENTR00        byte    %8.0g      CCENTR00   IWR: Background noise from people
                                                    entering/leaving room
    CCENTH00        byte    %8.0g      CCENTH00   IWR: Background noise from people
                                                    entering/leaving the house
    CCINTC00        byte    %8.0g      CCINTC00   IWR: Interruption of cognitive
                                                    assessments from another child
    CCINTA00        byte    %8.0g      CCINTA00   IWR: Interruption of cognitive
                                                    assessments by an adult
    CCTIRC00        byte    %8.0g      CCTIRC00   Whether cohort child tired
    CCASSC00        byte    %8.0g      CCASSC00   Circumstances of the cognitive
                                                    assessment
    CCSAOC00        byte    %8.0g      CCSAOC00   Sally Anne outcome
    CCPSOC00        byte    %8.0g      CCPSOC00   Pattern similarities outcome
    CCNVOC00        byte    %8.0g      CCNVOC00   Naming Vocab outcome
    CCPCOC00        byte    %8.0g      CCPCOC00   Pattern constuction outcome
    CCHTOC00        byte    %8.0g      CCHTOC00   Height outcome
    CCWTOC00        byte    %8.0g      CCWTOC00   Weight outcome
    CCWSOC00        byte    %8.0g      CCWSOC00   Waist outcome
    CCCMNO00        byte    %8.0g      CCCMNO00   COG: Cohort Member Number
    CCAPST00        long    %tc..                 PHYS: Start time of physical
                                                    assessments
    CCAPET00        long    %tc..                 PHYS: End time of physical
                                                    assessments
    CCAPLN00        int     %8.0g      CCAPLN00   PHYS: Length of physical
                                                    assessments
    CCAPIN00        byte    %8.0g      CCAPIN00   PHYS: Interviewer: Id now like to
                                                    measure ht, wgt and waist
    CCHTDN00        byte    %8.0g      CCHTDN00   PHYS: Whether height measured
    CCNOHT0A        byte    %8.0g      CCNOHT0A   PHYS: Reason for refusal (Final)
    CCNOHT0B        byte    %8.0g      CCNOHT0B   PHYS: Reason for refusal (Final)
    CCHTCM00        double  %12.0g     CCHTCM00   PHYS: Height in cms
    CCHTAT00        byte    %8.0g      CCHTAT00   PHYS: number of attempts at
                                                    measurement
    CCHTTM00        long    %tc..                 PHYS: Time Measurement was taken
    CCHTRLAA        byte    %8.0g      CCHTRLAA   PHYS: Height measurement
                                                    circumstances (final)
    CCHTRLAB        byte    %8.0g      CCHTRLAB   PHYS: Height measurement
                                                    circumstances (final)
    CCHTRLBA        byte    %8.0g      CCHTRLBA   PHYS: Height measurement
                                                    circumstances (final)
    CCHTRLBB        byte    %8.0g      CCHTRLBB   PHYS: Height measurement
                                                    circumstances (final)
    CCHTRLBC        byte    %8.0g      CCHTRLBC   PHYS: Height measurement
                                                    circumstances (final)
    CCHTRLBD        byte    %8.0g      CCHTRLBD   PHYS: Height measurement
                                                    circumstances (final)
    CCHTEL00        byte    %8.0g      CCHTEL00   PHYS: Whether further height
                                                    information
    CCHTEX0A        byte    %8.0g      CCHTEX0A   PHYS: Anything else about height
                                                    measurement (final)
    CCBKHT00        byte    %8.0g      CCBKHT00   PHYS: Whether looked in child
                                                    record book
    CCBKCM00        float   %9.0g      CCBKCM00   PHYS: Height in Centimetres
    CCWTDN00        byte    %8.0g      CCWTDN00   PHYS: Whether weight measured
    CCNOWT0A        byte    %8.0g      CCNOWT0A   PHYS: Reason for refusal (final)
    CCNOWT0B        byte    %8.0g      CCNOWT0B   PHYS: Reason for refusal (final)
    CCWTCM00        double  %12.0g     CCWTCM00   PHYS: Weight in Kilograms
    --more--

## Appending Programmatically

Programatically appending datasets together is slightly more
straightforward. First, we create a program, `load_height_long`, to load
the height data from a given sweep and format it so that it can be
appended to the other sweeps (i.e., giving variables consistent names).
This calls the `load_height_wide` program defined above to load the
data, then renames the variables to remove the sweep-specific prefixes
and creates a `fup` variable to identify the sweep.

``` stata
capture program drop load_height_long
program define load_height_long, rclass
    args sweep
    
    load_height_wide `sweep'
    local prefix : word `sweep' of `c(ALPHA)'
    rename `prefix'* *
    rename CHTCM?0 CHTCM00
    local fup : word `sweep' of ${fups}
    gen fup = `fup', after(CNUM00)  
end
```

To load data from sweeps 2-7 and append them together, we can again use
a loop. We first load the data for Sweep 3 (`load_height_long 3`), then
loop over Sweeps 4-7 to append these in, again using `preserve` and
`restore` to temporarily save and restore the master dataset while
loading each new sweep’s data.

``` stata
load_height_long 3

tempfile next_append
forvalues sweep = 4/7 { 
  preserve
        load_height_long `sweep'
        save "`next_append'", replace
    restore
  append using "`next_append'"
}

sort MCSID CNUM00 fup
list * in 1/10
```



    Contains data                                 
     Observations:        15,431                  
        Variables:           113                  
    --------------------------------------------------------------------------------
    Variable      Storage   Display    Value
        name         type    format    label      Variable label
    --------------------------------------------------------------------------------
    MCSID           str7    %7s                   MCS Research ID - Anonymised
                                                    Family/Household Identifier
    CCNUM00         byte    %8.0g      CCNUM00    Cohort Member number within an MCS
                                                    family
    CCBCHK00        byte    %8.0g      CCBCHK00   Does child still live here
    CCBWHZ00        byte    %8.0g      CCBWHZ00   What happened to child (merged)
    CCBDCY00        byte    %8.0g      CCBDCY00   When did child die (year)
    CCBDCM00        byte    %8.0g      CCBDCM00   When did child die (month)
    CCBADD00        byte    %8.0g      CCBADD00   Ask & record on ARF address of
                                                    twin/triplet who moved
    CCBLAT00        byte    %8.0g      CCBLAT00   Will need to collect twin/triplet
                                                    later
    CCBCOR00        byte    %8.0g      CCBCOR00   Check FF child's name, sex, DOB
                                                    are all correct
    CCBENG00        byte    %8.0g      CCBENG00   Can CM understand story in English
    CCCABR00        byte    %8.0g      CCCABR00   Whether CM lived outside UK since
                                                    last interview?
    CCCABD00        byte    %8.0g      CCCABD00   Months lived outside UK since last
                                                    interview?
    CCCHIC0A        byte    %8.0g      CCCHIC0A   Consent forms for child given MC1
    CCCHIC0B        byte    %8.0g      CCCHIC0B   Consent forms for child given MC2
    CCCHIC0C        byte    %8.0g      CCCHIC0C   Consent forms for child given MC3
    CCCHIC0D        byte    %8.0g      CCCHIC0D   Consent forms for child given MC4
    CCCHIC0E        byte    %8.0g      CCCHIC0E   Consent forms for child given MC5
    CCCHIC0F        byte    %8.0g      CCCHIC0F   Consent forms for child given MC6
    CCCHIC0G        byte    %8.0g      CCCHIC0G   Consent forms for child given MC7
    CCCHIC0H        byte    %8.0g      CCCHIC0H   Consent forms for child given MC8
    CCCHIC0I        byte    %8.0g      CCCHIC0I   Consent forms for child given MC9
    CCCHIC0J        byte    %8.0g      CCCHIC0J   Consent forms for child given MC10
    CCTVNS00        byte    %8.0g      CCTVNS00   Whether background noise from TV
                                                    etc
    CCCONV00        byte    %8.0g      CCCONV00   IWR: Background noise from
                                                    conversation
    CCBACC00        byte    %8.0g      CCBACC00   IWR: Background noise from other
                                                    children
    CCENTR00        byte    %8.0g      CCENTR00   IWR: Background noise from people
                                                    entering/leaving room
    CCENTH00        byte    %8.0g      CCENTH00   IWR: Background noise from people
                                                    entering/leaving the house
    CCINTC00        byte    %8.0g      CCINTC00   IWR: Interruption of cognitive
                                                    assessments from another child
    CCINTA00        byte    %8.0g      CCINTA00   IWR: Interruption of cognitive
                                                    assessments by an adult
    CCTIRC00        byte    %8.0g      CCTIRC00   Whether cohort child tired
    CCASSC00        byte    %8.0g      CCASSC00   Circumstances of the cognitive
                                                    assessment
    CCSAOC00        byte    %8.0g      CCSAOC00   Sally Anne outcome
    CCPSOC00        byte    %8.0g      CCPSOC00   Pattern similarities outcome
    CCNVOC00        byte    %8.0g      CCNVOC00   Naming Vocab outcome
    CCPCOC00        byte    %8.0g      CCPCOC00   Pattern constuction outcome
    CCHTOC00        byte    %8.0g      CCHTOC00   Height outcome
    CCWTOC00        byte    %8.0g      CCWTOC00   Weight outcome
    CCWSOC00        byte    %8.0g      CCWSOC00   Waist outcome
    CCCMNO00        byte    %8.0g      CCCMNO00   COG: Cohort Member Number
    CCAPST00        long    %tc..                 PHYS: Start time of physical
                                                    assessments
    CCAPET00        long    %tc..                 PHYS: End time of physical
                                                    assessments
    CCAPLN00        int     %8.0g      CCAPLN00   PHYS: Length of physical
                                                    assessments
    CCAPIN00        byte    %8.0g      CCAPIN00   PHYS: Interviewer: Id now like to
                                                    measure ht, wgt and waist
    CCHTDN00        byte    %8.0g      CCHTDN00   PHYS: Whether height measured
    CCNOHT0A        byte    %8.0g      CCNOHT0A   PHYS: Reason for refusal (Final)
    CCNOHT0B        byte    %8.0g      CCNOHT0B   PHYS: Reason for refusal (Final)
    CCHTCM00        double  %12.0g     CCHTCM00   PHYS: Height in cms
    CCHTAT00        byte    %8.0g      CCHTAT00   PHYS: number of attempts at
                                                    measurement
    CCHTTM00        long    %tc..                 PHYS: Time Measurement was taken
    CCHTRLAA        byte    %8.0g      CCHTRLAA   PHYS: Height measurement
                                                    circumstances (final)
    CCHTRLAB        byte    %8.0g      CCHTRLAB   PHYS: Height measurement
                                                    circumstances (final)
    CCHTRLBA        byte    %8.0g      CCHTRLBA   PHYS: Height measurement
                                                    circumstances (final)
    CCHTRLBB        byte    %8.0g      CCHTRLBB   PHYS: Height measurement
                                                    circumstances (final)
    CCHTRLBC        byte    %8.0g      CCHTRLBC   PHYS: Height measurement
                                                    circumstances (final)
    CCHTRLBD        byte    %8.0g      CCHTRLBD   PHYS: Height measurement
                                                    circumstances (final)
    CCHTEL00        byte    %8.0g      CCHTEL00   PHYS: Whether further height
                                                    information
    CCHTEX0A        byte    %8.0g      CCHTEX0A   PHYS: Anything else about height
                                                    measurement (final)
    CCBKHT00        byte    %8.0g      CCBKHT00   PHYS: Whether looked in child
                                                    record book
    CCBKCM00        float   %9.0g      CCBKCM00   PHYS: Height in Centimetres
    CCWTDN00        byte    %8.0g      CCWTDN00   PHYS: Whether weight measured
    CCNOWT0A        byte    %8.0g      CCNOWT0A   PHYS: Reason for refusal (final)
    CCNOWT0B        byte    %8.0g      CCNOWT0B   PHYS: Reason for refusal (final)
    CCWTCM00        double  %12.0g     CCWTCM00   PHYS: Weight in Kilograms
    --more--
