function cleanEEG = lix_asr(EEG, burstThreshold)

arg_flatline 	= 'off';
arg_highpass 	= 'off';
arg_channel 	= 'off';
arg_noisy		= 'off';
arg_burst 		= burstThreshold;
arg_window		= 'off';

cleanEEG = clean_artifacts(EEG, 'FlatlineCriterion', arg_flatline,...
                                	'Highpass',          arg_highpass,...
                                	'ChannelCriterion',  arg_channel,...
                                	'LineNoiseCriterion',  arg_noisy,...
                                	'BurstCriterion',    arg_burst,...
                                	'WindowCriterion',   arg_window);