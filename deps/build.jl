using Libdl

mods = ["MODULES.f90"];

routines = ["CUMULATE.f90", "DRIVE.f90", "FSM.f90", "INITIALIZE.f90", "OUTPUT.f90", "PHYSICS.f90", "QSAT.f90", "SET_PARAMETERS.f90", "SNOW.f90", "SOIL.f90", "SURF_EBAL.f90", "SURF_EXCH.f90", "SURF_PROPS.f90", "TRIDIAG.f90"];

if Sys.iswindows()
    flags = ["-m$(Sys.WORD_SIZE)", "-shared", "-O3"]
else
    flags = ["-m$(Sys.WORD_SIZE)", "-shared", "-O3", "-fPIC"]
end

run(`gfortran $flags $mods $routines -o FSM.$(Libdl.dlext)`)

rm.(filter!(f -> endswith(f, "mod"), readdir()))
