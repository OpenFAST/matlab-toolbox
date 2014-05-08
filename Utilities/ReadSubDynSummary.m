function [data] = ReadSubDynSummary(fileName)

fid   = fopen( fileName );

if ( fid <= 0 )
    error(['Could not open the summary file: ' fileName ]);
else

%     dataTypes = {' '};
%     
%     next_indx = 1;
%     n = length(dataTypes);
    
    
    
    while ( true )  
        line  = fgetl(fid);
        if ~ischar(line) % We reached the end of the file
            break;
        end
        line = upper(line);
                
        findx = strfind(line,'FEM EIGENVALUES [HZ]');
        if ~isempty(findx)
            findx = strfind(line,':')+1; %first index
            if isempty(findx)
                findx = 1;
            end
            n = str2double( strtok(line(findx:end))); %number of eigenvalues            
            data.FEM_eig =  fscanf(fid,'%*d %f',n);  
            fgetl(fid);
            continue;
        end        
        
        findx = strfind(line,'CB REDUCED EIGENVALUES [HZ]');
        if ~isempty(findx)
            findx = strfind(line,':')+1; %first index
            if isempty(findx)
                findx = 1;
            end
            n = str2double( strtok(line(findx:end))); %number of eigenvalues            
            data.CB_eig =  fscanf(fid,'%*d %f',n);           
            fgetl(fid);
            continue;
        end        
        
        findx = strfind(line,'KBBT');
        if ~isempty(findx)
            fgetl(fid);            
            fgetl(fid);
            data.KBBt = fscanf(fid,'%*s %f %f %f %f %f %f',[6,6]);
            data.KBBt = data.KBBt';
            fgetl(fid); %finish reading that line 

            fgetl(fid);          
            fgetl(fid);
            data.MBBt = fscanf(fid,'%*s %f %f %f %f %f %f',[6,6]);
            data.MBBt = data.MBBt';
            fgetl(fid); %finish reading that line 
            
            fgetl(fid);            
            fgetl(fid);
            fgetl(fid);
            data.MRB = fscanf(fid,'%*s %f %f %f %f %f %f',[6,6]);
            data.MRB = data.MRB';
            fgetl(fid); %finish reading that line 

            line=fgetl(fid);
            findx = strfind(line,'=')+1;
            data.Mass = str2double( strtok(line(findx:end)));
            
            line=fgetl(fid);
            findx = strfind(line,'=')+1;
            data.CM_coords = str2num( line(findx:end) );

            continue;
        end                            
        
    end    
                        
    
end

fclose(fid);

return
end

function [M] = readSDMatrix(fid)

return
end

