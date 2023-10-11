function score = sinr_optimization_function(x,umi_blind_flag,freq_flag,angle_flag,semi_edge,tx_analysis,uma_tx_model,umi_coverage_model,umi_hotspot_model,umi_blind_spot_model,coordinates_bbox,prop_model)

transmitters = copy(tx_analysis);
Nact = 0;
if umi_blind_flag
    umi_blind_index = find(contains(string({transmitters.Name}),umi_blind_spot_model.name)); Nact = length(umi_blind_index);
    lat_correction = semi_edge*(1 - 2*x(1:Nact));
    lon_correction = semi_edge*(1 - 2*x(Nact+1:2*Nact));
    
    aux = num2cell([transmitters(umi_blind_index).Latitude] - lat_correction);       [transmitters(umi_blind_index).Latitude] = deal(aux{:});
    aux = num2cell([transmitters(umi_blind_index).Longitude] - lon_correction);      [transmitters(umi_blind_index).Longitude] = deal(aux{:});
end 

Nact = 2*Nact + 1;
if freq_flag
    uma_freq = linspace(uma_tx_model.minimum_frequency,uma_tx_model.maximum_frequency,uma_tx_model.frequency_division_number);
    umi_hot_freq = linspace(umi_hotspot_model.minimum_frequency,umi_hotspot_model.maximum_frequency,umi_hotspot_model.frequency_division_number);
    umi_cov_freq = linspace(umi_coverage_model.minimum_frequency,umi_coverage_model.maximum_frequency,umi_coverage_model.frequency_division_number);
    umi_blind_freq = linspace(umi_blind_spot_model.minimum_frequency,umi_blind_spot_model.maximum_frequency,umi_blind_spot_model.frequency_division_number);

    uma_index = find(contains(string({transmitters.Name}),'Tx'));                              Numa = length(uma_index)/3;
    umi_hot_index = find(contains(string({transmitters.Name}),umi_hotspot_model.name));        Nhot = length(umi_hot_index);
    umi_cov_index = find(contains(string({transmitters.Name}),umi_coverage_model.name));       Ncov = length(umi_cov_index);
    umi_blind_index = find(contains(string({transmitters.Name}),umi_blind_spot_model.name));   Nblind = length(umi_blind_index);

    uma_freq_select = repelem(x(Nact:Nact+Numa-1),3); Nact = Nact + Numa;
    umi_hot_freq_select = x(Nact:Nact+Nhot-1);        Nact = Nact + Nhot;
    umi_cov_freq_select = x(Nact:Nact+Ncov-1);        Nact = Nact + Ncov;
    umi_blind_freq_select = x(Nact:Nact+Nblind-1);    Nact = Nact + Nblind;

    aux = num2cell(uma_freq(uma_freq_select));                  [transmitters(uma_index).TransmitterFrequency] = deal(aux{:});
    aux = num2cell(umi_cov_freq(umi_cov_freq_select));          [transmitters(umi_cov_index).TransmitterFrequency] = deal(aux{:});
    aux = num2cell(umi_hot_freq(umi_hot_freq_select));          [transmitters(umi_hot_index).TransmitterFrequency] = deal(aux{:});
    aux = num2cell(umi_blind_freq(umi_blind_freq_select));      [transmitters(umi_blind_index).TransmitterFrequency] = deal(aux{:});
end

if angle_flag
	cell_angles = 360*x(Nact:end); aux = num2cell(cell_angles);
	uma_index = find(contains(string({transmitters.Name}),'Tx'));
	[transmitters(uma_index).AntennaAngle] = deal(aux{:});
    end
end

try
    [~,~,~,sinr_data] = calculate_sinr_values_map(transmitters,coordinates_bbox,prop_model);
catch
    save('error.mat','x');
end
low_sinr_data = sinr_data < 0;
score = sum(low_sinr_data,'all');
end
