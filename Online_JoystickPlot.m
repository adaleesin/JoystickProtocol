function figData=Online_JoystickPlot(action,figData,trialType,newxdata,ToneA,ToneB)

global BpodSystem



switch action
     case 'ini'
%% Create Figure
figPlot=figure('Name','Online action Plot','Position', [1000 100 600 800], 'numbertitle','off');
hold on;
ProtoSummary=sprintf('%s : %s -- %s',...
    date, BpodSystem.GUIData.SubjectName, ...
    BpodSystem.GUIData.ProtocolName)
MyBox = uicontrol('style','text')
set(MyBox,'String',ProtoSummary, 'Position',[10,1,500,20])

%% action plot
%PlotParameters
labely='Trials';
maxy=200;       %y axe for actions
ystep=25;       %y axe for actions
miny=0;                            
ytickvalues=miny:ystep:maxy;
labelx='Time from reward (sec)';
minx=-1;    
maxx=10;     
xstep=1;    
xtickvalues=minx:xstep:maxx;
    subPlotTitles={'A Rew', 'A Pun', 'B Rew','B Pun', 'AB Rew','AB Pun', 'BA Rew', 'BA Pun'}; 
% subplot
for i=1:8
    actionsubplot(i)=subplot(4,2,i);
    hold on;
    actionplot(i)=plot([0 0],[1,500],'sk','MarkerSize',1,'MarkerFaceColor','k'); hold on;
    ToneAplot(i)=plot([0 0],[1,500],'sr','MarkerSize',2,'MarkerFaceColor','r');
    ToneBplot(i)=plot([0 0],[1,500],'sb','MarkerSize',2,'MarkerFaceColor','b');
    set(actionplot(i), 'XData',[],'YData',[]);
    set(ToneAplot(i), 'XData',[],'YData',[]);
    set(ToneBplot(i), 'XData',[],'YData',[]);
    xlabel(labelx); 
    ylabel(labely);
    title(subPlotTitles(i));
    set(actionsubplot(i),'XLim',[minx maxx],'XTick',xtickvalues,'YLim',[miny maxy],'YTick',ytickvalues,'YDir', 'reverse');
end
% for i=3:4
%     actionsubplot(i)=subplot(4,2,i);
%     hold on;
%     rewplot(i)=plot([0 0],[-5,500],'-b');
%     actionplot(i)=plot([0 0],[1,500],'sk','MarkerSize',MS_actions,'MarkerFaceColor','k');
%     set(actionplot(i), 'XData',[],'YData',[]);
%     xlabel(labelx); 
%     ylabel(labely);
%     title(subPlotTitles(i));
%     set(actionsubplot(i),'XLim',[minx maxx],'XTick',xtickvalues,'YLim',[miny maxy],'YTick',ytickvalues,'YDir', 'reverse');
% end
% 
% for i=5:6
%     plot(i)=subplot(4,2,i);
%     hold on;
%     rewplot(i)=plot([0 0],[-5,500],'-r');
% %     rewplot(i)=plot([0.7 0.7],[-5,500],'-b'); 
%     actionplot(i)=plot([0 0],[1,500],'sk','MarkerSize',MS_actions,'MarkerFaceColor','k');
%     set(actionplot(i), 'XData',[],'YData',[]);
%     hold on;
%     Toneplot(i)=plot([0 0],[1,500],'sk','MarkerSize',MS_actions,'MarkerFaceColor','b');
%     set(Toneplot(i), 'XData',[],'YData',[]);
%     xlabel(labelx); 
%     ylabel(labely);
%     title(subPlotTitles(i));
%     set(actionsubplot(i),'XLim',[minx maxx],'XTick',xtickvalues,'YLim',[miny maxy],'YTick',ytickvalues,'YDir', 'reverse');
% end
% 
% for i=7:8
%     plot(i)=subplot(4,2,i);
%     hold on;
%     rewplot(i)=plot([0 0],[-5,500],'-b');
% %     rewplot(i)=plot([0.7 0.7],[-5,500],'-b'); 
%     actionplot(i)=plot([0 0],[1,500],'sk','MarkerSize',MS_actions,'MarkerFaceColor','k');
%     set(actionplot(i), 'XData',[],'YData',[]);
%     hold on;
%     Toneplot(i)=plot([0 0],[1,500],'sk','MarkerSize',MS_actions,'MarkerFaceColor','r');
%     set(Toneplot(i), 'XData',[],'YData',[]);
%     xlabel(labelx); 
%     ylabel(labely);
%     title(subPlotTitles(i));
%     set(actionsubplot(i),'XLim',[minx maxx],'XTick',xtickvalues,'YLim',[miny maxy],'YTick',ytickvalues,'YDir', 'reverse');
% end
% %Save the figure properties
figData.fig=figPlot;
figData.actionsubplot=actionsubplot;
figData.actionplot=actionplot;
figData.ToneAplot=ToneAplot;
figData.ToneBplot=ToneBplot;


    case 'update'
%% actionPlot
%Extract the previous data from the plot
i=trialType;
if i>0
%initialize the first raster
previous_xdata=get(figData.actionplot(i),'XData'); %action time
previous_ToneAdata=get(figData.ToneAplot(i),'XData'); %action time
previous_ToneBdata=get(figData.ToneBplot(i),'XData'); 
previous_ydata=get(figData.actionplot(i),'YData'); %trial number
previous_ToneAydata=get(figData.ToneAplot(i),'YData'); %trial number
previous_ToneBydata=get(figData.ToneBplot(i),'YData');

if isempty(previous_ydata)==1
    trialTypeCount=1; 
else
    trialTypeCount=max(previous_ydata)+1;
end

if isempty(previous_ToneAydata)==1
    trialTypeCountToneA=1; 
else
    trialTypeCountToneA=max(previous_ToneAydata)+1;
end

if isempty(previous_ToneBydata)==1
    trialTypeCountToneB=1; 
else
    trialTypeCountToneB=max(previous_ToneBydata)+1;
end

updated_xdata=[previous_xdata newxdata];
updated_ToneA=[previous_ToneAdata ToneA];
updated_ToneB=[previous_ToneBdata ToneB];
newydata=linspace(trialTypeCount,trialTypeCount,size(newxdata,2));
newToneAydata=linspace(trialTypeCountToneA,trialTypeCountToneA,size(ToneA,2));
newToneBydata=linspace(trialTypeCountToneB,trialTypeCountToneB,size(ToneB,2));
updated_ydata=[previous_ydata newydata];
updated_ToneAydata=[previous_ToneAydata newToneAydata];
updated_ToneBydata=[previous_ToneBydata newToneBydata];
set(figData.actionplot(i),'XData',updated_xdata,'YData',updated_ydata); 
set(figData.ToneAplot(i),'XData',updated_ToneA,'YData',updated_ToneAydata);
set(figData.ToneBplot(i),'XData',updated_ToneB,'YData',updated_ToneBydata);
end
end
end