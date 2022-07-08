function [] = request(parameters)
%% Timer initialization and adding path utilities.
Te = datetime('now');
addpath('entities', 'connectors', 'use_cases', 'repositories', 'sumo_based_route_generator');

timer = createTimer;                                            % Start timer for non PC suspension.
start(timer);
                                                                                    
% Clearing work-path from old-results.
delete('Summary\*');
delete('Scenes\*');
delete('SiteViewer\*');

if exist('sumo_receivers_data.mat','file')
    delete('sumo_receivers_data.mat');
end
if exist('RxTxData.avi','file')
    delete('RxTxData.avi');
end
if exist('SiteViewer.avi','file')
    delete('SiteViewer.avi');
end

%% Simulation parameters definition.
% COMPANIES AND USERS.
FILTER_CELLS_BY_COMPANY = parameters.filter_by_company;         % Filter by company flag.

COUNTRY_ID = str2num(parameters.country);                       % Country identificator.
if COUNTRY_ID(1) == 214                                         % Select company identificator.
    COMPANY_ID = str2double(parameters.companySpain);
elseif COUNTRY_ID(1) == 505
    COMPANY_ID = str2double(parameters.companyAustralia);
elseif COUNTRY_ID(1) == 310
    COMPANY_ID = str2double(parameters.companyUSA);
end

NUMBER_OF_RECEIVERS = parameters.number_of_receivers;           % Number of receivers.
BW = parameters.individual_bw;                                  % Individual bandwidth (MHz).

distributionReceivers = parameters.distributionReceivers;       % Random distribution of receivers flag.


% TX MODELS.
UMA_TX_POWER = parameters.uma_power;                            % UMa power transmission (W).
UMI_COVERAGE_TX_POWER = parameters.umi_coverage_power;          % UMi Coverage power transmission (W).
UMI_HOTSPOT_TX_POWER = parameters.umi_hotspot_power;            % UMi Hotspot power transmission (W).
UMI_BLIND_SPOT_TX_POWER = parameters.umi_blind_power;           % UMi Blindspot power transmission (W).
UMI_ISD = parameters.umi_coverage_isd;                          % UMi intersite distance (m).

UMA_MIN_FREQ = parameters.uma_min_freq;                         % UMa minimum frequency (Hz).
UMA_MAX_FREQ = parameters.uma_max_freq;                         % UMa maximum frequency (Hz).
UMA_FREQ_NUM = parameters.uma_freq_number;                      % UMa frequencies number.

UMI_COVERAGE_MIN_FREQ = parameters.umi_coverage_min_freq;       % UMi coverage minimum frequency (Hz).
UMI_COVERAGE_MAX_FREQ = parameters.umi_coverage_max_freq;       % UMi coverage maximum frequency (Hz).
UMI_COVERAGE_FREQ_NUM = parameters.umi_coverage_freq_number;    % UMi coverage frequencies number.

UMI_HOTSPOT_MIN_FREQ = parameters.umi_hotspot_min_freq;         % UMi hotspot minimum frequency (Hz).
UMI_HOTSPOT_MAX_FREQ = parameters.umi_hotspot_max_freq;         % UMi hotspot maximum frequency (Hz).
UMI_HOTSPOT_FREQ_NUM = parameters.umi_hotspot_freq_number;      % UMi hotspot frequencies number.

UMI_BLIND_SPOT_MIN_FREQ = parameters.umi_blind_min_freq;        % UMi blindspot minimum frequency (Hz).
UMI_BLIND_SPOT_MAX_FREQ = parameters.umi_blind_max_freq;        % UMi blindspot maximum frequency (Hz).
UMI_BLIND_SPOT_FREQ_NUM = parameters.umi_blind_freq_number;     % UMi blindspot frequencies number.


% MAP AND MODE.
lat_min = parameters.minimum_latitude;                          % Bounding box - geographical coordinates.
lon_min = parameters.minimum_longitude;
lat_max = parameters.maximum_latitude;
lon_max = parameters.maximum_longitude;

IS_COVERAGE_MODE = parameters.coverage;                         % Coverage mode flag.
MAX_NUMBER_OF_ATTEMPTS = parameters.max_attempts;               % Max attempts number.
DOWNLOAD_MAP = parameters.download_map_file;                    % Download map flag.


% MOBILITY ANALYSIS.
sumo = 0;                                                       % By default, not using SUMO networks.

total_time = parameters.total_time;                             % Total simulation time.
step = parameters.step;                                         % Step time for simulation.
if step == 0                                                    % It cannot be zero.
    step = 1;
end

networkcellinfo = parameters.networkcellinfo;                   % Network Cell Info file type flag.
force_coordinates = parameters.forceCoordinates;                % For SUMO, replace file coordinates for input.

filename = parameters.filename;                                 % Attached routing file.

if ~isempty(filename)                                           % File extension and data extraction.
    file_extension = split(filename,'.');
    if strcmp(file_extension{2},'xlsx')                         % Reading .xlsx file.
        data_file = xlsread(filename);
        format long;
        if size(data_file,2) > 2
            data_file(:,2:4) = []; data_file(:,23) = [];
        end
    elseif strcmp(file_extension{2},'csv')                      % Reading .csv file.
        data_file = readtable(filename);
        format long;
        if size(data_file,2) > 2
            data_file(:,2:4) = []; data_file(:,23) = [];
            data_file = table2array(data_file);
        else
            data_file = table2array(data_file);
        end
    elseif strcmp(file_extension{2},'sumocfg')                  % Reading SUMO data.
        sumo = true;
        if ~exist([file_extension{1},'.mat'],'file')
            [receivers_routes,bbox_coordinates,Ntot,Ts] = sumo_gen_route(filename,step);
        else
            load([file_extension{1},'.mat'],'receivers_routes','bbox_coordinates','Ntot','Ts','dT');
            if dT ~= step
                [receivers_routes,bbox_coordinates,Ntot,Ts] = sumo_gen_route(filename,step);
            end
        end

        total_time = Ts;                                        % Force simulation time to SUMO time.

        if ~force_coordinates                                   % When use SUMO coordinates (default).
            lat_min = bbox_coordinates(1);
            lon_min = bbox_coordinates(2);
            lat_max = bbox_coordinates(3);
            lon_max = bbox_coordinates(4);
        end
        NUMBER_OF_RECEIVERS = Ntot;
    end
end

direction_duration = parameters.duration;                       % Direction duration (s).
direction_speed = parameters.speed;                             % Direction speed (m/s).
direction_distance = parameters.distance;                       % Direction distance (m).

if direction_duration == 0                                      % Obtaining non introduced directional parameter.
    direction_duration = direction_distance/direction_speed;
