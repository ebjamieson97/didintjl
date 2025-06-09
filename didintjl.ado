/*------------------------------------*/
/*didintjl*/
/*written by Eric Jamieson */
/*version 0.5.1 2025-06-09 */
/*------------------------------------*/

cap program drop didintjl
program define didintjl, rclass
    version 16
    syntax, outcome(string) state(string) time(string) ///
            treated_states(string) treatment_times(string) ///
            date_format(string) /// 
            [covariates(string) ccc(string) agg(string) weighting(string) ref_column(string) ref_group(string) ///
            freq(string) freq_multiplier(int 1) start_date(string) end_date(string) ///
            nperm(int 1000) verbose(int 1) seed(int 0) use_pre_controls(int 0)]

	// PART ONE: BASIC SETUP 
    qui cap which jl
    if _rc {
        di as error "The 'julia' package is required but not installed or not found in the system path. See https://github.com/droodman/julia.ado for more details."
        exit 3
    } 

    // Check seed value 
    if `seed' == 0 {
        qui jl: seed = abs(round(randn(1)[1]*10000))
    }
    else {
        qui jl: seed = `seed'
    }

    // Check use_pre_controls arg
    if `use_pre_controls' == 1 {
        qui jl: use_pre_controls = true
    }
    else if `use_pre_controls' == 0 {
        qui jl: use_pre_controls = false
    }
    else {
        di as error "use_pre_controls must be 0 (False) or 1 (True) (Default)"
        exit 43
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

    if "`start_date'" == "" {
        qui jl: start_date = nothing
    }
    else {
        global start_date = "`start_date'"
        qui jl: start_date = "$start_date"
    }
    if "`end_date'" == "" {
        qui jl: start_date = nothing
    }
    else {
        global end_date = "`end_date'"
        qui jl: end_date = "$end_date"
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
        global agg = "cohort"
    } 
    else {
        global agg = "`agg'"
    }

    if "`weighting'" == "" {
        global weighting = "both"
    } 
    else {
        global weighting = "`weighting'"
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
	
	// PART TWO: RUN DiDInt.jl and convert some columns to strings
    qui jl: results = DiDInt.didint("$outcome", "$state", "$time", df, treated_states, treated_times, date_format = "$date_format", covariates = covariates, ccc = "$ccc", agg = "$agg", weighting = "$weighting", ref = ref, freq = freq, freq_multiplier = $freq_multiplier, start_date = start_date, end_date = end_date, nperm = $nperm, verbose = verbose, seed = seed, use_pre_controls = use_pre_controls)
    qui jl: if "att_cohort" in DataFrames.names(results) ///
                results.treatment_time = string.(results.treatment_time); ///
            elseif "att_gt" in DataFrames.names(results) ///
                results.r1 = string.(results.r1); ///
                results.time = string.(results.time); ///
                results.gvar = string.(results.gvar); ///
            elseif "att_sgt" in DataFrames.names(results) ///
                results.t = string.(results.t); ///
                results.gvar = string.(results.gvar); ///
            elseif "att_t" in DataFrames.names(results) ///
                results.periods_post_treat = string.(results.periods_post_treat); ///
            end

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
		di as text "-----------------------------------------------------------------------------------------------------"
		di as text "                                       DiDInt.jl Results                    "
		di as text "-----------------------------------------------------------------------------------------------------"
		di as text "State                     | " as text "ATT             | SE     | p-val  | JKNIFE SE  | JKNIFE p-val | RI p-val"
		di as text "--------------------------|-----------------|--------|--------|------------|--------------|---------|"  
		
		// Initialize a temporary matrix to store the numeric results
        tempname table_matrix
        local num_rows = _N
        local num_cols = 7
        matrix `table_matrix' = J(`num_rows', `num_cols', .)
		local state_names ""
		
		forvalues i = 1/`=_N' {
			di as text %-25s "`=`tmp_state'[`i']'" as text " |" as result %-16.7f `tmp_att_s'[`i'] as text " | " as result  %-7.3f `tmp_se_att_s'[`i'] as text "| " as result %-7.3f `tmp_pval_att_s'[`i'] as text "| " as result  %-11.3f `tmp_jknifese_att_s'[`i'] as text "| " as result %-13.3f `tmp_jknifepval_att_s'[`i'] as text "|" as result %-9.3f `tmp_ri_pval_att_s'[`i'] as text "|"
    
			di as text "--------------------------|-----------------|--------|--------|------------|--------------|---------|"
			
			// Store the state name
            local state_name = `tmp_state'[`i']
            local state_names `state_names' `state_name'
            
            // Fill the matrix with numeric values
            matrix `table_matrix'[`i', 1] = `tmp_att_s'[`i']
            matrix `table_matrix'[`i', 2] = `tmp_se_att_s'[`i']
            matrix `table_matrix'[`i', 3] = `tmp_pval_att_s'[`i']
            matrix `table_matrix'[`i', 4] = `tmp_jknifese_att_s'[`i']
            matrix `table_matrix'[`i', 5] = `tmp_jknifepval_att_s'[`i']
            matrix `table_matrix'[`i', 6] = `tmp_ri_pval_att_s'[`i']
            matrix `table_matrix'[`i', 7] = `tmp_weights'[`i']
		}
		// Set column names for the matrix
        matrix colnames `table_matrix' = ATT SE pval JKNIFE_SE JKNIFE_pval RI_pval W
        
        // Set row names for the matrix using the state names
        matrix rownames `table_matrix' = `state_names'
        
        // Store the matrix in r()
        return matrix restab = `table_matrix'
        
		local linesize = c(linesize)
		if `linesize' < 103 {
			di as text "Results table may be squished, try expanding Stata results window."
		}
		di as text _n "Aggregation Method: State"
	}
	
    qui capture confirm variable `tmp_att_cohort'
	if _rc == 0 & `condition_met' == 0 {
		local condition_met 1
		di as text "-----------------------------------------------------------------------------------------------------"
		di as text "                                       DiDInt.jl Results                    "
		di as text "-----------------------------------------------------------------------------------------------------"
		di as text "Cohort                    | " as text "ATT             | SE     | p-val  | JKNIFE SE  | JKNIFE p-val | RI p-val"
		di as text "--------------------------|-----------------|--------|--------|------------|--------------|---------|"  
		
		// Initialize a temporary matrix to store the numeric results
        tempname table_matrix
        local num_rows = _N
        local num_cols = 7
        matrix `table_matrix' = J(`num_rows', `num_cols', .)
		local cohort_names ""
		
		forvalues i = 1/`=_N' {
			di as text %-25s "`=`tmp_treatment_time'[`i']'" as text " |" as result %-16.7f `tmp_att_cohort'[`i'] as text " | " as result  %-7.3f `tmp_se_att_cohort'[`i'] as text "| " as result %-7.3f `tmp_pval_att_cohort'[`i'] as text "| " as result  %-11.3f `tmp_jknifese_att_cohort'[`i'] as text "| " as result %-13.3f `tmp_jknifepval_att_cohort'[`i'] as text "|" as result %-9.3f `tmp_ri_pval_att_cohort'[`i'] as text "|"
    
			di as text "--------------------------|-----------------|--------|--------|------------|--------------|---------|"
			
			// Store the cohort name
            local cohort_name = `tmp_treatment_time'[`i']
            local cohort_names `cohort_names' `cohort_name'
            
            // Fill the matrix with numeric values
            matrix `table_matrix'[`i', 1] = `tmp_att_cohort'[`i']
            matrix `table_matrix'[`i', 2] = `tmp_se_att_cohort'[`i']
            matrix `table_matrix'[`i', 3] = `tmp_pval_att_cohort'[`i']
            matrix `table_matrix'[`i', 4] = `tmp_jknifese_att_cohort'[`i']
            matrix `table_matrix'[`i', 5] = `tmp_jknifepval_att_cohort'[`i']
            matrix `table_matrix'[`i', 6] = `tmp_ri_pval_att_cohort'[`i']
            matrix `table_matrix'[`i', 7] = `tmp_weights'[`i']
		}
		// Set column names for the matrix
        matrix colnames `table_matrix' = ATT SE pval JKNIFE_SE JKNIFE_pval RI_pval W
        
        // Set row names for the matrix using the state names
        matrix rownames `table_matrix' = `cohort_names'
        
        // Store the matrix in r()
        return matrix restab = `table_matrix'
        
		local linesize = c(linesize)
		if `linesize' < 103 {
			di as text "Results table may be squished, try expanding Stata results window."
		}
		di as text _n "Aggregation Method: Cohort"
	}

    qui capture confirm variable `tmp_att_sgt'
	if _rc == 0 & `condition_met' == 0 {
		local condition_met 1
		di as text "-----------------------------------------------------------------------------------------------------"
		di as text "                                       DiDInt.jl Results                    "
		di as text "-----------------------------------------------------------------------------------------------------"
		di as text "s;g;t                       | " as text "ATT             | SE     | p-val  | JKNIFE SE  | JKNIFE p-val | RI p-val"
		di as text "--------------------------|-----------------|--------|--------|------------|--------------|---------|"
		
		// Initialize a temporary matrix to store the numeric results
        tempname table_matrix
        local num_rows = _N
        local num_cols = 7
        matrix `table_matrix' = J(`num_rows', `num_cols', .)
		local state_names ""

        tempvar sgt
        qui gen `sgt' = `tmp_state' + ";" + `tmp_gvar' + ";" + `tmp_t'

        // Create the gt varialbe in julia
		
		forvalues i = 1/`=_N' {
			di as text %-25s "`=`sgt'[`i']'" as text " |" as result %-16.7f `tmp_att_sgt'[`i'] as text " | " as result  %-7.3f `tmp_se_att_sgt'[`i'] as text "| " as result %-7.3f `tmp_pval_att_sgt'[`i'] as text "| " as result  %-11.3f `tmp_jknifese_att_sgt'[`i'] as text "| " as result %-13.3f `tmp_jknifepval_att_sgt'[`i'] as text "|" as result %-9.3f `tmp_ri_pval_att_sgt'[`i'] as text "|"
    
			di as text "--------------------------|-----------------|--------|--------|------------|--------------|---------|"
			
			// Store the gt
            local sgt_name = `sgt'[`i']
            local sgt_names `sgt_names' `sgt_name'
            
            // Fill the matrix with numeric values
            matrix `table_matrix'[`i', 1] = `tmp_att_sgt'[`i']
            matrix `table_matrix'[`i', 2] = `tmp_se_att_sgt'[`i']
            matrix `table_matrix'[`i', 3] = `tmp_pval_att_sgt'[`i']
            matrix `table_matrix'[`i', 4] = `tmp_jknifese_att_sgt'[`i']
            matrix `table_matrix'[`i', 5] = `tmp_jknifepval_att_sgt'[`i']
            matrix `table_matrix'[`i', 6] = `tmp_ri_pval_att_sgt'[`i']
            matrix `table_matrix'[`i', 7] = `tmp_weights'[`i']
		}
		// Set column names for the matrix
        matrix colnames `table_matrix' = ATT SE pval JKNIFE_SE JKNIFE_pval RI_pval W
        
        // Set row names for the matrix using the state names
        matrix rownames `table_matrix' = `sgt_names'
        
        // Store the matrix in r()
        return matrix restab = `table_matrix'
        
		local linesize = c(linesize)
		if `linesize' < 103 {
			di as text "Results table may be squished, try expanding Stata results window."
		}
		di as text _n "Aggregation Method: sgt"
	}

    qui capture confirm variable `tmp_att_gt'
	if _rc == 0 & `condition_met' == 0 {
		local condition_met 1
		di as text "-----------------------------------------------------------------------------------------------------"
		di as text "                                       DiDInt.jl Results                    "
		di as text "-----------------------------------------------------------------------------------------------------"
		di as text "g;t                       | " as text "ATT             | SE     | p-val  | JKNIFE SE  | JKNIFE p-val | RI p-val"
		di as text "--------------------------|-----------------|--------|--------|------------|--------------|---------|"
		
		// Initialize a temporary matrix to store the numeric results
        tempname table_matrix
        local num_rows = _N
        local num_cols = 7
        matrix `table_matrix' = J(`num_rows', `num_cols', .)

        tempvar gt
        qui gen `gt' = `tmp_gvar' + ";" + `tmp_time'

        // Create the gt varialbe in julia
		
		forvalues i = 1/`=_N' {
			di as text %-25s "`=`gt'[`i']'" as text " |" as result %-16.7f `tmp_att_gt'[`i'] as text " | " as result  %-7.3f `tmp_se_att_gt'[`i'] as text "| " as result %-7.3f `tmp_pval_att_gt'[`i'] as text "| " as result  %-11.3f `tmp_jknifese_att_gt'[`i'] as text "| " as result %-13.3f `tmp_jknifepval_att_gt'[`i'] as text "|" as result %-9.3f `tmp_ri_pval_att_gt'[`i'] as text "|"
    
			di as text "--------------------------|-----------------|--------|--------|------------|--------------|---------|"
			
			// Store the gt
            local gt_name = `gt'[`i']
            local gt_names `gt_names' `gt_name'
            
            // Fill the matrix with numeric values
            matrix `table_matrix'[`i', 1] = `tmp_att_gt'[`i']
            matrix `table_matrix'[`i', 2] = `tmp_se_att_gt'[`i']
            matrix `table_matrix'[`i', 3] = `tmp_pval_att_gt'[`i']
            matrix `table_matrix'[`i', 4] = `tmp_jknifese_att_gt'[`i']
            matrix `table_matrix'[`i', 5] = `tmp_jknifepval_att_gt'[`i']
            matrix `table_matrix'[`i', 6] = `tmp_ri_pval_att_gt'[`i']
            matrix `table_matrix'[`i', 7] = `tmp_weights'[`i']
		}
		// Set column names for the matrix
        matrix colnames `table_matrix' = ATT SE pval JKNIFE_SE JKNIFE_pval RI_pval W
        
        // Set row names for the matrix using the state names
        matrix rownames `table_matrix' = `gt_names'
        
        // Store the matrix in r()
        return matrix restab = `table_matrix'
        
		local linesize = c(linesize)
		if `linesize' < 103 {
			di as text "Results table may be squished, try expanding Stata results window."
		}
		di as text _n "Aggregation Method: Simple"
	}

    qui capture confirm variable `tmp_att_t'
	if _rc == 0 & `condition_met' == 0 {
		local condition_met 1
		di as text "-----------------------------------------------------------------------------------------------------"
		di as text "                                       DiDInt.jl Results                    "
		di as text "-----------------------------------------------------------------------------------------------------"
		di as text "Periods Since Treatment   | " as text "ATT             | SE     | p-val  | JKNIFE SE  | JKNIFE p-val | RI p-val"
		di as text "--------------------------|-----------------|--------|--------|------------|--------------|---------|"  
		
		// Initialize a temporary matrix to store the numeric results
        tempname table_matrix
        local num_rows = _N
        local num_cols = 7
        matrix `table_matrix' = J(`num_rows', `num_cols', .)
		local time_names ""
		
		forvalues i = 1/`=_N' {
			di as text %-25s "`=`tmp_periods_post_treat'[`i']'" as text " |" as result %-16.7f `tmp_att_t'[`i'] as text " | " as result  %-7.3f `tmp_se_att_t'[`i'] as text "| " as result %-7.3f `tmp_pval_att_t'[`i'] as text "| " as result  %-11.3f `tmp_jknifese_att_t'[`i'] as text "| " as result %-13.3f `tmp_jknifepval_att_t'[`i'] as text "|" as result %-9.3f `tmp_ri_pval_att_t'[`i'] as text "|"
    
			di as text "--------------------------|-----------------|--------|--------|------------|--------------|---------|"
			
			// Store the state name
            local time_name = `tmp_periods_post_treat'[`i']
            local time_names `time_names' `time_name'
            
            // Fill the matrix with numeric values
            matrix `table_matrix'[`i', 1] = `tmp_att_t'[`i']
            matrix `table_matrix'[`i', 2] = `tmp_se_att_t'[`i']
            matrix `table_matrix'[`i', 3] = `tmp_pval_att_t'[`i']
            matrix `table_matrix'[`i', 4] = `tmp_jknifese_att_t'[`i']
            matrix `table_matrix'[`i', 5] = `tmp_jknifepval_att_t'[`i']
            matrix `table_matrix'[`i', 6] = `tmp_ri_pval_att_t'[`i']
            matrix `table_matrix'[`i', 7] = `tmp_weights'[`i']
		}
		// Set column names for the matrix
        matrix colnames `table_matrix' = ATT SE pval JKNIFE_SE JKNIFE_pval RI_pval W
        
        // Set row names for the matrix using the state names
        matrix rownames `table_matrix' = `state_names'
        
        // Store the matrix in r()
        return matrix restab = `table_matrix'
        
		local linesize = c(linesize)
		if `linesize' < 103 {
			di as text "Results table may be squished, try expanding Stata results window."
		}
		di as text _n "Aggregation Method: Periods Since Treatment"
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
	
	qui macro drop outcome state time date_format nperm freq_multiplier treated_states_to_julia treated_times_to_julia freq covariate_to_julia ref_column_to_julia ref_group_to_julia start_date end_date

end

/*--------------------------------------*/
/* Change Log */
/*--------------------------------------*/
*0.5.1 - changed use_pre_controls default to false
*0.5.0 - added start_date and end_date args and removed autoadjust to conincide with new version of DiDInt.jl package
*0.4.1 - added weighting arg
*0.4.0 - added sgt agg option, RI_pvals for sub-aggregate level, and seed arg
*0.3.0 - changed to rclass and added displays for outputs
*0.2.1 - removed 'stata_debug' arg, hopefully not needed anymore
*0.2.0 - fixed 'freq' arg - function actually works now for common + staggered adoption
*0.1.2 - added 'stata_debug' arg and trim whitespce for tokenized args
*0.1.1 - added 'agg' arg
*0.1.0 - created function
