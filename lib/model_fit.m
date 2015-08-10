function K = model_fit(parms,D,T,V)
%MODEL_FIT Summary of this function goes here
%   Detailed explanation goes here

    %
    del_t_mult = parms.del_t_mult;
    wT = parms.wT;
    F = parms.F;

    %
    wT = F(1,:);
    r1 = F(2:7,:);
    c1 = F(8:13,:);
    r2 = F(14:19,:);
    c2 = F(20:25,:);

    %
    K = nan(length(V),4);
    d = zeros(1,length(V));
    t = zeros(1,length(V));
    for i = 1:length(V)
        if length(V{i}) > 0
        
            %
            dt = [ 0; diff(T{i}) ];
            d(i) = -sum(V{i}.*dt);
            t(i) = max(T{i});

            %
            del_t = 1/(del_t_mult*length(T{i}));
            t_est = T{i}(end)*(0:del_t:1)';
            v_est = zeros(size(t_est));
            [nbin,bin] = histc(t_est,T{i});
            V_bin = V{i};
            V_bin(bin(end)+1) = 0;
            v_est = V_bin(bin+1);

            %
            Vm1 = my_get_velocity(wT,r1,c1,t_est,d(i),t(i));
            Vm2 = my_get_velocity(wT,r2,c2,t_est,d(i),t(i));
            vm = [ Vm1 Vm2 ];
            v = repmat(v_est,[1,size(F,2)+size(F,2)]);
            err = sum((v - vm).^2,1);
            idx = find(err == min(err));
            vm_star = vm(:,idx);
            v_star = v(:,idx);
            try
                [R,p] = corr(vm_star,v_star);
                K(i,3) = R^2;
                K(i,4) = p;
            end
            if idx <= size(F,2)
                f = F([1:13],idx);
                if ~isempty(f)
                    K(i,1) = 1000*f(1)/t(i);
                else
                    f = nan(1,13);
                end
                case_flg = 2;
            else
                f = F([1,14:25],idx-size(F,2));
                if ~isempty(f)
                    K(i,2) = 1000*f(1)/t(i);
                else
                    f = nan(1,13);
                end
                case_flg = 1;
            end
            wT_star = f(1);
            r_star = f(2:7);
            c_star = f(8:13);

            %
            if false
%                 if max(T{i}) > 300 && max(T{i}) < 350 && ...
%                    max(abs(d(i))) > 100 && max(abs(d(i))) < 200
%                     if i == 520 || i == 2236
                        v = my_get_velocity(wT_star,r_star,c_star,t_est,d(i),t(i));
                        my_plot(case_flg,t_est,v_est,t_est,v')
%                     end
%                 end
            end
            
        else
            t(i) = nan;
            d(i) = nan;
            D(i) = nan;
        end
    end
    
    K = [ K t' -d' D' ];
                
end

%%
%
%
function v = my_get_velocity(wT,r,c,T,d,t)

    tau(1,1,:) = T;
    A = repmat(wT,[size(c,1) 1 length(T)]);
    B = c.*r.*repmat(wT,[size(c,1),1]);
    C = repmat(B,[1 1 length(T)]);
    D = repmat(r,[1 1 length(T)]);
    E = repmat(tau,[size(r,1) size(r,2) 1]);
    F = C.*exp(A.*D.*E/t);
    v = real((-d/t)*squeeze(sum(F,1))');

end

%%
%
%
function ret_val = my_plot(case_flg,T,V,t,v)

    %
    font_name = 'Times';
    font_size = 16;
    line_width = 2;
    marker_size = 50;

    %
    figure(1)
    subplot(2,1,case_flg)
    newplot
    hold on
    plot(T,V/1000,'--k','LineWidth',line_width);
    plot(t,v/1000,'k','LineWidth',line_width);
    hold off
    axis([0 max(T) 0 1.1*max([max(v/1000),max(V/1000)])]);
    set(gca,'LineWidth',line_width);
    set(gca,'FontSize',font_size);
    set(gca,'FontWeight','bold');
    switch case_flg
        case 1
            title('Example Class I Mouse Movement','FontName',font_name,'FontSize',font_size,'FontWeight','bold');
        case 2
            title('Example Class II Mouse Movement','FontName',font_name,'FontSize',font_size,'FontWeight','bold');
    end
    xlabel('Time (msec)','FontName',font_name,'FontSize',font_size,'FontWeight','bold');
    ylabel('Mouse Speed (count/msec)','FontName',font_name,'FontSize',font_size,'FontWeight','bold');
    print -dtiff -r600 .\tif\fig4;
    pause

	ret_val = true;

end