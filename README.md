# didintjl
This Stata package acts as a wrapper for the Julia package DiDInt.jl. 

undidjl allows for estimation of difference-in-differences with covariates that may vary by state & time, see https://arxiv.org/abs/2412.14447 for more details.

## Installation 
```stata
net install didintjl, from("https://raw.githubusercontent.com/ebjamieson97/didintjl/main/")
```
didintjl may run slow the first time it is run if the DiDInt.jl package for Julia is not already downloaded. didintjl will automatically download the DiDInt.jl package for Julia if it is not found to be downloaded already.


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
