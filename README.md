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
matrix list r(restab) // for the results table at the sub-aggregate ATT level
```

## Example

- **Example do-file:** [`didintjl_example.do`](./didintjl_example.do)
- **Example dataset:** [`MeritExampleDataDiDIntjl.dta`](./MeritExampleDataDiDIntjl.dta)

```stata
. use "MeritExampleDataDiDIntjl.dta", clear
. didintjl, outcome("coll") state("state") time("year") treated_states("34 57 58 59 61 64 71 72 85 88") treatment_times("2000 1998 1993 1997 1999 1996 1991 1998 1997 2000") date_format("yyyy") covariates("asian male black") ccc("int") 


-----------------------------------------------------------------------------------------------------
                                       DiDInt.jl Results                    
-----------------------------------------------------------------------------------------------------
Cohort                    | ATT             | SE     | p-val  | JKNIFE SE  | JKNIFE p-val | RI p-val
--------------------------|-----------------|--------|--------|------------|--------------|---------|
1991-01-01                |0.0044675        | 0.040  | 0.911  | 0.044      | 0.920        |0.947    |
--------------------------|-----------------|--------|--------|------------|--------------|---------|
1993-01-01                |0.0414129        | 0.039  | 0.284  | 0.044      | 0.344        |0.676    |
--------------------------|-----------------|--------|--------|------------|--------------|---------|
1996-01-01                |0.0637732        | 0.047  | 0.172  | 0.058      | 0.272        |0.442    |
--------------------------|-----------------|--------|--------|------------|--------------|---------|
1997-01-01                |0.0883183        | 0.034  | 0.010  | 0.040      | 0.027        |0.333    |
--------------------------|-----------------|--------|--------|------------|--------------|---------|
1998-01-01                |0.0301035        | 0.056  | 0.593  | 0.067      | 0.654        |0.711    |
--------------------------|-----------------|--------|--------|------------|--------------|---------|
1999-01-01                |0.1940669        | 0.022  | 0.000  | 0.035      | 0.000        |0.300    |
--------------------------|-----------------|--------|--------|------------|--------------|---------|
2000-01-01                |-0.0161931       | 0.034  | 0.638  | 0.095      | 0.865        |0.893    |
--------------------------|-----------------|--------|--------|------------|--------------|---------|

Aggregation Method: Cohort

Aggregate Results:
Aggregate ATT: .05110589
Standard error: .01691945
p-value: .02338082
Jackknife SE: .02094461
Jackknife p-value: .05046831
RI p-value: .1911912

. di r(att)
.05110589

. matrix list r(restab)

r(restab)[7,7]
                    ATT           SE         pval    JKNIFE_SE  JKNIFE_pval      RI_pval            W
1991-01-01    .00446749    .04013573    .91142422    .04434281    .91979802    .94694692    .20179564
1993-01-01    .04141289    .03856304    .28364226    .04374331    .34446329    .67567569    .19153485
1996-01-01    .06377317    .04650304    .17173529    .05786769     .2717129    .44244245    .07567336
1997-01-01    .08831835    .03407904    .01038464    .03953078    .02677578    .33333334    .32107738
1998-01-01    .03010352    .05624292    .59341913     .0670686    .65430713     .7107107    .10859342
1999-01-01    .19406688    .02244097    3.613e-13    .03527422    4.179e-07     .3003003    .03548525
2000-01-01   -.01619311    .03420786    .63845724    .09473825    .86512369     .8928929     .0658401

```

