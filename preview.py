import MesaReader as mr
import numpy as np
import argparse
import matplotlib.pyplot as plt
plt.style.use('./journal.mplstyle')
from matplotlib.backends.backend_pdf import PdfPages
psr = argparse.ArgumentParser()
psr.add_argument('-m', dest='model')
psr.add_argument('-o', dest='opt')
args = psr.parse_args()
history_pms = 'LOGS_{}_pms/history.data'.format(args.model)
history_zams = 'LOGS_{}_zams/history.data'.format(args.model)
modelfile = args.model + '.model'

h_pms = mr.MesaData(history_pms)
h_zams = mr.MesaData(history_zams)
p = mr.MesaData(modelfile)
l = mr.MesaLogDir('LOGS_{}_zams'.format(args.model))
p_last = l.profile_data()
with PdfPages(args.opt) as pdf:
    fig, ax = plt.subplots()
    ax.plot(h_pms.log_Teff, h_pms.log_L)
    ax.plot(h_zams.log_Teff, h_zams.log_L)
    ax.set_xlabel('log($T_{Eff}$/K)')
    ax.set_ylabel('log Luminosity')
    # invert the x-axis
    ax.invert_xaxis()
    pdf.savefig(fig)
    plt.close()

    fig, ax = plt.subplots()
    ax.plot(p.R, p.h1, label='H1')
    ax.plot(p.R, p.he3, label='He3')
    ax.plot(p.R, p.he4, label='He4')
    ax.plot(p.R, p.c12, label='C12')
    ax.plot(p.R, p.n14, label='N14')
    ax.plot(p.R, p.o16, label='O16')
    ax.set_ylabel("fraction")
    ax.set_yscale('log')
    ax.set_xlabel('R($R_{sun}$)')
    ax.legend()
    pdf.savefig(fig)
    plt.close()

    fig, axs = plt.subplots(3,1)
    axs[0].plot(p.R, p.dq)
    axs[0].set_ylabel("Mass")
    axs[1].plot(p.R, p.d)
    axs[1].set_ylabel(r"$\rho/(\mathrm{g/cm}^3)$")
    axs[2].plot(p.R, p.T)
    axs[2].set_ylabel("T/K")
    axs[2].set_xlabel("R($R_{sun}$)")
    # make these tick labels invisible
    axs[0].tick_params('x', labelbottom=False)
    axs[1].tick_params('x', labelbottom=False)
    pdf.savefig(fig)
    plt.close()

    fig, ax = plt.subplots()
    ax.plot(p_last.R, p_last.screened_rate_r_h1_h1_ec_h2, label='pp')
    ax.plot(p_last.R, p_last.screened_rate_r_h1_h1_wk_h2, label='pep')
    ax.plot(p_last.R, p_last.screened_rate_r_be7_wk_li7, label='Be7')
    ax.plot(p_last.R, p_last.screened_rate_r_b8_wk_he4_he4, label='B8')
    ax.plot(p_last.R, p_last.screened_rate_r_h1_he3_wk_he4, label='Hep')
    ax.plot(p_last.R, p_last.screened_rate_r_n13_wk_c13, label='C')
    ax.plot(p_last.R, p_last.screened_rate_r_o15_wk_n15, label='N')
    ax.plot(p_last.R, p_last.screened_rate_r_f17_wk_o17, label='O')
    ax.set_xlabel("R($R_{sun}$)")
    ax.set_ylabel("screend rate")
    ax.set_yscale('log')
    ax.legend()
    pdf.savefig(fig)
    plt.close()

    fig, ax = plt.subplots()
    scale = p_last.R**2
    pp = scale * p.d **2 * p.h1 **2 * p_last.screened_rate_r_h1_h1_ec_h2
    pep = scale * p_last.ye * p.d **2 * p.h1 **2 * p_last.screened_rate_r_h1_h1_wk_h2
    be7 = scale * p_last.ye * p.d * p.be7/7 * p_last.screened_rate_r_be7_wk_li7
    b8 = scale * p.d * p.b8 * p_last.screened_rate_r_b8_wk_he4_he4
    hep = scale * p.d **2 * p.he3/3 * p.h1 * p_last.screened_rate_r_h1_he3_wk_he4
    c = scale * p.d * (p.n13/13) * p_last.screened_rate_r_n13_wk_c13
    n = scale * p.d * (p.o15/15) * p_last.screened_rate_r_o15_wk_n15
    o = scale * p.d * (p.f17/17) * p_last.screened_rate_r_f17_wk_o17
    ax.plot(p_last.R, pp, label='pp')
    ax.plot(p_last.R, pep, label='pep')
    ax.plot(p_last.R, be7, label='Be7')
    ax.plot(p_last.R, b8, label='B8')
    ax.plot(p_last.R, hep, label='Hep')
    ax.plot(p_last.R, c, label='C')
    ax.plot(p_last.R, n, label='N')
    ax.plot(p_last.R, o, label='O')
    ax.set_xlabel("R($R_{sun}$)")
    ax.set_ylabel("reaction rate")
    ax.set_xlim([0,0.35])
    ax.legend()
    pdf.savefig(fig)
    ax.set_ylim([1E-30,None])
    ax.set_yscale('log')
    pdf.savefig(fig)
    plt.close()

    fig, ax = plt.subplots()
    ax.plot(p_last.R, pp/np.sum(pp), label='pp')
    ax.plot(p_last.R, pep/np.sum(pep), label='pep')
    ax.plot(p_last.R, be7/np.sum(be7), label='Be7')
    ax.plot(p_last.R, b8/np.sum(b8), label='B8')
    ax.plot(p_last.R, hep/np.sum(hep), label='Hep')
    ax.plot(p_last.R, c/np.sum(c), label='C')
    ax.plot(p_last.R, n/np.sum(n), label='N')
    ax.plot(p_last.R, o/np.sum(o), label='O')
    ax.set_xlabel("R($R_{sun}$)")
    ax.set_ylabel("Nomalized screend rate")
    ax.set_xlim([0,0.35])
    ax.legend()
    pdf.savefig(fig)
    plt.close()