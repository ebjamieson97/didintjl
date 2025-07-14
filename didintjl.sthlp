{smcl}
{*------------------------------------*}
{* didintjl                                           }
{* written by Eric Jamieson                           }
{* version 0.5.2 2025-07-13                           }
{*------------------------------------*}

{help didintjl:didintjl}
{hline}

{title:didintjl}

{pstd}
didintjl - Stata wrapper for the DiDInt.jl Julia package.  
Estimates the average treatment effect on the treated (ATT) while accounting for covariates that may vary by state, time, or both. That is, estimates ATT while accounting for different violations of the common causal covariates assumption.
{p_end}

{title:Command Description}

{phang}
{cmd:didintjl} is a Stata command that serves as a wrapper for the DiDInt.jl Julia function.  
It requires you to specify the names of the outcome, state, and time variables along with other required parameters.  
It then calls the Julia function didint() with the provided options and returns a DataFrame of results (ATT, standard errors, and p-values) to the active Stata dataset.
{p_end}

{title:Syntax}

{pstd}
{cmd:didintjl} outcome(string) state(string) time(string) ///
    treated_states(string) treatment_times(string) ///
    date_format(string) ///
    [covariates(string) ccc(string) ref_column(string) ref_group(string) ///
    freq(string) freq_multiplier(int 1) start_date(string) end_date(string)///
    nperm(int 1000) verbose(int 1) seed(int 0) use_pre_controls(int 0)]
{p_end}

{title:Parameters}

{pstd}
- {bf:outcome} (string)  
 Name of the column containing the outcome of interest.
  
- {bf:state} (string)  
 Name of the column containing the state membership.

- {bf:time} (string)  
 Name of the column containing the date of the observation.

- {bf:treated_states} (string)  
 A string (or list of strings) indicating the treated state(s).

- {bf:treatment_times} (string)  
 A string (or list) of treatment times corresponding to the treated states.  
 The order should match (first treated state → first treatment time, etc.).

- {bf:date_format} (string)  
 The date format used in the data (e.g., "yyyy/mm/dd", "ddmonyyyy", etc.).

- {bf:covariates} (string, optional)  
 A string (or space-separated list) of covariate names. If omitted, covariate adjustment is skipped.

- {bf:ccc} (string, optional, default "int")  
 Specifies which version of DID-INT to use. Options include "hom", "time", "state", "add", and "int" (default).

- {bf:ref_column} (string, optional)  
 If using a reference category for a categorical variable, specify the column name.

- {bf:ref_group} (string, optional)  
 If using a reference category, specify the reference group.  
 Both {bf:ref_column} and {bf:ref_group} must be provided together.

- {bf:freq} (string, optional)  
 Timeframe for periods in staggered adoption scenarios (e.g., "year", "month", "week", "day").

- {bf:freq_multiplier} (int, optional, default 1)  
 Multiplier for the freq argument (e.g., 2 for a two-year period).

- {bf:start_date} (string, optional)  
Can be set to indicate the start of the window for the analysis.

- {bf:end_date} (string, optional)  
Can be set to indicate the end of the window for the analysis.

- {bf:nperm} (int, optional, default 1000)  
 Number of unique permutations for randomization inference.

- {bf:verbose} (int, optional, default 1)  
 Set to 1 for progress output, 0 for quiet operation. Note this argument is deprecated and will have no effect.
{p_end}

{title:Examples}

{phang2}
For example, using the MeritExampleDataDiDIntjl.dta :
{p_end}

{pstd}
* CCC : two-way intersection
didintjl, outcome("coll") state("state") time("year") ///
 treated_states("34 57 58 59 61 64 71 72 85 88") ///
  treatment_times("2000 1998 1993 1997 1999 1996 1991 1998 1997 2000") ///
   date_format("yyyy") covariates("asian male black") ccc("int") 
{p_end}

{title:Author}

{pstd}
Eric Jamieson  
{p_end}

{title:Citation}

{pstd}
If you use didintjl in your research, please cite:  
Please cite: Sunny Karim, and Matthew D. Webb. Good Controls Gone Bad: Difference-in-Differences with Covariates. {browse "https://arxiv.org/abs/2412.14447"} {p_end}
{p_end}

{smcl}
