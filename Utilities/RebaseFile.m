function newSubfileName = RebaseFile(SubfileName, newDir);
% Change filename, potentially create parent directory if needed

newSubfileName = GetFullFileName( SubfileName, newDir ); % new path + name

[newSubfilePath] = fileparts(newSubfileName);
if ~isempty(newSubfilePath)
    if 7~=exist(newSubfilePath,'dir')
       mkdir(newSubfilePath)
    end
end
