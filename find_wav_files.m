function wav_files = find_wav_files(root_dir)
    % Recursively find all .wav files in root_dir and its subdirectories
    % INPUT: root_dir - Root directory to start the search (string)
    % OUTPUT: wav_files - Cell array of full paths to .wav files
    
    wav_files = {};  % Initialize empty cell array
    
    % Get list of all files and folders in root_dir
    files_and_dirs = dir(root_dir);
    
    % Loop through each entry
    for i = 1:length(files_and_dirs)
        % Get name and full path
        name = files_and_dirs(i).name;
        full_path = fullfile(root_dir, name);
        
        % Skip '.' and '..' (special directories)
        if strcmp(name, '.') || strcmp(name, '..')
            continue;
        end
        
        % Check if it's a directory
        if files_and_dirs(i).isdir
            % Recursive call to search inside the subdirectory
            subdir_files = find_wav_files(full_path);
            % Append found files to the main list
            wav_files = [wav_files; subdir_files]; 
        elseif endsWith(name, '.wav', 'IgnoreCase', true)
            % If it's a .wav file, add it to the list
            wav_files{end+1, 1} = full_path;
        end
    end
end
