function  moveZaberMotors(tType)

    global BpodSystem motors

    p = cellfun(@(x) strcmp(x,'Position'),BpodSystem.GUIData.ParameterGUI.ParamNames);
    motor_param.GoPosition = str2double(get(BpodSystem.GUIHandles.ParameterGUI.Params(p),'String'));
    
    p = cellfun(@(x) strcmp(x,'MotorMoveTime'),BpodSystem.GUIData.ParameterGUI.ParamNames);
    motor_param.MotorMoveTime = str2double(get(BpodSystem.GUIHandles.ParameterGUI.Params(p),'String'));
    
    GoPos  = motor_param.GoPosition;
    NoGoPos  = motor_param.GoPosition; % no separate nogo
%     NoGoPos = motor_param.NoGoPosition;
    halfpoint = abs(round(abs(GoPos-NoGoPos)/2)) + min(NoGoPos,GoPos);
    
    if tType == 1
        position = GoPos;
    else
        position = NoGoPos;
    end

    tic
    move_absolute_sequence(motors,{halfpoint,position},1); % motor 1 should be anterior-posterior
    movetime = toc;
    
    if movetime < motor_param.MotorMoveTime % Should make this min-ITI a SoloParamHandle
         pause(motor_param.MotorMoveTime-movetime); % 4
    end

end









