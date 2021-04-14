function manualChangeProtocol(hObject, eventdata, input)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents as double

global S

protocolType = get(hObject,'Value');

% input.GUI.ProtocolType = protocolType; 
S.GUI.ProtocolType = protocolType;

