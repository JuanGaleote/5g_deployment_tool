function [Ne,Ts] = get_simulation_parameters(root)

% Initializing the entities number array with the follow structure:
%   [cars, pedestrian, bicycles, buses, motorcycles, urban, ships, trucks].

Ne = zeros(8,1);                    

% Counting car trips (necessary).

fid = fopen([root,'.passenger.trips.xml'],'r','n','UTF-8');
text = fread(fid, [1, Inf], '*char');
fclose(fid);

k = strfind(text,'<trip ');
Npas = str2double(extractBetween(text(k(end):end),'id="veh','"')) + 1;

% Getting simulation time.

k1 = strfind(text,'<time>');
k2 = strfind(text,'</time');
T = str2double(extractBetween(text(k1:k2),'"','"'));
Ts = T(end) - T(1);

% Counting pedestrian trips.

fid = fopen([root,'.pedestrian.trips.xml'],'r','n','UTF-8');
if fid ~= -1
    text = fread(fid, [1, Inf], '*char');
    fclose(fid);

    k = strfind(text,'<person ');
    Nped = str2double(extractBetween(text(k(end):end),'id="ped','"')) + 1;
else
    Nped = 0;
end

% Counting bicycle trips.

fid = fopen([root,'.bicycle.trips.xml'],'r','n','UTF-8');
if fid ~= -1
    text = fread(fid, [1, Inf], '*char');
    fclose(fid);

    k = strfind(text,'<trip ');
    Nbike = str2double(extractBetween(text(k(end):end),'id="bike','"')) + 1;
else
    Nbike = 0;
end

% Counting bus trips.

fid = fopen([root,'.bus.trips.xml'],'r','n','UTF-8');
if fid ~= -1
    text = fread(fid, [1, Inf], '*char');
    fclose(fid);

    k = strfind(text,'<trip ');
    Nbus = str2double(extractBetween(text(k(end):end),'id="bus','"')) + 1;
else
    Nbus = 0;
end

% Counting motorcycle trips.

fid = fopen([root,'.motorcycle.trips.xml'],'r','n','UTF-8');
if fid ~= -1
    text = fread(fid, [1, Inf], '*char');
    fclose(fid);

    k = strfind(text,'<trip ');
    Nmoto = str2double(extractBetween(text(k(end):end),'id="moto','"')) + 1;
else
    Nmoto = 0;
end

% Counting rail urban trips.

fid = fopen([root,'.rail_urban.trips.xml'],'r','n','UTF-8');
if fid ~= -1
    text = fread(fid, [1, Inf], '*char');
    fclose(fid);

    k = strfind(text,'<trip ');
    Nurb = str2double(extractBetween(text(k(end):end),'id="urban','"')) + 1;
else
    Nurb = 0;
end

% Counting ship trips.

fid = fopen([root,'.ship.trips.xml'],'r','n','UTF-8');
if fid ~= -1
    text = fread(fid, [1, Inf], '*char');
    fclose(fid);

    k = strfind(text,'<trip ');
    Nship = str2double(extractBetween(text(k(end):end),'id="ship','"')) + 1;
else
    Nship = 0;
end

% Counting truck trips.

fid = fopen([root,'.truck.trips.xml'],'r','n','UTF-8');
if fid ~= -1
    text = fread(fid, [1, Inf], '*char');
    fclose(fid);

    k = strfind(text,'<trip ');
    Ntruck = str2double(extractBetween(text(k(end):end),'id="truck','"')) + 1;
else
    Ntruck = 0;
end

% Saving all the parameters.

Ne = [Npas, Nped, Nbike, Nbus, Nmoto, Nurb, Nship, Ntruck];

end