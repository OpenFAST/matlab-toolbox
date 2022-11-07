function [retval] = startsWithString(str, prefix)
    % wrap the function "startswith" which is not available in Octave..
    if (exist ("OCTAVE_VERSION", "builtin") > 0)
        n = length(prefix);
        if n == 0 
            retval = 1; % Every string starts with empty prefix
            return
        end
        retval = strncmp(str, prefix, n);
    else
        retval = startsWith(str, prefix);
    end
end
