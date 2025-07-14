use "MeritExampleDataDiDIntjl.dta", clear


* aggregation is by "cohort" (gvar) and weighting is set to "both" (applies weighting while computing sub-aggregate level ATTs and when computing the aggregate ATT from the sub-aggregate ATTs) in all of the following examples

* CCC : two-way intersection
didintjl, outcome("coll") state("state") time("year") treated_states("34 57 58 59 61 64 71 72 85 88") treatment_times("2000 1998 1993 1997 1999 1996 1991 1998 1997 2000") date_format("yyyy") covariates("asian male black") ccc("int") 


* CCC : time
didintjl, outcome("coll") state("state") time("year") treated_states("34 57 58 59 61 64 71 72 85 88") treatment_times("2000 1998 1993 1997 1999 1996 1991 1998 1997 2000") date_format("yyyy") covariates("asian male black") ccc("time")

* CCC : state
didintjl, outcome("coll") state("state") time("year") treated_states("34 57 58 59 61 64 71 72 85 88") treatment_times("2000 1998 1993 1997 1999 1996 1991 1998 1997 2000") date_format("yyyy") covariates("asian male black") ccc("state")


* CCC : additive
didintjl, outcome("coll") state("state") time("year") treated_states("34 57 58 59 61 64 71 72 85 88") treatment_times("2000 1998 1993 1997 1999 1996 1991 1998 1997 2000") date_format("yyyy") covariates("asian male black") ccc("add")

* CCC : homogenous
didintjl, outcome("coll") state("state") time("year") treated_states("34 57 58 59 61 64 71 72 85 88") treatment_times("2000 1998 1993 1997 1999 1996 1991 1998 1997 2000") date_format("yyyy") covariates("asian male black") ccc("hom")
