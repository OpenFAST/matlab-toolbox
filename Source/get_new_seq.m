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

nb = 3; %% do not change this
[rq, csize] = size(rot_q_triplet);
if(csize ~= nb)
 display('***ERROR: num of columns in the input triplet matrix is not a multiple of 3, the allowable number of blades');
 return
end
num_rot = rq*nb;

for i = 1:rq
 for j = 1:nb
  vrot((i-1)*nb+j) = rot_q_triplet(i,j);
 end
end

id_seq = zeros(ntot,1);
for i = 1:num_rot
 id_seq(vrot(i)) = i;
end

num_nr = ntot-num_rot;
k=0;
for i = 1:ntot
 if(id_seq(i) == 0)
  k = k+1;
  new_seq(k) = i;
 else
  new_seq(num_nr+id_seq(i)) = i;
 end
end
%------------------------------------------------------------------------------------------------------------------------