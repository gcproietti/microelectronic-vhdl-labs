library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use WORK.constants.all;

entity registerfile is
 generic(nbit_data : integer :=  NumBit_data;
	 nbit_addr : integer := NumBit_address);
 port ( CLK: 		IN std_logic;
         RESET: 	IN std_logic;
	 ENABLE: 	IN std_logic;
	 RD1: 		IN std_logic;
	 RD2: 		IN std_logic;
	 WR: 		IN std_logic;
	 ADD_WR: 	IN std_logic_vector(nbit_addr-1 downto 0);
	 ADD_RD1: 	IN std_logic_vector(nbit_addr-1 downto 0);
	 ADD_RD2: 	IN std_logic_vector(nbit_addr-1 downto 0);
	 DATAIN: 	IN std_logic_vector(nbit_data-1 downto 0);
         OUT1: 		OUT std_logic_vector(nbit_data-1 downto 0);
	 OUT2: 		OUT std_logic_vector(nbit_data-1 downto 0));
end registerfile;

architecture A of registerfile is

        -- suggested structures
        subtype REG_ADDR is natural range 0 to 31; -- using natural type
	type REG_ARRAY is array(REG_ADDR) of std_logic_vector(nbit_data-1 downto 0); 
	signal REGISTERS : REG_ARRAY;

	
begin 
  process (CLK)
    variable TMP_REGISTERS : REG_ARRAY;
    variable WR_ADDR  : REG_ADDR;
    variable RD1_ADDR : REG_ADDR;
    variable RD2_ADDR : REG_ADDR;
  begin

    if rising_edge(CLK) then

      TMP_REGISTERS := REGISTERS;
      if RESET = '1' then
        for i in REG_ADDR loop
          TMP_REGISTERS(i) := (others => '0');
        end loop;
        REGISTERS <= TMP_REGISTERS;
        OUT1 <= (others => '0');
        OUT2 <= (others => '0');

      elsif ENABLE = '1' then

        WR_ADDR  := conv_integer(ADD_WR);
        RD1_ADDR := conv_integer(ADD_RD1);
        RD2_ADDR := conv_integer(ADD_RD2);

        if WR = '1' then
          TMP_REGISTERS(WR_ADDR) := DATAIN;
        end if;

        if RD1 = '1' then
          OUT1 <= TMP_REGISTERS(RD1_ADDR);
        end if;

        if RD2 = '1' then
          OUT2 <= TMP_REGISTERS(RD2_ADDR);
        end if;

        REGISTERS <= TMP_REGISTERS;
      end if;

    end if;
  end process;
      
  

end A;

----


configuration CFG_RF_BEH of registerfile is
  for A
  end for;
end configuration;