elseif direction_speed == 0
    direction_speed = direction_distance/direction_duration;
elseif direction_distance == 0
    direction_distance = direction_duration*direction_speed;
end


% DEPLOYMENT.
UMA_ANALYSIS = parameters.uma;                                  % UMa analysis flag (always marked).
UMI_GRID = parameters.grid;                                     % UMi Coverage flag.
UMI_HOTSPOT = parameters.hotspot;                               % UMi Hotspot flag.
UMI_BLIND = parameters.blind;                                   % UMi Blindspot flag.


% PROPAGATION MODEL.
if parameters.longley_rice                                      % Main propagation model selection.
    PROPAGATION_MODEL = {'longley-rice'};                       % Longley Rice model.
else
    PROPAGATION_MODEL = {'raytracing'};                         % Ray-Tracing model.
end

prop_model.type = PROPAGATION_MODEL;                            % Model characteristics.

prop_model.ray_method = parameters.ray_method;
prop_model.angular_separation = parameters.angular_separation;
prop_model.max_reflections= parameters.max_reflections;
prop_model.buildings_material = parameters.buildings_material;
prop_model.terrain_material = parameters.terrain_material;

prop_model.temperature = parameters.temperature;
prop_model.air_pressure = parameters.air_pressure;
prop_model.water_density = parameters.water_density;
prop_model.rain_rate = parameters.rain_rate;

if parameters.rain                                              % Add rain model.
    prop_model.type = [prop_model.type, {'rain'}];
end

if parameters.fog                                               % Add fog model.
    prop_model.type = [prop_model.type, {'fog'}];
end

if parameters.gas                                               % Add gas model.
    prop_model.type = [prop_model.type, {'gas'}];
end


% ANIMATION CONFIGURATION.
siteviewer_animation = parameters.siteviewer_animation;
connection_animation = parameters.connection_animation;

% OPTIMIZATION OPTIONS.
umi_blind_opt_flag = parameters.umi_blind_position_opt;
freq_opt_flag = parameters.freq_assignment_opt;
cell_angle_opt_flag = parameters.cellangle_opt;

opt_generations = parameters.opt_generations;
opt_population = parameters.opt_population;
umi_opt_square_edge = parameters.square_edge_umiblind_opt;

%% Constants and models definition.
UMA_NAME = 'UMA';
UMI_COVERAGE_NAME = 'UMI cov';
UMI_HOTSPOT_NAME = 'UMI h';
UMI_BLIND_SPOT_NAME = 'UMI bs';
UMA_ANTENNA = 'sector';
UMI_ANTENNA = 'isotropic';
UMA_HEIGHT = 25;
UMI_HEIGHT = 10;

uma_tx_model = tx_model(UMA_TX_POWER, UMA_ANTENNA, UMA_HEIGHT, UMA_NAME, UMA_MIN_FREQ, UMA_MAX_FREQ, UMA_FREQ_NUM);
umi_coverage_model = tx_model(UMI_COVERAGE_TX_POWER, UMI_ANTENNA, UMI_HEIGHT, UMI_COVERAGE_NAME, UMI_COVERAGE_MIN_FREQ, UMI_COVERAGE_MAX_FREQ, UMI_COVERAGE_FREQ_NUM);
umi_hotspot_model = tx_model(UMI_HOTSPOT_TX_POWER, UMI_ANTENNA, UMI_HEIGHT, UMI_HOTSPOT_NAME, UMI_HOTSPOT_MIN_FREQ, UMI_HOTSPOT_MAX_FREQ, UMI_HOTSPOT_FREQ_NUM);
umi_blind_spot_model = tx_model(UMI_BLIND_SPOT_TX_POWER, UMI_ANTENNA, UMI_HEIGHT, UMI_BLIND_SPOT_NAME, UMI_BLIND_SPOT_MIN_FREQ, UMI_BLIND_SPOT_MAX_FREQ, UMI_BLIND_SPOT_FREQ_NUM);

%% Map generation.
disp("Generating map and getting social attractors...");

coordinates_bbox = location_bbox(lat_min,lat_max,lon_min,lon_max);
extract_map_data(coordinates_bbox,DOWNLOAD_MAP);

map = siteviewer('Buildings','map.osm');

%% Filter cells if needed.
bbox_cells = coordinates_bbox.get_cells_bbox_string();          % Getting string coordinates for requesting.

if ~networkcellinfo                                             % Filtering for Network Cell Info source.
    if (FILTER_CELLS_BY_COMPANY)
        selected_phone_cells = get_cells_from_opensignal(bbox_cells,COUNTRY_ID,COMPANY_ID,0);
    else
        selected_phone_cells = get_cells_from_opensignal(bbox_cells,COUNTRY_ID,[],0);
    end
else                                                            % Needed to select company for this file type.
    uma_cellid = data_file(:,8);
    uma_cellid = deduplicate_transmitters_from_cellid(uma_cellid);
    selected_phone_cells = get_cells_from_opensignal(bbox_cells,COUNTRY_ID,COMPANY_ID,uma_cellid);
end

%% Users - receivers.
disp("Generating receivers...");

[social_attractors_latitudes, social_attractors_longitudes, ...
    social_attractors_weighting] = read_buildings_file();

if isempty(filename)                                            % Filtering if file selected or not.
    if ~distributionReceivers                                   % Non random Rx distribution.
        [receivers_latitudes, receivers_longitudes] = generate_receivers_from_social_attractors(...
            social_attractors_latitudes, social_attractors_longitudes, ...
            social_attractors_weighting, NUMBER_OF_RECEIVERS, coordinates_bbox);

        receivers = rxsite(...
            'Latitude', receivers_latitudes, ...
            'Longitude', receivers_longitudes, ...
            'AntennaHeight', 1.5);
    else
        receivers_latitudes = (lat_max - lat_min).*rand(NUMBER_OF_RECEIVERS,1) + lat_min;
        receivers_longitudes = (lon_max - lon_min).*rand(NUMBER_OF_RECEIVERS,1) + lon_min;

        receivers = rxsite(...
            'Latitude', receivers_latitudes, ...
            'Longitude', receivers_longitudes, ...
            'AntennaHeight', 1.5);
    end
