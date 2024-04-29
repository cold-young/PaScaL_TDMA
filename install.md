## Compile
## Prerequisites
Prerequisites to compile PaScaL_TDMA are as follows:
* MPI
* fortran compiler ([`nvfortran`](https://developer.nvidia.com/hpc-sdk-downloads) for GPU runs, NVIDIA HPC SDK 21.1 or higher)
    
### Option1: NVIDIA HPC SDK + nvfortran
* Install `NVIDIA HPC SDK => 21.1` : [Link](https://developer.nvidia.com/hpc-sdk-downloads)
  * The NVIDIA HPC SDK includes a pre-compiled version of Open MPI.
  * Tested in `HPC SDK 24.3`, `cuda 12.3`.
  * Change `24.3` to `Your SDK version`
  
  ```shell
  cd ~/PaScaL_TDMA
  export TDMA_PATH=$(pwd)
  export NVARCH=`uname -s`_`uname -m`
  export PATH=/opt/nvidia/hpc_sdk/$NVARCH/24.3/compilers/bin:$PATH
  export cuda_version=$(nvcc --version | grep "release" | sed 's/.*release //' | sed 's/,//' | cut -d' ' -f1); export cuda_version
  export MPI=/opt/nvidia/hpc_sdk/$NVARCH/24.3/comm_libs/$cuda_version/openmpi4/latest
  export PATH=$PATH:/opt/nvidia/hpc_sdk/$NVARCH/24.3/compilers/bin
  export opt=module
  ```

  * Add shortcuts (*Optional*)
  ```shell

  echo 'export NVARCH=`uname -s`_`uname -m`' >> ~/.bashrc
  echo 'alias  nvmpirun="/opt/nvidia/hpc_sdk/$NVARCH/24.3/comm_libs/mpi/bin/mpirun"' >> ~/.bashrc

  source ~/.bashrc
  ```

* Build PaScaL_TDMA 
  ```shell
  make all
  ```

* Test examples
  ```shell 
  cd examples
  nvmpirun -np 2 ex1_single.out
  ```

### Option2: Intell + Open MPI
  ```shell
  cd ~/PaScaL_TDMA
  export TDMA_PATH=$(pwd)

  export opt=J
  ```


### Compile and build
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