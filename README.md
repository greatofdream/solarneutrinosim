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

## Code structure
+ `inlist_project`: soft link to `inlist_[model]_pms` and `inlist_[model]_zams` used for pms and zams simulation, created automatically by `Makefile`
  + Two stages (pms and zams) are recommended by [doc](https://docs.mesastar.org/en/stable/using_mesa/building_inlists.html#starting-model)
  + pms starts from a model with uniform composition

## Setting
+ Element data: By default, the initial composition in MESA is `initial_zfracs = 3` which corresponds to the GS98 metal fraction ([doc reference](https://docs.mesastar.org/en/24.08.1/using_mesa/building_inlists.html#initial-composition))
  + In the MESA-r24.08.1, MB22 is added with zfrac as 9. Therefore, there is no need to manually modified the MESA code. (see `star/defaults/star_job.defaults`)
  + In the MESA-r24.08.1, MB22 is added with opacity as `oplib_mb22`. (see `kap/defaults/kap.defaults`)
```fortran
! Example inlist: SSM model: ags09
initial_zfracs = 6
kappa_file_prefix = 'a09'
! Example inlist: SSM model: mb22
initial_zfracs = 9
kappa_file_prefix = 'oplib_mb22'
```
+ Opacity setting: `kap`
  + `Zbase`: Zbase is typically only used for Type2 opacities which operate deeper in the stellar interior. [Physically, this usually corresponds to the initial metallicity of the star](https://docs.mesastar.org/en/stable/kap/overview.html#radiative-opacities) [and remains static during the entirety of a calculation. Variations in metallicity from nuclear burning and mixing should not alter Zbase as its purpose is to serve as a reference metallicity for C and O enhancement during Helium burning.](https://docs.mesastar.org/en/stable/kap/defaults.html#zbase)
+ Model initial: default load the zams model, for pms simulation the initial parameters are set as following:
  + `initial_mass`: 1 sun mass
  + `initial_z`, `initial_y`: refer from MB22 paper.
+ [convection control](https://docs.mesastar.org/en/latest/using_mesa/building_inlists.html#convection-and-convective-boundaries): It seems that mesa-r23.05.1 add the option controlling the convection.
+ mesh control: `star_data_def.inc`

## Running
+ compile: `./mk`
+ simulation: `make`

# Software Requirement
[Mesa Doc](https://docs.mesastar.org/en/release-r22.05.1/using_mesa/running.html)
[2020 school](https://cococubed.com/mesa_summer_school_2020/index.html)
[Instrument paper](https://arxiv.org/abs/1903.01426)
[Mail list](https://lists.mesastar.org/mailman/listinfo/mesa-users)

# Appendix
## MESA setting control
+ `initial_z`: to set the metals fractions, initial metallicity for create pre-ms and create initial model.
    - `star_job.defaults`,select one of the options defined in `$MESA_DIR/chem/public/chem_def.f90`
    - `$MESA_DIR/star/private/adjust_xyz.f90`: `case (0) ! use non-standard values given in controls`
    - invoked by `$MESA_DIR/star/job/run_star_support.f90`
+ `history_columns.list`: column meaning
+ `star/defaults/controls.defaults`: control meaning
+ [rewrite the function](https://docs.mesastar.org/en/release-r22.05.1/using_mesa/extending_mesa.html?highlight=run_star_extras#using-the-other-hooks)
+ difference between `z_initial` and `chem_def` is used for set metalicity fraction
+ need recompile the project (`./mk`) after update the MESA


## MB22 support
+ `mesa-r22.05.1` does not contain MB22, need manually add the MB22 support in code
  + add option and metal abundance value in `$MESA_DIR/chem/public/chem_def.f90` (example: `resources/r22.05.1/chem_def.f90`)
+ `mesa-r23.05.1` does not contain MB22, need manually add the MB22 support in setting file
  + support set `initial_zfracs=0` in the `inlist` file for custom zfrac setting without modified the code.
+ `mesa-r24.08.1` contains MB22, include [kap](https://docs.mesastar.org/en/24.08.1/changelog.html#kap)

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
