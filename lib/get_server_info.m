function server = get_server_info()
%GET_SERVER_INFO prompt user for username and password
%   GET_SERVER_INFO()

% 11/13/12 - Initial revision - Stuart Hagler

    server{1}.name = 'mysql1.bme.ohsu.edu';
    server{1}.username = input('Enter your mysql1 username:  ', 's');
    server{1}.password = input('Enter your mysql1 password:  ', 's');

end

