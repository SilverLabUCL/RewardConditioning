function move_absolute_sequence(z, seq, varargin)

% Move actuator to a sequence of absolute positions, without pausing at each position. 

    if ~isa(seq,'cell')
        error('Argument seq must be a cell array')
    end

    if nargin > 2
        unit = varargin{1};
    else
        unit = 1;
    end

    % jitter mode - jitters by uniform distro of [0 127]; if position >= 180000-128, jitters by NEGATIVE that.
    jitter_mode = 1; % set to 0 to disable

    if (jitter_mode == 1) 
        disp('move_absolute_sequence.m::jitter mode ON ; jittering by 128 microsteps'); 
    end

    if z.sobj.BytesAvailable > 0
        fread(z.sobj,z.sobj.BytesAvailable,'uint8');  % clear input buffer
    end

    for k=1:length(seq)
        position = seq{k};    
        % jitter 
        if (jitter_mode == 1)
            offs = round(127*rand);
            if (position < (180000-128))
                position = position + offs;
            else
                position = position - offs;
            end
        end
        cmd = [unit 20 single_to_four_bytes(position)];
        fwrite(z.sobj,cmd,'uint8');

        disp(['move_absolute_sequence::command to zaber: ' num2str(20) ' data: ' num2str(position)]);

        motor_status = 20;
        while motor_status ~= 0 % status 0 is idle
            % fwrite(z.sobj,[unit 54 0 0 0 0],'uint8'); % Command 54: Return Status
            try
                motor_status = get_status(z,unit);
            catch
                stop(z.sobj);
                reset(z.sobj);
                renumber_all(z.sobj);
                % If timeout error, clear buffer and try again:
                if z.sobj.BytesAvailable > 0
                    fread(z.sobj,z.sobj.BytesAvailable,'uint8');  
                end
                motor_status = get_status(z,unit);
            end
            if motor_status ~= 0
                pause(0.01);
            end
        end
    end

end
