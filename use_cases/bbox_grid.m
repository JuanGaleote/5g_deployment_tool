function [dlat, dlon, Nlat, Nlon] = bbox_grid(lat_min, lat_max, lon_min, lon_max)
% bbox_grid - Divide a surface over a sphere in a regular whose area cell is lower than 4 km^2.
%
%   This function return the increments you have to take for divide the
%   surface in a grid with area cell lower than 4 km^2. Also include the
%   steps number for reach this objective from the min latitud/longitude to
%   the max value. All the INPUTS must be in DEGREES.

R = 6371;                           % Earth radius (km).

% Compute the solid angle (Sr) and the sustented area (km^2).
omega_tot = solid_angle_from_geo(lat_min, lat_max, lon_min, lon_max);
Stot = omega_tot*R^2;       

fprintf("Computing a %.2f km² area...\n",Stot);

% Search by bipartition a grid with a surface per cell lower than 4 km^2.
Sgrid = Stot;
dlat = lat_max - lat_min;
dlon = lon_max - lon_min;
Nlat = 1;
Nlon = 1;

if dlat > dlon
    bipart = 1;
else
    bipart = 0;
end

while Sgrid > 4
    if bipart
        dlat = dlat/2;
        Nlat = 2*Nlat;
        if dlat < dlon
            bipart = 0;
        end  
    else
        dlon = dlon/2;
        Nlon = 2*Nlon;
        if dlon < dlat
            bipart = 1;
        end    
    end
    Scell = 0;
    for i = 1:Nlat 
        for j = 1:Nlon
            omega_cell = solid_angle_from_geo(lat_min + (i - 1)*dlat, lat_min + i*dlat,...
                                              lon_min + (j - 1)*dlon, lon_min + j*dlon);
            Saux = omega_cell*R^2;
            if Saux > Scell      
                Scell = Saux;
            end
        end
    end  
    Sgrid = Scell;
end

fprintf("Made a %d x %d grid division...\n",Nlat,Nlon);
end



