function stop(z)

    if strcmp(get(z.sobj,'Status'),'closed')
        error('Serial port status is closed.')
    end

    cmd = [z.unit 23 0 0 0 0];
    fwrite(z.sobj,cmd,'int8','async');

end
