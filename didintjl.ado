/*------------------------------------*/
/*didintjl*/
/*written by Eric Jamieson */
/*version 0.3.0 2025-04-05 */
/*------------------------------------*/

cap program drop didintjl
program define didintjl, rclass
    version 16
    syntax, outcome(string) state(string) time(string) ///
            treated_states(string) treatment_times(string) ///
            date_format(string) /// 
            [covariates(string) ccc(string) agg(string) ref_column(string) ref_group(string) ///
            freq(string) freq_multiplier(int 1) autoadjust(int 0) ///
            nperm(int 1000) verbose(int 1)]

	// PART ONE: BASIC SETUP 
    qui cap which jl
    if _rc {
        di as error "The 'julia' package is required but not installed or not found in the system path. See https://github.com/droodman/julia.ado for more details."
        exit 3
    } 

    // Check that DiDInt.jl for Julia is installed, update if updatejuliapackage == 1
    jl: using Pkg
    jl: if Base.find_package("DiDInt") === nothing              ///
            SF_display("DiDInt.jl not installed, installing now.");  ///
            Pkg.add(url="https://github.com/ebjamieson97/DiDInt.jl"); ///
            SF_display(" DiDInt.jl is done installing.");             ///
        end        
    jl: using DiDInt

    qui jl save df

    // Allow some variables to be passed to Julia 
    global outcome = "`outcome'"
    global state = "`state'"
    global time = "`time'"
    global date_format = "`date_format'"
    global nperm = `nperm'
    global freq_multiplier = `freq_multiplier'
    if "`freq'" == "" {
        qui jl: freq = nothing
    }
    else {
        global freq = "`freq'"
        qui jl: freq = "$freq"
    }

    // Parse treated_states and treatment_times
    qui jl: treated_states = String[]
    qui jl: treated_times = String[]
    qui tokenize "`treated_states'"
    while "`1'" != "" {
        local token = trim("`1'")
        if ("`token'" != "") {
            global treated_states_to_julia "`token'"
            qui jl: push!(treated_states, "$treated_states_to_julia")
        }
        macro shift
    }
    qui tokenize "`treatment_times'"
    while "`1'" != "" {
        local token = trim("`1'")
        if ("`token'" != "") {
            global treated_times_to_julia "`token'"
            qui jl: push!(treated_times, "$treated_times_to_julia")
        }
        macro shift
    }

    // Parse covariates if necessary
    if "`covariates'" == ""{
        qui jl: covariates = nothing
    }
    else {
        qui jl: covariates = String[]
        tokenize "`covariates'"
        while "`1'" != "" {
            local token = trim("`1'")
            if ("`token'" != "") {
                global covariate_to_julia "`token'"
                qui jl: push!(covariates, "$covariate_to_julia")
            }
            macro shift
        }
    }

    if "`ccc'" == "" {
        global ccc = "int"
    } 
    else {
        global ccc = "`ccc'"
    }
    
    if "`agg'" == "" {
        global agg = "state"
    } 
    else {
        global agg = "`agg'"
    }

    // Parse ref_column tokens with trimming
    if "`ref_column'" != "" {
        qui jl: ref_keys = String[]
        tokenize "`ref_column'"
        while "`1'" != "" {
            local token = trim("`1'")
            if ("`token'" != "") {
                global ref_column_to_julia "`token'"
                qui jl: push!(ref_keys, "$ref_column_to_julia")
            }
            macro shift
        }
        if "`ref_group'" == "" {
            di as error "If ref_column is specified, then ref_group must be specified as well!"
            exit 6
        }
    }

    // Parse ref_group tokens with trimming
    if "`ref_group'" != "" {
        qui jl: ref_values = String[]
        tokenize "`ref_group'"
        while "`1'" != "" {
            local token = trim("`1'")
            if ("`token'" != "") {
                global ref_group_to_julia "`token'"
                qui jl: push!(ref_values, "$ref_group_to_julia")
            }
            macro shift
        }
        if "`ref_column'" == "" {
            di as error "If ref_group is specified, then ref_column must be specified as well!"
            exit 7
        }
        qui jl: ref = Dict(zip(ref_keys, ref_values))
    }

    if "`ref_column'" == "" & "`ref_group'" == "" {
        qui jl: ref = nothing
    }

    if `autoadjust' == 0 {
        qui jl: autoadjust = false
    }
    else if `autoadjust' == 1 {
        qui jl: autoadjust = true
    }
    else {
        di as error "autoadjust must be 0 (False) or 1 (True)"
        exit 4
    }

    if `verbose' == 0 {
        qui jl: verbose = false
    }
    else if `verbose' == 1 {
        qui jl: verbose = true
    }
    else {
        di as error "verbose must be 0 (False) or 1 (True)"
        exit 5
    }
	
	// PART TWO: RUN DiDInt.jl
    qui jl: results = DiDInt.didint("$outcome", "$state", "$time", df, treated_states, treated_times, date_format = "$date_format", covariates = covariates, ccc = "$ccc", agg = "$agg", ref = ref, freq = freq, freq_multiplier = $freq_multiplier, autoadjust = autoadjust, nperm = $nperm, verbose = verbose)

	// PART THREE: PASS RESULTS TO STATA
	tempname result_frame
    qui cap frame drop `result_frame'
    qui frame create `result_frame'
    qui frame change `result_frame'
    qui jl use results
    qui ds 
    qui local result_vars `r(varlist)'
    foreach var in `result_vars' {
        tempvar tmp_`var' 
        qui gen `tmp_`var'' = `var'
        qui drop `var'
    }
	local condition_met 0

	qui capture confirm variable `tmp_att_s'
	if _rc == 0 & `condition_met' == 0 {
		local condition_met 1
		di as text "-------------------------------------------------------------------------------------------"
		di as text "                                       DiDInt.jl Results                    "
		di as text "-------------------------------------------------------------------------------------------"
		di as text "State                     | " as text "ATT             | SE     | p-val  | JKNIFE SE  | JKNIFE p-val |"
		di as text "--------------------------|-----------------|--------|--------|------------|--------------|"
		
		// Initialize a temporary matrix to store the numeric results
        tempname table_matrix
        local num_rows = _N
        local num_cols = 5
        matrix `table_matrix' = J(`num_rows', `num_cols', .)
		local state_names ""
		
		forvalues i = 1/`=_N' {
			di as text %-25s "`=`tmp_state'[`i']'" as text " |" as result %-16.7f `tmp_att_s'[`i'] as text " | " as result  %-7.3f `tmp_se_att_s'[`i'] as text "| " as result %-7.3f `tmp_pval_att_s'[`i'] as text "| " as result  %-11.3f `tmp_jknifese_att_s'[`i'] as text "| " as result %-13.3f `tmp_jknifepval_att_s'[`i'] as text "|"
    
			di as text "--------------------------|-----------------|--------|--------|------------|--------------|"
			
			// Store the state name
            local state_name = `tmp_state'[`i']
            local state_names `state_names' `state_name'
            
            // Fill the matrix with numeric values
            matrix `table_matrix'[`i', 1] = `tmp_att_s'[`i']
            matrix `table_matrix'[`i', 2] = `tmp_se_att_s'[`i']
            matrix `table_matrix'[`i', 3] = `tmp_pval_att_s'[`i']
            matrix `table_matrix'[`i', 4] = `tmp_jknifese_att_s'[`i']
            matrix `table_matrix'[`i', 5] = `tmp_jknifepval_att_s'[`i']
		}
		// Set column names for the matrix
        matrix colnames `table_matrix' = ATT SE pval JKNIFE_SE JKNIFE_pval
        
        // Set row names for the matrix using the state names
        matrix rownames `table_matrix' = `state_names'
        
        // Store the matrix in r()
        return matrix restab = `table_matrix'
        
		local linesize = c(linesize)
		if `linesize' < 93 {
			di as text "Results table may be squished, try expanding Stata results window."
		}
		di as text _n "Aggregation Method: State"
	}
	
    qui capture confirm variable `tmp_att_cohort'
	if _rc == 0 & `condition_met' == 0 {
		local condition_met 1
		di as text "-------------------------------------------------------------------------------------------"
		di as text "                                       DiDInt.jl Results                    "
		di as text "-------------------------------------------------------------------------------------------"
		di as text "Cohort                    | " as text "ATT             | SE     | p-val  | JKNIFE SE  | JKNIFE p-val |"
		di as text "--------------------------|-----------------|--------|--------|------------|--------------|"
		
		// Initialize a temporary matrix to store the numeric results
        tempname table_matrix
        local num_rows = _N
        local num_cols = 5
        matrix `table_matrix' = J(`num_rows', `num_cols', .)
		local cohort_names ""
		
		forvalues i = 1/`=_N' {
			di as text %-25s "`=`tmp_treatment_time'[`i']'" as text " |" as result %-16.7f `tmp_att_cohort'[`i'] as text " | " as result  %-7.3f `tmp_se_att_cohort'[`i'] as text "| " as result %-7.3f `tmp_pval_att_cohort'[`i'] as text "| " as result  %-11.3f `tmp_jknifese_att_cohort'[`i'] as text "| " as result %-13.3f `tmp_jknifepval_att_cohort'[`i'] as text "|"
    
			di as text "--------------------------|-----------------|--------|--------|------------|--------------|"
			
			// Store the cohort name
            local cohort_name = `tmp_treatment_time'[`i']
            local cohort_names `cohort_names' `cohort_name'
            
            // Fill the matrix with numeric values
            matrix `table_matrix'[`i', 1] = `tmp_att_cohort'[`i']
            matrix `table_matrix'[`i', 2] = `tmp_se_att_cohort'[`i']
            matrix `table_matrix'[`i', 3] = `tmp_pval_att_cohort'[`i']
            matrix `table_matrix'[`i', 4] = `tmp_jknifese_att_cohort'[`i']
            matrix `table_matrix'[`i', 5] = `tmp_jknifepval_att_cohort'[`i']
		}
		// Set column names for the matrix
        matrix colnames `table_matrix' = ATT SE pval JKNIFE_SE JKNIFE_pval
        
        // Set row names for the matrix using the state names
        matrix rownames `table_matrix' = `cohort_names'
        
        // Store the matrix in r()
        return matrix restab = `table_matrix'
        
		local linesize = c(linesize)
		if `linesize' < 93 {
			di as text "Results table may be squished, try expanding Stata results window."
		}
		di as text _n "Aggregation Method: Cohort"
	}

    qui capture confirm variable `tmp_time'
	if _rc == 0 & `condition_met' == 0 {
		local condition_met 1
		di as text "-------------------------------------------------------------------------------------------"
		di as text "                                       DiDInt.jl Results                    "
		di as text "-------------------------------------------------------------------------------------------"
		di as text "r1;t                      | " as text "ATT             | SE     | p-val  | JKNIFE SE  | JKNIFE p-val |"
		di as text "--------------------------|-----------------|--------|--------|------------|--------------|"
		
		// Initialize a temporary matrix to store the numeric results
        tempname table_matrix
        local num_rows = _N
        local num_cols = 5
        matrix `table_matrix' = J(`num_rows', `num_cols', .)
		local state_names ""

        tempvar rt
        qui gen `rt' = `tmp_r1' + ";" + `tmp_time'

        // Create the gt varialbe in julia
		
		forvalues i = 1/`=_N' {
			di as text %-25s "`=`rt'[`i']'" as text " |" as result %-16.7f `tmp_att_rt'[`i'] as text " | " as result  %-7.3f `tmp_se_att_rt'[`i'] as text "| " as result %-7.3f `tmp_pval_att_rt'[`i'] as text "| " as result  %-11.3f `tmp_jknifese_att_rt'[`i'] as text "| " as result %-13.3f `tmp_jknifepval_att_rt'[`i'] as text "|"
    
			di as text "--------------------------|-----------------|--------|--------|------------|--------------|"
			
			// Store the rt
            local rt_name = `rt'[`i']
            local rt_names `rt_names' `rt_name'
            
            // Fill the matrix with numeric values
            matrix `table_matrix'[`i', 1] = `tmp_att_rt'[`i']
            matrix `table_matrix'[`i', 2] = `tmp_se_att_rt'[`i']
            matrix `table_matrix'[`i', 3] = `tmp_pval_att_rt'[`i']
            matrix `table_matrix'[`i', 4] = `tmp_jknifese_att_rt'[`i']
            matrix `table_matrix'[`i', 5] = `tmp_jknifepval_att_rt'[`i']
		}
		// Set column names for the matrix
        matrix colnames `table_matrix' = ATT SE pval JKNIFE_SE JKNIFE_pval
        
        // Set row names for the matrix using the state names
        matrix rownames `table_matrix' = `rt_names'
        
        // Store the matrix in r()
        return matrix restab = `table_matrix'
        
		local linesize = c(linesize)
		if `linesize' < 93 {
			di as text "Results table may be squished, try expanding Stata results window."
		}
		di as text _n "Aggregation Method: Simple"
	}
	

       // Display aggregate results
       di as text _n "Aggregate Results:"
       di as text "Aggregate ATT: " as result `tmp_agg_att'[1]
       di as text "Standard error: " as result `tmp_se_agg_att'[1]
       di as text "p-value: " as result `tmp_pval_agg_att'[1]
       di as text "Jackknife SE: " as result `tmp_jknifese_agg_att'[1]
       di as text "Jackknife p-value: " as result `tmp_jknifepval_agg_att'[1]
       di as text "RI p-value: " as result `tmp_ri_pval_agg_att'[1]
	   
	// Store aggregate results in r()
    return scalar att = `tmp_agg_att'[1]
    return scalar se = `tmp_se_agg_att'[1]
    return scalar p = `tmp_pval_agg_att'[1]
    return scalar jkse = `tmp_jknifese_agg_att'[1]
    return scalar jkp = `tmp_jknifepval_agg_att'[1]
    return scalar rip = `tmp_ri_pval_agg_att'[1]
    
	qui drop _all
	qui frame change default
    qui frame drop `result_frame'
	
	qui macro drop outcome state time date_format nperm freq_multiplier treated_states_to_julia treated_times_to_julia freq covariate_to_julia ref_column_to_julia ref_group_to_julia

end

/*--------------------------------------*/
/* Change Log */
/*--------------------------------------*/
*0.3.0 - changed to rclass and added displays for outputs
*0.2.1 - removed 'stata_debug' arg, hopefully not needed anymore
*0.2.0 - fixed 'freq' arg - function actually works now for common + staggered adoption
*0.1.2 - added 'stata_debug' arg and trim whitespce for tokenized args
*0.1.1 - added 'agg' arg
*0.1.0 - created function
