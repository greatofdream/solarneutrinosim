! ***********************************************************************
!
!   Copyright (C) 2010-2019  Bill Paxton & The MESA Team
!
!   this file is part of mesa.
!
!   mesa is free software; you can redistribute it and/or modify
!   it under the terms of the gnu general library public license as published
!   by the free software foundation; either version 2 of the license, or
!   (at your option) any later version.
!
!   mesa is distributed in the hope that it will be useful, 
!   but without any warranty; without even the implied warranty of
!   merchantability or fitness for a particular purpose.  see the
!   gnu library general public license for more details.
!
!   you should have received a copy of the gnu library general public license
!   along with this software; if not, write to the free software
!   foundation, inc., 59 temple place, suite 330, boston, ma 02111-1307 usa
!
! ***********************************************************************
 
      module run_star_extras

      use star_lib
      use star_def
      use const_def
      use math_lib
      
      implicit none
      
      ! these routines are called by the standard run_star check_model
      contains
      
      subroutine extras_controls(id, ierr)
            integer, intent(in) :: id
            integer, intent(out) :: ierr
            type (star_info), pointer :: s
            ierr = 0
            call star_ptr(id, s, ierr)
            if (ierr /= 0) return
            
            ! this is the place to set any procedure pointers you want to change
            ! e.g., other_wind, other_mixing, other_energy  (see star_data.inc)
   
   
            ! the extras functions in this file will not be called
            ! unless you set their function pointers as done below.
            ! otherwise we use a null_ version which does nothing (except warn).
   
            s% extras_startup => extras_startup
            s% extras_start_step => extras_start_step
            s% extras_check_model => extras_check_model
            s% extras_finish_step => extras_finish_step
            s% extras_after_evolve => extras_after_evolve
            s% how_many_extra_history_columns => how_many_extra_history_columns
            s% data_for_extra_history_columns => data_for_extra_history_columns
            s% how_many_extra_profile_columns => how_many_extra_profile_columns
            s% data_for_extra_profile_columns => data_for_extra_profile_columns  
   
            s% how_many_extra_history_header_items => how_many_extra_history_header_items
            s% data_for_extra_history_header_items => data_for_extra_history_header_items
            s% how_many_extra_profile_header_items => how_many_extra_profile_header_items
            s% data_for_extra_profile_header_items => data_for_extra_profile_header_items
   
         end subroutine extras_controls
         
         
         subroutine extras_startup(id, restart, ierr)
            integer, intent(in) :: id
            logical, intent(in) :: restart
            integer, intent(out) :: ierr
            type (star_info), pointer :: s
            ierr = 0
            call star_ptr(id, s, ierr)
            if (ierr /= 0) return
         end subroutine extras_startup
         
   
         integer function extras_start_step(id)
            integer, intent(in) :: id
            integer :: ierr
            type (star_info), pointer :: s
            ierr = 0
            call star_ptr(id, s, ierr)
            if (ierr /= 0) return
            extras_start_step = 0
         end function extras_start_step
   
   
         ! returns either keep_going, retry, or terminate.
         integer function extras_check_model(id)
            integer, intent(in) :: id
            integer :: ierr
            type (star_info), pointer :: s
            ierr = 0
            call star_ptr(id, s, ierr)
            if (ierr /= 0) return
            extras_check_model = keep_going         
            if (.false. .and. s% star_mass_h1 < 0.35d0) then
               ! stop when star hydrogen mass drops to specified level
               extras_check_model = terminate
               write(*, *) 'have reached desired hydrogen mass'
               return
            end if
   
   
            ! if you want to check multiple conditions, it can be useful
            ! to set a different termination code depending on which
            ! condition was triggered.  MESA provides 9 customizeable
            ! termination codes, named t_xtra1 .. t_xtra9.  You can
            ! customize the messages that will be printed upon exit by
            ! setting the corresponding termination_code_str value.
            ! termination_code_str(t_xtra1) = 'my termination condition'
   
            ! by default, indicate where (in the code) MESA terminated
            if (extras_check_model == terminate) s% termination_code = t_extras_check_model
         end function extras_check_model
   
   
         integer function how_many_extra_history_columns(id)
            integer, intent(in) :: id
            integer :: ierr
            type (star_info), pointer :: s
            ierr = 0
            call star_ptr(id, s, ierr)
            if (ierr /= 0) return
            how_many_extra_history_columns = 2
         end function how_many_extra_history_columns
         
         
         subroutine data_for_extra_history_columns(id, n, names, vals, ierr)
            integer, intent(in) :: id, n
            character (len=maxlen_history_column_name) :: names(n)
            real(dp) :: vals(n)
            integer, intent(out) :: ierr
            type (star_info), pointer :: s

            ! define the variable
            real(dp), parameter :: frac = 0.90
            integer :: i
            real(dp) :: edot, edot_partial

            ierr = 0
            call star_ptr(id, s, ierr)
            if (ierr /= 0) return
            
            ! note: do NOT add the extras names to history_columns.list
            ! the history_columns.list is only for the built-in history column options.
            ! it must not include the new column names you are adding here.

            !  track the Lagrangian mass and physical radius interior to which 90% of the nuclear energy generation takes place
            edot = dot_product(s% dm(1:s% nz), s% eps_nuc(1:s% nz))
            edot_partial = 0
            do i = s% nz, 1, -1
                  edot_partial = edot_partial + s% dm(i) * s% eps_nuc(i)
                  if (edot_partial .ge. (frac * edot)) exit
            end do
            ! column 1
            names(1) = "m90"
            vals(1) = s% q(i) * s% star_mass  ! in solar masses

            ! column 2
            names(2) = "log_R90"
            vals(2) = log10(s% R(i) / Rsun) ! in solar radii

   
         end subroutine data_for_extra_history_columns
   
         
         integer function how_many_extra_profile_columns(id)
            integer, intent(in) :: id
            integer :: ierr
            type (star_info), pointer :: s
            ierr = 0
            call star_ptr(id, s, ierr)
            if (ierr /= 0) return
            how_many_extra_profile_columns = 9
         end function how_many_extra_profile_columns
         
         
         subroutine data_for_extra_profile_columns(id, n, nz, names, vals, ierr)
            use net_lib, only: net_work_size
            integer, intent(in) :: id, n, nz
            character (len=maxlen_profile_column_name) :: names(n)
            real(dp) :: vals(nz,n)
            integer, intent(out) :: ierr
            type (star_info), pointer :: s
            integer :: k, op_err, net_lwork
            logical :: okay
            ierr = 0
            call star_ptr(id, s, ierr)
            if (ierr /= 0) return

            net_lwork = net_work_size(s% net_handle, ierr)

            ! note: do NOT add the extra names to profile_columns.list
            ! the profile_columns.list is only for the built-in profile column options.
            ! it must not include the new column names you are adding here.
   
            ! here is an example for adding a profile column
            ! names(1) = 'beta'
            ! do k = 1, nz
            !   vals(k,1) = s% Pgas(k)/s% Peos(k)
            ! end do
            names(1) = 'extra_raw_rate_r_h1_h1_ec_h2'
            names(2) = 'screened_rate_r_h1_h1_ec_h2'
            names(3) = 'screened_rate_r_h1_h1_wk_h2'
            names(4) = 'screened_rate_r_h1_he3_wk_he4'
            names(5) = 'screened_rate_r_be7_wk_li7'
            names(6) = 'screened_rate_r_b8_wk_he4_he4'
            names(7) = 'screened_rate_r_n13_wk_c13'
            names(8) = 'screened_rate_r_o15_wk_n15'
            names(9) = 'screened_rate_r_f17_wk_o17'
            okay = .true.
            do k = 1, nz
               if (.not. okay) cycle
               op_err = 0
               call do1_net( &
                  s, k, s% species, &
                  s% num_reactions, net_lwork, &
                  n, nz, vals, op_err)
               if (op_err /= 0) okay = .false.
            end do
         end subroutine data_for_extra_profile_columns

         subroutine do1_net( &
               s, k, species, num_reactions, net_lwork, &
               n, nz, vals, ierr)
            use rates_def, only: std_reaction_Qs, std_reaction_neuQs, i_rate
            use net_def, only: Net_Info
            use net_lib, only: net_get
            use chem_def, only: chem_isos, category_name
            use eos_def, only : i_eta
            use utils_lib,only: &
               is_bad_num, realloc_double, realloc_double3
            type (star_info), pointer :: s         
            integer, intent(in) :: k, species, num_reactions, net_lwork, n, nz
            real(dp) :: vals(nz,n)
            integer, intent(out) :: ierr
   
            integer :: i, j, screening_mode
            real(dp) :: log10_rho, log10_T, alfa, beta, &
               d_eps_nuc_dRho, d_eps_nuc_dT, cat_factor
            real(dp), target :: net_work_ary(net_lwork)
            real(dp), pointer :: net_work(:)
            type (Net_Info), target :: net_info_target
            type (Net_Info), pointer :: netinfo
            
            character (len=100) :: message
            real(dp), pointer :: reaction_neuQs(:)
            integer :: sz
            real(dp) :: eps_nuc_factor
            
            logical, parameter :: dbg = .false.

            include 'formats'
            
            ierr = 0
            
            net_work => net_work_ary
            netinfo => net_info_target
         
            log10_rho = s% lnd(k)/ln10
            log10_T = s% lnT(k)/ln10

            screening_mode = get_screening_mode(s,ierr)         
            if (ierr /= 0) then
               write(*,*) 'unknown string for screening_mode: ' // trim(s% screening_mode)
               stop 'do1_net'
               return
            end if
         
            call net_get( &
               s% net_handle, .false., netinfo, species, num_reactions, s% xa(1:species,k), &
               s% T(k), log10_T, s% rho(k), log10_Rho, &
               s% abar(k), s% zbar(k), s% z2bar(k), s% ye(k), &
               s% eta(k), s% d_eos_dlnT(i_eta,k), s% d_eos_dlnd(i_eta,k), &
               s% rate_factors, s% weak_rate_factor, &
               std_reaction_Qs, std_reaction_neuQs, &
               s% eps_nuc(k), d_eps_nuc_dRho, d_eps_nuc_dT, s% d_epsnuc_dx(:,k), & 
               s% dxdt_nuc(:,k), s% d_dxdt_nuc_dRho(:,k), s% d_dxdt_nuc_dT(:,k), s% d_dxdt_nuc_dx(:,:,k), &
               screening_mode, &
               s% eps_nuc_categories(:,k), &
               s% eps_nuc_neu_total(k), net_lwork, net_work, ierr)
         
            if (ierr /= 0) then
               write(*,*) 'do1_net: net_get failure for cell ', k
               return
            end if
            
            call show_stuff(s,k,net_lwork,net_work,n,nz,vals)

         end subroutine do1_net

         integer function get_screening_mode(s,ierr)
            use rates_lib, only: screening_option
            type (star_info), pointer :: s 
            integer, intent(out) :: ierr
            include 'formats'
            ierr = 0
            if (s% screening_mode_value >= 0) then
               get_screening_mode = s% screening_mode_value
               return
            end if
            get_screening_mode = screening_option(s% screening_mode, ierr)
            if (ierr /= 0) return
            s% screening_mode_value = get_screening_mode
            !write(*,2) 'get_screening_mode ' // &
            !   trim(s% screening_mode), get_screening_mode
         end function get_screening_mode
         
         
         
         subroutine show_stuff(s,k,lwork,work,n,nz,vals)
            use chem_def
            use rates_def
            use rates_lib, only: rates_reaction_id
            use net_lib, only: get_reaction_id_table_ptr, get_net_rate_ptrs
            type (star_info), pointer :: s         
            integer, intent(in) :: k, lwork, n, nz
            real(dp), pointer :: work(:)
            real(dp) :: vals(nz,n)

            integer, pointer :: reaction_id(:) ! maps net reaction number to reaction id
            integer :: i, j, ierr, species, num_reactions, rate_id
            real(dp), pointer, dimension(:) :: &
               rate_screened, rate_screened_dT, rate_screened_dRho, &
               rate_raw, rate_raw_dT, rate_raw_dRho

            include 'formats'
            
            ierr = 0
            num_reactions = s% num_reactions
            
            call get_net_rate_ptrs(s% net_handle, &
               rate_screened, rate_screened_dT, rate_screened_dRho, &
               rate_raw, rate_raw_dT, rate_raw_dRho, lwork, work, &
               ierr)
            if (ierr /= 0) then
               write(*,*) 'failed in get_net_rate_ptrs'
               stop 1
            end if
            
            call get_reaction_id_table_ptr(s% net_handle, reaction_id, ierr) 
            if (ierr /= 0) return

            ! set the character string name of the reaction rates
            ! and fill vals(k,how_many_extra_profile_columns)

            ! raw rate
            rate_id = rates_reaction_id('r_h1_h1_ec_h2')
            if (rate_id <= 0) then
               write(*,*) 'failed to find reaction rate id -- not valid name?'
               vals(k,1) = 0
               return
            end if
            vals(k,1) = get_raw_rate(rate_id)
            
            ! screened rate
            rate_id = rates_reaction_id('r_h1_h1_ec_h2')
            if (rate_id <= 0) then
               write(*,*) 'failed to find reaction rate id -- not valid name?'
               vals(k,2) = 0
               return
            end if
            vals(k,2) = get_screened_rate(rate_id)

            rate_id = rates_reaction_id('r_h1_h1_wk_h2')
            if (rate_id <= 0) then
               write(*,*) 'failed to find reaction rate id -- not valid name?'
               vals(k,3) = 0
               return
            end if
            vals(k,3) = get_screened_rate(rate_id)

            rate_id = rates_reaction_id('r_h1_he3_wk_he4')
            if (rate_id <= 0) then
               write(*,*) 'failed to find reaction rate id -- not valid name?'
               vals(k,4) = 0
               return
            end if
            vals(k,4) = get_screened_rate(rate_id)

            rate_id = rates_reaction_id('r_be7_wk_li7')
            if (rate_id <= 0) then
               write(*,*) 'failed to find reaction rate id -- not valid name?'
               vals(k,5) = 0
               return
            end if
            vals(k,5) = get_screened_rate(rate_id)

            rate_id = rates_reaction_id('r_b8_wk_he4_he4')
            if (rate_id <= 0) then
               write(*,*) 'failed to find reaction rate id -- not valid name?'
               vals(k,6) = 0
               return
            end if
            vals(k,6) = get_screened_rate(rate_id)

            rate_id = rates_reaction_id('r_n13_wk_c13')
            if (rate_id <= 0) then
               write(*,*) 'failed to find reaction rate id -- not valid name?'
               vals(k,7) = 0
               return
            end if
            vals(k,7) = get_screened_rate(rate_id)
            
            rate_id = rates_reaction_id('r_o15_wk_n15')
            if (rate_id <= 0) then
               write(*,*) 'failed to find reaction rate id -- not valid name?'
               vals(k,8) = 0
               return
            end if
            vals(k,8) = get_screened_rate(rate_id)

            rate_id = rates_reaction_id('r_f17_wk_o17')
            if (rate_id <= 0) then
               write(*,*) 'failed to find reaction rate id -- not valid name?'
               vals(k,9) = 0
               return
            end if
            vals(k,9) = get_screened_rate(rate_id)
            
            contains
            
            real(dp) function get_screened_rate(id)
               integer, intent(in) :: id
               integer :: j
               include 'formats'

               get_screened_rate = -99
               do j=1,num_reactions

                  if (reaction_id(j) /= rate_id) cycle

   !                write(6,'(a,i4,i4,1p2e12.4)') 'found it', id, size(std_reaction_Qs), & 
   !                           std_reaction_Qs(ir_c12_ag_o16), std_reaction_Qs(ir_he4_he4_he4_to_c12)
   ! rates are in num_reaction order, Q's are in irate order
   ! eps_nuc from a specific reaction
                     get_screened_rate = rate_screened(j)
                  return
               end do

               write(*,*) 'failed to find reaction rate id -- not in current net?'
               get_screened_rate = -99

            end function get_screened_rate

            real(dp) function get_raw_rate(id)
               integer, intent(in) :: id
               integer :: j
               include 'formats'

               get_raw_rate = -99
               do j=1,num_reactions

                  if (reaction_id(j) /= rate_id) cycle

                  ! if (rate_screened(j) < 1d-20) then
                  !    get_raw_rate = -99
                  ! else
                  get_raw_rate = rate_raw(j)
                  ! end if
                  return
               end do

               write(*,*) 'failed to find reaction rate id -- not in current net?'
               get_raw_rate = -99

            end function get_raw_rate
            
         end subroutine show_stuff

         integer function how_many_extra_history_header_items(id)
            integer, intent(in) :: id
            integer :: ierr
            type (star_info), pointer :: s
            ierr = 0
            call star_ptr(id, s, ierr)
            if (ierr /= 0) return
            how_many_extra_history_header_items = 0
         end function how_many_extra_history_header_items
   
   
         subroutine data_for_extra_history_header_items(id, n, names, vals, ierr)
            integer, intent(in) :: id, n
            character (len=maxlen_history_column_name) :: names(n)
            real(dp) :: vals(n)
            type(star_info), pointer :: s
            integer, intent(out) :: ierr
            ierr = 0
            call star_ptr(id,s,ierr)
            if(ierr/=0) return
   
            ! here is an example for adding an extra history header item
            ! also set how_many_extra_history_header_items
            ! names(1) = 'mixing_length_alpha'
            ! vals(1) = s% mixing_length_alpha
   
         end subroutine data_for_extra_history_header_items
   
   
         integer function how_many_extra_profile_header_items(id)
            integer, intent(in) :: id
            integer :: ierr
            type (star_info), pointer :: s
            ierr = 0
            call star_ptr(id, s, ierr)
            if (ierr /= 0) return
            how_many_extra_profile_header_items = 0
         end function how_many_extra_profile_header_items
   
   
         subroutine data_for_extra_profile_header_items(id, n, names, vals, ierr)
            integer, intent(in) :: id, n
            character (len=maxlen_profile_column_name) :: names(n)
            real(dp) :: vals(n)
            type(star_info), pointer :: s
            integer, intent(out) :: ierr
            ierr = 0
            call star_ptr(id,s,ierr)
            if(ierr/=0) return
   
            ! here is an example for adding an extra profile header item
            ! also set how_many_extra_profile_header_items
            ! names(1) = 'mixing_length_alpha'
            ! vals(1) = s% mixing_length_alpha
   
         end subroutine data_for_extra_profile_header_items
   
   
         ! returns either keep_going or terminate.
         ! note: cannot request retry; extras_check_model can do that.
         integer function extras_finish_step(id)
            integer, intent(in) :: id
            integer :: ierr
            type (star_info), pointer :: s
            ierr = 0
            call star_ptr(id, s, ierr)
            if (ierr /= 0) return
            extras_finish_step = keep_going
   
            ! to save a profile, 
               ! s% need_to_save_profiles_now = .true.
            ! to update the star log,
               ! s% need_to_update_history_now = .true.
   
            ! see extras_check_model for information about custom termination codes
            ! by default, indicate where (in the code) MESA terminated
            if (extras_finish_step == terminate) s% termination_code = t_extras_finish_step
         end function extras_finish_step
         
         
         subroutine extras_after_evolve(id, ierr)
            integer, intent(in) :: id
            integer, intent(out) :: ierr
            type (star_info), pointer :: s
            ierr = 0
            call star_ptr(id, s, ierr)
            if (ierr /= 0) return
         end subroutine extras_after_evolve
   

      end module run_star_extras
      
