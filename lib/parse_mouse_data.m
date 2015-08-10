function [analyzed_data,vc] = parse_mouse_data(data_struct,data)
%PARSE_MOUSE_DATA identify mouse moves in a particular session data set
%   PARSE_MOUSE_DATA(DATA_STRUCT,DATA,EVENTS)

% 06/22/14 - Initial revision - Stuart Hagler

    % parameters
    font_name = 'Times';
    font_size = 16;
    kernal_width = 100;
    line_width = 2;
    
    % identify mouse moves (if data looks okay)
    if ~isempty(data)      
        [analyzed_data,vc,Xi,Xi0] = my_partition_wrpr(data_struct,data);
    else
    	analyzed_data = my_clear_variables(); 
        Xi = [];
        Xi0 = [];
    end
    
    %
    if size(analyzed_data.cursor,1) ~= 0 && ...
       size(analyzed_data.cursor,2) ~= 0 
    	analyzed_data.cursor(:,2) = round(analyzed_data.cursor(:,2));
	end
    
    % plots
    if false %~isempty(analyzed_data.cursor)
        if length(unique(analyzed_data.cursor(:,1))) > 200
            figure(1)
            ret_val = my_plot_vel_density(data_struct,analyzed_data,Xi,Xi0,font_name,font_size,line_width);
            figure(2)
            ret_val = my_plot_mouse_moves(analyzed_data,font_size,line_width);
            pause
        end
    end

end

%%
% --- function to empty variables
%
function analyzed_data = my_clear_variables()
    analyzed_data.cursor = [];
    analyzed_data.session = [];
end

%%
% --- function to identify pauses between moves
%
function [x_idx,x0] = my_identify_pauses(x,n)

    X = sort(x);
    x0 = X(n);
    if ~isempty(x)
        x_idx = [1; find(x < x0)+1; length(x)+2];
    else
        x_idx = [1; length(x)+2];
    end

end

%%
% --- function to identify pauses between moves
%
function [x_idx,x0] = my_identify_pauses2(x,x0)

    if ~isempty(x)
        x_idx = [1; find(x < x0)+1; length(x)+2];
    else
        x_idx = [1; length(x)+2];
    end

end

%%
% --- function to identify velocity cutoff between moves and pauses
%
function log_vc = my_log_vel_cutoff(data_struct,Xi)

    %
    kernal_width = data_struct.params.log_vel_kernal_width;
    
    %
    N = 0;
    while N < 10
        
        % approximate log-distribution
        [f,xi] = ksdensity(Xi,'width',kernal_width,'npoints',500);
                  
        % restrict to ignore edge effects
        idx1 = find(xi < -2);
        idx2 = find(xi > 0);
        idx = union(idx1,idx2);
        xi(idx) = [];
        f(idx) = [];

        % approximate derivatives
        df = diff(f);
        ddf = diff(diff(f));
        
        % find regions that are concave upward
        idx1 = find(ddf >= 0);
        didx1 = diff(idx1);
        idx2 = [ 0 find(didx1 > 1) length(idx1) ];
        idx = [];
        for i = 1:length(idx2)-1
            idx_tmp = idx1(idx2(i)+1:idx2(i+1));
            if min(f(idx_tmp)) ~= f(idx_tmp(1)) && ...
                min(f(idx_tmp)) ~= f(idx_tmp(end))
                idx = [ idx idx_tmp ];
            end
        end

        %
        if ~isempty(idx)
            min_idx = idx(find(f(idx) == min(f(idx))));
            N = inf;
        else
            min_idx = nan;
            N = N + 1;
        end
        
    end
    
    if ~isnan(min_idx)
        log_vc = xi(min_idx(end));
    else
        log_vc = nan;
    end

end

%%
%
%
function [M,P,X,Y] = my_moves_and_pauses_matries(analyzed_data)

    m = analyzed_data.cursor(:,[1,2]);
    x = analyzed_data.cursor(:,[1,3]);
    y = analyzed_data.cursor(:,[1,4]);
    z = unique(m(:,1));
    
    % create moves matrix
    for i = 1:length(z)
        idx = find(m(:,1) == z(i));
        M(i,:) = [ m(idx(1),2) m(idx(end),2) ];
        X(i,:) = [ x(idx(1),2) x(idx(end),2) ];
        Y(i,:) = [ y(idx(1),2) y(idx(end),2) ];
    end

    % create pauses matrix
    P(1,:) = [ -60000 M(1,1)-1 ];
    for i = 2:size(M,1)
        P(i,:) = [ M(i-1,2)+1 M(i,1)-1 ];
    end
    P(end+1,:) = [ M(end,2)+1 M(end,2)+60001 ];

end

