function prepared_data = prepare_data(raw_data)
%PREPARE_DATA reexpress session data in a more convenient form
%   PREPARE_DATA(RAW_DATA)

% 11/13/12 - Initial revision - Stuart Hagler

    % session length
    session = [ 0 raw_data.session_end_time-raw_data.session_start_time ];
    
    % reexpress data (if there is any)
    if ~isempty(raw_data.cursor_times)
    
        % cursor times in msec
        T = 24*60*60*1000*(raw_data.cursor_times - raw_data.session_start_time);

        % initial cursor position
        T0 = 24*60*60*1000*(raw_data.cursor_times(1) - raw_data.session_start_time);
        X0 = raw_data.cursor_X_pos(1);
        Y0 = raw_data.cursor_Y_pos(1);

        % initialize variables
        DT = diff(T);
        DX = diff(raw_data.cursor_X_pos);
        DY = diff(raw_data.cursor_Y_pos);

        % drop data points
        idx1 = find(DT == 0);
        idx2 = find(DX == 0);
        idx3 = find(DY == 0);
        idx = union(idx1,intersect(idx2,idx3));
        DT(idx) = [];
        DX(idx) = [];
        DY(idx) = [];

        % generate event sequences
        T = T0 + [ 0; cumsum(DT) ];
        X = X0 + [ 0; cumsum(DX) ];
        Y = Y0 + [ 0; cumsum(DY) ];
        
    else
        
        T = [];
        X = [];
        Y = [];
        
    end
    
    % package results
    prepared_data.cursor = [ T X Y ];
    prepared_data.session = session;

end