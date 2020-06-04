
loads=[1 5 10];
Nloads=length(loads);

fcts=cell(1,Nloads);

for a=1:Nloads
%     load(sprintf('FCT_%dperc.mat',loads(a)));
    load(sprintf('FCT_%dperc_cwnd10.mat',loads(a)));
    fcts{a}=data_fct;
    Nrecorded_flows(a)=length(data_fct(:,1));
end

figure;
plot(loads,Nrecorded_flows,'-o');
grid on;

data=csvread('../../../Figure1_traffic/websearch.csv');
flowsize=data(:,1).';
% flowcdf=data(:,2).';
Nflowsize=length(flowsize);

meanFCTs=cell(1,Nloads);
FCTs99=cell(1,Nloads);

for a=1:Nloads
    Nrecorded_flows=length(fcts{a});
    
    % get the number of flows in each size
    Nfiltered_flows=zeros(1,Nflowsize);
    for fs=1:Nflowsize
        for i=1:Nrecorded_flows
            if fcts{a}(i,3)==flowsize(fs)
                Nfiltered_flows(fs)=Nfiltered_flows(fs)+1;
            end
        end
    end
    
    % filter the flows by size
    filtered_flows=cell(1,Nflowsize);
    [meanFCTs{a},FCTs99{a}]=deal(zeros(1,Nflowsize));
    for fs=1:Nflowsize
        filtered_flows{fs}=zeros(Nfiltered_flows(fs),5);
    end
    for fs=1:Nflowsize
        fprintf('iter_fs = %d out of %d\n',fs,Nflowsize);
        cnt=1;
        for i=1:length(fcts{a}(:,1))
            if fcts{a}(i,3)==flowsize(fs)
                filtered_flows{fs}(cnt,:)=fcts{a}(i,:);
                cnt=cnt+1;
            end
        end
        if isempty(filtered_flows{fs})==0
            meanFCTs{a}(fs)=mean(filtered_flows{fs}(:,4));
            perc=.99; % percentile
            temp=sort(filtered_flows{fs}(:,4));
            [n,~]=size(temp);
            FCTs99{a}(fs)=temp(round(perc*n));
        end
    end
    
end


%% get the FCTs for basic RotorNet

FCTs90_RN=cell(1);

load(sprintf('FCT_1perc_RLBonly.mat'));
fcts_RN=data_fct;
Nrecorded_flows=length(fcts_RN);
% get the number of flows in each size
Nfiltered_flows=zeros(1,Nflowsize);
for fs=1:Nflowsize
    for i=1:Nrecorded_flows
        if fcts_RN(i,3)==flowsize(fs)
            Nfiltered_flows(fs)=Nfiltered_flows(fs)+1;
        end
    end
end
% filter the flows by size
filtered_flows=cell(1,Nflowsize);
FCTs90_RN{1}=zeros(1,Nflowsize);
for fs=1:Nflowsize
    filtered_flows{fs}=zeros(Nfiltered_flows(fs),5);
end
for fs=1:Nflowsize
    fprintf('rotornet iter_fs = %d out of %d\n',fs,Nflowsize);
    cnt=1;
    for i=1:length(fcts_RN(:,1))
        if fcts_RN(i,3)==flowsize(fs)
            filtered_flows{fs}(cnt,:)=fcts_RN(i,:);
            cnt=cnt+1;
        end
    end
    if isempty(filtered_flows{fs})==0
        perc=.95; % percentile
        temp=sort(filtered_flows{fs}(:,4));
        [n,~]=size(temp);
        FCTs90_RN{1}(fs)=temp(round(perc*n));
    end
end

%%

% figure;
% hold on;
% 
% % h(1)=plot(flowsize,1e3*meanFCTs{1},'o','linewidth',2);
% % plot(flowsize,1e3*meanFCTs{1},'-k','linewidth',1,'color',h(1).Color);
% for a=1:5
%     h(a)=plot(flowsize,1e3*FCTs99{a},'o','linewidth',2);
%     plot(flowsize,1e3*FCTs99{a},'-k','linewidth',1,'color',h(a).Color);
% end
% 
% plot(flowsize,1e3*1e3*(flowsize+64)*8/10e9,'--k','linewidth',1);
% 
% grid on;
% box on;
% ax=gca;
% ax.XScale='log';
% ax.YScale='log';
% ax.FontSize=16;
% xlabel('Flow size (bytes)');
% ylabel('Flow completion time (\mus)');
% xlim([4000 30e6]);
% ax.XTick=[10^4 10^5 10^6 10^7];
% ylim([10^1 10^5]);



