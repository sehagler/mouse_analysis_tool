function ret_val = general_tasks(flg,data_struct)
%GENERAL_TASKS manage setup and cleanup of algorithm
%   GENERAL_TASKS(FLG,DATA_STRUCT)

% 11/13/12 - Initial revision - Stuart Hagler

    switch flg
        case 'setup'
            ret_val = my_setup(data_struct);
        case 'cleanup'
            ret_val = my_cleanup(data_struct);
        otherwise
            ret_val = false;
    end

end

%%
% --- function to cleanup after running algorithm
%
function ret_val = my_cleanup(data_struct)

    rmpath(data_struct.params.paths.lib_analyze_data_path);
    rmpath(data_struct.params.paths.lib_common);
    rmpath(data_struct.params.paths.lib_pull_data);
    ret_val = true;

end

%%
% --- function to setup before funning algorithm
%
function ret_val = my_setup(data_struct)

    addpath(data_struct.params.paths.lib_analyze_data_path);
    addpath(data_struct.params.paths.lib_common);
    addpath(data_struct.params.paths.lib_pull_data);
    ret_val = true;

end

