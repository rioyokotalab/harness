program cpu_fortran
  implicit none
  integer(kind=8), parameter :: n = 100000_8
  integer(kind=8) :: i, total, expected
  total = 0_8
  do i = 1_8, n
    total = total + i
  end do
  expected = n * (n + 1_8) / 2_8
  if (total /= expected) error stop 1
  print '(a)', 'cpu_fortran=pass'
end program cpu_fortran
