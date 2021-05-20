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
    [Freq,Sounds, ID] = generate_cues( S );
    for jj=ID
        PsychToolboxSoundServer('Load', jj, Sounds{jj});    
    end
    BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_PlaySound';

    %% Define trials
    MaxTrials = 9999;
    TrialTypes = [];
    BpodSystem.Data.TrialTypes = []; % The trial type of each trial completed will be added here.
    BpodSystem.Data.TrialOutcomes = []; % The trial outcomes

    %% Initialise plots
    initialise_plots( true );

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

        
        %load sounds
        [Freq,Sounds, ID] = generate_cues( S );
        for jj=ID
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

        sma = NewStateMatrix(); % Assemble state matrix
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        
        % Build state matrix depending on the protocol type
        if S.GUI.ProtocolType==1   % simple tones
        %---------------------------------------------------------
        %  when triggered, go to 
           
                
                sma = AddState(sma, 'Name', 'TrigTrialStart', ...                    
                    'Timer', S.GUI.TriggerWait, ...
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
            
            if S.GUI.ProtocolType == 1
                TrialBehPlot(BpodSystem.GUIHandles.ToneFig, BpodSystem.Data.nTrials, currentTrial )
            end
            
            SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
            BpodSystem.ProtocolSettings = S;
            SaveProtocolSettings(S); % SaveBpodProtocolSettings;

        end

        HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
        if BpodSystem.Status.BeingUsed == 0
            return
        end

    end

end


%% To add plotting

function TrialBehPlot(ax, Ntrials, trials )

    global BpodSystem
    
    fmax = 20; %kHz
    cm = colormap( jet(fmax) );
    % f1 = 1000; f2 = 25000;
    
    
%     
%     ctr=1;
%     for jj=1:5:fmax
%        leg(ctr) = plot(ax, NaN, NaN, 'color', cm(jj,:), 'linewidth',1);
%        lname{ctr} = ['Freq = ', num2str(jj), ' kHz' ];
%        ctr=ctr+1;
%     end
    
    Ndisplay = 40;
    ind1 = max(1, Ntrials-Ndisplay+1);
    
    hold(ax, 'on');
    
    try
        TrialStart = BpodSystem.Data.RawEvents.Trial{trials}.States.TrigTrialStart(2);
    catch
        TrialStart = arrayfun( @(jj) 0, trials);
    end

    for trial=trials
        nsamples = length(BpodSystem.Data.StimuliID);
        
        for jj=1:nsamples
           freq = BpodSystem.Data.StimuliFreqs(jj);
            clr = ceil(freq/1000);
            if clr<1, clr=1; end
            if clr>fmax, clr = fmax; end
           
           state = ['Sample_', num2str(jj)];
           plot(ax, BpodSystem.Data.RawEvents.Trial{1,trial}.States.(state) - TrialStart, [trial,trial],'color', cm(clr,:), 'linewidth', 1 );
           
           
        end
        
    end
    
    
%     legend( lname );
    ylim(ax, [ind1 ind1+40]);
        
end


function initialise_plots( doTones )

    global BpodSystem
    if nargin<1, doTones=true; end
    
    if doTones
        BpodSystem.ProtocolFigures.ToneFig = figure('Position', [150 400 800 400], ...
            'name','Trial Frequencies plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off', 'Color', [1 1 1]);

        BpodSystem.GUIHandles.ToneFig = axes('Position', [.15 .2 .8 .7], 'FontSize', 11);
    end
        
end


function [Freq,Sounds, ID] = generate_cues( S )
    SF = 192000; % Analog module sampling rate
    
    if S.GUI.Freq_Interval<=0, S.GUI.Freq_Interval=500; end
    
    Freq = S.GUI.Freq_Min: S.GUI.Freq_Interval:S.GUI.Freq_Max;
    nFreq = length(Freq);
    ID =1:nFreq;
    for jj=ID
        Sounds{jj} = GenerateSineWave(SF, Freq(jj), S.GUI.SamplePeriod)*.9; % Sampling freq (hz), Sine frequency (hz), duration (s)
        
    end
    
end        