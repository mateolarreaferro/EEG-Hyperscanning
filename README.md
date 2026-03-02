# EEG-Hyperscanning
Neuroscience of Auditory Perception III: Hyperscanning - Takako Fujioka / Stanford University

# Piano Duet 2017 Analysis (451C W26)

## Overview
EEG hyperscanning analysis pipeline for a Piano Duet study (Music 451C W26, Feb 2026). Two pianists played together while EEG was recorded simultaneously from both. The analysis examines two neural measures: **FRN** (Feedback-Related Negativity) and **Alpha ERD** (Event-Related Desynchronization).

## Directory Structure
```
/Volumes/MLF/EEG-Hyperscanning/
├── Piano_Duet2017/           # Raw .cnt EEG files (Neuroscan format)
├── brainstorm_db/Duet2017/   # Brainstorm protocol database
│   └── data/                 # Per-subject processed data (S01-S24)
├── EventFiles/               # MATLAB event files for each run
├── 451CW26_exercise/         # All analysis scripts
│   ├── do_0a_bst_linkraw_DuetEx.m
│   ├── do_0a2_import_channel_DuetEx.m
│   ├── do_0b_bst_ssp_DuetEx.m
│   ├── do_1a_add_trigger_DuetEx.m
│   ├── do_1b_bst_import_trigger_DuetEx.m
│   ├── do_1c_bst_import_continuous_DuetEx.m
│   ├── do_1d_bst_run_repair_steps_DuetEx.m
│   ├── do_2a_bst_epoch_avg_FRN_DuetEx.m
│   ├── do_2b_bst_epoch_avg_alphaERD_DuetEx.m
│   ├── do_3a_export_data_FRN_DuetEx.m
│   ├── do_3b_bst_induced_alphaERD_DuetEx.m
│   ├── do_3c_extract_alphaERD_DuetEx.m
│   ├── do_4a_1_process.m        # FRN processing (split from do_4a)
│   ├── do_4a_2_plots.m          # FRN visual inspection
│   ├── do_4a_3_peaks.m          # FRN peak identification
│   ├── do_4a_4_export.m         # FRN amplitude extraction + topomaps
│   ├── do_4a_analysis_FRN_DuetEx.m  # Original monolithic FRN script
│   ├── do_4b_analysis_AlphaERD_DuetEx.m
│   ├── my_ttest.m               # Custom ttest (no Statistics Toolbox)
│   ├── my_fcdf.m                # Custom fcdf (no Statistics Toolbox)
│   ├── rmaov2.m                 # Repeated-measures ANOVA functions
│   ├── rmaov31.m
│   ├── rmaov32.m
│   ├── rmaov33.m
│   ├── do_make_elec_groups.m    # Electrode grouping utility
│   ├── do_elec_GA.m             # Grand average utility
│   ├── repair_steps_12_data2.m  # Drift gap repair
│   └── rri_topoplot.m           # Topoplot function
├── output/                   # Analysis outputs
│   ├── FRN_DuetEx_20260208.mat
│   ├── AlphaERD_DuetEx_20260208.mat
│   ├── Workspace_FRN_DuetEx_20260208.mat
│   ├── Workspace_AlphaERD_DuetEx_20260208.mat
│   ├── FRN_P3a_amp_20260208.txt       # For R/Python stats
│   ├── AlphaERD_DuetEx_20260208.txt   # For R stats
│   ├── QQ_FRN_residuals.png           # ANOVA residual normality check
│   └── FRN_interaction_plot.png       # 3-way interaction plot
├── anova_FRN_DuetEx.py       # Python 3-way RM-ANOVA for FRN
├── anova_FRN_DuetEx.R        # Original R script (reference)
├── instructions.docx         # Original pipeline instructions
└── download_scripts.sh       # SCP from CCRMA server
```

## Subjects
- **8 pairs** (16 subjects for FRN): S01-S02, S03-S04, S07-S08, S09-S10, S13-S14, S17-S18, S19-S20, S23-S24
- **7 pairs** (14 subjects for Alpha ERD): Same minus S07-S08
- Odd-numbered = SubA, even-numbered = SubB
- Excluded pairs: S05-S06, S11-S12, S15-S16, S21-S22

