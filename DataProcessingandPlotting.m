%% New and Improved Patch and Finapres Data Analysis Script
% Created By: Kimberly Branan, Kendall Frazee
% Last Update: 16 Jan 2025

clear; clc; close all;
%% Select the Directory Path of the Finapres Data Folder
path_Finapres = uigetdir('',"Select the subject's STATIC or DYNAMIC Folder");

%% Assigning Paths for all Necessary Files
BP_File_Names = {'fiSYS','fiMAP','fiDIA'};
Trial_File_Names = {'40 mmhg'}; %change to the desired trial
clear Data 
for t = 1:1:length(Trial_File_Names)
    path_Finapres_Trial = strcat(path_Finapres,'\',Trial_File_Names{t});
    path_Finapres_Trial_Patch = strcat(path_Finapres_Trial,'\Patch');
    path_Finapres_Trial_Finapres = strcat(path_Finapres_Trial,'\Finapres');
    
    % Finapres Data Paths
    list = dir(path_Finapres_Trial_Finapres);
    
    path_Finapres_Trial_Finapres_Raw = strcat(path_Finapres_Trial_Finapres,'\',list(end).name);
    
    Finapres_File_Name_BackBone = strsplit(list(end).name,' ');
    Finapres_File_Name_BackBone = Finapres_File_Name_BackBone{1};
    
    for i = 1:1:length(BP_File_Names)
        Finapres_BP_File_Paths{i} = strcat(path_Finapres_Trial_Finapres_Raw,'\',Finapres_File_Name_BackBone," ",BP_File_Names{i},'.csv');
    end
    
    Finapres_Marker_File_Path = strcat(path_Finapres_Trial_Finapres_Raw,'\',Finapres_File_Name_BackBone," Markers.csv");
    Finapres_Waveform_File_Path = strcat(path_Finapres_Trial_Finapres_Raw,'\',Finapres_File_Name_BackBone," fiAPLvl.csv");
    
    % Patch Data Paths
    list = dir(path_Finapres_Trial_Patch);
    Patch_Time_Path = strcat(path_Finapres_Trial_Patch,'\',list(end).name);
    Patch_Data_Path = strcat(path_Finapres_Trial_Patch,'\',list(end-1).name);
    %% Import Pressure Patch Data (.mat file)
    patch_data = load('-mat', Patch_Data_Path);
    patch_time = load('-mat', Patch_Time_Path);
    
    %% Import Finapress BP Data (.csv file) and Save as Single .xlsx file
    
    for i = 1:1:length(Finapres_BP_File_Paths)
        fiSYS_DIA{i} = import_fiSYS(Finapres_BP_File_Paths{i});
    end
    
    CSV_Title = 'DBP_MAP_SBP Finapress Data';
    
    SYS_DIA_Finapress = [fiSYS_DIA{1},fiSYS_DIA{2}(:,2),fiSYS_DIA{3}(:,2)];
    
    csv_path = strcat(path_Finapres_Trial_Finapres_Raw,'\',CSV_Title,'.xlsx');
    
    Finapres_SYS_MAP_DIA = array2table(SYS_DIA_Finapress,'VariableNames',{'Time','DBP','MAP','SBP'});
    writetable(Finapres_SYS_MAP_DIA,csv_path)
    
    %% Import Finapres Waveform Data (.csv file)
    Finapres_Waveforms = importFinapres_Marker_Info(Finapres_Waveform_File_Path);
    
    %% Import Finapres Marker Information (.csv file)
    Finapres_Markers = importFinapres_Marker_Info(Finapres_Marker_File_Path);
    
    %% Parsing Finapres Data Based on the Marker Info
    for i = 1:1:length(Finapres_Markers.Time)
        if Finapres_Markers.Label(i) == "User marker 1"
            data_start_index = i;
            break;
        end
    end
    
    % Keeping all Data where the marker indicates the study has started
    Data.Finapres.BPs = Finapres_SYS_MAP_DIA(Finapres_SYS_MAP_DIA.Time>=Finapres_Markers.Time(data_start_index),:);
    Data.Finapres.Waveform = Finapres_Waveforms(Finapres_Waveforms.Time>=Finapres_Markers.Time(data_start_index),:);
    Data.Finapres.Waveform.Label = str2double(Data.Finapres.Waveform.Label);
    Data.Finapres.Markers = Finapres_Markers;
    Data.Finapres.data_start_index = data_start_index;
    %% Plotting the Finapres Data
    plot(Data.Finapres.Waveform.Time,Data.Finapres.Waveform.Label)
    hold on
    xline(Finapres_Markers.Time((data_start_index):end),'-',{'1','2','3'},'LineWidth',2);
    hold off
    
%% Creating Time Arrays for the Patch Data
fs = 40;    %patch sampling rate
patch_start_times = datetime(patch_time.time_date,'Format','HH:mm:ss.SSS');
patch_data_waveforms = patch_data.All_the_data;

for i = 1:length(patch_data_waveforms)
    q = 0;
    for j = 1:1:length(patch_data_waveforms{i})
        Data.Patch.Times{i}{j,1} = 60*(minute(patch_start_times(:,i)) - minute(patch_start_times(:,1)))+second(patch_start_times(:,i))+(q * 1/fs);
        q = q+1;
    end
    Data.Patch.Waveform{i} = patch_data_waveforms{i}(:,1);
    Data.Patch.ContactPressure{i} = patch_data_waveforms{i}(:,2);
end

    
    %% Time Aligning the Data
    figure('Name','Time Aligning Plot')
    tl = tiledlayout(2,1,'TileSpacing','compact');
    nexttile;
    title(tl,'Selected the peak of the tap.')
    title('Patch Data')
    xlabel('Time (HH:mm:ss.SS)')
    ylabel('Amplitude (A.U.)')
    time1axis = cell2mat(Data.Patch.Times{1});
    plot(time1axis,Data.Patch.Waveform{1}(:,1));
    xlim([time1axis(1),time1axis(end)]);
    tap_points_time{1} = getpts;
    
    nexttile;
    title('Finapres Data')
    xlabel('Time (sec)')
    ylabel('Pressure (mmHg)')
    plot(Data.Finapres.Waveform.Time(1:10000),Data.Finapres.Waveform.Label(1:10000));
    tap_points_time{2} = getpts;
    title(tl,'DONE')
    pause(1);
    close all;
    
    %% Reassigning the Finapres Time Variable
    Data.Finapres.Waveform.Time = tap_points_time{1}+Data.Finapres.Waveform.Time-tap_points_time{2};
    Data.Finapres.BPs.Time = tap_points_time{1}+Data.Finapres.BPs.Time-tap_points_time{2};
    Finapres_Markers.Time = tap_points_time{1}+Finapres_Markers.Time-tap_points_time{2};
    
    %% Finding the AC Peaks and Feet
    fs = 40;    %sampling rate (Hz)
    % fs_W = 200; %Finapres sampling rate (Hz)
    fc = 10;
    [b,a] = butter(3,fc./(fs/2),'low');

    for i = 1:1:length(Data.Patch.Waveform)
        [Data.Patch.ACPeaks{i},Data.Patch.ACPeaks_Time{i}] = findpeaks(Data.Patch.Waveform{i},fs,'MinPeakDistance',0.6);
        time_holder = cell2mat(Data.Patch.Times{i}(1));
        Data.Patch.ACPeaks_Time{i} = time_holder+Data.Patch.ACPeaks_Time{i};
        [Data.Patch.ACFeet{i},Data.Patch.ACFeet_Time{i}] = findpeaks(-1*(Data.Patch.Waveform{i}),fs,'MinPeakDistance',0.6);
        Data.Patch.ACFeet{i} = -1*Data.Patch.ACFeet{i};
        Data.Patch.ACFeet_Time{i} = time_holder+Data.Patch.ACFeet_Time{i};

        [Data.Patch.Envelope{i}(:,1),Data.Patch.Envelope{i}(:,2)] = envelope(Data.Patch.Waveform{i},fs/2,'peak');

    end
    
    [Data.Finapres.Peaks(:,2), Data.Finapres.Peaks(:,1)] = findpeaks(table2array(Data.Finapres.Waveform(:,2)), 200, 'MinPeakDistance',0.6);
    [Data.Finapres.Feet(:,2), Data.Finapres.Feet(:,1)] = findpeaks(-1*table2array(Data.Finapres.Waveform(:,2)), 200, 'MinPeakDistance',0.6);
    Data.Finapres.Feet(:,2) = -1*Data.Finapres.Feet(:,2);
    Data.Finapres.Peaks(:,1) = Data.Finapres.Peaks(:,1) + table2array(Data.Finapres.Waveform(1,1));
    Data.Finapres.Feet(:,1) = Data.Finapres.Feet(:,1) + table2array(Data.Finapres.Waveform(1,1));

    NewData.One(:,1) = Data.Patch.ACPeaks_Time{1}(12:16,1);
    NewData.One(:,2) = Data.Patch.ACPeaks{1}(12:16,1);
    NewData.One(:,3) = Data.Patch.ACFeet_Time{1}(12:16,1);
    NewData.One(:,4) = Data.Patch.ACFeet{1}(12:16,1);

    NewData.Two(:,1) = Data.Patch.ACPeaks_Time{2}(11:15,1);
    NewData.Two(:,2) = Data.Patch.ACPeaks{2}(11:15,1);
    NewData.Two(:,3) = Data.Patch.ACFeet_Time{2}(11:15,1);
    NewData.Two(:,4) = Data.Patch.ACFeet{2}(11:15,1);

    NewData.Three(:,1) = Data.Patch.ACPeaks_Time{3}(11:15,1);
    NewData.Three(:,2) = Data.Patch.ACPeaks{3}(11:15,1);
    NewData.Three(:,3) = Data.Patch.ACFeet_Time{3}(11:15,1);
    NewData.Three(:,4) = Data.Patch.ACFeet{3}(11:15,1);

    %% Plotting Finapres and Patch Data
    % uncomment commented lines in this section for dynamic data
    f = figure;
    tl = tiledlayout(3,1,"TileSpacing","compact");
    
    ax(1) = nexttile;
    colororder({'b','k'});
    yyaxis left
    plot(Data.Finapres.Waveform.Time,Data.Finapres.Waveform.Label)
    ylabel({'Finger Blood Pressure','mmHg'})
    hold on
    %plot(Data.Finapres.BPs.Time,Data.Finapres.BPs.SBP)
    %xline(Data.Finapres.Markers.Time(Data.Finapres.data_start_index:end),'-',{'Feet Flat','Rest','150°','120°','90°'},'LineWidth',2);
    yyaxis right
    for i = 1:1:length(Data.Patch.Times)
        time_holder2 = cell2mat(Data.Patch.Times{i});
        plot(time_holder2,Data.Patch.Waveform{i},'k-')
        hold on
        plot(Data.Patch.ACPeaks_Time{i},Data.Patch.ACPeaks{i},'ro','LineWidth',1)
        plot(Data.Patch.ACFeet_Time{i},Data.Patch.ACFeet{i},'ro','LineWidth',1)

        plot(time_holder2,Data.Patch.Envelope{i}(:,1),'r--','LineWidth',1)
        plot(time_holder2,Data.Patch.Envelope{i}(:,2),'r--','LineWidth',1)
    end
    ylabel({'Patch Amplitude','(A.U.)'})
    hold off
    
    ax(2) = nexttile;
    colororder({'r','k'});
    yyaxis left
    % xline(Finapres_Markers.Time(data_start_index:end),'-',{'Feet Flat','Rest','150°','120°','90°'},'LineWidth',2);
    hold on 
    for i = 1:1:length(Data.Patch.Times)
        time_holder3 = cell2mat(Data.Patch.Times{i})
        plot(time_holder3,Data.Patch.ContactPressure{i},'r-')
        hold on
    end
    ylabel({'Contact Pressure','mmHg'})
    yyaxis right
    for i = 1:1:length(Data.Patch.Times)
        time_holder4 = cell2mat(Data.Patch.Times{i})
        plot(time_holder4,Data.Patch.Waveform{i},'k-')
        hold on
    end
    ylabel({'Patch Amplitude','(A.U.)'})
    hold off

    ax(3) = nexttile;
    colororder({'r','k'});
    yyaxis left
    % xline(Finapres_Markers.Time(data_start_index:end),'-',{'Feet Flat','Rest','150°','120°','90°'},'LineWidth',2);
    hold on 
    for i = 1:1:length(Data.Patch.Times)
        time_holder5 = cell2mat(Data.Patch.Times{i})
        plot(time_holder5,Data.Patch.ContactPressure{i},'r-')
        hold on
    end
    ylabel({'Contact Pressure','mmHg'})
    yyaxis right
    for i = 1:1:length(Data.Patch.Times)
        time_holder6 = cell2mat(Data.Patch.Times{i})
        plot(time_holder6,Data.Patch.Envelope{i}(:,1)./Data.Patch.Envelope{i}(:,2),'k-')
        hold on
    end
    ylabel({'Patch AC Amplitude','(A.U.)'})
    hold off
    
    linkaxes(ax,'x')
    title(tl,Trial_File_Names{t})
    fontsize('increase');
    fontsize('increase');
    fontsize('increase');
    set(gcf,'WindowState','maximized')

end