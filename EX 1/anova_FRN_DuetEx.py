#!/usr/bin/env python3
"""
anova_FRN_DuetEx.py — 3-way within-subjects RM-ANOVA on FRN data
Replicates the R script anova_FRN_DuetEx.R using pure Python.

Piano Duet 2017 EEG hyperscanning study (Music 451C W26)
DV:  FRN
Factors (all within-subjects, 2 levels each):
  partner  — Human / Comp
  agency   — Self / Other
  melody   — Same / Diff
Subjects: 10 (5 clean pairs)
"""

import numpy as np
import pandas as pd
from scipy import stats
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

# ───────────────────────────────────────────────────────────────────
# 1. DATA LOADING & PREPARATION
# ───────────────────────────────────────────────────────────────────
data_path = "output/FRN_P3a_amp_20260208.txt"
dat = pd.read_csv(data_path, sep="\t")

# Strip whitespace from column names and string columns
dat.columns = dat.columns.str.strip()
for col in dat.select_dtypes(include="object").columns:
    dat[col] = dat[col].str.strip()

# Keep only 5 clean pairs (10 subjects)
keep_subj = ["S01", "S02", "S03", "S04", "S09", "S10", "S17", "S18", "S19", "S20"]
dat = dat[dat["subjID"].isin(keep_subj)].copy()

# Factor ordering
dat["partner"] = pd.Categorical(dat["partner"], categories=["Human", "Comp"], ordered=True)
dat["agency"] = pd.Categorical(dat["agency"], categories=["Self", "Other"], ordered=True)
dat["melody"] = pd.Categorical(dat["melody"], categories=["Same", "Diff"], ordered=True)

# Sorted subject list
subjects = sorted(dat["subjID"].unique())
n = len(subjects)  # 10
subj_idx = {s: i for i, s in enumerate(subjects)}

# Build 4-D array Y[subject, partner, agency, melody]
partner_levels = ["Human", "Comp"]
agency_levels = ["Self", "Other"]
melody_levels = ["Same", "Diff"]

Y = np.full((n, 2, 2, 2), np.nan)
for _, row in dat.iterrows():
    si = subj_idx[row["subjID"]]
    pi = partner_levels.index(row["partner"])
    ai = agency_levels.index(row["agency"])
    mi = melody_levels.index(row["melody"])
    Y[si, pi, ai, mi] = row["FRN"]

assert not np.isnan(Y).any(), "Missing cells in the design!"

print("=" * 70)
print("3-Way Within-Subjects Repeated Measures ANOVA  —  FRN")
print(f"  Subjects: {n}  |  Factors: partner(2) × agency(2) × melody(2)")
print(f"  Subjects used: {', '.join(subjects)}")
print("=" * 70)

# ───────────────────────────────────────────────────────────────────
# 2. 3-WAY WITHIN-SUBJECTS RM-ANOVA  (manual SS decomposition)
# ───────────────────────────────────────────────────────────────────
# Notation: i=subject, j=partner, k=agency, l=melody
# Grand mean
GM = Y.mean()

# Marginal means
S_i = Y.mean(axis=(1, 2, 3))            # subject means
P_j = Y.mean(axis=(0, 2, 3))            # partner means
A_k = Y.mean(axis=(0, 1, 3))            # agency means
M_l = Y.mean(axis=(0, 1, 2))            # melody means

PA_jk = Y.mean(axis=(0, 3))             # partner × agency
PM_jl = Y.mean(axis=(0, 2))             # partner × melody
AM_kl = Y.mean(axis=(0, 1))             # agency × melody

PAM_jkl = Y.mean(axis=0)                # partner × agency × melody (cell means)

SP_ij = Y.mean(axis=(2, 3))             # subject × partner
SA_ik = Y.mean(axis=(1, 3))             # subject × agency
SM_il = Y.mean(axis=(1, 2))             # subject × melody

SPA_ijk = Y.mean(axis=3)                # subject × partner × agency
SPM_ijl = Y.mean(axis=2)                # subject × partner × melody
SAM_ikl = Y.mean(axis=1)                # subject × agency × melody

# Number of observations per level
q_p, q_a, q_m = 2, 2, 2
N = n * q_p * q_a * q_m  # total observations

# --- Sum of Squares ---
# SS_total
SS_total = np.sum((Y - GM) ** 2)

# SS_subjects
SS_S = q_p * q_a * q_m * np.sum((S_i - GM) ** 2)

# Main effects
SS_P = n * q_a * q_m * np.sum((P_j - GM) ** 2)
SS_A = n * q_p * q_m * np.sum((A_k - GM) ** 2)
SS_M = n * q_p * q_a * np.sum((M_l - GM) ** 2)

