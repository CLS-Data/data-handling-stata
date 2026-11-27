---
layout: default
title: Working with the Household Grid
nav_order: 3
parent: Next Steps
format:
  gfm:
    variant: +yaml_metadata_block
jupyter: stata
---


- [Download the Stata script for this
  page](../do_files/next_steps-household_grid.do)

# Introduction

In this section, we describe the basics of using the household grid.
Specifically, we show how to use the household grid to:

1.  Identify particular family members

2.  Create family-member specific variables

3.  Find out who the “main parent” and “second parent” are, and whether
    these are the same people in each sweep

4.  Determine the relationships between other members of the household.

# Finding Mother of Cohort Members

To show how to perform 1 & 2, we use the example of finding natural
mothers’ employment status at the first sweep. The household grids are
stored in their own subfolder, `household_grids`. The Sweep 1 household
grid (`household_grids/wave_one_lsype_household_grid_file_2020.dta`) has
one row for each member of the cohort member’s household, [including the
cohort member
themselves](https://cls-data.github.io/data-handling-stata/docs/next_steps-data_structures.html).
We load just five variables: `NSID` and `W1HhID`, which together
uniquely identify an individual, `W1Sex` and `W1R_1`, which contain
information on the individual’s sex and their relationship to the cohort
member, and `W1EmpStat`, which contains their employment status.

`W1HhID` is the individual’s person number within the household. The
cohort member is always person number 1. The household grid records the
relationships between household members in the variables `W1R_1`,
`W1R_2`, …, `W1R_14`; the number at the end of the variable name is the
person number of the *other* household member. `W1R_1` therefore records
the relationship of the person in the row to person number 1 - that is,
to the cohort member.

`W1R_1 == 8` identifies natural parents and `W1Sex == 2` identifies
females. Combining the two identifies natural mothers. Below, we use
`tabulate` to show the different (observed) values for the sex and
relationship variables; `numlabel, add` adds the numeric values to the
value labels, so that both are displayed in the tables. We also use
`keep if` to retain rows for natural mothers only, keeping the person
identifiers (`NSID` and `W1HhID`) and employment status.
`bysort NSID: gen n = _N` followed by `keep if n == 1` is included as an
interim step to ensure there is just one natural mother per family.

``` stata
use NSID W1HhID W1Sex W1R_1 W1EmpStat using "household_grids/wave_one_lsype_household_grid_file_2020.dta", clear
numlabel, add // Adds numeric values to value labels
tabulate W1Sex
tabulate W1R_1
keep if W1R_1 == 8 & W1Sex == 2
bysort NSID: gen n = _N
keep if n == 1
drop n
keep NSID W1HhID W1EmpStat
```


                         Sex of this person |      Freq.     Percent        Cum.
    ----------------------------------------+-----------------------------------
               -999. Missing household data |        104        0.15        0.15
                                    1. Male |     33,916       48.04       48.19
                                  2. Female |     36,573       51.81      100.00
    ----------------------------------------+-----------------------------------
                                      Total |     70,593      100.00

         Relationship to household member 1 |      Freq.     Percent        Cum.
    ----------------------------------------+-----------------------------------
               -999. Missing household data |        104        0.15        0.15
                               -92. Refused |         26        0.04        0.18
                        -91. Not applicable |     15,656       22.18       22.36
                           1. Husband/ Wife |          1        0.00       22.36
                   3. Natural son/ daughter |          3        0.00       22.37
                            5. Foster child |          2        0.00       22.37
                 6. Step-son/ Step-daughter |          1        0.00       22.37
                          8. Natural parent |     24,959       35.36       57.73
                         9. Adoptive parent |        152        0.22       57.94
                          10. Foster parent |        138        0.20       58.14
                            11. Step-parent |      1,685        2.39       60.53
        12. Parent-in-law/ Partner's parent |         17        0.02       60.55
                13. Natural brother/ sister |     23,658       33.51       94.06
                  14. Half-brother/ -sister |      1,456        2.06       96.13
                  15. Step-brother/ -sister |        492        0.70       96.82
                16. Adopted brother/ sister |         65        0.09       96.91
          17. Foster brother/ Foster sister |        151        0.21       97.13
          18. Brother-in-law/ Sister-in-law |        186        0.26       97.39
                             19. Grandchild |          3        0.00       97.40
                            20. Grandparent |        722        1.02       98.42
                         21. Other relative |        791        1.12       99.54
                     22. Other non-relative |        325        0.46      100.00
    ----------------------------------------+-----------------------------------
                                      Total |     70,593      100.00
    (55,834 observations deleted)
    (4 observations deleted)

Note, there is one cohort member per family in Next Steps. There is,
therefore, no ambiguity about which cohort member a relationship refers
to.

# Creating a Mother’s Employment Variable

Unlike in the [Millennium Cohort
Study](https://cls-data.github.io/data-handling-stata/docs/mcs-household_grid.html),
the Next Steps household grid holds several characteristics of each
household member, including their employment status (`W1EmpStat`),
marital status (`W1MarStat`) and ethnic group (`W1EthGrp`). Having
identified natural mothers, we can therefore create a variable for
whether the cohort member’s mother is in paid work directly. `W1EmpStat`
takes the values `1` and `2` for individuals in full-time and part-time
paid work, respectively, and values between `3` and `9` for other
statuses (e.g., looking after the family or household). Below, we use
`gen` (short for `generate`) and `replace` with the `inrange()` function
to create a binary variable, `mother_works`, and use `tabulate` to show
the number and percentage of mothers who are and are not in paid work.
`mother_works` is left as missing (`.`) where `W1EmpStat` has any other
value (for instance, the negative values used for missing data); the
`missing` option tells `tabulate` to include a row for these mothers.

``` stata
tabulate W1EmpStat
gen mother_works = .
replace mother_works = 1 if inrange(W1EmpStat, 1, 2)
replace mother_works = 0 if inrange(W1EmpStat, 3, 9)
keep NSID mother_works
tabulate mother_works, missing
```


           Employment status of this person |      Freq.     Percent        Cum.
    ----------------------------------------+-----------------------------------
                               -92. Refused |          3        0.02        0.02
                        -91. Not applicable |         51        0.35        0.37
    1. Doing paid work for 30 or more hours |      4,727       32.04       32.40
    2. Doing paid work for fewer than 30 ho |      4,649       31.51       63.91
           3. Unemployed/ Looking for a job |        212        1.44       65.35
          4. On a training course or scheme |         86        0.58       65.93
       5. In full-time education/ at school |        155        1.05       66.98
     6. Looking after the family/ household |      4,510       30.57       97.55
            7. Retired from work altogether |         22        0.15       97.70
                          8. Sick/ disabled |        256        1.74       99.43
                                   9. Other |         79        0.54       99.97
                                         11 |          3        0.02       99.99
                             12. Not Stated |          2        0.01      100.00
    ----------------------------------------+-----------------------------------
                                      Total |     14,755      100.00
    (14,755 missing values generated)
    (9,376 real changes made)
    (5,320 real changes made)

    mother_work |
              s |      Freq.     Percent        Cum.
    ------------+-----------------------------------
              0 |      5,320       36.06       36.06
              1 |      9,376       63.54       99.60
              . |         59        0.40      100.00
    ------------+-----------------------------------
          Total |     14,755      100.00

The result is a dataset with one row per family with an identified
natural mother, which can be merged with other cohort member-level
datasets using `NSID`. Note, the family background files contain derived
variables for some characteristics of the cohort member’s mother and
father (in this case, `W1empsmum` and `W1empsdad` in
`safeguarded_eul/wave_one_lsype_family_background_2020.dta`). The
approach shown here is needed where a derived variable is not available,
or where you are interested in other family members, such as siblings or
grandparents.

# Identifying the Main and Second Parent

In Sweeps 1-4, [interviews were conducted with a “main parent” and a
“second
parent”](https://cls-data.github.io/data-handling-stata/docs/next_steps-data_structures.html).
Variables relating to these individuals are suffixed `MP` and `SP` (for
example, `W1hiqualgMP` and `W1hiqualgSP` in
`safeguarded_eul/wave_one_lsype_family_background_2020.dta`). To
interpret these variables, it is helpful to know who the main and second
parent are.

The household grid contains the variables `W1mainres` and `W1secores`,
which record the person numbers of the main parent and second parent,
respectively. These variables take the same value for every member of a
household. Below, we create a variable, `role`, by comparing each
individual’s person number (`W1HhID`) to these variables, and drop the
rows for individuals who are neither the main nor the second parent. We
then tabulate main and second parents’ relationship to the cohort member
against their sex; `bysort role:` repeats the `tabulate` command for
each value of `role`.

``` stata
use NSID W1HhID W1Sex W1R_1 W1mainres W1secores using "household_grids/wave_one_lsype_household_grid_file_2020.dta", clear
gen role = "Main parent" if W1HhID == W1mainres
replace role = "Second parent" if W1HhID == W1secores & role == ""
drop if role == ""
bysort role: tabulate W1R_1 W1Sex
```

    (54,971 missing values generated)
    variable role was str11 now str13
    (11,267 real changes made)
    (43,704 observations deleted)

    -------------------------------------------------------------------------------
    -> role = Main parent

          Relationship to |  Sex of this person
       household member 1 |      Male     Female |     Total
    ----------------------+----------------------+----------
                  Refused |         0          4 |         4 
           Natural parent |     2,598     12,485 |    15,083 
          Adoptive parent |        16         62 |        78 
            Foster parent |        11         71 |        82 
              Step-parent |        79         61 |       140 
    Parent-in-law/ Partne |         0          1 |         1 
    Natural brother/ sist |        34         36 |        70 
    Half-brother/ -sister |         1          1 |         2 
    Foster brother/ Foste |         0          1 |         1 
    Brother-in-law/ Siste |         1          1 |         2 
              Grandparent |        16         85 |       101 
           Other relative |        12         35 |        47 
       Other non-relative |         2          9 |        11 
    ----------------------+----------------------+----------
                    Total |     2,770     12,852 |    15,622 

    -------------------------------------------------------------------------------
    -> role = Second parent

          Relationship to |  Sex of this person
       household member 1 |      Male     Female |     Total
    ----------------------+----------------------+----------
           Natural parent |     7,544      2,218 |     9,762 
          Adoptive parent |        60         11 |        71 
            Foster parent |        45          9 |        54 
              Step-parent |     1,263        111 |     1,374 
    Natural brother/ sist |         5          1 |         6 
    ----------------------+----------------------+----------
                    Total |     8,917      2,350 |    11,267 

The resulting dataset has one row per parent. It can be used to create
variables for a specific type of parent from the `MP` and `SP`
variables. We show an example of this in [*Combining Data Within A
Sweep*](https://cls-data.github.io/data-handling-stata/docs/next_steps-merging_within_sweep.html).

## Changes in the Main and Second Parent Across Sweeps

The main and second parent are roles in the interview rather than fixed
individuals: the person interviewed as the main parent in one sweep is
not necessarily the person interviewed as the main parent in the next.
This matters when using `MP` and `SP` variables from more than one
sweep.

A household member is intended to keep the same person number in each
sweep, so we can check whether the main parent has changed by comparing
the person number of the main parent across sweeps. Below, we do this
for Sweeps 1 and 2. For each sweep, we load the household grid, keep the
row for the main parent, and rename their person number so that it has a
different name in each sweep (`w1_main_hhid` and `w2_main_hhid`). (The
Sweep 2 household grid,
`household_grids/wave_two_lsype_household_grid_file_2020.dta`, contains
equivalent variables to the Sweep 1 grid, with the prefix `W2` rather
than `W1`.) We save the Sweep 1 dataset (`temp_w1_main.dta`) so that it
can be merged with the Sweep 2 dataset.

``` stata
use NSID W1HhID W1mainres using "household_grids/wave_one_lsype_household_grid_file_2020.dta", clear
keep if W1HhID == W1mainres
rename W1HhID w1_main_hhid
keep NSID w1_main_hhid
save "temp_w1_main.dta", replace

use NSID W2HhID W2mainres using "household_grids/wave_two_lsype_household_grid_file_2020.dta", clear
keep if W2HhID == W2mainres
rename W2HhID w2_main_hhid
keep NSID w2_main_hhid
```

    (54,971 observations deleted)
    file temp_w1_main.dta saved
    (48,766 observations deleted)

We then merge the two datasets using `merge`. We specify `1:1` to
indicate a one-to-one merge on the identifier `NSID` (i.e., there is at
most one row per cohort member in each dataset) and `keep(match)` so
that we keep the families where a main parent was identified in both
sweeps. The `nogenerate` option ensures that `Stata` does not create the
`_merge` variable. Finally, we create a variable, `same_person`, which
is equal to `1` where the main parent has the same person number in the
two sweeps and `0` where they do not, and tabulate it.

``` stata
merge 1:1 NSID using "temp_w1_main.dta", keep(match) nogenerate
gen same_person = w1_main_hhid == w2_main_hhid
tabulate same_person
```


        Result                      Number of obs
        -----------------------------------------
        Not matched                             0
        Matched                            13,435  
        -----------------------------------------

    same_person |      Freq.     Percent        Cum.
    ------------+-----------------------------------
              0 |      1,223        9.10        9.10
              1 |     12,212       90.90      100.00
    ------------+-----------------------------------
          Total |     13,435      100.00

Where the main parent is not the same person in the two sweeps, a
variable such as `W2hiqualgMP` describes a different person to
`W1hiqualgMP`. Where this matters for your analysis, you could restrict
the sample to families where the main parent is unchanged, or use the
approach shown above to create variables for a particular parent (e.g.,
the mother) in each sweep.

# Determining Relationships between Other Household Members

So far we have only used `W1R_1`, the relationship of each household
member to the cohort member. The remaining relationship variables
(`W1R_2` to `W1R_14`) can be used to identify the relationships between
other members of the household. Specifically, they record the person in
the row’s (ego) relationship to the person denoted by the column
(alter); the number at the end of the variable name corresponds to the
alter’s `W1HhID`. For instance, the variable `W1R_2` denotes the
relationship of the person in the row to the person in the same
household with `W1HhID == 2`. Below, we extract a small set of data from
the Sweep 1 household grid to show this in action. `if NSID == NSID[1]`
selects the rows with the same `NSID` as the first row of the dataset,
so that we look at just one household.

``` stata
use NSID W1HhID W1R_* using "household_grids/wave_one_lsype_household_grid_file_2020.dta", clear
list W1HhID W1R_1 W1R_2 W1R_3 if NSID == NSID[1]
```


           +-----------------------------------------+
           | W1HhID      W1R_1      W1R_2      W1R_3 |
           |-----------------------------------------|
        1. |      1   Not appl   Not appl   Not appl |
        2. |      2    Natural   Not appl   Not appl |
        3. |      3   Step-par   Husband/   Not appl |
        4. |      4    Natural    Natural   Step-son |
           +-----------------------------------------+

Each row shows the relationships of one household member to the first
three people in the household. (`list` displays the value labels of
these variables rather than the underlying numeric values. Long labels
may be cut off, as `list` shows no more characters than the width of a
variable’s display format. Adding the `nolabel` option to the command
would display the numeric values instead.) For instance, where the
person with `W1HhID == 2` is the natural parent of the cohort member,
their row has `W1R_1 == 8 [Natural parent]`. Note, each relationship is
only recorded once, in the row of the person with the *higher* person
number: a relationship variable is only filled in where the individual’s
`W1HhID` is greater than the number at the end of the variable name, and
is otherwise coded as not applicable (`-91`). `W1R_2`, for instance, is
only filled in for individuals with a `W1HhID` of 3 or more, and every
relationship variable is coded as not applicable for the cohort member
(`W1HhID == 1`). The relationship in the other direction is not recorded
and has to be inferred - if the person with `W1HhID == 2` is the natural
parent of the cohort member, then the cohort member is the natural child
of that person.

If we want to find the particular person occupying a specific
relationship for an individual (e.g., we want to know the `W1HhID` of
the person’s partner), we need to reshape the data into long-format with
one row per ego-alter relationship within a household (for more on
reshaping data, see [*Reshaping Data from Long to Wide (or Wide to
Long)*](https://cls-data.github.io/data-handling-stata/docs/next_steps-reshape_long_wide.html)).
For instance, to find the individuals who are spouses or partners, we
can do the following:

``` stata
reshape long W1R_, i(NSID W1HhID) j(W1HhID_alter)
keep if inlist(W1R_, 1, 2)
keep NSID W1HhID W1HhID_alter
rename W1HhID_alter partner_hhid
list in 1/10 // One row per couple: each relationship is only recorded for the person with the higher person number
save "temp_couples.dta", replace
```

    (j = 1 2 3 4 5 6 7 8 9 10 11 12 13 14)

    Data                               Wide   ->   Long
    -----------------------------------------------------------------------------
    Number of observations           70,593   ->   988,302     
    Number of variables                  16   ->   4           
    j variable (14 values)                    ->   W1HhID_alter
    xij variables:
                     W1R_1 W1R_2 ... W1R_14   ->   W1R_
    -----------------------------------------------------------------------------
    (976,593 observations deleted)

         +------------------------------+
         |     NSID   W1HhID   partne~d |
         |------------------------------|
      1. | NS10001S        3          2 |
      2. | NS10002T        3          2 |
      3. | NS10003V        3          2 |
      4. | NS10004W        3          2 |
      5. | NS10005X        3          2 |
         |------------------------------|
      6. | NS10007Z        3          2 |
      7. | NS10008A        3          2 |
      8. | NS10009B        3          2 |
      9. | NS10010L        3          2 |
     10. | NS10011M        3          2 |
         +------------------------------+
    file temp_couples.dta saved

`reshape long W1R_, i(NSID W1HhID) j(W1HhID_alter)` stacks the
relationship variables (`W1R_1`, `W1R_2`, …, `W1R_14`) into a single
variable, `W1R_`, and stores the number at the end of each variable
name - the alter’s person number - in a new variable, `W1HhID_alter`. We
then keep the rows where the relationship is husband/wife (`1`) or
partner/cohabitee (`2`), and rename `W1HhID_alter` as `partner_hhid` (in
the output, `list` abbreviates this name to `partne~d`).

As each relationship is only recorded once, the dataset has one row per
*couple*, with the partner with the higher person number in the `W1HhID`
column. To find each person’s spouse or partner (conditional on one
being present), both members of a couple need a row. Below, we use
`rename` to swap the person numbers of the two partners and then use
`append` to add the rows of the original dataset (which we saved as
`temp_couples.dta` above); `order` and `sort` are used to arrange the
columns and rows of the combined dataset. Swapping the person numbers is
sufficient here as the relationship is the same in both directions; for
other relationships (e.g., parent and child), the relationship itself
would also need to be recoded.

``` stata
rename (W1HhID partner_hhid) (partner_hhid W1HhID) // Swaps the person numbers of the two partners
append using "temp_couples.dta"
order NSID W1HhID partner_hhid
sort NSID W1HhID
list in 1/10
```

    (label W1HhID already defined)

         +------------------------------+
         |     NSID   W1HhID   partne~d |
         |------------------------------|
      1. | NS10001S        2          3 |
      2. | NS10001S        3          2 |
      3. | NS10002T        2          3 |
      4. | NS10002T        3          2 |
      5. | NS10003V        2          3 |
         |------------------------------|
      6. | NS10003V        3          2 |
      7. | NS10004W        2          3 |
      8. | NS10004W        3          2 |
      9. | NS10005X        2          3 |
     10. | NS10005X        3          2 |
         +------------------------------+

# Coda

This only scratches the surface of what can be achieved with the
household grid. A few further points are worth noting:

- The household grids for Sweeps 2-4
  (`wave_[two-four]_lsype_household_grid_file_2020.dta`) have a similar
  structure to the Sweep 1 grid. The relationship variables (`W2R_1`,
  `w3R_1`, `W4R_1`, and so on) follow the same rule: each relationship
  is only recorded once, in the row of the person with the higher person
  number. Variable names differ in their use of upper and lower case,
  however: for instance, the person number is `W2HhID` in Sweep 2,
  `w3HhID` in Sweep 3 and `W4hhid` in Sweep 4.[^1] These grids also
  include people who have left the household since an earlier sweep; the
  variables `W2SHGInt`, `w3SHGint` and `W4SHGint` record whether a
  person is still living with the cohort member.
- From Sweep 5, the household grid was completed by the cohort member
  and is much less detailed. The Sweep 5-7 grids
  (`wave_[five-seven]_lsype_household_grid_file_2020.dta`) contain a
  single variable recording a simplified relationship to the cohort
  member (e.g., `W5RELATION`), and the main and second parent are no
  longer identified. The person number is named `HHID` in these files.
  Note, at Sweep 7, `W7RELATION` is only filled in for people who are
  new to the household at that sweep
  (`W7SHGINT == 2 [Present - New at current wave]`) and is coded
  `-91 [Not applicable]` for everyone else; at Sweeps 5 and 6, the
  relationship is recorded for all people present in the household (this
  is not documented in the user guide). For people who were already in
  the household at Sweep 7, the relationship to the cohort member
  therefore needs to be taken from the Sweep 5 or 6 grid, by matching on
  `NSID` and `HHID`.
- At Sweeps 8 and 9, information on the people the cohort member lives
  with is contained in `ns8_2015_household_members.dta` and
  `ns9_2022_person_grid.dta` (both also in the `household_grids`
  subfolder). These files do not include a row for the cohort member,
  and the relationship to the cohort member is recorded in the variables
  `W8RELTOKEY` and `W9RELTOKEY`, respectively.

[^1]: `rename` can be used to rename variables *en masse* so that they
    follow the same rubric. For instance, `rename *, upper` converts
    every variable name in a dataset to upper case, so that the person
    number would be named `W2HHID`, `W3HHID` and `W4HHID` in Sweeps 2, 3
    and 4, respectively. See [*Combining Data Across
    Sweeps*](https://cls-data.github.io/data-handling-stata/docs/next_steps-merging_across_sweeps.html)
    for more on `rename`.
