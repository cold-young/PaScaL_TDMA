program main

    use mpi
    use PaScaL_TDMA

    implicit none

    integer, parameter  :: N = 10
    integer :: nprocs, myrank, ierr
    integer :: ista, iend, n_sub
    integer :: i

    double precision, allocatable, dimension(:) :: a, b, c, d, x
    double precision, allocatable, dimension(:) :: a_sub, b_sub, c_sub, d_sub, x_sub
    integer, allocatable, dimension(:) :: cnt, disp
    type(ptdma_plan_single) :: px_single   ! Plan for a single tridiagonal system of equations

    call MPI_Init(ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, myrank, ierr)

    call para_range(1, N, nprocs, myrank, ista, iend)
    n_sub = iend - ista + 1

    allocate (a(N)); a(:) = 1
    allocate (b(N)); b(:) = 2
    allocate (c(N)); c(:) = 1
    allocate (d(N)); d(:) = 0
    allocate (x(N)); x(:) = 0

    allocate (a_sub(n_sub)); a_sub(:) = 1
    allocate (b_sub(n_sub)); b_sub(:) = 2
    allocate (c_sub(n_sub)); c_sub(:) = 1
    allocate (d_sub(n_sub)); d_sub(:) = 0
    allocate (x_sub(n_sub)); x_sub(:) = 0

    allocate ( cnt(nprocs) ); cnt(:) = 0
    allocate ( disp(nprocs) ); disp(:) = 0

    ! Build cnt and disp array
    call MPI_Gather(n_sub, 1, MPI_INTEGER, cnt, 1, MPI_INTEGER, 0, MPI_COMM_WORLD, ierr)

    if (myrank.eq.0) then
        disp(1) = 0
        do i = 2, size(cnt)
            disp(i) = disp(i - 1) + cnt(i - 1)
        end do
    endif

    ! Generate random x vector and rhs vector in rank 0
    if (myrank.eq.0) then
        call random_number(x)
        d(1) = b(1) * x(1) + c(1) * x(2)
        do i = 2, N-1
            d(i) = a(i) * x(i - 1) + b(i) * x(i) + c(i) * x(i + 1)
        enddo
        d(N) = a(N) * x(N - 1) + b(N) * x(N)
    endif

    ! Scatter rhs vector
    call MPI_Scatterv(d, cnt, disp, MPI_DOUBLE_PRECISION, d_sub, n_sub, &
                      MPI_DOUBLE_PRECISION, 0, MPI_COMM_WORLD, ierr)

    ! Solve equation
    call PaScaL_TDMA_plan_single_create(px_single, myrank, nprocs, MPI_COMM_WORLD, 0)
    call PaScaL_TDMA_single_solve(px_single, a_sub, b_sub, c_sub, d_sub, n_sub)
    call PaScaL_TDMA_plan_single_destroy(px_single)

    ! Gather solution and evaluate norm2
    call MPI_Gatherv(d_sub, n_sub, MPI_DOUBLE_PRECISION, d, cnt, disp, &
                      MPI_DOUBLE_PRECISION, 0, MPI_COMM_WORLD, ierr)

    if (myrank.eq.0) then
        print *, "Avg. norm2 (norm2 / N)= ", norm2(d - x) / N
    endif

    deallocate (a, b, c, d, x)
    deallocate (a_sub, b_sub, c_sub, d_sub, x_sub)
    deallocate (cnt, disp)

    call MPI_Finalize(ierr)

end program main