%% HG 2021
% Trigerred version for Rig 2

function PlayTones_rig2( )
    
    % SETUP
    % You will need:
    % - A Bpod.
    % Psych Toolbox (For playing Sound)
    % Speakers
    
    global BpodSystem S;

    
    %% Define parameters
    S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
    
    if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings

        S.GUI.PreSamplePeriod = 1.0;        % in sec
        S.GUI.SamplePeriod = 0.20;          % in sec
        S.GUI.PostSamplePeriod = 1.0;       % in sec
        S.GUI.Stimuli_Per_Trial = 4;      % in sec
        S.GUI.StimuliReps       = 1;      %reps within trial
        S.GUIPanels.Behaviour= {'PreSamplePeriod', 'SamplePeriod', 'PostSamplePeriod' ...   % common params
                                'Stimuli_Per_Trial', 'StimuliReps'};                        % task params

        S.GUI.IsRig2 = 1;
        S.GUI.TriggerWait = 1;              % in sec
        S.GUIPanels.StateControl = {'IsRig2', 'TriggerWait'};

        S.GUI.Freq_Min = 2000; %Hz        
        S.GUI.Freq_Max = 20000;        
        S.GUI.Freq_Interval = 1000;        
        S.GUIPanels.Stimuli = {'Freq_Min', 'Freq_Max', 'Freq_Interval'};
        
        S.GUIMeta.ProtocolType.Style = 'popupmenu';     % protocol type selection
        S.GUIMeta.ProtocolType.String = {'Stim_Simple', 'Stim_Sequence'};
        S.GUI.ProtocolType = 1; % default =  delay reward
        S.GUIPanels.Protocol= {'ProtocolType'};
    end

    % Initialize parameter GUI plugin
    BpodParameterGUI('init', S);

    % Sync the protocol selections
    p = cellfun(@(x) strcmp(x,'ProtocolType'),BpodSystem.GUIData.ParameterGUI.ParamNames);
    set(BpodSystem.GUIHandles.ParameterGUI.Params(p),'callback',{@manualChangeProtocol, S})

    %% Initiate sounds
   
    PsychToolboxSoundServer('init')
    [Freq, ID] = generate_cues( S );
    for jj=ID
        Sounds{jj} = GenerateSineWave(SF, Freq(jj), S.GUI.SamplePeriod)*.9; % Sampling freq (hz), Sine frequency (hz), duration (s)
        PsychToolboxSoundServer('Load', jj, Sounds{jj});    
    end
    BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_PlaySound';

    %% Define trials
    MaxTrials = 9999;
    TrialTypes = [];
    BpodSystem.Data.TrialTypes = []; % The trial type of each trial completed will be added here.
    BpodSystem.Data.TrialOutcomes = []; % The trial outcomes

    %% Initialise plots
    initialise_plots( true, true );
    PerfOutcomePlot(BpodSystem.GUIHandles.PerfOutcomePlot,1,'init',0);
    TrialBehPlot( BpodSystem.GUIHandles.LickFig, 1, [] );
    
    % Pause the protocol before starting
    BpodSystem.Status.Pause = 1;
    HandlePauseCondition;

    % Define inputs/outputs
    io.TrialTrigger = 'BNC1High';
    io.Punish = {'SoftCode', 3};
    

    %% Main trial loop
        
    for currentTrial = 1 : MaxTrials
        
        S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
        disp(['Starting trial ',num2str(currentTrial)])
        TrigWait = S.GUI.TriggerWait;
        
        
        %load sounds
        [Freq, ID] = generate_cues( S );
        for jj=ID
            Sounds{jj} = GenerateSineWave(SF, Freq(jj), S.GUI.SamplePeriod)*.9; % Sampling freq (hz), Sine frequency (hz), duration (s)
            PsychToolboxSoundServer('Load', jj, Sounds{jj});    
        end
        BpodSystem.Data.allSoundFreq = Freq;
        BpodSystem.Data.allSoundID = ID;
        
        
        % design stim sequence
        nFreq = length(Freq);
        currStimuli = randperm(nFreq, S.GUI.Stimuli_Per_Trial );
        currStimuli = repmat(currStimuli, [S.GUI.StimuliReps,1] );
        currStimuli = reshape( currStimuli, [ S.GUI.Stimuli_Per_Trial*S.GUI.StimuliReps, 1] );
        BpodSystem.Data.StimuliFreqs = Freq( currStimuli );
        BpodSystem.Data.StimuliID = currStimuli;
        nStim = length(currStimuli);
        

        PerfOutcomePlot(BpodSystem.GUIHandles.PerfOutcomePlot,currentTrial,'next_trial',TrialTypes(currentTrial), BpodSystem.GUIHandles.DisplayNTrials);

        sma = NewStateMatrix(); % Assemble state matrix
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        
        % Build state matrix depending on the protocol type
        if S.GUI.ProtocolType==1   % simple tones
        %---------------------------------------------------------
        %  when triggered, go to 
           
                
                sma = AddState(sma, 'Name', 'TrigTrialStart', ...                    
                    'Timer', interval, ...
                    'StateChangeConditions', {io.TrialTrigger, 'Pre_1', 'Tup', 'TrialEnd'}, ...
                    'OutputActions', {});

                for stim = 1:nStim-1   
                    stimOut = {'SoftCode', currStimuli(stim) };

                    sma = AddState(sma, 'Name', ['Pre_',num2str(stim)], ...
                        'Timer', S.GUI.PreSamplePeriod, ...
                        'StateChangeConditions', {'Tup', ['Sample_',num2str(stim)]}, ...
                        'OutputActions', {});

                    sma = AddState(sma, 'Name', ['Sample_',num2str(stim)], ...
                        'Timer', S.GUI.SamplePeriod, ...
                        'StateChangeConditions', {'Tup', ['Post_',num2str(stim),]}, ...
                        'OutputActions', stimOut );
                    
                    sma = AddState(sma, 'Name', ['Post_',num2str(stim)], ...
                        'Timer', S.GUI.PostSamplePeriod, ...
                        'StateChangeConditions', {'Tup', ['Pre_',num2str(stim+1)]}, ...
                        'OutputActions', {});
                end
                
                % last stim
                stim = nStim;
                stimOut = {'SoftCode', currStimuli(stim) };
                sma = AddState(sma, 'Name', ['Pre_',num2str(stim)], ...
                    'Timer', S.GUI.PreSamplePeriod, ...
                    'StateChangeConditions', {'Tup', ['Sample_',num2str(stim)]}, ...
                    'OutputActions', {});

                sma = AddState(sma, 'Name', ['Sample_',num2str(stim)], ...
                    'Timer', S.GUI.SamplePeriod, ...
                    'StateChangeConditions', {'Tup', ['Post_',num2str(stim),]}, ...
                    'OutputActions', stimOut );

                sma = AddState(sma, 'Name', ['Post_',num2str(stim)], ...
                    'Timer', S.GUI.PostSamplePeriod, ...
                    'StateChangeConditions', {'Tup',  'TrialEnd'}, ...
                    'OutputActions', {});
                
                
                % end trial
                sma = AddState(sma, 'Name', 'TrialEnd', ...                            
                    'Timer', 0.05, ...
                    'StateChangeConditions', {'Tup', 'exit'}, ...
                    'OutputActions', {});

        else
        end    
        
        
        
        SendStateMatrix(sma);
        RawEvents = RunStateMatrix;         % this step takes a long time and variable (seem to wait for GUI to update, which takes a long time)

        if ~isempty(fieldnames(RawEvents)) % If trial data was returned

            BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
            BpodSystem.Data.TrialSettings(currentTrial) = S; % Add the settings used for the current trial to the Data struct (to be saved after the trial ends)
            
            SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
            BpodSystem.ProtocolSettings = S;
            SaveProtocolSettings(S); % SaveBpodProtocolSettings;

        end

        % Pause the protocol before starting if in Water-Valve-Calibration
        if S.GUI.ProtocolType == 1
            BpodSystem.Status.Pause = 1;
        end        

        HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
        if BpodSystem.Status.BeingUsed == 0
            return
        end

    end

