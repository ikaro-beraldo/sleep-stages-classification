%% Architecture routine

% All_Sort = vector with classification code (WK = 3; NREM = 2; REM = 1
% Epoch length = epoch length in seconds (ex: 10 or 30)
% Segment length in hours (0 = whole data; scalar (~0) = segment length in
% hours; matrix = segments timestamps [beginning end; beginning end...]

function architecture = app_architecture(All_Sort,epoch_length,segment_length)

%% Parameters and pre-allocating
params.epoch_length = epoch_length;
params.total_length = length(All_Sort);
clear epoch_length 
TD.AWAKE=2; % set minimum duration to consider a AWAKE bout (number of 10s epochs)
TD.NREM=2; % set minimum duration to consider a REM bout (number of 10s epochs)
TD.REM=2; % set minimum duration to consider a REM bout (number of 10s epochs)

% Check if it will be segmented or not (0 = whole data; 1 = segmented data)
if segment_length == 0
    params.segment_length_blocks = params.total_length;                             % Length of each segment in number of blocks
    params.timestamps(1,1) = 1;                     % Get the beginning indices
    params.timestamps(1,2) = params.total_length;   % Get the end indices
    params.n_segments = size(params.timestamps,1);  % Get number of indices
elseif numel(segment_length) > 1 % Check if it is a matrix with [Beginning End] of events
    params.timestamps(:,1) = segment_length(:,1);
    params.timestamps(:,2) = segment_length(:,2);
    params.n_segments = size(params.timestamps,1);
else % A specific number of segments
    % Get the indices from the segments (The last segment might have less
    % epochs than the other ones)
    params.segment_length_blocks = floor(segment_length * (3600 / params.epoch_length));   % Length of each segment in number of blocks
    params.timestamps(:,1) = 1:params.segment_length_blocks:params.total_length;    % Get the beginning indices
    params.timestamps(:,2) = [params.timestamps(2:end,1)-1; params.total_length];   % Get the end indices
    params.n_segments = size(params.timestamps,1);  % Get number of indices
end

% Segments loop
for seg_idx = 1:params.n_segments
    
    AWAKE = zeros(length(All_Sort(params.timestamps(seg_idx,1):params.timestamps(seg_idx,2))),1);  % AWAKE (ones represent periods correponding to the AWAKE state)
    NREM = zeros(length(All_Sort(params.timestamps(seg_idx,1):params.timestamps(seg_idx,2))),1);   % NREM
    REM = zeros(length(All_Sort(params.timestamps(seg_idx,1):params.timestamps(seg_idx,2))),1);    % REM
    
    % Create segmented All Sort
    All_Sort_seg = All_Sort(params.timestamps(seg_idx,1):params.timestamps(seg_idx,2));
    
    % Get the current segment length
    params.length_current_segment(seg_idx,1) = length(All_Sort_seg);
    
    %% Function main workflow
    
    % Insert '1' in the indices correponding to AWAKE epochs
    AWAKE(All_Sort_seg == 3) = 1;
    % Insert '1' in the indices correponding to NREM epochs
    NREM(All_Sort_seg == 2) = 1;
    % Insert '1' in the indices correponding to REM epochs
    REM(All_Sort_seg == 1) = 1;
    
    % ###################### AWAKE ###########################
    
    S=find(diff([0;AWAKE])==1);     % Beginning
    E=find(diff([0;AWAKE])==-1);    % End of a sequence
    
    % W: Collum 1: Start , Collum 2: End , Collum 3: Duration
    if size(S,1)==size(E,1)
        W.AWAKE=[S,E,E-S];
    else
        W.AWAKE=[S(1:end-1),E,E-S(1:end-1)];
    end
    
    architecture.AWAKE.total(seg_idx,1) = length(find(AWAKE == 1))/params.length_current_segment(seg_idx,1)*100;
    
    if ~(isempty(W.AWAKE))  % Check if bouts matrix isn't empty
        W1.AWAKE=W.AWAKE;
        W.AWAKE(W.AWAKE(:,3)<TD.AWAKE,3)=NaN;
        
        aux=find((isnan(W.AWAKE(:,3)))==0);
        nbouts=size(aux,1);
        
        architecture.AWAKE.duration_all{seg_idx,1} = W.AWAKE.*params.epoch_length;
        architecture.AWAKE.duration_mean(seg_idx,1) = nanmean(W.AWAKE(:,3))*params.epoch_length;
%         architecture.AWAKE.total(seg_idx,1) =((sum(W1(:,3)))/params.length_current_segment)*100;
        architecture.AWAKE.Nbouts(seg_idx,1) = nbouts/((params.length_current_segment(seg_idx,1)*params.epoch_length)/60);
    else % If bouts matrix is empty
        architecture.AWAKE.duration_all{seg_idx,1} = [NaN NaN NaN];
        architecture.AWAKE.duration_mean(seg_idx,1) = 0;
%         architecture.AWAKE.total(seg_idx,1) = 0;
        architecture.AWAKE.Nbouts(seg_idx,1) = 0;
    end
    
    clear S E test
    
     
    % ###################### NREM ###########################
    
    S=find(diff([0;NREM])==1);     % Beginning
    E=find(diff([0;NREM])==-1);    % End of a sequence
    
    % W: Collum 1: Start , Collum 2: End , Collum 3: Duration
    if size(S,1)==size(E,1)
        W.nREM=[S,E,E-S];
    else
        W.nREM=[S(1:end-1),E,E-S(1:end-1)];
    end
    
    architecture.NREM.total(seg_idx,1) = length(find(NREM == 1))/params.length_current_segment(seg_idx,1)*100;
    
    if ~(isempty(W.nREM))  % Check if bouts matrix isn't empty
        W1.nREM=W.nREM;
        W.nREM(W.nREM(:,3)<TD.NREM,3)=NaN;
        
        aux=find((isnan(W.nREM(:,3)))==0);
        nbouts=size(aux,1);
        
        architecture.NREM.duration_all{seg_idx,1} = W.nREM.*params.epoch_length;
        architecture.NREM.duration_mean(seg_idx,1) = nanmean(W.nREM(:,3))*params.epoch_length;
%         architecture.NREM.total(seg_idx,1) =((sum(W1(:,3)))/params.length_current_segment)*100;
        architecture.NREM.Nbouts(seg_idx,1) = nbouts/((params.length_current_segment(seg_idx,1)*params.epoch_length)/60);
    else % If bouts matrix is empty
        architecture.NREM.duration_all{seg_idx,1} = [NaN NaN NaN];
        architecture.NREM.duration_mean(seg_idx,1) = 0;
%         architecture.NREM.total(seg_idx,1) = 0;
        architecture.NREM.Nbouts(seg_idx,1) = 0;
    end
    
    clear S E test
    
     
    % ###################### REM ###########################
    
    S=find(diff([0;REM])==1);     % Beginning
    E=find(diff([0;REM])==-1);    % End of a sequence
    
    % W: Collum 1: Start , Collum 2: End , Collum 3: Duration
    if size(S,1)==size(E,1)
        W.REM=[S,E,E-S];
    else
        W.REM=[S(1:end-1),E,E-S(1:end-1)];
    end
    
    architecture.REM.total(seg_idx,1) = length(find(REM == 1))/params.length_current_segment(seg_idx,1)*100;
    
    if ~(isempty(W.REM))  % Check if bouts matrix isn't empty
        W1.REM=W.REM;
        W.REM(W.REM(:,3)<TD.REM,3)=NaN;
        
        aux=find((isnan(W.REM(:,3)))==0);
        nbouts=size(aux,1);
        
        architecture.REM.duration_all{seg_idx,1} = W.REM.*params.epoch_length;
        architecture.REM.duration_mean(seg_idx,1) = nanmean(W.REM(:,3))*params.epoch_length;
%         architecture.REM.total(seg_idx,1) =((sum(W1(:,3)))/params.length_current_segment)*100;
        architecture.REM.Nbouts(seg_idx,1) = nbouts/((params.length_current_segment(seg_idx,1)*params.epoch_length)/60);
    else % If bouts matrix is empty
        architecture.REM.duration_all{seg_idx,1} = [NaN NaN NaN];
        architecture.REM.duration_mean(seg_idx,1) = 0;
%         architecture.REM.total(seg_idx,1) = 0;
        architecture.REM.Nbouts(seg_idx,1) = 0;
    end
    
    clear S E test
    
   
end
% Also get the params used
architecture.params = params;
end

% ####################### PLOT ###########################

% pause(2)
% clc
%
% clear REM_aux All_Sortt aux AWAKE_aux dir E fn* i
% close all
% clc
%
% subplot(1,3,1)
% bar([mean(PV_AWAKE_total),mean(NR1_PV_AWAKE_total);mean(PV_REM_total),mean(NR1_PV_REM_total)]);
% ylabel('Time spent (% of total)')
%
% set(gca,'fontsize',14)
% set(gca,'Tickdir','out')
% set(gca,'Linewidth',1)
% set(gca,'fontname','helvetica')
% ax = gca; % Get handle to current axes.
% ax.XColor = 'k'; % Red
% ax.YColor = 'k'; % Blue
% set(gcf,'color','white')
% box off
%
% subplot(1,3,2)
% bar([mean(PV_AWAKE_Nbouts),mean(NR1_PV_AWAKE_Nbouts);mean(PV_REM_Nbouts),mean(NR1_PV_REM_Nbouts)]);
% ylabel('Frequency (bouts/min)')
%
% set(gca,'fontsize',14)
% set(gca,'Tickdir','out')
% set(gca,'Linewidth',1)
% set(gca,'fontname','helvetica')
% ax = gca; % Get handle to current axes.
% ax.XColor = 'k'; % Red
% ax.YColor = 'k'; % Blue
% set(gcf,'color','white')
% box off
%
% subplot(1,3,3)
% bar([mean(PV_AWAKE_duration_mean),mean(NR1_PV_AWAKE_duration_mean);mean(PV_REM_duration_mean),mean(NR1_PV_REM_duration_mean)]);
% ylabel('Mean duration of bouts (s)')
% legend('PV-Cre','NR1-PV-Cre')
% legend boxoff
%
% set(gcf,'position',[1 1 1000 400]);
% set(gca,'fontsize',14)
% set(gca,'Tickdir','out')
% set(gca,'Linewidth',1)
% set(gca,'fontname','helvetica')
% ax = gca; % Get handle to current axes.
% ax.XColor = 'k'; % Red
% ax.YColor = 'k'; % Blue
% set(gcf,'color','white')
% box off
%
% %% histogram and cdf for bouts duration
%
% % DEACTIVATED
%
% colors = get(0, 'defaultAxesColorOrder');
%
% clc
% clear M
%
% for i=1:size(PV_AWAKE_duration_all,2);
%
%     if i==1;
%
%         M1=PV_AWAKE_duration_all{1,i}(:,3);
%
%     else
%
%         M1=[M1;PV_AWAKE_duration_all{1,i}(:,3)];
%
%     end
%
%
%
% end
%
%
% for i=1:size(NR1_PV_AWAKE_duration_all,2);
%
%     if i==1;
%
%         M2=NR1_PV_AWAKE_duration_all{1,i}(:,3);
%
%     else
%
%         M2=[M2;NR1_PV_AWAKE_duration_all{1,i}(:,3)];
%
%     end
%
%
%
% end
%
%
% A=M1;
% B=M2;
%
% [H,P,KSSTAT] = kstest2(A,B);
%
% figure (1);
% subplot(1,2,1)
% histogram(A,0:80:800,'FaceColor',colors(7,:)*0,'EdgeColor',colors(7,:)*0,'FaceAlpha',0.8,'EdgeAlpha',0.8,'Normalization','probability');
% hold on;
% histogram(B,0:80:800,'FaceColor',colors(7,:),'EdgeColor',colors(7,:)*0.5,'FaceAlpha',0.5,'EdgeAlpha',0.8,'Normalization','probability');
% xlim([0 800])
% xlabel('Duration of bouts (s)')
% t=xlabel('Duration of bouts (s)');
% t.Color = 'k';
% ylabel('Probability')
% t1=ylabel('Probability');
% t1.Color = 'k';
% set(gcf,'color','white')
% box off
% legend('PV-Cre','PV-Cre/NR1 f/f');
% legend boxoff
% set(gca,'fontsize',14)
% ax=gca;
% ax.XColor = 'k'; % X labels are red.
% ax.YColor = 'k';
% set(gca,'Tickdir','out')
% set(gca,'Linewidth',1.5)
% set(gca,'fontname','helvetica')
%
% subplot(1,2,2)
% h=cdfplot(A);
% hold on
% h1=cdfplot(B);
% set(h, 'LineStyle', '-', 'Color',colors(7,:)*0,'linewidth',4);
% set(h1, 'LineStyle', '-', 'Color',colors(7,:),'linewidth',4);
% xlabel('Duration of bouts (s)')
% t=xlabel('Duration of bouts (s)');
% t.Color = 'k';
% ylabel('Cumulative Distribution')
% t1=ylabel('Cumulative Distribution');
% t1.Color = 'k';
% set(gca,'fontsize',14)
% set(gca,'Tickdir','out')
% set(gca,'Linewidth',1.5)
% set(gca,'fontname','helvetica')
% ax=gca;
% ax.XColor = 'k'; % X labels are red.
% ax.YColor = 'k';
% grid on
% box off
% ylim([0 1])
% xlim([0 800])
%
%
% % ACTIVATED
%
% colors = get(0, 'defaultAxesColorOrder');
%
% clc
% clear M
%
% for i=1:size(PV_ACT_duration_all,2);
%
%     if i==1;
%
%         M1=PV_REM_duration_all{1,i}(:,3);
%
%     else
%
%         M1=[M1;PV_REM_duration_all{1,i}(:,3)];
%
%     end
%
%
%
% end
%
%
% for i=1:size(NR1_PV_REM_duration_all,2);
%
%     if i==1;
%
%         M2=NR1_PV_REM_duration_all{1,i}(:,3);
%
%     else
%
%         M2=[M2;NR1_PV_REM_duration_all{1,i}(:,3)];
%
%     end
%
%
%
% end
%
% clear A B
%
% A=M1;
% B=M2;
%
% [H2,P2,KSSTAT2] = kstest2(A,B);
%
% hold off
%
% figure(2)
% subplot(1,2,1)
% histogram(A,0:15:150,'FaceColor',colors(7,:)*0,'EdgeColor',colors(7,:)*0,'FaceAlpha',0.8,'EdgeAlpha',0.8,'Normalization','probability');
% hold on;
% histogram(B,0:15:150,'FaceColor',colors(7,:)*0.5,'EdgeColor',colors(7,:)*0.3,'FaceAlpha',0.5,'EdgeAlpha',0.8,'Normalization','probability');
% xlim([0 150])
% xlabel('Duration of bouts (s)')
% t=xlabel('Duration of bouts (s)');
% t.Color = 'k';
% ylabel('Probability')
% t1=ylabel('Probability');
% t1.Color = 'k';
% set(gcf,'color','white')
% box off
% legend('PV-Cre','PV-Cre/NR1 f/f');
% legend boxoff
% set(gca,'fontsize',14)
% ax=gca;
% ax.XColor = 'k'; % X labels are red.
% ax.YColor = 'k';
% set(gca,'Tickdir','out')
% set(gca,'Linewidth',1.5)
% set(gca,'fontname','helvetica')
%
% subplot(1,2,2)
% h=cdfplot(A);
% hold on
% h1=cdfplot(B);
% set(h, 'LineStyle', '-', 'Color',colors(7,:)*0,'linewidth',4);
% set(h1, 'LineStyle', '-', 'Color',colors(7,:),'linewidth',4);
% xlabel('Duration of bouts (s)')
% t=xlabel('Duration of bouts (s)');
% t.Color = 'k';
% ylabel('Cumulative Distribution')
% t1=ylabel('Cumulative Distribution');
% t1.Color = 'k';
% set(gca,'fontsize',14)
% set(gca,'Tickdir','out')
% set(gca,'Linewidth',1.5)
% set(gca,'fontname','helvetica')
% ax=gca;
% ax.XColor = 'k'; % X labels are red.
% ax.YColor = 'k';
% grid on
% box off
% ylim([0 1])
% xlim([0 150])
%
% end