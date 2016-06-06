function [Mesh] = ReadFASTmesh(FileID)
%[Mesh] = ReadFASTmesh(FileID)
% Author: Bonnie Jonkman, National Renewable Energy Laboratory
% (c) 2013, National Renewable Energy Laboratory
%
%
% Input:
%  FileID        - either:
%                   (1) integer: contains file identifier to file opened
%                           for reading binary
%                   (2) string: contains name of file to open
%
% Output:
%  Mesh          - data structure with mesh information
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%

if isnumeric(FileID)
    fid = FileID;
    if fid < 1
        error('ReadFASTmesh:: FileID must be an identifier connected to an open file or a vaild file name.');
    end
    closeFile = false;
else
    FileName = FileID;
    [fid, message] = fopen( FileName );
    if fid < 1
        error(['ReadFASTmesh:: Error opening file: ' FileName '. ' message]);
    end
    closeFile = true;
end

%% -----------------------------------------------------------------

ReKi = fread( fid, 1, 'int32');
if (ReKi == 4)
    nbits = 'float32';
elseif (ReKi == 8)
    nbits = 'float64';
else
    disp(['undefined nbits/ReKi = ' num2str(ReKi)])
    nbits = 'float64';
end 
    
fieldmask_size = fread( fid, 1, 'int32');    
fieldmask_int = fread(fid,fieldmask_size,'int32');
fieldmask  = fieldmask_int~=0; % convert to logical values

Mesh.Nnodes             = fread( fid, 1, 'int32'); 
Mesh.NElemList          = fread( fid, 1, 'int32'); 
Mesh.Position           = reshape( fread( fid,   3*Mesh.Nnodes, nbits     ),    3, Mesh.Nnodes ); 
Mesh.RefOrientation     = reshape( fread( fid, 3*3*Mesh.Nnodes, 'float64' ), 3, 3, Mesh.Nnodes ); 


%%
% Mesh.tmpVec = fread(fid,inf,nbits);
% return;

if fieldmask(1)
    Mesh.Force          = fread( fid,   [3, Mesh.Nnodes], nbits ); 
end 
if fieldmask(2)   
    Mesh.Moment         = fread( fid,   [3, Mesh.Nnodes], nbits ) ;
end 
if fieldmask(3)
    tmp = fread( fid,   [9, Mesh.Nnodes], 'float64' );    
    Mesh.Orientation    = reshape( tmp, 3, 3, Mesh.Nnodes ); 
end     
if fieldmask(4)
    Mesh.TranslationDisp= fread( fid,   [3, Mesh.Nnodes], 'float64' ); 
end     
if fieldmask(5)
    Mesh.TranslationVel = fread( fid,   [3, Mesh.Nnodes], nbits );
end     
if fieldmask(6)
    Mesh.RotationVel    = fread( fid,   [3, Mesh.Nnodes], nbits ); 
end     
if fieldmask(7)
    Mesh.TranslationAcc = fread( fid,   [3, Mesh.Nnodes], nbits );
end 
    
if fieldmask(8)
    Mesh.RotationAcc    = fread( fid,   [3, Mesh.Nnodes], nbits );
end

if fieldmask(9)
    Mesh.Scalars        = fread( fid,   [3, Mesh.Nnodes], nbits );
end

if Mesh.NElemList > 0
    Mesh.Element(Mesh.NElemList,1).Xelement = 0;
    for i = 1:Mesh.NElemList
        Mesh.Element(i).Xelement = fread( fid, 1,         'int32');
        ElemNodes                = fread( fid, 1,         'int32');
        Mesh.Element(i).Nodes    = fread( fid, ElemNodes, 'int32');

    end
end

%% -----------------------------------------------------------------
if (closeFile)
    fclose(fid);
end

return;

