Theory                          {#theory_page}
======

[TOC]
# Thomas algorithm

 The Thomas algorithm is the best-known **sequential tridiagonal matrix algorhtm** (TDMA) that is commonly used to obtain the solution of a tridiagonal system. It is a special form of the Gaussian elimination algorithm for the diaonally dominant or symmetric positive definite (SPD) tridiagonal matrix. This algorithm has the ideal compuational complexity, \\(O(N)\\). It greatly reduced to \\(O(N)\\) instead of \\(O(N^3)\\) for the Gauss elimination.

$$
\begin{pmatrix}
b_0 & c_0 & 0 & 0 & 0 & \cdots &0 \\\
a_1 & b_1 & c_1 & 0 & 0 & \cdots &0 \\\
0 & a_2 & b_2 & c_2 & 0 &  \cdots &0 \\\
0 & 0 & a_3 & b_3 & c_3 &   \cdots &0 \\\
\vdots & \vdots & \vdots & \vdots & \vdots & \ddots & \vdots \\\
0 & 0 & 0 & 0 & 0 & \cdots & c_{n-1} \\\
0 & 0 & 0 & 0 & 0 & \cdots & b_n
\end{pmatrix}   \begin{pmatrix}
x_0 \\\ x_1 \\\ x_2 \\\ x_3 \\\ \vdots \\\ x_{n-2} \\\ x_{n-1}
\end{pmatrix}   \begin{pmatrix}
d_0 \\\ d_1 \\\ d_2 \\\ d_3 \\\ \vdots \\\ d_{n-2} \\\ d_{n-1}
\end{pmatrix},
$$

the Gaussian elimination procedure can be simplified as follows:

\image html al1_TA.png width=40%

1. Forward elimination
   
   $$
   c'_i = 
   \begin{cases}
    \frac{c_i}{b_i}, & i=0\\
    \frac{c_i}{b_i-a_i c' _{i-1}}, & i=1, 2, \cdots, n-2\\
   \end{cases}
   $$
   $$
   d'_i = 
      \begin{cases}
      \frac{d_i}{b_i}, & i=0\\
      \frac{d_i - a_i d'_{i-1}}{b_i-a_i c' _{i-1}}, & i=1, 2, \cdots, n-1\\
      \end{cases}
   $$

2. Backward elimination
   
   <!-- $$
   x_{n-1} &= d' _{n-1}, \\\
   x_i &= d' _i - c' _i x_{i+1}, \quad i = n-2, n-3, \cdots, 1, 0
   $$ -->
   $$
   \begin{aligned}
   x_{n-1} &= {d}'_{n-1}, \\\
   x_{i} &= {d}'_{i} - c'_{i}x_{i+1}, \quad i = n-2, n-3, \cdots, 1, 0
   \end{aligned}
   $$

However, the Thomas algorithm for a tridiagonal system cannot be made parallel due to its sequential process during both elimination and substitution.


# Modified Thomas algorithm

The divide-and-conquer method [[1]](#reference) is used to solve partitioned tridiagonal systems of equations in the distributed memory system.

**Divide-and-conquer methods**

- Divide-and-condquer methods have been utilized to solve many tridiagonal systems in a parallel manner. 
- Large tridiagonal system is transformed into a reduced tridiagonal system through partial reduction in each partitioned sub-matrix, which are divided in computing cores. 

- The soultion is the obtained by solving the reduced tridiagonal system and updating the remaining unknowns in the partitioned sub-matrices.

### Hybrid Thomas-PCR
- A hybrid Thomas-PCR method that directly reduces the unknowns using a modified Thomas algorithm and solves the reduced tridiagonal system using a PCR algorithm.

\image html al2_modified_TA.png width=50%


  1. Transforming the partitioned sub-matrices in the tridiagonal systems into modified sub-matrices 
  2. Constructing reduced tridiagonal systems from the modified sub-matrices
  3. Solving the reduced tridiagonal systems
  4. Distributing the solution of reduced tridiagonal system
  5. Updating the other unknowns


\image html eq_1.png width=80%

**Step 1.** Each computing core transforms the partitioned sub-matrices in the tridiagonal systems of equations into the modified forms by applying the modified Thomas algorithm [[1]](#reference).

\image html eq_2.png width=80%

**Step 2.** The reduced tridiagonal systems are contributed by collecting the first and last row.
* Data communication is still required
  * The amount of communication required is remarkably reduced
  * **Each core needs to communicate only for two rows**

\image html eq_3.png width=50%

**Step 3.** The reduced tridiagonal systems contributed in upper equation are solved by applying the Thomas algorithm.

\image html eq_4.png width=50%

**Step 4.** The remaining unknowns of the modified sub-matrices in Step 1 are solved in each computing core with the solutions obtained in Step 3 and Step 4. 

# All-to-all communication

- The newly designed communication scheme based on MPI Alltoallw acclerates to collect the rows and construct the reduced tridiagonal systems.

\image html al3_PaScaL_TDMA.png width=60%

The main algorithm for a tridiagonal matrix consists of the following five steps: 

**Step 1.** Transform the partitioned submatrices in the tridiagonal systems into modified submatrices:
        Each computing core transforms the partitioned submatrices in the tridiagonal systems of equations into the modified forms by applying `the modified Thomas algorithm`.

**Step 2.** Construct reduced tridiagonal systems from the modified submatrices:
        The reduced tridiagonal systems are constructed by collecting the first and last rows of the modified submatrices from each core using `MPI_Ialltoallw`.

\image html fig1.png width=90%

- PaScaL_TDMA reduces the amount of communication compared to conventional all-to-all scheme.


**Step 3.** Solve the reduced tridiagonal systems:
        The reduced tridiagonal systems constructed in `Step 2` are solved by applying `the Thomas algorithm`.

**Step 4.** Distribute the solutions of the reduced tridiagonal systems:
        The solutions of the reduced tridiagonal systems in `Step 3` are distributed to each core using `MPI_Ialltoallw`.
        This communication is an exact inverse of the communication in `Step 2`.

**Step 5.** Update the other unknowns in the modified tridiagonal systems:
        The remaining unknowns in the modified submatrices in `Step 1` are solved in each computing core with the solutions obtained in `Step 3` and `Step 4`.


### PaScaL_TDMA: Parallel and Scalable Library TriDiagonal Matrix Algorithm
- PaScaL_TDMA is written in Fortran90 and implemented using module interfaces for easy application.

- Massively parallel library to solve the tridiagonal systems of equations for distributed memory systems. 

  - PaScaL_TDMA computes the large tridiagonal system by partitioning it into small sub-systems in a parallel manner 
  - The dramatic decrease of total execution time with good strong and weak scalability

\image html fig2.png

- `Transpose 1` conducts the necessary data transpose for the next step.
  - The number of transpose is equal to the number of FFT and TDMA
  - It requires larger communication than `Transpose 2` inevitably.
  
- `Transpose 2` conducts a redundant transpose to retrieve the original decomposed shape. 
  - Due to this redundant step, the size of communicator is kept no more than the number of MPI proccesses in each axis direction.
  - This scheme can be more beneficial than `Transpose 1` when the number of MPI processes is huge.
  

\image html fig3.png width=50%

- We construct build two-stage MPI communicators: intra-communicator belonging to inter-communicator. 
  - The root rank in the intra-communicator gathers data from the processes within the same intra-communicator.
  - Then, the root ranks in each intra-communicator read/write data from/to a single file using the MPI-IO through the inter-communicator.

# Reference
<!-- [1] [J. Kim, P. Moin, J. Comput. Phys. 59 (2) (1985) 308–323.](https://www.sciencedirect.com/science/article/abs/pii/0021999185901482) -->
[[1] Laszlo, E., Giles, M., & Appleyard, J. (2016). Manycore algorithms for batch scalar and block tridiagonal solvers. ACM Transactions on Mathematical Software (TOMS), 42(4), 1-36.](https://www.sciencedirect.com/science/article/abs/pii/0021999185901482) 

<div class="section_buttons">

| Previous          |                              Next |
|:------------------|----------------------------------:|
| [Performance](perf_page.html) | [Links](link_page.html) |
</div>