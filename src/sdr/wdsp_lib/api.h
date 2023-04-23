#pragma once
#define PORT __declspec( dllexport )

PORT void WDSPwisdom(const char* directory);
PORT void OpenChannel(int channel, int in_size, int dsp_size, int input_samplerate, int dsp_rate, int output_samplerate, int type, int state, double tdelayup, double tslewup, double tdelaydown, double tslewdown);
PORT void CloseChannel(int channel);
PORT void SetType(int channel, int type);
PORT void SetInputBuffsize(int channel, int in_size);
PORT void SetDSPBuffsize(int channel, int dsp_size);
PORT void SetInputSamplerate(int channel, int samplerate);
PORT void SetDSPSamplerate(int channel, int samplerate);
PORT void SetOutputSamplerate(int channel, int samplerate);
PORT void SetAllRates(int channel, int in_rate, int dsp_rate, int out_rate);
PORT void SetChannelState(int channel, int state, int dmode);
PORT void SetChannelTDelayUp(int channel, double time);
PORT void SetChannelTSlewUp(int channel, double time);
PORT void SetChannelTDelayDown(int channel, double time);
PORT void SetChannelTSlewDown(int channel, double time);