else
    if networkcellinfo                                          % Network Cell Info file selected.
        receivers = rxsite(...
            'Latitude', data_file(1,15), ...
            'Longitude', data_file(1,16), ...
            'AntennaHeight', 1.5);
    elseif sumo                                                 % SUMO file selected.
        pedestrians_names = fieldnames(receivers_routes.pedestrians);
        vehicles_names = fieldnames(receivers_routes.vehicles);

        receivers = rxsite('Name','init','Latitude',0,'Longitude',0,'AntennaHeight',0);

        for i = 1:length(pedestrians_names)
            aux = receivers_routes.pedestrians.(pedestrians_names{i});
            aux = aux(~isnan(aux(:,1)),:);
            receivers = [receivers; rxsite('Name',pedestrians_names{i},...
                'Latitude',aux(1,1),...
                'Longitude',aux(1,2),...
                'AntennaHeight',1.5)];
        end
        receivers = receivers(2:end);
        for i = 1:length(vehicles_names)
            aux = receivers_routes.vehicles.(vehicles_names{i});
            aux = aux(~isnan(aux(:,1)),:);
            receivers = [receivers; rxsite('Name',vehicles_names{i},...
                'Latitude',aux(1,1),...
                'Longitude',aux(1,2),...
                'AntennaHeight',1.5)];
        end
    else                                                        % Xlsx file selected.
        receivers = rxsite(...
            'Latitude', data_file(1,1), ...
            'Longitude', data_file(1,2), ...
            'AntennaHeight', 1.5);
    end
end

%% UMa and UMi transmitters generation.
% Only selected cells will be generated (by defect, always generate at least UMa cells).
uma_transmitters = txsite.empty;
umi_transmitters = txsite.empty;
umi_transmitters_hotspot = txsite.empty;
umi_transmitters_grid = txsite.empty;
umi_transmitters_blind = txsite.empty;
tx_analysis = txsite.empty;

% UMa generation.
if UMA_ANALYSIS && ~isempty(selected_phone_cells)
    disp("Generating UMa layer...");
    if networkcellinfo
        selected_phone_cells = struct2table(selected_phone_cells);
        uma_latitudes = selected_phone_cells(:,1).lat;
        uma_longitudes = selected_phone_cells(:,2).lon;
        uma_transmitters = get_transmitters_from_coordinates(uma_latitudes,uma_longitudes,uma_tx_model);
    else
        [uma_latitudes,uma_longitudes] = get_coordinates_from_cells(selected_phone_cells);
        uma_transmitters = get_transmitters_from_coordinates(uma_latitudes,uma_longitudes,uma_tx_model);
    end
    [data_latitudes,data_longitudes,~,uma_sinr_data] = calculate_sinr_values_map(uma_transmitters,coordinates_bbox,prop_model);
    tx_analysis = uma_transmitters;
end

% UMi Hotspot generation (social attractors).
if UMI_HOTSPOT
    disp("Generating UMi close to social attractors...");
    [umi_cell_latitudes,umi_cell_longitudes] = calculate_small_cells_from_social_attractors(social_attractors_latitudes,social_attractors_longitudes,social_attractors_weighting);
    if ~isempty(umi_cell_latitudes)
        [umi_cell_latitudes,umi_cell_longitudes] = deduplicate_transmitters_from_coordinates(umi_cell_latitudes,umi_cell_longitudes);
        umi_transmitters_hotspot = get_transmitters_from_coordinates(umi_cell_latitudes,umi_cell_longitudes,umi_hotspot_model);

        tx_analysis = [tx_analysis,umi_transmitters_hotspot];
        umi_transmitters = [umi_transmitters,umi_transmitters_hotspot];
    end
end

% UMi Grid generation (hexagons).
if UMI_GRID
    disp("Generating UMi distributed layer...");
    [distributed_latitudes,distributed_longitudes] = distribute_umi_cells_among_box(coordinates_bbox,UMI_ISD);
    umi_transmitters_grid = get_transmitters_from_coordinates(distributed_latitudes,distributed_longitudes,umi_coverage_model);

    tx_analysis = [tx_analysis,umi_transmitters_grid];
    umi_transmitters = [umi_transmitters,umi_transmitters_grid];
end

% UMi Blind generation (coverage blind points).
if UMI_BLIND
    disp("Generating UMi to cover blind points...");
    if UMI_HOTSPOT || UMI_GRID
        [data_latitudes,data_longitudes,~,best_sinr_data] = calculate_sinr_values_map(tx_analysis,coordinates_bbox,prop_model);
    else
        best_sinr_data = uma_sinr_data;
    end
    [new_umi_cell_latitudes, new_umi_cell_longitudes] = ...
        calculate_small_cells_coordinates_from_sinr(best_sinr_data, ...
        data_latitudes,data_longitudes);
    umi_transmitters_blind = get_transmitters_from_coordinates(new_umi_cell_latitudes,new_umi_cell_longitudes,umi_blind_spot_model);

    tx_analysis = [tx_analysis,umi_transmitters_blind];
    umi_transmitters = [umi_transmitters,umi_transmitters_blind];
end

% For optimization, calculating UMi SINR data only one time (except if UMi Blind selected, then will be two).
if UMI_HOTSPOT || UMI_GRID || UMI_BLIND
    [~,~,~,umi_sinr_data] = calculate_sinr_values_map(umi_transmitters,coordinates_bbox,prop_model);
end

