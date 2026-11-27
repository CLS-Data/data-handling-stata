---
layout: default
title: Reshaping Data from Long to Wide (or Wide to Long)
nav_order: 6
parent: Next Steps
format:
  gfm:
    variant: +yaml_metadata_block
jupyter: stata
---


- [Download the Stata script for this
  page](../do_files/next_steps-reshape_long_wide.do)

# Introduction

In this section, we show how to reshape data from long to wide (and vice
versa). We do this for both raw and cleaned data. To demonstrate, we use
data on cohort members’ height and weight collected in Sweeps 8 and 9
(ages 25 and 32).

# Reshaping Raw Data from Wide to Long

We begin by loading the data from each sweep and merging these together
into a single wide format dataset; see [Combining Data Across
Sweeps](https://cls-data.github.io/data-handling-stata/docs/next_steps-merging_across_sweeps.html)
for further explanation on how this is achieved. Height and weight are
stored in the main interview files for Sweeps 8 and 9
(`ns8_2015_main_interview.dta` and `ns9_2022_main_interview.dta`, both
in the `safeguarded_eul` subfolder). The names of the height and weight
variables follow the same convention in the two sweeps, differing only
in the prefix that denotes the sweep (`W8HEIGHT` and `W9HEIGHT`;
`W8WEIGHT` and `W9WEIGHT`). This is typical for variables collected in
Sweeps 8 and 9, but [not for variables collected in both earlier and
later
sweeps](https://cls-data.github.io/data-handling-stata/docs/next_steps-data_structures.html),
which usually need to be renamed before they can be reshaped. Below,
`order` and `sort` are used to arrange the columns and rows of the
merged dataset.

``` stata
use NSID W8HEIGHT W8WEIGHT using "safeguarded_eul/ns8_2015_main_interview.dta", clear
save "temp_w8.dta", replace

use NSID W9HEIGHT W9WEIGHT using "safeguarded_eul/ns9_2022_main_interview.dta", clear
merge 1:1 NSID using "temp_w8.dta", nogenerate
order NSID W8HEIGHT W8WEIGHT W9HEIGHT W9WEIGHT
sort NSID
list in 1/10
```

    (:49'G:\DB\dbdeposit\lsype\deposits\Checks\NS8\NS8_2015_Main_Inte)
    file temp_w8.dta saved
    (File created by user 'qtnznhm' at Wed Aug  7 12:02:49 2024)

        Result                      Number of obs
        -----------------------------------------
        Not matched                         3,832
            from master                     1,703  
            from using                      2,129  

        Matched                             5,576  
        -----------------------------------------

         +--------------------------------------------------------------+
         |     NSID   W8HEIGHT       W8WEIGHT       W9HEIGHT   W9WEIGHT |
         |--------------------------------------------------------------|
      1. | NS10001S       1.85          73.03              .          . |
      2. | NS10002T          .              .           1.68         57 |
      3. | NS10004W       1.55          55.34   Not applicab         51 |
      4. | NS10006Y          .              .           1.55     109.32 |
      5. | NS10011M       1.73             75   Not applicab         89 |
         |--------------------------------------------------------------|
      6. | NS10017T          .              .           1.78      85.28 |
      7. | NS10018V          .              .           1.65         61 |
      8. | NS10019W          .              .           1.57      64.41 |
      9. | NS10020F       1.83   Not applicab   Not applicab        100 |
     10. | NS10021G       1.85          73.48   Not applicab      84.82 |
         +--------------------------------------------------------------+

The dataset has 5 variables. Besides the identifier, `NSID`, there are 4
variables for height and weight measurements at each sweep. Each of
these 4 variables is prefixed by the letter `W` and a single digit
indicating the sweep. We can reshape the dataset into long format (one
row per person x sweep combination) using the `reshape long` command so
that the resulting dataset has four variables: one person identifier, a
variable for sweep, and variables for height and weight. By default,
`reshape long` expects the variables that are to be reshaped to be named
in a specific format: `stub` + `suffix`.[^1] Here, we want our stubs to
be `HEIGHT` and `WEIGHT`, and our suffixes to be the sweep numbers (8
and 9). As the sweep number is currently towards the start of the
variable names, we first rename the variables to match this format. In
the `rename` command, `#` is a wildcard that stands for one or more
digits, so `W8HEIGHT` is renamed `HEIGHT8`, `W9HEIGHT` is renamed
`HEIGHT9`, and so on. Then in the `reshape long` command, we specify the
stubs in the main command, with the identifier and suffix variables
specified in the `i()` and `j()` command options respectively. Note the
identifier (`i()`) exists in the data, while the suffix variable (`j()`)
is created during the reshape process.

``` stata
rename (W#HEIGHT W#WEIGHT) (HEIGHT# WEIGHT#) // Moves the sweep number to the end of the name, where reshape expects it by default
reshape long HEIGHT WEIGHT, i(NSID) j(sweep)
list in 1/10
```

    (j = 8 9)

    Data                               Wide   ->   Long
    -----------------------------------------------------------------------------
    Number of observations            9,408   ->   18,816      
    Number of variables                   5   ->   4           
    j variable (2 values)                     ->   sweep
    xij variables:
                            HEIGHT8 HEIGHT9   ->   HEIGHT
                            WEIGHT8 WEIGHT9   ->   WEIGHT
    -----------------------------------------------------------------------------

         +------------------------------------------+
         |     NSID   sweep         HEIGHT   WEIGHT |
         |------------------------------------------|
      1. | NS10001S       8           1.85    73.03 |
      2. | NS10001S       9              .        . |
      3. | NS10002T       8              .        . |
      4. | NS10002T       9           1.68       57 |
      5. | NS10004W       8           1.55    55.34 |
         |------------------------------------------|
      6. | NS10004W       9   Not applicab       51 |
      7. | NS10006Y       8              .        . |
      8. | NS10006Y       9           1.55   109.32 |
      9. | NS10011M       8           1.73       75 |
     10. | NS10011M       9   Not applicab       89 |
         +------------------------------------------+

Note, when reshaping to long format, multiple variables are effectively
appended together, so the reshaped variables can only have one set of
value labels. In this case, the value labels attached to the Sweep 8 and
Sweep 9 variables are not identical (for instance, `-8` is labelled
“Insufficient information” in Sweep 8 and “Don’t know” in Sweep 9).
`reshape long` does not print a warning about this. It keeps the value
labels of one variable in each set (here, those of the Sweep 9
variables), so values from Sweep 8 are displayed with the Sweep 9
labels, and the original labels are not restored if the data are later
reshaped back to wide format. Where this is a concern, value labels can
be removed before the variables are renamed and reshaped using
`label values` (for instance,
`label values W8HEIGHT W8WEIGHT W9HEIGHT W9WEIGHT .`).

# Reshaping Raw Data from Long to Wide

We can reshape the data from long to wide format using the
`reshape wide` command. We again specify the stubs in the main command,
and the identifier and suffix variables in `i()` and `j()`,
respectively. The suffix variable exists in the data, and its values are
used to create the new variable names during the reshape process. We
then use `rename` to return the variables to their original names, with
the sweep number following the initial `W`.

``` stata
reshape wide HEIGHT WEIGHT, i(NSID) j(sweep)
rename (HEIGHT# WEIGHT#) (W#HEIGHT W#WEIGHT)
list in 1/10
```

    (j = 8 9)

    Data                               Long   ->   Wide
    -----------------------------------------------------------------------------
    Number of observations           18,816   ->   9,408       
    Number of variables                   4   ->   5           
    j variable (2 values)             sweep   ->   (dropped)
    xij variables:
                                     HEIGHT   ->   HEIGHT8 HEIGHT9
                                     WEIGHT   ->   WEIGHT8 WEIGHT9
    -----------------------------------------------------------------------------

         +--------------------------------------------------------------+
         |     NSID   W8HEIGHT       W8WEIGHT       W9HEIGHT   W9WEIGHT |
         |--------------------------------------------------------------|
      1. | NS10001S       1.85          73.03              .          . |
      2. | NS10002T          .              .           1.68         57 |
      3. | NS10004W       1.55          55.34   Not applicab         51 |
      4. | NS10006Y          .              .           1.55     109.32 |
      5. | NS10011M       1.73             75   Not applicab         89 |
         |--------------------------------------------------------------|
      6. | NS10017T          .              .           1.78      85.28 |
      7. | NS10018V          .              .           1.65         61 |
      8. | NS10019W          .              .           1.57      64.41 |
      9. | NS10020F       1.83   Not applicab   Not applicab        100 |
     10. | NS10021G       1.85          73.48   Not applicab      84.82 |
         +--------------------------------------------------------------+

# Reshaping Cleaned Data from Long to Wide

It is likely that you will not just need to reshape raw data, but
cleaned data too. In the next two sections we offer advice on naming
variables so that they are easy to select and reshape in long or wide
formats. First, we reshape the raw data to long format once more and
clean it by creating a new variable for the cohort member’s age at each
sweep, and creating new `height` and `weight` variables that replace
negative values in the raw height and weight data with `.` (as well as
giving these variables more easy-to-understand names). To create the age
variable, we create a global macro, `ages`, which contains the
(approximate) age of cohort members at each of the nine sweeps, and use
the `word()` function to pick out the entry for the relevant sweep
(i.e., `word("${ages}", 8)` returns `25`). As `word()` returns text, we
use `real()` to convert the result to a number. We create the `height`
and `weight` variables with `gen double` so that no precision is lost
when the values are copied: by default, `gen` creates variables of type
`float`, which hold fewer significant digits than variables of type
`double`.

``` stata
global ages 14 15 16 17 18 19 20 25 32

rename (W#HEIGHT W#WEIGHT) (HEIGHT# WEIGHT#)
reshape long HEIGHT WEIGHT, i(NSID) j(sweep)
gen age = real(word("${ages}", sweep))
gen double height = HEIGHT if HEIGHT > 0 // double keeps the full precision of the raw values
gen double weight = WEIGHT if WEIGHT > 0
keep NSID age height weight
list in 1/10
```

    (j = 8 9)

    Data                               Wide   ->   Long
    -----------------------------------------------------------------------------
    Number of observations            9,408   ->   18,816      
    Number of variables                   5   ->   4           
    j variable (2 values)                     ->   sweep
    xij variables:
                            HEIGHT8 HEIGHT9   ->   HEIGHT
                            WEIGHT8 WEIGHT9   ->   WEIGHT
    -----------------------------------------------------------------------------
    (9,687 missing values generated)
    (4,992 missing values generated)

         +----------------------------------+
         |     NSID   age   height   weight |
         |----------------------------------|
      1. | NS10001S    25     1.85    73.03 |
      2. | NS10001S    32        .        . |
      3. | NS10002T    25        .        . |
      4. | NS10002T    32     1.68       57 |
      5. | NS10004W    25     1.55    55.34 |
         |----------------------------------|
      6. | NS10004W    32        .       51 |
      7. | NS10006Y    25        .        . |
      8. | NS10006Y    32     1.55   109.32 |
      9. | NS10011M    25     1.73       75 |
     10. | NS10011M    32        .       89 |
         +----------------------------------+

To reshape the clean data from long to wide format, we can use the
`reshape wide` command as before. This time, we specify the variable
containing the cohort member’s age in `j()`, so that the new variable
names end with the age at measurement (`height25`, `height32`, and so
on). We then use `rename` to add an underscore between the stub and the
age.

``` stata
reshape wide height weight, i(NSID) j(age)
rename (height# weight#) (height_# weight_#)
list in 1/10
```

    (j = 25 32)

    Data                               Long   ->   Wide
    -----------------------------------------------------------------------------
    Number of observations           18,816   ->   9,408       
    Number of variables                   4   ->   5           
    j variable (2 values)               age   ->   (dropped)
    xij variables:
                                     height   ->   height25 height32
                                     weight   ->   weight25 weight32
    -----------------------------------------------------------------------------

         +------------------------------------------------------+
         |     NSID   heigh~25   weigh~25   heigh~32   weigh~32 |
         |------------------------------------------------------|
      1. | NS10001S       1.85      73.03          .          . |
      2. | NS10002T          .          .       1.68         57 |
      3. | NS10004W       1.55      55.34          .         51 |
      4. | NS10006Y          .          .       1.55     109.32 |
      5. | NS10011M       1.73         75          .         89 |
         |------------------------------------------------------|
      6. | NS10017T          .          .       1.78      85.28 |
      7. | NS10018V          .          .       1.65         61 |
      8. | NS10019W          .          .       1.57      64.41 |
      9. | NS10020F       1.83          .          .        100 |
     10. | NS10021G       1.85      73.48          .      84.82 |
         +------------------------------------------------------+

Notice that the new variable names consist of a descriptive stub, an
underscore, and the age at measurement (in the output above, `list`
shortens the names - `height_25` is displayed as `heigh~25`, for
instance). A consistent convention such as this makes it simple to refer
to groups of variables using wildcards, either by name (e.g.,
`height_??`) or by numerical range (e.g., `?eight_2?`).[^2] As cohort
members were aged between 14 and 32 in Sweeps 1-9, the age is always two
characters long. In studies that include measurements from earlier in
life, it is worth padding ages with a leading zero (e.g., `height_05`)
so that the names of similar variables are the same length.

# Reshaping Cleaned Data from Wide to Long

Finally, we can reshape the clean wide dataset back to long format using
the `reshape long` command. As the variable names now include an
underscore before the age, we specify the stubs as `height_` and
`weight_`, and then use `rename` to remove the underscores from the
names of the reshaped variables. Note how easy it is to specify the
variables we want to reshape: because we used a consistent naming
structure for the cleaned variables, we only need to give `reshape long`
the two stubs.

``` stata
reshape long height_ weight_, i(NSID) j(age)
rename (height_ weight_) (height weight)
list in 1/10
```

    (j = 25 32)

    Data                               Wide   ->   Long
    -----------------------------------------------------------------------------
    Number of observations            9,408   ->   18,816      
    Number of variables                   5   ->   4           
    j variable (2 values)                     ->   age
    xij variables:
                        height_25 height_32   ->   height_
                        weight_25 weight_32   ->   weight_
    -----------------------------------------------------------------------------

         +----------------------------------+
         |     NSID   age   height   weight |
         |----------------------------------|
      1. | NS10001S    25     1.85    73.03 |
      2. | NS10001S    32        .        . |
      3. | NS10002T    25        .        . |
      4. | NS10002T    32     1.68       57 |
      5. | NS10004W    25     1.55    55.34 |
         |----------------------------------|
      6. | NS10004W    32        .       51 |
      7. | NS10006Y    25        .        . |
      8. | NS10006Y    32     1.55   109.32 |
      9. | NS10011M    25     1.73       75 |
     10. | NS10011M    32        .       89 |
         +----------------------------------+

[^1]: The position of the suffix can instead be marked with an `@` in
    the stub. For instance,
    `reshape long W@HEIGHT W@WEIGHT, i(NSID) j(sweep)` would reshape the
    data without the variables being renamed first, though the reshaped
    variables would then be named `WHEIGHT` and `WWEIGHT`.

[^2]: In `Stata`, `?` is a wildcard that stands for exactly one
    character and `*` is a wildcard that stands for zero or more
    characters. `height_??` therefore matches any variable name that
    begins `height_` and is followed by exactly two characters, while
    `?eight_2?` matches the height and weight variables measured between
    ages 20 and 29 (here, `height_25` and `weight_25`).
