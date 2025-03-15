function [dict, avg_length] = train_huffman(train_signals, bits_per_sample, quantization_type)
% Concat train samples to one big sequence to extract frequencies
train_size = length(train_signals);
train_signal = [];
for i = 1:train_size
    train_signal = [train_signal; train_signals{i}];
end

train_signal = double(train_signal);

if quantization_type == "mu_law"
    mu = 255;
    train_signal = compand(train_signal, mu, max(abs(train_signal)), "mu/compressor");
end

% Quantize with lower levels than 16 bits (originally 16)
if bits_per_sample ~= 16 || quantization_type ~= "uniform"
    n_levels = 2^bits_per_sample;
    train_signal = double(train_signal) / 2^15; % [-1, 1]
    audio_quantized = floor(train_signal * (n_levels / 2));
else
    audio_quantized = train_signal;
end

% Make a table to use groupcounts()
T = table(audio_quantized);
grouped_data = groupcounts(T, 'audio_quantized');
symbols = grouped_data.audio_quantized;
counts = grouped_data.GroupCount;

% Compute probabilities
probabilities = counts' / sum(counts);

% Compute entropy
computed_entropy = computeEntropy(probabilities);
fprintf("Entropy of the used train set is %.2f\n", computed_entropy);

% Get the dictionary
[dict, avg_length] = huffmandict(symbols, probabilities);
end
