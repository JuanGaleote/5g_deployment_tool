classdef tx_model
    properties
        power
        antenna_type
        height
        name
        minimum_frequency
        maximum_frequency
        frequency_division_number
    end
    
    methods
        function obj = tx_model(power, antenna_type, height, name,...
                minimum_frequency, maximum_frequency, frequency_division_number)
            obj.power = power;
            obj.antenna_type = antenna_type;
            obj.height = height;
            obj.name = name;
            obj.minimum_frequency = minimum_frequency;
            obj.maximum_frequency = maximum_frequency;
            obj.frequency_division_number = frequency_division_number;
        end
    end
end
