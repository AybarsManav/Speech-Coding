function [space_save, snr, reconstructed_signal] = test_huffman(original_test_signal, symbols_per_sample, bits_per_symbol, quantization_type, dict, plot_stuff)
% Quantize the signal similarly
n_levels = 2 ^ bits_per_symbol;

% Seperate 16 bit symbols into 2 - 8 bits
if symbols_per_sample == 2
    test_signal = typecast(original_test_signal, "int8");
else
    test_signal = original_test_signal;
end

test_signal = double(test_signal);
if quantization_type == "mu_law"
    mu = 255;
    test_signal = compand(test_signal, mu, max(abs(test_signal)), "mu/compressor");
end

if bits_per_symbol ~= 16 || quantization_type ~= "uniform"
    n_levels = 2^bits_per_symbol;
    test_signal = double(test_signal) / 2^15; % [-1, 1]
    audio_quantized = floor(test_signal * (n_levels / 2));
else
    audio_quantized = test_signal;
end


%% Encoding + additional missing symbol handling
tic;
% To handle missing symbols in the codec, I use the closest symbols to the
% input symbols.
train_symbols = cell2mat(dict(: , 1));
encoded_data = [];
for i = 1:length(audio_quantized)
    symbol = audio_quantized(i);
    
    % Check if symbol exists in Huffman dictionary
    if ~ismember(symbol, train_symbols)
        % Find the nearest available symbol
        [~, idx] = min(abs(train_symbols - symbol)); % Nearest neighbor search
        nearest_symbol = train_symbols(idx);
        audio_quantized(i) = nearest_symbol; % Change the symbol with the nearest symbol in codec
    end
end
encoded_data = huffmanenco(audio_quantized, dict);
encode_time = toc;
%% Decoding + use the original dictionary while decoding
tic;
decoded_data = huffmandeco(encoded_data, dict);

if quantization_type == "mu_law"
    reconstructed_signal = compand(decoded_data, mu, max(abs(decoded_data)), 'mu/expander');
else
    reconstructed_signal = decoded_data;
end

if symbols_per_sample == 2
    reconstructed_signal = typecast(int8(reconstructed_signal), 'int16');
end

% Reconstruction Error
decoded_time = toc;


fprintf('Encoding Time: %.4f sec\n', encode_time);
fprintf('Decoding Time: %.4f sec\n', decoded_time);

% To make reconstructed signal have the same scale as the original
reconstructed_signal = double(reconstructed_signal) * 2^(16 - bits_per_symbol);

MSE = mean((reconstructed_signal  - double(original_test_signal)).^2 );
fprintf('MSE = %.3f \n', MSE);

signal_power = sum((double(original_test_signal)).^2);
noise_power = sum((double(original_test_signal) - reconstructed_signal).^2);
snr = 10 * log10(signal_power) - 10 * log10(noise_power);
fprintf('SNR = %.3f \n', snr);

if plot_stuff
figure; 
plot(original_test_signal, "Color", [0, 0, 1], 'LineWidth', 2.0); hold on;
plot(reconstructed_signal, "Color", [1, 0, 0], 'LineWidth', 1.0); hold off;
legend("Original Signal", "Reconstructed Signal", 'FontSize', 20); grid on;
title("Comparison", 'FontSize', 25);
xlabel("Sample Index", 'FontSize', 20);
ylabel("Amplitude", 'FontSize', 20);
set(gca, 'FontSize', 20);
x_limits = xlim; 

figure; 
bar((reconstructed_signal  - double(original_test_signal)).^2, "red");
title("Samplewise Squared Error", 'FontSize', 25); grid on;
xlabel("Sample Index", 'FontSize', 20);
ylabel("Squared Error", 'FontSize', 20);
xlim(x_limits);
set(gca, 'FontSize', 20);
end

% Compression rate
original_size = numel(original_test_signal) * 16; % Originally 16 bit per sample
compressed_size = numel(encoded_data);

compression_ratio = original_size / compressed_size;
fprintf('compression_ratio = %.3f \n', compression_ratio);
space_save =  1 - 1/compression_ratio;
fprintf('space saving = %.3f \n', space_save);

T = table(audio_quantized);
grouped_data = groupcounts(T, 'audio_quantized');
symbols = grouped_data.audio_quantized;
counts = grouped_data.GroupCount;

% Compute probabilities
probabilities = counts' / sum(counts);

% Compute entropy
computed_entropy = computeEntropy(probabilities);
fprintf("Entropy of the used test signal is %.2f\n", computed_entropy);
end