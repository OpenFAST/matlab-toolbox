function data = VTKRead(filePath)
    % Read .VTK file and returns datasets stored in the file.
    % The following is supported:
    %    - Structured Points
    %    - Structured Grid
    %    - Rectilinear Grid
    %    - Polygonal Data
    %    - Unstructured Grid
    %
    % INPUTS:
    %  - filePath: string, File to read(Directory required)
    %
    % OUTPUTS:
    %  - data:  structure, containing header, description, file format, dataset structure information and associated attributes

    % check if the file exists
    if(~exist(filePath,'file'))
        error('Cannot open file %s.\nPlease double check the file''s name or its directory!',filePath);
    end

    % Declare and initialize output
    data={};

    % Suported datasets
    DATASET_TYPES={'structured_points', 'structured_grid', 'rectilinear_grid', 'polydata', 'unstructured_grid'};

    %% LOAD VTK DATA
    fid         = fopen(filePath,'r'); % open and read file
    Header      = fgetl(fid)      ; % Header - file version and identifier (i.e. "vtk DataFile Version x.x")
    Description = fgetl(fid)      ; % Title - 256 characters maximum used to describe the data information (teminated with '\n')
    FileFormat  = fgetl(fid)      ; % Data file format ("ASCII" or "BINARY")

    %% DETECT DATASET TYPE
    lineID=3;                                  % already read line id
    datasetType=0;                             % initialize dataset type ('0' as unidentified)

    while(~feof(fid))                       % loop over lines to read dataset type
        dataStr = fgetl(fid); % get a new line in the file
        lineID  = lineID+1  ; % update the line id 
        if(containString(lower(dataStr), 'dataset')) % check if the new line contains the keyword "dataset"

            % split this line and pack up into a cell that contains separated
            % strings
            splittedData=strsplit(dataStr,' ');
            
            % remove empty elements
            splittedData=splittedData(~cellfun('isempty',splittedData));
            % get the dataset type (the string right after the keyword "dataset")
            loadedDataType=splittedData{2};
            
            % check if the type is defined in the dictionary
            idx = find(strcmp(DATASET_TYPES, lower(loadedDataType)));
            if(~isempty(idx))
                % confirm dataset type defined in the dictionary
                datasetType = idx;
                break;
            else
                fclose(fid);
                error('%s is not a defined dataset type in a .vtk file! (Line: %d)', loadedDataType, lineID);
            end        
        end
    end

    %% LOAD TOPOLOGY BASED ON DATASET TYPE AND FILL IN ASSOCIATED ATTRIBUTES
    switch datasetType
        case 1
            [fid, geom] = read_structured_points(fid);        
        case 2
            [fid, geom] = read_structured_grid(fid);
        case 3
            [fid, geom] = read_rectilinear_grid(fid);
        case 4
            [fid, geom] = read_polydata(fid);
        case 5
            [fid, geom] = read_unstructured_grid(fid);
        otherwise
            fclose(fid);
            error('Dataset type not found!, Supported types: %s', strjoin(DATASET_TYPES, ', '));
    end
    DatasetType = DATASET_TYPES(datasetType);
    %% Adding useful Geometry info for grids.
    if isfield(geom, 'xp_grid') && isfield(geom, 'yp_grid') && isfield(geom, 'zp_grid')
        [X, Y, Z] = meshgrid(geom.xp_grid, geom.yp_grid, geom.zp_grid);
        geom.X = X;
        geom.Y = Y;
        geom.Z = Z;
    end

    %% LOAD DATASET ATTRIBUTES
    Attributes = read_dataset_attributes(fid, geom);

    %% STORE in output struct
    data.filename    = filePath;
    data.header      = Header   ;
    data.description = Description         ;
    data.fileformat  = FileFormat       ;
    % Merge Geometry and Attribute fields into the output structure
    mergestructs = @(x,y) cell2struct([struct2cell(x);struct2cell(y)],[fieldnames(x);fieldnames(y)]);
    data = mergestructs( data, geom);
    data = mergestructs( data, Attributes);

    fclose(fid);
