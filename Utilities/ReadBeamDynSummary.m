% ADP: edited to read more of the summary file contents
%
%  1. read the mass/stiffness matrices in addition to full ones
%
function [data] = ReadBeamDynSummary(fileName)

   fid   = fopen( fileName );

   if ( fid <= 0 )
      error(['Could not open the summary file: ' fileName ]);
   else



      while ( true )
         line  = fgetl(fid);
         if ~ischar(line) % We reached the end of the file
            break;
         end
         line = upper(line);

         %% Some initial info
         findx = strfind(line,'QUADRATURE METHOD:');
         if ~isempty(findx)
            tmp=textscan(line,'%*s %s','Delimiter',':');
            data.Quadrature=tmp{1};
         end

         
         findx = strfind(line,'NUMBER OF ELEMENTS:');
         if ~isempty(findx)
            tmp=textscan(line,'%*s %f','Delimiter',':');
            data.NumElements=tmp{1};
         end
         
         findx = strfind(line,'NUMBER OF NODES:');
         if ~isempty(findx)
            tmp=textscan(line,'%*s %f','Delimiter',':');
            data.TotFE=tmp{1};
            if isfield(data,'NumElements')
               data.FEperElem=(data.TotFE+data.NumElements-1)/data.NumElements;
            end
            continue;
         end
         
         
         %% FE position info.  ends with blank line, may have multiple elements
         findx = strfind(line,'INITIAL POSITION VECTORS');
         if ~isempty(findx)
            nelem=0;
            for i=1:data.NumElements
               line=fgetl(fid);
               if ~isempty(line)
                  nelem = textscan(line,'Element number: %f');
               end
               if nelem{1} ~= i
                  disp(['Error in reading initial position vectors of FE nodes from ' fileName '. Skipping.']);
                  continue;
               else
                  dummy=fgetl(fid);    % Header line
                  dummy=fgetl(fid);    % Another header line
                  data.FE.Pos(:,:,i)=fscanf(fid, '%f',[5,data.FEperElem])';
                  line=fgetl(fid);     % get end of line
               end
            end
            continue;
         end
         
         findx = strfind(line,'INITIAL WEINER-MILENKOVIC ROTATION VECTORS ');
         if ~isempty(findx)
            nelem=0;
            for i=1:data.NumElements
               line=fgetl(fid);
               if ~isempty(line)
                  nelem = textscan(line,'Element number: %f');
               end
               if nelem{1} ~= i
                  disp(['Error in reading initial position vectors of FE nodes from ' fileName '. Skipping.']);
                  continue;
               else
                  dummy=fgetl(fid);    % Header line
                  dummy=fgetl(fid);    % Another header line
                  data.FE.Rot(:,:,i)=fscanf(fid, '%f',[5,data.FEperElem])';
                  line=fgetl(fid);     % get end of line
               end
            end
            continue;
         end
         
         
         %% Find the QP mass stiffness matrices
         findx = strfind(line,'QUADRATURE POINT NUMBER:');
         if ~isempty(findx)
            tmp=textscan(line,'%*s %f','Delimiter',':');
            GlobQP = tmp{1}(1);
            if size(tmp{1},2) > 1
               data.SectionElem(GlobQP)   = tmp{1}(2);
               data.SectionQP(GlobQP)     = tmp{1}(3);
            end
            data.SectionK(1:6,1:6,GlobQP)= fscanf(fid, '%f',[6,6]);
            dummy=fgetl(fid);
            data.SectionM(1:6,1:6,GlobQP)= fscanf(fid, '%f',[6,6]);
            continue;
         end


         
         %% Get the full stiffness matrices
         findx = strfind(line,'FULL STIFFNESS MATRIX');
         if ~isempty(findx)
            data.K = readMatrix(fid,line);

            if (isempty(strfind(line,'IEC COORDINATES')))
               data.K = convertBD2IEC(data.K);
            end
            continue;
         end

         findx = strfind(line,'FULL MASS MATRIX');
         if ~isempty(findx)
            data.M = readMatrix(fid,line);

            if (isempty(strfind(line,'IEC COORDINATES')))
               data.M = convertBD2IEC(data.M);
            end
            continue;
         end

      end %while


   end

   fclose(fid);

   return
end


function [M] = readMatrix(fid, lastLine, nc)

   findx = strfind(lastLine,':');
   dummy=textscan( lastLine(findx(1)+1:end), '%f %*s %f', 2 );

   nr=dummy{1};
   if ~isempty(dummy{2})
      nc=dummy{2};
   elseif nargin < 3
      nc = 1;
   end

   M = fscanf(fid, '%f',[nc,nr]);
   M = M';
   fgetl(fid); %finish reading that line

   return
end

function [IEC] = convertBD2IEC(BD)
   nc=size(BD,1);

   T = [0,1,0;
      0,0,1;
      1,0,0];

   T_full = zeros(nc,nc);
   for n=1:3:nc
      T_full(n:(n+2),n:(n+2)) = T;
   end

   IEC = T_full * BD * T_full';

   return
end