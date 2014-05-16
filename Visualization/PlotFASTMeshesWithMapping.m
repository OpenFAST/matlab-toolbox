function PlotFASTMeshesWithMapping( mesh_file )

dummy_fileName = -1;
ExportFigures  = false;


% [Mesh1_I,  Mesh1_O,  Mesh2_I,  Mesh2_O,  f1, MotionMap,   LoadMap ] = ...
    PlotFASTIOMeshes_mapping( mesh_file ) ;            
% [Mesh1_I,  Mesh1_O,  Mesh2_I,  Mesh2_O,  f1, MotionMap,   LoadMap ] = ...
    PlotFASTIOMeshes( mesh_file, dummy_fileName, dummy_fileName, dummy_fileName, ExportFigures );

end
