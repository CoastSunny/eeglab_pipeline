function idx = pick_freq(freqs, freq_range)

nl = length(freq_range);

if nl>2
    disp('Error: The length of freq_range must be 1 or 2.');
    return;
end

if nl==2 && freq_range(1) > freq_range(2)
    disp('Error: freq_range(1) shouldn''t be bigger than freq_range(2).')
end

freqs = to_col_vector(freqs);
freq_range = to_col_vector(freq_range);
idx = dsearchn(freqs, freq_range);
