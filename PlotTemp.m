%%% =======================================================================
%%   Purpose: 
%       This function plots the calibrated temperatures relative to bottom 
%       water temperature recorded by each sensor. These plots are found 
%       under the Penetration Data tab on SlugHeat GUI.
%%   Last edit:
%       01/19/2024 by Kristin Dickerson, UCSC 
%%% =======================================================================

function    [S_Lines, ...
            AllSensors,...
            h_axTempAboveBWT] = ...
            PlotTemp(axes_TempAboveBWT, ...
            axes_BottomWaterTemp, ...
            axes_Depth, ...
            axes_Tilt, ...
            checkbox_BottomWaterPlot, ...
            AllSensorsTemp, ...
            NumberOfSensors, ...
            WaterThermistor, ...
            WaterSensorTemp, ...
            AllRecords, ...
            PenetrationRecord, ...
            HeatPulseRecord, ...
            EndRecord, ... 
            PulseData)

    % Delete current children of plots
    % --------------------------------
    delete(axes_TempAboveBWT.Children)
    delete(axes_BottomWaterTemp.Children)
    delete(axes_Depth.Children)
    delete(axes_Tilt.Children)
    
    % Define plot colormap
    % --------------------
        CMap= colormap(axes_TempAboveBWT, 'turbo');
        CMap = flipud(CMap);
        CMap = interp1(1:256,CMap,1:256/(NumberOfSensors):256); 
        colormap(axes_TempAboveBWT, CMap);
    
    % Plot temperatures of all sensors (except BW top sensor) on main plot
    % --------------------------------------------------------------------
        AllSensors = zeros(1, NumberOfSensors);
        for i=NumberOfSensors:-1:1
            % Plot by record number
        h_axTempAboveBWT(i) = plot(axes_TempAboveBWT, AllRecords, ...
            AllSensorsTemp(:,i),'-o','markersize',2, ...
            'Color',CMap(i,:),'markerfacecolor',CMap(i,:), 'tag', ...
            ['sensTemp_' num2str(i)]);    
        axes_TempAboveBWT.Color = [0.94,0.94,0.94];
        axes_TempAboveBWT.XMinorTick='on';
        axes_TempAboveBWT.YMinorTick= 'on';
    
        hold(axes_TempAboveBWT, 'on');
        AllSensors(i) = i;
        end
        drawnow
    
        axes_TempAboveBWT.UserData=3;
    
    
    % Plot temperatures of bottom water top sensor
    % --------------------------------------------
        if WaterThermistor == 1
           plot(axes_BottomWaterTemp, AllRecords,WaterSensorTemp, ...
               'k-','markersize',3);
           axes_BottomWaterTemp.Color = [0.94,0.94,0.94];
        else
            checkbox_BottomWaterPlot.Value = 0;
            checkbox_BottomWaterPlot.Enable = 'off';
        end
        drawnow; 
    
    % Plot lines for start and end of penetration and heat pulse
    % -----------------------------------------------------------
    
        PenLine = xline(axes_TempAboveBWT, PenetrationRecord, '--k', ...
            'FontWeight', 'bold', 'FontSize', 16);
        PenLine.Label = 'Start of Penetration';
        PenBWTLine = xline(axes_BottomWaterTemp, PenetrationRecord, '--k');
        PenDepthLine = xline(axes_Depth, PenetrationRecord, '--k');
        hold(axes_Depth,'on');
        PenTiltLine = xline(axes_Tilt, PenetrationRecord, '--k');
        hold(axes_Tilt,'on');
    
        if PulseData
            HPLine = xline(axes_TempAboveBWT, HeatPulseRecord, '--k', ...
                'FontWeight', 'bold', 'LabelHorizontalAlignment','left', ...
                'FontSize', 16);
            HPLine.Label = 'Heat Pulse';
            HPBWTLine = xline(axes_BottomWaterTemp, HeatPulseRecord, '--k');
            HPDepthLine = xline(axes_Depth, HeatPulseRecord, '--k');
            HPTiltLine = xline(axes_Tilt, HeatPulseRecord, '--k');
    
            S_HPLines = struct('HPLine', HPLine, 'HPBWTLine', ...
            HPBWTLine, 'HPDepthLine', HPDepthLine, 'HPTiltLine', HPTiltLine);
        else
            S_HPLines = struct();
        end
    
        EndLine = xline(axes_TempAboveBWT, EndRecord, '--k', ...
            'LabelHorizontalAlignment','left', 'FontWeight', 'bold', ...
            'FontSize', 16);
        EndLine.Label = 'End of Penetration';
        EndBWTLine = xline(axes_BottomWaterTemp, EndRecord, '--k');
        EndDepthLine = xline(axes_Depth, EndRecord, '--k');
        EndTiltLine = xline(axes_Tilt, EndRecord, '--k');
        drawnow;
    
        S_PenLines = struct('PenLine', PenLine, 'PenBWTLine', PenBWTLine, ...
            'PenDepthLine', ...
            PenDepthLine, 'PenTiltLine', PenTiltLine);
        S_EndPenLines = struct('EndLine', EndLine, 'EndBWTLine', EndBWTLine, ...
            'EndDepthLine', EndDepthLine, ...
            'EndTiltLine', EndTiltLine);
    
        S_Lines = struct('S_PenLines', S_PenLines, 'S_HPLines', S_HPLines, ...
            'S_EndPenLines', S_EndPenLines);
    
    % Link X axes of all four plots -- zooming or panning on one 
    % does the same to rest
    % --------------------------------------------------------------------
    
        % set x axis limits
        xlim(axes_TempAboveBWT, [(PenetrationRecord-5), (EndRecord+1)])
    
        % set y axis limits
        if HeatPulseRecord~=-999
            TempPreHP = AllSensorsTemp(AllRecords<HeatPulseRecord, :);
            ylim(axes_TempAboveBWT, [min(min(AllSensorsTemp)), ...
                max(max(TempPreHP))+0.75])
        else
            ylim(axes_TempAboveBWT, [min(min(AllSensorsTemp)), ...
                max(max(AllSensorsTemp))+0.75])
        end
    
    
    