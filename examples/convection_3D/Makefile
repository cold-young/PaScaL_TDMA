include $(HOME)/Makefile.inc

EXE = convection_3D

INC = $(HOME)/include
LIB = $(HOME)/lib -lpascal_tdma

global = global.o
topology = mpi_topology.o 
subdomain = mpi_subdomain.o
THETA = solve_theta.o
main = main.o

OBJS   = $(global) $(topology) $(subdomain) $(THETA) $(main)

all:$(OBJS)
	$(FC) ${FLAG} ${OBJS} -o $(EXE) -I$(INC) -L$(LIB)
	mv $(EXE) $(HOME)/run

%.o: %.f90
	$(FC) $(FLAG) -c $^ -o $@  -I$(INC)

%(subdomain)	: %(topology)
%(THETA)		: %(global) #%(p3t_module) 
%(main)			: %(global) %(topology) %(subdomain) %(THETA)
$(EXE)			: %(OBJS)

clean:
	rm -f *.mod *.o *__genmod.f90 $(HOME)/run/$(EXE) $(HOME)/run/*.PLT $(HOME)/run/*.dat
