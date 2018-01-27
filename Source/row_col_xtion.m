function [Aout] = row_col_xtion(Ainp, new_seq, rc_id, rev_seq)
% re-sequence rows or columns of the input matrix

% inputs:
% Ainp = input mxn matrix
% new_seq = desired sequence of non-rot and rot variables
% rc_id = 1: rows need to be re-sequenced
% rc_id = 2: columns need to be re-sequenced
% rev_seq = 0: forward sequenceing requested
% rev_seq = 1: reverse sequenceing requested

% output:
% Aout = transformed mxn matrix

[m,n] = size(Ainp);
sn = length(new_seq);
if(rc_id == 1 && m ~= sn)
 display('ERROR** number of rows of the input matrix does not match size of the vector new_seq ');
end
if(rc_id == 2 && n ~= sn)
 display('ERROR** number of columns of the input matrix does not match size of the vector new_seq ');
end

Aout = zeros(m,n); % preallocate space for Aout
if(rev_seq == 0)
    if(rc_id == 1)
        for i = 1:m
            Aout(i,:) = Ainp(new_seq(i),:);
        end
    elseif(rc_id == 2)
        for i = 1:n
            Aout(:,i) = Ainp(:,new_seq(i));
        end
    end
elseif(rev_seq == 1)
    if(rc_id == 1)
        for i = 1:m
            Aout(new_seq(i),:) = Ainp(i,:);
        end
    elseif(rc_id == 2)
        for i = 1:n
            Aout(:,new_seq(i)) = Ainp(:,i);
        end
    end
end
%---------------------------------------------------------
