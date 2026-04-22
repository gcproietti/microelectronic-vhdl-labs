library IEEE;
use IEEE.std_logic_1164.all; --  libreria IEEE con definizione tipi standard logic
use IEEE.numeric_std.all;

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

   -- VIRTUAL ADDRESS TYPES
   subtype VIRTUAL_ADDR is natural range 0 to (2**NumBit_address) - 1;
   type VIR_REG_ARRAY is array(VIRTUAL_ADDR) of std_logic_vector(NumBit_data-1 downto 0);  

   -- PHYSICAL(REAL) ADDRESS TYPES
   subtype PHYSICAL_ADDR is natural range 0 to (F_const * 2 * N_const) + N_const + M_const - 1;
   type PHY_REG_ARRAY is array(PHYSICAL_ADDR) of std_logic_vector(NumBit_data-1 downto 0); 
end CONSTANTS;
