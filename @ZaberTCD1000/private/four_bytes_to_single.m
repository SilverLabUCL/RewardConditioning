function r = four_bytes_to_single(n)

% Converts 4 bytes in 2's complement (LSB) to 32-bit decimal number.

    if length(n) ~= 4
        error('Input must be 4-element vector, each elt representing a byte.')
    end

    if sum(n > 255 | n < 0) > 0
        error('At least one input vector element is out of 0-255 range.')
    end

    b = [dec2binvec(n(1),8) dec2binvec(n(2),8) dec2binvec(n(3),8) dec2binvec(n(4),8)];

    signbit = b(end);
    if signbit==0
        r = binvec2dec(b);
    else
        b = xor(b,ones(1,32));
        b = binary_add(b,dec2binvec(1,32));
        r = -binvec2dec(b);
    end

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
