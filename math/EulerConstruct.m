function [M] = EulerConstruct(x,y,z)

      cx = cos( x );
      sx = sin( x );
      
      cy = cos( y );
      sy = sin( y );
      
      cz = cos( z );
      sz = sin( z );
         
      M(1,1) =  cy*cz;            
      M(2,1) = -cy*sz;            
      M(3,1) =  sy;    
      
      M(1,2) =  cx*sz+sx*sy*cz;            
      M(2,2) =  cx*cz-sx*sy*sz;            
      M(3,2) =       -sx*cy;     
      
      M(1,3) =  sx*sz-cx*sy*cz;            
      M(2,3) =  sx*cz+cx*sy*sz;            
      M(3,3) =        cx*cy;               

end 