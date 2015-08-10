function data_use = pull_session(data_struct,server,sbj_data,session_num)
%PULL_SESSION pull usage data for a particular computer session
%   PULL_SESSION(DATA_STRUCT,SERVER,SBJ_DATA,SESSION_NUM)

% 11/13/12 - Initial revision - Stuart Hagler

    % add path to matlab mysql scripts
    addpath(data_struct.params.paths.mysql_toolkit);
    
    % get data for session
    if length(sbj_data.sessions(session_num,:)) == 2 && ...
       isempty(find(isnan(sbj_data.sessions(session_num,:)),1))
        data_use = my_get_usage_data(data_struct,server,sbj_data.sbjid, ...
                                     sbj_data.sessions(session_num,:));
    elseif (length(sbj_data.sessions(session_num,:)) == 2 && ...
            ~isempty(find(isnan(sbj_data.sessions(session_num,:)),1))) || ...
           length(sbj_data.sessions(session_num,:)) == 1
        sbj_data.sessions(session_num,2) = now;
        msg_str = ['\tbad end datetime\n\t\t\t  using '   ...
                   datestr(now,'dd-mmm-yyyy HH:MM:SS') '\n'];
        fprintf(msg_str);
        data_use = my_get_usage_data(data_struct,server,sbj_data.sbjid,...
                                     sbj_data.sessions(session_num,:));
    else
        fprintf('\tbad start datetime\n');
        data_use = [];
    end
    
    % remove path to matlab mysql scripts
    rmpath(data_struct.params.paths.mysql_toolkit);

end

%%
% --- function to pull computer usage data
%
function data_use = my_get_usage_data(data_struct,server,id,session)

    % get beginning and ending datetimes
    datetime0 = session(1);
    datetime1 = session(2);
    
    % initialize temporary tables
    ret_val = tmp_tbls('create',data_struct,server,id,datetime0,datetime1);
    
    % read temporary tables
	try
        data_use = tmp_tbls('read',data_struct,server,id,datetime0,datetime1);
    catch
        fprintf('\t\tfailed to read data table!\n');
    	mysql('close');
    	data_use = [];
    end
    
end