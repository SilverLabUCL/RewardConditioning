function z = ZaberTCD1000(a)
%
% Arguments:
%
% -NONE: Zaber is intialized on serial port COM7.
% -Can be string giving serial port ID, eg, 'COM7'.
% This configuration is computer specific
%
% Zaber T-CD1000 motor controller class constructor

    global ZaberPORT
    ZaberPORT='COM5';
    global maximum_zaber_position
    maximum_zaber_position = 200000;

    if nargin == 0
        out = instrfind('Port',ZaberPORT);
        for i = 1:length(out)
            fclose(out(i));
        end
        z.sobj = serial(ZaberPORT,'BaudRate',9600,'DataBits',8,'Parity','none','StopBits',1,...
            'InputBufferSize',6,'OutputBufferSize',6); % Input and output codes are all 6 bytes each
        set(z.sobj,'BytesAvailableFcnCount',6,'BytesAvailableFcnMode','byte')
        z.unit = 0;
        z = class(z,'ZaberTCD1000');

    elseif isa(a,'char')
        a = ZaberPORT; % FORCE PORT
        out = instrfind('Port',a);
        for i = 1:length(out)
            fclose(out(i));
        end
        z.sobj = serial(a,'BaudRate',9600,'DataBits',8,'Parity','none','StopBits',1,...
            'InputBufferSize',6,'OutputBufferSize',6); % Input and output codes are all 6 bytes each
        set(z.sobj,'BytesAvailableFcnCount',6,'BytesAvailableFcnMode','byte')
        z.unit = 0;
        z = class(z,'ZaberTCD1000');

    elseif isa(a,'ZaberTCD1000')
        z = a;
    end

end
