function [small_cell_latitudes, small_cell_longitudes] = calculate_small_cells_coordinates_from_sinr(sinr_data, latitudes, longitudes, varargin)

% calculate_small_cells_coordinates_from_sinr - This function returns the
% position of new base stations according to a division of the low SINR map
% based on the k-means algorithm. Returns the geographical coordinates of
% each centroid as the position of the stations.

%% Initial k-means searching.
points_with_low_sinr = sinr_data <= 0;                                              % Locating the low SINR points around the grid.
X1 = latitudes(points_with_low_sinr);                                               % Latitude points.
X2 = longitudes(points_with_low_sinr);                                              % Longitude points.
XGrid = [X1,X2];                                                                    % Low SINR grid constructions.
[~,C,~,k] = best_kmeans(XGrid);                                                     % Searching for the best k-means division of the map.

%% Clustering SINR analysis.
full_grid = [latitudes,longitudes];                                                 % Loading the full SINR grid.
warning('off','all');
idx_full = kmeans(full_grid,k,'MaxIter',1,'Start',C);                               % Mapping of each point to its corresponding cluster.
warning('on','all');
idx_final = idx_full;                                                               % Mapping excluding the positive SINR points.
idx_final(~points_with_low_sinr) = 0;

cluster_gross_size = zeros(k,1);                                                    % Complete cluster size (in number of points).
cluster_net_size = zeros(k,1);                                                      % Low SINR cluster size (in number of points).
for i = 1:k
    cluster_gross_size(i) = sum(idx_full == i,"all");
    cluster_net_size(i) = sum(idx_final == i,"all");
end
relative_cluster_low_sinr_perc = cluster_net_size./cluster_gross_size;              % Relative fraction of low SINR points in each cluster.
absolute_cluster_low_sinr_perc = cluster_net_size./length(sinr_data);               % Absolute fraction of low SINR points in each cluster.

% figure(1);
% hold on;
% gscatter(full_grid(:,1),full_grid(:,2),idx_final,[1,1,1;lines(k)],'..');
% plot(C(:,1),C(:,2),'kx','MarkerSize',20);
% voronoi(C(:,1),C(:,2));
% hold off;
% grid minor;
% title('Cluster mapping');
% legend('off');
% xlabel('Latitude'); ylabel('Longitude');
% saveas(1,'first_clustering','epsc');
% saveas(1,'first_clustering','jpg');

%% Calculating surface of each cluster.
% Creating a narrow grid of our terrain.
lat_min = min(latitudes); lat_max = max(latitudes);
lon_min = min(longitudes); lon_max = max(longitudes);
Nsamples = 1e3;
dlat = (lat_max - lat_min)/(Nsamples-1);
dlon = (lon_max - lon_min)/(Nsamples-1);
lat_grid = lat_min:dlat:lat_max;
lon_grid = lon_min:dlon:lon_max;
[lat_grid,lon_grid] = meshgrid(lat_grid,lon_grid);
area_grid = [lat_grid(:),lon_grid(:)];

% Linking each point to its cluster.
warning('off','all');
idx_area = kmeans(area_grid,k,'MaxIter',1,'Start',C);
warning('on','all');