figure;
hold on;

m={'o','+','x','d','*','^'};
ms=[6 8 8 6 8 6 8];

% plot(100e3,1e3*60,'vk','markersize',6,'linewidth',2);

h(1)=plot(flowsize,1e3*meanFCTs{1},m{1},'markersize',ms(1),'linewidth',2);
plot(flowsize,1e3*meanFCTs{1},'-k','linewidth',1,'color',h(1).Color);

% plot(100e3,1e3*77,[m{1} 'k'],'markersize',ms(1),'linewidth',2,'color',h(1).Color);

legtext{1}='1% load, avg.';

for a=2:length(loads)
    h(a)=plot(flowsize,1e3*FCTs99{a},m{a},'markersize',ms(a),'linewidth',2);
    plot(flowsize,1e3*FCTs99{a},'-k','linewidth',1,'color',h(a).Color);
    legtext{a}=sprintf('%d%% load, 99%%-tile',loads(a));
end

% plot(100e3,1e3*113,[m{2} 'k'],'markersize',ms(2),'linewidth',2,'color',h(2).Color);
% plot(100e3,1e3*225,[m{3} 'k'],'markersize',ms(3),'linewidth',2,'color',h(3).Color);

for a=1:1
    h_RN=plot(flowsize,1e3*FCTs90_RN{a},'sk','markersize',ms(2),'linewidth',1);
    plot(flowsize,1e3*FCTs90_RN{a},'-k','linewidth',1);
    % legtext{a}='RotorNet';
    uistack(h_RN,'bottom');
end

pktsize=zeros(1,length(loads));
for a=1:length(loads)
    pktsize=min([flowsize(a) 1436]);
end

Nqueues=2; % smallest number of queues to transit
NlinksRTT=4; % smallest round trip number of ToR-ToR links
ideal_lat=1e6*((flowsize+64)*8/10e9 + ... % flow serialization at NIC
    (Nqueues-1)*(pktsize+64)*8/10e9 +  ... % packet serialization at queues
    Nqueues*64*8/10e9 + ... % ACK serialization
    NlinksRTT*500e-9); % link delay
plot(flowsize,ideal_lat,'--k','linewidth',1);

ht = text(9e3,5e4,{'(No hybrid,','1% load)'});
set(ht,'FontSize',16)

ht = text(9e3,7e2,{'(Hybrid, +33%','cost)'});
set(ht,'FontSize',16)

grid on;
box on;
ax=gca;
ax.XScale='log';
ax.YScale='log';
ax.FontSize=18;
xlabel('Flow size (bytes)');
% ylabel('Flow completion time (\mus)');
ax.XTick=[10^4 10^5 10^6 10^7];
ax.YTick=[10^1 10^2 10^3 10^4 10^5];
xlim([flowsize(2) 30e6]);
ylim([7 6e5]);
ax.MinorGridLineStyle='none';

% set(gcf,'position',[543 506 560 420]); % original
set(gcf,'position',[543 506 500 420]);
ax.Units='points';
% ax.Position % print the position
% set(gca,'position',[61.9143 58.8214 318.1857 232.5536]); % original
set(gca,'position',[35 58.8214 318.1857 232.5536]);

ht = text(5e4,2e1,'Minimum latency');
set(ht,'Rotation',30)
set(ht,'FontSize',16)

% hl=drawbrace([1.3e5 3e5], [1.3e5 4e4]);
% hl.Color='k';
% hl.LineWidth=1;

% hleg=legend(h,legtext);
% hleg.FontSize=10;
% hleg.Location='northwest';

% ht = text(1.8e5,1.15e5,'Shuffle, various loads, 99%-tile');
% set(ht,'FontSize',10)

ax.XColor=[0 0 0];
ax.YColor=[0 0 0];
ax.GridColor=[0 0 0];
ax.MinorGridColor=[0 0 0];
ax.GridAlpha=.1;
fig = gcf;
fig.PaperPositionMode = 'auto';
fig_pos = fig.PaperPosition;
fig.PaperSize = [fig_pos(3) fig_pos(4)];

print(fig,'fcts_rotornet_2','-dpdf')


