#!/usr/bin/env python3
"""
anova_AlphaERD_DuetEx.py — 3-way within-subjects RM-ANOVA on Alpha ERD data
Replicates do_4b_analysis_AlphaERD_DuetEx.m (rmaov33) using Python.

Piano Duet 2017 EEG hyperscanning study (Music 451C W26)

Separate ANOVAs for Leader and Follower:
  DV:  AlphaERD
  Factors (all within-subjects):
    IV1: melody   — same(2) / diff(2)
    IV2: partner  — human(2) / comp(2)
    IV3: elec     — fc / cpl / cpr / po (4 levels)
  Subjects: 10 (5 best pairs, matching FRN analysis)
"""

import numpy as np
import pandas as pd
from scipy import stats
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

# ───────────────────────────────────────────────────────────────────
# 1. DATA LOADING
# ───────────────────────────────────────────────────────────────────
data_path = "451CW26_exercise/AlphaERD_DuetEx_20260208.txt"
dat = pd.read_csv(data_path, sep="\t")
dat.columns = dat.columns.str.strip()
for col in dat.select_dtypes(include="object").columns:
    dat[col] = dat[col].str.strip()

# Keep only 5 best pairs (10 subjects), matching FRN analysis
keep_subj = ["S01", "S02", "S03", "S04", "S09", "S10", "S17", "S18", "S19", "S20"]
dat = dat[dat["Subj"].isin(keep_subj)].copy()

subjects = sorted(dat["Subj"].unique())
n = len(subjects)
subj_idx = {s: i for i, s in enumerate(subjects)}

melody_levels = ["same", "diff"]
partner_levels = ["human", "comp"]
elec_levels = ["fc", "cpl", "cpr", "po"]
role_levels = ["leader", "follower"]

q_m, q_p, q_e = 2, 2, 4

print(f"Alpha ERD Analysis — {n} subjects: {', '.join(subjects)}")
print()