end

% --------------------------------------------------------------------------------
%% ---  FUNCTIONS THAT READ TOPOLOGY INFORMATION OF DIFFERENT TYPES OF DATASETS
% --------------------------------------------------------------------------------
function [fid, geom]=read_structured_points(fid)
    % Read structured points
    % structure keywords of dataset structured points
    STRUCTURED_POINTS_KEYWORDS={'dimensions', 'origin', 'spacing'};
    KEYWORDS = STRUCTURED_POINTS_KEYWORDS;
    % get the number of keywords
    nKeywords=numel(KEYWORDS);
    % flag array that reflects if all keywords are loaded
    flagsAllRead=zeros(1,nKeywords);

    % Output
    geom = struct();

    while(~feof(fid))
        % read one line
        dataStr=fgetl(fid);

        % pack up a cell that contains strings from this line
        splittedData=strsplit(dataStr,' ');
        splittedData=splittedData(~cellfun('isempty',splittedData));

        % if the cell is empty, a blank line is encountered 
        if(isempty(splittedData))
            continue;
        end
        % look for information of dataset structure
        loadedAttributeName=splittedData{1};
        flag=strcmpi(STRUCTURED_POINTS_KEYWORDS,loadedAttributeName);
        % record encountered keyword.
        if(any(flag))
            attrData=[];
            idx=flag==true;
            for iData=2:numel(splittedData)        
                attrData=cat(1,attrData,str2double(splittedData{iData}));
            end
            % Store
            geom.(STRUCTURED_POINTS_KEYWORDS{idx}) = attrData;
            flagsAllRead(idx)=1;
        end
        
        % if all keywords are loaded, break out the while loop, otherwise, go
        % to the next loop to read a new line until all keywords are filled in.
        if(all(flagsAllRead))
            break;
        end

    end

    % missing some keyword
    if(~all(flagsAllRead))
        fclose(fid);
        error('EOF! Missing geometry/topology information defined.\nFound:    %s\nExpected: %s ', strjoin(STRUCTURED_POINTS_KEYWORDS(flagsAllRead==1),', '),strjoin(STRUCTURED_POINTS_KEYWORDS,', '));
    end
    % Dataset specific:
    geom.xp_grid = geom.origin(1) + linspace(0, geom.spacing(1)*(geom.dimensions(1)-1), geom.dimensions(1));
    if numel(geom.spacing)>1
        geom.yp_grid = geom.origin(2) + linspace(0, geom.spacing(2)*(geom.dimensions(2)-1), geom.dimensions(2));
    end
    if numel(geom.spacing)>2
        geom.zp_grid = geom.origin(3) + linspace(0, geom.spacing(3)*(geom.dimensions(3)-1), geom.dimensions(3));
    end
end

function [fid, geom]=read_structured_grid(fid)
    % read structured grid
    STRUCTURED_GRID_KEYWORDS={'dimensions', 'points'};
    KEYWORDS = STRUCTURED_GRID_KEYWORDS;
    nKeywords=numel(KEYWORDS);
    flagsAllRead=zeros(1, nKeywords);

    geom = struct();
    dimensions=[];
    while(~feof(fid))

        dataStr=fgetl(fid);
        splittedData=strsplit(dataStr,' ');
        splittedData=splittedData(~cellfun('isempty',splittedData));
        if(isempty(splittedData))
            continue;
        end
        loadedAttributeName=splittedData{1};
        flag=strcmpi(KEYWORDS, loadedAttributeName);
        
        if(any(flag))
            idx=find(flag==true);
            switch(idx)
                case 1
                    for iData=2:numel(splittedData)
                        dimensions=cat(1,dimensions,str2double(splittedData{iData}));                    
                    end     
                case 2
                    nPoints  = str2double(splittedData{2});
                    DataType = splittedData{3}            ;
                    num = fscanf(fid,'%f');
                    Points=reshape(num,[3 nPoints]);
            end

            flagsAllRead(idx)=1;

        end

        if(all(flagsAllRead))
            break;
        end

    end

    if(~all(flagsAllRead))
        fclose(fid);
        error('EOF! Missing geometry/topology information defined.\nFound:    %s\nExpected: %s ', strjoin(KEYWORDS(flagsAllRead==1),', '), strjoin(KEYWORDS,', '));
    end

    geom.DatasetType = 'structured_grid';
    geom.Dimensions  = dimensions       ;
    geom.Points      = Points           ;
    geom.DataType    = DataType         ;
