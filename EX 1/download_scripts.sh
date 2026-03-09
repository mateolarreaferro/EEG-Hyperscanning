#!/bin/bash
# Download new scripts from CCRMA

REMOTE="mlarreaf@ccrma-gate.stanford.edu:/user/t/takako/MATLAB/Duet/eeg_analysis/451CW26_exercise"
LOCAL="/Volumes/MLF/EEG-Hyperscanning/451CW26_exercise"

scp "$REMOTE/do_3c_export_AlphaERD_DuetEx.m" "$LOCAL/"
scp "$REMOTE/do_4b_analysis_AlphaERD_DuetEx.m" "$LOCAL/"
scp "$REMOTE/rmaov33.m" "$LOCAL/"
scp "$REMOTE/rmaov32.m" "$LOCAL/"
scp "$REMOTE/rmaov31.m" "$LOCAL/"
scp "$REMOTE/rmaov2.m" "$LOCAL/"
scp "$REMOTE/do_make_elec_groups.m" "$LOCAL/"
scp "$REMOTE/do_elec_GA.m" "$LOCAL/"

echo "Done!"
