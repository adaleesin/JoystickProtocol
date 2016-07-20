function joystick_ada_2diections
% joystick_ada_2diections
% Ada LI, May30 2016

global BpodSystem

%% ******************************************
% % Training Level
TrainingLevel = 5 % option 1, 2 ,3, 4

switch TrainingLevel
    case 1 

        TrialTypeProbs = [1 0 0 0];   % Go A only
    case 2 

        TrialTypeProbs = [0 1 0 0];  % Go B only
    case 3 % task without air puff

        TrialTypeProbs= [0.5 0.5 0 0];  % trial types --- Go A, Go B,
    case 4 % task without air puff

        TrialTypeProbs= [0 0 0.5 0.5];  
    case 5 % task without air puff

        TrialTypeProbs= [0.25 0.25 0.25 0.25];  
end

%% Define parameters
S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
    S.SoundDuration = []; % Duration of sound1 (s)s)
    S.SoundRamping=0.3;         %sec
    S.MeanSoundFrequencyA = 500;   %Hz
    S.MeanSoundFrequencyB = 5000;  %Hz
    S.WidthOfFrequencies=2;
    S.NumberOfFrequencies=5;
    S.TrialTypeProbs=TrialTypeProbs;
    S.RewardAmount=8;
 end
%% Initialize parameter GUI plugin
BpodSystem.Data.Sequence = [];

%% Define stimuli and send to sound server
SF = 192000; % Sound card sampling rate
noise = randn(1, SF);  
Sound1=SoundGenerator(SF, S.MeanSoundFrequencyA, S.WidthOfFrequencies, S.NumberOfFrequencies, S.SoundDuration, S.SoundRamping);
Sound2=SoundGenerator(SF, S.MeanSoundFrequencyB, S.WidthOfFrequencies, S.NumberOfFrequencies, S.SoundDuration, S.SoundRamping);

% Program sound server
PsychToolboxSoundServer('init');
tmp1 = exprnd(1,MaxTrials,1);
tmp1(tmp1 > 6) = exprnd(1);
S.SoundDuration = tmp1 + 1; % type 1-- mean 2; offset 1; cutoff 6


PsychToolboxSoundServer('Load', 1, Sound1); %PsychToolboxSoundServer('load', SoundID, Waveform)
PsychToolboxSoundServer('Load', 2, Sound2); %Sounds are triggered by sending a soft code back to the governing computer 
                                            %from a trial's state matrix, and calling PsychToolboxSoundServer from a predetermined 
                                            %soft code handler function.
PsychToolboxSoundServer('Load', 3, noise); 
BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_PlaySound';



%% Define trials
if TrainingLevel <= 5
maxTrials = 5000;
S.TrialSequence = zeros(1,maxTrials);
for x = 1:maxTrials
    P = rand;
    Cutoffs = cumsum(S.TrialTypeProbs);
    Found = 0;
    for y = 1:length(S.TrialTypeProbs)
        if P<Cutoffs(y) && Found == 0
            Found = 1;
            S.TrialSequence(x) = y;
        end
    end
end

elseif TrainingLevel == 6 
maxTrials =600;    
S.TrialSequence = zeros(1,maxTrials);
S.TrialSequence(1:300)=1;
S.TrialSequence(301:600)=2;
else 
maxTrials = 600;    
S.TrialSequence = zeros(1,maxTrials);
S.TrialSequence(1:300)=2;
S.TrialSequence(301:600)=1;
end
TrialSequence=S.TrialSequence;