## Experimental Conditions (8 total)
Crossed design: Role (Leader/Follower) x Melody (Same/Diff) x Partner (Human/Comp)
1. LeaderSameHuman
2. LeaderDiffHuman
3. FollowerSameHuman
4. FollowerDiffHuman
5. LeaderSameComp
6. LeaderDiffComp
7. FollowerSameComp
8. FollowerDiffComp

## Melody Assignments (melnames)
Each pair has a specific melody assignment order:
```
S01-S02: 1,2,3,4    S03-S04: 3,4,1,2
S07-S08: 3,4,1,2    S09-S10: 1,2,3,4
S13-S14: 1,2,3,4    S17-S18: 1,2,3,4
S19-S20: 3,4,1,2    S23-S24: 3,4,1,2
```

## Pipeline Steps

### Preprocessing (Brainstorm required)
| Step | Script | Description |
|------|--------|-------------|
| 0a | `do_0a_bst_linkraw_DuetEx.m` | Link raw .cnt files to Brainstorm protocol "Duet2017" |
| 0a2 | `do_0a2_import_channel_DuetEx.m` | Import `channel_initial.mat` (replaces CNT 2D defaults) |
| 0b | `do_0b_bst_ssp_DuetEx.m` | SSP eye artifact removal (VEO=blinkv, HEO=blinkh) |
| 1a | `do_1a_add_trigger_DuetEx.m` | Create event files with 5 markers per file |
| 1b | `do_1b_bst_import_trigger_DuetEx.m` | Import event files into Brainstorm |
| 1c | `do_1c_bst_import_continuous_DuetEx.m` | Import raw files with SSP applied |
| 1d | `do_1d_bst_run_repair_steps_DuetEx.m` | Fix 10-second drift gaps in .cnt data |

### FRN Analysis
| Step | Script | Description |
|------|--------|-------------|
| 2a | `do_2a_bst_epoch_avg_FRN_DuetEx.m` | Epoch [-0.5, 1.0]s, bad channel rejection, averaging |
| 3a | `do_3a_export_data_FRN_DuetEx.m` | Export averaged ERPs to MATLAB workspace |
| 4a_1 | `do_4a_1_process.m` | Load, filter (25Hz/40Hz LP), baseline, diff waveforms, t-tests |
| 4a_2 | `do_4a_2_plots.m` | Visual inspection plots |
| 4a_3 | `do_4a_3_peaks.m` | Peak identification for FRN/P3a time windows |
| 4a_4 | `do_4a_4_export.m` | Amplitude extraction, text file export, topomaps |

### Alpha ERD Analysis
| Step | Script | Description |
|------|--------|-------------|
| 2b | `do_2b_bst_epoch_avg_alphaERD_DuetEx.m` | Epoch [-1.5, 3.0]s, downsample to 125Hz |
| 3b | `do_3b_bst_induced_alphaERD_DuetEx.m` | Morlet wavelet TF (1-60Hz), ERS/ERD, time offset |
| 3c | `do_3c_extract_alphaERD_DuetEx.m` | Extract alpha (8-13Hz) bins, save workspace |
| 4b | `do_4b_analysis_AlphaERD_DuetEx.m` | Filter, baseline, electrode grouping, t-tests, ANOVA, topomaps |

## Key Technical Details

### EEG Setup
- 67 channels: 64 EEG + VEO + HEO + Trig
- Original sampling rate: 500 Hz
- File format: Neuroscan .cnt
- 62 channels used in analysis (excluding VEO, HEO, Trig, M1, M2)

### Electrode Groups
- **fc**: F1, Fz, F2, FC1, FCz, FC2 (channels 9,10,11,18,19,20)
- **cpl**: C1, C3, C5, CP1, CP3, CP5 (channels 27,26,25,36,35,34)
- **cpr**: C2, C4, C6, CP2, CP4, CP6 (channels 29,30,31,38,39,40)
- **po**: P1, Pz, P2, PO3, POz, PO4 (channels 45,46,47,55,56,57)

### FRN-specific
- Electrode group: fc6 = channels 9,10,11,18,19,20; PzP2P4 = channels 48,49,50
- Low-pass filters: 25 Hz and 40 Hz (Butterworth order 4)
- Baseline: [-100, 0] ms