end


%% To add plotting

function TrialBehPlot(ax, Ntrials, trials, lickevent)

    global BpodSystem
    sz = 10;
    if nargin<4, lickevent = 'BNC2High'; end
        
    trigIn = 'BNC1High';
    
    Ndisplay = 40;
    ind1 = max(1, Ntrials-Ndisplay+1);
    
    hold(ax, 'on');
    
    
    leg(1) = scatter(ax, NaN, NaN, sz, 'r', 'filled');

    try
        TrialStart = BpodSystem.Data.RawEvents.Trial{trials}.States.TrigTrialStart(2);
    catch
        TrialStart = arrayfun( @(jj) 0, trials);
    end

    for trial=trials
    plot(ax, BpodSystem.Data.RawEvents.Trial{1,trial}.States.SamplePeriod - TrialStart, [trial,trial], 'k');
    end
    leg(2) = plot(ax, NaN, NaN, 'k');

    for trial=trials
    if isfield(BpodSystem.Data.RawEvents.Trial{1,trial}.States,'Reward')
        lw=1;
        if isfield( BpodSystem.Data.RawEvents.Trial{trial}.Events, lickevent)
            if any(BpodSystem.Data.RawEvents.Trial{trial}.Events.(lickevent)>=BpodSystem.Data.RawEvents.Trial{trial}.States.Reward(1) ... 
           & BpodSystem.Data.RawEvents.Trial{trial}.Events.(lickevent)<=BpodSystem.Data.RawEvents.Trial{trial}.States.RewardConsumption(2))
            lw=3;
            end
        end
    plot(ax, BpodSystem.Data.RawEvents.Trial{1,trial}.States.Reward - TrialStart, [trial,trial], 'b', 'linewidth',lw);
    plot(ax, BpodSystem.Data.RawEvents.Trial{1,trial}.States.RewardConsumption - TrialStart, [trial,trial], 'b', 'linewidth',lw);
    end
    end
    
    leg(3) = plot( ax, NaN, NaN, 'b');

    for trial=trials
    if isfield(BpodSystem.Data.RawEvents.Trial{1,trial}.States,'AnswerPeriod')
    plot(ax, BpodSystem.Data.RawEvents.Trial{1,trial}.States.AnswerPeriod - TrialStart, [trial,trial], 'g');
    end
    end
    leg(4) = plot(ax,  NaN, NaN, 'g');

    % licks
    for trial=trials
    if isfield( BpodSystem.Data.RawEvents.Trial{1,trial}.Events, lickevent), licks = BpodSystem.Data.RawEvents.Trial{1,trial}.Events.(lickevent) - TrialStart; 
    scatter(ax, licks, ones(size(licks))*trial, sz,'r','filled');
    end
    end
    
    for trial=trials
    if isfield( BpodSystem.Data.RawEvents.Trial{1,trial}.Events, trigIn) 
        trig = BpodSystem.Data.RawEvents.Trial{1,trial}.Events.(trigIn) - TrialStart; 
        scatter(ax, trig, ones(size(trig))*trial, sz,'g','filled');
    end
    end
    
    leg(5) = scatter(ax,  NaN, NaN, 'g', 'filled');

    
    legend(ax,  leg, 'Licks', 'SamplePeriod', 'Reward and consumption', 'Answer Period', 'Trial Trigger');
    ylim(ax, [ind1 ind1+40]);
    xlim(ax, [-1, 8] );
