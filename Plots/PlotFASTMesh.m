function PlotFASTMesh( MeshFileName, figure_id, MarkerColor )
%
%
Mesh = ReadFASTmesh(MeshFileName);

if nargin < 2
    figure_id = figure;
    MarkerColor = 'c';
end

FieldNames = {'RefOrientation','Orientation','TranslationDisp',...
              'TranslationVel','RotationVel',...
              'TranslationAcc','RotationAcc',...
              'Force','Moment','Scalars' };
 
npr = 2;
npc = 5;

%% Plot each field
for iField = 1:length(FieldNames)
    
    if isfield(Mesh,FieldNames{iField})    
        
        subplot(npr,npc,iField)
        hold on;
        PlotField( Mesh, FieldNames{iField}, MarkerColor, 0.5);
        
        ConnectElements(Mesh);
        
        view(3)
        axis equal;
%         axis vis3d ;
        camproj('perspective') 
        title( FieldNames{iField} )

%         set(gca,'CameraPosition', cam_position,  ...
%                 'CameraTarget',   cam_target , ...
%                 'CameraViewAngle',cam_angle  );
        
    end
end

return;
end % function


function PlotField( Mesh, FieldName, MarkerColor, CoordSize)

    FieldValues = eval( ['Mesh.' FieldName] );
    
    [s1, s2, s3] = size(FieldValues);
    
    if( strcmpi(FieldName,'Orientation') || strcmpi(FieldName,'RefOrientation') )
        for iNode = 1:Mesh.Nnodes
            origin  = repmat(Mesh.Position(:,iNode),1,3);  %the origin of 3 vectors
            Field   = FieldValues(:,:,iNode);

                %multiply Field by CoordSize to make vectors a certain
                %length in meters:
            Field = Field*CoordSize;
            
            quiver3( origin(1,:),      origin(2,:),      origin(3,:),...
                      Field(1,:),       Field(2,:),       Field(3,:),...
                     0, ...        %no automatic scaling
                    'linewidth',2, 'MaxHeadSize',0.5,'AutoScale','Off','color',MarkerColor, ...
                    'DisplayName', [FieldName ', node ' num2str(iNode)] );                                    
            
        end % iNode

    else
        origin = Mesh.Position; 

            %multiply Field by CoordSize to make vectors a certain length
            %in meters:
        Field = FieldValues*CoordSize;
                                      
            quiver3( origin(1,:),      origin(2,:),      origin(3,:),...
                      Field(1,:),       Field(2,:),       Field(3,:),...
                     0, ...        %no automatic scaling
                    'linewidth',2, 'MaxHeadSize',0.5,'AutoScale','Off','color',MarkerColor, ...
                    'DisplayName', FieldName );                                    
                
        if strcmpi(FieldName,'Moment') % create two arrows for the moment
            % because I can't figure out how to make a better arrow (with 2
            % heads or 2 lines), I'm going to draw two arrows for the
            % moments:
            Field2 = Field*0.9;          
            
            quiver3( origin(1,:),      origin(2,:),      origin(3,:),...
                     Field2(1,:),      Field2(2,:),      Field2(3,:),...
                     0, ...        %no automatic scaling
                    'linewidth',3, 'MaxHeadSize',0.45,'AutoScale','Off','color',MarkerColor, ...
                    'DisplayName', FieldName );                                    
        end
                
    end
return;
end

function ConnectElements(Mesh)
%bjj: this works only for line2 elements

    for i = 1:Mesh.NElemList
        
        for n=2:length(Mesh.Element(i).Nodes)
            nodes = [ Mesh.Element(i).Nodes(n-1), Mesh.Element(i).Nodes(n) ];
            plot3(Mesh.Position(1,nodes), Mesh.Position(2,nodes), Mesh.Position(3,nodes),...
                  'Color',[1,1,1]*.25 ) ;
        end        
    end

    return;
 end
    
 

