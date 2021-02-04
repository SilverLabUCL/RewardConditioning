function reset(z,varargin)

% Value persists after powerdown and resets in non-volatile memory.

    if strcmp(get(z.sobj,'Status'),'closed')
        error('Serial port status is closed.')
    end

    if nargin>2
        unit = varargin{1};
    else
        unit = 0;
    end

    cmd = [unit 0 single_to_four_bytes(0)];
    fwrite(z.sobj,cmd,'int8');

end