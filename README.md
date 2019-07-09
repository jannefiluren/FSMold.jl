# FSM

[![Build Status](https://travis-ci.org/jmgnve/FSM.jl.svg?branch=master)](https://travis-ci.org/jmgnve/FSM.jl)

[![Coverage Status](https://coveralls.io/repos/github/jmgnve/FSM.jl/badge.svg?branch=master)](https://coveralls.io/github/jmgnve/FSM.jl?branch=master)

Julia wrapper for the Factorial Snow Model (original code available on this [homepage](https://github.com/RichardEssery/FSM)). For installing the package, run the following code:

```julia
Pkg.clone("https://github.com/jmgnve/FSM.jl")
```

The example below runs one model combination and plots the results (requires the PyPlot.jl and Plots.jl packages).

```julia
using FSM
using PyPlot

am = 0;
cm = 0;
dm = 0;
em = 0;
hm = 0;

metdata = readdlm(joinpath(Pkg.dir("FSM"), "data\\met_CdP_0506.txt"), Float32);

md = FsmType(am, cm, dm, em, hm);

hs = run_fsm(md, metdata);

plot(hs)

```

The example folder contains code for running all model combinations and also a simple particle filter implementation:

```julia
cd(joinpath(Pkg.dir("FSM"), "examples"))

include("run_all_combinations.jl")

include("test_pfilter.jl")
```






