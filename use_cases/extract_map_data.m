function [] = extract_map_data(coordinates_bbox,DOWNLOAD_MAP)
% extract_map_data - Return the phone cells (and the buildings) from a determinated area.
%
% This function returns the phone cells objects recovered of opensignal. If
% the user indicates it, also returns the buildings model from open street
% maps API.

lat_min = coordinates_bbox.minimum_latitude;
lat_max = coordinates_bbox.maximum_latitude;
lon_min = coordinates_bbox.minimum_longitude;
lon_max = coordinates_bbox.maximum_longitude;

[dlat, dlon, Nlat, Nlon] = bbox_grid(lat_min, lat_max, lon_min, lon_max);

lat = lat_min:dlat:lat_max;
lon = lon_min:dlon:lon_max;

osm_map = [];

fid = fopen('map.osm','r','n','UTF-8');
aux = fread(fid, [1 Inf], '*char');
fclose(fid);

lat_min_act = str2double(extractBetween(aux,'minlat="','"'));
lat_max_act = str2double(extractBetween(aux,'maxlat="','"'));
lon_min_act = str2double(extractBetween(aux,'minlon="','"'));
lon_max_act = str2double(extractBetween(aux,'maxlon="','"'));

use_actual_map = 1;
use_actual_map = use_actual_map & (round(lat_min,4) == round(lat_min_act,4));
use_actual_map = use_actual_map & (round(lat_max,4) == round(lat_max_act,4));
use_actual_map = use_actual_map & (round(lon_min,4) == round(lon_min_act,4));
use_actual_map = use_actual_map & (round(lon_max,4) == round(lon_max_act,4));

if ~use_actual_map
    for i = 1:Nlat
        for j = 1:Nlon
            coordinates_bbox = location_bbox(lat(i),lat(i+1),lon(j),lon(j+1));
            bbox_map = coordinates_bbox.get_maps_bbox_string();
            if (DOWNLOAD_MAP)
                download_buildings_from_openstreetmap(bbox_map);
                social_attractors_coordinates = coordinates_bbox.get_social_attractors_bbox_string();
                system('python main.py ' + social_attractors_coordinates);
            else
                system('python main.py');
            end
            if i == 1 && j == 1
                % Modifying .osm file.
                fid = fopen('map.osm','r','n','UTF-8');
                aux = fread(fid, [1 Inf], '*char');
                fclose(fid);
                aux = replaceBetween(aux,'minlat="','"',num2str(lat_min,'%.7f'));
                aux = replaceBetween(aux,'minlon="','"',num2str(lon_min,'%.7f'));
                aux = replaceBetween(aux,'maxlat="','"',num2str(lat_max,'%.7f'));
                aux = replaceBetween(aux,'maxlon="','"',num2str(lon_max,'%.7f'));
                aux = replaceBetween(aux,length(aux)-6,length(aux),'');
                osm_map = aux;

                % Modifying _json.osm file.
                fid = fopen('buildings_info.json','r','n','UTF-8');
                aux = fread(fid, [1 Inf], '*char');
                fclose(fid);
                aux = replaceBetween(aux,length(aux),length(aux),'');
                buildings_info = aux;
            else
                % Modifying .osm file.
                fid = fopen('map.osm','r','n','UTF-8');
                aux = fread(fid, [1 Inf], '*char');
                fclose(fid);
                aux = replaceBetween(aux,1,' <node','');
                aux = replaceBetween(aux,length(aux)-6,length(aux),'');
                osm_map = [osm_map, aux];

                % Modifying _json.osm file.
                fid = fopen('buildings_info.json','r','n','UTF-8');
                aux = fread(fid, [1 Inf], '*char');
                fclose(fid);
                if length(aux) > 2
                    aux = replaceBetween(aux,1,1,',');
                    aux = replaceBetween(aux,length(aux),length(aux),'');
                    buildings_info = [buildings_info, aux];
                end
            end
        end
    end

    osm_map = [osm_map, '</osm>'];
    osm_map(osm_map == '') = '';
    osm_map = unicode2native(osm_map, 'UTF-8');

    fid = fopen('map.osm','w');
    fwrite(fid, osm_map, 'uint8');
    fclose(fid);

    buildings_info = [buildings_info, ']'];
    buildings_info(buildings_info == '') = '';
    buildings_info = unicode2native(buildings_info, 'UTF-8');

    fid = fopen('buildings_info.json','w');
    fwrite(fid, buildings_info, 'uint8');
    fclose(fid);
end

end


