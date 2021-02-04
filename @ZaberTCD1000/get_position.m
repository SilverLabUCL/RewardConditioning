function r = get_position(z, varargin)

    if strcmp(get(z.sobj,'Status'),'closed')
        error('Serial port status is closed.')
    end

    if nargin>1
        unit = varargin{1};
    else
        unit = 1; % not 0
    end

    cmd = [unit 60 0 0 0 0];
    fwrite(z.sobj,cmd,'uint8'); %'async';

    reply = fread(z.sobj,6,'uint8');
    
    if length(reply)==6
        r = four_bytes_to_single(reply(3:6));
    end

end