# Unknown
To do some FP and ALU-RBA

404000B7  →  lui x1, 0x40400  (x1 = 3.0)
40000137  →  lui x2, 0x40000  (x2 = 2.0)
00210253  →  fadd.s f4, x1, x2
041102D3  →  fsub.s f5, x2, x1  
08110353  →  fmul.s f6, x2, x1
0C2083D3  →  fdiv.s f7, x1, x2