end % read structured grid

function [fid,geom]=read_rectilinear_grid(fid)
    % read rectilinear grid
    RECTILINEAR_GRID_KEYWORDS={'dimensions','x_coordinates','y_coordinates','z_coordinates'};
    KEYWORDS = RECTILINEAR_GRID_KEYWORDS;
    nKeywords    = numel(KEYWORDS)   ;
    flagsAllRead = zeros(1,nKeywords);
    geom = struct();
    DataTypes=cell(1,3);
    dimensions=[];
    xp_grid = [];
    yp_grid = [];
    zp_grid = [];
    idx = -1;
    while(~feof(fid))
        dataStr=fgetl(fid);
        splittedData=strsplit(dataStr,' ');
        splittedData=splittedData(~cellfun('isempty',splittedData));
        if(isempty(splittedData))
            continue;
        end
        loadedAttributeName=splittedData{1};
        flag=strcmpi(KEYWORDS,loadedAttributeName);
        if(any(flag))
            idx=find(flag==true);
            flagsAllRead(idx)=1;
            if(1==idx) % Dimensions
                for iData=2:numel(splittedData)
                    dimensions=cat(1,dimensions,str2double(splittedData{iData}));
                end
            else
                DataTypes{idx-1}=splittedData{3};
                switch idx                 
                    case 2
                        xp_grid = fscanf(fid,'%f');
                    case 3
                        yp_grid = fscanf(fid,'%f');
                    case 4
                        zp_grid = fscanf(fid,'%f');
                end
            end
        end
        if(all(flagsAllRead))
            if length(zp_grid)==dimensions(3)
                break;
            end
        end
    end
    if(~all(flagsAllRead))
        fclose(fid);
        error('EOF! Missing geometry/topology information defined.\nFound:    %s\nExpected: %s ', strjoin(KEYWORDS(flagsAllRead==1),', '),strjoin(KEYWORDS,', '));
    end
    geom.DatasetType = 'structured_grid';
    geom.dimensions  = dimensions       ;
    geom.xp_grid     = xp_grid             ;
    geom.yp_grid     = yp_grid             ;
    geom.zp_grid     = zp_grid             ;
end % read rectilinear grid

