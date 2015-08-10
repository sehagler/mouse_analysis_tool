function oadc = get_oadc()
%GET_SCORES Summary of this function goes here
%   Detailed explanation goes here

    [num,txt,raw] = xlsread([pwd '\xls\N83 TO STUART 061714.xls' ]);
    oadc_nums = num;
    for i = 2:size(txt,1)
        dates(i-1,1) = my_get_dates(char(txt(i,2)));
        dates(i-1,2) = my_get_dates(char(txt(i,3)));
    end
    oadc = [ oadc_nums dates ];
    
end

%%
%
%
function date = my_get_dates(txt_date)

    idx = findstr(txt_date,'/');
    if idx(1) == 2
        txt_date = [ '0' txt_date ];
    end
    idx = findstr(txt_date,'/');
    if idx(2) == 5
        txt_date = [ txt_date(1:3) '0' txt_date(4:end) ];
    end
    txt_date = [ txt_date ' 00:00:00' ];
    date = datenum(txt_date,'mm/dd/yyyy HH:MM:SS');

end
