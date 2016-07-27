% function [logMap, theta, v_pi] = DCM_LogMap(DCM)
function [logMap, theta, v_pi] = DCM_LogMap(DCM)

      cosTheta  = 0.5*( trace(DCM) - 1.0 );
      cosTheta  = min( max(cosTheta,-1.0), 1.0 );
      theta = acos( cosTheta );       % Eq. 25 ( 0<=theta<=pi )
      
      
%%      
      
        if ( theta > 3.1 ) % theta/(2*sin(theta)) blows up quickly as theta approaches pi, 
         % so I'm putting a pretty large tolerance on pi here, and using a different equation to find the solution near pi
                     
             %d11 = 1 - (1-cos(theta))/theta^2 * (logMap3^2 + logMap2^2)
             %d22 = 1 - (1-cos(theta))/theta^2 * (logMap3^2 + logMap1^2)
             %d33 = 1 - (1-cos(theta))/theta^2 * (logMap2^2 + logMap1^2)

             logMap(1) = theta * sqrt(abs( 0.5 * ( 1.0 + DCM(1,1) - DCM(2,2) - DCM(3,3) ) / (1.0-cosTheta) ));
             logMap(2) = theta * sqrt(abs( 0.5 * ( 1.0 - DCM(1,1) + DCM(2,2) - DCM(3,3) ) / (1.0-cosTheta) ));
             logMap(3) = theta * sqrt(abs( 0.5 * ( 1.0 - DCM(1,1) - DCM(2,2) + DCM(3,3) ) / (1.0-cosTheta) ));

             % we choose logMap1 positive then we get the signs for logMap2 and logMap3:
             if ( logMap(1) ~= 0.0 )
                %d12+d21=2*(1-cos(theta))/theta**2 * logMap(1)*logMap(2); 2*(1-cos(theta))/theta**2 * logMap(1)>0 so logMap(2) is sign(logMap(2),d12+d21)
                %d13+d31=2*(1-cos(theta))/theta**2 * logMap(1)*logMap(3); 2*(1-cos(theta))/theta**2 * logMap(1)>0 so logMap(3) is sign(logMap(3),d13+d31)

                logMap(2) = sign( logMap(2), DCM(1,2)+DCM(2,1) );
                logMap(3) = sign( logMap(3), DCM(1,3)+DCM(3,1) );            
             else
                % because logMap1 is zero, we can choose logMap2 positive:

                %d23+d32=2*(1-cos(theta))/theta**2 * logMap(2)*logMap(3); 2*(1-cos(theta))/theta**2 * logMap(2)>0 so logMap(3) is sign(logMap(3),d23+d32)
                logMap(3) = sign( logMap(3), DCM(2,3)+DCM(3,2) );            

             end

             % at this point we may have the wrong sign for logMap (though if theta==pi, it doesn't matter because we can change it in the DCM_setLogMapforInterp() routines)
             % we'll do a little checking to see if we should change the sign:

             if ( theta == pi ) 
                 return
             end

             v(1) = -DCM(3,2) + DCM(2,3); %-skewSym(3,2)
             v(2) =  DCM(3,1) - DCM(1,3); % skewSym(3,1)
             v(3) = -DCM(2,1) + DCM(1,2); %-skewSym(2,1)

             indx_max = 1;
             for i = 2:3
                if ( abs(v(i)) > abs(v(indx_max)) ) 
                    indx_max = i;
                end
             end


             if ( sign(1.0,v(indx_max)) ~= sign(1.0,logMap(indx_max)) )
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