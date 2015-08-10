function params = get_params_struct()
%GET_PARAMS_STRUCT Summary of this function goes here
%   GET_PARAMS_STRUCT(PROJ)

% 06/15/14 - Initial revision - Stuart Hagler

    % algorithm base parameters
    params.fitts_law_offset     = 1;
    params.log_vel_kernal_width = 0.15;
    params.lambda               = 0.5;
    params.max_event_duration   = 5000;
    params.min_num_good_moves   = 10;
    params.min_num_sessions     = 10;
    params.min_points_in_move   = 2;
    params.phi_cutoff           = 1;
    params.target_width         = 40;
    
    % algorithm paths
    params.paths.mysql_toolkit = './mySqlMatlab';

end

