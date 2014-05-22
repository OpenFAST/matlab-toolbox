function DrawMeshLoads(Mesh, MotionMesh, CoordSize )

    MarkerColor_F = [0,.5,.5];   % Force color
    MarkerColor_M = [1,0,0];     % Moment color

    if nargin < 3
       CoordSize = 1;
    end

    
    %% draw the force and moments in the displaced positions 
    origin  = Mesh.Position + MotionMesh.TranslationDisp;

    %% Force
    if isfield(Mesh,'Force')
        Field   = Mesh.Force*CoordSize(1);  %multiply Field by CoordSize to make vectors a certain length in meters
        quiver3( origin(1,:),      origin(2,:),      origin(3,:),...
                  Field(1,:),       Field(2,:),       Field(3,:),...
                 0, ...        %no automatic scaling
                'linewidth',2, 'MaxHeadSize',0.5,'AutoScale','Off','color',MarkerColor_F, ...
                'DisplayName', 'Forces' );   
        hold on;
        axis equal;
        view(3);
          
        % draw lines for distributed loads   (this works only for line2 elements)         
        if Mesh.NElemList > 0 && length( Mesh.Element(1).Nodes) ==2
            DistributedForce = zeros(3,length(Mesh.Element(1).Nodes),Mesh.NElemList);
            for i = 1:Mesh.NElemList 
                for n=1:length(Mesh.Element(i).Nodes)
                    node = Mesh.Element(i).Nodes(n);
                    DistributedForce(:,n,i)  = origin(:,node) + Field(:,node);
               end        
            end          
            
            plot3(squeeze(DistributedForce(1,:,:)), squeeze(DistributedForce(2,:,:)), squeeze(DistributedForce(3,:,:)),...
                'Color',MarkerColor_F, 'LineWidth', 1.75,'DisplayName', 'Distributed forces' ) ;
        end          
    end
    
    %% Moment    
    if isfield(Mesh,'Moment')
        % because I can't figure out how to make a better arrow (with 2 heads
        % or 2 lines), I'm going to draw two arrows for the moments:
        
        if length(CoordSize) > 1 % allow different scaling for moments
            CoordSize = CoordSize(2);
        end
        
        Field   = [Mesh.Moment*CoordSize, 0.9*Mesh.Moment*CoordSize];  %multiply Field by CoordSize to make vectors a certain length in meters           
        quiver3( [origin(1,:),origin(1,:)], [origin(2,:),origin(2,:)], [origin(3,:),origin(3,:)],...
                  Field(1,:),                Field(2,:),               Field(3,:),...
                 0, ...        %no automatic scaling
                'linewidth',3, 'MaxHeadSize',0.45,'AutoScale','Off','color',MarkerColor_M, ...
                'DisplayName', 'Moments' );     
            
        hold on;
        axis equal;
        view(3);
                        
        % draw lines for distributed loads   (this works only for line2 elements)         
        if Mesh.NElemList > 0 && length( Mesh.Element(1).Nodes) ==2
            DistributedMoment = zeros(3,length(Mesh.Element(1).Nodes),Mesh.NElemList);
                    
            for i = 1:Mesh.NElemList 
    %             NonZeroElem 
                for n=1:length(Mesh.Element(i).Nodes)
                    node = Mesh.Element(i).Nodes(n);
                    DistributedMoment(:,n,i) = origin(:,node) + Field(:,node);
               end        
            end

            plot3(squeeze(DistributedMoment(1,:,:)), squeeze(DistributedMoment(2,:,:)), squeeze(DistributedMoment(3,:,:)),...
                'Color',MarkerColor_M, 'LineWidth', 1.75,'DisplayName', 'Distributed moments' ) ;

        end
            
    end
        
    return;
 end
    