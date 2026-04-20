package CONSTANTS is
   constant IVDELAY : time := 0.1 ns;
   constant NDDELAY : time := 0.2 ns;
   constant NDDELAYRISE : time := 0.6 ns;
   constant NDDELAYFALL : time := 0.4 ns;
   constant NRDELAY : time := 0.2 ns;
   constant DRCAS : time := 1 ns;
   constant DRCAC : time := 2 ns;
   --Register Files
   constant NumBit_data : integer := 64;
   constant NumBit_address : integer := 8;
   constant M_const : integer := 73;
   constant N_const : integer := 21;
   constant F_const : integer := 3;
   --
   constant Num_windows : integer := 3;
   constant TP_MUX : time := 0.5 ns; 	
end CONSTANTS;
