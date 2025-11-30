/*------------------------------------*/
/*didintjl_plot*/
/*written by Eric Jamieson */
/*version 0.0.1 2025-11-23 */
/*------------------------------------*/

cap program drop didintjl_plot
program define didintjl_plot
    version 16
    syntax, outcome(varname) state(varname) time(varname) ///
            [gvar(varname) ///
            treated_states(string) treatment_times(string) date_format(string) /// 
            covariates(string) ccc(string) weights(int 1) ref_column(string) ref_group(string) ///
            freq(string) freq_multiplier(int 1) start_date(string) end_date(string) ///
            hc(int 3) event(int 0) ci(real 0.95)]

	// PART ONE: BASIC SETUP 
    qui cap which jl
    if _rc {
        di as error "The 'julia' package is required but not installed or not found in the system path. See https://github.com/droodman/julia.ado for more details."
        exit 3
    }

    // Pass hc, event, and ci args to julia
    qui jl: hc = `hc'
    qui jl: ci = `ci'
    if `event' == 1 {
        qui jl: event = true
    }
    else if `event' == 0 {
        qui jl: event = false
    }
    else {
        di as error "'event' must be either 1 (True) or 0 (False)."
    }

    // Check date_format
    if "`date_format'" == "" {
        qui jl: date_format = nothing
    }
    else {
        qui jl: date_format = "`date_format'"
    }

    // Check that DiDInt.jl for Julia is installed
    qui jl: using Pkg
    jl: if Base.find_package("DiDInt") === nothing              ///
            SF_display("DiDInt.jl not installed, installing now.");  ///
            Pkg.add(url="https://github.com/ebjamieson97/DiDInt.jl"); ///
            SF_display(" DiDInt.jl is done installing.");             ///
        end        
    qui jl: using DiDInt

    qui jl save data

    // Allow some variables to be passed to Julia 
    qui jl: outcome = Symbol("`outcome'")
    qui jl: state = Symbol("`state'")
    qui jl: time = Symbol("`time'")
    qui jl: freq_multiplier = `freq_multiplier'
    if "`gvar'" != "" {
        qui jl: gvar = Symbol("`gvar'")
    }
    else {
        qui jl: gvar = nothing
    }

    if "`freq'" == "" {
        qui jl: freq = nothing
    }
    else {
        qui jl: freq = "`freq'"
    }

    if "`start_date'" == "" {
        qui jl: start_date = nothing
    }
    else {
        qui jl: start_date = "`start_date'"
    }
    if "`end_date'" == "" {
        qui jl: end_date = nothing
    }
    else {
        qui jl: end_date = "`end_date'"
    }

    // Parse treated_states and treatment_times
    if "`treated_states'" != "" {
        qui jl: treated_states = String[]
        qui tokenize "`treated_states'"
        while "`1'" != "" {
            local token = trim("`1'")
            if ("`token'" != "") {
                qui jl: temp = "`token'"
                qui jl: push!(treated_states, temp)
            }
            macro shift
        }
    }
    else {
        qui jl: treated_states = nothing
    }

    if "`treatment_times'" != "" {
        qui jl: treated_times = String[]
        qui tokenize "`treatment_times'"
        while "`1'" != "" {
            local token = trim("`1'")
            if ("`token'" != "") {
                qui jl: temp = "`token'"
                qui jl: push!(treated_times, temp)
            }
            macro shift
        }
    }
    else {
        qui jl: treated_times = nothing
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
                qui jl: temp = "`token'"
                qui jl: push!(covariates, temp)
            }
            macro shift
        }
    }

    if "`ccc'" == "" {
        local ccc "all"
        qui jl: ccc = "all"
    } 
    else {
        qui jl: ccc = String[]
        tokenize "`ccc'"
        while "`1'" != "" {
            local token = trim("`1'")
            if ("`token'" != "") {
                qui jl: temp = "`token'"
                qui jl: push!(ccc, temp)
            }
            macro shift
        }
    }

    if `weights' == 0 {
        qui jl: weights = false
    }
    else if `weights' == 1 {
        qui jl: weights = true
    }
    else {
        di as err "Set 'weights' to either 0 (False) or 1 (True)."
        exit 4
    }

    
    // Parse ref_column tokens with trimming
    if "`ref_column'" != "" {
        qui jl: ref_keys = String[]
        tokenize "`ref_column'"
        while "`1'" != "" {
            local token = trim("`1'")
            if ("`token'" != "") {
                qui jl: temp = "`token'"
                qui jl: push!(ref_keys, temp)
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
                qui jl: temp = "`token'"
                qui jl: push!(ref_values, temp)
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

    // PART TWO: Run didint_plot in Julia
	qui jl: plot_data = DiDInt.didint_plot(outcome, state, time, data, gvar = gvar, treated_states = treated_states, treatment_times = treated_times, date_format = date_format, covariates = covariates, ref = ref, ccc = ccc, event = event, weights = weights, ci = ci, freq = freq, freq_multiplier = freq_multiplier, start_date = start_date, end_date = end_date, hc = hc)
	qui jl: treat_period = skipmissing(plot_data[!, "treat_period"])
    qui jl: n_treat = length(collect(treat_period))
    qui jl: plot_data = plot_data[1:(end-n_treat), Not(:treat_period)]



    // PART THREE: PASS RESULTS TO STATA
	tempname result_frame
    qui cap frame drop `result_frame'
    qui frame create `result_frame'
    qui frame change `result_frame'
	qui jl use plot_data 

    // PART FOUR: Make plots
    if `event' == 0 {
        // Create a mapping of period to time labels
        bysort period: gen first = _n == 1
        
        // Determine x-axis frequency (every 2nd period)
        local xfreq = 2
        
        // Build xlabel string with every xfreq periods
        local xlabel_sparse ""
        qui levelsof period if first, local(all_periods)
        foreach p of local all_periods {
            if mod(`p', `xfreq') == 0 {
                qui levelsof time if period == `p' & first, local(tm) clean
                local xlabel_sparse `"`xlabel_sparse' `p' "`tm'""'
            }
        }
        
        // Check if grc1leg2 is available
        local use_grc1leg2 = 1
        capture which grc1leg2
        if _rc != 0 {
            local use_grc1leg2 = 0
            local yspacing = 7
            local final_ncols = 3
            local final_nrows = 2
        }
        else {
            local yspacing = 1
            local final_ncols = 3
            local final_nrows = 2
        }
        
        // Get treatment periods
        qui jl: SF_macro_save("treatment_times", join(string.(treat_period), " "))

        // Get list of unique states and ccc (specifications) for later use
        qui levelsof state, local(state_list)
		di as result "got state_list"
        local n_states : word count `state_list'
		di as result "got n_states"
        local ncols = min(5, max(2, ceil(`n_states'/10)))
        
        qui levelsof ccc, local(ccc_list)
        local n_specs : word count `ccc_list'
        
        // Create numeric versions for reshape
        encode state, gen(state_num)
        encode ccc, gen(ccc_num)
        
        // Drop string and temporary variables before reshape
        drop state ccc first time start_date period_length
        
        // Reshape to have one column per state
        reshape wide lambda, i(ccc_num period) j(state_num)
        // Define colors for plotting
        local colors "navy maroon forest_green orange purple dkorange teal cranberry"
        di as result "defined colours"
        // Create plots for each specification (ccc)
        local graph_names ""
        local spec_counter = 1
        foreach spec_name of local ccc_list {
            // Build the twoway plot command dynamically
            local plot_cmd ""
            forvalues st = 1/`n_states' {
                local color : word `st' of `colors'
                if `st' > 1 local plot_cmd "`plot_cmd' ||"
                local plot_cmd `plot_cmd' (connected lambda`st' period if ccc_num == `spec_counter', lcolor(`color') mcolor(`color'))"
            }
            
            // Build legend order dynamically
            local legend_order ""
            local counter = 1
            foreach state_name of local state_list {
                local legend_order `"`legend_order' `counter' "`state_name'""'
                local counter = `counter' + 1
            }
            
            // Execute the plot with ccc name as title
            twoway `plot_cmd' ///
                   , title("`spec_name'") ///
                   xline(`treatment_times', lcolor(gray) lpattern(dash) lwidth(medium)) ///
                   legend(order(`legend_order') cols(`ncols') size(small) ///
                          symxsize(3) colgap(9) region(lcolor(black))) ///
                   ytitle("Lambda", margin(r=`yspacing')) ///
                   ylabel(, angle(0) labsize(small)) ///
                   xtitle("Time") ///
                   xlabel(`xlabel_sparse', angle(0) labsize(small)) ///
                   name(spec`spec_counter', replace) nodraw
            
            local graph_names `graph_names' spec`spec_counter'
            local spec_counter = `spec_counter' + 1
        }
        
        // Combine graphs
        if `use_grc1leg2' == 1 {
            grc1leg2 `graph_names', ///
                rows(`final_nrows') cols(`final_ncols') ///
                title("Parallel Trends", justification(center)) ///
                legendfrom(spec1) ///
                position(6) ///
                name(by_spec, replace)
        }
        else {
            graph combine `graph_names', ///
                rows(`final_nrows') cols(`final_ncols') ///
                title("Parallel Trends", justification(center)) ///
                name(by_spec, replace)
        }
    }
    else if `event' == 1 {
        
    }
    
    qui drop _all
	qui frame change default
    qui frame drop `result_frame'
	qui jl: plot_data = nothing; GC.gc()
end

/*--------------------------------------*/
/* Change Log */
/*--------------------------------------*/
* 0.0.1 - created function