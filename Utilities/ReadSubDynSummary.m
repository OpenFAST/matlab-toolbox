function [data] = ReadSubDynSummary(fileName)
% [data] = ReadSubDynSummary(fileName)
% fileName is the SubDyn summary file to read
% data is a data structure containing the values from the summary file

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
                
        findx = strfind(line,'NUMBER OF NODES (NNODES)');
        if ~isempty(findx)            
            fgetl(fid);
            fgetl(fid);
            
            nodeTable = readSDMatrix(fid,line, 5);
            data.Node_coords = nodeTable(:,3:5);
            data.MeshNode = nodeTable(:,2);
            continue;
        end
        
        findx = strfind(line,'FEM EIGENVALUES [HZ]');
        if ~isempty(findx)
            findx = strfind(line,':'); %first index
            if isempty(findx)
                findx = 1;
            end
            n = str2double( strtok(line(findx(1)+1:end))); %number of eigenvalues            
            data.FEM_eig =  fscanf(fid,'%*d %f',n);  
            fgetl(fid);
            continue;
        end        
        
        findx = strfind(line,'CB REDUCED EIGENVALUES [HZ]');
        if ~isempty(findx)
            findx = strfind(line,':'); %first index
            if isempty(findx)
                findx = 1;
            end
            n = str2double( strtok(line(findx(1)+1:end))); %number of eigenvalues            
            data.CB_eig =  fscanf(fid,'%*d %f',n);           
            fgetl(fid); %finish reading that line
            continue;
        end
        
        findx = strfind(line,'FEM EIGENVECTORS');
        if ~isempty(findx)
            findx = strfind(line,'('); %first index
            if isempty(findx)
                findx = 1;
            end
            nr=str2double( strtok(line(findx(1)+1:end)) );
            data.FEM_eigVec = readSDMatrix_withHdrs(fid,nr);
            continue;
        end        
        
        findx = strfind(line,'PHIM:');
        if ~isempty(findx)
            data.PhiM = readSDMatrix(fid,line);
            continue;
        end        

        findx = strfind(line,'PHIR:');
        if ~isempty(findx)
            data.PhiR = readSDMatrix(fid,line);
            continue;
        end        
        
        
        findx = strfind(line,'KBBT AND MBBT');
        if ~isempty(findx) 
            fgetl(fid);          
            fgetl(fid);
            data.KBBt = readSDMatrix_withHdrs(fid,6);            

            fgetl(fid);          
            fgetl(fid);
            data.MBBt = readSDMatrix_withHdrs(fid,6);            
            
            fgetl(fid);            
            fgetl(fid);
            fgetl(fid);
            fgetl(fid);
            data.MRB = readSDMatrix_withHdrs(fid,6);            

            fgetl(fid);
            line=fgetl(fid);
            findx = strfind(line,'=')+1;
            data.Mass = str2double( strtok(line(findx:end)));
            
            line=fgetl(fid);
            findx = strfind(line,'=')+1;
            data.CM_coords = str2num( line(findx:end) ); %returns 3 values (x,y,z)

            continue;
        end                            
        
        
        findx = strfind(line,'FULL FEM K AND M MATRICES');
        if ~isempty(findx)
            findx=strfind(line,':');
            nr=str2double( strtok(line(findx(1)+1:end)) );
            
            fgetl(fid);
            data.K = readSDMatrix_withHdrs(fid,nr);
            fgetl(fid);
            fgetl(fid);
            data.M = readSDMatrix_withHdrs(fid,nr);            
        end        
        
    end    
                        
    
end

fclose(fid);

return
end

function [M] = readSDMatrix(fid,lastLine, nc)

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

function [M] = readSDMatrix_withHdrs(fid,nr)

    line   = fgetl(fid);
    colHdr = textscan(line,'%s');
    nc     = length( colHdr{1} );
    
    M =  fscanf(fid,['%*s ' repmat('%f',1,nc)],[nc,nr]); 
    
    M = M';
    fgetl(fid); %finish reading that line 
           
return
end




