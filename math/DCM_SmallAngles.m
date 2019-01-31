function [GetSmllRotAngsD] = DCM_SmallAngles( DCMat )
    
    LrgAngle  = 0.4; % Threshold for when a small angle becomes large (about 23deg).  This comes from: COS(SmllAngle) ~ 1/SQRT( 1 + SmllAngle^2 ) and SIN(SmllAngle) ~ SmllAngle/SQRT( 1 + SmllAngle^2 ) results in ~5% error when SmllAngle = 0.4rad.
    
      % calculate the small angles
   GetSmllRotAngsD(1) = DCMat(2,3) - DCMat(3,2);
   GetSmllRotAngsD(2) = DCMat(3,1) - DCMat(1,3);
   GetSmllRotAngsD(3) = DCMat(1,2) - DCMat(2,1);

   denom             = DCMat(1,1) + DCMat(2,2) + DCMat(3,3) - 1.0;

   GetSmllRotAngsD = GetSmllRotAngsD / denom;
   
   if ( denom ~= 0 )
         % check that the angles are, in fact, small
      if ( any( abs(GetSmllRotAngsD) > LrgAngle ) )
         disp( 'Warning: Angles in GetSmllRotAngs() are not small.' );
      end
   else
     disp( 'Warning: denominator is zero in GetSmllRotAngs(). Angles are not small.' );
   end
   