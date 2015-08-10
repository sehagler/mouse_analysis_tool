function session_data = parse_session_data(sbj_data,data_struct,server,...
                                           dates,session_cutoff, ...
                                           min_sessions,max_sessions)
%PARSE_SESSION_DATA Summary of this function goes here
%   Detailed explanation goes here

% 06/15/14 - Initial revision - Stuart Hagler

    % get oadc number
	oadc = sbj_data.oadcnum;
            
	% display subject whose data is being parsed
	fprintf('subject oadc = %d\n',oadc);
       
	% display date range
    fprintf('\tdates = %s to %s\n',datestr(dates(1)),datestr(dates(2)));
                    
    % generate data files for each session
    n = 0;
    if ~isempty(sbj_data.sessions)
        I = (find(sbj_data.sessions(:,1) >= dates(1) & sbj_data.sessions(:,1) < dates(2)))';
        if length(I) >= min_sessions
            if ~isinf(max_sessions)
                if length(I) > max_sessions
                    idxs = randperm(length(I));
                    idxs = sort(idxs(1:max_sessions));
                    I = I(idxs);
                end
            end
            for i = I
                drawnow;
                n = n + 1;
                sbj_data.sessions(i,2) = ...
                    min([sbj_data.sessions(i,2),sbj_data.sessions(i,1) + session_cutoff]);
                session_data_tmp = ...
                    my_parse_session(data_struct,server,sbj_data,i);
                [session_w_neg,session_w_pos,session_idle] = ...
                    analyze_session(session_data_tmp);
                session_data{n}.sbj = session_data_tmp.sbj;
                session_data{n}.rho = session_data_tmp.rho;
                session_data{n}.w_neg = session_w_neg;
                session_data{n}.w_pos = session_w_pos;
                session_data{n}.idle = session_idle;
            end
        else
            session_data = [];
        end 
    else
        session_data = [];
    end

end

%%
% --- function to generate the data file for a session
%
function session_data = my_parse_session(data_struct,server,sbj_data,k)

    % empty data structure
	data = [];

	% display login being parsed
	fprintf('\tlogin %d - %s\n',k, ...
            datestr(sbj_data.sessions(k,1)));
        
	% get oadc number
	oadc = sbj_data.oadcnum;
    session_data = pull_session(data_struct,server,sbj_data,k);
    if ~isempty(session_data)
    	[parsed_data,vc] = parse_mouse_data(data_struct,session_data);
        session_data.rho = log10(vc);
        session_data.parsed_data = parsed_data;
        session_data.sbj = sbj_data;
    else
    	fprintf('\t\session is empty!\n');
        session_data.rho = [];
        session_data.parsed_data = [];
        session_data.sbj = sbj_data;
    end
    
    % set return value
    ret_val = true;

end

