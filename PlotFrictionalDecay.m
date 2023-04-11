%%% ==============================================================================
%   Purpose: 
%     This function plots each step of the frictional decay reduction.
%     Plots include Temperature vs. Time (s), Temperature vs. Dimensionless Time
%     (Tau), Temperature vs. Bullard Decay Function (F(alpha,tau)), and 
%     Residual Misfit (°C) vs. Time Shifts (s)
%%% ==============================================================================

function [h_axFricTempvTime, ...
        h_axFricTempvTau, ...
        h_axFricTempvTauPoints, ...
        h_axFricTempvTauLines, ...
        h_axFricRMSvTimeShift, ...
        h_axFricRMSvTimeShiftMinDelays ...
        ] = PlotFrictionalDecay(...
        h_axTempAboveBWT, ...
        axes_TempvTime, ...
        axes_TempvTau, ...
        axes_TempvBullFunc,...
        axes_TimeShift, ...
        grid_FricDecayAxes, ...
        SensorsToUse, ...
        ShiftedTime, ...
        IndexOfMinimums, ...
        DataTemp, ...
        FricTime, ...
        TimeShifts, ...
        ShiftedTau, ...
        FricTauMax, ...
        FricTauMin, ...
        DataFAT, ...
        DataLimits, ...
        b, ...
        a, ...
        MinimumFricEqTemp, ...
        RMS, ...
        MinimumFricDelays)


% ====================================== %
%                 PLOT                   %
% ====================================== %



% Reset all axes on frictional decay tab
% --------------------------------------
delete(axes_TempvTime.Children)
delete(axes_TempvTau.Children)
delete(axes_TempvBullFunc.Children)
delete(axes_TimeShift.Children)
grid_FricDecayAxes.RowHeight = {'1x', '1x'};
grid_FricDecayAxes.ColumnWidth = {'1x', '1x'};

