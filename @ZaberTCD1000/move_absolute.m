function move_absolute(z, position, varargin)

    if strcmp(get(z.sobj,'Status'),'closed')
        error('Serial port status is closed.')
    end

    global maximum_zaber_position

    if position > maximum_zaber_position || position < 0
        error('Desired position out of range.') % Need to check range; this's just a guess.
    end

    if nargin>2
        unit = varargin{1};
    else
        unit = 0;
    end
    % unit=0;
    cmd = [unit 20 single_to_four_bytes(position)];
    fwrite(z.sobj,cmd,'uint8'); % 'async'

end
