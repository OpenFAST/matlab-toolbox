function [Mesh] = ReadFASTMotionMeshes(fileName,plotMeshes)
%%
%     fileName = ...
%       ['C:\Users\bjonkman\Documents\DATA\DesignCodes\simulators\FAST\SVNdirectory\branches\BJonkman\CertTest\' ...
%        'Test21.gra'];

%%
if nargin < 2
    plotMeshes = false;
end

%% read the file and header:

    [fid, message] = fopen( fileName );
    if fid < 1
        error(['ReadFASTMotionMeshes:: Error opening file: ' fileName '. ' message]);
    end

    File_ID = fread( fid, 1, 'int32');
    
    if File_ID ~= 101
        error(['Invalid File_ID in ' fileName '. Unknown file format.']);
    end
        
    numBl_ED   = fread( fid, 1, 'int32');          
    numBl_BD   = fread( fid, 1, 'int32'); 
    
    if plotMeshes
        NumMeshes= numBl_ED+8+numBl_BD*2;
        [MeshName,MarkerColor,LineColors]=getMeshNames(NumMeshes,numBl_ED,numBl_BD);
        fig=figure;
        subplot(1,1,1);        
        
        writerObj = VideoWriter([fileName '.avi']);
        open(writerObj);
    end
    
%% ..... each time step

    [t,cnt] = fread( fid, 1, 'float64');          
    n = 0;
    while cnt == 1 && n < 18
        n = n + 1;
    
        for k = 1:numBl_ED
          Mesh.ED_Blade(k) = ReadFASTmesh(fid);
        end
        Mesh.ED_Tower           = ReadFASTmesh(fid);
        Mesh.ED_Platform        = ReadFASTmesh(fid);
        Mesh.SD_TransitionPiece = ReadFASTmesh(fid);
        Mesh.SD_y2              = ReadFASTmesh(fid);
        Mesh.HD_Morison_Distrib = ReadFASTmesh(fid);
        Mesh.HD_Morison_Lumped  = ReadFASTmesh(fid);
        Mesh.HD_Mesh            = ReadFASTmesh(fid);
        Mesh.MAP_Fairlead       = ReadFASTmesh(fid);
        
        for k = 1:numBl_BD
            Mesh.BD_RootMotion(k)= ReadFASTmesh(fid);
            Mesh.BD_BldMotion(k) = ReadFASTmesh(fid);
        end
        
        if plotMeshes
            clf;

            plotAllMeshes(Mesh,NumMeshes,MeshName,LineColors,t,fileName);
           
            xlim([-15,5]);
            ylim([-75,75]);
            zlim([-175,175]);
            frame = getframe(fig);
            writeVideo(writerObj,frame);            
        end
        
        [t,cnt] = fread( fid, 1, 'float64');        
    end 
    
    fclose( fid );
    if plotMeshes
        close(writerObj);
    end
return;
end
%% get some values for plotting
function [MeshName,MarkerColor,LineColors]=getMeshNames(NumMeshes,numBl,numBl_BD)

    MarkerColor=cell(NumMeshes,1);
    MeshName=cell(NumMeshes,1);
    for k = 1:numBl
      MarkerColor{k} = [.1,.1,.1]*k;
      MeshName{k} = ['ED_Blade(' num2str(k) ')'];
    end    

    MarkerColor{numBl+1}=[1.000, 0.001, 0.001];
    MeshName{   numBl+1}='ED_Tower';

    MarkerColor{numBl+2}=[0.001, 1.000, 0.001];
    MeshName{   numBl+2}='ED_Platform';

    MarkerColor{numBl+3}=[0.001, 0.001, 1.000];
    MeshName{   numBl+3}='SD_TransitionPiece';

    MarkerColor{numBl+4}=[1.000, 1.000, 0.001];
    MeshName{   numBl+4}='SD_y2';

    MarkerColor{numBl+5}=[0.001, 1.000, 1.000];
    MeshName{   numBl+5}='HD_Morison_Distrib';

    MarkerColor{numBl+6}=[1.000, 0.001, 1.000];
    MeshName{   numBl+6}='HD_Morison_Lumped';

    MarkerColor{numBl+7}=[0.501, 1.000, 0.001];
    MeshName{   numBl+7}='HD_Mesh';

    MarkerColor{numBl+8}=[0.001, 1.000, 0.501];
    MeshName{   numBl+8}='MAP_Fairlead';

    k = 0;
    for j = 1:numBl_BD
      k = k + 1;
      MarkerColor{numBl+8+k} = [.1,0,.1]*j;
      MeshName{   numBl+8+k} = ['BD_RootMotion(' num2str(j) ')'];

      k = k + 1;          
      MarkerColor{numBl+8+k} = [.1,.1,0]*j;
      MeshName{   numBl+8+k} = ['BD_BldMotion(' num2str(j) ')'];
    end    


    LineColors=lines(NumMeshes);
    return;
end
        
        

%% plot meshes:
function [] = plotAllMeshes(Mesh,NumMeshes,MeshName,LineColors,t,fileName)


        for i=1:NumMeshes % (numBl+1):NumMeshes
            MeshData = eval(['Mesh.' MeshName{i} ';']);
                % we're going to plot the displaced value

            if MeshData.Nnodes > 0
                MeshData.RefOrientation = MeshData.Orientation;
                MeshData.Position = MeshData.Position + MeshData.TranslationDisp;
                
                DrawMesh( MeshData, LineColors(i,:), '', MeshName{i} );
            end

        end
        axis equal;
        camproj('perspective') 
        
        title( {'All meshes from', fileName, ['t=', num2str(t) ' s']},'interpreter','none');
   
end
