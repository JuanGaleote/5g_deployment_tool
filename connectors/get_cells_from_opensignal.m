function [phone_cells] = get_cells_from_opensignal(bbox_cells,COUNTRY_ID,COMPANY_ID,CELL_ID)

% First, load DB from the selected country.

cells = readtable(['data_opencellid/' num2str(COUNTRY_ID) '.csv']);

if CELL_ID ~= 0                                 % Filter if we have the CellID from the objective stations.
    phone_cells = [];
    cellid = table2array(cells(:,5));           % CellID list.
    
    for i=1:length(CELL_ID)
        index = find(cellid == CELL_ID(i));     
        if isempty(index)                       % If CellID unknown, request it to the API UnwiredLabs.     
            thingSpeakURL = 'https://eu1.unwiredlabs.com/v2/process.php'; 
            writeApiKey = 'pk.a505ce71a0a998165cd1ec07d40a50aa';
            data = struct('token',writeApiKey,'radio','lte','mcc',214,'mnc',3,'cells',[struct('cid',CELL_ID(i)),struct('cid',CELL_ID(i))],'address',1);
            options = weboptions('MediaType','application/json');
            response = webwrite(thingSpeakURL,data,options);
            phone_cells(i).lat=response.lat;
            phone_cells(i).lon=response.lon;
            
            % Including new cell to our existing DB.
            new_cell = {'LTE',COUNTRY_ID,COMPANY_ID,0,CELL_ID(i),0,response.lon,response.lat,0,0,0,0,0,0};
            cells = [cells;new_cell];
            writetable(cells,['data_opencellid/' num2str(COUNTRY_ID) '.csv']);
        else                                    % If CellID known, get the location data.
            if length(index) > 1
                radio = strfind(table2array(cells(index,1)),'LTE');
                radio = find(not(cellfun('isempty',radio)));
                index = index(radio);
                phone_cells(i).lat = cells(index,8).lat;
                phone_cells(i).lon = cells(index,7).lon;
            else
                phone_cells(i).lat = cells(index,8).lat;
                phone_cells(i).lon = cells(index,7).lon;
            end
        end
    end
else       
    coordinates = strsplit(bbox_cells,',');
    lat_max = str2double(coordinates(3));
    lat_min = str2double(coordinates(1));
    lon_max = str2double(coordinates(4));
    lon_min = str2double(coordinates(2));
    
    radio = table2array(cells(:,1));
    lat = table2array(cells(:,8));
    lon = table2array(cells(:,7));
    mnc = table2array(cells(:,3));
    
    radio = strfind(radio,'LTE');   
    radio = find(not(cellfun('isempty',radio)));
    index = radio(find(lat(radio)<lat_max&lat(radio)>lat_min));  
    index2 = index(find(lon(index)<lon_max&lon(index)>lon_min));
    
    if ~isempty(COMPANY_ID)
        index_company = index2(find(mnc(index2) == COMPANY_ID));
        phone_cells = cells(index_company,:);
        phone_cells = table2struct(phone_cells);
    else
        phone_cells = cells(index2,:);
        phone_cells = table2struct(phone_cells);
    end
end
end

