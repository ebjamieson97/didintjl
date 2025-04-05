# didintjl
This Stata package acts as a wrapper for the Julia package DiDInt.jl. 

undidjl allows for estimation of difference-in-differences with covariates that may vary by state & time, see https://arxiv.org/abs/2412.14447 for more details.

## Installation 
didintjl will automatically download the DiDInt.jl package for Julia if it is not found to be downloaded already.

```stata
net install didintjl, from("https://raw.githubusercontent.com/ebjamieson97/didintjl/main/")
```

### Update
```stata
ado uninstall didintjl
net install didintjl, from("https://raw.githubusercontent.com/ebjamieson97/didintjl/main/")
```

## Requirements
* **Julia**: Version > 1.11.1
* **Stata**: Version 14.1 or later
* **David Roodman’s Julia package for Stata**: [julia.ado](https://github.com/droodman/julia.ado)

### Get Help
```stata
help didintjl
```

## Return Values

```stata
r(att) // for the aggregate att
r(se) // for the standard error of the aggregate att
r(p) // for the p-value from the two-sided t-test of the aggregate att
r(jkse) // for the jackknife standard error of the aggregate att
r(jkp) // for the p-value from the two-sided t-test of the aggregate att using the jackknife standard error
r(rip) // for the p-value resulting from the randomization inference procedure
matrix list restab // for the results table at the state/cohort/rt level
```

## Julia Side Errors
### Valid for DiDInt.jl version 0.2.1

Errors that happen in Julia can have their messages cut-off when displaying through the Stata outputs. Usually, only the first few characters of the Julia error message are visible in Stata. Below are all of the Julia error codes from *DiDInt.jl* and their associated messages.

```julia
error("Er01: Please specify a date_format listed here: $possible_formats.")
error("Er02: Unsupported period type: $period_type, try day(s), week(s), month(s), or year(s).")
error("Er03: 'agg' must be one of: $(agg_options)")
error("Er04: 'nperm' must be a positive integer > 0.")
error("Er05: The following columns could not be found in the data: ", join(missing_cols, ", "))
error("Er06: Column '$outcome' must be numeric, but found $(eltype(data_copy[!, outcome]))")
error("Er07$(join(missing_cov, ", ")): The preceding covariates could not be found in the data.")
error("Er08: If 'treatment_times' are entered as a number, the 'date_format' must be \"yyyy\".")
error("Er09: If 'treatment_times' are entered as numbers, they must all be 4 digits long in 'yyyy' date_format.")
error("Er10: Detected multiple unique date_formats in 'treatment_times'.")
error("Er11: The 'time' column was found to be numeric but consisting of values of ambiguous date formatting (i.e. not consistent 4 digit entries.)")
error("Er12: If 'time' column is numeric or 'treatment_times' is numeric, then both must be numeric.")
error("Er13: 'treatment_times' must have at least one entry.")
error("Er14: No control states were found.")
error("Er15: 'treated_states' and the 'state' column ($state) must both be numerical or both be strings. \n 
Instead, found: 'treated_states': $treated_states_type and '$state': $state_column_type.")
error("Er16: The following 'treated_states' could not be found in the data: $(missing_states). \n 
Only found the following states: $(unique(data_copy.state_71X9yTx))")
error("Er17: Found missing values in the 'outcome' column.")
error("Er18: Found missing values in the 'state' column.")
error("Er19: Found missing values in the 'time' column.")
error("Er20: Found missing values in the '$cov' column.")
error("Er21: Dates in the 'time' column are not all the same length!")
error("Er22: If 'time' is a numeric column, dates must be 4 digits long.")
error("Er23: First date in 'time' column uses mixed separators: - and /.")
error("Er24 $i: Separator positions differs from the first date in 'time' column in date entry $i: $date")
error("Er25 $i: Date found in 'time' column (entry $i) which uses multiple separator types: $date")
error("Er26 $i: Date found in 'time' column (entry $i: $date) which uses different separator types from first date.")
error("Er27: First date in 'treatment_times' uses mixed separators: - and /.")
error("Er28 $i: Separator positions differs from the first date in 'treatment_times' in the $i'th entry: $date")
error("Er29 $i: Date found in 'treatment_times' column (entry $i) which uses multiple separator types: $date")
error("Er30 $i: Date found in 'treatment_times' (entry $i: $date) which uses different separator types from first date.")
error("Er31: 'treatment_times' and 'time' column were found to have date strings with different lengths.")
error("Er32: 'treatment_times' and 'time' column have different separator positions.")
error("Er33: 'treatment_times' and 'time' column have different separator types.")
error("Er34: If 'time' column is a String column, must specify the 'date_format' argument.")
error("Er35: 'time' column must be a String, Date, or Number column.")
error("Er36: 'freq' was not set to a valid option. Try one of: $freq_options")
error("Er37: The following 'treatment_times' are not found in the data: $(missing_dates). \n 
Try defining an argument for 'freq' or set 'autoadjust = true' in order to activate the date matching procedure.")
error("Er38: 'treatment_times' should either be the same length as the 'treated_states' vector or of length 1.")
error("Er39: 'treatment_times' should be the same length as the 'treated_states'.")
error("Er40 $s: For state $s, the earliest date ($earliest) is not strictly less than the treatment time ($treat_time).")
error("Er41 $s: For state $s, the treatment time ($treat_time) is greater than the last date ($latest).")
error("Er42: A non-common or non-staggered adoption scenario was discovered!? This error should not be possible!")
error("Er43 $refcat $cov: Reference category '$refcat' not found in column '$cov'.")
error("Er44 $cov: Only detected one unique factor ($unique_categories) in factor variable $cov.")
error("Er45 $cov: column was found to be ($cov_type) neither of type Number, AbstractString, nor CategoricalValue!")
error("Er46: 'ccc' must be set to one of: \"int\", \"time\", \"state\", \"add\", or \"hom\".")
```
