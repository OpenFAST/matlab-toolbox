function [out, f1] = PlotFASTIOMeshes_mapping( MeshInputFile )


%% -----------------
% Read file:

    out.fileName = MeshInputFile;

    [fid, message] = fopen( MeshInputFile );
    if fid < 1
        error(['PlotFASTIOMeshes:: Error opening file: ' MeshInputFile '. ' message]);
    end
    Mesh1_Input  = fid;
    Mesh1_Output = fid;
    Mesh2_Input  = fid;
    Mesh2_Output = fid;
        
    
   % DO NOT REORDER THESE READ STATEMENTS!!!! 
out.Mesh1_LoadInput = ReadFASTmesh(Mesh1_Input);
out.Mesh1_MotionOutput = ReadFASTmesh(Mesh1_Output); %data not needed for Only2 plots (but used in the output list)

out.Mesh2_MotionInput = ReadFASTmesh(Mesh2_Input);
out.Mesh2_LoadOutput = ReadFASTmesh(Mesh2_Output); %data not needed for Only1 plots (but used in the output list)


out.Mesh1_I_1pt = ReadFASTmesh(fid);
out.Mesh2_O_1pt = ReadFASTmesh(fid);
out.Mesh1_O_1PT = ReadFASTmesh(fid);


[out.MotionMap] = ReadFASTmappingData(fid);
[~, out.LoadMap, out.Mesh2_LoadOutput_aug, out.Mesh2_LoadOutput_lump, out.Mesh1_LoadInput_lump] = ReadFASTmappingData(fid);

%% not sure I care about this
[~, out.Mesh1_I_1pt_LoadMap, out.Mesh1_I_1pt_aug, out.Mesh1_I_1pt_lumpSrc, out.Mesh1_I_1pt_lumpDest] = ReadFASTmappingData(fid);
[~, out.Mesh2_O_1pt_LoadMap, out.Mesh2_O_1pt_aug, out.Mesh2_O_1pt_lumpSrc, out.Mesh2_O_1pt_lumpDest] = ReadFASTmappingData(fid);

%% -----------------
% plot motions mapping (Dest nodes from Src nodes):

Mesh2PlotOffset  = [0,0,0]'; %[30,0,0]';

out.Mesh2_MotionInput.Position = out.Mesh2_MotionInput.Position + repmat(Mesh2PlotOffset,1,out.Mesh2_MotionInput.Nnodes);
out.Mesh2_LoadOutput.Position  = out.Mesh2_LoadOutput.Position  + repmat(Mesh2PlotOffset,1,out.Mesh2_LoadOutput.Nnodes );


RefColor1     = [0,0,0];
RefColor2     = [1,1,1]*.5;
RefColor2_aug = [.5,0,.5];

ScaleSize = 1;

f1=figure;
subplot(1,1,1)
hold on;
title('Motion mapping (Mesh 1 to Mesh 2)')

DrawMesh(out.Mesh1_MotionOutput, RefColor1, ScaleSize );
DrawMesh(out.Mesh2_MotionInput,  RefColor2, ScaleSize );
DrawMapping(out.Mesh1_MotionOutput.Position,  out.Mesh2_MotionInput.Position,  out.MotionMap);
axis equal;


%% -----------------
% plot loads mapping (Src nodes to Dest nodes):
f2=figure;
subplot(1,1,1)
hold on;
title('Loads mapping (Mesh 2 to Mesh 1)')

DrawMesh(out.Mesh1_LoadInput,  RefColor1, ScaleSize );
DrawMesh(out.Mesh2_LoadOutput, RefColor2, ScaleSize );
if ~isempty(out.Mesh2_LoadOutput_aug) && out.Mesh2_LoadOutput_aug.Nnodes > 0 
    out.Mesh2_LoadOutput_aug.Position = out.Mesh2_LoadOutput_aug.Position + repmat(Mesh2PlotOffset,1,out.Mesh2_LoadOutput_aug.Nnodes);
    DrawMesh(out.Mesh2_LoadOutput_aug, RefColor2_aug, ScaleSize );    
    DrawMapping(out.Mesh2_LoadOutput_aug.Position,   out.Mesh1_LoadInput.Position,  out.LoadMap);   
else
    DrawMapping(out.Mesh2_LoadOutput.Position,   out.Mesh1_LoadInput.Position,  out.LoadMap);
end
axis equal;
   


return;
end % function

function DrawMapping(SrcPos,DestPos,mapping)
    MarkerColor = 'r';
    if size(mapping,2) ~= size(DestPos,2)
        disp('wrong destination sizes!')
        size(mapping)
        size(DestPos)
        return
    end
    if size(mapping,1) ~= size(SrcPos,2)
        disp('wrong source sizes!')
        size(mapping)
        size(SrcPos)
        return
    end
    
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
