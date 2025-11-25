---
layout: default
title: Reshaping Data from Long to Wide (or Wide to Long)
nav_order: 7
parent: MCS
format:
  gfm:
    variant: +yaml_metadata_block
jupyter: stata
---


- [Download the Stata script for this
  page](../do_files/mcs-reshape_long_wide.do)

# Introduction

In this section, we show how to reshape data from long to wide (and vice
versa). We do this for both raw and cleaned data. To demonstrate, we use
data on cohort member’s height and weight collected in Sweeps 3-7.

# Reshaping Raw Data from Wide to Long

We begin by loading the data from each sweep and merging these together
into a single wide format data frame; see [Combining Data Across
Sweeps](https://cls-data.github.io/docs/mcs-merging_across_sweeps.html)
for further explanation on how this is achieved and in particular how to
create `programs` (functions) in Stata. Note, the names of the height
and weight variables in Sweep 5 (`ECHTCMA0` and `ECWTCMAO`) diverge
slightly from the convention used for other sweeps (`[C-G]CHTCM00` and
`[C-G]CWTCM00` where `[C-G]` denotes sweep). To make the names of the
columns in the wide dataset consistent (useful preparation for reshaping
data), we rename the Sweep 5 variables so they follow the convention for
the other sweeps.

``` stata
global fups 0 3 5 7 11 14 17

capture program drop load_anthro_wide
program define load_anthro_wide, rclass
    args sweep
    
    local stublist CNUM00 CHTCMA0 CHTCM00 CWTCMA0 CWTCM00
  local prefix : word `sweep' of `c(ALPHA)'
    local fup : word `sweep' of ${fups}
    
    local prefixed_list ""
    foreach stubvar of local stublist {
        local prefixed_list "`prefixed_list' `prefix'`stubvar'"
    }
    
    quietly describe using "`fup'y/mcs`sweep'_cm_interview.dta", varlist
    local varlist `r(varlist)'
    local in_file: list prefixed_list & varlist
    
    use MCSID `in_file' using "`fup'y/mcs`sweep'_cm_interview.dta", clear
    rename *CNUM00 CNUM00
end

load_anthro_wide 1

tempfile next_merge
quietly forvalues sweep = 2/7 { 
    preserve
        load_anthro_wide `sweep'
        save "`next_merge'", replace
    restore
    merge 1:1 MCSID CNUM00 using "`next_merge'", nogenerate
}

rename ?C?TCMA0 ?C?TCM00

