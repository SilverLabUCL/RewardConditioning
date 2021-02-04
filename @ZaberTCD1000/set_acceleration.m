function set_acceleration(z,data,varargin)

% Value persists after powerdown and resets in non-volatile memory.

    if strcmp(get(z.sobj,'Status'),'closed')
        error('Serial port status is closed.')
    end

    if data > 512 || data < 1
        error('Desired acceleration out of range.')
    end

    if nargin>2
        unit = varargin{1};
    else
        unit = 0;
    end

    cmd = [unit 43 single_to_four_bytes(data)];
    fwrite(z.sobj,cmd,'int8');

end