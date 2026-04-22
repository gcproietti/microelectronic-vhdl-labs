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
        ADD_WR: 	IN PHYSICAL_ADDR;
        ADD_RD1: 	IN PHYSICAL_ADDR;
        ADD_RD2: 	IN PHYSICAL_ADDR;
        DATAIN: 	IN std_logic_vector(nbit_data-1 downto 0);
        OUT1: 		OUT std_logic_vector(nbit_data-1 downto 0);
        OUT2: 		OUT std_logic_vector(nbit_data-1 downto 0));
end registerfile;

architecture A of registerfile is

signal REGISTERS : VIR_REG_ARRAY;

	
begin 
  process (CLK)
    variable TMP_REGISTERS : VIR_REG_ARRAY;

  begin

    if rising_edge(CLK) then

      TMP_REGISTERS := REGISTERS;

      if RESET = '1' then

        for i in PHYSICAL_ADDR loop
          TMP_REGISTERS(i) := (others => '0');
        end loop;

        REGISTERS <= TMP_REGISTERS;
        OUT1 <= (others => '0');
        OUT2 <= (others => '0');

      elsif ENABLE = '1' then

        if WR = '1' then
          TMP_REGISTERS(ADD_WR) := DATAIN;
        end if;

        if RD1 = '1' then
          OUT1 <= TMP_REGISTERS(ADD_RD1);
        end if;

        if RD2 = '1' then
          OUT2 <= TMP_REGISTERS(ADD_RD2);
        end if;

        REGISTERS <= TMP_REGISTERS;
      end if;

    end if;
  end process;
      
  

end A;

