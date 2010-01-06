!@+leo-ver=4-thin
!@+node:gcross.20100106124611.1984:@thin second_order.f95
!@@language fortran90

module vpif__greens_function__second_order
  implicit none

contains

!@+others
!@+node:gcross.20100106124611.2001:initialize_weights
subroutine initialize_weights(number_of_slices,weights)
    integer, intent(in) :: number_of_slices
    double precision, intent(out) :: weights(number_of_slices)

    weights(1) = 0.5d0
    weights(2:number_of_slices-1) = 1d0
    weights(number_of_slices) = 0.5d0

end subroutine
!@-node:gcross.20100106124611.2001:initialize_weights
!@+node:gcross.20100106124611.2002:compute_log_greens_function
function compute_log_greens_function(number_of_slices,weights,potential) result (log_gfn)
    integer, intent(in) :: number_of_slices
    double precision, intent(in), dimension(number_of_slices) :: weights, potential

    double precision :: log_gfn

    interface
        pure function ddot(n,x,incx,y,incy)
          integer, intent(in) :: n, incx, incy
          double precision, intent(in), dimension(n*incx) :: x
          double precision, intent(in), dimension(n*incy) :: y
          double precision :: ddot
        end function ddot
    end interface

    log_gfn = ddot(number_of_slices,weights,1,potential,1)

end function
!@-node:gcross.20100106124611.2002:compute_log_greens_function
!@+node:gcross.20100106124611.2004:compute_log_greens_function_
subroutine compute_log_greens_function_(number_of_slices,weights,potential,log_gfn)
    integer, intent(in) :: number_of_slices
    double precision, intent(in), dimension(number_of_slices) :: weights, potential
    double precision, intent(out) :: log_gfn

    log_gfn = compute_log_greens_function(number_of_slices,weights,potential)

end subroutine
!@-node:gcross.20100106124611.2004:compute_log_greens_function_
!@-others

end module
!@-node:gcross.20100106124611.1984:@thin second_order.f95
!@-leo
