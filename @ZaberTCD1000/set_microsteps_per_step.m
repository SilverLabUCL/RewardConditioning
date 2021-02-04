function set_microsteps_per_step(z,data)

% Value persists after powerdown and resets in non-volatile memory.

    if strcmp(get(z.sobj,'Status'),'closed')
        error('Serial port status is closed.')
    end

    cmd = [z.unit 37 single_to_four_bytes(data)];
    fwrite(z.sobj,cmd,'int8');

end