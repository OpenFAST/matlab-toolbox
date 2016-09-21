function [Mat, name, line] = readFASTMatrix(fid)

    line = fgetl(fid);
    if ischar(line) && ~isempty(line)
        C = textscan( line, '%s', 'delimiter', ':' );
        if isempty(C) || length(C{1}) < 2
            name = -1;
            Mat = [];
            return
        end
        
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