sort MCSID CNUM00 
list * in 1/10
```








    . rename ?C?TCMA0 ?C?TCM00

    . sort MCSID CNUM00 

    . list * in 1/10

         +-----------------------------------------------------------------+
      1. |   MCSID |   CNUM00 | BCHTCM00 | CCHTCM00 | CCWTCM00 | DCHTCM00  |
         | M10001N | 1st Coho |       97 |    114.4 |     21.2 |    127.8  |
         |-----------------------------------------------------------------|
         | DCWTCM00 | ECHTCM00 | ECWTCM00 | FCHTCM00 | FCWTCM00 | GCHTCM00 |
         |     25.5 |        . |        . |        . |        . |        . |
         |-----------------------------------------------------------------|
         |                            GCWTCM00                             |
         |                                   .                             |
         +-----------------------------------------------------------------+

         +-----------------------------------------------------------------+
      2. |   MCSID |   CNUM00 | BCHTCM00 | CCHTCM00 | CCWTCM00 | DCHTCM00  |
         | M10002P | 1st Coho |       96 |    110.5 |     19.2 |      123  |
         |-----------------------------------------------------------------|
         | DCWTCM00 | ECHTCM00 | ECWTCM00 | FCHTCM00 | FCWTCM00 | GCHTCM00 |
         |     26.2 |    143.5 |     41.8 |    163.2 |     52.3 |    174.1 |
         |-----------------------------------------------------------------|
         |                            GCWTCM00                             |
         |                                59.4                             |
         +-----------------------------------------------------------------+

         +-----------------------------------------------------------------+
      3. |   MCSID |   CNUM00 | BCHTCM00 | CCHTCM00 | CCWTCM00 | DCHTCM00  |
         | M10007U | 1st Coho |      102 |      118 |     25.3 |      129  |
         |-----------------------------------------------------------------|
         | DCWTCM00 | ECHTCM00 | ECWTCM00 | FCHTCM00 | FCWTCM00 | GCHTCM00 |
         |     26.5 |    154.5 |     40.6 |    173.6 |     57.1 |    180.6 |
         |-----------------------------------------------------------------|
         |                            GCWTCM00                             |
         |                                71.4                             |
         +-----------------------------------------------------------------+

         +-----------------------------------------------------------------+
      4. |   MCSID |   CNUM00 | BCHTCM00 | CCHTCM00 | CCWTCM00 | DCHTCM00  |
         | M10008V | 1st Coho | No Measu |        . |        . |        .  |
         |-----------------------------------------------------------------|
         | DCWTCM00 | ECHTCM00 | ECWTCM00 | FCHTCM00 | FCWTCM00 | GCHTCM00 |
         |        . |        . |        . |        . |        . |        . |
         |-----------------------------------------------------------------|
         |                            GCWTCM00                             |
         |                                   .                             |
         +-----------------------------------------------------------------+

         +-----------------------------------------------------------------+
      5. |   MCSID |   CNUM00 | BCHTCM00 | CCHTCM00 | CCWTCM00 | DCHTCM00  |
         | M10008V | 2nd Coho | No Measu |        . |        . |        .  |
         |-----------------------------------------------------------------|
         | DCWTCM00 | ECHTCM00 | ECWTCM00 | FCHTCM00 | FCWTCM00 | GCHTCM00 |
         |        . |        . |        . |        . |        . |        . |
         |-----------------------------------------------------------------|
         |                            GCWTCM00                             |
         |                                   .                             |
         +-----------------------------------------------------------------+

         +-----------------------------------------------------------------+
      6. |   MCSID |   CNUM00 | BCHTCM00 | CCHTCM00 | CCWTCM00 | DCHTCM00  |
         | M10011Q | 1st Coho |      106 |      121 |     32.9 |      137  |
         |-----------------------------------------------------------------|
         | DCWTCM00 | ECHTCM00 | ECWTCM00 | FCHTCM00 | FCWTCM00 | GCHTCM00 |
         |     51.2 |    168.1 |       74 |        . |        . |        . |
         |-----------------------------------------------------------------|
         |                            GCWTCM00                             |
         |                                   .                             |
         +-----------------------------------------------------------------+

         +-----------------------------------------------------------------+
      7. |   MCSID |   CNUM00 | BCHTCM00 | CCHTCM00 | CCWTCM00 | DCHTCM00  |
         | M10014T | 1st Coho |       97 |        . |        . |        .  |
         |-----------------------------------------------------------------|
         | DCWTCM00 | ECHTCM00 | ECWTCM00 | FCHTCM00 | FCWTCM00 | GCHTCM00 |
         |        . |        . |        . |        . |        . |        . |
         |-----------------------------------------------------------------|
         |                            GCWTCM00                             |
         |                                   .                             |
         +-----------------------------------------------------------------+

         +-----------------------------------------------------------------+
      8. |   MCSID |   CNUM00 | BCHTCM00 | CCHTCM00 | CCWTCM00 | DCHTCM00  |
         | M10015U | 1st Coho |       94 |    110.3 |     19.7 |    121.5  |
         |-----------------------------------------------------------------|
         | DCWTCM00 | ECHTCM00 | ECWTCM00 | FCHTCM00 | FCWTCM00 | GCHTCM00 |
         |     24.1 |      143 |     38.2 |    163.9 |     56.2 |      169 |
         |-----------------------------------------------------------------|
         |                            GCWTCM00                             |
         |                                75.7                             |
         +-----------------------------------------------------------------+

         +-----------------------------------------------------------------+
      9. |   MCSID |   CNUM00 | BCHTCM00 | CCHTCM00 | CCWTCM00 | DCHTCM00  |
         | M10016V | 1st Coho |      102 |    117.7 |       23 |      130  |
         |-----------------------------------------------------------------|
         | DCWTCM00 | ECHTCM00 | ECWTCM00 | FCHTCM00 | FCWTCM00 | GCHTCM00 |
         |       29 |    151.8 |     41.5 |      167 |     51.5 |    185.1 |
         |-----------------------------------------------------------------|
         |                            GCWTCM00                             |
         |                                74.1                             |
         +-----------------------------------------------------------------+
    --more--

We can reshape the dataset into long format (one row per person x sweep
combination) using the `reshape long` command. To use `reshape long`,
Stata requires variables to be named in a specific format: `stub` +
`suffix`. Here, we want our stubs to be `CHTCM00` and `CWTCM00`, and our
suffixes to be the sweep letters. First, we rename the variables to
match this format. Then in the `reshape long` command, we specify the
stubs in the main command, with the identifier and suffix variables
specified in the `i()` and `j()` command options respectively. Note the
identifier (`i()`) exists in the data, while the suffix variable (`j()`)
is created during the reshape process.

``` stata
rename *CWTCM00 CWTCM00*
rename *CHTCM00 CHTCM00*
reshape long CWTCM00 CHTCM00, i(MCSID CNUM00) j(sweep_letter) string
list * in 1/10
```




    (j = B C D E F G)
    (variable CWTCM00B not found)

    Data                               Wide   ->   Long
    -----------------------------------------------------------------------------
    Number of observations           19,483   ->   116,898     
    Number of variables                  13   ->   5           
    j variable (6 values)                     ->   sweep_letter
    xij variables:
             CWTCM00B CWTCM00C ... CWTCM00G   ->   CWTCM00
             CHTCM00B CHTCM00C ... CHTCM00G   ->   CHTCM00
    -----------------------------------------------------------------------------


         +---------------------------------------------------+
         |   MCSID     CNUM00   sweep_~r   CHTCM00   CWTCM00 |
         |---------------------------------------------------|
      1. | M10001N   1st Coho          B        97         . |
      2. | M10001N   1st Coho          C     114.4      21.2 |
      3. | M10001N   1st Coho          D     127.8      25.5 |
      4. | M10001N   1st Coho          E         .         . |
      5. | M10001N   1st Coho          F         .         . |
         |---------------------------------------------------|
      6. | M10001N   1st Coho          G         .         . |
      7. | M10002P   1st Coho          B        96         . |
      8. | M10002P   1st Coho          C     110.5      19.2 |
      9. | M10002P   1st Coho          D       123      26.2 |
     10. | M10002P   1st Coho          E     143.5      41.8 |
         +---------------------------------------------------+

# Reshaping Raw Data from Long to Wide

We can reshape the data from long to wide format using the
`reshape wide` command. We again specify the stubs in the main command,
and the identifier and suffix variables in `i()` and `j()`,
respectively. The suffix variable exists in the data, but the value of
this are used to create new variable names during the reshape process.

``` stata
reshape wide CHTCM00 CWTCM00, i(MCSID CNUM00) j(sweep_letter) string
rename CWTCM00* *CWTCM00
rename CHTCM00* *CHTCM00
list in 1/10
```


    (j = B C D E F G)

    Data                               Long   ->   Wide
    -----------------------------------------------------------------------------
    Number of observations          116,898   ->   19,483      
    Number of variables                   5   ->   14          
    j variable (6 values)      sweep_letter   ->   (dropped)
    xij variables:
                                    CHTCM00   ->   CHTCM00B CHTCM00C ... CHTCM00G
                                    CWTCM00   ->   CWTCM00B CWTCM00C ... CWTCM00G
    -----------------------------------------------------------------------------




         +-----------------------------------------------------------------+
      1. |   MCSID |   CNUM00 | BCHTCM00 | BCWTCM00 | CCHTCM00 | CCWTCM00  |
         | M10001N | 1st Coho |       97 |        . |    114.4 |     21.2  |
         |-----------------------------------------------------------------|
         | DCHTCM00 | DCWTCM00 | ECHTCM00 | ECWTCM00 | FCHTCM00 | FCWTCM00 |
         |    127.8 |     25.5 |        . |        . |        . |        . |
         |--------------------------------+--------------------------------|
         |            GCHTCM00            |            GCWTCM00            |
         |                   .            |                   .            |
         +-----------------------------------------------------------------+

         +-----------------------------------------------------------------+
      2. |   MCSID |   CNUM00 | BCHTCM00 | BCWTCM00 | CCHTCM00 | CCWTCM00  |
         | M10002P | 1st Coho |       96 |        . |    110.5 |     19.2  |
         |-----------------------------------------------------------------|
         | DCHTCM00 | DCWTCM00 | ECHTCM00 | ECWTCM00 | FCHTCM00 | FCWTCM00 |
         |      123 |     26.2 |    143.5 |     41.8 |    163.2 |     52.3 |
         |--------------------------------+--------------------------------|
         |            GCHTCM00            |            GCWTCM00            |
         |               174.1            |                59.4            |
         +-----------------------------------------------------------------+

         +-----------------------------------------------------------------+
      3. |   MCSID |   CNUM00 | BCHTCM00 | BCWTCM00 | CCHTCM00 | CCWTCM00  |
         | M10007U | 1st Coho |      102 |        . |      118 |     25.3  |
         |-----------------------------------------------------------------|
         | DCHTCM00 | DCWTCM00 | ECHTCM00 | ECWTCM00 | FCHTCM00 | FCWTCM00 |
         |      129 |     26.5 |    154.5 |     40.6 |    173.6 |     57.1 |
         |--------------------------------+--------------------------------|
         |            GCHTCM00            |            GCWTCM00            |
         |               180.6            |                71.4            |
         +-----------------------------------------------------------------+

         +-----------------------------------------------------------------+
      4. |   MCSID |   CNUM00 | BCHTCM00 | BCWTCM00 | CCHTCM00 | CCWTCM00  |
         | M10008V | 1st Coho |       -2 |        . |        . |        .  |
         |-----------------------------------------------------------------|
         | DCHTCM00 | DCWTCM00 | ECHTCM00 | ECWTCM00 | FCHTCM00 | FCWTCM00 |
         |        . |        . |        . |        . |        . |        . |
         |--------------------------------+--------------------------------|
         |            GCHTCM00            |            GCWTCM00            |
         |                   .            |                   .            |
         +-----------------------------------------------------------------+

         +-----------------------------------------------------------------+
      5. |   MCSID |   CNUM00 | BCHTCM00 | BCWTCM00 | CCHTCM00 | CCWTCM00  |
         | M10008V | 2nd Coho |       -2 |        . |        . |        .  |
         |-----------------------------------------------------------------|
         | DCHTCM00 | DCWTCM00 | ECHTCM00 | ECWTCM00 | FCHTCM00 | FCWTCM00 |
         |        . |        . |        . |        . |        . |        . |
         |--------------------------------+--------------------------------|
         |            GCHTCM00            |            GCWTCM00            |
         |                   .            |                   .            |
         +-----------------------------------------------------------------+

         +-----------------------------------------------------------------+
      6. |   MCSID |   CNUM00 | BCHTCM00 | BCWTCM00 | CCHTCM00 | CCWTCM00  |
         | M10011Q | 1st Coho |      106 |        . |      121 |     32.9  |
         |-----------------------------------------------------------------|
         | DCHTCM00 | DCWTCM00 | ECHTCM00 | ECWTCM00 | FCHTCM00 | FCWTCM00 |
         |      137 |     51.2 |    168.1 |       74 |        . |        . |
         |--------------------------------+--------------------------------|
         |            GCHTCM00            |            GCWTCM00            |
         |                   .            |                   .            |
         +-----------------------------------------------------------------+

         +-----------------------------------------------------------------+
      7. |   MCSID |   CNUM00 | BCHTCM00 | BCWTCM00 | CCHTCM00 | CCWTCM00  |
         | M10014T | 1st Coho |       97 |        . |        . |        .  |
         |-----------------------------------------------------------------|
         | DCHTCM00 | DCWTCM00 | ECHTCM00 | ECWTCM00 | FCHTCM00 | FCWTCM00 |
         |        . |        . |        . |        . |        . |        . |
         |--------------------------------+--------------------------------|
         |            GCHTCM00            |            GCWTCM00            |
         |                   .            |                   .            |
         +-----------------------------------------------------------------+

         +-----------------------------------------------------------------+
      8. |   MCSID |   CNUM00 | BCHTCM00 | BCWTCM00 | CCHTCM00 | CCWTCM00  |
         | M10015U | 1st Coho |       94 |        . |    110.3 |     19.7  |
         |-----------------------------------------------------------------|
         | DCHTCM00 | DCWTCM00 | ECHTCM00 | ECWTCM00 | FCHTCM00 | FCWTCM00 |
         |    121.5 |     24.1 |      143 |     38.2 |    163.9 |     56.2 |
         |--------------------------------+--------------------------------|
         |            GCHTCM00            |            GCWTCM00            |
         |                 169            |                75.7            |
         +-----------------------------------------------------------------+

         +-----------------------------------------------------------------+
      9. |   MCSID |   CNUM00 | BCHTCM00 | BCWTCM00 | CCHTCM00 | CCWTCM00  |
         | M10016V | 1st Coho |      102 |        . |    117.7 |       23  |
         |-----------------------------------------------------------------|
         | DCHTCM00 | DCWTCM00 | ECHTCM00 | ECWTCM00 | FCHTCM00 | FCWTCM00 |
         |      130 |       29 |    151.8 |     41.5 |      167 |     51.5 |
         |--------------------------------+--------------------------------|
         |            GCHTCM00            |            GCWTCM00            |
         |               185.1            |                74.1            |
         +-----------------------------------------------------------------+
    --more--

# Reshaping Cleaned Data from Long to Wide

It is likely that you will not just need to reshape raw data, but
cleaned data too. In the next two sections we offer advice on naming
variables so that they are easy to select and reshape in long or wide
formats. First, we clean the long dataset by converting the `CNUM00` and
`sweep` columns to integers, creating a new column for follow-up time,
and creating new `height` and `weight` variables that replace negative
values in the raw height and weight data with `.` (as well as giving
these variables more easy-to-understand names).

``` stata
rename *CWTCM00 CWTCM00*
rename *CHTCM00 CHTCM00*
reshape long CHTCM00 CWTCM00, i(MCSID CNUM00) j(sweep_letter) string
gen sweep = (strpos("`c(ALPHA)'", sweep_letter) + 1) / 2
gen fup = word("${fups}", sweep)
destring fup, replace