function [fid, unstructuredGrid]=read_unstructured_grid(fid)
    % read unstructured grid
    UNSTRUCTURED_GRID_KEYWORDS={'points', 'cells', 'cell_types'};
    KEYWORDS = UNSTRUCTURED_GRID_KEYWORDS;
    nKeywords=numel(KEYWORDS);
    flagsAllRead=zeros(1,nKeywords);
    Points=[];
    while(~feof(fid))

        dataStr=fgetl(fid);

        splittedData=strsplit(dataStr,' ');
        splittedData=splittedData(~cellfun('isempty',splittedData));

        if(isempty(splittedData))
            continue;
        end
        
        loadedAttributeName=splittedData{1};
        %pause
        flag=strcmpi(KEYWORDS,loadedAttributeName);
        %flag
        if(any(flag))
            
            idx=find(flag==true);
            
            % TODO OPTIMIZE THIS
            switch(idx)
                case 1
                    nPoints=str2double(splittedData{2});
                    DataType=splittedData{3};
                    data=[];
                    iPoint=0;
                    while(iPoint<nPoints)
                        dataStr=fgetl(fid);
                        splittedData=strsplit(dataStr,' ');
                        splittedData=splittedData(~cellfun('isempty',splittedData));
                        data=cat(2,data,str2double(splittedData));
                        iPoint=numel(data)/3;
                    end
                    Points=reshape(data,[3 nPoints]);
                case 2
                    nCells=str2double(splittedData{2});
                    CellListSize=str2double(splittedData{3});
                    CellPointsNum=zeros(1,nCells);
                    CellPointsIndices=cell(1,nCells);

                    for iCell=1:nCells
                        dataStr=fgetl(fid);
                        splittedData=strsplit(dataStr,' ');
                        splittedData=splittedData(~cellfun('isempty',splittedData));

                        temp=str2double(splittedData);
                        CellPointsNum(iCell)=temp(1);
                        CellPointsIndices{iCell}=temp(2:end);                 
                    end

                case 3

                    nCells=str2double(splittedData{2});
                    CellTypes=zeros(1,nCells);
                    for iCell=1:nCells
                        dataStr=fgetl(fid);
                        splittedData=strsplit(dataStr,' ');
                        splittedData=splittedData(~cellfun('isempty',splittedData));
                        CellTypes(iCell)=str2double(splittedData);                    
                    end
                    
            end
            flagsAllRead(idx)=1;
        end

        if(all(flagsAllRead))
            break;
        end

    end

    %flagsAllRead
    if(~all(flagsAllRead))
        fclose(fid);
        error('EOF! Missing geometry/topology information defined.\nFound:    %s\nExpected: %s ', strjoin(KEYWORDS(flagsAllRead==1),', '),strjoin(KEYWORDS,', '));
    end

    unstructuredGrid.DatasetType="unstructured_grid";
    unstructuredGrid.PointsNumber=nPoints;
    unstructuredGrid.Points=Points;
    unstructuredGrid.DataType=DataType;
    unstructuredGrid.CellConnectivityIndices=CellPointsIndices;
    unstructuredGrid.CellListSize=CellListSize;
    unstructuredGrid.CellPointsNumbers=CellPointsNum;
end % read unstructured grid

