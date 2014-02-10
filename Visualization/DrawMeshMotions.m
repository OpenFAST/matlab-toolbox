function DrawMeshMotions(Mesh, MarkerColor, CoordSize,DisplacedOnly )

    my_red    = [191, 48, 48]/256;
    my_orange = [255,146,  0]/256;
    my_purple = [ 57, 20,175]/256;
    my_blue   = [102,163,210]/256; 
    my_green  = [  0,204,  0]/256;
    my_pink   = [210, 53,210]/256;

    MarkerColor_TV = my_pink; %[0.0, 0.5, 0.5];   % Translational velocity 
    MarkerColor_RV = my_blue;   %[1.0, 0.0, 0.0];   % Rotational velocity
    MarkerColor_TA = my_green;                     % Translational acceleration 
    MarkerColor_RA = my_orange;                    % Rotational acceleration 

    if nargin < 4
        DisplacedOnly = false;
        if nargin < 3
            CoordSize = 1;
            if nargin < 2
                MarkerColor = [0.5,0.5,0.5]; %gray
            end
        end
    end
    
    
    %% draw the displaced orientation markers

    origin = Mesh.Position + Mesh.TranslationDisp;
    
    for iNode = 1:Mesh.Nnodes
%         Mesh.Position(:,iNode)
%         [iNode Mesh.TranslationDisp(:,iNode)']
        Field   = Mesh.Orientation(:,:,iNode)*CoordSize;  %multiply Field by CoordSize to make vectors a certain length in meters

        quiver3( repmat(origin(1,iNode),3,1),   repmat(origin(2,iNode),3,1),  repmat(origin(3,iNode),3,1),...
                  Field(:,1),                    Field(:,2),                   Field(:,3),...
                 0, ...        %no automatic scaling
                'linewidth',2, 'MaxHeadSize',0.5,'AutoScale','Off','color',MarkerColor, ...
                'DisplayName', [ 'Node ' num2str(iNode) ' displaced position/orientation' ] );                                                
    end % iNode
    
    
    %% connect the nodes to form (line2) elements     
    
    if Mesh.NElemList > 0 && length( Mesh.Element(1).Nodes) ==2
        DistributedValue = zeros(3,length(Mesh.Element(1).Nodes),Mesh.NElemList);
        for i = 1:Mesh.NElemList 
            for n=1:length(Mesh.Element(i).Nodes)
                node = Mesh.Element(i).Nodes(n);
                DistributedValue(:,n,i)  = origin(:,node);
            end        
        end          

        plot3(squeeze(DistributedValue(1,:,:)), squeeze(DistributedValue(2,:,:)), squeeze(DistributedValue(3,:,:)),...
            'Color',MarkerColor, 'LineWidth', 1.75,'DisplayName', 'Mesh element' ) ;
    end  

                
    if DisplacedOnly
        return
    else
        CoordSize=0.5;
    end
    

        
    
    %% Plot Rotational Acceleration    
    if isfield(Mesh,'RotationAcc')
        % because I can't figure out how to make a better arrow (with 2 heads
        % or 2 lines), I'm going to draw two arrows for the moments and RotationVel fields:

        Field   = [Mesh.RotationAcc*CoordSize, 0.9*Mesh.RotationAcc*CoordSize];  %multiply Field by CoordSize to make vectors a certain length in meters           
        quiver3( [origin(1,:),origin(1,:)], [origin(2,:),origin(2,:)], [origin(3,:),origin(3,:)],...
                  Field(1,:),                Field(2,:),               Field(3,:),...
                 0, ...        %no automatic scaling
                'linewidth',3, 'MaxHeadSize',0.45,'AutoScale','Off','color',MarkerColor_RA, ...
                'DisplayName', 'Rotational acceleration' );     
            
        hold on;
        axis equal;
        view(3);
                        
        % draw lines for distributed loads   (this works only for line2 elements)         
        if Mesh.NElemList > 0 && length( Mesh.Element(1).Nodes) ==2
            DistributedValue = zeros(3,length(Mesh.Element(1).Nodes),Mesh.NElemList);
                    
            for i = 1:Mesh.NElemList 
    %             NonZeroElem 
                for n=1:length(Mesh.Element(i).Nodes)
                    node = Mesh.Element(i).Nodes(n);
                    DistributedValue(:,n,i) = origin(:,node) + Field(:,node);
               end        
            end

            plot3(squeeze(DistributedValue(1,:,:)), squeeze(DistributedValue(2,:,:)), squeeze(DistributedValue(3,:,:)),...
                'Color',MarkerColor_RA, 'LineWidth', 1.75,'DisplayName', 'Rotational acceleration elements' ) ;

        end
            
    end        
    
    %% Plot Translational Acceleration
    if isfield(Mesh,'TranslationAcc')
        Field   = Mesh.TranslationAcc*CoordSize;  %multiply Field by CoordSize to make vectors a certain length in meters
        quiver3( origin(1,:),      origin(2,:),      origin(3,:),...
                  Field(1,:),       Field(2,:),       Field(3,:),...
                 0, ...        %no automatic scaling
                'linewidth',2, 'MaxHeadSize',0.5,'AutoScale','Off','color',MarkerColor_TA, ...
                'DisplayName', 'Translational acceleration' );   
        hold on;
        axis equal;
        view(3);
          
        % draw lines for distributed loads   (this works only for line2 elements)         
        if Mesh.NElemList > 0 && length( Mesh.Element(1).Nodes) ==2
            DistributedValue = zeros(3,length(Mesh.Element(1).Nodes),Mesh.NElemList);
            for i = 1:Mesh.NElemList 
                for n=1:length(Mesh.Element(i).Nodes)
                    node = Mesh.Element(i).Nodes(n);
                    DistributedValue(:,n,i)  = origin(:,node) + Field(:,node);
               end        
            end          
            
            plot3(squeeze(DistributedValue(1,:,:)), squeeze(DistributedValue(2,:,:)), squeeze(DistributedValue(3,:,:)),...
                'Color',MarkerColor_TA, 'LineWidth', 1.75,'DisplayName', 'Translational acceleration element' ) ;
        end          
    end
    
    
    %% Plot Rotational Velocity    
    if isfield(Mesh,'RotationVel')
        % because I can't figure out how to make a better arrow (with 2 heads
        % or 2 lines), I'm going to draw two arrows for the moments and RotationVel fields:

        Field   = [Mesh.RotationVel*CoordSize, 0.9*Mesh.RotationVel*CoordSize];  %multiply Field by CoordSize to make vectors a certain length in meters           
        quiver3( [origin(1,:),origin(1,:)], [origin(2,:),origin(2,:)], [origin(3,:),origin(3,:)],...
                  Field(1,:),                Field(2,:),               Field(3,:),...
                 0, ...        %no automatic scaling
                'linewidth',3, 'MaxHeadSize',0.45,'AutoScale','Off','color',MarkerColor_RV, ...
                'DisplayName', 'Rotational velocity' );     
            
        hold on;
        axis equal;
        view(3);
                        
        % draw lines for distributed loads   (this works only for line2 elements)         
        if Mesh.NElemList > 0 && length( Mesh.Element(1).Nodes) ==2
            DistributedValue = zeros(3,length(Mesh.Element(1).Nodes),Mesh.NElemList);
                    
            for i = 1:Mesh.NElemList 
    %             NonZeroElem 
                for n=1:length(Mesh.Element(i).Nodes)
                    node = Mesh.Element(i).Nodes(n);
                    DistributedValue(:,n,i) = origin(:,node) + Field(:,node);
               end        
            end

            plot3(squeeze(DistributedValue(1,:,:)), squeeze(DistributedValue(2,:,:)), squeeze(DistributedValue(3,:,:)),...
                'Color',MarkerColor_RV, 'LineWidth', 1.75,'DisplayName', 'Rotational velocity elements' ) ;

        end
            
    end        
    
    %% Plot Translational Velocity
    if isfield(Mesh,'TranslationVel')
        Field   = Mesh.TranslationVel*CoordSize;  %multiply Field by CoordSize to make vectors a certain length in meters
        quiver3( origin(1,:),      origin(2,:),      origin(3,:),...
                  Field(1,:),       Field(2,:),       Field(3,:),...
                 0, ...        %no automatic scaling
                'linewidth',2, 'MaxHeadSize',0.5,'AutoScale','Off','color',MarkerColor_TV, ...
                'DisplayName', 'Translational velocity' );   
        hold on;
        axis equal;
        view(3);
          
        % draw lines for distributed loads   (this works only for line2 elements)         
        if Mesh.NElemList > 0 && length( Mesh.Element(1).Nodes) ==2
            DistributedValue = zeros(3,length(Mesh.Element(1).Nodes),Mesh.NElemList);
            for i = 1:Mesh.NElemList 
                for n=1:length(Mesh.Element(i).Nodes)
                    node = Mesh.Element(i).Nodes(n);
                    DistributedValue(:,n,i)  = origin(:,node) + Field(:,node);
               end        
            end          
            
            plot3(squeeze(DistributedValue(1,:,:)), squeeze(DistributedValue(2,:,:)), squeeze(DistributedValue(3,:,:)),...
                'Color',MarkerColor_TV, 'LineWidth', 1.75,'DisplayName', 'Translational velocity element' ) ;
        end          
    end
        
    
    
return
 end
    