BpodSystem.ProtocolFigures.OutcomePlotFig = figure('Position', [50 1000 900 150],'Name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
BpodSystem.GUIHandles.OutcomePlot= axes('Position', [.075 .3 .89 .6]);
OutcomePlot_Joystick(BpodSystem.GUIHandles.OutcomePlot,'init',2-S.TrialSequence); 
FigAction_1=Online_JoystickPlot('ini');
FigAction_2=Online_ResponseCurve('ini');
%% Main trial loop
for currentTrial = 1:maxTrials

    disp(['Trial # ' num2str(currentTrial) ': trial type ' num2str(S.TrialSequence(currentTrial))]);
  
    WaterTime = GetValveTimes(S.RewardAmount,[1]); % This code gets the time valves 2 (valve code)must be open to deliver liquid being set. 
    PuffTime = 0.02;
    S.ReinforcementDelays(currentTrial) =rand;

    sma = NewStateMatrix();
    sma = AddState(sma, 'Name', 'Dummy1',...
        'Timer',0,...
        'StateChangeConditions',{'Tup','Dummy2'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'Dummy2',...
        'Timer',0,...
        'StateChangeConditions',{'Tup','DeliverStimulus'},...
        'OutputActions', {});
   if S.TrialSequence(currentTrial)==1    
    sma = AddState(sma, 'Name', 'DeliverStimulus',...
        'Timer',0.4,...
        'StateChangeConditions',{'Tup','ControlRunDelay'},...
        'OutputActions', {'SoftCode', 1,'WireState',4});
    sma = AddState(sma, 'Name', 'ControlRunDelay',...
        'Timer',S.ReinforcementDelays(currentTrial),...
        'StateChangeConditions', {'BNC1High', 'DeliverNoise','BNC2High', 'DeliverNoise','Tup','WaitForRun'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'WaitForRun', ...
        'Timer',5,...
        'StateChangeConditions', {'Tup', 'TimeOut','BNC1High','DeliverReward','BNC2High','DeliverPunish'},...
        'OutputActions', {'PWM3', 255,'WireState', 1});
    elseif S.TrialSequence(currentTrial)==2 
    sma = AddState(sma, 'Name', 'DeliverStimulus',...
        'Timer',0.4,...
        'StateChangeConditions',{'Tup','ControlRunDelay'},...
        'OutputActions', {'SoftCode', 2,'WireState',8});
    sma = AddState(sma, 'Name', 'ControlRunDelay', ...
        'Timer',S.ReinforcementDelays(currentTrial),...
        'StateChangeConditions', {'BNC1High', 'DeliverNoise','BNC2High', 'DeliverNoise','Tup','WaitForRun'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'WaitForRun', ...
            'Timer',5,...
            'StateChangeConditions', {'Tup', 'TimeOut','BNC2High','DeliverReward','BNC1High','DeliverPunish'},...
            'OutputActions', {'PWM3', 255,'WireState', 2});
    elseif S.TrialSequence(currentTrial)==3 
    sma = AddState(sma, 'Name', 'DeliverStimulus',...
        'Timer',0.4,...
        'StateChangeConditions',{'Tup','ISI'},...
        'OutputActions', {'SoftCode', 1,'WireState',4});
    sma = AddState(sma, 'Name', 'ISI',...
        'Timer',0.3,...
        'StateChangeConditions',{'Tup','DeliverStimulusAgain'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'DeliverStimulusAgain',...
        'Timer',0.4,...
        'StateChangeConditions',{'Tup','ControlRunDelay'},...
        'OutputActions', {'SoftCode', 2,'WireState',8});
    sma = AddState(sma, 'Name', 'ControlRunDelay', ...
        'Timer',S.ReinforcementDelays(currentTrial),...
        'StateChangeConditions', {'BNC1High', 'DeliverNoise','BNC2High', 'DeliverNoise','Tup','WaitForRun'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'WaitForRun', ...
            'Timer',5,...
            'StateChangeConditions', {'Tup', 'TimeOut','BNC2High','DeliverReward','BNC1High','DeliverPunish'},...
            'OutputActions', {'PWM3', 255,'WireState', 2});
    elseif S.TrialSequence(currentTrial)==4 
    sma = AddState(sma, 'Name', 'DeliverStimulus',...
        'Timer',0.4,...
        'StateChangeConditions',{'Tup','ISI'},...
        'OutputActions', {'SoftCode', 2,'WireState',8});
    sma = AddState(sma, 'Name', 'ISI',...
        'Timer',0.3,...
        'StateChangeConditions',{'Tup','DeliverStimulusAgain'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'DeliverStimulusAgain',...
        'Timer',0.4,...
        'StateChangeConditions',{'Tup','ControlRunDelay'},...
        'OutputActions', {'SoftCode', 1,'WireState',4});
    sma = AddState(sma, 'Name', 'ControlRunDelay', ...
        'Timer',S.ReinforcementDelays(currentTrial),...
        'StateChangeConditions', {'BNC1High', 'DeliverNoise','BNC2High', 'DeliverNoise','Tup','WaitForRun'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'WaitForRun', ...
            'Timer',5,...
            'StateChangeConditions', {'Tup', 'TimeOut','BNC1High','DeliverReward','BNC2High','DeliverPunish'},...
            'OutputActions', {'PWM3', 255,'WireState', 1});
   end 
      
    sma = AddState(sma, 'Name', 'DeliverNoise', ...
        'Timer',0.5,...
        'StateChangeConditions', {'Tup', 'ITI'}, ...
        'OutputActions', {'SoftCode', 3}); 
    sma = AddState(sma, 'Name', 'ITI', ...
        'Timer',5,...
        'StateChangeConditions', {'Tup', 'exit'}, ...
        'OutputActions', {'BNCState',1}); 
    sma = AddState(sma, 'Name', 'DeliverPunish', ...
        'Timer',PuffTime,...
        'StateChangeConditions', {'Tup', 'ITI'}, ...
        'OutputActions', {'ValveState', 2});
    sma = AddState(sma,'Name', 'DeliverReward', ...
        'Timer',WaterTime, ...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {'ValveState', 1});
    sma = AddState(sma, 'Name', 'TimeOut', ...
        'Timer',0.5,...
        'StateChangeConditions', {'Tup', 'ITI'}, ...
        'OutputActions', {'PWM1', 255'}); 

    
    SendStateMatrix(sma);
    RawEvents = RunStateMatrix;
    if ~isempty(fieldnames(RawEvents)) % If trial data was returned
    BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents);
    BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
    BpodSystem.Data.Sequence(currentTrial) = TrialSequence(currentTrial); 
    UpdateOutcomePlot(S.TrialSequence, BpodSystem.Data);                             
    SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file  
    end
    [PlotIndex,TrialType,Response_events,DelayTime,ResponseTime]=UpdateOnlineEvent(BpodSystem.Data);
    FigAction_1=Online_JoystickPlot('update',FigAction_1,TrialType,Response_events); 
    FigAction_2=Online_ResponseCurve('update',FigAction_2,PlotIndex,DelayTime,ResponseTime); 
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes. 
    if BpodSystem.BeingUsed == 0
    return
    end
end



%---------------------------------------- /MAIN LOOP

function [PlotIndex,TrialType,Response_events,DelayTime,ResponseTime]=UpdateOnlineEvent(Data)

switch Data.Sequence(end)
    case 1
        if ~isnan(Data.RawEvents.Trial{end}.States.DeliverReward(1))
            TrialType= 1;
            PlotIndex=1;
            Response_events=Data.RawEvents.Trial{end}.Events.BNC1High-Data.RawEvents.Trial{end}.States.Dummy2(2);
            DelayTime=Data.RawEvents.Trial{end}.States.ControlRunDelay(2)-Data.RawEvents.Trial{end}.States.ControlRunDelay(1);
            ResponseTime=Data.RawEvents.Trial{end}.States.DeliverReward(1)-Data.RawEvents.Trial{end}.States.ControlRunDelay(2);
        elseif ~isnan(Data.RawEvents.Trial{end}.States.DeliverPunish(1))
            TrialType= 3;
            PlotIndex=0;
            Response_events=Data.RawEvents.Trial{end}.Events.BNC2High-Data.RawEvents.Trial{end}.States.Dummy2(2);     
            DelayTime=0;
            ResponseTime=0;
        else
            TrialType= 0;
            PlotIndex=0;
            Response_events=[66];
            DelayTime=0;
            ResponseTime=0;
%         elseif ~isnan(Data.RawEvents.Trial{end}.States.DeliverNoise(1))
%             TrialType= 5;
%             DelayTime=0;
%             ResponseTime=0;
%             try
%             Response_events=[Data.RawEvents.Trial{end}.Events.BNC1High Data.RawEvents.Trial{end}.Events.BNC2High];
%             catch
%             try Response_events=Data.RawEvents.Trial{end}.Events.BNC1High;
%             catch
%             Response_events=Data.RawEvents.Trial{end}.Events.BNC2High;
%             end
%             end
%         else
%             TrialType= 0;
%             Response_events=[66];
%             DelayTime=0;
%             ResponseTime=0;
        end
    case 2

        if ~isnan(Data.RawEvents.Trial{end}.States.DeliverReward(1))
            TrialType= 2;
            PlotIndex=2;
            Response_events=Data.RawEvents.Trial{end}.Events.BNC2High-Data.RawEvents.Trial{end}.States.Dummy2(2);
            DelayTime=Data.RawEvents.Trial{end}.States.ControlRunDelay(2)-Data.RawEvents.Trial{end}.States.ControlRunDelay(1);
            ResponseTime=Data.RawEvents.Trial{end}.States.DeliverReward(1)-Data.RawEvents.Trial{end}.States.ControlRunDelay(2);
        elseif ~isnan(Data.RawEvents.Trial{end}.States.DeliverPunish(1))
            TrialType= 4;
            PlotIndex=0;
            Response_events=Data.RawEvents.Trial{end}.Events.BNC1High-Data.RawEvents.Trial{end}.States.Dummy2(2);
            DelayTime=0;
            ResponseTime=0;
        else
            TrialType= 0;
            PlotIndex=0;
            Response_events=[66];
            DelayTime=0;
            ResponseTime=0;
%         elseif ~isnan(Data.RawEvents.Trial{end}.States.DeliverNoise(1))
%             TrialType= 6;
%             DelayTime=0;
%             ResponseTime=0;
%             try
%             Response_events=[Data.RawEvents.Trial{end}.Events.BNC1High Data.RawEvents.Trial{end}.Events.BNC2High];
%             catch
%             try Response_events=Data.RawEvents.Trial{end}.Events.BNC1High;
%             catch
%             Response_events=Data.RawEvents.Trial{end}.Events.BNC2High;
%             end
%             end
%         else
%             TrialType=0;
%             Response_events=[66];
%             DelayTime=0;
%             ResponseTime=0;
        end
     case 3

        if ~isnan(Data.RawEvents.Trial{end}.States.DeliverReward(1))
            TrialType= 5;
            PlotIndex=3;
            Response_events=Data.RawEvents.Trial{end}.Events.BNC2High-Data.RawEvents.Trial{end}.States.Dummy2(2);
            DelayTime=Data.RawEvents.Trial{end}.States.ControlRunDelay(2)-Data.RawEvents.Trial{end}.States.ControlRunDelay(1);
            ResponseTime=Data.RawEvents.Trial{end}.States.DeliverReward(1)-Data.RawEvents.Trial{end}.States.ControlRunDelay(2);
        elseif ~isnan(Data.RawEvents.Trial{end}.States.DeliverPunish(1))
            TrialType= 7;
            PlotIndex=0;
            Response_events=Data.RawEvents.Trial{end}.Events.BNC1High-Data.RawEvents.Trial{end}.States.Dummy2(2);
            DelayTime=0;
            ResponseTime=0;
         else
            TrialType= 0;
            PlotIndex=0;
            Response_events=[66];
            DelayTime=0;
            ResponseTime=0;
%         elseif ~isnan(Data.RawEvents.Trial{end}.States.DeliverNoise(1))
%             TrialType= 6;
%             DelayTime=0;
%             ResponseTime=0;
%             try
%             Response_events=[Data.RawEvents.Trial{end}.Events.BNC1High Data.RawEvents.Trial{end}.Events.BNC2High];
%             catch
%             try Response_events=Data.RawEvents.Trial{end}.Events.BNC1High;
%             catch
%             Response_events=Data.RawEvents.Trial{end}.Events.BNC2High;
%             end
%             end
%         else
%             TrialType=0;
%             Response_events=[66];
%             DelayTime=0;
%             ResponseTime=0;
        end
     case 4
        if ~isnan(Data.RawEvents.Trial{end}.States.DeliverReward(1))
            TrialType= 6;
            PlotIndex=4;
            Response_events=Data.RawEvents.Trial{end}.Events.BNC1High-Data.RawEvents.Trial{end}.States.Dummy2(2);
            DelayTime=Data.RawEvents.Trial{end}.States.ControlRunDelay(2)-Data.RawEvents.Trial{end}.States.ControlRunDelay(1);
            ResponseTime=Data.RawEvents.Trial{end}.States.DeliverReward(1)-Data.RawEvents.Trial{end}.States.ControlRunDelay(2);
        elseif ~isnan(Data.RawEvents.Trial{end}.States.DeliverPunish(1))
            TrialType= 8;
            PlotIndex=0;
            Response_events=Data.RawEvents.Trial{end}.Events.BNC2High-Data.RawEvents.Trial{end}.States.Dummy2(2);
            DelayTime=0;
            ResponseTime=0;
        else
            TrialType= 0;
            PlotIndex=0;
            Response_events=[66];
            DelayTime=0;
            ResponseTime=0;
%         elseif ~isnan(Data.RawEvents.Trial{end}.States.DeliverNoise(1))
%             TrialType= 5;
%             DelayTime=0;
%             ResponseTime=0;
%             try
%             Response_events=[Data.RawEvents.Trial{end}.Events.BNC1High Data.RawEvents.Trial{end}.Events.BNC2High];
%             catch
%             try Response_events=Data.RawEvents.Trial{end}.Events.BNC1High;
%             catch
%             Response_events=Data.RawEvents.Trial{end}.Events.BNC2High;
%             end
%             end
%         else
%             TrialType= 0;
%             Response_events=[66];
%             DelayTime=0;
%             ResponseTime=0;
        end
end




function UpdateOutcomePlot(TrialSequence, Data)
global BpodSystem
Outcomes = zeros(1,Data.nTrials);
for x = 1:Data.nTrials
    if ~isnan(Data.RawEvents.Trial{x}.States.DeliverReward(1))
        Outcomes(x) = 1;
    elseif ~isnan(Data.RawEvents.Trial{x}.States.DeliverPunish(1))
         Outcomes(x) = 0;
    elseif ~isnan(Data.RawEvents.Trial{x}.States.DeliverNoise(1))
         Outcomes(x) = 2;
    else
        Outcomes(x) = 3;
    end
end
OutcomePlot_Joystick(BpodSystem.GUIHandles.OutcomePlot,'update',Data.nTrials+1,2-TrialSequence,Outcomes);


