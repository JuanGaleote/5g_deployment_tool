function [umi_cell_latitudes, umi_cell_longitudes] = calculate_small_cells_from_social_attractors(social_attractors_latitudes, social_attractors_longitudes, social_attractors_weighting)

threshold = mean(social_attractors_weighting);

best_social_attractors_indexes = social_attractors_weighting > threshold;
umi_cell_latitudes = social_attractors_latitudes(best_social_attractors_indexes);
umi_cell_longitudes = social_attractors_longitudes(best_social_attractors_indexes);
end
