export CODE_RUNNER_SYSTEM=archer
export CODE_RUNNER_NO_ANALYSIS=false
eval `modulecmd bash unload PrgEnv-cray`
eval `modulecmd bash load PrgEnv-gnu`
eval `modulecmd bash load fftw`
export XTPE_LINK_TYPE=dynamic
export LD_LIBRARY_PATH=/opt/xt-libsci/10.4.1/gnu/lib/44:$LD_LIBRARY_PATH
echo "Configuration is now complete."
