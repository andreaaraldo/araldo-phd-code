% Data taken from some paper
A_360p = -17.53;
B_360p = -1.048;
C_360p = 0.9912;

r_360p = [250, 750, 1600]  ;% bit-rate


u_360p = A_360p * r_360p.^B_360p + C_360p
cache_space = r_360p .* 60 * 5 / 8


A_720p = -4.85;
B_720p = -0.647;
C_720p = 1.011;

r_720p = [2100, 3000, 3450]  ;% bit-rate


u_720p = A_720p * r_720p.^B_720p + C_720p
cache_space = r_720p .* 60 * 5 / 8
