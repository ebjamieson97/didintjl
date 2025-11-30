use "MeritExampleDataDiDIntjl.dta", clear

* For more details, call:
help didintjl_plot
set trace off
set tracedepth 1
didintjl_plot, outcome("coll") state("state") time("year") treatment_times("2000 1998 1993 1997 1999 1996 1991 1998 1997 2000") date_format("yyyy") covariates("asian male black") ccc("hom")