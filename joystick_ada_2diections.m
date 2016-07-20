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
    S.SoundDuration1 = []; % Duration of sound1 (s)s)
    S.SoundDuration2 = []; % Duration of sound2 (s)
    S.SoundRamping=0.3;         %sec
    S.MeanSoundFrequencyA = 500;   %Hz
    S.MeanSoundFrequencyB = 5000;  %Hz
    S.WidthOfFrequencies=2;
    S.NumberOfFrequencies=5;
    S.TrialTypeProbs=TrialTypeProbs;
    S.RewardAmount=8;
end
BpodSystem.Data.Sequence = [];


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

%% Define stimuli and send to sound server
SF = 192000; % Sound card sampling rate
noise = randn(1, SF);  
PsychToolboxSoundServer('init');
BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_PlaySound';
tmp1 = exprnd(0.5,maxTrials,1);
tmp1(tmp1 > 2) = exprnd(0.5);
S.SoundDuration1 = tmp1 + 0.5; % type 1-- mean 2; offset 1; cutoff 6
tmp2 = exprnd(0.5,maxTrials,1);
tmp2(tmp2 > 2) = exprnd(0.5);
S.SoundDuration2 = tmp2 + 0.5; % type 1-- mean 2; offset 1; cutoff 6
PsychToolboxSoundServer('Load', 3, noise); 

