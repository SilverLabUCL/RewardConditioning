function r = get_status(z, varargin)

    if nargin > 1
        unit = varargin{1};
    else
        unit = 1;
    end

    if z.sobj.BytesAvailable > 0
        fread(z.sobj,z.sobj.BytesAvailable,'uint8');  % clear input buffer
    end

    fwrite(z.sobj,[unit 54 0 0 0 0],'uint8'); % Command 54: Return Status
    
    reply = fread(z.sobj, 6, 'uint8');
    r = four_bytes_to_single(reply(3:6));

end

