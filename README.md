# didintjl
This Stata package acts as a wrapper for the Julia package DiDInt.jl. 

undidjl allows for estimation of difference-in-differences with covariates that may vary by state & time, see https://arxiv.org/abs/2412.14447 for more details.

## Installation 
```stata
net install didintjl, from("https://raw.githubusercontent.com/ebjamieson97/didintjl/main/")
```
### Update
```stata
ado uninstall undidjl
net install undidjl, from("https://raw.githubusercontent.com/ebjamieson97/didintjl/main/")
```

## Requirements
* **Julia**: Version > 1.11.1
* **Stata**: Version 14.1 or later
* **David Roodman’s Julia package for Stata**: [julia.ado](https://github.com/droodman/julia.ado)

### Get Help
```stata
help didintjl
```
