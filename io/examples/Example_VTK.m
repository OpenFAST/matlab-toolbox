%% Documentation   
% Examples to read various VTK files from OpenFAST
%
%% Initialization
clear all; close all; clc;
restoredefaultpath;
addpath(genpath('C:/Work/_libs/matlab-toolbox/'))

%% Parameters

%% Structured point, e.g. OLAF plane outputs or FAST.Farm plane outputs
% vtk = VTKRead('../../_ExampleData/ExampleFiles/VTK_StructuredPointsPointData.vtk');
vtk = VTKRead('../../data/example_files/VTK_VelocityPlane.vtk');
% - Extract field into individual components
u = vtk.point_data_grid.Velocity_x;
v = vtk.point_data_grid.Velocity_y;
w = vtk.point_data_grid.Velocity_z;
% - Plot a cross section
fig = figure();
if vtk.dimensions(3)==1
     contourf(squeeze(vtk.X), squeeze(vtk.Y), squeeze(u(:,:)));
    xlabel('x [m]')
    ylabel('y [m]')
elseif vtk.dimensions(2)==1
    contourf(squeeze(vtk.X), squeeze(vtk.Z), squeeze(u(1,:,:)));
    xlabel('x [m]')
    ylabel('z [m]')
elseif vtk.dimensions(1)==1
    contourf(squeeze(vtk.Y), squeeze(vtk.Z), squeeze(u(:,1,:))); % untested
    xlabel('y [m]')
    ylabel('z [m]')
end
colorbar();
title('Streamwise velocity in plane')



%% Polydata, e.g. OLAF Segments or Source Panels
vtkl = VTKRead('../../data/example_files/VTK_PolyData_Lines.vtk');
vtkp = VTKRead('../../data/example_files/VTK_PolyData_Polygons.vtk');


%% Rectilinear grid 
vtkr = VTKRead('../../data/example_files/VTK_RectilinearGrid.vtk');