%% Parameters optimization.
if umi_blind_opt_flag || freq_opt_flag || cell_angle_opt_flag
    Nparam = 0; x = []; LB = []; UB = [];
    intcon = [];
    semi_edge = umi_opt_square_edge/2;  
    if umi_blind_opt_flag
        Nparam = Nparam + 2*numel(umi_transmitters_blind);
        x = [x,1/2.*ones(1,Nparam)];
        LB = [LB,zeros(1,Nparam)];
        UB = [UB,ones(1,Nparam)];
    end
    if freq_opt_flag
        Nparam = Nparam + numel(uma_transmitters)/3 + numel(umi_transmitters);

        Numa = numel(uma_transmitters);
        Numi_cov = numel(umi_transmitters_grid);
        Numi_hot = numel(umi_transmitters_hotspot);
        Numi_blind = numel(umi_transmitters_blind);
        intcon = [1:(Numa/3+Numi_cov+Numi_hot+Numi_blind)] + 2*numel(umi_transmitters_blind);

        pos = 0;
        if UMA_ANALYSIS
            uma_freq = linspace(uma_tx_model.minimum_frequency,uma_tx_model.maximum_frequency,uma_tx_model.frequency_division_number);
            [~,aux] = ismember([tx_analysis(pos+1:3:Numa).TransmitterFrequency],uma_freq); x = [x,aux];    
            LB = [LB,ones(1,Numa/3)]; UB = [UB,numel(uma_freq)*ones(1,Numa/3)];
            pos = pos + Numa;
        end
        if UMI_HOTSPOT
            umi_hot_freq = linspace(umi_hotspot_model.minimum_frequency,umi_hotspot_model.maximum_frequency,umi_hotspot_model.frequency_division_number);
            [~,aux] = ismember([tx_analysis(pos+1:pos+Numi_hot).TransmitterFrequency],umi_hot_freq); x = [x,aux];
            LB = [LB,ones(1,Numi_hot)]; UB = [UB,numel(umi_hot_freq)*ones(1,Numi_hot)];
            pos = pos + Numi_hot;
        end
        if UMI_GRID
            umi_cov_freq = linspace(umi_coverage_model.minimum_frequency,umi_coverage_model.maximum_frequency,umi_coverage_model.frequency_division_number);
            [~,aux] = ismember([tx_analysis(pos+1:pos+Numi_cov).TransmitterFrequency],umi_cov_freq); x = [x,aux];
            LB = [LB,ones(1,Numi_cov)]; UB = [UB,numel(umi_cov_freq)*ones(1,Numi_cov)];
            pos = pos + Numi_cov;
        end
        if UMI_BLIND
            umi_blind_freq = linspace(umi_blind_spot_model.minimum_frequency,umi_blind_spot_model.maximum_frequency,umi_blind_spot_model.frequency_division_number);  
            [~,aux] = ismember([tx_analysis(pos+1:pos+Numi_blind).TransmitterFrequency],umi_blind_freq); x = [x,aux];
            LB = [LB,ones(1,Numi_blind)]; UB = [UB,numel(umi_blind_freq)*ones(1,Numi_blind)];
        end   
    end
    if cell_angle_opt_flag
        Nparam = Nparam + numel(uma_transmitters);
		
		uma_index = find(contains(string({tx_analysis.Name}),'Tx')); Numa = length(uma_index);
		cell_angles = [tx_analysis(uma_index).AntennaAngle]; aux = (cell_angles + 180)/360;
		x = [x,aux];
		LB = [LB,zeros(1,Numa)]; UB = [UB,ones(1,Numa)];
    end

    options = gaoptimset('Generations',opt_generations,'PopulationSize',opt_population,'EliteCount',1,...
        'PlotFcns',{@gaplotbestf,@gaplotbestindiv,@gaplotexpectation,@gaplotstopping},...
        'MutationFcn', {@mutationadaptfeasible,1/40},...
        'InitialPopulation',x,...
        'StallGenLimit',500000,'StallTimeLimit',100000);

    f = @(z) sinr_optimization_function(z,umi_blind_opt_flag,freq_opt_flag,cell_angle_opt_flag,semi_edge, ...
        tx_analysis,uma_tx_model,umi_coverage_model,umi_hotspot_model,umi_blind_spot_model, ...
        coordinates_bbox,prop_model);

    [x,fval] = ga(f,Nparam,[],[],[],[],LB,UB,[],intcon,options);
    fprintf('Optimization final results: %d points with low SINR.\n',fval);

    %% Results aplication.
    Nact = 0;
    if umi_blind_opt_flag
        umi_blind_index = find(contains(string({tx_analysis.Name}),umi_blind_spot_model.name)); Nact = length(umi_blind_index);
        lat_correction = semi_edge*(1 - 2*x(1:Nact));
        lon_correction = semi_edge*(1 - 2*x(Nact+1:2*Nact));
    
        aux = num2cell([tx_analysis(umi_blind_index).Latitude] - lat_correction);       [tx_analysis(umi_blind_index).Latitude] = deal(aux{:});
        aux = num2cell([tx_analysis(umi_blind_index).Longitude] - lon_correction);      [tx_analysis(umi_blind_index).Longitude] = deal(aux{:});
    end 
    
    Nact = 2*Nact + 1;
    if freq_opt_flag
        uma_freq = linspace(uma_tx_model.minimum_frequency,uma_tx_model.maximum_frequency,uma_tx_model.frequency_division_number);
        umi_hot_freq = linspace(umi_hotspot_model.minimum_frequency,umi_hotspot_model.maximum_frequency,umi_hotspot_model.frequency_division_number);
        umi_cov_freq = linspace(umi_coverage_model.minimum_frequency,umi_coverage_model.maximum_frequency,umi_coverage_model.frequency_division_number);
        umi_blind_freq = linspace(umi_blind_spot_model.minimum_frequency,umi_blind_spot_model.maximum_frequency,umi_blind_spot_model.frequency_division_number);
    
        uma_index = find(contains(string({tx_analysis.Name}),'Tx'));                              Numa = length(uma_index)/3;
        umi_hot_index = find(contains(string({tx_analysis.Name}),umi_hotspot_model.name));        Nhot = length(umi_hot_index);
        umi_cov_index = find(contains(string({tx_analysis.Name}),umi_coverage_model.name));       Ncov = length(umi_cov_index);
        umi_blind_index = find(contains(string({tx_analysis.Name}),umi_blind_spot_model.name));   Nblind = length(umi_blind_index);
    
        uma_freq_select = repelem(x(Nact:Nact+Numa-1),3); Nact = Nact + Numa;
        umi_hot_freq_select = x(Nact:Nact+Nhot-1);        Nact = Nact + Nhot;
        umi_cov_freq_select = x(Nact:Nact+Ncov-1);        Nact = Nact + Ncov;
        umi_blind_freq_select = x(Nact:Nact+Nblind-1);    Nact = Nact + Nblind;
    
        aux = num2cell(uma_freq(uma_freq_select));                  [tx_analysis(uma_index).TransmitterFrequency] = deal(aux{:});
        aux = num2cell(umi_cov_freq(umi_cov_freq_select));          [tx_analysis(umi_cov_index).TransmitterFrequency] = deal(aux{:});
        aux = num2cell(umi_hot_freq(umi_hot_freq_select));          [tx_analysis(umi_hot_index).TransmitterFrequency] = deal(aux{:});
        aux = num2cell(umi_blind_freq(umi_blind_freq_select));      [tx_analysis(umi_blind_index).TransmitterFrequency] = deal(aux{:});
    end
    
	Nact = Nact + 1
    if cell_angle_opt_flag
		cell_angles = x(Nact:end); aux = num2cell(cell_angles);
		uma_index = find(contains(string({tx_analysis.Name}),'Tx'));
		[tx_analysis(uma_index).AntennaAngle] = deal(aux{:});
    end
end

%% Results.
disp("Showing final map...");

%% Scene capturing with JAVA.
import java.awt.*;
import java.awt.event.*;

