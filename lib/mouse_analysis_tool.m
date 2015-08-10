function analyzed_data = mouse_analysis_tool(oadcnum,dates,data_struct, ...
                                             server,session_cutoff, ...
                                             project_name,min_sessions, ...
                                             max_sessions)
%MOUSE_ANALYSIS_TOOL Summary of this function goes here
%   Detailed explanation goes here

% 06/15/14 - Initial revision - Stuart Hagler
   
    % set warnings off
    warning off;
    
    % add project name to parameter structure
    data_struct.params.proj_info.project = project_name;
    
    % get subject data
    sbj_data = pull_sbj_data(oadcnum,data_struct,server);
    
    % parse session data
    session_data = ...
    	parse_session_data(sbj_data,data_struct,server,dates, ...
                           session_cutoff,min_sessions,max_sessions);
    
    % create data matrices
    Rho = [];
    T_idle = [];
    W_I = [];
    W_II = [];
    for i = 1:length(session_data)
        if ~isnan(session_data{i}.rho)
            Rho = [ Rho; session_data{i}.rho ];
            T_idle = [ T_idle; session_data{i}.idle ];
            W_I = [ W_I; session_data{i}.w_neg ];
            W_II = [ W_II; session_data{i}.w_pos ];
        end
    end
    if isempty(Rho)
        Rho = nan;
    end
    
    % analyze data
    num_sessions = length(session_data);
    W = [ W_I; W_II ];
    [B,Tau,T,D,Delta,K,num_moves] = my_analyze_moves(W);
    [B_I,Tau_I,T_I,D_I,Delta_I,K_I,num_moves_I] = my_analyze_moves(W_I);
    [B_II,Tau_II,T_II,D_II,Delta_II,K_II,num_moves_II] = my_analyze_moves(W_II);
    if ~isempty(T_idle)
        idle_time = [ median(T_idle) iqr(T_idle) ];
    else
        idle_time = nan(1,2);
    end
    
    % assemble data structure
    analyzed_data.oadc = oadcnum;
    analyzed_data.dates = dates;
    analyzed_data.num_sessions = num_sessions;
    analyzed_data.rho = [ mean(Rho) std(Rho) ];
    analyzed_data.num_moves = num_moves;
    analyzed_data.num_moves_I = num_moves_I;
    analyzed_data.num_moves_II = num_moves_II;
    analyzed_data.Delta = Delta;
    analyzed_data.Delta_I = Delta_I;
    analyzed_data.Delta_II = Delta_II;
    analyzed_data.D = D;
    analyzed_data.D_I = D_I;
    analyzed_data.D_II = D_II;
    analyzed_data.K = K;
    analyzed_data.K_I = K_I;
    analyzed_data.K_II = K_II;
    analyzed_data.T = T;
    analyzed_data.T_I = T_I;
    analyzed_data.T_II = T_II;
    analyzed_data.B = B;
    analyzed_data.B_I = B_I;
    analyzed_data.B_II = B_II;
    analyzed_data.Tau = Tau;
    analyzed_data.Tau_I = Tau_I;
    analyzed_data.Tau_II = Tau_II;
    analyzed_data.idle_time = idle_time;
    
    % set return value
    ret_val = true;

end

%%
%
%
function [B,Tau,t,d,delta,K,num] = my_analyze_moves(W)

    if ~isempty(W)
        D = W(:,5);
        Delta = W(:,6);
        lambda = W(:,6)./W(:,5);
        T = W(:,4);
        idx = find(lambda > 1/2 & T < 4000);
        D = D(idx);
        Delta = Delta(idx);
        T = T(idx);
        idx = randperm(length(T));
        idx = idx(1:min([length(T),1000000]));
        y = T(idx);
        X = [ ones(size(y)) log2(D(idx)) 1./D(idx) ];
        [b,bint,r,rint,stats] = regress(y,X);
        B = [ b' stats([1,3]) ];
        X = [ ones(size(y)) log2(Delta(idx)) 1./Delta(idx) ];
        [b,bint,r,rint,stats] = regress(y,X);
        B = [ B; b' stats([1,3]) ];
        X = D(idx).^(1/3);
        Tau = [ mean(y./X) std(y./X) ];
        num = size(W,1);
        t = [ median(T(idx)) iqr(T(idx)) ];
        d = [ median(D(idx)) iqr(D(idx)) ];
        delta = [ median(Delta(idx)) iqr(Delta(idx)) ];
        K = [ median(Delta(idx)./D(idx)) iqr(Delta(idx)./D(idx)) ];
    else
        B = nan(1,5);
        Tau = nan(1,2);
        num = 0;
        t = nan(1,2);
        d = nan(1,2);
        delta = nan(1,2);
        K = nan(1,2);
    end

end