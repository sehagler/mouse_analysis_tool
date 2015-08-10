clear all

% get list of oadc numbers
oadc = get_oadc();

% use only data from beginning of session to cutoff
session_cutoff = 1/24;

% project name in MySql database
project_name = 'BRP';

% ignore date interval if there are fewer sessions than minimum
min_sessions = 1;

% maximum number of sessions analyzed in one date interval
max_sessions = inf;

% setup
addpath([ pwd '/lib' ]);
data_struct.params = get_params_struct();
server = get_server_info();

% analyze all oadcs for all dates
for i = 1:size(oadc,1)
    
    oadcnum = oadc(i,1);
    num_days = 28;
    num_weeks = (oadc(i,3)-oadc(i,2))/num_days;
    for j = 1:num_weeks
        dates(j,:) = [ oadc(i,2)+(j-1)*num_days oadc(i,2)+j*num_days ];
    end

    m = i;
    n = 0;
    for j = 1:size(dates,1)
        n = n + 1;
        analyzed_data{m}{n} = ...
            mouse_analysis_tool(oadcnum,dates(j,:),data_struct,server, ...
                                session_cutoff,project_name,min_sessions, ...
                                max_sessions);
        analyzed_data{m}{n}
        save ./mat/analyzed_data
    end
end