module toms_minimizer
use vars_module 

implicit none

integer, save :: job_no = 0

public :: delayed_submit, objective_function

CONTAINS

function objective_function(x) result(value)
  use vars_module
  real(dp), dimension(:), intent(in) :: x
  real(dp)                           :: value

  real(dp), dimension(nvars) :: x_dum
  character(len=40) :: name
  logical :: file_exists

  job_no = job_no + 1
  write(name,"(a,i4.4)") "job_", job_no

  call submit_job(name,x)
  call collect_job(name,value)
  
end function objective_function

subroutine submit_job(name,x)
  real(dp), dimension(:), intent(in) :: x
  character(len=*), intent(in) :: name

  real(dp), dimension(nvars) :: x_dum
  logical :: file_exists

  inquire(file=trim(name)// ".sed", exist=file_exists)
  x_dum=x
  if(file_exists) then
    print *, "file exits. getting information"
    call get_subs_file(x_dum,name)
  endif

  call generate_subs_file(x,name)
  call system("sh run_script.sh " // trim(name))!run job
endsubroutine submit_job

subroutine collect_job(name,value)
  character(len=*), intent(in) :: name
  real(dp) ,intent(out):: value
  real(dp) :: e
  integer  :: iu, iostat

  value = huge(0.0_dp)  ! Default value if something goes wrong

  call io_assign(iu)!collect job
  open(unit=iu,file=trim(name)// "/OPTIM_OUTPUT", &
        form="formatted",status="old", iostat=iostat)
  if (iostat /=0 ) then
     STOP "OPTIM_OUTPUT file not available"
  endif
  read(iu,*) e
  value = e
  close(iu)
endsubroutine collect_job

subroutine delayed_submit(p,y)
real(dp), dimension(:,:), intent(in)  :: p
real(dp),dimension(:),intent(out) :: y !return the energies from our delayed collection
character(len=40) :: name
integer :: i,job_no_at_start

job_no_at_start = job_no
!submit jobs
   do i=1, nvars+1
    write(name,"(a,i4.4)") "job_", job_no_at_start+i
    call submit_job(name,p(i,:)) 
   enddo

!get results
    do i=1, nvars+1
  write(name,"(a,i4.4)") "job_", job_no_at_start+i
      call collect_job(name,y(i))
      job_no = job_no + 1
   enddo
end subroutine delayed_submit

end module toms_minimizer
