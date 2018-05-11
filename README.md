# MBC
*A MATLAB®-based postprocessor for Multi-Blade Coordinate transformation of wind turbine state-space models*

## by Gungit Bir, NREL

MBC is a set of MatLab scripts that performs multi-blade coordinate transformation (MBC) on wind turbine system models.
The dynamics of wind turbine rotor blades are conventionally expressed in rotating frames attached to the individual blades.
The tower-nacelle subsystem sees the combined effect of all rotor blades, not the individual blades. This is because the rotor
responds as a whole to excitations such as aerodynamic gusts, control inputs, and tower-nacelle motion—all of which occur in a
 nonrotating frame. MBC helps integrate the dynamics of individual blades and express them in a fixed (nonrotating) frame.

MBC is mandatory to controls and stability analyses—erroneous predictions can result otherwise. A novel feature of this MBC code
is that it can handle variable-speed operation and turbines with dissimilar blades. Depending on the analysis objective, a user
may generate system models either in the first-order (state-space) form or the second-order (physical-domain) form. MBC3 can
handle both types of system models. Key advantages of MBC are: capturing cumulative dynamics of the rotor blades and its interaction
with the tower-nacelle subsystem, well-conditioning of system matrices by eliminating non-essential periodicity, and filtering operation.

## Usage
The MBC scripts were updated to functions and modified to deal with some changes in OpenFAST linearizaton for BeamDyn. The old scripts have been moved 
to the `Source\old` directory. The new functions can be called with
```
[mbc_data, matData, FAST_linData] = fx_mbc3( FileNames )
```
where the returned data structures are:
- `mbc_data`:  the MBC3-transformed data
- `matData`: the data from calling fx_getMats
- `FAST_linData`: the raw data stored in the OpenFAST linearization files

After the MBC3 transformation, the `campbell_diagram_data` function can be called to help analyze modes:
`[CampbellData] = campbell_diagram_data(mbc_data, BladeLen, TowerLen, xlsFileName)`

Note that the blade and tower lengths are inputs to this function. Also, if the optional `xlsFileName` is used, the CampbellData is written to an Excel 
file, which can be useful for analyzing the results.
