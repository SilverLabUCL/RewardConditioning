function  moveZaberMotors(tType)

    global BpodSystem motors

    p = cellfun(@(x) strcmp(x,'Position1'),BpodSystem.GUIData.ParameterGUI.ParamNames);
    motor_param.Position1 = str2double(get(BpodSystem.GUIHandles.ParameterGUI.Params(p),'String'));

    p = cellfun(@(x) strcmp(x,'Position2'),BpodSystem.GUIData.ParameterGUI.ParamNames);
    motor_param.Position2 = str2double(get(BpodSystem.GUIHandles.ParameterGUI.Params(p),'String'));

    p = cellfun(@(x) strcmp(x,'MotorMoveTime'),BpodSystem.GUIData.ParameterGUI.ParamNames);
    motor_param.MotorMoveTime = str2double(get(BpodSystem.GUIHandles.ParameterGUI.Params(p),'String'));
    
    Pos1  = motor_param.Position1;
    Pos2  = motor_param.Position2; % no separate nogo

    halfpoint = abs(round(abs(Pos1-Pos2)/2)) + min(Pos2,Pos1);
    
    if tType == 1
        position = Pos1;
    else
        position = Pos2;
    end

    tic
    move_absolute_sequence(motors,{halfpoint,position},1); % motor 1 should be anterior-posterior
    movetime = toc;
    
    if movetime < motor_param.MotorMoveTime % Should make this min-ITI a SoloParamHandle
         pause(motor_param.MotorMoveTime-movetime); % 4
    end

end









