function sbj_data = pull_sbj_data(oadcnum,data_struct,server)
%PULL_SBJ_DATA pull data for all subjects
%   PULL_SBJ_DATA(DATA_STRUCT,SERVER)

% 03/27/14 - Initial revision - Stuart Hagler

    % add mysql path
    addpath(data_struct.params.paths.mysql_toolkit);
    
    % get subject data
    sbj_data.oadcnum = oadcnum;
    sbj_data.sbjid = my_subject_sbjid(oadcnum,data_struct,server);
    sbj_data.dob = my_subject_dob(sbj_data.sbjid,data_struct,server);
    sbj_data.gender = my_subject_gender(sbj_data.sbjid,data_struct,server);

    % get session beginning and ending datetimes
    sess_data = pull_sess_calcs(sbj_data.sbjid,data_struct,server);
    
    if ~isempty(sess_data)
        sbj_data.sessions = sess_data(:,[2,3]);
    else
        sbj_data.sessions = [];
    end
    
    % remove mysql path
    rmpath(data_struct.params.paths.mysql_toolkit);

end
    
%%
% --- function to get subject date of birth
%
function dob = my_subject_dob(sbjid,data_struct,server)

    % open db
    ret_val = mysql('open',server{1}.name, ...
                    server{1}.username,server{1}.password);
    % query date of birth
    sql = [ 'SELECT DOB ' ...
            'FROM subjects_new.subjects ' ...
            'WHERE idx = ' num2str(sbjid) ];
    dob = unique(mysql(sql));
    
    % close db
    mysql('close');
    
end

%%
% --- function to get subject gender
%
function gender = my_subject_gender(sbjid,data_struct,server)

    % open db
    ret_val = mysql('open',server{1}.name, ...
                    server{1}.username,server{1}.password);

    % query gender
    sql = [ 'SELECT Gender ' ...
            'FROM subjects_new.subjects ' ...
            'WHERE idx = ' num2str(sbjid) ];
    gender = unique(mysql(sql));
    
    % close db
    mysql('close');
    
end
    
%%
% --- function to get subject oadc numbers
%
function sbjid = my_subject_sbjid(oadcnum,data_struct,server)

    % open db
    ret_val = mysql('open',server{1}.name, ...
                    server{1}.username,server{1}.password);

    % query oadc number
    sql = [ 'SELECT idx ' ...
            'FROM subjects_new.subjects ' ...
            'WHERE OADC = ' num2str(oadcnum) ];
    sbjid = unique(mysql(sql));
    
    % restrict to single subject id if necessary
    sbjid = sbjid(1);
    
    % close db
    mysql('close');
    
end