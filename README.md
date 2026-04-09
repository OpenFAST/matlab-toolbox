# MATLAB Toolbox for OpenFAST, including MBC3
A collection of MATLAB tools developed for use with OpenFAST, including
readers/writers (input/output), various utilities,
and a MATLAB®-based postprocessor for Multi-Blade Coordinate transformation of 
wind turbine state-space models.

## Download 
From a command line:
```
git clone https://github.com/OpenFAST/matlab-toolbox
```

## Install in MATLAB
From a MATLAB command window:

```
addpath( genpath('AbsolutePathToToolbox') )
```
where `AbsolutePathToToolbox` is the name of the absolute path where you cloned this toolbox. 
Adding this command to your MATLAB `startup.m` file will make sure these tools are avalible every time you
use MATLAB.


## Folders 

The scripts are organized in the following folders:
- `Campbell`: contains scripts to produce a Campbell diagram (work in progress, see [here](#campbell-diagram). 
- `ConvertFASTversions:` scripts to convert input files from different versions of OpenFAST (in particular FAST7 and FAST8, some scripts are not up to date for the latest OpenFAST)
- `data`: Data used to test the different scripts
- `FAST2MATLAB` and `MATLAB2FAST`: scripts to read and write FAST input files
- `io`: input-output scripts. (NOTE: a lot of input output scripts are still in `Utilities`)  (see [examples](io/examples/))
- `MBC`: scripts to perform the multi-blade coordinate  transformation (see [here](#MBC))
- `Plots`: plotting scripts
- `ProgrammingTools`: tools for OpenFAST developers
- `Utilities`: miscellaneous tools used in the library (see [examples](Utilities/examples/)).
- `math`: generic mathematical tools used in the library
- `_ExampleData`: data used in some examples (e.g. the Campbell Diagram example)


The content of some of these folders are described below.




## Campbell diagram

Tools to generate a Campbell diagram are provided in the `Campbell` folder. 
The scripts are operational but are still considered work in progress as they require the user to be quite familiar with OpenFAST and the linearization process. 

The mode identification is not fully automated, and the user will have to perform a manual modification of the XLS or CSV file ("Modes\_ID" tab or file).



The following example script is provided:
```
Campbell/examples/runCampbell.m
```
This script requires OpenFAST 2.3. 


Before additional documentation is provided, some answers may be found in the following link:

- [Issue 480 on Campbell diagram](https://github.com/OpenFAST/openfast/issues/480)



### Campbell diagram with trim option

The trim option has been introduced in the dev branch of OpenFAST in August 2020. Limited documentation and support is currently provided. 


The following example script is provided:
```
Campbell/examples/runCampbell_Trim.m
```
This script requires OpenFAST 2.3 dev (August 2020). 


Before additional documentation is provided, some answers may be found in the following links

- [Implementation plan for the Trim Option](https://github.com/ebranlard/temp-lin/blob/master/ForceSetPoint.pdf)

- [Pull request for Trim and Mode shape](https://github.com/OpenFAST/openfast/pull/373)

- [Issue 480 on Campbell diagram](https://github.com/OpenFAST/openfast/issues/480)





### Mode shapes visualization

Mode shape visualization has been introduced in the dev branch of OpenFAST in August 2020. Limited documentation and support is currently provided. 


The following example script is provided:
```
Campbell/examples/runCampbell_Trim.m
```
This script requires OpenFAST 2.3 dev (August 2020). 


Before additional documentation is provided, some answers may be found in the following links:

- [Pull request for Trim and Mode shape](https://github.com/OpenFAST/openfast/pull/373)

- [VTK visualization](https://github.com/OpenFAST/r-test/blob/dev/glue-codes/openfast/5MW_Land_ModeShapes/vtk-visualization.md): this describe the underlying steps to produce the visualization. These steps are not required when running the example scripts since these steps have been wrapped by some matlab function. Yet, it is still necessary to install paraview-python, and this documentation is useful to understand the process.

- [Issue 480 on Campbell diagram](https://github.com/OpenFAST/openfast/issues/480)





## MBC

MBC is a set of MATLAB scripts that performs multi-blade coordinate transformation (MBC) on wind turbine system models.
The dynamics of wind turbine rotor blades are conventionally expressed in rotating frames attached to the individual blades.
The tower-nacelle subsystem sees the combined effect of all rotor blades, not the individual blades. This is because the rotor
responds as a whole to excitations such as aerodynamic gusts, control inputs, and tower-nacelle motion—all of which occur in a
 nonrotating frame. MBC helps integrate the dynamics of individual blades and express them in a fixed (nonrotating) frame.

MBC is mandatory to controls and stability analyses—erroneous predictions can result otherwise. A novel feature of this MBC code
is that it can handle variable-speed operation and turbines with dissimilar blades. Depending on the analysis objective, a user
may generate system models either in the first-order (state-space) form or the second-order (physical-domain) form. MBC3 can
handle both types of system models. Key advantages of MBC are: capturing cumulative dynamics of the rotor blades and its interaction
with the tower-nacelle subsystem, well-conditioning of system matrices by eliminating non-essential periodicity, and filtering operation.

### MBC3 Usage
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
```
[CampbellData] = campbell_diagram_data(mbc_data, BladeLen, TowerLen, xlsFileName)
```

Note that the blade and tower lengths are inputs to this function. Also, if the optional `xlsFileName` is used, the CampbellData is written to an Excel 
file, which can be useful for analyzing the results.





## Utilities
Various utilities used by other scripts. Examples are:
- run OpenFAST simulations. 
- read OpenFAST input files 
- read OpenFAST output files

See [examples](Utilities/examples/)

