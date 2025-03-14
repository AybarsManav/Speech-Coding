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
train_size = round(0.7 * n_signals);
rand_indices = randperm(n_signals);
train_signals = audio_signals(rand_indices(1:train_size));
test_signals = audio_signals(rand_indices(train_size+1:end));

%% 
% Parameters could be: block-length, quantization level, quantization type
bits_per_sample = 16;
quantization_type = "uniform";

%% Train
[dict, avg_length] = train_huffman(train_signals, bits_per_sample, quantization_type);


%% Test
original_test_signal = test_signals{1};
test_huffman(original_test_signal, bits_per_sample, quantization_type, dict, true);














