program main

    use mpi
    use PaScaL_TDMA
    use mpi_topology

    implicit none

    integer :: Nx = 100, Ny = 100
    integer :: nx_sub, ny_sub, n_sub
    integer :: nprocs, myrank, ierr
    integer :: ista, iend
    integer :: npx
    integer :: i, j, iblk
    integer, allocatable, dimension(:) :: cnt_x, disp_x, cnt_y, disp_y, cnt_all, disp_all

    double precision, allocatable, dimension(:,:) :: a, b, c, d, x, y
    double precision, allocatable, dimension(:,:) :: a_sub, b_sub, c_sub, d_sub, d_sub_tr
    double precision, allocatable, dimension(:)   :: d_blk

    type(ptdma_plan_many) :: px_many, py_many   ! Plan for many tridiagonal systems of equations

    call MPI_Init(ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, myrank, ierr)

    call MPI_Dims_create(nprocs, 2, np_dim, ierr)

    period(0) = .false.
    period(1) = .false.

    call mpi_topology_make

    npx = np_dim(0)

    call para_range(1, nx, comm_1d_x%nprocs, comm_1d_x%myrank, ista, iend)
    nx_sub = iend - ista + 1

    call para_range(1, ny, comm_1d_y%nprocs, comm_1d_y%myrank, ista, iend)
    ny_sub = iend - ista + 1

    n_sub = nx_sub * ny_sub

    allocate ( a(Nx, Ny) ); a(:,:) = 1
    allocate ( b(Nx, Ny) ); b(:,:) = 2
    allocate ( c(Nx, Ny) ); c(:,:) = 1
    allocate ( d(Nx, Ny) ); d(:,:) = 0
    allocate ( x(Nx, Ny) ); x(:,:) = 0
    allocate ( y(Nx, Ny) ); y(:,:) = 0
    allocate ( d_blk(Nx * Ny) ); d_blk(:) = 0

    allocate ( cnt_x(np_dim(0)) );  cnt_x(:) = 0
    allocate ( cnt_y(np_dim(1)) );  cnt_y(:) = 0
    allocate ( cnt_all(nprocs) );   cnt_all(:) = 0
    allocate ( disp_x(np_dim(0)) ); disp_x(:) = 0
    allocate ( disp_y(np_dim(1)) ); disp_y(:) = 0
    allocate ( disp_all(nprocs) );  disp_all(:) = 0

    ! Build cnt and disp array
    call MPI_Allgather(nx_sub, 1, MPI_INTEGER, cnt_x,   1, MPI_INTEGER, comm_1d_x%mpi_comm, ierr)
    call MPI_Allgather(ny_sub, 1, MPI_INTEGER, cnt_y,   1, MPI_INTEGER, comm_1d_y%mpi_comm, ierr)
    call MPI_Allgather(n_sub,  1, MPI_INTEGER, cnt_all, 1, MPI_INTEGER, MPI_COMM_WORLD, ierr)

    disp_x(1) = 0
    do i = 2, size(cnt_x)
        disp_x(i) = disp_x(i - 1) + cnt_x(i - 1)
    enddo

    disp_y(1) = 0
    do i = 2, size(cnt_y)
        disp_y(i) = disp_y(i - 1) + cnt_y(i - 1)
    enddo

    disp_all(1) = 0
    do i = 2, nprocs
        disp_all(i) = disp_all(i - 1) + cnt_all(i - 1)
    enddo

    ! Generate random x vector and rhs vector in rank 0
    if (myrank.eq.0) then

        call random_number(x(:,:))

        ! y = A_x * x
        do j = 1, ny
            y(1, j) = b(1, j) * x(1, j) + c(1, j) * x(2, j)
            do i = 2, nx - 1
                y(i, j) = a(i, j) * x(i - 1, j) + b(i, j) * x(i, j) + c(i, j) * x(i + 1, j)
            enddo
            y(nx, j) = a(nx, j) * x(nx - 1, j) + b(nx, j) * x(nx, j)
        enddo

        ! d = A_y * y
        do i = 1, nx
            d(i, 1) = b(i, 1) * y(i, 1) + c(i, 1) * y(i, 2)
        enddo
        do j = 2, ny - 1
            do i = 1, nx
                d(i, j) = a(i, j) * y(i, j - 1) + b(i, j) * y(i, j) + c(i, j) * y(i, j + 1)
            enddo
        enddo
        do i = 1, nx
            d(i, ny) = a(i, ny) * y(i, ny - 1) + b(i, ny) * y(i, ny)
        enddo

        do iblk = 1, npx
            do j = 1, ny
                do i = 1, cnt_x(iblk)
                    d_blk(i + (j - 1) * cnt_x(iblk) + disp_x(iblk) * ny) &
                        = d(i + disp_x(iblk), j)
                enddo
            enddo
        enddo
    endif

    ! Main solver part
    allocate ( a_sub(nx_sub, ny_sub) ); a_sub(:,:) = 1
    allocate ( b_sub(nx_sub, ny_sub) ); b_sub(:,:) = 2
    allocate ( c_sub(nx_sub, ny_sub) ); c_sub(:,:) = 1
    allocate ( d_sub(nx_sub, ny_sub) ); d_sub(:,:) = 0
    allocate ( d_sub_tr(ny_sub, nx_sub) ); d_sub_tr(:,:) = 0

    ! Scatter rhs vector
    call MPI_Scatterv(d_blk, cnt_all, disp_all, MPI_DOUBLE_PRECISION, d_sub, n_sub, &
                      MPI_DOUBLE_PRECISION, 0, MPI_COMM_WORLD, ierr)

    ! Solve equation in y-direction
    call PaScaL_TDMA_plan_many_create(py_many, nx_sub, comm_1d_y%myrank, comm_1d_y%nprocs, comm_1d_y%mpi_comm)
    call PaScaL_TDMA_many_solve(py_many, a_sub, b_sub, c_sub, d_sub, nx_sub, ny_sub)
    call PaScaL_TDMA_plan_many_destroy(py_many, comm_1d_y%nprocs)


    ! Solve equation in x-direction
    a_sub(:,:) = 1
    b_sub(:,:) = 2
    c_sub(:,:) = 1

    do j = 1, ny_sub
        do i = 1, nx_sub
            d_sub_tr(j, i) = d_sub(i, j)
        enddo
    enddo

    call PaScaL_TDMA_plan_many_create(px_many, ny_sub, comm_1d_x%myrank, comm_1d_x%nprocs, comm_1d_x%mpi_comm)
    call PaScaL_TDMA_many_solve(px_many, a_sub, b_sub, c_sub, d_sub_tr, ny_sub, nx_sub)
    call PaScaL_TDMA_plan_many_destroy(px_many, comm_1d_x%nprocs)

    do j = 1, ny_sub
        do i = 1, nx_sub
            d_sub(i, j) = d_sub_tr(j, i)
        enddo
    enddo

    ! Gather solution and evaluate norm2
    call MPI_Gatherv(d_sub, n_sub, MPI_DOUBLE_PRECISION, d_blk, cnt_all, disp_all, &
                      MPI_DOUBLE_PRECISION, 0, MPI_COMM_WORLD, ierr)

    do iblk = 1, npx
        do j = 1, ny
            do i = 1, cnt_x(iblk)
                d(i + disp_x(iblk), j) = &
                    d_blk(i + (j - 1) * cnt_x(iblk) + disp_x(iblk) * ny)
            enddo
        enddo
    enddo

    if (myrank.eq.0) then
        print *, "Avg. norm2 (norm2 / (nx * ny)) = ", norm2(d - x) / nx / ny
    endif


    deallocate (a, b, c, d, x, d_blk)
    deallocate (a_sub, b_sub, c_sub, d_sub)
    deallocate (cnt_x, disp_x)
    deallocate (cnt_y, disp_y)
    deallocate (cnt_all, disp_all)

    call mpi_topology_clean

    call MPI_Finalize(ierr)

