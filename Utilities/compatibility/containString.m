function b=containstring(str, pattern)
    % wrap the function "contains" which is not available in Octave..
    if (exist ("OCTAVE_VERSION", "builtin") > 0)
        b=~isempty(strfind(str,pattern));
    else
        b=contains(str,pattern);
    end
end