gen height = CHTCM00 if CHTCM00 > 0
gen weight = CWTCM00 if CWTCM00 > 0
keep MCSID CNUM00 fup height weight
list in 1/10
```




    (j = B C D E F G)

    Data                               Wide   ->   Long
    -----------------------------------------------------------------------------
    Number of observations           19,483   ->   116,898     
    Number of variables                  14   ->   5           
    j variable (6 values)                     ->   sweep_letter
    xij variables:
             CHTCM00B CHTCM00C ... CHTCM00G   ->   CHTCM00
             CWTCM00B CWTCM00C ... CWTCM00G   ->   CWTCM00
    -----------------------------------------------------------------------------



    fup: all characters numeric; replaced as byte

    (38,920 missing values generated)

    (54,396 missing values generated)



         +--------------------------------------------+
         |   MCSID     CNUM00   fup   height   weight |
         |--------------------------------------------|
      1. | M10001N   1st Coho     3       97        . |
      2. | M10001N   1st Coho     5    114.4     21.2 |
      3. | M10001N   1st Coho     7    127.8     25.5 |
      4. | M10001N   1st Coho    11        .        . |
      5. | M10001N   1st Coho    14        .        . |
         |--------------------------------------------|
      6. | M10001N   1st Coho    17        .        . |
      7. | M10002P   1st Coho     3       96        . |
      8. | M10002P   1st Coho     5    110.5     19.2 |
      9. | M10002P   1st Coho     7      123     26.2 |
     10. | M10002P   1st Coho    11    143.5     41.8 |
         +--------------------------------------------+

`c(ALPHA)` is an inbuilt macro which contains the letters of the
alphabet in upper-case with spaces between letters.
`` strpos("`c(ALPHA)'", alt_letter) `` finds the position of the
`alt_letter` (i.e., A, B, C, or D) in this string. Dividing by 2 and
adding 1 converts this to the corresponding `APNUM00` value (e.g., C
would be in the 5th position in the string \[`A B C ...`\]).

