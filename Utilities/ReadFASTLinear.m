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
    ValuesFromFile = {'t'
              'RotSpeed'
              'Azimuth'
              'WindSpeed'
              'n_x'
              'n_xd'
              'n_z'
              'n_u'
              'n_y' };
    MissingWindSpeed = false; % add this for backward compatibility
    for i=1:length(ValuesFromFile)
        line = fgetl(fid);
        C = textscan( line, '%s', 'delimiter', ':' );
        try
            d = textscan( C{1}{2}, '%f', 'CollectOutput',1 );
            data.(ValuesFromFile{i}) = d{1};
        catch
            MissingWindSpeed = true;
        end
    end
    
    if MissingWindSpeed
        for i=length(ValuesFromFile):-1:5
            data.(ValuesFromFile{i}) = data.(ValuesFromFile{i-1}) ;
        end
        data = rmfield(data,'WindSpeed');
    else
        line = fgetl(fid);
    end
    
    data.n_x2     = 0;    
    data.Azimuth  = mod(data.Azimuth,2*pi);

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
        [data.x_op,    data.x_desc, data.x_rotFrame, data.x_DerivOrder] = readLinTable(fid,data.n_x);
        [data.xdot_op, data.xdot_desc]                                  = readLinTable(fid,data.n_x);
        if data.x_DerivOrder(1) == 0 % this is an older file without derivOrder columns
            data.x_DerivOrder(:) = 2; % (these are second-order states)
            data.n_x2 = data.n_x; 
        else
            data.n_x2 = sum(data.x_DerivOrder == 2); % (number of second-order states)
        end
    else
        data.n_x2 = 0;
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
            [M, name] = readFASTMatrix(fid);
            if ~ischar(name) 
                break;
            end
            data.(name) = M;
        end
    end
    
    fclose(fid);
return
end 

function [op, desc, RF, DerivOrd] = readLinTable(fid,n)

    desc = cell(n,1);
    op   = cell(n,1);
    RF   = false(n,1);
    DerivOrd = zeros(n,1);

    fgetl(fid); % table title/comment
    fgetl(fid); % table header row 1
    fgetl(fid); % table header row 2
    
    for row=1:n
        line = fgetl(fid);
        [C,pos] = textscan( line, '%*f %f %s %f',1 );
        if strcmp(C{2}(end),',') %we've got an orientation line (first string ends in comma instead of T/F):    
            [C,pos] = textscan( line, '%*f %f %*s %f %*s %f %s %f',1 );
            op{row} = [C{1:3}];
        else
            op{row} = C{1};
        end
        
        RF(row) = strcmp(C{end-1},'T');
        if isempty(C{end}) || isnan(C{end})
            DerivOrd(row) = 0; % older files don't have the DerivOrd column
        else
            DerivOrd(row) = C{end};
        end
            
        desc{row}=strtrim( line(pos+1:end) );
  
    end
    

    fgetl(fid); % skip a blank line
return
end
