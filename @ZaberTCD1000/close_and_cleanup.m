function close_and_cleanup(z)

    if strcmp(get(z.sobj,'Status'),'open')
        fclose(z.sobj); 
    end
    
    delete(z.sobj)
    clear z.sobj

end
