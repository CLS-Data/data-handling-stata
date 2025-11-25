---
layout: default
title: Working with the Household Grid
nav_order: 4
parent: MCS
format:
  gfm:
    variant: +yaml_metadata_block
jupyter: stata
---


- [Download the Stata script for this
  page](../do_files/mcs-household_grid.do)

# Introduction

In this section, we describe the basics of using the household grid.
Specifically, we show how to use the household grid to:

1.  Identify particular family members

2.  Create family-member specific variables

3.  Determine the relationships between non-cohort members within a
    family.

# Finding Mother of Cohort Members

To show how to perform 1 & 2, we use the example of finding natural
mothers’ smoking status at the first sweep. We load just four variables
from the Sweep 1 household grid: `MCSID` and `APNUM00`, which together
uniquely identify an individual, and `AHPSEX00` and `AHCREL00`, which
contain information on the individual’s sex and their relationship to
the household’s cohort member(s). `AHCREL00 == 7` identifies natural
parents and `AHPSEX00 == 2` identifies females. Combining the two
identifies natural mothers. Below, we use `label list` (and `tabulate`
with `numlabel ..., add` as an alternative) to show the different
(observed) values for the sex and relationship variables. We also use
`keep if` to create retain rows for natural mothers only, saving just
the person identifiers (`MCSID` and `APNUM00`) which we will merge with
smoking information shortly. `bysort MCSID: gen n = _N` followed by
`keep if n == 1` is included as an interim step to ensure there is just
one natural mother per family.

``` stata
use MCSID APNUM00 AHPSEX00 AHCREL00 using "0y/mcs1_hhgrid.dta", clear
label list AHPSEX00 AHCREL00
numlabel AHPSEX00 AHCREL00, add // Alternatively tabulate
tabulate AHPSEX00
tabulate AHCREL00
keep if AHCREL00 == 7 & AHPSEX00 == 2
bysort MCSID: gen n = _N
keep if n == 1
drop n
keep MCSID APNUM00
save "temp_mothers.dta", replace
```



    AHPSEX00:
              -2 Unknown
              -1 Not applicable
               1 Male
               2 Female
    AHCREL00:
              -9 Refusal
              -8 Dont Know
              -1 Not available
               1 Husband/Wife
               2 Partner/Cohabitee
               3 Natural son/daughter
               4 Adopted son/daughter
               5 Foster son/daughter
               6 Step-son/ step-daughter
               7 Natural parent
               8 Adoptive parent
               9 Foster parent
              10 Step-parent/partner of parent
              11 Natural brother/Natural sister
              12 Half-brother/Half-sister
              13 Step-brother/Step-sister
              14 Adopted brother/Adopted sister
              15 Foster brother/Foster sister
              16 Grandchild
              17 Grandparent
              18 Nanny/au pair
              19 Other relative
              20 Other non-relative
              96 Self



          Person Sex   |      Freq.     Percent        Cum.
    -------------------+-----------------------------------
           -2. Unknown |         55        0.07        0.07
    -1. Not applicable |     18,734       25.05       25.12
               1. Male |     26,438       35.35       60.47
             2. Female |     29,567       39.53      100.00
    -------------------+-----------------------------------
                 Total |     74,794      100.00


      Relationship to Cohort Member    |      Freq.     Percent        Cum.
    -----------------------------------+-----------------------------------
                           -9. Refusal |          5        0.01        0.01
                         -8. Dont Know |          1        0.00        0.01
                     7. Natural parent |     33,812       45.21       45.21
                    8. Adoptive parent |          2        0.00       45.22
                      9. Foster parent |          3        0.00       45.22
     10. Step-parent/partner of parent |         50        0.07       45.29
    11. Natural brother/Natural sister |     13,873       18.55       63.84
          12. Half-brother/Half-sister |      3,486        4.66       68.50
          13. Step-brother/Step-sister |         16        0.02       68.52
    14. Adopted brother/Adopted sister |          8        0.01       68.53
      15. Foster brother/Foster sister |          9        0.01       68.54
                       17. Grandparent |      2,164        2.89       71.43
                     18. Nanny/au pair |         20        0.03       71.46
                    19. Other relative |      2,326        3.11       74.57
                20. Other non-relative |        233        0.31       74.88
                              96. Self |     18,786       25.12      100.00
    -----------------------------------+-----------------------------------
                                 Total |     74,794      100.00

    (56,279 observations deleted)


    (0 observations deleted)



    file temp_mothers.dta saved

