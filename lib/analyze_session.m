function [w_neg,w_pos,idle] = analyze_session(session_data)
%ANALYZE_SESSION Summary of this function goes here
%   Detailed explanation goes here

    cursor = session_data.parsed_data.cursor;

    %
    warning off;

    %
    min_events = 10;
    
    %
    parms_1.del_t_mult = 3;
    parms_1.wT = 2*pi*(0.2:0.05:2.2);
    parms_1.F = my_model_structure(parms_1.wT);

    %
    if size(cursor,1) ~= 0
        if false
            ret_val = my_plot_mouse_moves(cursor);
            pause
        end
        T_session = (max(cursor(:,2)) - min(cursor(:,2)))/60000;
        Z = unique(cursor(:,1));
        N_session = length(Z);
        if length(Z) > 0
            D = zeros(1,length(Z));
            V = cell(1,length(Z));
            T = cell(1,length(Z));
            for k = 1:length(Z)
                dt = 16;
                idx = find(cursor(:,1) == Z(k));
                t = cursor(idx,2);
                x = cursor(idx,3);
                y = cursor(idx,4);
                d = sqrt((diff(x).^2) + (diff(y).^2));
                t = diff(t);
                V{k} = [ 0; d./t; 0 ];
                D(k) = sqrt( (x(end)-x(1))^2 + (y(end)-y(1))^2 );
                T{k} = [ 0; cumsum(t)+dt; sum(t)+2*dt ];
            end
            idx = 1:length(T);
            if length(idx) > min_events
                K = model_fit(parms_1,D,T,V);
                idx_neg = find(~isnan(K(:,2)));
                idx_pos = find(~isnan(K(:,1)));
                w_neg = K(idx_neg,[2,3:end]);
                w_pos = K(idx_pos,[1,3:end]);
            else
                w_neg = [];
                w_pos = [];
            end
            Z_list = sort(unique(Z));
            idle = [];
            for i = 1:length(Z_list)-1;
                z1 = find(cursor(:,1) == Z_list(i));
                z2 = find(cursor(:,1) == Z_list(i+1));
                idle(i,:) = cursor(z2(1),2)-cursor(z1(end),2);
            end
        end
    else
        idle = [];
        w_neg = [];
        w_pos = [];
    end

end

%%
%
%
function c = my_coefficients(r)

    R = conj(r');
    A = [ ones(size(R)); R; R.^2; ...
          exp(R); R.*exp(R); (R.^2).*exp(R) ];    
    b = [ -1; 0; 0; 0; 0; 0 ]; 
    c = A\b;
    
end

%%
%
%
function F = my_model_structure(wT)

    r_neg = my_roots_of_neg_one();
    r_pos = my_roots_of_pos_one();
    
    F = zeros(1+2*length(r_neg)+2*length(r_pos),length(wT));
    for i = 1:length(wT)
        F(:,i) = [ wT(i); r_neg; my_coefficients(r_neg*wT(i)); ...
                          r_pos; my_coefficients(r_pos*wT(i)) ];
    end

end

%%
% --- function to plot identified mouse moves
%
function ret_val = my_plot_mouse_moves(cursor)

    % parameters
    font_name = 'Times';
    font_size = 16;
    kernal_width = 100;
    line_width = 2;

    %
    T = 0.001*cursor(:,2);
    X = cursor(:,3);
    Y = cursor(:,4);
    Z = cursor(:,1);
    
    %
%     range = [897,902];
%     idx = find(T >= 897 & T <= 902);
%     T = T(idx);
%     X = X(idx);
%     Y = Y(idx);
%     Z = Z(idx);
    
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
    set(gca,'FontName',font_name);
    set(gca,'FontSize',font_size);
    set(gca,'FontWeight','bold');
    xlim(range);
    title('Sample Mouse Position Data','FontName',font_name,'FontSize',font_size,'FontWeight','bold');
    xlabel('Time into Session (sec)','FontName',font_name,'FontSize',font_size,'FontWeight','bold');
    ylabel(sprintf('Horizontal\n Position (counts)'),'FontName',font_name,'FontSize',font_size,'FontWeight','bold');
    
    % plot vertical position
    subplot(2,1,2);
    newplot;
    hold on
    scatter(T,Y,S,C,'filled');
    hold off
    set(gca,'LineWidth',line_width);
    set(gca,'FontName',font_name);
    set(gca,'FontSize',font_size);
    set(gca,'FontWeight','bold');
    xlim(range);
    %title('Horizontal Mouse Position','FontName',font_name,'FontSize',font_size,'FontWeight','bold');
    xlabel('Time into Session (sec)','FontName',font_name,'FontSize',font_size,'FontWeight','bold');
    ylabel(sprintf('Vertical\n Position (counts)'),'FontName',font_name,'FontSize',font_size,'FontWeight','bold');
    
    print -dtiff -r300 .\tif\fig2
    
    % set return value
    ret_val = true;
    
end

%%
%
%
function r = my_roots_of_neg_one()

    p = [ 1 0 0 0 0 0 1 ];
    r = roots(p);

end

%%
%
%
function r = my_roots_of_pos_one()

    p = [ 1 0 0 0 0 0 -1 ];
    r = roots(p);
    
end