function [fid,polydata] = read_polydata(fid)
    % read polydata
    POLYDATA_KEYWORDS   = {'points','vertices','lines','polygons','triangle_stripes'};
    ATTRIBUTES_KEYWORDS = {'point_data','cell_data'}                                 ;

    Points=[];
    % Vertices
    nVertices=0;
    VerticesListSize=0;
    VerticesPointsNum=[];
    VerticesIndices=[];

    % Lines
    nLines=0;
    LinesListSize=0;
    LinesPointsNum=[];
    LinesIndices=[];

    % Polygons
    nPolygons=0;
    PolygonsListSize=0;
    PolygonsPointsNum=[];
    PolygonsIndices=[];

    % Triangle strips
    nTriangleStrips=0;
    TriangleStripsListSize=0;
    TriangleStripsPointsNum=[];
    TriangleStripsIndices=[];

    while(~feof(fid))
        offset=ftell(fid);
        dataStr=fgetl(fid);
        splittedData=strsplit(dataStr,' ');
        splittedData=splittedData(~cellfun('isempty',splittedData));
        
        if(isempty(splittedData))
            continue;
        end

        if(any(strcmpi(ATTRIBUTES_KEYWORDS,splittedData{1})))
            fseek(fid,offset,'bof');
            break;
        end

        loadedAttributeName=splittedData{1};
        flag=strcmpi(POLYDATA_KEYWORDS,loadedAttributeName);
        
        if(any(flag))
            
            idx=find(flag==true);
            
            if(1==idx)
                % --- Reading points
                nPoints  = str2double(splittedData{2});
                DataType = splittedData{3}            ;
                num = fscanf(fid,'%f');
                Points = reshape(num, [3, nPoints])';
            else

                nPrimitives=str2double(splittedData{2});
                PrimitivesListSize=str2double(splittedData{3});
                PrimitivesPointsNum=zeros(1,nPrimitives);
                PrimitivesPointsIndices=cell(1,nPrimitives);

                % TODO Optimize
                for iPrimitives=1:nPrimitives
                    dataStr=fgetl(fid);
                    splittedData=strsplit(dataStr,' ');
                    splittedData=splittedData(~cellfun('isempty',splittedData));
                    data=str2double(splittedData);
                    PrimitivesPointsNum(iPrimitives)=data(1);
                    PrimitivesPointsIndices{iPrimitives}=data(2:end);                    
                end

                switch(idx)
                    case 2
                        nVertices=nVertices+nPrimitives;
                        VerticesListSize=VerticesListSize+PrimitivesListSize;
                        VerticesPointsNum=cat(2,VerticesPointsNum,PrimitivesPointsNum);
                        VerticesIndices=cat(2,VerticesIndices,PrimitivesPointsIndices);
                    case 3
                        nLines=nLines+nPrimitives;
                        LinesListSize=LinesListSize+PrimitivesListSize;
                        LinesPointsNum=cat(2,LinesPointsNum,PrimitivesPointsNum);
                        LinesIndices=cat(2,LinesIndices,PrimitivesPointsIndices);
                    case 4
                        nPolygons=nPolygons+nPrimitives;
                        PolygonsListSize=PolygonsListSize+PrimitivesListSize;
                        PolygonsPointsNum=cat(2,PolygonsPointsNum,PrimitivesPointsNum);
                        PolygonsIndices=cat(2,PolygonsIndices,PrimitivesPointsIndices);
                    case 5
                        nTriangleStrips=nTriangleStrips+nPrimitives;
                        TriangleStripsListSize=TriangleStripsListSize+PrimitivesListSize;
                        TriangleStripsPointsNum=cat(2,TriangleStripsPointsNum,PrimitivesPointsNum);
                        TriangleStripsIndices=cat(2,TriangleStripsIndices,PrimitivesPointsIndices);
                end
            end
        end
    end

    polydata.DatasetType='polydata';

    if(0~=nPoints)
        polydata.points = Points;
        %polydata.Points.DataType=DataType;
    end

    if(0~=nVertices)
        polydata.vertices.Number        = nVertices        ;
        polydata.vertices.PointsIndices = VerticesIndices  ;
        polydata.vertices.Size          = VerticesListSize ;
        polydata.vertices.CellsNumber   = VerticesPointsNum;
    end

    if(0~=nLines)
        polydata.lines.Number        = nLines        ;
        polydata.lines.PointsIndices = LinesIndices  ;
        polydata.lines.Size          = LinesListSize ;
        polydata.lines.CellsNumber   = LinesPointsNum;
    end

    if(0~=nPolygons)
        polydata.polygons.Number        = nPolygons        ;
        polydata.polygons.PointsIndices = PolygonsIndices  ;
        polydata.polygons.Size          = PolygonsListSize ;
        polydata.polygons.CellsNumber   = PolygonsPointsNum;
    end

    if(0~=nTriangleStrips)
        polydata.triangleStrips.Number        = nTriangleStrips        ;
        polydata.triangleStrips.PointsIndices = TriangleStripsIndices  ;
        polydata.triangleStrips.Size          = TriangleStripsListSize ;
        polydata.triangleStrips.CellsNumber   = TriangleStripsPointsNum;
    end
end % read polydata

