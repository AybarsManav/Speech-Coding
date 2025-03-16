root_dir = "database/";
% Find audio files
audio_signal_paths = find_wav_files(root_dir);
n_signals = length(audio_signal_paths);
audio_signals = cell(n_signals, 1);

% Read every audio file in their native forms, here 16 bit integer
for i = 1:n_signals
    audio_signals{i} = audioread(audio_signal_paths{i}, "native");
end

% Make a train and test split of 0.7 to 0.3
train_ratio = 0.7;
train_size = round(train_ratio* n_signals);
rand_indices = randperm(n_signals);
train_signals = audio_signals(rand_indices(1:train_size));
test_signals = audio_signals(rand_indices(train_size+1:end));

%% 
% Parameters could be: block-length, quantization level, quantization type
symbols_per_sample = 1; % 2 or 1, note that if this is 2, then quantization type must be uniform and bits_per_symbol must be 16
bits_per_symbol = 8;
quantization_type = "mu_law"; % "uniform" or "mu_law" 

%% Train
[dict, avg_length] = train_huffman(train_signals, symbols_per_sample, bits_per_symbol, quantization_type);

%% Test
original_test_signal = test_signals{3};
[space_save, snr, reconstructed_signal] = test_huffman(original_test_signal, symbols_per_sample, bits_per_symbol, quantization_type, dict, true);

% To listen to the reconstructed signal
% sound(reconstructed_signal / max(abs(reconstructed_signal)), 8000, 16);

%% Analyze the effect of training set size to performance
score_mat = zeros(train_size, 2);
for n = 1:train_size
    % Train using n signals
    [dict, avg_length] = train_huffman(train_signals(1:n), symbols_per_sample, bits_per_symbol, quantization_type);

    space_save_avg = 0;
    snr = 0;
    % Test on all test signals
    for k = 1:(n_signals - train_size)
        [space_save, snr] = test_huffman(test_signals{k}, symbols_per_sample, bits_per_symbol, quantization_type, dict, false);
        space_save_avg = space_save + space_save_avg;
        snr_avg = snr + snr_avg;
    end
    space_save_avg = space_save_avg / (n_signals - train_size);
    snr_avg = snr_avg / (n_signals - train_size);

    score_mat(n, :) = [space_save_avg, snr_avg];
end

figure; 

space_save_metric = score_mat(:,1);
psnr_values = score_mat(:,2);

yyaxis left;
plot(space_save_metric, '-o', 'Color', [0, 0, 1], 'LineWidth', 2.0, 'MarkerSize', 10);
ylabel("Space Save Metric", 'FontSize', 20);

yyaxis right;
plot(psnr_values, '-s', 'Color', [1, 0, 0], 'LineWidth', 2.0, 'MarkerSize', 10);
ylabel("SNR (dB)", 'FontSize', 20);

title("Compression and Reconstruction Performance", 'FontSize', 25);
xlabel("Train Set Size", 'FontSize', 20);
grid on;

set(gca, 'FontSize', 20);
legend("Space Save Metric", "SNR", 'FontSize', 20, 'Location', 'best');

%% Quantization and compression tradeoff
score_mat_quantization = zeros(4, 2);

% Original 16 bit uniform quantization
symbols_per_sample = 1; 
bits_per_symbol = 16;
quantization_type = "uniform";
[dict, avg_length] = train_huffman(train_signals, symbols_per_sample, bits_per_symbol, quantization_type);

space_save_avg = 0;
snr_avg = 0;
for k = 1:(n_signals - train_size)
    [space_save, snr, ~] = test_huffman(test_signals{k}, symbols_per_sample, bits_per_symbol, quantization_type, dict, false);
    space_save_avg = space_save + space_save_avg;
    snr_avg = snr + snr_avg;
end
space_save_avg = space_save_avg / (n_signals - train_size);
snr_avg = snr_avg / (n_signals - train_size);
score_mat_quantization(1, :) = [space_save_avg, snr_avg];

%% 8 bit uniform quantization
symbols_per_sample = 1; 
bits_per_symbol = 8;
quantization_type = "uniform";
[dict, avg_length] = train_huffman(train_signals, symbols_per_sample, bits_per_symbol, quantization_type);

space_save_avg = 0;
snr_avg = 0;
for k = 1:(n_signals - train_size)
    [space_save, snr, ~] = test_huffman(test_signals{k}, symbols_per_sample, bits_per_symbol, quantization_type, dict, false);
    space_save_avg = space_save + space_save_avg;
    snr_avg = snr + snr_avg;
end
space_save_avg = space_save_avg / (n_signals - train_size);
snr_avg = snr_avg / (n_signals - train_size);
score_mat_quantization(2, :) = [space_save_avg, snr_avg];


%% 16 bit mu-law quantization
symbols_per_sample = 1; 
bits_per_symbol = 16;
quantization_type = "mu_law";
[dict, avg_length] = train_huffman(train_signals, symbols_per_sample, bits_per_symbol, quantization_type);

space_save_avg = 0;
snr_avg = 0;
for k = 1:(n_signals - train_size)
    [space_save, snr, ~] = test_huffman(test_signals{k}, symbols_per_sample, bits_per_symbol, quantization_type, dict, false);
    space_save_avg = space_save + space_save_avg;
    snr_avg = snr + snr_avg;
end
space_save_avg = space_save_avg / (n_signals - train_size);
snr_avg = snr_avg / (n_signals - train_size);
score_mat_quantization(3, :) = [space_save_avg, snr_avg];

%% 8 bit mu-law quantization
symbols_per_sample = 1; 
bits_per_symbol = 8;
quantization_type = "mu_law";
[dict, avg_length] = train_huffman(train_signals, symbols_per_sample, bits_per_symbol, quantization_type);

space_save_avg = 0;
snr_avg = 0;
for k = 1:(n_signals - train_size)
    [space_save, snr, ~] = test_huffman(test_signals{k}, symbols_per_sample, bits_per_symbol, quantization_type, dict, false);
    space_save_avg = space_save + space_save_avg;
    snr_avg = snr + snr_avg;
end
space_save_avg = space_save_avg / (n_signals - train_size);
snr_avg = snr_avg / (n_signals - train_size);
score_mat_quantization(4, :) = [space_save_avg, snr_avg];

%%
quantization_methods = {'16-bit Uniform', '8-bit Uniform', '16-bit μ-law', '8-bit μ-law'};
saved_space = score_mat_quantization(:, 1);
snr_values = score_mat_quantization(:, 2);

figure;
yyaxis left;
bar(saved_space, 'FaceColor', 'b'); 
ylabel('Saved Space', 'FontSize', 18);

yyaxis right;
plot(snr_values, '-ro', 'LineWidth', 2, 'MarkerSize', 10);
ylabel('SNR (dB)', 'FontSize', 18);

set(gca, 'XTickLabel', quantization_methods, 'FontSize', 16);
xlabel('Quantization Method', 'FontSize', 20);
title('Compression vs. Quality Tradeoff', 'FontSize', 22);
grid on;
legend('Saved Space', 'SNR', 'FontSize', 16, 'Location', 'best');