# ───────────────────────────────────────────────────────────────────
# 2. 3-WAY RM-ANOVA (matching rmaov33 from MATLAB)
# ───────────────────────────────────────────────────────────────────
def rm_anova_3way(Y, n_subj, qa, qb, qc, factor_names):
    """
    3-way within-subjects ANOVA on Y[subject, A, B, C].
    Matches rmaov33.m output format.
    """
    N_total = n_subj * qa * qb * qc
    GM = Y.mean()

    # Marginal means
    S_i = Y.mean(axis=(1, 2, 3))
    A_j = Y.mean(axis=(0, 2, 3))
    B_k = Y.mean(axis=(0, 1, 3))
    C_l = Y.mean(axis=(0, 1, 2))
    AB_jk = Y.mean(axis=(0, 3))
    AC_jl = Y.mean(axis=(0, 2))
    BC_kl = Y.mean(axis=(0, 1))
    ABC_jkl = Y.mean(axis=0)
    SA_ij = Y.mean(axis=(2, 3))
    SB_ik = Y.mean(axis=(1, 3))
    SC_il = Y.mean(axis=(1, 2))
    SAB_ijk = Y.mean(axis=3)
    SAC_ijl = Y.mean(axis=2)
    SBC_ikl = Y.mean(axis=1)

    # SS
    SS_total = np.sum((Y - GM) ** 2)
    SS_S = qa * qb * qc * np.sum((S_i - GM) ** 2)

    SS_A = n_subj * qb * qc * np.sum((A_j - GM) ** 2)
    SS_B = n_subj * qa * qc * np.sum((B_k - GM) ** 2)
    SS_C = n_subj * qa * qb * np.sum((C_l - GM) ** 2)

    SS_AB = n_subj * qc * np.sum((AB_jk - A_j[:, None] - B_k[None, :] + GM) ** 2)
    SS_AC = n_subj * qb * np.sum((AC_jl - A_j[:, None] - C_l[None, :] + GM) ** 2)
    SS_BC = n_subj * qa * np.sum((BC_kl - B_k[:, None] - C_l[None, :] + GM) ** 2)

    SS_ABC = n_subj * np.sum(
        (ABC_jkl
         - AB_jk[:, :, None] - AC_jl[:, None, :] - BC_kl[None, :, :]
         + A_j[:, None, None] + B_k[None, :, None] + C_l[None, None, :]
         - GM) ** 2
    )

    SS_SA = qb * qc * np.sum((SA_ij - S_i[:, None] - A_j[None, :] + GM) ** 2)
    SS_SB = qa * qc * np.sum((SB_ik - S_i[:, None] - B_k[None, :] + GM) ** 2)
    SS_SC = qa * qb * np.sum((SC_il - S_i[:, None] - C_l[None, :] + GM) ** 2)

    SS_SAB = qc * np.sum(
        (SAB_ijk - SA_ij[:, :, None] - SB_ik[:, None, :]
         - AB_jk[None, :, :] + S_i[:, None, None] + A_j[None, :, None] + B_k[None, None, :]
         - GM) ** 2
    )
    SS_SAC = qb * np.sum(
        (SAC_ijl - SA_ij[:, :, None] - SC_il[:, None, :]
         - AC_jl[None, :, :] + S_i[:, None, None] + A_j[None, :, None] + C_l[None, None, :]
         - GM) ** 2
    )
    SS_SBC = qa * np.sum(
        (SBC_ikl - SB_ik[:, :, None] - SC_il[:, None, :]
         - BC_kl[None, :, :] + S_i[:, None, None] + B_k[None, :, None] + C_l[None, None, :]
         - GM) ** 2
    )
    SS_SABC = np.sum(
        (Y
         - SAB_ijk[:, :, :, None] - SAC_ijl[:, :, None, :]
         - SBC_ikl[:, None, :, :] - ABC_jkl[None, :, :, :]
         + SA_ij[:, :, None, None] + SB_ik[:, None, :, None] + SC_il[:, None, None, :]
         + AB_jk[None, :, :, None] + AC_jl[None, :, None, :] + BC_kl[None, None, :, :]
         - S_i[:, None, None, None] - A_j[None, :, None, None]
         - B_k[None, None, :, None] - C_l[None, None, None, :]
         + GM) ** 2
    )

    SS_within = SS_total - SS_S
    SS_check = (SS_A + SS_SA + SS_B + SS_SB + SS_C + SS_SC
                + SS_AB + SS_SAB + SS_AC + SS_SAC + SS_BC + SS_SBC
                + SS_ABC + SS_SABC)
    assert abs(SS_within - SS_check) < 1e-6, f"SS decomp failed: within={SS_within:.6f} vs check={SS_check:.6f}"

    df_s = n_subj - 1
    A_name, B_name, C_name = factor_names

    # Print in rmaov33 style
    print(f"\n  The number of IV1 levels are: {qa}")
    print(f"  The number of IV2 levels are: {qb}")
    print(f"  The number of IV3 levels are: {qc}")
    print(f"  The number of subjects are:   {n_subj}")
    print()
    print("  Three-Way Analysis of Variance With Repeated Measures on Three Factors Table.")
    print("  " + "-" * 99)
    fmt = "  {:<30s} {:>12.3f} {:>6d} {:>15.3f} {:>10.3f} {:>8.4f}   {:<4s}"
    fmt_err = "  {:<30s} {:>12.3f} {:>6d} {:>15.3f}"
    hdr = f"  {'SOV':<30s} {'SS':>12s} {'df':>6s} {'MS':>15s} {'F':>10s} {'P':>8s}   {'Sig':>4s}"
    print(hdr)
    print("  " + "-" * 99)

    # Between-subjects
    print(f"  {'Between-Subjects':<30s} {SS_S:>12.3f} {df_s:>6d}")
    print()
    print(f"  {'Within-Subjects':<30s} {SS_within:>12.3f} {n_subj * (qa*qb*qc - 1) - df_s:>6d}")

    effects = [
        (A_name,               SS_A,   SS_SA,   qa - 1),
        (B_name,               SS_B,   SS_SB,   qb - 1),
        (C_name,               SS_C,   SS_SC,   qc - 1),
        (f"{A_name}x{B_name}", SS_AB,  SS_SAB,  (qa-1)*(qb-1)),
        (f"{A_name}x{C_name}", SS_AC,  SS_SAC,  (qa-1)*(qc-1)),
        (f"{B_name}x{C_name}", SS_BC,  SS_SBC,  (qb-1)*(qc-1)),
        (f"{A_name}x{B_name}x{C_name}", SS_ABC, SS_SABC, (qa-1)*(qb-1)*(qc-1)),
    ]

    results = []
    for name, ss_eff, ss_err, df_eff in effects:
        df_err = df_s * df_eff
        MS_eff = ss_eff / df_eff
        MS_err = ss_err / df_err
        F_val = MS_eff / MS_err if MS_err > 0 else np.inf
        p_val = stats.f.sf(F_val, df_eff, df_err)
        sig = "S" if p_val < 0.05 else "NS"
        print(fmt.format(name, ss_eff, df_eff, MS_eff, F_val, p_val, sig))
        print(fmt_err.format(f"Error({name})", ss_err, df_err, MS_err))
        print()
        results.append((name, df_eff, df_err, F_val, p_val, ss_eff / (ss_eff + SS_S + ss_err)))

    print("  " + "-" * 99)
    print(f"  {'Total':<30s} {SS_total:>12.3f} {N_total - 1:>6d}")
    print("  " + "-" * 99)
    print(f"  With a given significance level of: 0.05")
    return results


def paired_contrast(vals_a, vals_b, df_denom):
    diff = vals_a - vals_b
    estimate = diff.mean()
    se = diff.std(ddof=1) / np.sqrt(len(diff))
    t_val = estimate / se if se > 0 else np.inf
    p_val = 2 * stats.t.sf(abs(t_val), df_denom)
    return estimate, se, df_denom, t_val, p_val


