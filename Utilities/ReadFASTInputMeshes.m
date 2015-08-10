function [Mesh] = ReadFASTInputMeshes(fileName,plotMeshes)
%%
%     fileName = ...
%       ['C:\Users\bjonkman\Documents\DATA\DesignCodes\simulators\FAST\SVNdirectory\branches\BJonkman\CertTest\' ...
%        'Test21_InputMeshes.bin'];


%% read the file:

    [fid, message] = fopen( fileName );
    if fid < 1
        error(['ReadFASTInputMeshes:: Error opening file: ' fileName '. ' message]);
    end

    File_ID = fread( fid, 1, 'int32');
    
    if File_ID ~= 2 && File_ID ~= 1 && File_ID ~= 3
        error(['Invalid File_ID in ' fileName '. Unknown file format.']);
    end
    
    
    numBl   = fread( fid, 1, 'int32');          
          
    for k = 1:numBl
      Mesh.ED_Blade(k) = ReadFASTmesh(fid);
    end
    Mesh.ED_Tower           = ReadFASTmesh(fid);
    Mesh.ED_Platform        = ReadFASTmesh(fid);
    Mesh.SD_TransitionPiece = ReadFASTmesh(fid);
    Mesh.SD_L               = ReadFASTmesh(fid);
    Mesh.HD_Morison_Distrib = ReadFASTmesh(fid);
    Mesh.HD_Morison_Lumped  = ReadFASTmesh(fid);
    Mesh.HD_WAMIT           = ReadFASTmesh(fid);
    Mesh.MAP_Fairlead       = ReadFASTmesh(fid);

    if File_ID > 1
        numBl2   = fread( fid, 1, 'int32');          
        for k = 1:numBl2
            Mesh.BD_RootMotion(k)= ReadFASTmesh(fid);
            Mesh.BD_DistrLoad(k) = ReadFASTmesh(fid);
        end
    else
        numBl2 = 0;
    end 

    if File_ID > 2
        numBl3   = fread( fid, 1, 'int32');          
        for k = 1:numBl3
            Mesh.AD_BladeMotion(k)= ReadFASTmesh(fid);
        end
    else
        numBl3 = 0;
    end 
        
    fclose( fid );
   
%% plot meshes:
    if nargin > 1 && plotMeshes
        NumMeshes= numBl+8+numBl2*2+numBl3;
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
        MeshName{   numBl+4}='SD_L';

        MarkerColor{numBl+5}=[0.001, 1.000, 1.000];
        MeshName{   numBl+5}='HD_Morison_Distrib';

        MarkerColor{numBl+6}=[1.000, 0.001, 1.000];
        MeshName{   numBl+6}='HD_Morison_Lumped';

        MarkerColor{numBl+7}=[0.501, 1.000, 0.001];
        MeshName{   numBl+7}='HD_WAMIT';

        MarkerColor{numBl+8}=[0.001, 1.000, 0.501];
        MeshName{   numBl+8}='MAP_Fairlead';

        k = 0;
        for j = 1:numBl2
          k = k + 1;
          MarkerColor{numBl+8+k} = [.1,0,.1]*j;
          MeshName{   numBl+8+k} = ['BD_RootMotion(' num2str(j) ')'];
          
          k = k + 1;          
          MarkerColor{numBl+8+k} = [.1,.1,0]*j;
          MeshName{   numBl+8+k} = ['BD_DistrLoad(' num2str(j) ')'];
        end    
        

        for j = 1:numBl3
          k = numBl + 8 + 2*numBl2 + j;
          MarkerColor{k} = [.1,0,.1]*j;
          MeshName{   k} = ['AD_BladeMotion(' num2str(j) ')'];          
        end    
        
        
        LineColors=lines(NumMeshes);

    %     fid = fopen( fileName );
    %     File_ID = fread( fid, 1, 'int32');
    %     numBl   = fread( fid, 1, 'int32');

        %%          
        f=figure;
        currlimits=[0 0 0;
                    1 1 1];


        for i=1:NumMeshes % (numBl+1):NumMeshes
            MeshData = eval(['Mesh.' MeshName{i} ';']);

            if MeshData.Nnodes > 0

                figure(f);
                subplot(1,1,1);

                for k=1:2
                    hold on;
                    subplot(1,1,1);

                    DrawMesh( MeshData, LineColors(i,:), '', MeshName{i} );

                    axis equal;
                    camproj('perspective') 
                    theseLimits=[xlim' ylim' zlim'];

                    currlimits(1,:) = min( currlimits(1,:), theseLimits(1,:) );
                    currlimits(2,:) = max( currlimits(2,:), theseLimits(2,:) );

                    if k == 1
                        fig(i) = figure;
                        isfig(i) = 1;
                    end

        %             subplot(1,NumMeshes,i);
                end        
            else
                isfig(i) = -1;
            end

        end
    %     fclose(fid)

        for i=1:NumMeshes
            if isfig(i) > 0
                figure(fig(i));
                xlim(currlimits(:,1))
                ylim(currlimits(:,2))
                zlim(currlimits(:,3))
                title(strrep(MeshName{i},'_','\_'))
            end
        end

        figure(f)
        xlim(currlimits(:,1))
        ylim(currlimits(:,2))
        zlim(currlimits(:,3))   
        title( {'All meshes from', fileName},'interpreter','none');

    end
    
end
