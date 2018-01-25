% test_solve_for_V.m
clear
clc

A= [0.3 -0.5;-0.5 1];
b = [2;6];
c = [0;0];
e = [1;1];
expected_feedback_num = 1;

[cvx_v, matlab_v] = solve_for_V(A,b,c,e, expected_feedback_num);

