function [Mesh1_I,Mesh1_O,Mesh2_I,Mesh2_O, f] ...
    = PlotFASTIOMeshes( Mesh1_Input, Mesh1_Output,Mesh2_Input,Mesh2_Output, exportFigure )
%%
%
DisplacedOnly = true;

if nargin < 5 
    exportFigure = 0;
end

if exportFigure ~= 0
    fig_start = 1;
    fig_end   = 2;
else
    fig_start = 2;
    fig_end   = 2;
end


if (isnumeric(Mesh1_Output))
    [fid, message] = fopen( Mesh1_Input );
    if fid < 1
        error(['PlotFASTIOMeshes:: Error opening file: ' Mesh1_Input '. ' message]);
    end
    Mesh1_Input  = fid;
    Mesh1_Output = fid;
    Mesh2_Input  = fid;
    Mesh2_Output = fid;    
end
   % DO NOT REORDER THESE READ STATEMENTS!!!! 
Mesh1_I = ReadFASTmesh(Mesh1_Input);
Mesh1_O = ReadFASTmesh(Mesh1_Output); 
Mesh2_I = ReadFASTmesh(Mesh2_Input);
Mesh2_O = ReadFASTmesh(Mesh2_Output); 

if (isnumeric(Mesh1_Output))
    fclose(fid);
end

%%

% FieldNames = {'RefOrientation','Orientation','TranslationDisp',...
%               'TranslationVel','RotationVel',...
%               'TranslationAcc','RotationAcc',...
%               'Force','Moment','Scalars' };
 
% npr = 2; %rows are values for each module:
% npc = 3; % 1) Reference, 2) Loads, 3) Motions
RefColor     = [1,1,1]*.5;
MotionsColor = [.5,0,.5];



%.............................
% compute scaling factor to scale motions:
% ScaleSize = 0.5; %scaling factor for arrows on quiver plot
maxMotion = 1;
if isfield(Mesh2_I,'TranslationVel')
    maxMotion = max( maxMotion, max(abs(Mesh2_I.TranslationVel( :))) );
end
if isfield(Mesh1_O,'TranslationVel')
    maxMotion = max( maxMotion, max(abs(Mesh1_O.TranslationVel( :))) );
end
if isfield(Mesh2_I,'TranslationAcc')
    maxMotion = max( maxMotion, max(abs(Mesh2_I.TranslationAcc( :))) );
end
if isfield(Mesh1_O,'TranslationAcc')
    maxMotion = max( maxMotion, max(abs(Mesh1_O.TranslationAcc( :))) );
end
if isfield(Mesh2_I,'RotationVel')
    maxMotion = max( maxMotion, max(abs(Mesh2_I.RotationVel( :))) );
end
if isfield(Mesh1_O,'RotationVel')
    maxMotion = max( maxMotion, max(abs(Mesh1_O.RotationVel( :))) );
end
if isfield(Mesh2_I,'RotationAcc')
    maxMotion = max( maxMotion, max(abs(Mesh2_I.RotationAcc( :))) );
end
if isfield(Mesh1_O,'RotationAcc')
    maxMotion = max( maxMotion, max(abs(Mesh1_O.RotationAcc( :))) );
end

             
m_exp =max( 1, log10( maxMotion ));
m_exp = round(m_exp*10)/10; %round to one decimal place
ScaleSize = 10^(-m_exp);
%ScaleSize = 1;
disp(['Motions scaled by ' num2str(ScaleSize) ' for plotting.']);
%.............................


%.............................
% compute scaling factor to scale forces and moments:
% ForceSize = 1./1000  %scaling factor for arrows on quiver plot
maxLoad = max( [ max(abs(Mesh1_I.Force( :)));
                 max(abs(Mesh1_I.Moment(:)));
                 max(abs(Mesh2_O.Force(:)));
                 max(abs(Mesh2_O.Moment(:))); ] );
             
% f_exp = floor(max( 1, log10( maxLoad ))); 
% f_exp = floor( maxLoad*10^(-f_exp) )*10^(f_exp); % 1 digit of precision

f_exp =max( 1, log10( maxLoad ));
f_exp = round(f_exp*10)/10; %round to one decimal place
ForceSize  = 10^(-f_exp);
%ForceSize  = 1*10^-6;
%MomentSize = 1*10^-4;
MomentSize = ForceSize;

% ForceSize = 1/f_exp;
disp(['Forces scaled by ' num2str(ForceSize) ' for plotting.']);
disp(['Moments scaled by ' num2str(MomentSize) ' for plotting.']);
scltxt = [num2str(ForceSize) ' (forces), ',num2str(MomentSize) ' (moments)' ];
%.............................


f=figure;
IndividualFigs=zeros(6,1);

%% Plot Mod1 Reference
    figure(f); subplot(3,2,1)
    for i=fig_start:fig_end
      hold on;  
      DrawMesh(Mesh1_I, RefColor, ScaleSize );   
      setAxisValues('\bfMesh1 Reference',i==1,exportFigure); 
      if i < fig_end; IndividualFigs(1)=figure; subplot(1,1,1); end
    end
  