axes_TempvTime.Color = [0.90 0.90 0.90];
axes_TempvTau.Color = [0.90 0.90 0.90];
axes_TempvBullFunc.Color = [0.90 0.90 0.90];
axes_TimeShift.Color = [0.90 0.90 0.90];

 % Plot Temperature vs. Time (s)
 % ------------------------------

 n=1;

 for i = SensorsToUse
     h_axFricTempvTime(i) = plot(axes_TempvTime, ShiftedTime(:,n,IndexOfMinimums(n)), ...
                DataTemp(:,n,IndexOfMinimums(n)),'-o','markersize',2, ...
        'Color',h_axTempAboveBWT(i).Color,'markerfacecolor',h_axTempAboveBWT(i).Color, 'tag', ['sensTemp_' num2str(i)]);
     hold(axes_TempvTime, 'on');
     n=n+1;
 end

      % Set labels and axes limits
      % --------------------------------------------------
        xlabel(axes_TempvTime, '\bfTime (s)','fontsize',16,'verticalalignment','top')
        ylabel(axes_TempvTime, '\bfTemperature ( ^oC)','fontsize',16,'verticalalignment','bottom')
        set(axes_TempvTime,'xlim',[FricTime(1)+min(min(TimeShifts)) ...
            FricTime(end)+max(max(TimeShifts))])

     % Lines indicating start and end of frictional decay
     % --------------------------------------------------
        xline(axes_TempvTime, FricTime(1), '--k', 'Label', 'Start of frictional decay', ...
         'FontSize',16, 'FontWeight', 'bold')
        xline(axes_TempvTime, FricTime(end), '--k', 'Label', 'End of frictional decay', ...
         'FontSize',16, 'FontWeight', 'bold')

 % Plot Temperature vs. Dimensionless Time (Tau)
 % ---------------------------------------------
    
 n=1;

  for i = SensorsToUse
     h_axFricTempvTau(i) = plot(axes_TempvTau, ShiftedTau(:,n,IndexOfMinimums(n)),...
         DataTemp(:,n,IndexOfMinimums(n)),'-o','markersize',2, ...
        'Color',h_axTempAboveBWT(i).Color,'markerfacecolor',h_axTempAboveBWT(i).Color, 'tag', ['sensTemp_' num2str(i)]);
     hold(axes_TempvTau, 'on');
     n=n+1;
 end

      % Set labels and axes limits
      % --------------------------------------------------
        xlabel(axes_TempvTau, '\tau','fontsize',18,'verticalalignment','top')
        ylabel(axes_TempvTau, '\bfTemperature ( ^oC)','fontsize',16,'verticalalignment','top')
        set(axes_TempvTau,'yaxislocation','right', 'XLim', [0 FricTauMax+1])
 
      % Lines indicating min and max of Tau (set by PAR file)
      % -----------------------------------------------------
        xline(axes_TempvTau, FricTauMin, '--k', 'Label', 'Minimum Tau', ...
            'FontSize',16, 'FontWeight', 'bold')
        xline(axes_TempvTau, FricTauMax, '--k', 'Label', 'Maximum Tau', ...
            'FontSize',16, 'FontWeight', 'bold')

 % Plot Temperature vs. Bullard Decay Function (F(alpha,tau))
 % ---------------------------------------------------------------
 n=1;

 for i = SensorsToUse
    h_axFricTempvTauPoints(i) = plot(axes_TempvBullFunc, DataFAT(:,n,IndexOfMinimums(n)),...
        DataTemp(:,n,IndexOfMinimums(n)),'d','markersize',2, ...
        'Color',h_axTempAboveBWT(i).Color,'markerfacecolor',h_axTempAboveBWT(i).Color, ...
        'tag', ['sensCorrectedTemp_' num2str(i)]);
     hold(axes_TempvBullFunc, 'on');
    h_axFricTempvTauLines(i) = plot(axes_TempvBullFunc, [0 DataFAT(DataLimits(1),n,IndexOfMinimums(n))],...
        b(n,IndexOfMinimums(n))*[0 DataFAT(DataLimits(1),n,IndexOfMinimums(n))] ...
        + a(n,IndexOfMinimums(n)), 'Color',h_axTempAboveBWT(i).Color,...
        'tag', ['sensBestFitLine_' num2str(i)]);

     n=n+1;

 end

      % Set labels
      % --------------------------------------------------
        xlabel(axes_TempvBullFunc, '\bfF(2,\rm\fontsize{18}\tau)\bf\fontsize{18}','fontsize',18,'verticalalignment','top')
        ylabel(axes_TempvBullFunc, '\bfTemperature ( ^oC)','fontsize',16,'verticalalignment','bottom')

      % Set plot limits -- not sure if this is necessary. does not do
      % anything to the penetration that I am testing with. maybe fixes
      % other ones?
      % ---------------------
        PlotLims = [0 ...
          max(diag(squeeze((DataFAT(DataLimits(1),:,IndexOfMinimums))))) ...
          min([MinimumFricEqTemp;min(min(min(DataTemp)))]) ...
          max([MinimumFricEqTemp;max(max(max(DataTemp)))])];
        
        PlotLims(2) = PlotLims(2)+PlotLims(2)/20;
        PlotLims(3) = PlotLims(3)-(PlotLims(4)-PlotLims(3))/20;
        PlotLims(4) = PlotLims(4)+(PlotLims(4)-PlotLims(3))/20;
        set(axes_TempvBullFunc,'xlim',PlotLims(1:2), ...
            'ylim',PlotLims(3:4))
        
 % Plot Residual Misfit (°C) vs. Time Shifts (s)
 % ---------------------------------------------------------------
    n=1;

    for i = SensorsToUse
        h_axFricRMSvTimeShift(i) = plot(axes_TimeShift, TimeShifts(:,n),...
            RMS(n,:),'-v','markersize',2, ...
            'Color',h_axTempAboveBWT(i).Color,'markerfacecolor',h_axTempAboveBWT(i).Color, ...
            'tag', ['sensCorrectedTemp_' num2str(i)]);
     
        hold(axes_TimeShift, 'on');

        h_axFricRMSvTimeShiftMinDelays(i) = xline(axes_TimeShift, MinimumFricDelays(n), ...
             'Color',h_axTempAboveBWT(i).Color, 'linestyle', '--', 'FontWeight','bold');
        n=n+1;
    end

          % Set labels and axes limits
          % ----------------------------
            xlabel(axes_TimeShift, '\bfTime Shifts (s)','fontsize',16,'verticalalignment','top')
            ylabel(axes_TimeShift, '\bfResidual Misfit ( ^oC)', ...
            'fontsize',16,'verticalalignment','top')
            set(axes_TimeShift,'yaxislocation','right','yscale','log')