Note, where a cohort member is part of a family (`MCSID`) with two or
more cohort members, the cohort member will have been a multiple birth
(i.e., twin or triplet), so familial relationships should apply to all
cohort members in the family, which is why there is just one
relationship (`[A-G]HCREL00`) variable per household grid file. This
will change as the cohort members age, move into separate residences and
start their own families.

# Creating a Mother’s Smoking Variable

Now we have a dataset containing the IDs of natural mothers, we can load
the smoking information from the Sweep 1 parent interview file
(`0y/mcs1_parent_interview.dta`). The smoking variable we use is called
`APSMUS0A` and contains information on the tobacco product (if any) a
parent consumes. We classify a parent as a smoker if they use any
tobacco product.

``` stata
use MCSID APNUM00 APSMUS0A using "0y/mcs1_parent_interview.dta", clear
label list APSMUS0A
gen parent_smoker = 1 if inrange(APSMUS0A, 2, 95)
replace parent_smoker = 0 if APSMUS0A == 1
keep MCSID APNUM00 parent_smoker
save "temp_smoking.dta", replace
```



    APSMUS0A:
              -9 Refusal
              -8 Don't Know
              -1 Not applicable
               1 No, does not smoke
               2 Yes, cigarettes
               3 Yes, roll-ups
               4 Yes, cigars
               5 Yes, a pipe
              95 Yes, other tobacco product

    (21,246 missing values generated)

    (21,229 real changes made)


    file temp_smoking.dta saved

Now we can merge the two datasets together to ensure we only keep rows
in `temp_smoking` that appear in `temp_mothers`. We use `merge` to do
this. The result is a dataset with one row per family with an identified
mother. We rename the `parent_smoker` variable to `mother_smoker` to
clarify that it refers to the mother’s smoking status.

Below we also use `tabulate` to tabulate the number and proportions of
mothers who smoke and those who do not.

``` stata
use "temp_mothers.dta", clear
merge 1:1 MCSID APNUM00 using "temp_smoking.dta", keep(master match)
drop _merge
rename parent_smoker mother_smoker
tabulate mother_smoker
```




        Result                      Number of obs
        -----------------------------------------
        Not matched                            23
            from master                        23  (_merge==1)
            from using                          0  (_merge==2)

        Matched                            18,492  (_merge==3)
        -----------------------------------------




    mother_smok |
             er |      Freq.     Percent        Cum.
    ------------+-----------------------------------
              0 |     12,883       69.68       69.68
              1 |      5,605       30.32      100.00
    ------------+-----------------------------------
          Total |     18,488      100.00

`merge 1:1 ..., keep(master match)` is used to (a) perform a one-to-one
(`1:1`) merge on the two identifiers (i.e., at most one row per
combination of these variables in both datasets) and (b) to retain only
rows that appear in both datasets or in the mothers dataset (i.e.,
`keep(master match)`).

# Determining Relationships between Non-Cohort Members

The household grids include another set of relationship variables
besides `[A-G]HCREL00`. These vary in name slightly between sweeps:
`[A-D]HPREL[A-Z]0` in `mcs[1-4]_hhgrid.dta`, `EPREL0[A-Z]00` in
`mcs5_hhgrid.dta`, and `[F-G]HPREL0[A-Z]` in `mcs[6-7]_hhgrid.dta`.
These variables can be used to identify the relationships between all
family members, including non-cohort members. Specifically, they record
the person in the row’s (ego) relationship to the person denoted by the
column (alt); the letter `[A-Z]` in the variable name corresponds to the
alt’s `[A-D]PNUM00`. For instance, the variable `AHPRELB0` denotes the
relationship of the person in the row to the person in the same family
with `APNUM00 == 2`. Below, we extract a small set of data from the
Sweep 1 household grid to show this in action.