To reshape the clean data from long to wide format, we can use the
`reshape wide` command as before.

``` stata
reshape wide height weight, i(MCSID CNUM00) j(fup)
list in 1/10
```


    (j = 3 5 7 11 14 17)

    Data                               Long   ->   Wide
    -----------------------------------------------------------------------------
    Number of observations          116,898   ->   19,483      
    Number of variables                   5   ->   14          
    j variable (6 values)               fup   ->   (dropped)
    xij variables:
                                     height   ->   height3 height5 ... height17
                                     weight   ->   weight3 weight5 ... weight17
    -----------------------------------------------------------------------------


         +----------------------------------------------------------------------+
      1. |   MCSID |   CNUM00 | height3 | weight3 | height5 | weight5 | height7 |
         | M10001N | 1st Coho |      97 |       . |   114.4 |    21.2 |   127.8 |
         |----------------------------------------------------------------------|
         | weight7  | height11  | weight11  | height14  | weight14  | height17  |
         |    25.5  |        .  |        .  |        .  |        .  |        .  |
         |----------------------------------------------------------------------|
         |                               weight17                               |
         |                                      .                               |
         +----------------------------------------------------------------------+

         +----------------------------------------------------------------------+
      2. |   MCSID |   CNUM00 | height3 | weight3 | height5 | weight5 | height7 |
         | M10002P | 1st Coho |      96 |       . |   110.5 |    19.2 |     123 |
         |----------------------------------------------------------------------|
         | weight7  | height11  | weight11  | height14  | weight14  | height17  |
         |    26.2  |    143.5  |     41.8  |    163.2  |     52.3  |    174.1  |
         |----------------------------------------------------------------------|
         |                               weight17                               |
         |                                   59.4                               |
         +----------------------------------------------------------------------+

         +----------------------------------------------------------------------+
      3. |   MCSID |   CNUM00 | height3 | weight3 | height5 | weight5 | height7 |
         | M10007U | 1st Coho |     102 |       . |     118 |    25.3 |     129 |
         |----------------------------------------------------------------------|
         | weight7  | height11  | weight11  | height14  | weight14  | height17  |
         |    26.5  |    154.5  |     40.6  |    173.6  |     57.1  |    180.6  |
         |----------------------------------------------------------------------|
         |                               weight17                               |
         |                                   71.4                               |
         +----------------------------------------------------------------------+

         +----------------------------------------------------------------------+
      4. |   MCSID |   CNUM00 | height3 | weight3 | height5 | weight5 | height7 |
         | M10008V | 1st Coho |       . |       . |       . |       . |       . |
         |----------------------------------------------------------------------|
         | weight7  | height11  | weight11  | height14  | weight14  | height17  |
         |       .  |        .  |        .  |        .  |        .  |        .  |
         |----------------------------------------------------------------------|
         |                               weight17                               |
         |                                      .                               |
         +----------------------------------------------------------------------+

         +----------------------------------------------------------------------+
      5. |   MCSID |   CNUM00 | height3 | weight3 | height5 | weight5 | height7 |
         | M10008V | 2nd Coho |       . |       . |       . |       . |       . |
         |----------------------------------------------------------------------|
         | weight7  | height11  | weight11  | height14  | weight14  | height17  |
         |       .  |        .  |        .  |        .  |        .  |        .  |
         |----------------------------------------------------------------------|
         |                               weight17                               |
         |                                      .                               |
         +----------------------------------------------------------------------+

         +----------------------------------------------------------------------+
      6. |   MCSID |   CNUM00 | height3 | weight3 | height5 | weight5 | height7 |
         | M10011Q | 1st Coho |     106 |       . |     121 |    32.9 |     137 |
         |----------------------------------------------------------------------|
         | weight7  | height11  | weight11  | height14  | weight14  | height17  |
         |    51.2  |    168.1  |       74  |        .  |        .  |        .  |
         |----------------------------------------------------------------------|
         |                               weight17                               |
         |                                      .                               |
         +----------------------------------------------------------------------+

         +----------------------------------------------------------------------+
      7. |   MCSID |   CNUM00 | height3 | weight3 | height5 | weight5 | height7 |
         | M10014T | 1st Coho |      97 |       . |       . |       . |       . |
         |----------------------------------------------------------------------|
         | weight7  | height11  | weight11  | height14  | weight14  | height17  |
         |       .  |        .  |        .  |        .  |        .  |        .  |
         |----------------------------------------------------------------------|
         |                               weight17                               |
         |                                      .                               |
         +----------------------------------------------------------------------+

         +----------------------------------------------------------------------+
      8. |   MCSID |   CNUM00 | height3 | weight3 | height5 | weight5 | height7 |
         | M10015U | 1st Coho |      94 |       . |   110.3 |    19.7 |   121.5 |
         |----------------------------------------------------------------------|
         | weight7  | height11  | weight11  | height14  | weight14  | height17  |
         |    24.1  |      143  |     38.2  |    163.9  |     56.2  |      169  |
         |----------------------------------------------------------------------|
         |                               weight17                               |
         |                                   75.7                               |
         +----------------------------------------------------------------------+

         +----------------------------------------------------------------------+
      9. |   MCSID |   CNUM00 | height3 | weight3 | height5 | weight5 | height7 |
         | M10016V | 1st Coho |     102 |       . |   117.7 |      23 |     130 |
         |----------------------------------------------------------------------|
         | weight7  | height11  | weight11  | height14  | weight14  | height17  |
         |      29  |    151.8  |     41.5  |      167  |     51.5  |    185.1  |
         |----------------------------------------------------------------------|
         |                               weight17                               |
         |                                   74.1                               |
         +----------------------------------------------------------------------+
    --more--