% Reshaping into a matrix concordant with the grid previously built.
idx_area = flip(reshape(idx_area',[Nsamples,Nsamples]));        
% subplot(1,2,2); imshow(idx_area,[]);

% Estimating the surface of each cluster by numerical 2-D integration.
R = 6371;                                                                           % Earth radius (km).
surfaces = zeros(k,1);                                                              % Initializing the surface vector.
for i = 1:k                                                                         % Analyzing each cluster. 
    cluster = idx_area == i;                                                        % Identify the corresponding cluster positions.
    for j = 1:size(cluster,1)                                                       % Moving across the meridiane divisions.
        current_meridian = cluster(j,:);                                            % Selecting the current meridian line position.
        current_lon = lon_grid(j,1);                                                % Selecting the current meridian line.
        if sum(current_meridian) ~= 0                                               % If exists a finite latitude line owned by the cluster.
            % Adding the corresponding thin rectangle area (km²).
            lat_vector = lat_grid(1,current_meridian);
            surfaces(i) = surfaces(i) + solid_angle_from_geo(min(lat_vector),max(lat_vector),current_lon,current_lon + dlon)*R^2;
        end
    end
end
final_surfaces = surfaces.*relative_cluster_low_sinr_perc;

%% If necessary, dividing a cluster in subclusters.
% Filtering if the area of a cluster is minor than a maximum defined by the
% frequency distributer optimum radius. Also, the cluster has to have a
% large number of low SINR surface (minor than the 10% of the total
% low SINR points).
max_surface_for_one_bs = pi*0.3^2;
cluster_low_sinr_perc_ratio = absolute_cluster_low_sinr_perc/sum(absolute_cluster_low_sinr_perc);
cluster_division_flag = ~(cluster_low_sinr_perc_ratio <= 0.05 | final_surfaces <= max_surface_for_one_bs);

% Iteratively, dividing the flagged clusters into subclusters.
max_iterations = 10;
current_iteration = 0;
while sum(cluster_division_flag) > 0 && current_iteration < max_iterations
    current_iteration = current_iteration + 1;
    Cnews = [];
    knews = 0;
    for i = 1:k
        if cluster_division_flag(i)
            cluster = idx_final == i;
            XGrid = [latitudes(cluster),longitudes(cluster)];
            [~,Csub,~,ksub] = best_kmeans(XGrid);
            Cnews = [Cnews;Csub];
            knews = knews + ksub;
        end
    end
    C(cluster_division_flag,:) = [];
    C = [C;Cnews];
    k = size(C,1);
    
    warning('off','all');
    idx_full = kmeans(full_grid,k,'MaxIter',1,'Start',C);
    warning('on','all');
    idx_final = idx_full; 
    idx_final(~points_with_low_sinr) = 0;
    
    cluster_gross_size = zeros(k,1);
    cluster_net_size = zeros(k,1);
    for i = 1:k
        cluster_gross_size(i) = sum(idx_full == i,"all");
        cluster_net_size(i) = sum(idx_final == i,"all");
    end
    relative_cluster_low_sinr_perc = cluster_net_size./cluster_gross_size;
    absolute_cluster_low_sinr_perc = cluster_net_size./length(sinr_data);
    
    warning('off','all');
    idx_area = kmeans(area_grid,k,'MaxIter',1,'Start',C);
    warning('on','all');
    idx_area = flip(reshape(idx_area',[Nsamples,Nsamples]));
    surfaces = zeros(k,1);
    for i = 1:k
        cluster = idx_area == i;
        for j = 1:size(cluster,1)
            current_meridian = cluster(j,:);
            current_lon = lon_grid(j,1);
            if sum(current_meridian) ~= 0
                lat_vector = lat_grid(1,current_meridian);
                surfaces(i) = surfaces(i) + solid_angle_from_geo(min(lat_vector),max(lat_vector),current_lon,current_lon + dlon)*R^2;
            end
        end
    end
    final_surfaces = surfaces.*relative_cluster_low_sinr_perc;
    cluster_low_sinr_perc_ratio = absolute_cluster_low_sinr_perc/sum(absolute_cluster_low_sinr_perc);
    cluster_division_flag = ~(cluster_low_sinr_perc_ratio <= 0.05 | final_surfaces <= max_surface_for_one_bs);
end

% figure(5)
% hold on;
% gscatter(full_grid(:,1),full_grid(:,2),idx_final,[1,1,1;lines(k)],'..');
% plot(C(:,1),C(:,2),'kx','MarkerSize',20);
% voronoi(C(:,1),C(:,2));
% hold off;
% title('Cluster mapping');
% grid minor;
% legend('off');
% xlabel('Latitude');
% ylabel('Longitude');
% saveas(5,'clustering_deployment','epsc');
% saveas(5,'clustering_deployment','jpg');
% close all;

small_cell_latitudes = C(:,1);
small_cell_longitudes = C(:,2);
end

