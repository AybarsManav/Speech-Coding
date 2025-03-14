function test_huffman(original_test_signal, bits_per_sample, quantization_type, dict, plot_stuff)
% Quantize the signal similarly
n_levels = 2 ^ bits_per_sample;

if bits_per_sample ~= 16
    n_levels = 2^bits_per_sample;
    test_signal = double(original_test_signal) / 2^15; % [-1, 1]
    test_signal = floor(test_signal * (n_levels / 2));
else
    test_signal = original_test_signal;
end

% Quantize using dpcm 
if quantization_type == "dpcm"
    audio_quantized = diff(test_signal);
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
decoded_time = toc;

fprintf('Encoding Time: %.4f sec\n', encode_time);
fprintf('Decoding Time: %.4f sec\n', decoded_time);

% Reconstruction Error
if quantization_type == "dpcm"
    reconstructed_signal = cumsum([audio_quantized(1); decoded_data]);
else
    reconstructed_signal = decoded_data;
end

% To make reconstructed signal have the same scale as the original
reconstructed_signal = double(reconstructed_signal) * 2^(16 - bits_per_sample);

RMSE = sqrt(mean((reconstructed_signal  - double(original_test_signal)).^2 ));
fprintf('RMSE = %.3f \n', RMSE);

if plot_stuff
    figure; 
    subplot(2, 1, 1);
    plot(original_test_signal, "Color", [1, 0, 0]); hold on;
    plot(reconstructed_signal, "Color", [0, 0, 1]); hold off;
    legend("Original Signal", "Reconstructed Signal");
    title("Comparison");
    x_limits = xlim;
    subplot(2, 1, 2); 
    bar((reconstructed_signal  - double(original_test_signal)).^2, "red");
    title("Samplewise Squared Error");
    xlim(x_limits);
end

% Compression rate
original_size = numel(original_test_signal) * 16; % Originally 16 bit per sample
compressed_size = numel(encoded_data);

compression_ratio = original_size / compressed_size;
fprintf('compression_ratio = %.3f \n', compression_ratio);
end