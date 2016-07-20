function figData=Online_ResponseCurve(action,figData,PlotIndex,newxdata,newydata)

global BpodSystem

switch action
     case 'ini'
%% Create Figure
figPlot=figure('Name','Online action Plot','Position', [300 400 600 600], 'numbertitle','off');
hold on;
ProtoSummary=sprintf('%s : %s -- %s',...
    date, BpodSystem.GUIData.SubjectName, ...
    BpodSystem.GUIData.ProtocolName)
MyBox = uicontrol('style','text')
set(MyBox,'String',ProtoSummary, 'Position',[10,1,500,20])

%% action plot
%PlotParameters
labely='ResponseTime (sec)';
miny=-2;              
maxy=5;
ystep=1;
ytickvalues=miny:ystep:maxy;
labelx='ToneLength (sec)';
minx=0;    
maxx=2;     
xstep=0.5;    
xtickvalues=minx:xstep:maxx;
    subPlotTitles={'A Planning', 'B Planning' 'AB Replanning' 'BA Replanning'}; 
% subplot
for i=1:4
    actionsubplot(i)=subplot(2,2,i);
    hold on;
    actionplot(i)=scatter([0 0],[0 0],'fill');
    set(actionplot(i), 'XData',[],'YData',[]);
    xlabel(labelx); 
    ylabel(labely);
    title(subPlotTitles(i));
    set(actionsubplot(i),'XLim',[minx maxx],'XTick',xtickvalues,'YLim',[miny maxy],'YTick',ytickvalues);
end


%Save the figure properties
figData.fig=figPlot;
figData.actionsubplot=actionsubplot;
figData.actionplot=actionplot;


    case 'update'
%% actionPlot
%Extract the previous data from the plot
i=PlotIndex;
if i>0
%initialize the first raster
previous_xdata=get(figData.actionplot(i),'XData'); %action time
previous_ydata=get(figData.actionplot(i),'YData'); %trial number

% if isempty(previous_ydata)==1
%     trialTypeCount=1; 
% else
%     trialTypeCount=max(previous_ydata)+1;
% end

updated_xdata=[previous_xdata newxdata];
updated_ydata=[previous_ydata newydata];
set(figData.actionplot(i),'XData',updated_xdata,'YData',updated_ydata);
end
end
end