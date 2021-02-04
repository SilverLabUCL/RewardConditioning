function serial_close(z)

    if strcmp(get(z.sobj,'Status'),'open')
        fclose(z.sobj);
    end

end
