function [] = download_buildings_from_openstreetmap(bbox_map)    
    try
        coordinates = split(bbox_map,',');
        options = weboptions('ContentType', 'xml','Timeout',360);
        map_uri = ['https://overpass-api.de/api/interpreter?data=[bbox:',char(coordinates(2)),',',char(coordinates(1)),',',char(coordinates(4)),',',char(coordinates(3)), ...
            '];(node(',char(coordinates(2)),',',char(coordinates(1)),',',char(coordinates(4)),',',char(coordinates(3)),');%3C;);out%20meta;'];
        map_file = websave('map.osm',map_uri,options);
    catch
        try
            pause(60);
            map_file = websave('map.osm',map_uri,options);
        catch
            map_uri = 'https://api.openstreetmap.org/api/0.6/map';
            options = weboptions('ContentType', 'xml', 'Timeout', 10);
            map_file = websave('map.osm', map_uri, 'bbox', bbox_map, options);
        end
    end
end