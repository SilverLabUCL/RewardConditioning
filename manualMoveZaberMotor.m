function manualMoveZaberMotor(hObject, ~, motor_num)

    global motors

    position = get(hObject,'String');

    move_absolute(motors,str2double(position),str2double(motor_num));

end

