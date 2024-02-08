%%% =======================================================================
%%   Purpose: 
%       This function plots the depth data from the tap file. These plots 
%       are found under the Penetration Data tab on SlugHeat GUI. If no 
%       tap file exists, the average depth will be used and the user will 
%       be notified with a pop-up window.
%%   Last edit:
%       01/13/2024 by Kristin Dickerson, UCSC 
%%% =======================================================================

function PlotTilt(TAPRecord, ...
            figure_Main, ...
            TiltMean, ...
            Tilt, ...
            checkbox_TiltPlot, ...
            grid_PenetrationInfo, ...
            axes_Tilt, ...
            Reprocess)

 TAPRecord = 1:1:length(TAPRecord);  

% Plot tilt sensor data
% ------------------------
    if isempty(TAPRecord) || length(Tilt) == 1
        if Reprocess == 1
            uialert(figure_Main,['There is no tilt and pressure (TAP) record.' ...
                fprintf('\n') 'Average tilt = ' num2str(TiltMean) '°'], ['File' ...
                ' not found'], 'Icon', 'warning');
        end
            checkbox_TiltPlot.Value = 0;
            checkbox_TiltPlot.Enable = 'off';
            grid_PenetrationInfo.RowHeight = {'1x', '1x', '0x', '0x'};   
    else
        plot(axes_Tilt, TAPRecord, Tilt, '-r', 'MarkerSize',3);
        axes_Tilt.Color = [0.94,0.94,0.94];
    end
    drawnow;