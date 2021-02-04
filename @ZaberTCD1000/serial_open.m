function serial_open(z)

    if strcmp(get(z.sobj,'Status'),'closed')
        fopen(z.sobj);
    end

end
