function [MotionMap, LoadMap, Aug, lumpSrc, lumpDest] = ReadFASTmappingData(fid)

    MotionMap   = ReadFASTmatrix(fid);
    LoadMap     = ReadFASTmatrix(fid);
    M = fread( fid, 3, 'int32'); 
    
    if M(1) ~= 0
        Aug  = ReadFASTmesh(fid);
    else
        Aug = [];
    end
    if M(2) ~= 0
        lumpSrc = ReadFASTmesh(fid);
    else
        lumpSrc = [];
    end
    if M(3) ~= 0
        lumpDest = ReadFASTmesh(fid);
    else
        lumpDest = [];
    end


return
end


function [M]=ReadFASTmatrix(fid)
nbits = 'float32';
    M = fread( fid, 1, 'int32'); 
    if M ~= 0
        r = fread( fid, 1, 'int32');    
        c = fread( fid, 1, 'int32');    
        M = fread( fid,   [r, c], nbits ); 
    end
    
return
end