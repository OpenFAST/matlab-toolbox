function [DCM] = DCM_fromWMparam(cc)
    %BD_CrvMatrixR(cc)
   c = cc/4;

   c0  = 0.5 * (1 - dot(c));         
   c1 = c(1);
   c2 = c(2);
   c3 = c(3);
   
   tr0 = 1 - c0;             
   tr0 = 2/(tr0*tr0);

   Rr(1,1) = tr0*(c1*c1 + c0*c0) - 1;
   Rr(2,1) = tr0*(c1*c2 + c0*c3);
   Rr(3,1) = tr0*(c1*c3 - c0*c2);

   Rr(1,2) = tr0*(c1*c2 - c0*c3);
   Rr(2,2) = tr0*(c2*c2 + c0*c0) - 1;
   Rr(3,2) = tr0*(c2*c3 + c0*c1);

   Rr(1,3) = tr0*(c1*c3 + c0*c2);
   Rr(2,3) = tr0*(c2*c3 - c0*c1);
   Rr(3,3) = tr0*(c3*c3 + c0*c0) - 1;

   DCM = transpose(Rr);

   return;
end