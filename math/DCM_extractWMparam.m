function [cc] = DCM_extractWMparam(DCM)
% BD_CrvExtractCrv(Rr,cc)

   Rr = transpose(DCM);

   sm(1) = 1 + Rr(1,1) + Rr(2,2) + Rr(3,3);      %  4 c_0 c_0 t_{r0}
   sm(2) = 1 + Rr(1,1) - Rr(2,2) - Rr(3,3);      %  4 c_1 c_1 t_{r0}
   sm(3) = 1 - Rr(1,1) + Rr(2,2) - Rr(3,3);      %  4 c_2 c_2 t_{r0}
   sm(4) = 1 - Rr(1,1) - Rr(2,2) + Rr(3,3);      %  4 c_3 c_3 t_{r0}

   [~,ipivot] = max(sm);
   
      
   switch (ipivot)
   case (4)      
      %% We need the condition that c_3 is not zero.
      sm(1)  = Rr(2,1) - Rr(1,2);                           %  4 c_0 c_3 t_{r0}
      sm(2)  = Rr(1,3) + Rr(3,1);                           %  4 c_1 c_3 t_{r0}
      sm(3)  = Rr(2,3) + Rr(3,2);                           %  4 c_2 c_3 t_{r0}
     %sm(4)  = 1 - Rr(1,1) - Rr(2,2) + Rr(3,3);             %  4 c_3 c_3 t_{r0}

   case (3)      
      %% We need the condition that c_2 is not zero.
      sm(1)  = Rr(1,3) - Rr(3,1);                           %  4 c_0 c_2 t_{r0}
      sm(2)  = Rr(1,2) + Rr(2,1);                           %  4 c_1 c_2 t_{r0}
     %sm(3)  = 1 - Rr(1,1) + Rr(2,2) - Rr(3,3);             %  4 c_2 c_2 t_{r0}
      sm(4)  = Rr(2,3) + Rr(3,2);                           %  4 c_3 c_2 t_{r0}

   case (2)
      %% We need the condition that c_1 is not zero.
      sm(1)  = Rr(3,2) - Rr(2,3);                           %  4 c_0 c_1 t_{r0}
     %sm(2)  = 1 + Rr(1,1) - Rr(2,2) - Rr(3,3);             %  4 c_1 c_1 t_{r0}
      sm(3)  = Rr(1,2) + Rr(2,1);                           %  4 c_2 c_1 t_{r0}
      sm(4)  = Rr(1,3) + Rr(3,1);                           %  4 c_3 c_1 t_{r0}

   case (1)
      %% We need the condition that c_0 is not zero.
     %sm(1)  = 1 + Rr(1,1) + Rr(2,2) + Rr(3,3);             %  4 c_0 c_0 t_{r0}
      sm(2)  = Rr(3,2) - Rr(2,3);                           %  4 c_1 c_0 t_{r0}
      sm(3)  = Rr(1,3) - Rr(3,1);                           %  4 c_2 c_0 t_{r0}
      sm(4)  = Rr(2,1) - Rr(1,2);                           %  4 c_3 c_0 t_{r0}
   end


   em = sm(1) + 2*sqrt(sm(ipivot)) * sign( sm(1) ); 
   em = 4/em;                                        % 1 / ( 4 t_{r0} c_{ipivot} ), assuming 0 <= c_0 < 4 and c_{ipivot-1} > 0
   cc = em*sm(1:3);

   return;
end