% Create a Robot-object to do the key-pressing. Commands for pressing keys:
[merged_latitudes,merged_longitudes,merged_grid_size,best_sinr_data] = calculate_sinr_values_map(tx_analysis,coordinates_bbox,prop_model);
try
    show(receivers, 'Icon', 'pins/receiver.png', 'IconSize', [18 18],'Animation','none');
    plot_values_map(tx_analysis, merged_latitudes, merged_longitudes, merged_grid_size, best_sinr_data, prop_model);
catch
    close(map);
    map = siteviewer('Buildings','map.osm');
    show(receivers, 'Icon', 'pins/receiver.png', 'IconSize', [18 18],'Animation','none');
    plot_values_map(tx_analysis, merged_latitudes, merged_longitudes, merged_grid_size, best_sinr_data, prop_model);
end

rob = Robot;
rob.keyPress(KeyEvent.VK_WINDOWS);
rob.keyPress(KeyEvent.VK_UP);
rob.keyRelease(KeyEvent.VK_UP);
rob.keyRelease(KeyEvent.VK_WINDOWS);
pause(5);
show_legend(map);

%% UMi Backhaul computing.
if ~isempty(umi_transmitters) && ~isempty(uma_transmitters)
    disp("Computing backhaul...");
    backhaul_matrix = get_backhaul_relation(uma_transmitters,umi_transmitters);
    for i = 1:length(backhaul_matrix)
        current_uma = backhaul_matrix(i);
        if current_uma ~= 0
            los(uma_transmitters(current_uma),umi_transmitters(i));
        end
    end
end
close(map);

%% Receivers directions.
disp("Generating coordinates for each receiver.");
if isempty(filename)                                            % Filtering if there is a file selected.
    if total_time~=0                                            % Mobility simulation.

        latitudes_aleatorias = (lat_max - lat_min).*rand(NUMBER_OF_RECEIVERS,1) + lat_min;
        longitudes_aleatorias = (lon_max - lon_min).*rand(NUMBER_OF_RECEIVERS,1) + lon_min;

        modos_transporte = randi([0 2],1,NUMBER_OF_RECEIVERS);
        api_key = '-NqbbgbdNAjen1jTPULtFaTkiCuW8gX3ZdFa1cuWY5o';

        for rx = 1:NUMBER_OF_RECEIVERS
            % Getting string start-end coordinates.
            coordinates_start = num2str(receivers_latitudes(rx),10) + "," + num2str(receivers_longitudes(rx),10);
            coordinates_end = num2str(latitudes_aleatorias(rx),10) + "," + num2str(longitudes_aleatorias(rx),10);

            % Mode selection.
            mode = modos_transporte(rx);

            % Getting a random route from the API Heres Map.
            get_directions_receivers(mode,api_key,coordinates_start,coordinates_end);
            fichero = jsondecode(fileread('polyline.json'));
            if isempty(fichero.routes)
                coordinates = strsplit(coordinates_start,',');
                users(rx).latOut = coordinates(1);
                users(rx).lonOut = coordinates(2);
                users(rx).duration = 0;
                users(rx).distance = 0;
                users(rx).speed = 0;
                users(rx).step = 1;
            else
                users(rx).polyline = fichero.routes.sections.polyline;
                system(['python decoder_flexpolyline.py ' users(rx).polyline]);
                users(rx).latOut = importdata('latitudes.txt');
                users(rx).lonOut = importdata('longitudes.txt');
                fichero2 = jsondecode(fileread('summary.json'));
                users(rx).duration = fichero2.routes.sections.summary.duration;
                users(rx).distance = fichero2.routes.sections.summary.length;
                users(rx).speed = users(rx).distance/users(rx).duration;
                users(rx).step = users(rx).distance/length(users(rx).latOut);
            end
        end
    else                                                        % Static receivers simulation.
        for rx = 1:NUMBER_OF_RECEIVERS
            users(rx).latOut = receivers_latitudes(rx);
            users(rx).lonOut = receivers_longitudes(rx);
            users(rx).speed = 0;
            users(rx).distance = 0;
            users(rx).step = 1;
        end

    end
else
    if networkcellinfo                                          % Network Cell Info file selected.
        users.latOut = data_file(:,15);
        users.lonOut = data_file(:,16);
        users.speed = direction_speed;
        users.distance = direction_distance;
        users.step = users.distance/length(users.latOut);
        NUMBER_OF_RECEIVERS = 1;
    elseif ~sumo                                                % Xlsx/csv file selected.
        users.latOut = data_file(:,1);
        users.lonOut = data_file(:,2);
        users.speed = direction_speed;
        users.distance = direction_distance;
        users.step = users.distance/length(users.latOut);
        NUMBER_OF_RECEIVERS = 1;
    end
end

%% Mobility analysis.
signal_receivers = zeros(NUMBER_OF_RECEIVERS,total_time+1);
sinr_receivers = zeros(NUMBER_OF_RECEIVERS,total_time+1);
capacity_receivers = zeros(NUMBER_OF_RECEIVERS,total_time+1);
rsnr = [];
time = 1;
connect_user = [];

if sumo
    pedestrians_names = fieldnames(receivers_routes.pedestrians);
    vehicles_names = fieldnames(receivers_routes.vehicles);

    for i = 1:length(pedestrians_names)
        sumo_sinr.pedestrians.(pedestrians_names{i}) = NaN*zeros(1,total_time/step + 1);
        sumo_signal.pedestrians.(pedestrians_names{i}) = NaN*zeros(1,total_time/step + 1);
        sumo_capacity.pedestrians.(pedestrians_names{i}) = NaN*zeros(1,total_time/step + 1);
    end
    for i = 1:length(vehicles_names)
        sumo_sinr.vehicles.(vehicles_names{i}) = NaN*zeros(1,total_time/step + 1);
        sumo_signal.vehicles.(vehicles_names{i}) = NaN*zeros(1,total_time/step + 1);
        sumo_capacity.vehicles.(vehicles_names{i}) = NaN*zeros(1,total_time/step + 1);
    end
end

