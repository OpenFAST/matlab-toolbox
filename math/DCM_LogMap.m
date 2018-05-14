% function [logMap, theta, v_pi] = DCM_LogMap(DCM)
function [logMap, theta, v_pi] = DCM_LogMap(DCM)

      cosTheta  = 0.5*( trace(DCM) - 1.0 );
      cosTheta  = min( max(cosTheta,-1.0), 1.0 );
      theta = acos( cosTheta );       % Eq. 25 ( 0<=theta<=pi )
      
      
%%      
      
        if ( theta > 3.1 ) % theta/(2*sin(theta)) blows up quickly as theta approaches pi, 
         % so I'm putting a pretty large tolerance on pi here, and using a different equation to find the solution near pi
            
            
             logMap(1) = 1.0 + DCM(1,1) - DCM(2,2) - DCM(3,3);
             logMap(2) = 1.0 - DCM(1,1) + DCM(2,2) - DCM(3,3);
             logMap(3) = 1.0 - DCM(1,1) - DCM(2,2) + DCM(3,3);
                          
             [~,indx] = max(abs(logMap));
             
             divisor = sqrt(abs( logMap(indx) *  2*(1 - cosTheta)  )) / theta;
             if indx==1
                 logMap(2) = DCM(1,2) + DCM(2,1);
                 logMap(3) = DCM(1,3) + DCM(3,1);
             elseif indx ==2
                 logMap(1) = DCM(1,2) + DCM(2,1);
                 logMap(3) = DCM(2,3) + DCM(3,2);
             else
                 logMap(1) = DCM(1,3) + DCM(3,1);
                 logMap(2) = DCM(2,3) + DCM(3,2);
             end
             logMap = logMap / divisor;            
            
             % at this point we may have the wrong sign for logMap (though if theta==pi, it doesn't matter because we can change it in the DCM_setLogMapforInterp() routines)
             % we'll do a little checking to see if we should change the sign:

             if ( theta == pi ) 
                 return
             end

             v(1) = -DCM(3,2) + DCM(2,3); %-skewSym(3,2)
             v(2) =  DCM(3,1) - DCM(1,3); % skewSym(3,1)
             v(3) = -DCM(2,1) + DCM(1,2); %-skewSym(2,1)
             
             [~,indx_max] = max(abs(v));

             if ( sign(v(indx_max)) ~= sign(logMap(indx_max)) )
                 logMap = -logMap;
             end
         
        else
         
            TwoSinTheta = 2.0*sin(theta);
         
             if ( theta == 0 || TwoSinTheta == 0 )
                logMap = zeros(3,1);                                                   
             else 
                logMap(1) = -DCM(3,2) + DCM(2,3); 
                logMap(2) =  DCM(3,1) - DCM(1,3); 
                logMap(3) = -DCM(2,1) + DCM(1,2); 

                logMap    = theta / TwoSinTheta * logMap;   
             end
         
        end
      
      
      
      
      
      
%%      
      
%       TwoSinTheta = 2.0*sin(theta);
%       
%       v_pi = sqrt( 0.5 * abs( diag(DCM) + 1 ) );
%       if (v_pi(1) ~= 1.0)            
%             v_pi(2) = v_pi(2) .* sign(DCM(1,2) );
%             v_pi(3) = v_pi(3) .* sign(DCM(1,3) );
%       else
%             v_pi(3) = v_pi(3) .* sign( DCM(2,3) ) ;
%       end
%       v_pi = -pi*v_pi;
%       
%       if( pi == theta )
%       
%           logMap =  v_pi;                                                          % Eq. 26c  
%                      
%       else
%          
%          if ( theta == 0.0 || TwoSinTheta == 0.0 )
%          
%             logMap = zeros(3,1);                                                         % Eq. 26a
%                   
%          else % 0 < theta < pi 
%       
%             skewSym = DCM - transpose(DCM);
%       
%             logMap(1) = -skewSym(3,2);
%             logMap(2) =  skewSym(3,1);
%             logMap(3) = -skewSym(2,1);
%       
%             logMap    = theta / TwoSinTheta * logMap;   % Eq. 26b
%          end
%          
%       end                 

end 