function [DCM, theta] = DCM_exp(lambda)
%%
   theta = norm(lambda);                   % Eq. 32
   theta2 = theta^2;

   if ( theta == 0.0 || theta2 == 0.0 ) 
      
      DCM = eye(3);    % Eq. 33a
      
   else   
      
         % convert lambda to skew-symmetric matrix:
      tmp_mat(1,1) =  0.0;                                            
      tmp_mat(2,1) = -lambda(3);                                           
      tmp_mat(3,1) =  lambda(2);                                           
      tmp_mat(1,2) =              lambda(3);                               
      tmp_mat(2,2) =              0.0;                                
      tmp_mat(3,2) =             -lambda(1);                               
      tmp_mat(1,3) =                               -lambda(2);             
      tmp_mat(2,3) =                                lambda(1);             
      tmp_mat(3,3) =                                0.0;            
      
      
         % Eq. 33b
      %DCM_exp = I + sin(theta)/theta*tmp_mat + (1-cos(theta))/theta**2)*matmul(tmp_mat,tmp_mat)
      
         % one method:
      %CALL eye(DCM_exp, ErrStat, ErrMsg)                  
      %DCM_exp = DCM_exp + sin(theta)/theta*tmp_mat 
      %DCM_exp = DCM_exp + (1-cos(theta))/theta2 * MATMUL(tmp_mat, tmp_mat) 
      
         % hopefully this order of calculations gives better numerical results:
      stheta = sin(theta);
      DCM      = (1-cos(theta))/theta * tmp_mat;      
      DCM(1,1) = DCM(1,1) + stheta;
      DCM(2,2) = DCM(2,2) + stheta;
      DCM(3,3) = DCM(3,3) + stheta;
      
      DCM = DCM * tmp_mat ;
      DCM = DCM / theta;
      DCM(1,1) = DCM(1,1) + 1.0; % add identity
      DCM(2,2) = DCM(2,2) + 1.0;
      DCM(3,3) = DCM(3,3) + 1.0;
            
   end            

end 