for t = 1:step:(total_time + 1)
    disp(['Computing results of mobility - ' num2str(t-1) 's']);

    if ~sumo
        for rx = 1:NUMBER_OF_RECEIVERS
            m = (t-1)*users(rx).speed;
            if users(rx).step~=0
                indice = round(m/users(rx).step) + 1;
            else
                indice = 1;
            end
            if indice > length(users(rx).latOut)
                indice = length(users(rx).latOut);
            end
            receivers_latitudes(rx) = users(rx).latOut(indice);
            receivers_longitudes(rx) = users(rx).lonOut(indice);
        end
        receivers = rxsite(...
            'Latitude', receivers_latitudes, ...
            'Longitude', receivers_longitudes, ...
            'AntennaHeight', 1.5);
        N_Rx = NUMBER_OF_RECEIVERS;
    else
        N_Rx = 0;
        receivers = rxsite('Name','init','Latitude',0,'Longitude',0,'AntennaHeight',0);
        receivers_latitudes = [];
        receivers_longitudes = [];

        for i = 1:length(pedestrians_names)
            aux = receivers_routes.pedestrians.(pedestrians_names{i});
            aux = aux((t - 1)/step + 1,:);
            if ~isnan(aux(1,1))
                N_Rx = N_Rx + 1;
                receivers = [receivers; rxsite('Name',pedestrians_names{i},...
                    'Latitude',aux(1,1),...
                    'Longitude',aux(1,2),...
                    'AntennaHeight',1.5)];
                receivers_latitudes(N_Rx) = aux(1,1);
                receivers_longitudes(N_Rx) = aux(1,2);
            end
        end
        receivers = receivers(2:end);
        for i = 1:length(vehicles_names)
            aux = receivers_routes.vehicles.(vehicles_names{i});
            aux = aux((t - 1)/step + 1,:);
            if ~isnan(aux(1,1))
                N_Rx = N_Rx + 1;
                receivers = [receivers; rxsite('Name',vehicles_names{i},...
                    'Latitude',aux(1,1),...
                    'Longitude',aux(1,2),...
                    'AntennaHeight',1.5)];
                receivers_latitudes(N_Rx) = aux(1,1);
                receivers_longitudes(N_Rx) = aux(1,2);
            end
        end
    end

    % Reference coordinates for centering SiteViewer.
    margen = 0.0025;
    dlat = lat_max - lat_min;
    dlon = lon_max - lon_min;
    screen_size = Toolkit.getDefaultToolkit().getScreenSize();
    siteViewer_references = rxsite(...
        'Latitude', [lat_max+dlat/50, lat_min-dlat/50], ...
        'Longitude', [lon_max+dlon/50, lon_min-dlon/50], ...
        'AntennaHeight', 1.5);

    % Scene visualization in SiteViewer for the current time.
    map = siteviewer('Buildings','map.osm');
    show(receivers,'Icon','pins/receiver.png','IconSize',[18 18],'Animation','none');
    plot_values_map(tx_analysis,merged_latitudes,merged_longitudes,merged_grid_size,best_sinr_data,prop_model);
    pause(2);
    rob.keyPress(KeyEvent.VK_WINDOWS);
    rob.keyPress(KeyEvent.VK_UP);
    rob.keyRelease(KeyEvent.VK_UP);
    rob.keyRelease(KeyEvent.VK_WINDOWS);
    pause(2);
    show(siteViewer_references,'IconSize',[1 1],'Animation','zoom');
    pause(2);
    show_legend(map);
    pause(2);
    rob.mouseMove(screen_size.width/2,screen_size.height/2);
    rob.mousePress(InputEvent.BUTTON2_MASK);
    rob.mouseMove(screen_size.width/2,screen_size.height/1.5);
    rob.mouseRelease(InputEvent.BUTTON2_MASK);
    rob.mousePress(InputEvent.BUTTON1_MASK);
    rob.mouseMove(screen_size.width/2,screen_size.height/1.35);
    rob.mouseRelease(InputEvent.BUTTON1_MASK);
    pause(2);

    if siteviewer_animation
        disp("Generating screenshot of SiteViewer");
        filename = ['SiteViewer/SiteViewer_',num2str(t-1),'s.jpg'];

        % Commands for pressing keys: Screen capture.
        toolkit = java.awt.Toolkit.getDefaultToolkit();
        rectangle = java.awt.Rectangle(toolkit.getScreenSize());
        image = rob.createScreenCapture(rectangle);
        filehandle = java.io.File(filename);
        javax.imageio.ImageIO.write(image,'jpg',filehandle);
    end

    % If Network Cell Info file exists, it store the metrics obtain with mobile app for comparision.
    if networkcellinfo
        rsnr(time,:) = data_file(indice,24);
        signal(time,:) = data_file(indice,14);
    end

    % Computing results.
    disp("Generating SINR matrix for all the receivers");
    [sinr_matrix,signal_strength_data] = get_sinr_matrix_for_all_the_transmitters(receivers,tx_analysis,prop_model);
    count = sum(sum(sinr_matrix > 0) > 0);
    capacity_matrix = get_capacity_matrix_for_all_the_transmitters(receivers,tx_analysis,sinr_matrix,BW,map);
    close(map);

    disp("Computing pairing...");
    sinr_data = zeros(1,N_Rx);
    power_data = zeros(1,N_Rx);
    pairing_capacity = zeros(1,N_Rx);
    pairing_matrix = zeros(1,N_Rx);
    pairing_names = cellstr('');
    total_capacity = zeros(1,length(tx_analysis));
    for i = 1:N_Rx
        [value,index] = max(capacity_matrix(:,i));
        sinr_data(i) = sinr_matrix(index,i);
        power_data(i) = signal_strength_data(index,i);
        pairing_capacity(i) = value;
        pairing_matrix(i) = index;
        pairing_names(i) = cellstr(string(tx_analysis(index).Name));
        total_capacity(index) = total_capacity(index) + value;
    end
    if ~isempty(umi_transmitters) && ~isempty(uma_transmitters)
        traffic_uma = zeros(1,length(uma_transmitters));
        for i = 1:length(traffic_uma)
            linked_umi = find(backhaul_matrix == i);
            for j = 1:length(linked_umi)
                traffic_uma(i) = traffic_uma(i) + total_capacity(linked_umi(j));
            end
        end
    end
    
    
    % Save results for each Rx at the current time.
    if ~sumo                                                   % Filtering if we have SUMO file.
        sinr_receivers(time,:) = sinr_data;
        signal_receivers(time,:) = power_data;
        capacity_receivers(time,:) = pairing_capacity;
    else
        sinr_receivers = sinr_data;                            % Current users reception data.
        signal_receivers = power_data;
        capacity_receivers = pairing_capacity;

        for i = 1:N_Rx                                          % Global users reception data.
            if ~isempty(strfind(receivers(i).Name,'ped'))
                sumo_sinr.pedestrians.(receivers(i).Name)(time) = sinr_receivers(i);
                sumo_signal.pedestrians.(receivers(i).Name)(time) = signal_receivers(i);
                sumo_capacity.pedestrians.(receivers(i).Name)(time) = capacity_receivers(i);
            else
                sumo_sinr.vehicles.(receivers(i).Name)(time) = sinr_receivers(i);
                sumo_signal.vehicles.(receivers(i).Name)(time) = signal_receivers(i);
                sumo_capacity.vehicles.(receivers(i).Name)(time) = capacity_receivers(i);
            end
        end
    end

    % Tx and Rx labels arrays.
    label_rx = {};
    label_tx = {};
    rx_names = strings(1,length(receivers));
    tx_names = strings(1,length(tx_analysis));

    cont = 1;

    % Rx label assignment.
    if ~sumo
        for i = 1:N_Rx
            label_rx{i} = {['Rx', num2str(i), '^{', num2str(sinr_data(i)), 'dB}_{', pairing_names{i}, '}']};
            rx_names(i) = ['Rx' num2str(i)];
        end
    else
        for i = 1:N_Rx
            label_rx{i} = {[receivers(i).Name, '^{', num2str(sinr_data(i)), 'dB}_{', pairing_names{i}, '}']};
            rx_names(i) = [receivers(i).Name, num2str(i)];
        end
    end

    % Tx label assignment.
    u = 0;
    for k = 1:3:length(uma_transmitters)                        % UMa data.
        tx_name = strsplit(tx_analysis(k).Name);
        if networkcellinfo
            label_tx{cont} = {[tx_name{1}, tx_name{2}, '^{', num2str(length(find(pairing_matrix == k | pairing_matrix == k+1 | pairing_matrix == k+2))), '}_{', num2str(uma_cellid(k-u)), '}']};
        else
            label_tx{cont} = {[tx_name{1}, tx_name{2}, '^{', num2str(length(find(pairing_matrix == k | pairing_matrix == k+1 | pairing_matrix == k+2))), '}']};
        end
        tx_names(cont) = [tx_name{1}, tx_name{2}];
        tx_latitudes(cont) = tx_analysis(k).Latitude;
        tx_longitudes(cont) = tx_analysis(k).Longitude;
        cont = cont+1;
        u = u + 2;
    end

    for k = (length(uma_transmitters) + 1):length(tx_analysis)  % UMi data.
        tx_latitudes(cont) = tx_analysis(k).Latitude;
        tx_longitudes(cont) = tx_analysis(k).Longitude;
        tx_names(cont) = tx_analysis(k).Name;
        label_tx{cont} = {[tx_analysis(k).Name, '^{', num2str(length(find(pairing_matrix == k))), '}']};
        cont = cont + 1;
    end

    tx_names = tx_names(1:cont-1);
    if connection_animation
        disp("Showing SINR of each receiver...");
        figure();
        plot(receivers_longitudes, receivers_latitudes, 'ks','MarkerSize',2,'MarkerFaceColor','r');
        margen2 = 0.0035;
        ylim([lat_min-margen2 lat_max+margen2]);
        xlim([lon_min-margen2 lon_max+margen2]);
        title(['Time: ', num2str(t-1), 's.']);
        %   plot_openstreetmap('Alpha', 0.5, 'Scale', 2, 'BaseUrl', "https://a.tile.openstreetmap.org");
        plot_openstreetmap('Alpha', 0.5, 'Scale', 2, 'BaseUrl', "http://a.tile.openstreetmap.fr/hot");
        rob.keyPress(KeyEvent.VK_WINDOWS);
        rob.keyPress(KeyEvent.VK_RIGHT);
        rob.keyRelease(KeyEvent.VK_RIGHT);
        rob.keyRelease(KeyEvent.VK_WINDOWS);
        pause(2);
        set(gca, 'LooseInset', [0,0,0,0]);
        label_rx = text(receivers_longitudes,receivers_latitudes,string(label_rx),'HorizontalAlignment','center','FontSize',12);

        disp("Showing users connected...");
        figure();
        plot(tx_longitudes, tx_latitudes, 'ks','MarkerSize',2,'MarkerFaceColor','r');
        ylim([lat_min-margen lat_max+margen])
        xlim([lon_min-margen lon_max+margen])
        title(['Time: ', num2str(t-1), 's.']);
        plot_openstreetmap('Alpha', 0.5, 'Scale', 2, 'BaseUrl', "http://a.tile.openstreetmap.fr/hot");
        rob.keyPress(KeyEvent.VK_WINDOWS);
        rob.keyPress(KeyEvent.VK_LEFT);
        rob.keyRelease(KeyEvent.VK_LEFT);
        rob.keyRelease(KeyEvent.VK_WINDOWS);
        pause(2);
        set(gca,'LooseInset', [0,0,0,0]);
        label_tx = text(tx_longitudes,tx_latitudes,label_tx,'HorizontalAlignment','center','FontSize',12);

        for i=1:N_Rx
            if contains(pairing_names(i),"cell")
                label_rx(i).Color='red';
            elseif contains(pairing_names(i), "cov")
                label_rx(i).Color='blue';
            elseif contains(pairing_names(i), "b")
                label_rx(i).Color=[6 171 8]/255;
            elseif contains(pairing_names(i), "h")
                label_rx(i).Color=[1 0.56 0];
            end
        end

        for i=1:length(label_tx)
            if contains(label_tx(i).String,"Tx")
                label_tx(i).Color='red';
            elseif contains(label_tx(i).String, "cov")
                label_tx(i).Color='blue';
            elseif contains(label_tx(i).String, "b")
                label_tx(i).Color=[6 171 8]/255;
            elseif contains(label_tx(i).String, "h")
                label_tx(i).Color=[1 0.56 0];
            end
        end

        filename = ['Scenes/Scene_' num2str(t-1) 's.jpg'];

        % Commands for pressing keys: Screen capture.
        pause(2)
        toolkit = java.awt.Toolkit.getDefaultToolkit();
        rectangle = java.awt.Rectangle(toolkit.getScreenSize());
        image = rob.createScreenCapture(rectangle);
        filehandle = java.io.File(filename);
        javax.imageio.ImageIO.write(image,'jpg',filehandle);
        close all
    end

    tx_user = [];
    %% Results for UMa.
    disp("Saving results...");
    filename = ['Summary/summary' num2str(t-1) 's.txt'];
    file_id = fopen(filename,'w');
    for i = 1:3:length(uma_transmitters)-2
        transmitter_offset = length(umi_transmitters);
        name = "Name: " + uma_transmitters(i).Name;
        location = " - Location: " + uma_transmitters(i).Latitude + " , " + uma_transmitters(i).Longitude;
        power = " - Power: " + uma_transmitters(i).TransmitterPower + " W";
        frequency = " - Frequency: " + uma_transmitters(i).TransmitterFrequency/1e9 + " GHz";
        angles = " - Sector angles: " + uma_transmitters(i).AntennaAngle + " " + uma_transmitters(i+1).AntennaAngle + " " + uma_transmitters(i+2).AntennaAngle;
        connected_users = " - Connected users: " + length(find(pairing_matrix == i + transmitter_offset | pairing_matrix == i+1 + transmitter_offset | pairing_matrix == i+2 + transmitter_offset));
        if length(find(pairing_matrix == i + transmitter_offset | pairing_matrix == i+1 + transmitter_offset | pairing_matrix == i+2 + transmitter_offset)) == 0
            tx_user= [tx_user -0.25];
        else
            tx_user= [tx_user length(find(pairing_matrix == i + transmitter_offset | pairing_matrix == i+1 + transmitter_offset | pairing_matrix == i+2 + transmitter_offset))];
        end
        users_traffic = " - Traffic demanded by users: " + sum(total_capacity(transmitter_offset+i : transmitter_offset+i+2)) + " Mbps";
        if ~isempty(umi_transmitters)
            umi_traffic = " - Traffic demanded by UMis: " + sum(traffic_uma(i:i+2)) + " Mbps";
            fprintf(file_id, '%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n\n', name, location, power, frequency, angles, connected_users, users_traffic, umi_traffic);
        else
            fprintf(file_id, '%s\n%s\n%s\n%s\n%s\n%s\n%s\n\n', name, location, power, frequency, angles, connected_users, users_traffic);
        end
    end

    %% Results for UMi
    if ~isempty(umi_transmitters)                               % Only if UMi station generated.
        for i = 1:length(umi_transmitters)
            name = "Name: " + umi_transmitters(i).Name;
            location = " - Location: " + umi_transmitters(i).Latitude + " , " + umi_transmitters(i).Longitude;
            power = " - Power: " + umi_transmitters(i).TransmitterPower + " W";
            frequency = " - Frequency: " + umi_transmitters(i).TransmitterFrequency/1e9 + " GHz";
            connected_users = " - Connected users: " + length(find(pairing_matrix == i));
            if length(find(pairing_matrix==i))==0
                tx_user= [tx_user -0.25];
            else
                tx_user= [tx_user length(find(pairing_matrix == i))];
            end

            users_traffic = " - Traffic demanded by users: " + sum(total_capacity(i)) + " Mbps";
            connected_to = " - Backhaul to: " + uma_transmitters(backhaul_matrix(i)).Name;
            pointing_to = " - Backhaul to coordinates: " + uma_transmitters(backhaul_matrix(i)).Latitude + " , " + uma_transmitters(backhaul_matrix(i)).Longitude;
            fprintf(file_id, '%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n\n', name, location, power, frequency, connected_users, users_traffic, connected_to, pointing_to);
        end
        umi_coverage = length(find(umi_sinr_data > 0))/length(umi_sinr_data)*100;
        umi_coverage_message = " - UMi layer coverage: " + umi_coverage + " %";
        total_umi = " - Total number of UMi: " + length(umi_transmitters);
    end

    %% Summary.
    a = txsite("Latitude", lat_max, "Longitude", lon_max);
    b = txsite("Latitude", lat_min, "Longitude", lon_max);
    c = txsite("Latitude", lat_min, "Longitude", lon_min);
    height = distance(a,b)/1000;
    wide = distance(b,c)/1000;
    area = height*wide;

    coverage = length(find(best_sinr_data > 0))/length(best_sinr_data)*100;
    uma_coverage = length(find(uma_sinr_data > 0))/length(uma_sinr_data)*100;
    users_coverage = N_Rx - count;
    traffic = sum(total_capacity)/N_Rx;
    traffic_area = sum(total_capacity)/area;

    coverage_message = " - Total coverage (UMa + UMi): " + coverage + " % (area with SINR > 0 dB)";
    uma_coverage_message = " - UMa layer coverage: " + uma_coverage + " %";
    users_coverage_message = " - Users whose SINR < 0 dB: " + users_coverage + " out of " + N_Rx;
    total_network_traffic = " - Total Network traffic: " + sum(total_capacity) + " Mbps";
    mean_traffic = " - Mean traffic per user: " + traffic + " Mbps";
    traffic_area_message = " - Traffic / area: " + traffic_area + " Mbps/Km^2";
    total_uma = " - Total number of UMa: " + length(uma_transmitters);

    fprintf(file_id, '\n------- SUMMARY ------- \n');
    if ~isempty(umi_transmitters)
        fprintf(file_id, '%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n', coverage_message, uma_coverage_message, umi_coverage_message, users_coverage_message, total_network_traffic, mean_traffic, traffic_area_message, total_uma, total_umi);
        fclose(file_id);
    else
        fprintf(file_id, '%s\n%s\n%s\n%s\n%s\n%s\n%s\n', coverage_message, uma_coverage_message, users_coverage_message, total_network_traffic, mean_traffic, traffic_area_message, total_uma);
        fclose(file_id);
    end
    disp("Finished! You can check the summary openning summary.txt");

    connect_user(time,:) = tx_user;
    time = time + 1;