# Reshaping Cleaned Data from Wide to Long

Finally, we can reshape the clean wide dataset back to long format using
the `reshape long` command.

``` stata
reshape long height weight, i(MCSID CNUM00) j(fup)
list in 1/10
```


    (j = 3 5 7 11 14 17)

    Data                               Wide   ->   Long
    -----------------------------------------------------------------------------
    Number of observations           19,483   ->   116,898     
    Number of variables                  14   ->   5           
    j variable (6 values)                     ->   fup
    xij variables:
               height3 height5 ... height17   ->   height
               weight3 weight5 ... weight17   ->   weight
    -----------------------------------------------------------------------------


         +--------------------------------------------+
         |   MCSID     CNUM00   fup   height   weight |
         |--------------------------------------------|
      1. | M10001N   1st Coho     3       97        . |
      2. | M10001N   1st Coho     5    114.4     21.2 |
      3. | M10001N   1st Coho     7    127.8     25.5 |
      4. | M10001N   1st Coho    11        .        . |
      5. | M10001N   1st Coho    14        .        . |
         |--------------------------------------------|
      6. | M10001N   1st Coho    17        .        . |
      7. | M10002P   1st Coho     3       96        . |
      8. | M10002P   1st Coho     5    110.5     19.2 |
      9. | M10002P   1st Coho     7      123     26.2 |
     10. | M10002P   1st Coho    11    143.5     41.8 |
         +--------------------------------------------+
