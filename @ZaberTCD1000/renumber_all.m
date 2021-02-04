function renumber_all(z)

    if strcmp(get(z.sobj,'Status'),'closed')
        error('Serial port status is closed.')
    end

    unit = 0;
    fwrite(z.sobj,[unit 2 0 0 0 0],'int8'); % home

end
