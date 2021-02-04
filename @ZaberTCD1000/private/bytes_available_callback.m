function r = bytes_available_callback(obj,event,z,unit,seq,k)

    display(['callbk run with k=' int2str(k)])
    ba = get(obj,'BytesAvailable');
    if ba > 0
        [A,count,msg] = fread(obj,ba,'uint8');
    end
    k = k+1;
    move_absolute_sequence(z,unit,seq,k);

end
