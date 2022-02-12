function [final_uma_cellid] = deduplicate_transmitters_from_cellid(uma_cellid)

cells_index = 1;

for i = 1:length(uma_cellid)
    uma_cellid_original = uma_cellid(i);
    
    is_duplicated = false;
    
    for j=i:-1:1   
        uma_cellid_second = uma_cellid(j);
        if i~=j && uma_cellid_original==uma_cellid_second
            is_duplicated = true;
        end
    end
    
    if ~is_duplicated
        final_uma_cellid(cells_index) = uma_cellid_original;
        cells_index = cells_index + 1;
    end
end
end