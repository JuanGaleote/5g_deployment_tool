function [Ne,Ts] = get_simulation_parameters(root)

% The entities number array will have the follow structure:
%   [cars, pedestrian, bicycles, buses, motorcycles, urban, ships, trucks].               

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
Nped = 0;
if fid ~= -1
    text = fread(fid, [1, Inf], '*char');
    fclose(fid);

    k = strfind(text,'<person ');
    if ~isempty(k)
        Nped = str2double(extractBetween(text(k(end):end),'id="ped','"')) + 1;
    end
end

% Counting bicycle trips.

fid = fopen([root,'.bicycle.trips.xml'],'r','n','UTF-8');
Nbike = 0;
if fid ~= -1
    text = fread(fid, [1, Inf], '*char');
    fclose(fid);

    k = strfind(text,'<trip ');
    if ~isempty(k)
        Nbike = str2double(extractBetween(text(k(end):end),'id="bike','"')) + 1;
    end
end


% Counting bus trips.

fid = fopen([root,'.bus.trips.xml'],'r','n','UTF-8');
Nbus = 0;
if fid ~= -1
    text = fread(fid, [1, Inf], '*char');
    fclose(fid);

    k = strfind(text,'<trip ');
    if ~isempty(k)
        Nbus = str2double(extractBetween(text(k(end):end),'id="bus','"')) + 1;
    end
end

% Counting motorcycle trips.

fid = fopen([root,'.motorcycle.trips.xml'],'r','n','UTF-8');
Nmoto = 0;
if fid ~= -1
    text = fread(fid, [1, Inf], '*char');
    fclose(fid);

    k = strfind(text,'<trip ');
    if ~isempty(k)
        Nmoto = str2double(extractBetween(text(k(end):end),'id="moto','"')) + 1;
    end
end

% Counting rail urban trips.

fid = fopen([root,'.rail_urban.trips.xml'],'r','n','UTF-8');
Nurb = 0;
if fid ~= -1
    text = fread(fid, [1, Inf], '*char');
    fclose(fid);

    k = strfind(text,'<trip ');
    if ~isempty(k)
        Nurb = str2double(extractBetween(text(k(end):end),'id="urban','"')) + 1;
    end
end

% Counting ship trips.

fid = fopen([root,'.ship.trips.xml'],'r','n','UTF-8');
Nship = 0;
if fid ~= -1
    text = fread(fid, [1, Inf], '*char');
    fclose(fid);

    k = strfind(text,'<trip ');
    if ~isempty(k)
        Nship = str2double(extractBetween(text(k(end):end),'id="ship','"')) + 1;
    end
end

% Counting truck trips.

fid = fopen([root,'.truck.trips.xml'],'r','n','UTF-8');
Ntruck = 0;
if fid ~= -1
    text = fread(fid, [1, Inf], '*char');
    fclose(fid);

    k = strfind(text,'<trip ');
    if ~isempty(k)
        Ntruck = str2double(extractBetween(text(k(end):end),'id="truck','"')) + 1;
    end
end

% Saving all the parameters.

Ne = [Npas, Nped, Nbike, Nbus, Nmoto, Nurb, Nship, Ntruck];

end