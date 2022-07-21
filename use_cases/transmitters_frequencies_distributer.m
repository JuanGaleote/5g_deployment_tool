function base_stations_frequencies = transmitters_frequencies_distributer(latitudes,longitudes,fmin,fmax,Nfrequencies)

% transmitters_frequencies_distributer - Implementation of IFN Algorithm.

% Parameters initialization.

Nstations = length(latitudes);                                      % Number of base stations.
latitudes = reshape(latitudes,Nstations,1);                         % Reshaping latitudes array.
longitudes = reshape(longitudes,Nstations,1);                       % Reshaping longitudes array.
coordinates = [latitudes,longitudes];                               % Base stations geographical coordinates.
df = (fmax - fmin)/(Nfrequencies - 1);                              % Distance between adyacent frequencies.
f = fmin:df:fmax;                                                   % Availables frequencies.
R = 6371;                                                           % Earth radius (km), for distance estimations.
dmax = 0.3;                                                         % Radius for possibly interference (km).

% Variables initialization.

base_stations_frequencies = fmin.*ones(1,Nstations);                % Final frequencies assignment.
interference_matrix = zeros(Nstations);                             % Initial BS considerated for interference.
final_interference = zeros(Nstations);                              % Final possible interference matrix.

% Initial interference matrix calculation.

for i = 1:Nstations
    current_coordinates = coordinates(i,:);
    distances = R*deg2rad(distance('gc',current_coordinates,coordinates));
    interference_matrix(i,:) = (distances < dmax) & (distances > 0);
end
interference_vector = sum(interference_matrix);                     % Interference stations for each transmitters.
[~, I] = sort(interference_vector,'descend');                       % Sorting them in descend order interference.
mb = mean(interference_vector);                                     % Initial mean interference value.

% Iterative frequency assignment.

ma = -1;                                                            % Initializing final mean interference values.
do = 1;                                                             % Auxiliar value for do{}while(cond) loop structure.

while ((ma == mb) && (Nstations > Nfrequencies) && (Nfrequencies~=1)) && (ma ~= 0) || do
    % Frequency assignment for all possible casuistic.
    if (Nstations > Nfrequencies) && (Nfrequencies~=1) && (mb ~= 0)
        pointer = 1:Nfrequencies;                                   % Frequencies vector pointer.
        for i = I                                                   % Assignment in descent interference order.
            j = pointer(randi(numel(pointer)));                     % Random frequency pointer selection.
            pointer(pointer == j) = [];
            if isempty(pointer)
                pointer = 1:Nfrequencies;
            end
            aux = base_stations_frequencies.*interference_matrix(i,:);
            condition = base_stations_frequencies(i) == aux;
            
            if f(j) ~= base_stations_frequencies(i)
                base_stations_frequencies(condition) = f(j);
            end
        end
    elseif isinf(df) || isnan(df) || (mb == 0)                      % When only one frequency assignment.
        base_stations_frequencies(:) = f(1);
    else                                                            % When more frequencies than stations.
        base_stations_frequencies = f(1:Nstations);                 % Individual assignment.
    end

    % Results analyzing.
    for i = 1:Nstations                                             % Final interference matrix calculation.
        aux = base_stations_frequencies.*interference_matrix(i,:);
        final_interference(i,:) = base_stations_frequencies(i) == aux;
    end
    ma = mean(sum(final_interference));                             % Final mean interference value.
    do = 0;                                                         % End first iteration of while loop.
end

disp('Frequencies assignment...');
fprintf('Medium interference before: %.2f.\n', mb);
fprintf('Medium interference after: %.2f.\n', ma);
fprintf('Non interference stations: %d.\n', sum(sum(final_interference) == 0));
end
