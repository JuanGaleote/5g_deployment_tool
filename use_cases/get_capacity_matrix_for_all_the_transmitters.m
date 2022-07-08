function capacity_matrix = get_capacity_matrix_for_all_the_transmitters(rx,tx,sinr_matrix_db,BW,map)

% get_capacity_matrix_for_all_the_transmitters - This function estimates
% the MIMO channel matrix between each transmitter and receiver. It
% calculates the capacity of each link based in a MIMO system with a
% deterministic channel matrix, which is modeled by a raytracing included
% in the comm.MIMOChannel entity.

% https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=9461761 -> Receiver antenna designing for 5G.

low_sinr_flag = sinr_matrix_db < 0;                                                                     % Locating low SINR links.
pm = propagationModel('raytracing','MaxNumReflections',10);                                             % Propagation model for raytracing.
Nt = length(tx);                                                                                        % Number of transmitters.
Nr = length(rx);                                                                                        % Number of receivers.
Nant_t = 64;                                                                                            % Transmitter antenna number.
Nant_r = 8;                                                                                             % Receiver antenna number.

uma_identifier = contains({tx.Name},'Tx ');                                                             % Filtering between UMa and UMi base stations.
final_uma = find(uma_identifier,1,'last');
first_umi = final_uma + 1;

rays = cell(Nt-2*final_uma/3,length(rx));                                                               % Calculating raytracing for high SINR links.
bs_tx = [tx(1:3:final_uma),tx(first_umi:end)];
idx_t = 1;
for i = 1:length(bs_tx)
    if i <= final_uma/3
        is_low = low_sinr_flag(idx_t,:) & low_sinr_flag(idx_t + 1,:) & low_sinr_flag(idx_t + 2,:);
        idx_t = idx_t + 3;
    else
        is_low = low_sinr_flag(idx_t,:);
        idx_t = idx_t + 1;
    end

    for j = 1:Nr
        if ~is_low(j)
            ray = raytrace(bs_tx(i),rx(j),pm,'type','pathloss');
            rays{i,j} = ray{1,1};
        end
    end
end

sinr_matrix = 10.^(sinr_matrix_db/10);                                                                  % SINR matrix must be expressed in linear values.
capacity_matrix = zeros(Nt,Nr);                                                                         % Initializing the capacity matrix.
idx_t = 1;                                                                                              % Initializing base station index.

for i = 1:Nt
	txAngle = tx(i).AntennaAngle(1);																	% Sector orientation.

    lat = tx(i).Latitude; lon = tx(i).Longitude;
    anthts = tx(i).AntennaHeight;
    latlon = [double(lat) wrapTo180(double(lon))];
    coords = rfprop.internal.AntennaSiteCoordinates(latlon, anthts, map);
    txPos = coords.enuFromRegionCenter;
    R = rfprop.internal.coordinateTransformationMatrix(txAngle);
    if i == 1
        txElements = tx(i).Antenna.getElementPosition;
    end
    txArrayPos = txPos' + R*txElements;

    for j = 1:Nr
        if ~isempty(rays{idx_t,j}) && ~low_sinr_flag(i,j)
			pathAoDs = [rays{idx_t,j}.AngleOfDeparture];												% Angles of departure.
			pathAoAs = [rays{idx_t,j}.AngleOfArrival];													% Angles of arrival
            avgPathGains = -[rays{idx_t,j}.PathLoss];                                                   % Average path gains.
			phaseShift = -[rays{idx_t,j}.PhaseShift];													% Phase shift.
			
			G = 10.^(avgPathGains/10).*exp(1j*phaseShift);												% Complex gain for each ray.
			
            lat = rx(j).Latitude; lon = rx(j).Longitude;
            anthts = rx(j).AntennaHeight;
            latlon = [double(lat) wrapTo180(double(lon))];
            coords = rfprop.internal.AntennaSiteCoordinates(latlon, anthts, map);
            rxPos = coords.enuFromRegionCenter;
            rxArrayPos = rxPos' + [-0.068, -0.034,  0.034,  0.068, -0.068, -0.034, 0.034, 0.068; ...
                                   -0.034, -0.034, -0.034, -0.034,  0.034,  0.034, 0.034, 0.034; ...
                                    0.000,  0.000,  0.000,  0.000,  0.000,  0.000, 0.000, 0.000];

            directivity_flag = abs(wrapTo180(txAngle) - pathAoDs(1,:)) <= 90;
            if sum(directivity_flag) ~= 0
                H = scatteringchanmtx(txArrayPos,rxArrayPos,pathAoDs(directivity_flag),pathAoAs(directivity_flag),G(directivity_flag))';
			    H = H/norm(H)*sqrt(Nant_t*Nant_r);
                capacity_matrix(i,j) = log2(real(det(eye(Nant_r) + sinr_matrix(i,j)/Nant_t*(H*H'))));
            else
                capacity_matrix(i,j) = log2(1 + sinr_matrix(i,j));
            end
        else
            capacity_matrix(i,j) = log2(1 + sinr_matrix(i,j));                                          % When there is no ray beteween transmitter and receiver.
        end
    end
    if mod(i,3) == 0 && i <= final_uma
        idx_t = idx_t + 1;                                                                              % Actualizing the base station index. 
    elseif i >= first_umi
        idx_t = idx_t + 1;
    end
end
capacity_matrix = BW*capacity_matrix;                                                                   % Final capacity of each link (Mbps).
end
