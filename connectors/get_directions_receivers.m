function [] = get_directions_receivers(mode,api_key,coordinates_start,coordinates_end)

if mode==0
    mode='car';
elseif mode==1
    mode='pedestrian';
else
    mode='scooter';
end

map_uri = 'https://router.hereapi.com/v8/routes';
options = weboptions('ContentType', 'xml', 'Timeout', 10);
map_file = websave('polyline.json', map_uri,'transportMode',mode,'origin',coordinates_start,'destination',coordinates_end,'apiKey',api_key,options,'return','polyline');
map_file = websave('summary.json', map_uri,'transportMode',mode,'origin',coordinates_start,'destination',coordinates_end,'apiKey',api_key,options,'return','summary');

end