function DrawMesh(Mesh, MarkerColor, CoordSize, MeshDesc )

    if nargin < 2
        MarkerColor = [.001,.001,.001]; %black
        CoordSize = 1;
        MeshDesc = '';
    elseif nargin < 3
        CoordSize = 1;
        MeshDesc = '';
    elseif nargin < 4
        MeshDesc = '';
    end

    if isempty(CoordSize)
        CoordSize = 1;
    end
    
    if length(MeshDesc) > 1
        MeshDesc = [ MeshDesc ' ' ];
    end
    
    %% draw the reference orientation markers
    hold on;
%     xlabel('X (m)');
%     ylabel('Y (m)');
%     zlabel('Z (m)');
    xlabel('X');
    ylabel('Y');
    zlabel('Z');
    view(3);
    grid on;
    
            
    for iNode = 1:Mesh.Nnodes
        origin  = Mesh.Position(:,iNode);  %the (x,y,z) origin of 3 vectors
        Field   = Mesh.RefOrientation(:,:,iNode)*CoordSize;  %multiply Field by CoordSize to make vectors a certain length in meters
        
        quiver3( repmat(origin(1),3,1),   repmat(origin(2),3,1),  repmat(origin(3),3,1),...
                  Field(:,1),             Field(:,2),             Field(:,3),...
                 0, ...        %no automatic scaling
                'linewidth',2, 'MaxHeadSize',0.5,'AutoScale','Off','color',MarkerColor, ...
                'DisplayName', [ MeshDesc 'Node ' num2str(iNode) ' reference position/orientation' ] );   
    end % iNode

    
    %% connect the nodes to form elements     
%bjj: this works only for line2 elements
    
    if isnumeric( MarkerColor )
        LineColor = MarkerColor*.5;
    else
        LineColor = MarkerColor;
    end
    LineColor = [1,1,1]*.0025;

    for i = 1:Mesh.NElemList        
        for n=2:length(Mesh.Element(i).Nodes)
            nodes = [ Mesh.Element(i).Nodes(n-1), Mesh.Element(i).Nodes(n) ];
            plot3(Mesh.Position(1,nodes), Mesh.Position(2,nodes), Mesh.Position(3,nodes),...
                  'Color',LineColor, 'LineWidth', 1.75 ) ;
        end        
    end
    
    
    return;
 end
    