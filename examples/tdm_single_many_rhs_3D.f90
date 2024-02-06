program main

    use mpi
    use PaScaL_TDMA

    implicit none

    integer, parameter  :: Nx = 20, Ny = 21, N = 1000, Nsys = Nx * Ny
    integer :: nprocs, myrank, ierr
    integer :: ista, iend, n_sub
    integer :: i, j, k

    double precision, allocatable, dimension(:)     :: a, b, c
    double precision, allocatable, dimension(:,:,:)   :: d, x
    double precision, allocatable, dimension(:)     :: a_sub, b_sub, c_sub
    double precision, allocatable, dimension(:,:,:)   :: d_sub, x_sub
    integer, allocatable, dimension(:) :: cnt, disp
    type(ptdma_plan_many_rhs) :: px_many   ! Plan for many tridiagonal systems of equations

    call MPI_Init(ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, myrank, ierr)

    call para_range(1, N, nprocs, myrank, ista, iend)
    n_sub = iend - ista + 1

    allocate ( a(N) ); a(:) = 1
    allocate ( b(N) ); b(:) = 2
    allocate ( c(N) ); c(:) = 1
    allocate ( d(Nx, Ny, N) ); d(:,:,:) = 0
    allocate ( x(Nx, Ny, N) ); x(:,:,:) = 0

    allocate ( a_sub(n_sub) ); a_sub(:) = 1
    allocate ( b_sub(n_sub) ); b_sub(:) = 2
    allocate ( c_sub(n_sub) ); c_sub(:) = 1
    allocate ( d_sub(Nx, Ny, n_sub) ); d_sub(:,:,:) = 0
    allocate ( x_sub(Nx, Ny, n_sub) ); x_sub(:,:,:) = 0

    allocate ( cnt(nprocs) ); cnt(:) = 0
    allocate ( disp(nprocs) ); disp(:) = 0

    ! Build cnt and disp array
    call MPI_Gather(n_sub, 1, MPI_INTEGER, cnt, 1, MPI_INTEGER, 0, MPI_COMM_WORLD, ierr)

    if (myrank.eq.0) then
        disp(1) = 0
        do i = 2, size(cnt)
            disp(i) = disp(i - 1) + cnt(i - 1)
        end do

        cnt = cnt * Nsys
        disp = disp * Nsys
    endif
    
    ! Generate random x vector and rhs vector in rank 0
    if (myrank.eq.0) then
        call random_number(x(:,:,:))
        do i = 1, Nx
            do j = 1, Ny
                d(i, j, 1) = b(1) * x(i, j, 1) + c(1) * x(i, j, 2)
                do k = 2, N - 1
                    d(i, j, k) = a(k) * x(i, j, k - 1) + b(k) * x(i, j, k) + c(k) * x(i, j, k + 1)
                enddo
                d(i, j, N) = a(N) * x(i, j, N - 1) + b(N) * x(i, j, N)
        enddo
        enddo
    endif

    ! Scatter rhs vector
    call MPI_Scatterv(d, cnt, disp, MPI_DOUBLE_PRECISION, d_sub, n_sub * Nsys, &
                      MPI_DOUBLE_PRECISION, 0, MPI_COMM_WORLD, ierr)

    ! Solve equation
    call PaScaL_TDMA_plan_many_rhs_create(px_many, Nsys, myrank, nprocs, MPI_COMM_WORLD)
    call PaScaL_TDMA_many_rhs_solve(px_many, a_sub, b_sub, c_sub, d_sub, Nsys, n_sub)
    call PaScaL_TDMA_plan_many_rhs_destroy(px_many, nprocs)

    ! Gather solution and evaluate norm2
    call MPI_Gatherv(d_sub, n_sub * Nsys, MPI_DOUBLE_PRECISION, d, cnt, disp, &
                      MPI_DOUBLE_PRECISION, 0, MPI_COMM_WORLD, ierr)

    if (myrank.eq.0) then
        print *, "Avg. norm2 (norm2 / (Nsys * N)) = ", norm2(d - x) / Nsys / N
    endif

    deallocate (a, b, c, d, x)
    deallocate (a_sub, b_sub, c_sub, d_sub, x_sub)
    deallocate (cnt, disp)

    call MPI_Finalize(ierr)

end program main