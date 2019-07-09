using FSM
using Base.Test

# Load driving data

metdata = readdlm(joinpath(dirname(@__FILE__), "..", "data", "met_CdP_0506.txt"));

# Load data from fortran run

valdata = readdlm(joinpath(dirname(@__FILE__), "..", "data", "out_CdP_0506.txt"));

# Model data

md = FsmType(0, 0, 0, 0, 0);

# Run model

hs_new = run_fsm(md, metdata);

# From fortran run

hs_old = valdata[:, 6];

# Tests

@test maximum(abs(hs_new-hs_old)) < 0.01
