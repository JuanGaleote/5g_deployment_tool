function [sinr_matrix,signal_strength] = get_sinr_matrix_for_all_the_transmitters(receivers, transmitters, model_name, varargin)

validateattributes(receivers,{'rxsite'},{'nonempty'},'sinr','',1);
validateattributes(transmitters,{'txsite'},{'nonempty'},'sinr','',2);

input_parameters = inputParser;
if nargin > 2 && mod(numel(varargin),2)
    input_parameters.addOptional('PropagationModel', [], @(x)ischar(x)||isstring(x)||isa(x,'rfprop.PropagationModel'));
else
    input_parameters.addParameter('PropagationModel', []);
end

[receivers, transmitters, validated_params] = validate_parameters(receivers, transmitters, input_parameters, model_name, varargin{:});

args = {'Type','power', ...
    'TransmitterAntennaSiteCoordinates', validated_params.txsCoords};
if ~validated_params.usingDefaultGain
    args = [args, 'ReceiverGain', rxGain];
end
propagation_model = propagationModel('longley-rice');
signal_strength = sigstrength(receivers, transmitters, propagation_model, args{:});

transmitter_frequencies = [transmitters.TransmitterFrequency];

number_of_transmitters = length(transmitters);
sinr_matrix = zeros(number_of_transmitters, validated_params.numRxs);
for rxInd = 1:validated_params.numRxs
    for txInd = 1:number_of_transmitters
        sigStrengths = signal_strength(:,rxInd)';    
        
        % Main source power.
        sigSourceInd = txInd;
        sigSourcePower = sigStrengths(sigSourceInd);

        intSourceFqs = transmitter_frequencies;
        intSourcePowers = sigStrengths;
        intSourceFqs(sigSourceInd) = [];
        intSourcePowers(sigSourceInd) = [];
        
        % Interference sources power.
        sigSourceFq = transmitter_frequencies(sigSourceInd);
        intSourceInd = (intSourceFqs == sigSourceFq);
        intSourcePowers = intSourcePowers(intSourceInd);
        intSourcePowers = 10.^(intSourcePowers/10);
        interferencePower = sum(intSourcePowers)+ 10^(validated_params.noisePower/10);
        interferencePower = 10*log10(interferencePower);

        receiver_sinr = sigSourcePower - interferencePower;
        sinr_matrix(txInd, rxInd) = receiver_sinr;
    end
end

end
