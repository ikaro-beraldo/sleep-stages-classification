function signal = notchfilter(s_input,srate,exc_freq)

fs = srate;             % sampling rat
f0 = exc_freq;          % notch frequency
fn = fs/2;              % Nyquist frequency
freqRatio = f0/fn;      % ratio of notch freq. to Nyquist freq.

notchWidth = 0.007;       % width of the notch

% Compute zeros
notchZeros = [exp( sqrt(-1)*pi*freqRatio ), exp( -sqrt(-1)*pi*freqRatio )];

% Compute poles
notchPoles = (1-notchWidth) * notchZeros;

% figure;
% zplane(notchZeros.', notchPoles.');

b = poly( notchZeros ); %  Get moving average filter coefficients
a = poly( notchPoles ); %  Get autoregressive filter coefficients

% figure;
% freqz(b,a,32000,fs)

% filter signal x
signal = filter(b,a,s_input);

end