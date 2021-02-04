function r = read_last_reply(z)

    r = [];

    if get(z.sobj,'BytesAvailable')>0
        r = fread(z.sobj,6,'int8');
    end

end