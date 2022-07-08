function omega = solid_angle_from_geo(lat_min, lat_max, lon_min, lon_max)
% solid_angle_from_geo - Compute the solid angle from geographic coordinates.
%
%   Compute the solid angle from the coordinates which must be in DEGREES.
%   The function return the solid angle in STERADIANS.

omega = (sind(lat_max) - sind(lat_min))*deg2rad(lon_max - lon_min);

end
