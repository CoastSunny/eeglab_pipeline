clear, clc, close all
base_dir = '~/Data/mabin/';
input_tag = 'merge';
output_tag = 'pre';
file_ext = 'set';

brain_template = 'Spherical';
on_ref = 'FCz';
append_on_ref = true;
off_ref = {'TP9', 'TP10'};

srate = 250;
hipass = 1;
lowpass = 45;
marks = {'S 11', 'S 12', ...
         'S 21', 'S 22', ...
         'S 31', 'S 32'};
epoch_time = [-1.5, 3];

flatline = 5;
mincorr = 0.4;
linenoisy = [];

thresh_param.low_thresh = -500;
thresh_param.up_thresh = 500;
trends_param.slope = 200;
trends_param.r2 = 0.3;
spectra_param.threshold = [-35, 35];
spectra_param.freqlimits = [20 40];
joint_param.single_chan = 8;
joint_param.all_chan = 4;
kurt_param.single_chan = 8;
kurt_param.all_chan = 4;
thresh_chan = 0.1;
reject = 1;

%%------------------------
input_dir = fullfile(base_dir, input_tag);
output_dir = fullfile(base_dir, output_tag);
if ~exist(output_dir, 'dir'); mkdir(output_dir); end

in_filename = get_filename(input_dir, file_ext);
id = get_id(in_filename);

rm_chans = {'HEOL', 'HEOR', 'HEOG', 'HEO', ...
            'VEOD', 'VEO', 'VEOU', 'VEOG', ...
            'M1', 'M2', 'TP9', 'TP10', ...
            'CB1', 'CB2'};

% set_matlabpool(2);

for i = 1:numel(id)

    print_info(id, i);
    out_filename = fullfile(output_dir, sprintf('%s_%s.mat', id{i}, output_tag));
    if exist(out_filename, 'file')
        warning('files alrealy exist!')
        continue
    end
    
    ica = struct();
    if strcmp(off_ref, 'average')
        isavg = 1;
    else
        isavg = 0;
    end

    % import dataset
    [EEG, ALLEEG, CURRENTSET] = import_data(input_dir, in_filename{i});

    if EEG.srate > 500
       EEG = pop_resample(EEG, 500);
       EEG = eeg_checkset(EEG);
    end
    
    % high pass filtering
    EEG = pop_eegfiltnew(EEG, hipass, 0);
    EEG = eeg_checkset(EEG);

    % low pass filtering
    if exist('lowpass', 'var') && ~isempty(lowpass)
        EEG = pop_eegfiltnew(EEG, 0, lowpass);
        EEG = eeg_checkset(EEG);
    end

    % add channel locations
    EEG = add_chanloc(EEG, brain_template, on_ref, append_on_ref);

    % remove channels
    if ~isavg
        real_rm_chans = setdiff(rm_chans, off_ref);
    else
        real_rm_chans = rm_chans;
    end

    EEG = pop_select(EEG, 'nochannel', real_rm_chans);
    EEG = eeg_checkset(EEG);

    labels = {EEG.chanlocs.labels};
    % re-reference if necessary
    if ~isavg
        EEG = pop_reref(EEG, find(ismember(labels, off_ref)));
        EEG = eeg_checkset(EEG);
    else
        EEG = pop_reref(EEG, []);
        EEG = eeg_checkset(EEG);
    end

    orig_chanlocs = EEG.chanlocs;
    EEG = rej_badchan(EEG, flatline, mincorr, linenoisy);
    if ~isfield(EEG.etc, 'clean_channel_mask')
        EEG.etc.clean_channel_mask = ones(1, EEG.nbchan);
    end

    badchans = {orig_chanlocs.labels};
    badchans = badchans(~EEG.etc.clean_channel_mask);

    % re-reference if offRef is average
    if isavg
        EEG = pop_reref(EEG, []);
        EEG = eeg_checkset(EEG);
    end

    % epoching
    EEG = pop_epoch(EEG, natsort(marks), epoch_time, 'epochinfo', 'yes');
    EEG = eeg_checkset(EEG);

    % baseline-zero
    EEG = pop_rmbase(EEG, []);

    % down-sampling
    EEG = pop_resample(EEG, srate);
    EEG = eeg_checkset(EEG);

    try
        % reject epochs
        [EEG, info] = rej_epoch_auto(EEG, thresh_param, trends_param, spectra_param, ...
                                     joint_param, kurt_param, thresh_chan, reject);
    catch err
        err.message
    end
    try
        % run ica
        [ica.icawinv, ica.icasphere, ica.icaweights] = run_ica(EEG, isavg);
        ica.info = info;
        ica.info.badchans = badchans;
        ica.info.orig_chanlocs = orig_chanlocs;
        parsave(out_filename, ica, 'ica', '-mat');
    catch err
        err.message
        fprintf('subj %i %s error!', i, id{i});
    end
    EEG = []; ALLEEG = []; CURRENTSET = [];
end
% eeglab redraw;