%% Plot Mod1 Motions and Loads
    figure(f); subplot(3,2,3);
    for i=fig_start:fig_end
        hold on;
        DrawMesh(Mesh1_O, RefColor, ScaleSize );   
        DrawMeshMotions(Mesh1_O, MotionsColor, ScaleSize )
        setAxisValues('\bfMesh1: Outputs (Motions)',i==1,exportFigure, ScaleSize); 
        if i < fig_end; IndividualFigs(3)=figure; subplot(1,1,1); end
    end

    figure(f); subplot(3,2,5)
    for i=fig_start:fig_end
        hold on;
        DrawMesh(Mesh1_O, RefColor, ScaleSize );   
        DrawMeshMotions(Mesh1_O, MotionsColor, ScaleSize, DisplacedOnly )
        DrawMeshLoads(Mesh1_I, Mesh1_O, [ForceSize MomentSize])
        setAxisValues('Mesh1: Calculated Inputs (Loads)',i==1,exportFigure, scltxt); 
        if i < fig_end; IndividualFigs(5)=figure; subplot(1,1,1); end
    end
   
    
%% Plot Mod2 Reference
    figure(f); subplot(3,2,2)
    for i=fig_start:fig_end
      hold on;  
      DrawMesh(Mesh2_I, RefColor, ScaleSize );   
      setAxisValues('\bfMesh2 Reference',i==1,exportFigure);    
      if i < fig_end; IndividualFigs(2)=figure; subplot(1,1,1); end 
    end
  
%% Plot Mod2 Motions and Loads    
    figure(f); subplot(3,2,4);
    for i=fig_start:fig_end
        hold on;
        DrawMesh(Mesh2_I, RefColor, ScaleSize );   
        DrawMeshMotions(Mesh2_I, MotionsColor, ScaleSize )
        setAxisValues('Mesh2: Calculated Inputs (Motions)',i==1,exportFigure, ScaleSize); 
        if i < fig_end; IndividualFigs(4)=figure; subplot(1,1,1); end
    end

    figure(f); subplot(3,2,6);
    for i=fig_start:fig_end
        hold on;
        DrawMesh(Mesh2_I, RefColor, ScaleSize );   
        DrawMeshMotions(Mesh2_I, MotionsColor, ScaleSize, DisplacedOnly )
        DrawMeshLoads(Mesh2_O, Mesh2_I, [ForceSize MomentSize] )
        setAxisValues('\bfMesh2: Outputs (Loads)',i==1,exportFigure, scltxt); 
        if i < fig_end; IndividualFigs(6)=figure; subplot(1,1,1); end 
    end
    
%%
setLimits(f,IndividualFigs);

return;
end % function

function setLimits(f,IndividualFigs)

    figure(f);
    
        % figure out what the defalut limits on the plots are,
        % and get the max/min values for each axis:
    subplot(3,2,1);
    TheseXLimits=xlim;
    TheseYLimits=ylim;
    TheseZLimits=zlim;
    
    for i = 2:6
        subplot(3,2,i);
        
        TheseXLimits(1)=min(min(TheseXLimits,xlim));
        TheseYLimits(1)=min(min(TheseYLimits,ylim));
        TheseZLimits(1)=min(min(TheseZLimits,zlim));
        TheseXLimits(2)=max(max(TheseXLimits,xlim));
        TheseYLimits(2)=max(max(TheseYLimits,ylim));
        TheseZLimits(2)=max(max(TheseZLimits,zlim));
    end
    
    disp( TheseXLimits )
    disp( TheseYLimits )
    disp( TheseZLimits )
    
        % make limits consistent across individual figures
        
    for i=1:6
        if IndividualFigs(i) > 0
            figure(IndividualFigs(i));
            xlim(TheseXLimits);
            ylim(TheseYLimits);
            zlim(TheseZLimits);           
       end
    end
    
    
        % make the limits consistent across figure f
        % (note I do this last so that it's the "current figure" when we
        % return from this routine)
    figure(f);
    for i=1:6
        subplot(3,2,i);

        xlim(TheseXLimits);
        ylim(TheseYLimits);
        zlim(TheseZLimits);
    end
    
            
    return
end

function setAxisValues(titleTxt,showLgnd,exportFig,ScaleFactor)

    view(3)
    axis equal; %         axis vis3d ;
    camproj('perspective') 
    if nargin>0
        if nargin < 4 || (isnumeric(ScaleFactor) && ScaleFactor == 1)
            title(titleTxt)
        else
            if isnumeric(ScaleFactor)
                title( { titleTxt, ['\rmscaled by ' num2str(ScaleFactor) ' units']} );
            else
                title( { titleTxt, ['\rmscaled by ' ScaleFactor ' units']} );
            end 
        end
    end
    grid on

    
    
%         set(gca,'CameraPosition', cam_position,  ...
%                 'CameraTarget',   cam_target , ...
%                 'CameraViewAngle',cam_angle  );
    
    
    
    if exportFig == 1 % this particular model needs these properties:
%         xlim([-1 7])
%         ylim([-1 2])
%         zlim([-1 2])
%         set(gca,'FontName','Arial')
%         set(gca, 'XTick',-1:7, ...
%                  'YTick',-1:2, ...
%                  'ZTick',-1:2  );
%              
           % these labels are too far away, so we'll have to adjust to
           % strings
%         xlabel('')
%         ylabel('')
%         ypos=[-20.870124821934784, -30.608152320400897, 23.138462843672215];
%         xpos=[-20.87012482166956 , -30.608152320583304, 23.138462843701216];
%         
%         text(ypos(1),ypos(2),ypos(3),'Y','FontName','Arial')
%         text(xpos(1),xpos(2),xpos(3),'X','FontName','Arial')
    else
        xlabel('X')
        ylabel('Y')
        
    end 

    
    if showLgnd
     % legend('show','Location','EastOutside');
    end
                       
    
return
end





 

