function server = get_server_info()
%GET_SERVER_INFO prompt user for username and password
%   GET_SERVER_INFO()

% 08/10/15 - Initial revision - Stuart Hagler
% 08/10/15 - User can specify server - Stuart Hagler

    server{1}.name = input('Enter server:  ', 's');
    server{1}.username = input('Enter username:  ', 's');
    server{1}.password = input('Enter password:  ', 's');

end