end


function initialise_plots( doOutcome, doLicks )

    global BpodSystem
    if nargin<2, doLicks=true; end
    if nargin<1, doOutcome=true'; end
    
    if doOutcome
        BpodSystem.ProtocolFigures.PerfOutcomePlotFig = figure('Position', [150 800 1600 200], ...
        'name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off', 'Color', [1 1 1]);

        BpodSystem.GUIHandles.PerfOutcomePlot = axes('Position', [.15 .2 .8 .7], 'FontSize', 11);

        uicontrol('Style', 'text', 'String', 'nDisplay: ','Position',[20 170 100 18], ...
            'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);
        BpodSystem.GUIHandles.DisplayNTrials = uicontrol('Style','edit','string','100','Position',[125 170 40 18], ...
            'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);

        uicontrol('Style', 'text', 'String', 'hit % (all): ','Position',[20 140 100 18], ...
            'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);
        BpodSystem.GUIHandles.hitpct = uicontrol('Style','text','string','0','Position',[125 140 40 18], ...
            'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);

        uicontrol('Style', 'text', 'String', 'CR % (all): ','Position',[20 120 100 18], ...
            'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);
        BpodSystem.GUIHandles.corrRej = uicontrol('Style','text','string','0','Position',[125 120 40 18], ...
            'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);
        
        
        uicontrol('Style', 'text', 'String', 'hit % (40): ','Position',[20 90 100 18], ...
            'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);
        BpodSystem.GUIHandles.hitpctrecent = uicontrol('Style','text','string','0','Position',[125 90 40 18], ...
            'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);
        
        
        uicontrol('Style', 'text', 'String', 'CR % (40): ','Position',[20 70 100 18], ...
            'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);
        BpodSystem.GUIHandles.corrRejrecent = uicontrol('Style','text','string','0','Position',[125 70 40 18], ...
            'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);
        
        

        uicontrol('Style', 'text', 'String', 'Trials: ','Position',[20 40 100 18], ...
            'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);
        BpodSystem.GUIHandles.numtrials = uicontrol('Style','text','string','0','Position',[125 40 40 18], ...
            'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);

        uicontrol('Style', 'text', 'String', 'Rewards: ','Position',[20 20 100 18], ...
            'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);
        BpodSystem.GUIHandles.numRewards = uicontrol('Style','text','string','0','Position',[125 20 40 18], ...
            'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);

    
    end

    
    if doLicks
        
        BpodSystem.ProtocolFigures.LickFig = figure('Position', [150 400 800 400], ...
            'name','Trial behaviour plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off', 'Color', [1 1 1]);

        BpodSystem.GUIHandles.LickFig = axes('Position', [.15 .2 .8 .7], 'FontSize', 11);
    end
    
    
end


function [Freq, ID] = generate_cues( S )
    SF = 192000; % Analog module sampling rate
    
    if S.GUI.Freq_Interval<=0, S.GUI.Freq_Interval=500; end
    
    Freq = S.GUI.Freq_Min: S.GUI.Freq_Interval:S.GUI.Freq_Max;
    nFreq = length(Freq);
    ID =1:nFreq;
    
end        