function [p, newSubfileName] = GetFASTPar_Subfile(FP, VarName, oldDir, newDir)

        % get name of the file specified relative to the FP file:
    SubfileName = GetFASTPar(FP,VarName);

        % see if we need to make a new directory for the new AD root
    if nargin > 3
        % this is the new file name:
        % get it here before potentially changing it relative to the old
        % directory name
        newSubfileName = GetFullFileName( SubfileName, newDir ); % new path + name
        
        [newSubfilePath] = fileparts(newSubfileName);
        if ~isempty(newSubfilePath)
            if 7~=exist(newSubfilePath,'dir')
               mkdir(newSubfilePath)
            end
        end
    end
    
        % get the full path name, relative to the old directory location:
    SubfileName = GetFullFileName( SubfileName, oldDir );
    try
        p = FAST2Matlab(SubfileName,2); % get parameter data (2 header lines)
    catch
        disp(['Warning: cannot open ' SubfileName ' for reading']);
        p = [];
    end

    if nargin <= 3
        newSubfileName = SubfileName;
    end
            
end