# ───────────────────────────────────────────────────────────────────
# 3. RUN ANOVAS FOR EACH ROLE
# ───────────────────────────────────────────────────────────────────
all_results = {}

for role in role_levels:
    role_dat = dat[dat["Role"] == role].copy()

    # Build Y[subject, melody, partner, elec]
    Y = np.full((n, q_m, q_p, q_e), np.nan)
    for _, row in role_dat.iterrows():
        si = subj_idx[row["Subj"]]
        mi = melody_levels.index(row["Melody"])
        pi = partner_levels.index(row["Partner"])
        ei = elec_levels.index(row["Elec"])
        Y[si, mi, pi, ei] = row["AlphaERD"]

    assert not np.isnan(Y).any(), f"Missing cells for {role}!"

    print(f"\n{'='*80}")
    print(f"  {role.upper()}")
    print(f"{'='*80}")

    # Cell means (avg over electrodes, matching Washburn style)
    print(f"\n  Cell means (averaged over electrodes):")
    for mi, mlev in enumerate(melody_levels):
        for pi, plev in enumerate(partner_levels):
            vals = Y[:, mi, pi, :].mean(axis=1)
            print(f"    {mlev:5s} {plev:6s}: M={vals.mean():>8.3f}%, SD={vals.std(ddof=1):>8.3f}")

    # ANOVA: IV1=melody, IV2=partner, IV3=elec (matching MATLAB)
    results = rm_anova_3way(Y, n, q_m, q_p, q_e, ["Melody", "Partner", "Elec"])
    all_results[role] = (results, Y)

    # Post-hoc: melody × partner interaction (key from Washburn)
    print(f"\n  Post-hoc: Melody x Partner (averaged over electrodes)")
    df_ph = n - 1
    Y_mp = Y.mean(axis=3)  # [subj, melody, partner]

    print(f"    {'contrast':<30s} {'est':>9s} {'SE':>9s} {'df':>4s} {'t':>9s} {'p':>9s}")
    # Partner contrasts within each melody
    for mi, mlev in enumerate(melody_levels):
        est, se, df, t, p = paired_contrast(Y_mp[:, mi, 0], Y_mp[:, mi, 1], df_ph)
        print(f"    human-comp | {mlev:<14s} {est:>9.3f} {se:>9.3f} {df:>4d} {t:>9.3f} {p:>9.4f}")

    # Melody contrasts within each partner
    for pi, plev in enumerate(partner_levels):
        est, se, df, t, p = paired_contrast(Y_mp[:, 0, pi], Y_mp[:, 1, pi], df_ph)
        print(f"    same-diff  | {plev:<14s} {est:>9.3f} {se:>9.3f} {df:>4d} {t:>9.3f} {p:>9.4f}")
    print()


# ───────────────────────────────────────────────────────────────────
# 4. INTERACTION PLOTS (melody × partner, separate panels for role)
# ───────────────────────────────────────────────────────────────────
fig, axes = plt.subplots(1, 2, figsize=(10, 5), sharey=True)

colors = {"human": "#1b9e77", "comp": "#d95f02"}
markers = {"human": "o", "comp": "s"}
x_positions = np.array([0, 1])

for ri, role in enumerate(role_levels):
    _, Y = all_results[role]
    Y_mp = Y.mean(axis=3)  # avg over electrodes: [subj, melody, partner]
    ax = axes[ri]

    # Cousineau-Morey within-subject SE
    n_cond = q_m * q_p
    correction = np.sqrt(n_cond / (n_cond - 1))
    Y_flat = Y_mp.reshape(n, -1)
    subj_gm = Y_flat.mean(axis=1)
    overall_gm = Y_flat.mean()

    for pi, plev in enumerate(partner_levels):
        cell_norm = Y_mp[:, :, pi] - subj_gm[:, None] + overall_gm
        means = cell_norm.mean(axis=0)
        se_cm = cell_norm.std(axis=0, ddof=1) / np.sqrt(n) * correction

        ax.errorbar(x_positions, means, yerr=se_cm,
                     color=colors[plev], marker=markers[plev],
                     markersize=7, capsize=4, linewidth=1.5,
                     label=plev.capitalize())

    ax.set_title(role.capitalize(), fontsize=13)
    ax.set_xticks(x_positions)
    ax.set_xticklabels(["Same", "Diff"])
    ax.set_xlabel("Melody type")
    ax.set_xlim(-0.3, 1.3)
    ax.axhline(y=0, color='gray', linestyle='--', alpha=0.5)

axes[0].set_ylabel("Alpha ERD (%)")
handles, labels = axes[0].get_legend_handles_labels()
fig.legend(handles, labels, loc="lower center", ncol=2, frameon=False,
           fontsize=11, title="Partner")
fig.tight_layout(rect=[0, 0.08, 1, 1])
fig.savefig("output/AlphaERD_interaction_plot.png", dpi=150)
plt.close(fig)
print("\nSaved: output/AlphaERD_interaction_plot.png")

print("\nDone.")
