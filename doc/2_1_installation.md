Installation                        {#install_page}
============

[TOC]
# Downloads
The repository can be cloned as follows:

```
git clone https://github.com/MPMC-Lab/PaScaL_TDMA.git
```
Alternatively, the source files can be downloaded through github menu 'Download ZIP'.




# Compile
@note See detail for more information: [here](compile_page.html). 

## Prerequisites
Prerequisites to compile PaScaL_TDMA are as follows:
* MPI
* fortran compiler (`nvfortran` for GPU runs, NVIDIA HPC SDK 21.1 or higher)  

## Compile and build
* Build PaScaL_TDMA
    ```
	make lib
	```
* Build an example problem after build PaScaL_TDMA

    ```
	make example
	```
* Build all

    ```
	make all
	```
# Mores on compile option
The `Makefile` in root directory is to compile the source code, and is expected to work for most systems. The 'Makefile.inc' file in the root directory can be used to change the compiler (and MPI wrapper) and a few pre-defined compile options depending on compiler, execution environment and et al.

# Running the example
After building the example file, an executable binary, `*.out`, is built in the `run` folder. The `PARA_INPUT.inp` file in the `run` folder is a pre-defined input file, and the `*.out` can be executed as follows:
    ```
	mpirun -np 8 ./a.out ./PARA_INPUT.inp
    ```
# GPU power monitoring
In the `tool` folder, there is a Python script `gpu_power_monitor.py` that can be used to monitor and print real-time GPU power usage with timestamps. To use this script, you will need to install the `pynvml` library.

# Folder structure
* `src` : source files of PaScaL_TDMA 2.0.
* `example` : source files of an example problem for 3D heat-transfer equation.
* `include` : header files are created after building
* `lib` : a static library of PaScaL_TDMA 2.0 is are created after building
* `doc` : documentation
* `run` : an executable binary file for the example problem is created after building.
* `tool` : contains useful scripts and tools.

<div class="section_buttons">

| Previous          |                              Next |
|:------------------|----------------------------------:|
| [Introduction](index.html) | [Compile](compile_page.html) |
</div>