# Two-way interactions
SS_PA = n * q_m * np.sum((PA_jk - P_j[:, None] - A_k[None, :] + GM) ** 2)
SS_PM = n * q_a * np.sum((PM_jl - P_j[:, None] - M_l[None, :] + GM) ** 2)
SS_AM = n * q_p * np.sum((AM_kl - A_k[:, None] - M_l[None, :] + GM) ** 2)

# Three-way interaction
SS_PAM = n * np.sum(
    (PAM_jkl
     - PA_jk[:, :, None] - PM_jl[:, None, :] - AM_kl[None, :, :]
     + P_j[:, None, None] + A_k[None, :, None] + M_l[None, None, :]
     - GM) ** 2
)

# Error terms (subject × factor interactions)
SS_SP = q_a * q_m * np.sum(
    (SP_ij - S_i[:, None] - P_j[None, :] + GM) ** 2
)
SS_SA = q_p * q_m * np.sum(
    (SA_ik - S_i[:, None] - A_k[None, :] + GM) ** 2
)
SS_SM = q_p * q_a * np.sum(
    (SM_il - S_i[:, None] - M_l[None, :] + GM) ** 2
)

SS_SPA = q_m * np.sum(
    (SPA_ijk
     - SP_ij[:, :, None] - SA_ik[:, None, :]
     - PA_jk[None, :, :] + S_i[:, None, None] + P_j[None, :, None] + A_k[None, None, :]
     - GM) ** 2
)

SS_SPM = q_a * np.sum(
    (SPM_ijl
     - SP_ij[:, :, None] - SM_il[:, None, :]
     - PM_jl[None, :, :] + S_i[:, None, None] + P_j[None, :, None] + M_l[None, None, :]
     - GM) ** 2
)

SS_SAM = q_p * np.sum(
    (SAM_ikl
     - SA_ik[:, :, None] - SM_il[:, None, :]
     - AM_kl[None, :, :] + S_i[:, None, None] + A_k[None, :, None] + M_l[None, None, :]
     - GM) ** 2
)

SS_SPAM = np.sum(
    (Y
     - SPA_ijk[:, :, :, None] - SPM_ijl[:, :, None, :]
     - SAM_ikl[:, None, :, :] - PAM_jkl[None, :, :, :]
     + SP_ij[:, :, None, None] + SA_ik[:, None, :, None] + SM_il[:, None, None, :]
     + PA_jk[None, :, :, None] + PM_jl[None, :, None, :] + AM_kl[None, None, :, :]
     - S_i[:, None, None, None] - P_j[None, :, None, None]
     - A_k[None, None, :, None] - M_l[None, None, None, :]
     + GM) ** 2
)

# Verify decomposition
SS_check = (SS_S + SS_P + SS_A + SS_M
            + SS_PA + SS_PM + SS_AM + SS_PAM
            + SS_SP + SS_SA + SS_SM
            + SS_SPA + SS_SPM + SS_SAM + SS_SPAM)

print(f"\nSS decomposition check:  SS_total = {SS_total:.6f}")
print(f"  Sum of all 15 SS terms = {SS_check:.6f}")
print(f"  Difference = {abs(SS_total - SS_check):.2e}")
assert abs(SS_total - SS_check) < 1e-8, "SS decomposition failed!"
print("  ✓ SS decomposition verified\n")

# Degrees of freedom
df_S = n - 1
df_eff = 1  # all factors have 2 levels → df = 2-1 = 1
df_err = df_S * df_eff  # (n-1)*1 = 9

# Sum of all error SS (for generalized eta-squared denominator)
SS_all_error = SS_SP + SS_SA + SS_SM + SS_SPA + SS_SPM + SS_SAM + SS_SPAM

# Build ANOVA table
effects = [
    ("partner",                SS_P,   SS_SP),
    ("agency",                 SS_A,   SS_SA),
    ("melody",                 SS_M,   SS_SM),
    ("partner:agency",         SS_PA,  SS_SPA),
    ("partner:melody",         SS_PM,  SS_SPM),
    ("agency:melody",          SS_AM,  SS_SAM),
    ("partner:agency:melody",  SS_PAM, SS_SPAM),
]

# Generalized eta-squared denominator (Olejnik & Algina, 2003)
ges_denom = SS_S + SS_all_error

