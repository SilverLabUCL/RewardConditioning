function move_home(z, varargin)

    if strcmp(get(z.sobj,'Status'),'closed')
        error('Serial port status is closed.')
    end

    if nargin>1
        unit = varargin{1};
    else
        unit = 0;
    end

    fwrite(z.sobj,[unit 1 0 0 0 0],'uint8'); % home

end