end program main

!> @brief       Module for creating the cartesian topology of the MPI processes and subcommunicators.
!> @details     This module has three subcommunicators in each-direction and related subroutines.
!>
module mpi_topology

    use mpi

    implicit none

    integer, public :: mpi_world_cart       !< Communicator for cartesian topology
    integer, public :: np_dim(0:1)          !< Number of MPI processes in 2D topology
    logical, public :: period(0:1)          !< Periodicity in each direction

    !> @brief   Type variable for the information of 1D communicator
    type, public :: cart_comm_1d
        integer :: myrank                   !< Rank ID in current communicator
        integer :: nprocs                   !< Number of processes in current communicator
        integer :: west_rank                !< Previous rank ID in current communicator
        integer :: east_rank                !< Next rank ID in current communicator
        integer :: mpi_comm                 !< Current communicator
    end type cart_comm_1d

    type(cart_comm_1d), public :: comm_1d_x     !< Subcommunicator information in x-direction
    type(cart_comm_1d), public :: comm_1d_y     !< Subcommunicator information in y-direction

    private

    public  :: mpi_topology_make
    public  :: mpi_topology_clean

    contains

    !>
    !> @brief       Destroy the communicator for cartesian topology.
    !>
    subroutine mpi_topology_clean()

        implicit none
        integer :: ierr

        call MPI_Comm_free(mpi_world_cart, ierr)

    end subroutine mpi_topology_clean

    !>
    !> @brief       Create the cartesian topology for the MPI processes and subcommunicators.
    !>
    subroutine mpi_topology_make()
        implicit none
        logical :: remain(0:1)
        integer :: ierr

        ! Create the cartesian topology.
        call MPI_Cart_create( MPI_COMM_WORLD,    &!  input  | integer      | Input communicator (handle).
                              2,                 &!  input  | integer      | Number of dimensions of Cartesian grid (integer).
                              np_dim,            &!  input  | integer(1:3) | Integer array of size ndims specifying the number of processes in each dimension.
                              period,            &!  input  | logical(1:3) | Logical array of size ndims specifying whether the grid is periodic (true=1) or not (false=0) in each dimension.
                              .false.,           &!  input  | logical      | Ranking may be reordered (true=1) or not (false=0) (logical).
                              mpi_world_cart,    &! *output | integer      | Communicator with new Cartesian topology (handle).
                              ierr              &!  output | integer      | Fortran only: Error status
                            )

        ! Create subcommunicators and assign two neighboring processes in the x-direction.
        remain(0) = .true.
        remain(1) = .false.
        call MPI_Cart_sub( mpi_world_cart, remain, comm_1d_x%mpi_comm, ierr)
        call MPI_Comm_rank(comm_1d_x%mpi_comm, comm_1d_x%myrank, ierr)
        call MPI_Comm_size(comm_1d_x%mpi_comm, comm_1d_x%nprocs, ierr)
        call MPI_Cart_shift(comm_1d_x%mpi_comm, 0, 1, comm_1d_x%west_rank, comm_1d_x%east_rank, ierr)

        ! Create subcommunicators and assign two neighboring processes in the y-direction
        remain(0) = .false.
        remain(1) = .true.
        call MPI_Cart_sub( mpi_world_cart, remain, comm_1d_y%mpi_comm, ierr)
        call MPI_Comm_rank(comm_1d_y%mpi_comm, comm_1d_y%myrank, ierr)
        call MPI_Comm_size(comm_1d_y%mpi_comm, comm_1d_y%nprocs, ierr)
        call MPI_Cart_shift(comm_1d_y%mpi_comm, 0, 1, comm_1d_y%west_rank, comm_1d_y%east_rank, ierr)

    end subroutine mpi_topology_make

end module mpi_topology
    