print("-" * 70)
print(f"{'Effect':<26s} {'df1':>3s} {'df2':>3s} {'F':>10s} {'p':>10s} {'ges':>8s} {'sig':>4s}")
print("-" * 70)
for name, ss_eff, ss_err in effects:
    MS_eff = ss_eff / df_eff
    MS_err = ss_err / df_err
    F_val = MS_eff / MS_err
    p_val = stats.f.sf(F_val, df_eff, df_err)
    ges = ss_eff / (ss_eff + ges_denom)
    sig = "***" if p_val < 0.001 else "**" if p_val < 0.01 else "*" if p_val < 0.05 else "." if p_val < 0.1 else ""
    print(f"  {name:<24s} {df_eff:>3d} {df_err:>3d} {F_val:>10.3f} {p_val:>10.4f} {ges:>8.4f}  {sig}")
print("-" * 70)
print(f"  Signif. codes: '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1")
print(f"  N = {n} subjects, all factors 2-level → sphericity trivially satisfied\n")


# ───────────────────────────────────────────────────────────────────
# 3. RESIDUAL Q-Q PLOT
# ───────────────────────────────────────────────────────────────────
# Residuals = Y_ijkl - cell_mean_jkl - subject_mean_i + grand_mean
residuals = Y - PAM_jkl[None, :, :, :] - S_i[:, None, None, None] + GM
residuals_flat = residuals.flatten()

fig, ax = plt.subplots(figsize=(6, 5))
stats.probplot(residuals_flat, dist="norm", plot=ax)
ax.set_title("Normal Q-Q Plot of ANOVA Residuals (FRN)")
ax.get_lines()[0].set_markerfacecolor("steelblue")
ax.get_lines()[0].set_markeredgecolor("steelblue")
ax.get_lines()[0].set_markersize(5)
fig.tight_layout()
fig.savefig("output/QQ_FRN_residuals.png", dpi=150)
plt.close(fig)
print("Saved: output/QQ_FRN_residuals.png\n")


# ───────────────────────────────────────────────────────────────────
# 4. POST-HOC TESTS  (emmeans-style paired contrasts)
# ───────────────────────────────────────────────────────────────────
def paired_contrast(vals_a, vals_b, label_a, label_b, df_denom):
    """Paired t-test on subject-level marginal means.
    Returns (estimate, SE, df, t, p) matching emmeans output."""
    diff = vals_a - vals_b
    estimate = diff.mean()
    se = diff.std(ddof=1) / np.sqrt(len(diff))
    t_val = estimate / se
    p_val = 2 * stats.t.sf(abs(t_val), df_denom)
    return estimate, se, df_denom, t_val, p_val


def print_contrast_header():
    print(f"  {'contrast':<28s} {'estimate':>9s} {'SE':>9s} {'df':>4s} {'t.ratio':>9s} {'p.value':>9s}")


def print_contrast(label, est, se, df, t, p):
    print(f"  {label:<28s} {est:>9.4f} {se:>9.4f} {df:>4d} {t:>9.3f} {p:>9.4f}")


df_ph = n - 1  # 9

# --- 4a. Main effect of partner ---
print("=" * 70)
print("Post-hoc: Main effect of partner")
print("  (averaged over agency and melody)")
print("-" * 70)

# emmeans
partner_subj = np.array([Y[:, j, :, :].mean(axis=(1, 2)) for j in range(2)])  # (2, n)
for j, plev in enumerate(partner_levels):
    m = partner_subj[j].mean()
    se = partner_subj[j].std(ddof=1) / np.sqrt(n)
    print(f"  {plev:<10s} emmean = {m:>8.4f}   SE = {se:.4f}")
print()

print_contrast_header()
est, se, df, t, p = paired_contrast(partner_subj[0], partner_subj[1],
                                     "Human", "Comp", df_ph)
print_contrast("Human - Comp", est, se, df, t, p)
print()

# --- 4b. 2-way partner × melody ---
print("=" * 70)
print("Post-hoc: partner × melody interaction")
print("-" * 70)

# emmeans by melody
print("emmeans of partner by melody:")
for l, mlev in enumerate(melody_levels):
    print(f"  melody = {mlev}:")
    for j, plev in enumerate(partner_levels):
        vals = Y[:, j, :, l].mean(axis=1)  # avg over agency
        m = vals.mean()
        se = vals.std(ddof=1) / np.sqrt(n)
        print(f"    {plev:<10s} emmean = {m:>8.4f}   SE = {se:.4f}")
print()

# partner contrasts within each melody
print("Partner contrasts (Human - Comp) within each melody:")
print_contrast_header()
for l, mlev in enumerate(melody_levels):
    human_vals = Y[:, 0, :, l].mean(axis=1)
    comp_vals = Y[:, 1, :, l].mean(axis=1)
    est, se, df, t, p = paired_contrast(human_vals, comp_vals, "Human", "Comp", df_ph)
    print_contrast(f"Human-Comp | {mlev}", est, se, df, t, p)
