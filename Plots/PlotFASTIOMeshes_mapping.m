function [Mesh1_I,Mesh1_O,Mesh2_I,Mesh2_O, f1, MotionMap, LoadMap] ...
    = PlotFASTIOMeshes_mapping( MeshInputFile )

%% -----------------
% Read file:


    [fid, message] = fopen( MeshInputFile );
    if fid < 1
        error(['PlotFASTIOMeshes:: Error opening file: ' MeshInputFile '. ' message]);
    end
    Mesh1_Input  = fid;
    Mesh1_Output = fid;
    Mesh2_Input  = fid;
    Mesh2_Output = fid;
        
    
   % DO NOT REORDER THESE READ STATEMENTS!!!! 
Mesh1_I = ReadFASTmesh(Mesh1_Input);
Mesh1_O = ReadFASTmesh(Mesh1_Output); %data not needed for Only2 plots (but used in the output list)

Mesh2_I = ReadFASTmesh(Mesh2_Input);
Mesh2_O = ReadFASTmesh(Mesh2_Output); %data not needed for Only1 plots (but used in the output list)

Mesh1_I_1pt = ReadFASTmesh(fid);
Mesh2_O_1pt = ReadFASTmesh(fid);
Mesh1_O_1PT = ReadFASTmesh(fid);

[MotionMap] = ReadFASTmappingData(fid);
[~, LoadMap, Mesh2_O_aug, Mesh2_O_lump, Mesh1_I_lump] = ReadFASTmappingData(fid);
[~, Mesh1LoadMap,Mesh1LoadAug, Mesh2_O_lump,] = ReadFASTmappingData(fid);
[~, Mesh2LoadMap,Mesh2_O_aug, Mesh2_O_lump,] = ReadFASTmappingData(fid);

%% -----------------
% plot motions mapping (Dest nodes from Src nodes):

Mesh2PlotOffset  = [0,0,0]'; %[30,0,0]';

Mesh2_I.Position = Mesh2_I.Position + repmat(Mesh2PlotOffset,1,Mesh2_I.Nnodes);
Mesh2_O.Position = Mesh2_O.Position + repmat(Mesh2PlotOffset,1,Mesh2_O.Nnodes);


RefColor1     = [0,0,0];
RefColor2     = [1,1,1]*.5;
RefColor2_aug = [.5,0,.5];

ScaleSize = 1;

f1=figure;
subplot(1,1,1)
hold on;
title('Motion mapping (Mesh1 to Mesh 2)')

DrawMesh(Mesh1_O, RefColor1, ScaleSize );
DrawMesh(Mesh2_I, RefColor2, ScaleSize );
DrawMapping(Mesh1_O.Position,Mesh2_I.Position,MotionMap);
axis equal;


%% -----------------
% plot loads mapping (Src nodes to Dest nodes):
f2=figure;
subplot(1,1,1)
hold on;
title('Loads mapping (Mesh2 to Mesh 1)')

DrawMesh(Mesh1_I, RefColor1, ScaleSize );
DrawMesh(Mesh2_O, RefColor2, ScaleSize );
if ~isempty(Mesh2_O_aug) && Mesh2_O_aug.Nnodes > 0 
    Mesh2_O_aug.Position = Mesh2_O_aug.Position + repmat(Mesh2PlotOffset,1,Mesh2_O_aug.Nnodes);
    DrawMesh(Mesh2_O_aug, RefColor2_aug, ScaleSize );    
    DrawMapping(Mesh2_O_aug.Position,Mesh1_I.Position,LoadMap);   
else
    DrawMapping(Mesh2_O.Position,Mesh1_I.Position,LoadMap);
end
axis equal;
   


return;
end % function

function DrawMapping(SrcPos,DestPos,mapping)
    MarkerColor = 'r';
    
    for j=1:size(mapping,2)
        for i=1:size(mapping,1)            
            if mapping(i,j) > 0 
                
                Field = DestPos(:,j) - SrcPos(:,i);
                
                quiver3( SrcPos(1,i),      SrcPos(2,i),      SrcPos(3,i),...
                          Field(1),        Field(2),         Field(3),...
                         0, ...        %no automatic scaling
                        'linewidth',1.5, 'MaxHeadSize',0.25,'AutoScale','Off','color',MarkerColor, ...
                        'DisplayName', ['Mapping src(' num2str(i) ') to dest(' num2str(j) ')'] );                           
            end
        end        
    end
    
    
return
end
