
# Load packages

using FSM
using PyPlot
using Distributions
using ProgressMeter
using DataAssim

# Load data

function load_data()

  # Load data

  metdata = readdlm(joinpath(dirname(@__FILE__), "..", "data", "met_CdP_all.txt"))
  valdata = readdlm(joinpath(dirname(@__FILE__), "..", "data", "obs_CdP_all.txt"))

  prec = metdata[:, 7] + metdata[:, 8]

  metdata = hcat(metdata, prec)

  valdata[valdata .== -99] = NaN

  dates_met = map(DateTime, metdata[:,1], metdata[:,2], metdata[:,3], metdata[:,4])
  dates_val = map(DateTime, valdata[:,1], valdata[:,2], valdata[:,3], valdata[:,4])

  return dates_met, metdata, dates_val, valdata

end

# Load data

dates_met, metdata, dates_val, valdata = load_data()

# Settings

npart = 100
thres_prec = 273.6890
m_prec = 0.3051
p_corr = 1.0
timestep = 1.0

ntimes = size(metdata,1)

# Initial state

md = [FsmType(1, 1, 1, 1, 0) for i in 1:npart]

q_vec = [q_noise(randn(), randn(), randn(), randn(), randn(), randn()) for i in 1:npart]

# Allocate input array

ip = Array(FsmInput, npart)

# Allocate output array

od = zeros(ntimes, npart)

hs_sim = zeros(npart)

res = zeros(ntimes, 3)

# Initilize particles

wk = ones(npart) / npart

# Loop over time

@showprogress 1 "Computing..." for itime = 1:ntimes

  # Run the model for all particles

  for ipart = 1:npart

    # Handle input data

    year  = metdata[itime, 1]
    month = metdata[itime, 2]
    day   = metdata[itime, 3]
    hour  = metdata[itime, 4]
    SW    = metdata[itime, 5]
    LW    = metdata[itime, 6]
    P     = metdata[itime, 7] + metdata[itime, 8]
    Ta    = metdata[itime, 9]
    RH    = metdata[itime, 10]
    Ua    = metdata[itime, 11]
    Ps    = metdata[itime, 12]

    SW, LW, P, Ta, RH, Ua = perturb_input(q_vec, ipart, timestep, SW, LW, P, Ta, RH, Ua)

    Sf = precip_solid(P, Ta, thres_prec, p_corr, m_prec)

    Rf = precip_liquid(P, Ta, thres_prec, p_corr, m_prec)

    # Run the model

    ip[ipart] = FsmInput(year, month, day, hour, SW, LW, Sf, Rf, Ta, RH, Ua, Ps)

    hs_sim[ipart] = run_fsm(md[ipart], ip[ipart])

  end

  # Find observation

  iobs = find(dates_val .== dates_met[itime])

  hs_obs = valdata[iobs, 5]

  # Run particle filter

  if !isempty(hs_obs) && !isnan(hs_obs[1])

    for ipart = 1:npart
      wk[ipart] = pdf(Normal(hs_obs[1], max(0.1 * hs_obs[1], 0.05)), hs_sim[ipart]) * wk[ipart]
    end

    if sum(wk) > 0.0
      wk = wk / sum(wk)
    else
      wk = ones(npart) / npart
    end

    # Perform resampling

    Neff = 1 / sum(wk.^2)

    if round(Int64, Neff) < round(Int64, npart * 0.8)

      #println("Resampled at step: $itime")

      indx = resample(wk)

      md  = [deepcopy(md[i]) for i in indx]

      q_vec = [deepcopy(q_vec[i]) for i in indx]

      wk = ones(npart) / npart

    end

  end

  # Store results

  res[itime, 1] = sum(wk .* hs_sim)
  res[itime, 2] = minimum(hs_sim)
  res[itime, 3] = maximum(hs_sim)

end

# Plot results

fig = plt[:figure](figsize = (12,7))

plt[:style][:use]("ggplot")

plt[:plot](dates_val, valdata[:,5], linewidth = 1.2, color = "k", label = "Observed", zorder = 1)
plt[:fill_between](dates_met, res[:, 3], res[:, 2], facecolor = "r", edgecolor = "r", label = "Simulated", alpha = 0.55, zorder = 2)
plt[:legend]()



#using plots
#plot(dates_met, res[:, 3], fillrange = res[:, 2], color = "red", fillalpha = 0.5, linealpha = 0.5, label = "sim")
#plot(dates_met, [res[:, 3], res[:, 2]], fillrange = res[:, 2], color = "red", linealpha = 0.5, fillalpha = 0.5, label = "", grid = false)
#plot!(dates_val, valdata[:,5], linewidth = 1.2, color = "k")
# plot([x;x[end:-1:1]],[y1;y2[end:-1:1]], color = :red, linealpha = 0, fillalpha = 0.5, seriestype = :shape, label = "a filled area")
