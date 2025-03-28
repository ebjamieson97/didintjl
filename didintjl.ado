/*------------------------------------*/
/*didintjl*/
/*written by Eric Jamieson */
/*version 0.1.0 2025-03-027 */
/*------------------------------------*/

cap program drop didintjl
program define didintjl
    version 16
    syntax, outcome(string) state(string) time(string) ///
            treated_states(string) treatment_times(string) ///
            date_format(string) /// 
            [covariates(string) ccc(string) ref_column(string) ref_group(string) ///
            freq(string) freq_multiplier(int 1) autoadjust(int 0) ///
            nperm(int 1000) verbose(int 1)]

    cap which jl
	if _rc {
    	di as error "The 'julia' package is required but not installed or not found in the system path. See https://github.com/droodman/julia.ado for more details."
    	exit 3
	} 

    // Check that DiDInt.jl for Julia is installed
	jl: using Pkg
	jl: if Base.find_package("DiDInt") === nothing 				///
			SF_display("DiDInt.jl not installed, installing now.");  ///
			Pkg.add(url="https://github.com/ebjamieson97/DiDInt.jl"); ///
			SF_display("DiDInt.jl is done installing.");             ///
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
    global freq = "`freq'"

    // Parse treated_states and treatment_times
    qui jl: treated_states = String[]
    qui jl: treated_times = String[]
    local counter = 1
    qui tokenize "`treated_states'"
    while "`1'" != "" {
        global treated_states_to_julia "`1'"
		qui jl: push!(treated_states, "$treated_states_to_julia")
		local counter = `counter' + 1
		macro shift
    }
    qui tokenize "`treated_times'"
    while "`1'" != "" {
        global treated_times_to_julia "`1'"
		qui jl: push!(treated_times, "$treated_times_to_julia")
		local counter = `counter' + 1
		macro shift
    }

    // Parse covariates if necessary
	if "`covariates'" == ""{
		qui jl: covariates = nothing
	}
	else {
		qui jl: covariates = String[]
		local counter = 1
		tokenize "`covariates'"
		while "`1'" != "" {
            global covariate_to_julia "`1'"
			qui jl: push!(covariates, "$covariate_to_julia")
			local counter = `counter' + 1
			macro shift
		}
		
	}

    if "`ccc'" == "" {
        global ccc = "cohort"
    } 
    else {
        global ccc = "`ccc'"
    }

    if "`ref_column'" != "" {
        qui jl: ref_keys = String[]
        local counter = 1
        qui tokenize "`ref_column'"
        while "`1'" != "" {
            global ref_column_to_julia "`1'"
		    qui jl: push!(ref_keys, "$ref_column_to_julia")
		    local counter = `counter' + 1
		    macro shift
        }
        if "`ref_group'" == "" {
            di as error "If ref_column is specified, then ref_group must be specified as well!"
            exit 6
        }
    }

    if "`ref_group'" != "" {
        qui jl: ref_values = String[]
        local counter = 1
        qui tokenize "`ref_group'"
        while "`1'" != "" {
            global ref_column_to_julia "`1'"
		    qui jl: push!(ref_keys, "$ref_column_to_julia")
		    local counter = `counter' + 1
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

    qui jl: results = DiDInt.didint("$outcome", "$state", "$time", df, treated_states, treated_times, date_format = "$date_format", covariates = covariates, ccc = "$ccc", ref = ref, freq = "$freq", freq_multiplier = $freq_multiplier, autoadjust = autoadjust, nperm = $nperm, verbose = verbose)
    qui jl use results, clear


end
/*--------------------------------------*/
/* Change Log */
/*--------------------------------------*/
*0.1.0 - created function