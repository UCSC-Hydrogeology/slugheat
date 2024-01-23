%%% =======================================================================
%%   Purpose: 
%       This function plots the depth data from the tap file. These plots 
%       are found under the Penetration Data tab on SlugHeat GUI. If no 
%       tap file exists, the average depth will be used and the user will 
%       be notified with a pop-up window.
%%   Last edit:
%       01/13/2024 by Kristin Dickerson, UCSC 
%%% =======================================================================

function   PlotDepth(figure_Main, ...
            axes_Depth, ...
            checkbox_DepthPlot, ...
            Tilt, ...
            Depth, DepthMean, ...
            TAPRecord)

% Plot depth sensor data 
% ------------------------
    if isempty(TAPRecord) || length(Tilt) == 1
        uialert(figure_Main, ['There is no tilt and pressure (TAP) record ' ...
            'found.' fprintf('\n') 'Average depth = ' num2str(DepthMean) ' ' ...
            'm'],'File not found', 'Icon', 'warning');
        checkbox_DepthPlot.Value = 0;
        checkbox_DepthPlot.Enable = 'off';
    else
        plot(axes_Depth, TAPRecord, Depth, '-b', 'MarkerSize',3)
        axes_Depth.Color = [0.94,0.94,0.94];
        axes_Depth.YTickLabelRotation = 15;
        axes_Depth.YDir = 'reverse';
    end
    drawnow;