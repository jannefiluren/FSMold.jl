
# Load libraries

using PyPlot
using FSM
using DataFrames

# Load data

metdata = readdlm(joinpath(dirname(@__FILE__), "..", "data", "met_CdP_all.txt"), Float32)
valdata = readdlm(joinpath(dirname(@__FILE__), "..", "data", "obs_CdP_all.txt"), Float32)

dates_met = map(DateTime, metdata[:,1], metdata[:,2], metdata[:,3], metdata[:,4])
dates_val = map(DateTime, valdata[:,1], valdata[:,2], valdata[:,3])

# Initialize model states and select model combinations

md = FsmType[]

for i = 0:1, j = 0:1, k = 0:1, l = 0:1, m = 0:1
  push!(md, FsmType(i, j, k, l, m))
end

# Run model for all combinations

hs = zeros(size(metdata, 1), length(md))

tic()

for i in 1:length(md)
  hs[:, i] = run_fsm(md[i], metdata)
end

toc()

# Find the best model

df_obs = DataFrame(
    dates  = dates_val,
    hs_obs = @data(convert(Array{Float64}, valdata[:, 5]))
)

df_obs[:hs_obs][df_obs[:hs_obs].==-99] = NA

sse = Float64[]

for i in 1:length(md)

  df_sim = DataFrame(
      dates  = dates_met,
      hs_sim = @data(convert(Array{Float64}, hs[:, i]))
  )

  df_all = join(df_sim, df_obs, on=:dates)

  complete_cases!(df_all)

  push!(sse, sum((df_all[:hs_sim] - df_all[:hs_obs]).^2))

end

ibest = findfirst(sse .== minimum(sse))

print("am = $(md[ibest].am)\n")
print("cm = $(md[ibest].cm)\n")
print("dm = $(md[ibest].dm)\n")
print("em = $(md[ibest].em)\n")
print("hm = $(md[ibest].hm)\n")

# Plot results

valdata[valdata .== -99] = NaN

plot(dates_met, hs, color = "gray")
plot(dates_val, valdata[:, 5], color = "black")
plot(dates_met, hs[:, ibest], color = "red")