print()

# melody contrasts within each partner
print("Melody contrasts (Same - Diff) within each partner:")
print_contrast_header()
for j, plev in enumerate(partner_levels):
    same_vals = Y[:, j, :, 0].mean(axis=1)
    diff_vals = Y[:, j, :, 1].mean(axis=1)
    est, se, df, t, p = paired_contrast(same_vals, diff_vals, "Same", "Diff", df_ph)
    print_contrast(f"Same-Diff | {plev}", est, se, df, t, p)
print()

# --- 4c. 3-way contrasts ---
print("=" * 70)
print("Post-hoc: 3-way interaction contrasts")
print("-" * 70)

# Melody contrasts by partner × agency
print("\nMelody contrasts (Same - Diff) by partner × agency:")
print_contrast_header()
for j, plev in enumerate(partner_levels):
    for k, alev in enumerate(agency_levels):
        same_vals = Y[:, j, k, 0]
        diff_vals = Y[:, j, k, 1]
        est, se, df, t, p = paired_contrast(same_vals, diff_vals, "Same", "Diff", df_ph)
        label = f"Same-Diff | {plev},{alev}"
        print_contrast(label, est, se, df, t, p)
print()

# Agency contrasts by partner × melody
print("Agency contrasts (Self - Other) by partner × melody:")
print_contrast_header()
for j, plev in enumerate(partner_levels):
    for l, mlev in enumerate(melody_levels):
        self_vals = Y[:, j, 0, l]
        other_vals = Y[:, j, 1, l]
        est, se, df, t, p = paired_contrast(self_vals, other_vals, "Self", "Other", df_ph)
        label = f"Self-Other | {plev},{mlev}"
        print_contrast(label, est, se, df, t, p)
print()

# Partner contrasts by agency × melody
print("Partner contrasts (Human - Comp) by agency × melody:")
print_contrast_header()
for k, alev in enumerate(agency_levels):
    for l, mlev in enumerate(melody_levels):
        human_vals = Y[:, 0, k, l]
        comp_vals = Y[:, 1, k, l]
        est, se, df, t, p = paired_contrast(human_vals, comp_vals, "Human", "Comp", df_ph)
        label = f"Human-Comp | {alev},{mlev}"
        print_contrast(label, est, se, df, t, p)
print()


# ───────────────────────────────────────────────────────────────────
# 5. 3-WAY INTERACTION PLOT  (Cousineau-Morey within-subject SE)
# ───────────────────────────────────────────────────────────────────

# Compute subject-level cell means (already have Y[n,2,2,2])
# Cousineau-Morey: remove between-subject variance, then correct
n_cond = q_p * q_a * q_m  # 8 conditions
correction = np.sqrt(n_cond / (n_cond - 1))  # Morey correction

# Subject grand mean
subj_gm = Y.mean(axis=(1, 2, 3))  # (n,)
# Overall grand mean
overall_gm = Y.mean()

# Normalized values: Y_norm = Y - subj_mean + grand_mean
Y_norm = Y - subj_gm[:, None, None, None] + overall_gm

fig, axes = plt.subplots(1, 2, figsize=(8, 4.5), sharey=True)

colors = {"Human": "#1b9e77", "Comp": "#d95f02"}
markers = {"Human": "o", "Comp": "s"}
x_positions = np.array([0, 1])

for k, alev in enumerate(agency_levels):
    ax = axes[k]
    for j, plev in enumerate(partner_levels):
        cell_means = Y_norm[:, j, k, :]  # (n, 2) across melody
        means = cell_means.mean(axis=0)
        se_cm = cell_means.std(axis=0, ddof=1) / np.sqrt(n) * correction

        ax.errorbar(x_positions, means, yerr=se_cm,
                     color=colors[plev], marker=markers[plev],
                     markersize=7, capsize=4, linewidth=1.5,
                     label=plev)

    ax.set_title(alev, fontsize=13)
    ax.set_xticks(x_positions)
    ax.set_xticklabels(melody_levels)
    ax.set_xlabel("Melody type")
    ax.set_xlim(-0.3, 1.3)

axes[0].set_ylabel("FRN (\u03bcV)")

# Shared legend at bottom
handles, labels = axes[0].get_legend_handles_labels()
fig.legend(handles, labels, loc="lower center", ncol=2, frameon=False,
           fontsize=11, title="Partner")

fig.suptitle("")
fig.tight_layout(rect=[0, 0.08, 1, 1])
fig.savefig("output/FRN_interaction_plot.png", dpi=150)
plt.close(fig)
print("Saved: output/FRN_interaction_plot.png")
print("\nDone.")
