function Training_data = Train_Model (LFP,x,y,label_y,aux_GMM,Visual_inspection)

% Loading epochs
load('ALL_DATA.mat', 'DATA')

plot_epochs=[];
for jj=1:size(aux_GMM.Prob,2)
    % Choosing epochs with posterior probability higher than 70%
    l=find(aux_GMM.Prob(:,jj)>=0.7);
    plot_epochs=cat(1,l,plot_epochs);
end
clear l jj

% Time bins must not be the same as in visual inspection
plot_epochs = setdiff(plot_epochs,[Visual_inspection.AWAKE_idx Visual_inspection.NREM_idx Visual_inspection.REM_idx]);
plot_epochs = plot_epochs(randperm(length(plot_epochs)));

time=(1:1:size(DATA.LFP_epochs,2))./LFP.FS;

condition=1;
jj=0;
Training_data.Awake=[];
Training_data.NREM=[];
Training_data.REM=[];
Training_data.Transition.AWA_NREM=0;
Training_data.Transition.NREM_REM=0;
Training_data.Transition.REM_AWA=0;
Training_data.Transition.unknown=0;

set(0,'DefaultFigureWindowStyle','docked')
figure

while condition==1
    
    jj=jj+1;
    while isnan(DATA.LFP_epochs(plot_epochs(jj),:)) | isnan(DATA.EMG_epochs(plot_epochs(jj),:))
        jj=jj+1;
    end
    
    subplot(3,2,[1 2])
    plot(time,DATA.LFP_epochs(plot_epochs(jj),:));
    title(['Time bin: ' num2str(plot_epochs(jj))])
    ylim([-1 1])
    ylabel({'Hippocampus','(Amplitude)'})
    set(gca, 'XTick', [0 1 2 3 4 5 6 7 8 9 10]);
    box off
    
    subplot(3,2,[3 4])
    plot(time,DATA.EMG_epochs(plot_epochs(jj),:));
    ylim([-1 +1])
    ylabel({'EMG','(Amplitude)'})
    set(gca, 'XTick', [0 1 2 3 4 5 6 7 8 9 10]);
    box off
    
    subplot(3,2,5)
    Fidx=find(LFP.Frequency_distribution<=90);
    A=LFP.Power_normalized(plot_epochs(jj),Fidx);
    F=LFP.Frequency_distribution(Fidx);
    loglog(F,smooth(A,10),'k','linewidth',1.2);
    xlim([1 90])
    ylim([min(A)*0.5 max(A)*3]);
    xlabel('Frequency (log)')
    ylabel('PSD (log)')
    set(gca, 'xtick', [0 2 4 6 8 10 20 40 60 80]);
    box off
    
    subplot(3,2,6)
    scatter(x,y,10,[.8 .8 .8],'o','filled')
    hold on
    scatter(x(plot_epochs(jj)),y(plot_epochs(jj)),25,'r','o','filled')
    hold off
    xlabel('EMG (RMS)')
    ylabel(label_y)
    legend('All time windows','Choosed one')
    
    prompt = 'Select: \n1 = AWAKE \n2 = NREM \n3 = REM \n4 = Not sure \n5 = How many counted? \n';
    ip=input(prompt);
    if ip==1
        aux=plot_epochs(jj);
        Training_data.Awake=cat(1,Training_data.Awake,aux);
        clc
    elseif ip==2
        aux=plot_epochs(jj);
        Training_data.NREM=cat(1,Training_data.NREM,aux);
        clc
    elseif ip==3
        aux=plot_epochs(jj);
        Training_data.REM=cat(1,Training_data.REM,aux);
        clc
    elseif ip==4
        clc
        promptt = 'Why?: \n1 = Transition AWAKE<->NREM \n2 = Transition NREM<->REM \n3 = Transition REM<->AWAKE \n4 = None of those \n';
        ipp=input(promptt);
        if ipp==1
            Training_data.Transition.AWA_NREM=Training_data.Transition.AWA_NREM+1;
        elseif ipp==2
            Training_data.Transition.NREM_REM=Training_data.Transition.NREM_REM+1;
        elseif ipp==3
            Training_data.Transition.REM_AWA=Training_data.Transition.REM_AWA+1;
        elseif ipp==4
            Training_data.Transition.unknown=Training_data.Transition.unknown+1;
        end
        clc
    elseif ip==5
        clc
        disp(num2str(jj))
        pause
    else
        continue
    end
    Training_data.Awake = unique(nonzeros(Training_data.Awake));
    Training_data.NREM = unique(nonzeros(Training_data.NREM));
    Training_data.REM = unique(nonzeros(Training_data.REM));
    
    if size(Training_data.Awake,1)>=11 && ...
            size(Training_data.NREM,1)>=11 && ...
            size(Training_data.REM,1)>=11
        condition=0;
    end
end

close all

Training_data.All_sort=zeros(1,size(DATA.LFP_epochs,1));

Training_data.All_Awake=Training_data.Awake(randperm(length(Training_data.Awake)));
Training_data.All_NREM=Training_data.NREM(randperm(length(Training_data.NREM)));
Training_data.All_REM=Training_data.REM(randperm(length(Training_data.REM)));

Training_data.Awake=Training_data.Awake(1:40);
Training_data.NREM=Training_data.NREM(1:40);
Training_data.REM=Training_data.REM(1:40);

Training_data.All_sort(Training_data.Awake)=3;
Training_data.All_sort(Training_data.NREM)=2;
Training_data.All_sort(Training_data.REM)=1;

clearvars -except Training_data
save ('Trained_data','Training_data')

set(0,'DefaultFigureWindowStyle','normal')
end

