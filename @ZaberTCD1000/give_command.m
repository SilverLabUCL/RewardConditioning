function give_command(z,cmdnum,data,varargin)

    if strcmp(get(z.sobj,'Status'),'closed')
        error('Serial port status is closed.')
    end

    if nargin>3
        unit = varargin{1};
    else
        unit = 0;
    end

    cmd = [unit cmdnum single_to_four_bytes(data)];
    disp(['give_command::command to zaber: ' num2str(cmdnum) ' data: ' num2str(data)]);
    fwrite(z.sobj,cmd,'int8');

end