``` stata
use MCSID APNUM00 AHPREL* using "0y/mcs1_hhgrid.dta", clear
list APNUM00 AHPRELA0 AHPRELB0 AHPRELC0 if MCSID == "M10001N"
```




           +------------------------------------------+
           | APNUM00   AHPRELA0   AHPRELB0   AHPRELC0 |
           |------------------------------------------|
        1. |       1       Self   Husband/    Natural |
        2. |       2   Husband/       Self    Natural |
        3. |       3    Natural    Natural       Self |
        4. |       4    Natural    Natural    Natural |
        5. |       5    Natural    Natural    Natural |
           |------------------------------------------|
        6. |       6    Natural    Natural    Natural |
        7. |     100    Natural    Natural    Natural |
           +------------------------------------------+

There are seven members in this family, one of whom is a cohort member
(`APNUM00 == 100`). `APNUM00`’s 1 and 2 are the (natural) parents, and
`APNUM00`’s 3-6 and 100 are the (natural) children. The relationship
variables show that `APNUM00`’s 1 and 2 are married, and `APNUM00`’s 3-7
are siblings (`AHPRELC0 == 11 [Natural brother/sister]`) and biological
offspring of `APNUM00`’s 1 and 2
(`AHPREL[A-B]0 == 3 [Natural son/daughter]`). Note the symmetry in the
relationships. Where, `APNUM00 == 1`, `AHPRELC0 == 7 [Natural Parent]`
and where `APNUM00 == 3`, `AHPRELA0 == 3 [Natural son/daughter]`.

If we want to find the particular person occupying a specific
relationship for an individual (e.g., we want to know the `[A-G]PNUM00`
of the person’s partner), we need to reshape the data into long-format
with one row per ego-alt relationship within a family. For instance, if
we want to find each person’s spouse (conditional on one being present),
we can do the following:[^1]

``` stata
reshape long AHPREL, i(MCSID APNUM00) j(alt) string
gen alt_letter = substr(alt, 1, 1)
gen APNUM00_alt = (strpos("`c(ALPHA)'", alt_letter) + 1) / 2
keep if AHPREL == 1
keep MCSID APNUM00 APNUM00_alt
rename APNUM00_alt partner_pnum
list in 1/10
```


    (j = A0 B0 C0 D0 E0 F0 G0 H0 I0 J0 K0)

    Data                               Wide   ->   Long
    -----------------------------------------------------------------------------
    Number of observations           74,794   ->   822,734     
    Number of variables                  13   ->   4           
    j variable (11 values)                    ->   alt
    xij variables:
             AHPRELA0 AHPRELB0 ... AHPRELK0   ->   AHPREL
    -----------------------------------------------------------------------------



    (799,118 observations deleted)




         +------------------------------+
         |   MCSID   APNUM00   partne~m |
         |------------------------------|
      1. | M10001N         1          2 |
      2. | M10001N         2          1 |
      3. | M10002P         1          2 |
      4. | M10002P         2          1 |
      5. | M10007U         1          2 |
         |------------------------------|
      6. | M10007U         2          1 |
      7. | M10011Q         1          2 |
      8. | M10011Q         2          1 |
      9. | M10015U         1          2 |
     10. | M10015U         2          1 |
         +------------------------------+

`c(ALPHA)` is an inbuilt macro which contains the letters of the
alphabet in upper-case with spaces between letters.
`` strpos("`c(ALPHA)'", alt_letter) `` finds the position of the
`alt_letter` (i.e., A, B, C, or D) in this string. Dividing by 2 and
adding 1 converts this to the corresponding `APNUM00` value (e.g., C
would be in the 5th position in the string \[`A B C ...`\]).

# Coda

This only scratches the surface of what can be achieved with the
household grid. The `mcs[1-7]_hhgrid.dta` files also contain information
on cohort-member and family-member’s dates of birth, which can be used
to, for example, identify the number of resident younger siblings,
determine maternal and paternal age at birth, and so on.

[^1]: For more on reshaping data, see [*Reshaping Data from Long to Wide
    (or Wide to
    Long)*](https://cls-data.github.io/docs/mcs-reshape_long_wide.html).