### Alpha ERD-specific
- Alpha band: 8-13 Hz
- Epoch: [-1.5, 3.0]s at 125 Hz (563 samples)
- Morlet wavelet: Fc=1, FwhmTc=3
- ERS/ERD normalization: (x - mean) / mean * 100
- Time offset: -21 ms (Arduino correction)
- Brainstorm TF file pattern: `timefreq_morlet_*_ersd.mat`

## Modifications Made (Feb 2026 session with Claude)

### Path Fixes
All scripts originally had Windows paths (`C:\Users\tfujioka\...`). Updated to macOS:
- Brainstorm data: `/Volumes/MLF/EEG-Hyperscanning/brainstorm_db/Duet2017/data`
- Raw data: `/Volumes/MLF/EEG-Hyperscanning/Piano_Duet2017`
- Event files: `/Volumes/MLF/EEG-Hyperscanning/EventFiles`
- Output: `/Volumes/MLF/EEG-Hyperscanning/output`

### Statistics Toolbox Replacements
This MATLAB installation lacks the Statistics and Machine Learning Toolbox:
- `my_ttest.m` - Replaces `ttest()` using `betainc` for p-values
- `my_fcdf.m` - Replaces `fcdf()` using `betainc` for F-distribution CDF
- `nanmean` in `do_make_elec_groups.m` / `do_elec_GA.m` replaced with `mean(..., 'omitnan')`

### Java/Brainstorm Fixes
- `bst_report('Open', ...)` commented out everywhere (Java NullPointerException on macOS)
- All `save()` calls use explicit variable lists to avoid Java Swing object serialization errors

### Script Reorganization
The monolithic `do_4a_analysis_FRN_DuetEx.m` was split into 4 sequential scripts (do_4a_1 through do_4a_4) to avoid manual commenting/uncommenting of sections.

### do_3c File Pattern Fix
Changed search pattern from `timefreq_morlet_*_ersd_timeoffset.mat` to `timefreq_morlet_*_ersd.mat` (the time offset step doesn't append `_timeoffset` to TF filenames).

### do_4b Variable Fixes
- Added `alpha_e = ae;` after load (variable name mismatch between do_3c and do_4b)
- Replaced `time = Time;` with `time = linspace(-1.5, 3.0, ntime);`
- Added fallback time windows if half-amplitude peak detection fails

## Processing Order for New Subjects
1. Update pair/melnames lists in 0a, 0a2, 0b, 1a-1d, 2a, 2b
2. Run: 0a -> 0a2 -> 0b -> 1a -> 1b -> 1c -> 1d
3. FRN track: 2a -> 3a (update subject list) -> 4a_1 -> 4a_2 -> 4a_3 -> 4a_4
4. Alpha track: 2b -> 3b -> 3c (update subject list) -> 4b
5. Stats using exported .txt files (R or Python — see below)

## Statistical Analysis (Python)

`anova_FRN_DuetEx.py` replicates the R script (`anova_FRN_DuetEx.R`) without requiring R/RStudio.

**Requirements:** Python 3 with numpy, pandas, scipy, matplotlib

**Run:** `python3 anova_FRN_DuetEx.py`

**What it does:**
- Loads `output/FRN_P3a_amp_20260208.txt` and filters to 5 clean pairs (10 subjects: S01-S04, S09-S10, S17-S20)
- 3-way within-subjects RM-ANOVA on FRN: partner(Human/Comp) × agency(Self/Other) × melody(Same/Diff)
- Manual SS decomposition (all 15 terms verified to sum to SS_total)
- Generalized eta-squared per Olejnik & Algina (2003)
- Post-hoc paired contrasts matching R's `emmeans` output format
- Residual Q-Q plot → `output/QQ_FRN_residuals.png`
- 3-way interaction plot with Cousineau-Morey within-subject error bars → `output/FRN_interaction_plot.png`

## CCRMA Server
Scripts source: `mlarreaf@ccrma-gate.stanford.edu:/user/t/takako/MATLAB/Duet/eeg_analysis/451CW26_exercise/`
Use `download_scripts.sh` for batch download.