end

if total_time~=0
    if NUMBER_OF_RECEIVERS <= 8 && ~sumo                        % For less than 8 receivers (not SUMO).
        figure();                                               % SINR analysis.
        plot(1:step:total_time+1,sinr_receivers);
        legend(rx_names);
        title('SINR DATA RECEIVERS'); xlabel('Time (s)'); ylabel('SINR (dB)');
        if networkcellinfo                                      % Comparing with Network Cell ID Info data.
            rsnr(rsnr<-50) = 0;
            hold on
            plot(1:step:total_time+1,rsnr);
            legend('Result Urban 5GRX','Result Network Cell Info');
        end

        figure();                                               % Signal data analysis.
        plot(1:step:total_time+1,signal_receivers);
        legend(rx_names);
        title('SIGNAL DATA RECEIVERS'); xlabel('Time (s)'); ylabel('SIGNAL (dBm)');
        if networkcellinfo
            hold on
            plot(1:step:total_time+1,signal);
            legend('Result Urban 5GRX','Result Network Cell Info');
        end
    elseif sumo
        save('sumo_receivers_data.mat','sumo_sinr','sumo_signal','sumo_capacity','receivers_routes');
    end
    if length(tx_longitudes) <= 8                               % For less than 8 transmitters.
        figure();                                               % Connected users.
        bar(0:step:total_time,connect_user);
        legend(tx_names);
        title('CONNECTED USERS'); xlabel('Time (s)'); ylabel('CONNECTED USERS'); ylim([-0.5 Inf]);
    end
    %% Animation Mobility.
    disp("Generating Animation...");
    frames = total_time/step;
    makeAnimationMobility(frames,siteviewer_animation,connection_animation);
end
stop(timer)

Te = datetime('now') - Te;
fprintf('Elapsed time:');
disp(Te);

end