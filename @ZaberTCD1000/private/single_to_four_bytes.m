function r = single_to_four_bytes(n)

% Converts single-precision (32-bit) integer to 4 bytes in 2's complement.

    if length(n) > 1
        error('Input must be scaler.')
    end
    if n > (2^31 - 1) | n < (-2^31) % for 2's complement, need sign bit
        error('Input value out of 32-bit 2s complement range.')
    end

    b = dec2binvec(abs(n),32);
    if sign(n) == -1
        b = xor(b,ones(1,32));
        b = binary_add(b,dec2binvec(1,32));
    end

    r(1) = binvec2dec(b(1:8));
    r(2) = binvec2dec(b(9:16));
    r(3) = binvec2dec(b(17:24));
    r(4) = binvec2dec(b(25:32));

end

% ------------------------------------------------------------------------
function r = binary_add(x, y)

    if length(x)~=length(y)
        error('Input binary numbers must be same length.')
    end
    r = zeros(1,length(x));
    carrybit = 0;
    for k=1:length(r)
        r(k) = x(k)+y(k)+carrybit;
        carrybit = 0;
        if r(k)>1
            r(k) = mod(r(k),2);
            carrybit = 1;
        end
    end

end
