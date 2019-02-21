function [new_seq] = get_new_seq(rot_q_triplet,ntot)
% form new_sequence vector with non-rot identifiers followed by rot identifiers

%inputs:
% rot_q_triplet = input rqx3 matrix of rot_quantity_triplets
% ntot = total number of quantities

%Output:
% new_seq(ntot)

% convert input rqx3 matrix of rot_quantity_triplets into a vector of size 3*rq
% rq = num of rot_frame quantities appearing as triplets (e.g. first flap-mode deflection)
% vrot = vector of rotating-frame quantities (size 3*rq)


[rq, nb] = size(rot_q_triplet);
if(nb ~= 3)
 display('***ERROR: num of columns in the input triplet matrix is not a multiple of 3, the allowable number of blades');
 return
end

id_seq = zeros(ntot,1);
for i = 1:rq
    for j = 1:nb
        id_seq(rot_q_triplet(i,j)) = (i-1)*nb+j;
    end
end

new_seq = zeros(1,ntot); % allocate space for new_seq
num_rot = rq*nb;         % total number of id_seq that are non zero
num_nr  = ntot-num_rot;  % total number of id_seq that are zero
k=0;                     % counter for values that aren't triplets
for i = 1:ntot
    if (id_seq(i) == 0)  % not a triplet
        k = k+1;
        new_seq(k) = i;
    else
        new_seq(num_nr+id_seq(i)) = i;
    end
end
%------------------------------------------------------------------------------------------------------------------------