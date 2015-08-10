function data = pull_sess_calcs(sbjid,data_struct,server)
%PULL_SESS_CALCS pull session beginning and ending datetimes
%   PULL_SESS_CALCS(DATA_STRUCT,SERVER)

% 06/15/14 - Initial revision - Stuart Hagler

    % add mysql path
    addpath(data_struct.params.paths.mysql_toolkit);
    
    % get session beginning and ending datetimes
    data = [];
    [homeid,login_datetime] = my_login_event(sbjid,data_struct,server);
    homeid_vec = unique(homeid);
    for j = 1:length(homeid_vec)
    	idx1 = find(homeid == homeid_vec(j));
    	general_datetime = ...
        	my_general_event(data_struct,server,homeid_vec(j),login_datetime);
     	for k = 1:length(idx1)
         	idx2 = find(general_datetime > login_datetime(idx1(k)));
        	if ~isempty(idx2)
            	data = [ data; sbjid login_datetime(idx1(k)) ...
                         min(general_datetime(idx2)) ];
            else
                data = [ data; sbjid login_datetime(idx1(k)) ...
                         now ];
            end
        end         
    end

    % remove mysql path
    rmpath(data_struct.params.paths.mysql_toolkit);

end

%%
% --- function to get login datetimes for computer
%
function general_datetime = ...
    my_general_event(data_struct,server,homeid,login_datetime)

    % trim to date information
    login_date = floor(login_datetime);
    
    % open db
    ret_val = mysql('open',server{1}.name, ...
                    server{1}.username,server{1}.password);
    
    % query dates
    sql = [ 'SELECT EventDate ' ...
            'FROM ' data_struct.params.proj_info.project '.KCLogin ' ...
            'WHERE HomeId = ' num2str(homeid) ];
    general_date = mysql(sql);
    
    % query times
	sql = [ 'SELECT EventTime ' ...
            'FROM ' data_struct.params.proj_info.project '.KCLogin ' ...
            'WHERE HomeId = ' num2str(homeid) ];
    general_time = mysql(sql);
    
    % close db
    mysql('close');
    
    % package data
    general_datetime = general_date + general_time;
    
end

%%
% --- function to get login datetimes for subject
%
function [homeid,login_datetime] = my_login_event(sbjid,data_struct,server)

    % open db
    ret_val = mysql('open',server{1}.name, ...
                    server{1}.username,server{1}.password);

    % query dates
    sql = [ 'SELECT EventDate ' ...
            'FROM ' data_struct.params.proj_info.project '.KCLogin ' ...
            'WHERE subjectId = ' num2str(sbjid) ' ' ...
            ' AND Success = 1' ];
    login_date = mysql(sql);  
    
    % query times
    sql = [ 'SELECT EventTime ' ...
            'FROM ' data_struct.params.proj_info.project '.KCLogin ' ...
            'WHERE subjectId = ' num2str(sbjid) ' ' ...
            ' AND Success = 1' ];
    login_time = mysql(sql);  
    
    % query home ids
    sql = [ 'SELECT HomeId ' ...
            'FROM ' data_struct.params.proj_info.project '.KCLogin ' ...
            'WHERE subjectId = ' num2str(sbjid) ' ' ...
            ' AND Success = 1' ];
    homeid = mysql(sql);  
    
    % close db
    mysql('close');
    
    % package data
    login_datetime = login_date + login_time;
    
end