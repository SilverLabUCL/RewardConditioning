global motors_properties motors;

motors_properties.type = '@ZaberTCD1000';
motors_properties.port = 'COM5';

% motors = ZaberTCD1000(motors_properties.port);
% close_and_cleanup(motors);

out = instrfind('Port','COM5'); % this depends on the computer and port connected

for i=1:length(out)
    fclose(out(i));
end

motors = ZaberTCD1000(motors_properties.port);
serial_open(motors);

        