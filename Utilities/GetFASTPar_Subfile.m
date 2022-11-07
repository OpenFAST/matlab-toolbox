function [p, newSubfileName,err1] = GetFASTPar_Subfile(FP, VarName, oldDir, newDir, readHD)

   if nargin < 5
       readHD = false;
   end
        % get name of the file specified relative to the FP file:
    [SubfileName, err1] = GetFASTPar(FP,VarName);

    if (err1)
        p=[];
        newSubfileName = [];
        disp(['Warning: variable ' VarName ' not found']);
        return;
    end

        % see if we need to make a new directory for the new AD root
    if nargin > 3
        % Change filename, potentially create parent directory if needed
        % get it here before potentially changing it relative to the old
        % directory name
        newSubfileName = RebaseFile( SubfileName, newDir ); % new path + name
    end
    
        % get the full path name, relative to the old directory location:
    SubfileName = GetFullFileName( SubfileName, oldDir );
    if ~exist(SubfileName,'file')
        error('File not found: %s', SubfileName)
    end
    %try % removing try/catch to highlight cases where reader fail
    if readHD
        p = HD2Matlab(SubfileName,2); % get parameter data (2 header lines)
    else
        p = FAST2Matlab(SubfileName,2); % get parameter data (2 header lines)
    end 
    %catch
    %    disp(['Warning: an error occured while reading: ' SubfileName]);
    %    p.Label = [];
    %end

    if nargin <= 3
        newSubfileName = SubfileName;
    end
            
end
