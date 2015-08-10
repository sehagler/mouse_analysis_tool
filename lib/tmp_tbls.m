function data = tmp_tbls(mode,data_struct,server,id,start_datetime_str,end_datetime_str)
%TMP_TBLS manage temporary tables created in mysql query process
%   TMP_TBLS(MODE,DATA_STRUCT,SERVER,ID,START_DATETIME_STR,END_DATETIME_STR
%   )

% 11/13/12 - Initial revision - Stuart Hagler

    % identify temporary tables
    tmp_tbls.app_tmp = 'test.app_tmp';
    tmp_tbls.key_tmp = 'test.key_tmp';
    tmp_tbls.mouse_tmp = 'test.mouse_tmp';
    
    % check mode and do required actions
    switch mode
        case 'create'
            data = my_create_tbls(data_struct,server,id, ...
                                  start_datetime_str,end_datetime_str,tmp_tbls);
        case 'read'
            data = my_read_tbls(data_struct,server,start_datetime_str, ...
                                end_datetime_str,tmp_tbls);
    end

end

%%
% --- function to create temporary tables
%
function ret_val = my_create_tbls(data_struct,server,id,start_date_str, ...
                                  end_date_str,tmp_tbls)

    % open db
    ret_val = mysql('open',server{1}.name, ...
                    server{1}.username,server{1}.password);

    % drop existing temporary tables
    ret_val = mysql([ 'DROP TABLE IF EXISTS ' tmp_tbls.app_tmp  ]);
    ret_val = mysql([ 'DROP TABLE IF EXISTS ' tmp_tbls.key_tmp  ]);
    ret_val = mysql([ 'DROP TABLE IF EXISTS ' tmp_tbls.mouse_tmp  ]);

    % create application data table
    ret_val = mysql([ 'CREATE TABLE ' tmp_tbls.app_tmp ' ( ' ...
                      'EventDate date, ' ...
                      'EventTime time, ' ...
                      'MSec smallint(6), ' ...
                      'AppPath varchar(250), ' ...
                      'AppTitle varchar(250) );' ]);

    % create key data table
    ret_val = mysql([ 'CREATE TABLE ' tmp_tbls.key_tmp ' ( ' ...
                      'EventDate date, ' ...
                      'EventTime time, ' ...
                      'MSec smallint(6) );' ]);

    % create mouse data table
    ret_val = mysql([ 'CREATE TABLE ' tmp_tbls.mouse_tmp ' ( ' ...
                      'EventDate date, ' ...
                      'EventTime time, ' ...
                      'MSec smallint(6), ' ...
                      'EventID varchar(10), ' ...
                      'XPos smallint(6), ' ...
                      'YPos smallint(6) );' ]);
                  
    % parse datetime values
    enddatenum = datenum(end_date_str);
    enddate = floor(enddatenum);
    endtime = enddatenum - enddate;
    startdatenum = datenum(start_date_str);
    startdate = floor(startdatenum);
    starttime = startdatenum - startdate;

    % populate temporary tables
    if startdate == enddate
        
        date_str = datestr(startdate,'yyyy-mm-dd');
        starttimestr = datestr(starttime,'HH:MM:SS');
        endtimestr = datestr(endtime,'HH:MM:SS');
        
        sql = [ 'INSERT INTO ' tmp_tbls.app_tmp ' ' ...
                'SELECT EventDate, EventTime, MSec, AppPath, AppTitle ' ...
                'FROM BRP.KCAppChange ' ...
                'WHERE EventDate = ''' date_str ''' ' ...
                ' AND (EventTime BETWEEN ''' starttimestr ''' AND ''' endtimestr ''') '...
                ' AND subjectId = ' num2str(id) ];
        ret_val = mysql(sql);

        sql = [ 'INSERT INTO ' tmp_tbls.key_tmp ' ' ...
                'SELECT EventDate, EventTime, MSec ' ...
                'FROM BRP.KCKeyData ' ...
                'WHERE EventDate = ''' date_str ''' ' ...
                ' AND (EventTime BETWEEN ''' starttimestr ''' AND ''' endtimestr ''') '...
                ' AND subjectId = ' num2str(id) ];
        ret_val = mysql(sql);
        
        sql = [ 'USE KCMouseData' ];
        ret_val = mysql(sql);
        
        sql = [ 'SHOW TABLES LIKE ''subject_' num2str(id) ''' ' ];
        ret_val = mysql(sql);
        
        if ~isempty(ret_val)
            sql = [ 'INSERT INTO ' tmp_tbls.mouse_tmp ' ' ...
                    'SELECT EventDate, EventTime, MSec, EventID, XPos, YPos ' ...
                    'FROM KCMouseData.subject_' num2str(id) ' ' ...
                    'WHERE EventDate = ''' date_str ''' ' ...
                    ' AND (EventTime BETWEEN ''' starttimestr ''' AND ''' endtimestr ''')' ];
            ret_val = mysql(sql);
        else
            fprintf('\terror - couldn''t find table KCMouseData.subject_%s\n',num2str(id));
        end
        
    else
    
        datestr1 = datestr(startdate,'yyyy-mm-dd');
        datestr2 = datestr(startdate+1,'yyyy-mm-dd');
        datestr3 = datestr(enddate-1,'yyyy-mm-dd');
        datestr4 = datestr(enddate,'yyyy-mm-dd');
        
        starttimestr = datestr(starttime,'HH:MM:SS');
        endtimestr = datestr(endtime,'HH:MM:SS');

        sql = [ 'INSERT INTO ' tmp_tbls.app_tmp ' ' ...
                'SELECT EventDate, EventTime, MSec, AppPath, AppTitle ' ...
                'FROM BRP.KCAppChange ' ...
                'WHERE ( (EventDate = ''' datestr1 ''' AND EventTime >= ''' starttimestr ''') ' ...
                '        OR (EventDate BETWEEN ''' datestr2 ''' AND ''' datestr3 ''') '...
                '        OR (EventDate = ''' datestr4 ''' AND EventTime <= ''' endtimestr ''') ) '...
                ' AND subjectId = ' num2str(id) ];
        ret_val = mysql(sql);

        sql = [ 'INSERT INTO ' tmp_tbls.key_tmp ' ' ...
                'SELECT EventDate, EventTime, MSec ' ...
                'FROM BRP.KCKeyData ' ...
                'WHERE ( (EventDate = ''' datestr1 ''' AND EventTime >= ''' starttimestr ''') ' ...
                '        OR (EventDate BETWEEN ''' datestr2 ''' AND ''' datestr3 ''') '...
                '        OR (EventDate = ''' datestr4 ''' AND EventTime <= ''' endtimestr ''') ) '...
                ' AND subjectId = ' num2str(id) ];
        ret_val = mysql(sql);
        
                sql = [ 'USE KCMouseData' ];
        ret_val = mysql(sql);
        
        sql = [ 'SHOW TABLES LIKE ''subject_' num2str(id) ''' ' ];
        ret_val = mysql(sql);
        
        if ~isempty(ret_val)
            sql = [ 'INSERT INTO ' tmp_tbls.mouse_tmp ' ' ...
                    'SELECT EventDate, EventTime, MSec, EventID, XPos, YPos ' ...
                    'FROM KCMouseData.subject_' num2str(id) ' ' ...
                    'WHERE ( (EventDate = ''' datestr1 ''' AND EventTime >= ''' starttimestr ''') ' ...
                    '        OR (EventDate BETWEEN ''' datestr2 ''' AND ''' datestr3 ''') '...
                    '        OR (EventDate = ''' datestr4 ''' AND EventTime <= ''' endtimestr ''') )' ];
            ret_val = mysql(sql);
        else
            fprintf('\terror - couldn''t find table KCMouseData.subject_%s\n',num2str(id));
        end
    
    end

    % close db
    mysql('close');

    % set return value
    ret_val = true;

end


%%
% --- function to perform db application queries
%
function app_array = my_get_app_data(data_struct,server,tmp_tbl)

    ret_val = mysql('open',server{1}.name, ...
                    server{1}.username,server{1}.password);

    sql = [ 'SELECT EventDate ' ...
            'FROM ' tmp_tbl.app_tmp ];
    AppDate = mysql(sql);
    
    sql = [ 'SELECT EventTime ' ...
            'FROM ' tmp_tbl.app_tmp ];
    AppTime = mysql(sql);
    
	sql = [ 'SELECT MSec ' ...
            'FROM ' tmp_tbl.app_tmp ];
    AppMsec = mysql(sql);
    
    sql = [ 'SELECT AppPath ' ...
            'FROM ' tmp_tbl.app_tmp ];
    AppPath = mysql(sql);
    
    sql = [ 'SELECT AppTitle ' ...
            'FROM ' tmp_tbl.app_tmp ];
    AppTitle = mysql(sql);
    
    mysql('close');
    
	app_array.timestamp = AppDate + AppTime + AppMsec/(24*60*60*1000);
	app_array.path = AppPath;
	app_array.title = AppTitle;
    
end

%%
% --- function to perform db key queries
%
function key_array = my_get_key_data(data_struct,server,tmp_tbl)

    % open db
    ret_val = mysql('open',server{1}.name, ...
                    server{1}.username,server{1}.password);

    % query event date data
    sql = [ 'SELECT EventDate ' ...
            'FROM ' tmp_tbl.key_tmp ];
    KeyDate = mysql(sql);
    
    % query event time (to seconds) data
    sql = [ 'SELECT EventTime ' ...
            'FROM ' tmp_tbl.key_tmp ];
    KeyTime = mysql(sql);
    
    % query event milliseconds data
    sql = [ 'SELECT MSec ' ...
            'FROM ' tmp_tbl.key_tmp ];
    KeyMsec = mysql(sql);
    
    % close db
    mysql('close');
    
    % package data
    key_array = KeyDate + KeyTime + KeyMsec/(24*60*60*1000);
    
end

%%
% --- function to perform db mouse queries
%
function mouse_array = my_get_mouse_data(data_struct,server,tmp_tbl)

    % open db
    ret_val = mysql('open',server{1}.name, ...
                    server{1}.username,server{1}.password);

    % query event date data
    sql = [ 'SELECT EventDate ' ...
            'FROM ' tmp_tbl.mouse_tmp ];
    MouseDate_tmp = mysql(sql);
    
    % query event time data
    sql = [ 'SELECT EventTime, EventID, MSec ' ...
            'FROM ' tmp_tbl.mouse_tmp ];
    [MouseTime_tmp,dummy,MouseMsec_tmp] = mysql(sql);
    clear dummy;
    
    % package time data and clear unneeded data
    MouseDateTime_tmp = MouseDate_tmp + ...
                        MouseTime_tmp + ...
                        MouseMsec_tmp/(24*60*60*1000);
    clear MouseData_tmp MouseTime_tmp MouseMsec_tmp;
    
    % query mouse position data
    sql = [ 'SELECT XPos, EventID, YPos ' ...
            'FROM ' tmp_tbl.mouse_tmp ];
    [MouseX_tmp,dummy,MouseY_tmp] = mysql(sql);
    clear dummy;
    
    % close db
    mysql('close')
    
    % package data and clear unneeded data
    mouse_array = [ MouseDateTime_tmp MouseX_tmp MouseY_tmp ];
    clear MouseDateTime_tmp MouseX_tmp  MouseY_tmp;
    
    % eliminate bad data values and sort by time
    idx = find(sign(sum(isnan(mouse_array),2)) == 1);
    mouse_array(idx,:) = [];
    mouse_array = sortrows(mouse_array,1);
    
end

%%
% --- function to read temporary tables
%
function data = my_read_tbls(data_struct,server,start_datetime_str, ...
                             end_datetime_str,tmp_tbls)

    % query db
    app_array = ...
        my_get_app_data(data_struct,server,tmp_tbls);
    %key_array = ...
    %    my_get_key_data(data_struct,server,tmp_tbls);
    mouse_array = ...
        my_get_mouse_data(data_struct,server,tmp_tbls);

    % create data structure
    data.applications.path = app_array.path;
    data.applications.title = app_array.title;
    data.application_times = app_array.timestamp;
    data.cursor_times = mouse_array(:,1);
    data.cursor_X_pos = mouse_array(:,2);
    data.cursor_Y_pos = mouse_array(:,3); 
    data.session_start_time = start_datetime_str;
    data.session_end_time = end_datetime_str;

end
