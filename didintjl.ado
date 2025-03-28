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

            

end
/*--------------------------------------*/
/* Change Log */
/*--------------------------------------*/
*0.1.0 - created function