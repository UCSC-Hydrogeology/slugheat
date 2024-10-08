
%%% ==============================================================================
%% 	Purpose: 
%	    This function plots results from the heat flow regression analysis.
%	    Plots include Number of Sensors Used vs. Heat FLow, Number of 
%       Sensors Used vs. Scatter, Number of Sensors Used vs. Sigma Heat
%       FLow, and Number of Sensors Used vs. Sigma Scatter 
%% Last edit:
%       03/11/2024 by Kristin Dickerson, UCSC
%%% ==============================================================================

function [HFLine, ...
        ScatterLine, ...
        SigmaHFLine, ...
        SigmaScatterLine] = PlotHeatFlowRegression(axes_HeatFlow, ...
            axes_Sigma, ...
            SensorsUsedForBullardFit, ...
            ScatterHeatFlow, ...
            Scatter, ...
            Sigmab)


% ====================================== %
%                 PLOT                   %
% ====================================== %
    NumberOfSensors = length(SensorsUsedForBullardFit);
    
        fit = length(ScatterHeatFlow);
    
% Number of Sensors Used vs. Heat FLow (left) 
%                   and
% Number of Sensors Used vs. Scatter (right)
% ------------------------------------------
        yyaxis(axes_HeatFlow, 'left') 
        HFLine = plot(axes_HeatFlow, 1:fit, ScatterHeatFlow, 'd-', 'LineWidth',1);
        ylabel(axes_HeatFlow, '\bf \fontsize{14} Heat Flow (mW/m^{2})')
        yyaxis(axes_HeatFlow, 'right') 
        ScatterLine = plot(axes_HeatFlow, 1:fit, Scatter, '*-', 'LineWidth',1);
        ylabel(axes_HeatFlow, '\bf \fontsize{14} Scatter')
    
        axes_HeatFlow.XTick = 1:fit;
        axes_HeatFlow.XTickLabel = NumberOfSensors-fit+1:NumberOfSensors;
        axes_HeatFlow.XLabel.String = '\bf \fontsize{14} Number of Sensors Used';
    
        drawnow;
        pause(1);

    
% Number of Sensors Used vs. Sigma Heat FLow (left) 
%                   and
% Number of Sensors Used vs. Sigma Scatter (right)
% ------------------------------------------
        yyaxis(axes_Sigma, 'left') 
        SigmaHFLine = plot(axes_Sigma, 1:fit, Sigmab, 'd-', 'LineWidth',1);
        ylabel(axes_Sigma, '\bf \fontsize{14} Standard deviation (\fontsize{16}\sigma\fontsize{12}\bf_{HF}) (mW/m^{2})')
        yyaxis(axes_Sigma, 'right') 
        SigmaScatterLine = plot(axes_Sigma, 1:fit, Sigmab.*Scatter/max(Sigmab.*Scatter), '*-', 'LineWidth',1);
        ylabel(axes_Sigma, '\fontsize{14}\sigma\fontsize{12}\bf_{HF} \rmx\bf Scatter \fontsize{11}\rm(normalized)')
    
        axes_Sigma.XTick = 1:fit;
        axes_Sigma.XTickLabel = NumberOfSensors-fit+1:NumberOfSensors;
        axes_Sigma.XLabel.String = '\bf \fontsize{14} Number of Sensors Used';
    
        drawnow;
        pause(1);


    