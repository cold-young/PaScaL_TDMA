###############################################################################
# Compile setting with intel compiler and intel MPI.
# Modify flags according to the system and environment
###############################################################################

# Pre-set TDMA_PATH and MPI (See prerequisites)
# HOME := [Your Path]/PaScaL_TDMA
# MPI := /opt/nvidia/hpc_sdk/Linux_x86_64/24.3/comm_libs/12.3/openmpi4/openmpi-4.1.5

# FLAG  = -O3 -fPIC -cpp
# FLAG += -g
# FLAG += -fcheck=all -warn-all 
# FLAG += -fp-model=precise 
# FLAG += -check bounds
# FLAG += -xMIC-AVX512

###############################################################################
# Compile setting with nvfortran and non-intel MPI.
# Modify flags according to the system and environment
###############################################################################

FC = $(MPI)/bin/mpifort

#FLAG  = -fcheck=all -Og -g -cpp -Wall -fbacktrace -pedantic -fopenmp
FLAG  = -O3 -fPIC -cpp 
#FLAG += -tp=skylake 

###############################################################################
# To use CUDA
# PaScaL_TDMA is compiled for CUDA also.
###############################################################################

#USE_CUDA = yes
#FLAG += -mp:multicore -Mcuda -Minfo=accel 
#FLAG += -DUSE_NVTX