%% Online plot
BpodSystem.ProtocolFigures.OutcomePlotFig = figure('Position', [50 1000 900 150],'Name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
BpodSystem.GUIHandles.OutcomePlot= axes('Position', [.075 .3 .89 .6]);
OutcomePlot_Joystick(BpodSystem.GUIHandles.OutcomePlot,'init',2-S.TrialSequence); 
FigAction_1=Online_JoystickPlot('ini');
FigAction_2=Online_ResponseCurve('ini');

%% Main trial loop
for currentTrial = 1:maxTrials

    disp(['Trial # ' num2str(currentTrial) ': trial type ' num2str(S.TrialSequence(currentTrial))]);
          
    Sound1=SoundGenerator(SF, S.MeanSoundFrequencyA, S.WidthOfFrequencies, S.NumberOfFrequencies, S.SoundDuration1(currentTrial), S.SoundRamping);
    S.StimulusDuration1 = S.SoundDuration1(currentTrial);
    PsychToolboxSoundServer('Load', 1, Sound1);  

    Sound2=SoundGenerator(SF, S.MeanSoundFrequencyB, S.WidthOfFrequencies, S.NumberOfFrequencies, S.SoundDuration2(currentTrial), S.SoundRamping);
    S.StimulusDuration2 = S.SoundDuration2(currentTrial);
    PsychToolboxSoundServer('Load', 2, Sound2);

    WaterTime = GetValveTimes(S.RewardAmount,[1]); % This code gets the time valves 2 (valve code)must be open to deliver liquid being set. 
    PuffTime = 0.04;
    
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
    sma = AddState(sma, 'Name', 'DeliverStimulus', ...
        'Timer', 0,...
        'StateChangeConditions', {'Tup', 'StimulusDelay'},...
        'OutputActions',{'SoftCode',1});
    sma = AddState(sma, 'Name', 'StimulusDelay',...
        'Timer',S.StimulusDuration1,...
        'StateChangeConditions',{'BNC1High', 'TriggerNoise','BNC2High', 'TriggerNoise','Tup','WaitForRun'},...
        'OutputActions', {'WireState',4});
    sma = AddState(sma, 'Name', 'WaitForRun', ...
        'Timer',5,...
        'StateChangeConditions', {'Tup', 'TimeOut','BNC1High','DeliverReward','BNC2High','DeliverPunish'},...
        'OutputActions', {'WireState', 1});
    elseif S.TrialSequence(currentTrial)==2 
    sma = AddState(sma, 'Name', 'DeliverStimulus',...
        'Timer',0,...
        'StateChangeConditions',{'Tup','StimulusDelay'},...
        'OutputActions', {'SoftCode', 2});
    sma = AddState(sma, 'Name', 'StimulusDelay',...
        'Timer',S.StimulusDuration2,...
        'StateChangeConditions',{'BNC1High', 'TriggerNoise','BNC2High', 'TriggerNoise','Tup','WaitForRun'},...
        'OutputActions', {'WireState',8});
    sma = AddState(sma, 'Name', 'WaitForRun', ...
            'Timer',5,...
            'StateChangeConditions', {'Tup', 'TimeOut','BNC2High','DeliverReward','BNC1High','DeliverPunish'},...
            'OutputActions', {'WireState', 2});
    elseif S.TrialSequence(currentTrial)==3 
    sma = AddState(sma, 'Name', 'DeliverStimulus',...
        'Timer',0,...
        'StateChangeConditions',{'Tup','StimulusDelay1'},...
        'OutputActions', {'SoftCode', 1});
    sma = AddState(sma, 'Name', 'StimulusDelay1',...
        'Timer',S.StimulusDuration1,...
        'StateChangeConditions',{'BNC1High', 'TriggerNoise','BNC2High', 'TriggerNoise','Tup','DeliverStimulus2'},...
        'OutputActions', {'WireState',4});
    sma = AddState(sma, 'Name', 'DeliverStimulus2',...
        'Timer',0,...
        'StateChangeConditions',{'Tup','StimulusDelay2'},...
        'OutputActions', {'SoftCode', 2});
    sma = AddState(sma, 'Name', 'StimulusDelay2', ...
        'Timer',S.StimulusDuration2,...
        'StateChangeConditions', {'BNC1High', 'TriggerNoise','BNC2High', 'TriggerNoise','Tup','WaitForRun'},...
        'OutputActions', {'WireState',8});
    sma = AddState(sma, 'Name', 'WaitForRun', ...
            'Timer',5,...
            'StateChangeConditions', {'Tup', 'TimeOut','BNC2High','DeliverReward','BNC1High','DeliverPunish'},...
            'OutputActions', {'WireState', 2});
    elseif S.TrialSequence(currentTrial)==4 
    sma = AddState(sma, 'Name', 'DeliverStimulus',...
        'Timer',0,...
        'StateChangeConditions',{'Tup','StimulusDelay1'},...
        'OutputActions', {'SoftCode', 2});
    sma = AddState(sma, 'Name', 'StimulusDelay1',...
        'Timer',S.StimulusDuration2,...
        'StateChangeConditions',{'BNC1High', 'TriggerNoise','BNC2High', 'TriggerNoise','Tup','DeliverStimulus2'},...
        'OutputActions', {'WireState',8});
    sma = AddState(sma, 'Name', 'DeliverStimulus2',...
        'Timer',0,...
        'StateChangeConditions',{'Tup','StimulusDelay2'},...
        'OutputActions', {'SoftCode', 1});
    sma = AddState(sma, 'Name', 'StimulusDelay2', ...
        'Timer',S.StimulusDuration1,...
        'StateChangeConditions', {'BNC1High', 'TriggerNoise','BNC2High', 'TriggerNoise','Tup','WaitForRun'},...
        'OutputActions', {'WireState',4});
    sma = AddState(sma, 'Name', 'WaitForRun', ...
            'Timer',5,...
            'StateChangeConditions', {'Tup', 'TimeOut','BNC1High','DeliverReward','BNC2High','DeliverPunish'},...
            'OutputActions', {'WireState', 1});

   end 
      
    sma = AddState(sma, 'Name', 'TriggerNoise', ...
        'Timer',0,...
        'StateChangeConditions', {'Tup', 'DeliverNoise'}, ...
        'OutputActions', {'SoftCode', 255}); 
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
        'Timer',1,...
        'StateChangeConditions', {'Tup', 'ITI'}, ...
        'OutputActions', {'PWM3', 255'}); 

    
    SendStateMatrix(sma);
    RawEvents = RunStateMatrix;
    if ~isempty(fieldnames(RawEvents)) % If trial data was returned
    BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents);
    BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
    BpodSystem.Data.Sequence(currentTrial) = TrialSequence(currentTrial); 
    UpdateOutcomePlot(S.TrialSequence, BpodSystem.Data);                             
    SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file  
    end
    [PlotIndex,TrialType,Response_events,DelayTime,ResponseTime,ToneATime,ToneBTime]=UpdateOnlineEvent(BpodSystem.Data);
    FigAction_1=Online_JoystickPlot('update',FigAction_1,TrialType,Response_events,ToneATime,ToneBTime); 
    FigAction_2=Online_ResponseCurve('update',FigAction_2,PlotIndex,DelayTime,ResponseTime); 
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes. 
    if BpodSystem.BeingUsed == 0
    return
    end
end



%---------------------------------------- /MAIN LOOP

function [PlotIndex,TrialType,Response_events,DelayTime,ResponseTime,ToneATime,ToneBTime]=UpdateOnlineEvent(Data)

switch Data.Sequence(end)
    case 1
        if ~isnan(Data.RawEvents.Trial{end}.States.DeliverReward(1))
            TrialType= 1;
            PlotIndex=1;
            Response_events=Data.RawEvents.Trial{end}.Events.BNC1High-Data.RawEvents.Trial{end}.States.Dummy2(2);
            DelayTime=Data.RawEvents.Trial{end}.States.StimulusDelay(2)-Data.RawEvents.Trial{end}.States.StimulusDelay(1);
            ToneATime=Data.RawEvents.Trial{end}.States.StimulusDelay(2)-Data.RawEvents.Trial{end}.States.StimulusDelay(1);
            ToneBTime=[66];
            ResponseTime=Data.RawEvents.Trial{end}.States.DeliverReward(1)-Data.RawEvents.Trial{end}.States.StimulusDelay(2);
        elseif ~isnan(Data.RawEvents.Trial{end}.States.DeliverPunish(1))
            TrialType= 2;
            PlotIndex=0;
            Response_events=Data.RawEvents.Trial{end}.Events.BNC2High-Data.RawEvents.Trial{end}.States.Dummy2(2);     
            DelayTime=0;
            ResponseTime=0;
            ToneATime=Data.RawEvents.Trial{end}.States.StimulusDelay(2)-Data.RawEvents.Trial{end}.States.StimulusDelay(1);
            ToneBTime=[66];
        elseif ~isnan(Data.RawEvents.Trial{end}.States.DeliverNoise(1))
            TrialType= 0;
            PlotIndex=1;
            Response_events=[66];
            DelayTime=Data.TrialSettings(1,end).StimulusDuration1;
            ToneATime=0;
            ToneBTime=[66];
            ResponseTime=Data.RawEvents.Trial{end}.States.DeliverNoise(1)-Data.RawEvents.Trial{end}.States.StimulusDelay(1)-Data.TrialSettings(1,end).StimulusDuration1;
        else
            TrialType= 0;
            PlotIndex=0;
            Response_events=[66];
            DelayTime=0;
            ResponseTime=0;
            ToneATime=0;
            ToneBTime=[66];
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
            TrialType= 3;
            PlotIndex=2;
            Response_events=Data.RawEvents.Trial{end}.Events.BNC2High-Data.RawEvents.Trial{end}.States.Dummy2(2);
            DelayTime=Data.RawEvents.Trial{end}.States.StimulusDelay(2)-Data.RawEvents.Trial{end}.States.StimulusDelay(1);
            ResponseTime=Data.RawEvents.Trial{end}.States.DeliverReward(1)-Data.RawEvents.Trial{end}.States.StimulusDelay(2);
            ToneBTime=Data.RawEvents.Trial{end}.States.StimulusDelay(2)-Data.RawEvents.Trial{end}.States.StimulusDelay(1);
            ToneATime=[66];
        elseif ~isnan(Data.RawEvents.Trial{end}.States.DeliverPunish(1))
            TrialType= 4;
            PlotIndex=0;
            Response_events=Data.RawEvents.Trial{end}.Events.BNC1High-Data.RawEvents.Trial{end}.States.Dummy2(2);
            DelayTime=0;
            ResponseTime=0;
            ToneBTime=Data.RawEvents.Trial{end}.States.StimulusDelay(2)-Data.RawEvents.Trial{end}.States.StimulusDelay(1);
            ToneATime=[66];
        elseif ~isnan(Data.RawEvents.Trial{end}.States.DeliverNoise(1))
            TrialType= 0;
            PlotIndex=2;
            Response_events=[66];
            DelayTime=Data.TrialSettings(1,end).StimulusDuration2;
            ToneATime=[66];
            ToneBTime=0;
            ResponseTime=Data.RawEvents.Trial{end}.States.DeliverNoise(1)-Data.RawEvents.Trial{end}.States.StimulusDelay(1)-Data.TrialSettings(1,end).StimulusDuration2;
        else
            TrialType= 0;
            PlotIndex=0;
            Response_events=[66];
            DelayTime=0;
            ResponseTime=0;
            ToneBTime=0;
            ToneATime=[66];
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
            DelayTime=Data.RawEvents.Trial{end}.States.StimulusDelay2(2)-Data.RawEvents.Trial{end}.States.StimulusDelay2(1);
            ResponseTime=Data.RawEvents.Trial{end}.States.DeliverReward(1)-Data.RawEvents.Trial{end}.States.StimulusDelay2(2);
            ToneATime=Data.RawEvents.Trial{end}.States.StimulusDelay1(2)-Data.RawEvents.Trial{end}.States.StimulusDelay1(1);
            ToneBTime=Data.RawEvents.Trial{end}.States.StimulusDelay2(2)-Data.RawEvents.Trial{end}.States.StimulusDelay1(1);
        elseif ~isnan(Data.RawEvents.Trial{end}.States.DeliverPunish(1))
            TrialType= 6;
            PlotIndex=0;
            Response_events=Data.RawEvents.Trial{end}.Events.BNC1High-Data.RawEvents.Trial{end}.States.Dummy2(2);
            DelayTime=0;
            ResponseTime=0;
            ToneATime=Data.RawEvents.Trial{end}.States.StimulusDelay1(2)-Data.RawEvents.Trial{end}.States.StimulusDelay1(1);
            ToneBTime=Data.RawEvents.Trial{end}.States.StimulusDelay2(2)-Data.RawEvents.Trial{end}.States.StimulusDelay1(1);
        elseif ~isnan(Data.RawEvents.Trial{end}.States.DeliverNoise(1))
            TrialType= 0;
            PlotIndex=3;
            Response_events=[66];
            ToneATime=0;
            ToneBTime=[66];
            try
            DelayTime=Data.TrialSettings(1,end).StimulusDuration1;
            ResponseTime=Data.RawEvents.Trial{end}.States.DeliverNoise(1)-Data.RawEvents.Trial{end}.States.StimulusDelay1(1)-Data.TrialSettings(1,end).StimulusDuration1;
            catch
            DelayTime=Data.TrialSettings(1,end).StimulusDuration2;
            ResponseTime=Data.RawEvents.Trial{end}.States.DeliverNoise(1)-Data.RawEvents.Trial{end}.States.StimulusDelay2(1)-Data.TrialSettings(1,end).StimulusDuration2;
            end
         else
            TrialType= 0;
            PlotIndex=0;
            Response_events=[66];
            DelayTime=0;
            ResponseTime=0;
            ToneATime=0;
            ToneBTime=[66];
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
            TrialType= 7;
            PlotIndex=4;
            Response_events=Data.RawEvents.Trial{end}.Events.BNC1High-Data.RawEvents.Trial{end}.States.Dummy2(2);
            DelayTime=Data.RawEvents.Trial{end}.States.StimulusDelay2(2)-Data.RawEvents.Trial{end}.States.StimulusDelay2(1);
            ResponseTime=Data.RawEvents.Trial{end}.States.DeliverReward(1)-Data.RawEvents.Trial{end}.States.StimulusDelay2(2);
            ToneBTime=Data.RawEvents.Trial{end}.States.StimulusDelay1(2)-Data.RawEvents.Trial{end}.States.StimulusDelay1(1);
            ToneATime=Data.RawEvents.Trial{end}.States.StimulusDelay2(2)-Data.RawEvents.Trial{end}.States.StimulusDelay1(1);
        elseif ~isnan(Data.RawEvents.Trial{end}.States.DeliverPunish(1))
            TrialType= 8;
            PlotIndex=0;
            Response_events=Data.RawEvents.Trial{end}.Events.BNC2High-Data.RawEvents.Trial{end}.States.Dummy2(2);
            DelayTime=0;
            ResponseTime=0;
            ToneBTime=Data.RawEvents.Trial{end}.States.StimulusDelay1(2)-Data.RawEvents.Trial{end}.States.StimulusDelay1(1);
            ToneATime=Data.RawEvents.Trial{end}.States.StimulusDelay2(2)-Data.RawEvents.Trial{end}.States.StimulusDelay1(1);
        elseif ~isnan(Data.RawEvents.Trial{end}.States.DeliverNoise(1))
            TrialType= 0;
            PlotIndex=4;
            Response_events=[66];
            ToneATime=[66];
            ToneBTime=0;
            try
            DelayTime=Data.TrialSettings(1,end).StimulusDuration2;
            ResponseTime=Data.RawEvents.Trial{end}.States.DeliverNoise(1)-Data.RawEvents.Trial{end}.States.StimulusDelay1(1)-Data.TrialSettings(1,end).StimulusDuration2;
            catch
            DelayTime=Data.TrialSettings(1,end).StimulusDuration1;
            ResponseTime=Data.RawEvents.Trial{end}.States.DeliverNoise(1)-Data.RawEvents.Trial{end}.States.StimulusDelay2(1)-Data.TrialSettings(1,end).StimulusDuration1;
            end

        else
            TrialType= 0;
            PlotIndex=0;
            Response_events=[66];
            DelayTime=0;
            ResponseTime=0;
            ToneBTime=0;
            ToneATime=[66];
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