function [ATTRIBUTES] = read_dataset_attributes(fid, geom)
    % read dataset attributes, point_data or cell_data
    ATTRIBUTES={};
    nPoints          = 0;
    nCells           = 0;
    nLookupTables    = 0;
    currentAttribute = 0;
    tableSize        = 0;
    ID_POINT_DATA = 1;
    ID_CELL_DATA = 2;

    POINTS_DATA     = struct();
    CELLS_DATA      = struct();
    point_data_grid = struct(); % Duplicate of data, but quite convenient

    while(~feof(fid))
        dataStr=fgetl(fid);
        splittedData=strsplit(dataStr,' ');
        splittedData=splittedData(~cellfun('isempty',splittedData));
        if(isempty(splittedData))
            continue;
        end
        loadedFirstWord = lower(splittedData{1});

        if isequal(loadedFirstWord, 'point_data')
            nPoints=str2double(splittedData{2});
            currentAttribute=ID_POINT_DATA;
            tableSize=nPoints;
            continue;

        elseif isequal(loadedFirstWord, 'cell_data')
            nCells=str2double(splittedData{2});
            currentAttribute=ID_CELL_DATA;
            tableSize=nCells;
            continue;

        elseif isequal(loadedFirstWord, 'scalars') % --- SCALARS
            nLookupTables=0;
            Name     = splittedData{2}       ;
            DataType = splittedData{3}       ;
            Name     = replace(Name,'/', '_');

            % --- Deal with lookup table  TODO
            [dataStr,allgood,wrds, iRead] = ReadTillNotEmpty(fid);
            splittedData=strsplit(dataStr,' ');
            splittedData=splittedData(~cellfun('isempty',splittedData));
            nLookupTables=nLookupTables+1;
            if(length(splittedData)>=2)
                tableName=splittedData{2};
            else
                tableName='default';
            end
            if ~isequal(lower(tableName), 'default')
                error('>>> Cannot handle none default lookup table for now.')
            end
            % --- Read scalar field
            num = fscanf(fid,'%f');
            data = num(:)';
            if currentAttribute==ID_POINT_DATA
                POINTS_DATA.(Name) = data;
                if isfield(geom, 'dimensions')
                    data = permute(reshape(data, [geom.dimensions(1), geom.dimensions(2), geom.dimensions(3)]), [2,1,3]);
                    point_data_grid.(Name) = data;
                end
            else
                CELLS_DATA.(Name) = data;
            end
        elseif isequal(loadedFirstWord, 'lookup_table')
            error('>>> lookup table poorly handled for now')

        elseif isequal(loadedFirstWord, 'vectors') % --- VECTORS
            Name     = splittedData{2};
            DataType = splittedData{3};
            Name     = replace(Name,'/', '_');
            tempVector=[];
            num = fscanf(fid,'%f');
            data = reshape(num,[3 tableSize])';

            if currentAttribute==ID_POINT_DATA
                POINTS_DATA.(Name) = data;
                % PointVectorDataType% TODO potentially do something with the datatype here.
                if isfield(geom, 'dimensions')
                    VX = permute(reshape(data(:,1), [geom.dimensions(1), geom.dimensions(2), geom.dimensions(3)]), [2,1,3]);
                    VY = permute(reshape(data(:,2), [geom.dimensions(1), geom.dimensions(2), geom.dimensions(3)]), [2,1,3]);
                    VZ = permute(reshape(data(:,3), [geom.dimensions(1), geom.dimensions(2), geom.dimensions(3)]), [2,1,3]);
                    point_data_grid.([Name,'_x']) = VX;
                    point_data_grid.([Name,'_y']) = VY;
                    point_data_grid.([Name,'_z']) = VZ;
                end
            else
                CELLS_DATA.(Name) = data;
            end
        end
        continue;
    end

    if(0~=nPoints)
        ATTRIBUTES.point_data      = POINTS_DATA    ;
        ATTRIBUTES.point_data_grid = point_data_grid;
    end

    if(0~=nCells)
        ATTRIBUTES.cell_data=CELLS_DATA;
    end
end % read dataset attributes


function [ln, allgood, wrds, i] = ReadTillNotEmpty(fid)
    MAX_READ=1000000;
    i=0;
    bNOEOF=true;
    while i<MAX_READ
        if ~feof(fid)
            i=i+1;
            % reading lines and extracting words
            ln=fgetl(fid);
            %fprintf('ln={%s}\n',ln);
            if ~isempty(ln)
                wrds=textscan(ln,'%s','ReturnOnError',true);
                if ~isempty(wrds{1})
                    wrds=wrds{1};
                    break
                end
            end
        else
            wrds={};
            ln='';
            bNOEOF=false;
            break
        end
    end
    allgood=(i~=MAX_READ)&&bNOEOF; % return true if did not reach max value
end
