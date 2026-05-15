clc;
clear;
close all;

addpath(genpath(pwd));

fprintf('\n========== Running Figure 1 ==========\n');
main_fig1_ellipse();

fprintf('\n========== Running Figure 2 ==========\n');
main_fig2_spacing();

fprintf('\n========== Running Figure 3 ==========\n');
main_fig3_wedge_angle();

fprintf('\n========== Running Figure 4 ==========\n');
main_fig4_rate();

fprintf('\n========== Running Figure 5 ==========\n');
main_fig5_gnss_degradation();

fprintf('\n========== Running Scheme 1 ==========\n');
main_scheme1_offline();

fprintf('\n========== Running Scheme 2 ==========\n');
main_scheme2_robust();

fprintf('\n========== Running Scheme 3 ==========\n');
main_scheme3_mc_verify();

fprintf('\nAll simulations finished.\n');