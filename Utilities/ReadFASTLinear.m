function [data] = ReadFASTLinear(fileName)

    fid=fopen(fileName);
    if (fid == -1)
        error(['Linearization file "',fileName,'" could not be opened.']);
    end

    % generic header:
                    fgetl(fid); % skip a blank line
    data.ver{1,1} = fgetl(fid); % FAST version info 
    data.ver{2,1} = fgetl(fid); % submodule version info
                    fgetl(fid); % skip a blank line
    data.desc     = fgetl(fid); % model description
                    fgetl(fid); % skip a blank line
                    fgetl(fid); % "simulation information" comment/header line
                  
    % parse the next few lines:
    d = cell(8,1);
    for i=1:length(d)
        line = fgetl(fid);
        C = textscan( line, '%s', 'delimiter', ':' );
        d{i} = textscan( C{1}{2}, '%f', 'CollectOutput',1 );
    end
    
    data.t        = d{1}{1};
    data.RotSpeed = d{2}{1};
    data.Azimuth  = d{3}{1};
    data.n_x      = d{4}{1};
    data.n_xd     = d{5}{1};
    data.n_z      = d{6}{1};
    data.n_u      = d{7}{1};
    data.n_y      = d{8}{1};
            

    line = fgetl(fid);
    C = textscan( line, '%s', 'delimiter', '?' );
    if strfind( C{1}{2}, 'Yes' )
        SetOfMatrices = 2;
    else
        SetOfMatrices = 1;
    end         
    
    
    fgetl(fid); % skip a blank line
    %% ...........................................
    % get operating points and row/column order
    if data.n_x > 0 
        [data.x_op,    data.x_desc, data.x_rotFrame] = readLinTable(fid,data.n_x);
        [data.xdot_op, data.xdot_desc]               = readLinTable(fid,data.n_x);
    end

    if data.n_xd > 0 
        [data.xd_op,   data.xd_desc]                 = readLinTable(fid,data.n_xd);
    end
    if data.n_z > 0 
        [data.z_op,    data.z_desc]                  = readLinTable(fid,data.n_z);
    end
    if data.n_u > 0 
        [data.u_op,    data.u_desc, data.u_rotFrame] = readLinTable(fid,data.n_u);
    end
    if data.n_y > 0 
        [data.y_op,    data.y_desc, data.y_rotFrame] = readLinTable(fid,data.n_y);
    end
    
    
    fgetl(fid); % skip a blank line
    for i=1:SetOfMatrices
        %% ...........................................
        % get linearized state matrices
        fgetl(fid); % skip linearized state matrices or jacobian description line
        fgetl(fid); % skip a blank line

        while true
            [M, name] = readMatrix(fid);
            if ~ischar(name) 
                break;
            end
            data.(name) = M;
        end
    end
    
    fclose(fid);
return
end 

function [op, desc, RF] = readLinTable(fid,n)

    desc = cell(n,1);
    op   = cell(n,1);
    RF   = false(n,1);

    fgetl(fid); % table title/comment
    fgetl(fid); % table header row 1
    fgetl(fid); % table header row 2
    
    for row=1:n
        
        line = fgetl(fid);
        [C,pos] = textscan( line, '%*f %f %s',1 );
        if strcmp(line(pos),',') %we've got an orientation line:
            [C,pos] = textscan( line, '%*f %f %*s %f %*s %f %s',1 );
            op{row} = [C{1:3}];
        else
            op{row} = C{1};
        end
        RF(row) = strcmp(C{end},'T'); 
        desc{row}=strtrim( line(pos+1:end) );        
    end

    fgetl(fid); % skip a blank line
return
end

function [Mat, name] = readMatrix(fid)

    line = fgetl(fid);
    if ischar(line) && ~isempty(line)
        C = textscan( line, '%s', 'delimiter', ':' );
        name = C{1}{1};

        C = textscan( C{1}{2}, '%f %*s %f' );
        m=C{1};
        n=C{2};

        Mat = cell2mat( textscan(fid, repmat('%f',1,n),m,'CollectOutput',1) );
        fgetl(fid); %read end-of-line character(s)
    else
        name = -1;
        Mat = [];
    end
return
end
