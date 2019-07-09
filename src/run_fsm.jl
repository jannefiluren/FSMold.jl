
# Model state variables and choices for model combinations 

struct FsmType

    albs::Array{Float64,1}
    Ds::Array{Float64,1}
    Nsnow::Array{Int64,1}
    Sice::Array{Float64,1}
    Sliq::Array{Float64,1}
    theta::Array{Float64,1}
    Tsnow::Array{Float64,1}
    Tsoil::Array{Float64,1}
    Tsurf::Array{Float64,1}

    am::Int64
    cm::Int64
    dm::Int64
    em::Int64
    hm::Int64

    dt::Int64

end

# Model input variables

struct FsmInput

    year::Float64
    month::Float64
    day::Float64
    hour::Float64
    SW::Float64
    LW::Float64
    Sf::Float64
    Rf::Float64
    Ta::Float64
    RH::Float64
    Ua::Float64
    Ps::Float64

end


# Outer constructor for initilizing model state variables

function FsmType(am, cm, dm, em, hm, dt = 3600)

    # Define state variables

    rho_wat = 1000.0                  # Density of water (kg/m^3)
    Tm = 273.15                       # Melting point (K)

    Nsmax = 3                         # Maximum number of snow layers
    Nsoil = 4                         # Number of soil layers

    albs  = Array{Float64}(1)         # Snow albedo
    Ds    = Array{Float64}(Nsmax)     # Snow layer thicknesses (m)
    Nsnow = Array{Int64}(1)           # Number of snow layers
    Sice  = Array{Float64}(Nsmax)     # Ice content of snow layers (kg/m^2)
    Sliq  = Array{Float64}(Nsmax)     # Liquid content of snow layers (kg/m^2)
    theta = Array{Float64}(Nsoil)     # Volumetric moisture content of soil layers
    Tsnow = Array{Float64}(Nsmax)     # Snow layer temperatures (K)
    Tsoil = Array{Float64}(Nsoil)     # Soil layer temperatures (K)
    Tsurf = Array{Float64}(1)         # Surface skin temperature (K)

    # No snow in initial state

    albs[:] = 0.8
    Ds[:] = 0
    Nsnow[:] = 0
    Sice[:] = 0
    Sliq[:] = 0
    Tsnow[:] = Tm

    # Initial soil profiles

    fcly = 0.3
    fsnd = 0.6
    Vsat = 0.505 - 0.037 * fcly - 0.142 * fsnd

    fsat = 0.5 * ones(Float64, Nsoil)  # Initial moisture content of soil layers as fractions of saturation
    Tsoil[:] = 285.0
    Tsurf[1] = Tsoil[1]
    for k = 1:Nsoil
       	theta[k] = fsat[k] * Vsat
    end

    FsmType(albs, Ds, Nsnow, Sice, Sliq, theta, Tsnow, Tsoil, Tsurf, am, cm, dm, em, hm, dt)

end


# Run the model for a time series of meteorological input data 

function run_fsm!(hs, md::FsmType, metdata)

    for itime = 1:size(metdata, 1)

       	year  = metdata[itime, 1]
       	month = metdata[itime, 2]
       	day   = metdata[itime, 3]
       	hour  = metdata[itime, 4]
       	SW    = metdata[itime, 5]
       	LW    = metdata[itime, 6]
       	Sf    = metdata[itime, 7]
       	Rf    = metdata[itime, 8]
       	Ta    = metdata[itime, 9]
       	RH    = metdata[itime, 10]
       	Ua    = metdata[itime, 11]
       	Ps    = metdata[itime, 12]

       	ccall((:fsm_, fsm),
              Cvoid, 
              (Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64},
	       Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64},
	       Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Int64},
               Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64},
               Ptr{Float64}, Ptr{Int64}, Ptr{Int64}, Ptr{Int64}, Ptr{Int64}, Ptr{Int64}, Ptr{Int64}),
	      Ref{year}, Ref{month}, Ref{day}, Ref{hour}, Ref{SW}, Ref{LW}, Ref{Sf}, Ref{Rf}, Ref{Ta}, Ref{RH}, Ref{Ua}, Ref{Ps}, md.albs, md.Ds, md.Nsnow, md.Sice, md.Sliq, md.theta, md.Tsnow, md.Tsoil, md.Tsurf, Ref{md.am}, Ref{md.cm}, Ref{md.dm}, Ref{md.em}, Ref{md.hm}, Ref{md.dt})

       	hs[itime] = sum(md.Ds)

    end

    return nothing

end


function run_fsm(md::FsmType, metdata)
    
    hs = zeros(Float64, size(metdata, 1))
    
    run_fsm!(hs, md::FsmType, metdata)
    
    return hs

end


# Run the model for only one time step using FsmInput type

function run_fsm(md::FsmType, id::FsmInput)

    # Call fsm

    ccall((:fsm_, fsm),
          Cvoid,
          (Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64},
	   Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64},
	   Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Int64},
           Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64},
           Ptr{Float64}, Ptr{Int64}, Ptr{Int64}, Ptr{Int64}, Ptr{Int64}, Ptr{Int64}, Ptr{Int64}),
	  Ref{id.year}, Ref{id.month}, Ref{id.day}, Ref{id.hour}, Ref{id.SW}, Ref{id.LW}, Ref{id.Sf}, Ref{id.Rf}, Ref{id.Ta}, Ref{id.RH}, Ref{id.Ua}, Ref{id.Ps}, md.albs, md.Ds, md.Nsnow, md.Sice, md.Sliq, md.theta, md.Tsnow, md.Tsoil, md.Tsurf, Ref{md.am}, Ref{md.cm}, Ref{md.dm}, Ref{md.em}, Ref{md.hm}, Ref{md.dt})

    # Save results

    hs = sum(md.Ds)

    return hs

end
