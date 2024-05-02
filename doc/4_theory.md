Theory                          {#theory_page}
======

[TOC]
# Thomas algorithm

 The Thomas algorithm is the best-known sequential tridiagonal matrix algorhtm (TDMA) that is commonly used to obtain the solution of a tridiagonal system. It is a special form of the Gaussian elimination algorithm for the diaonally dominant or symmetric positive definite (SPD) tridiagonal matrix. This algorithm has the ideal compuational complexity, $O(N)$. It greatly reduced to $O(N)$ instead of $O(N^3)$ for the Gauss elimination.
 
 However, the Thomas algorithm for a tridiagonal system cannot be made parallel due to its sequential process during both elimination and substitution.

$$
\begin{pmatrix}
b_0 & c_0 & 0 & 0 & 0 & \cdots &0 \\
a_1 & b_1 & c_1 & 0 & 0 & \cdots &0 \\
0 & a_2 & b_2 & c_2 & 0 &  \cdots &0 \\
0 & 0 & a_3 & b_3 & c_3 &   \cdots &0 \\
\vdots & \vdots & \vdots & \vdots & \vdots & \ddots & \vdots \\
0 & 0 & 0 & 0 & 0 & \cdots & c_{n-1} \\
0 & 0 & 0 & 0 & 0 & \cdots & b_n
\end{pmatrix}
\begin{pmatrix}
x_0 \\ x_1 \\ x_2 \\ x_3 \\ \vdots \\ x_{n-2} \\ x_{n-1}
\end{pmatrix}
\begin{pmatrix}
d_0 \\ d_1 \\ d_2 \\ d_3 \\ \vdots \\ d_{n-2} \\ d_{n-1}
\end{pmatrix},
$$

the Gaussian elimination procedure can be simplified as follows:

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
   
   $$
   \begin{aligned}
   x_{n-1} & = d' _{n-1}, \\
   x_i & = d' _i - c' _i x_{i+1}, \quad i = n-2, n-3, \cdots, 1, 0
   \end{aligned}
   $$



# Modified Thomas algorithm

It is for distributed memory.

?? parallel cyclic reduction (PCR)? 
?? Alternatively, divide-and-conquer methods have been utilized to solve many tridiagonal systems in a parallel manner. In these methods, a large tridiagonal system is transformed into a reduced tridiagonal system through partial reduction in each partitioned sub-matrix, which are divided into computing cores. 


# All-to-all communication

Reduced all-to-all communication

<div class="section_buttons">

| Previous          |                              Next |
|:------------------|----------------------------------:|
| [Performance](perf_page.html) | [Links](link_page.html) |
</div>