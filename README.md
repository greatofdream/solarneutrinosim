# Introduction
Calculate the neutrino flux for different SSM
+ starting:
    + 1 M_sun
    + Z_ini:
+ constraints
    + tau: life,4.54E9yr
    + L: luminosity,3.8418E33ergs-1
    + R: radius,6.9598E10cm
    + Z/X: photospheric metal-to-hydrogen mass fraction
# Setting
+ By default, the initial composition in MESA is `initial_zfracs = 3` which corresponds to the GS98 metal fraction
```
initial_zfracs = 6
kappa_file_prefix = 'a09'
```
+ `initial_z`: to set the metals fractions, initial metallicity for create pre-ms and create initial model.
    - `star_job.defaults`,select one of the options defined in ``$MESA_DIR/chem/public/chem_def.f90``
    - `$MESA_DIR/star/private/adjust_xyz.f90`: `case (0) ! use non-standard values given in controls`
    - invoked by `$MESA_DIR/star/job/run_star_support.f90`
+ `history_columns.list`: column meaning
+ `star/defaults/controls.defaults`: control meaning
+ [rewrite the function](https://docs.mesastar.org/en/release-r22.05.1/using_mesa/extending_mesa.html?highlight=run_star_extras#using-the-other-hooks)
+ difference between z_initial and chem_def is used for set metalicity fraction
+ need recompile the project (`./mk`) after update the MESA
# Software Requirement
[Mesa Doc](https://docs.mesastar.org/en/release-r22.05.1/using_mesa/running.html)
[2020 school](https://cococubed.com/mesa_summer_school_2020/index.html)
[Instrument paper](https://arxiv.org/abs/1903.01426)
[Mail list](https://lists.mesastar.org/mailman/listinfo/mesa-users)

# Appendix
## MB22
+ `mesa-r22.05.1` does not contain MB22

## Reaction
+ `data/net_data/nets/basic.net`:
```
! pp chains
         
rpp_to_he3          ! p(p e+nu)h2(p g)he3
rpep_to_he3         ! p(e-p nu)h2(p g)he3     
r_he3_he3_to_h1_h1_he4       ! he3(he3 2p)he4 
r34_pp2             ! he4(he3 g)be7(e- nu)li7(p a)he4 
r34_pp3             ! he4(he3 g)be7(p g)b8(e+ nu)be8( a)he4  
r_h1_he3_wk_he4               ! he3(p e+nu)he4     

! cno cycles

rc12_to_n14         ! c12(p g)n13(e+nu)c13(p g)n14
rn14_to_c12         ! n14(p g)o15(e+nu)n15(p a)c12
rn14_to_o16         ! n14(p g)o15(e+nu)n15(p g)o16
ro16_to_n14         ! o16(p g)f17(e+nu)o17(p a)n14
```
+ `star/private/profile.f90`: add_eps_neu_rates = 0 add_eps_nuc_rates =0 add_screened_rates=0
    - The screen module calculates electron screening factors for thermonuclear reactions in both the weak and strong regime
+ `star_data/public/star_data_def.f90`: structure of `star_info`