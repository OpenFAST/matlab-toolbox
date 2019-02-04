function [data] = ReadBeamDynSummary(fileName)

fid   = fopen( fileName );

if ( fid <= 0 )
    error(['Could not open the summary file: ' fileName ]);
else    
   
    while ( true )  
        line  = fgetl(fid);
        if ~ischar(line) % We reached the end of the file
            break;
        end
        line = upper(line);
                
        findx = strfind(line,'FULL STIFFNESS MATRIX');
        if ~isempty(findx)            
            data.K = readMatrix(fid,line);
            
            if (isempty(strfind(line,'IEC COORDINATES')))
                data.K = convertBD2IEC(data.K);
            end
            continue;
        end
       
        findx = strfind(line,'FULL MASS MATRIX');
        if ~isempty(findx)            
            data.M = readMatrix(fid,line);
            
            if (isempty(strfind(line,'IEC COORDINATES')))
                data.M = convertBD2IEC(data.M);
            end
            continue;
        end
        
    end %while   
                        
    
end

fclose(fid);

return
end    
    
function [M] = readMatrix(fid, lastLine, nc)

    findx = strfind(lastLine,':');
    dummy=textscan( lastLine(findx(1)+1:end), '%f %*s %f', 2 );
    
    nr=dummy{1};
    if ~isempty(dummy{2})
        nc=dummy{2};
    elseif nargin < 3
        nc = 1;
    end
    
    M = fscanf(fid, '%f',[nc,nr]); 
    M = M';
    fgetl(fid); %finish reading that line     
    
return
end

function [IEC] = convertBD2IEC(BD)
    nc=size(BD,1);
   
    T = [0,1,0;
         0,0,1;
         1,0,0];
             
    T_full = zeros(nc,nc);
    for n=1:3:nc
        T_full(n:(n+2),n:(n+2)) = T;
    end
    
    IEC = T_full * BD * T_full';

return
end