%%
% --- function to partition and individual session
%
function [analyzed_data,vc,Xi,Xi0] = my_partition(data_struct,prepared_data)

	% get values needed for partitioning
	t     = diff(prepared_data.cursor(:,1));
	tau   = mode(t);
	x     = diff(prepared_data.cursor(:,2));
	y     = diff(prepared_data.cursor(:,3));
	[Q,d] = cart2pol(x,y);

	% generate action and velocity values
	s = (d.^2)./t;
    v = d./t;

	% trim data for very long time intervals
	idx = find(t < data_struct.params.max_event_duration);
    d_trimmed = d(idx);
	s_trimmed = s(idx);
	t_trimmed = t(idx);

	% construct action vectors
    D0 = [];
    D1 = [];
	for i = 1:length(s_trimmed)
    	r0 = t_trimmed(i)/tau;
        r = floor(r0);
        if rand(1) > r0-r
        	r = r+1;
        end
        if r == 0
        	r = 1;
        end
        di = d_trimmed(i)/r;
        D0 = [D0;di];
        D1 = [D1;repmat(di,[r,1])];
    end
    V0 = D0/tau;
    V1 = D1/tau;
    Xi0 = log10(V1);
    idx1 = find(Xi0 > -2);
    idx2 = find(Xi0 < 0);
    idx = intersect(idx1,idx2);
    Xi = Xi0(idx);

    if ~isempty(Xi)
    
        % calculate log-velocity cutoff
        log_vc = my_log_vel_cutoff(data_struct,Xi);
    
        % estimate number of moves
        n = max([1,length(find(V0 < 10^log_vc))]);
    
        % identify pauses using velocity
        [v_idx,v0] = my_identify_pauses2(v,10^log_vc); 
       
        % combine pauses identifed using above methods and identify moves
        idx = v_idx;
        for i = 1:length(idx)-1
            Z(idx(i):idx(i+1)-1) = i;
        end
        analyzed_data = prepared_data;
        analyzed_data.cursor = [ Z' prepared_data.cursor ];

        % eliminate identified moves that are too short
        trim_flg = true;
        if trim_flg
            X = analyzed_data.cursor(:,3);
            Y = analyzed_data.cursor(:,4);
            Z = analyzed_data.cursor(:,1);
            z = unique(Z);
            d = [];
            n = [];
            for i = 1:length(z)
                idx = find(Z == z(i));
                x_tmp = diff(X(idx));
                y_tmp = diff(Y(idx));
                d_tmp = sqrt(x_tmp.^2 + y_tmp.^2);
                d(i) = sum(d_tmp);
                n(i) = length(idx);
            end
            move_idx = find(n < data_struct.params.min_points_in_move);
            idx = [];
            for i = 1:length(move_idx)
                idx = [ idx; find(Z == z(move_idx(i))) ];
            end
            analyzed_data.cursor(idx,:) = [];
        end
        
        vc = 1000*(10^log_vc);
  
    else
        analyzed_data.cursor = [];
        vc = [];
    end

end

%%
% --- function to partition and individual session
%
function [analyzed_data,vc,Xi,Xi0] = my_partition_wrpr(data_struct,raw_data)

    % prepare data
    prepared_data = prepare_data(raw_data);
    
    % analyze data
    if size(prepared_data.cursor,1) > 2
        [analyzed_data,vc,Xi,Xi0] = my_partition(data_struct,prepared_data);
    else
        analyzed_data.cursor = [];
        vc = nan;
        Xi = [];
        Xi0 = [];
    end
    
end
    
%%
% --- function to plot identified mouse moves
%
function ret_val = my_plot_mouse_moves(analyzed_data,font_size,line_width)

    %
    T = 0.001*analyzed_data.cursor(:,2);
    X = analyzed_data.cursor(:,3);
    Y = analyzed_data.cursor(:,4);
    Z = analyzed_data.cursor(:,1);
    
    %
    idx = find(T >= 1683.5 & T <= 1688.5);
    T = T(idx);
    X = X(idx);
    Y = Y(idx);
    Z = Z(idx);
    T = T - T(1) + 1;
    X = X - X(1);
    Y = Y - Y(1);
    
    % data point size
    S = 10;

    % get order of clusters indices
    z = Z(1);
    for i = 1:length(Z);
        if Z(i) ~= z(end)
            z = [ z Z(i) ];
        end
    end
    
    % generate cluster symbols for plots
    c = colormap('Gray');
    %c = colormap('Lines');
    c = c([1,32],:);
    
    C = [];
    for i = 1:length(z);
        idx = find(Z == z(i));
        C = [ C; repmat(c(mod(i,2)+1,:),[ size(idx) 1 ]) ];
    end

    % plot horizontal position
    subplot(2,1,1);
    newplot;
    hold on
    scatter(T,X,S,C,'filled');
    hold off
    set(gca,'LineWidth',line_width);
    set(gca,'FontSize',font_size);
    set(gca,'FontWeight','bold');
    axis([0,5,-1000,100]);
    title('Horizontal Cursor Position','FontSize',font_size);
    xlabel('Time (s)','FontSize',font_size);
    ylabel('Position (counts)','FontSize',font_size);
    
    % plot vertical position
    subplot(2,1,2);
    newplot;
    hold on
    scatter(T,Y,S,C,'filled');
    hold off
    set(gca,'LineWidth',line_width);
    set(gca,'FontSize',font_size);
    set(gca,'FontWeight','bold');
    axis([0,5,-550,550]);
    title('Vertical Cursor Position','FontSize',font_size);
    xlabel('Time (s)','FontSize',font_size);
    ylabel('Position (counts)','FontSize',font_size);
    
    print -dtiff -r300 .\tif\fig2
    
    % set return value
    ret_val = true;
    
end

% %%
% %
% %
% function ret_val = my_plot_move_density(analyzed_data,kernal_width,font_size,line_width)
% 
%     % get moves and pauses matrices
%     [M,P,X,Y] = my_moves_and_pauses_matries(analyzed_data);
%     D = sqrt(X.^2 + Y.^2);
%     
%     % get moves
%     M = M(:,2) - M(:,1);
%     [fm xm] = ksdensity(M);
%     fm = fm*length(M);
%  
%     top = max(fm)+1;
%     idx = find(M > 400);
%     
%     % plot
%     subplot(2,1,1)
%     newplot
%     hold on
%     plot(xm,fm,'k','LineWidth',line_width);
%     hold off
%     axis([0 2000 0 top]);
%     set(gca,'LineWidth',line_width);
%     set(gca,'FontSize',font_size);
%     set(gca,'FontWeight','bold');
%     title('Active Moves','FontSize',font_size);
%     xlabel('Duration (msec)','FontSize',font_size);
%     ylabel('Probability Density','FontSize',font_size);
%     subplot(2,1,2)
%     scatter(M(idx),log(D(idx)),'k','.');
%     
%     % set return value
%     ret_val = true;
%     
% end

% %%
% %
% %
% function ret_val = my_plot_move_and_pause_densities(analyzed_data,events,kernal_width,font_size,line_width)
% 
%     % get moves and pauses matrices
%     [M,P] = my_moves_and_pauses_matries(analyzed_data);
%     
%     % divide moves into moves with and without events
%     M_event = [];
%     M_noevent = [];
%     for i = 1:size(M,1)
%         idx = [];
%         for j = 1:length(events)
%             idx = [idx find(events{j} >= M(i,1) & events{j} <= M(i,2)) ];
%         end
%         if length(idx) == 1
%             M_event = [ M_event; M(i,2)-M(i,1) ];
%         elseif length(idx) == 0
%             M_noevent = [ M_noevent; M(i,2)-M(i,1) ];
%         end
%     end
%     
%     % divide pauses into pauses with and without events
%     P_event = [];
%     P_noevent = [];
%     for i = 1:size(P,1)
%         idx = [];
%         for j = 1:length(events)
%             idx = [idx find(events{j} >= P(i,1) & events{j} <= P(i,2)) ];
%         end
%         if length(idx) == 1
%             P_event = [ P_event; P(i,2)-P(i,1) ];
%         elseif length(idx) == 0
%             P_noevent = [ P_noevent; P(i,2)-P(i,1) ];
%         end
%     end
%     idx = find(P_event > 2000);
%     P_event(idx) = [];
%     idx = find(P_noevent > 2000);
%     P_noevent(idx) = [];
% 
%     [f_mevent x_mevent] = ksdensity(M_event);
%     f_mevent = f_mevent*length(M_event);
%     [f_mnoevent x_mnoevent] = ksdensity(M_noevent);
%     f_mnoevent = f_mnoevent*length(M_noevent);
%     
%     [f_pevent x_pevent] = ksdensity(P_event);
%     f_pevent = f_pevent*length(P_event);
%     [f_pnoevent x_pnoevent] = ksdensity(P_noevent);
%     f_pnoevent = f_pnoevent*length(P_noevent);
%     
%     top = max([max(f_mevent) max(f_mnoevent) max(f_pevent) max(f_pnoevent)])+1;
%     
%     subplot(1,2,1)
%     newplot
%     hold on
%     h = area(x_mevent,f_mevent);
%     set(h,'FaceColor',[0.5,0.5,0.5]);
%     set(h,'LineWidth',line_width);
%     plot(x_mnoevent,f_mnoevent,'k','LineWidth',line_width);
%     hold off
%     axis([0 2000 0 top]);
%     set(gca,'LineWidth',line_width);
%     set(gca,'FontSize',font_size);
%     set(gca,'FontWeight','bold');
%     title('Active Moves','FontSize',font_size);
%     xlabel('Duration (msec)','FontSize',font_size);
%     ylabel('Probability Density','FontSize',font_size);
%     subplot(1,2,2)
%     newplot
%     hold on
%     h = area(x_pevent,f_pevent);
%     set(h,'FaceColor',[0.5,0.5,0.5]);
%     set(h,'LineWidth',line_width);
%     plot(x_pnoevent,f_pnoevent,'k','LineWidth',line_width);
%     hold off
%     axis([0 2000 0 top]);
%     set(gca,'LineWidth',line_width);
%     set(gca,'FontSize',font_size);
%     set(gca,'FontWeight','bold');
%     title('Inter-Move Intervals','FontSize',font_size);
%     xlabel('Duration (msec)','FontSize',font_size);
%     ylabel('Probability Density','FontSize',font_size);
%     
%     % set return value
%     ret_val = true;
%     
% end

% %%
% % --- function to plot kernal smoothed velocity density estimate
% %
% function ret_val = my_plot_vel_density1(xi,f,xi_min,font_size,line_width)
% 
%     x = 1000*(10.^xi);
%     x0 = 1000*(10.^-2);
%     x1 = 1000*(10.^0);
%     xc = 1000*(10.^xi_min);
% 
%     newplot
%     semilogx(x,f,'k','LineWidth',line_width);
%     hold on
%     semilogx([x0,x0],[0,1.25*max(f)],'-.k','LineWidth',line_width);
%     hold off
%     hold on
%     semilogx([x1,x1],[0,1.25*max(f)],'-.k','LineWidth',line_width);
%     hold off
%     axis([min(x),max(x),min(f),1.25*max(f)]);
%     set(gca,'LineWidth',line_width);
%     set(gca,'FontSize',font_size);
%     set(gca,'FontWeight','bold');
%     title('Search Region on Cursor Velocity Density','FontSize', ...
%         font_size,'FontWeight','bold');
%     text(0.98*x0+0.02*x1,1.13*max(f),'Search Region','FontSize', ...
%         font_size,'FontWeight','bold');
%     xlabel('Cursor Velocity (pixels/sec)','FontSize',font_size);
%     %print -dtiff -r300 .\tif\fig1
%     
%     % set return value
%     ret_val = true;
%     
% end

%%
% --- function to plot kernal smoothed velocity density estimate
%
function ret_val = my_plot_vel_density(data_struct,analyzed_data,Xi,Xi0,font_name,font_size,line_width)

    %
    T = 0.001*analyzed_data.cursor(:,2);
    X = analyzed_data.cursor(:,3);
    Y = analyzed_data.cursor(:,4);
    Z = analyzed_data.cursor(:,1);

    log_vel_kernal_width = data_struct.params.log_vel_kernal_width;
    xi_min = my_log_vel_cutoff(data_struct,Xi);
    [f,xi] = ksdensity(Xi0,'width',log_vel_kernal_width);

    x = 1000*(10.^xi);
    xc = 1000*(10.^xi_min);
    
    err = (x-xc).^2;
    idx = find(err == min(err));

    newplot
    semilogx(x,f,'k','LineWidth',line_width);
    hold on
    scatter(x(idx),f(idx),'o','k','MarkerEdgeColor','k','MarkerFaceColor','k');
    semilogx([xc,xc],[0,1.3*max(f)],'--k','LineWidth',line_width);
    hold off
    axis([min(x),max(x),min(f),1.3*max(f)]);   
    set(gca,'LineWidth',line_width);
    set(gca,'FontName',font_name);
    set(gca,'FontSize',font_size);
    set(gca,'FontWeight','bold');
    title('Mouse Speed Density for a Single Session', ...
          'FontName',font_name,'FontSize',font_size,'FontWeight','bold');
    text(10^(0.45*(log10(xc)+min(log10(x)))),1.2*max(f),'Idle', ...
         'FontName',font_name,'FontSize',font_size,'FontWeight','bold');
    text(10^(0.45*(log10(xc)+max(log10(x)))),1.2*max(f),'Active', ...
         'FontName',font_name,'FontSize',font_size,'FontWeight','bold');
    text(10^(log10(xc)),f(idx)-0.033,'v_c_u_t', ...
         'FontName',font_name,'FontSize',font_size,'FontWeight','bold');
    xlabel('Mouse Speed (count/s)','FontName',font_name, ...
        'FontSize',font_size,'FontWeight','bold');
    ylabel('Probability Density','FontName',font_name, ...
        'FontSize',font_size,'FontWeight','bold');
    print -dtiff -r600 .\tif\fig1
    
    xc
    T(end) - T(1)
    length(unique(Z))
    
    % set return value
    ret_val = true;
    
end