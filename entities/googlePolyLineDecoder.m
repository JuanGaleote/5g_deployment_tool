function [latOut,lonOut] = googlePolyLineDecoder(asciiIn,offset)
% Decodes ascii to lat lon decimal value from google polyline algorithm
%
% Inputs
%   asciiIn - Ascii text string of variable length that is the encoded
%   google polyline code for the google maps api. Assumed alternating
%   lat/lon
%
%   offset - a binary 1 or 0, where 1 means the raw readings of the
%   polyline will be output, which means the output latOut and lonOut array
%   will have the first value as a lat/lon and the subsequent values will
%   be offsets from that original value. A offset of 0 will output an array
%   of latitudes and longitudes
%
% Outputs
%   latOut - Signed decimal latitude or latitude (first value) + 
%       offset (subsequent values) of the ascii input. 
%   lonOut - Signed decimal longitude or longitude (fist value) +
%       offset (subsequent values) set of the ascii input.
%
% Google maps polyline API documentation can be found HERE:
% http://code.google.com/apis/maps/documentation/utilities/polylinealgorithm.html
% An example java based decoder (for comparison) can be found here:
% http://facstaff.unca.edu/mcmcclur/GoogleMaps/EncodePolyline/decode.html
%
% Example input : apabGfdvqLzChBu@zCaAhCaFdL}AfCq@^wF`BcWnQ_CnBiNfN
%   uHrGaLdFaLjGkGxBqFpC_C`AcB~@uEnD_ChAcAD_@EgDeCe@OwE[cA{@mB{E_B}Fq@sE
%{KgqAsBwOe[e~AiD}NkB}GsCkJmGqPgDyHsGgMeCgEaGaJuZib@qEkHsCkGcCaHcC_Ku@
%cEkAiJ{RqmBkRstCo@cNuBox@DeF`@iDn@wBVa@~CyB`AmAn@{AtAkGbAuA|@e@zFu@zF
%    ]f_@q@hUU`N_@|HaA|I{BzGkCpHcE|NqJdsAiz@pEuBrAc@rFsAdDc@hDWtEEhBD`
%Gh@xn@xL~EfAfGv@bGVjFKjFc@bp@qNtASxCOfB?lF\lIvArDZrJJzEPtCCpDLtOnA`VdA
%jb@y@hEYjEaAhDyA`B_Ajv@ip@tEoE|FgH`_@oi@`DiDlFkEhBkBrA}AbPcUzCeDxBkBnD
%iBjBg@lB[bGQpHDlCG~AKlBa@zAe@|DmB`DwBtHaHbFeHvB_ExGmOlCkF`HgKzEqGnPsRb
%    QmPn@y@lAa@~AqArBmDx@oBh@aCZaFVq@f@i@b@AJJt@yA`AuA`B_Ah@MhBpTZtFBj
%    C_@~Cm@fCCj@FRf@VRZhAd@
%
% Produced by Chris Hinkle, July 2011
% Last updated 8/3/2011
if nargin<2
    offset = 0;
end
if nargin<1
    asciiIn = '_mqN';
end
% parse into single values
tempCount = 0;
arrayCount = 1;
for i = 1:length(asciiIn)
    if asciiIn(i) < 95
        cellVal{arrayCount} = asciiIn(i-tempCount:i);
        arrayCount = arrayCount+1;
        tempCount = 0;
    else
        tempCount = tempCount+1;
    end
end
% 
% latOut = zeros(1,length(cellVal)/2);
% lonOut = zeros(length(cellVal)/2);
latCount = 1;
lonCount = 1;
for i = 1:length(cellVal)
    [tempVal] = getSingleLine(cellVal{i});
    if mod(i,2) == 1 %is odd, latitude
        latOut(latCount) = tempVal;
        latCount = latCount+1;
    else %is even, longitude
        lonOut(lonCount) = tempVal;
        lonCount = lonCount+1;
    end
end
if ~offset %dont want raw polyline, prefer absolute lat lon
    latOut = cumsum(latOut);
    lonOut = cumsum(lonOut);
end
%-------------------------------------------------------------------------%
function [decVal] = getSingleLine(asciiIn)
%break ascii down to individual numeric points
asciiNum = zeros(size(asciiIn));
for i = 1:length(asciiIn)
    asciiNum(i) = double(asciiIn(i));
end
%subtract 63 from each point
asciiNum = asciiNum-63;
%convert to binary
asciiBin = de2bi(asciiNum,'left-msb');
% un-or the 0x20 from each value
if size(asciiBin,1) > 1
    asciiBin = asciiBin(:,2:size(asciiBin,2));
    
    %reverse the order of the 5 bit chunks
    asciiBin1 = zeros(size(asciiBin));
    for i = 0:size(asciiBin,1)-1
        asciiBin1(size(asciiBin,1)-i,:) = asciiBin(1+i,:);
    end
else
    asciiBin1 = asciiBin;
end
asciiBin1 = asciiBin1';
asciiBin1 = asciiBin1(:);
% check if original decimal value is negative
if asciiBin1(end) == 1 %negative, need to invert the coding 
    bitMask = ones(size(asciiBin1));
    asciiBin1 = xor(asciiBin1,bitMask);
    isNeg = 1;
else %positive
    isNeg =0;
end
%right shift binary value one bit, zero pad
asciiBin1 = asciiBin1(:)';
% lengthVal = 8-mod(length(asciiBin1),8)+1;
if length(asciiBin1) > 1
    if isNeg%asciiBin1(end) == 0
        asciiBin1 = [asciiBin1(1:(length(asciiBin1)-1))]; 
    else
        asciiBin1 = [asciiBin1(1:(length(asciiBin1)-1))]; 
    end
else
    asciiBin1 = 0;
end
%if first value is 1, negative, need to take 2's complement
if isNeg%asciiBin1(end) == 0
    bitMask = ones(size(asciiBin1));
    asciiBin1 = xor(asciiBin1,bitMask);
    plusOne = 1;
else
    plusOne = 0;
end
%convert to string
for i = 1:length(asciiBin1)
    if i == 1
        stringVal = num2str(asciiBin1(i));
    else
        stringVal = [stringVal,num2str(asciiBin1(i))];
    end
end
decVal = bin2dec(stringVal);
decVal = decVal+plusOne;
if plusOne == 1
    decVal = -1.*decVal;
end
decVal = decVal / 1e5;