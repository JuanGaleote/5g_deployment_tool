classdef input_parameters
    properties
        uma_power;
        uma_min_freq;
        uma_max_freq;
        uma_freq_number;

        umi_coverage_power;
        umi_coverage_min_freq;
        umi_coverage_max_freq;
        umi_coverage_freq_number;

        umi_hotspot_power;
        umi_hotspot_min_freq;
        umi_hotspot_max_freq;
        umi_hotspot_freq_number;

        umi_blind_power;
        umi_blind_min_freq;
        umi_blind_max_freq;
        umi_blind_freq_number;
        
        minimum_latitude;
        maximum_latitude;
        minimum_longitude;
        maximum_longitude;
        capacity;
        coverage;
        max_attempts;
        download_map_file;
        filter_by_company;
        country;
        companySpain;
        companyAustralia;
        number_of_receivers;
        longley_rice;
        ray_tracing;
        umi_coverage_isd;
        individual_bw;
        total_time;
        step;
        distance;
        duration;
        speed;
        filename;
        uma;
        grid;
        hotspot;
        blind;
        distributionReceivers;
        networkcellinfo;
        forceCoordinates;

        rain;
        fog;
        gas;

        temperature;
        air_pressure;
        water_density;
        rain_rate;

        ray_method;
        angular_separation;
        max_reflections;
        buildings_material;
        terrain_material;

        siteviewer_animation;
        connection_animation;
    end
    
    methods
        function obj = input_parameters()
        end
    end
end

