library IEEE;
use IEEE.std_logic_1164.all; --  libreria IEEE con definizione tipi standard logic
use IEEE.numeric_std.all;
use WORK.constants.all; -- libreria WORK user-defined

entity DECODER is
  generic ( M: integer := M_const;
	        N: integer := N_const;
            F: integer := F_const;
            nbit_data : integer :=  (3*N+M)/NumBit_address;
            nbit_addr : integer := NumBit_address);
	Port (  CLK: 		IN std_logic;
            RESET: 	    IN std_logic;
            ENABLE: 	IN std_logic;
            RD1: 		IN std_logic;
            RD2: 		IN std_logic;
            WR: 		IN std_logic;
            ADD_WR: 	IN PHYSICAL_ADDR;
            ADD_RD1: 	IN PHYSICAL_ADDR;
            ADD_RD2: 	IN PHYSICAL_ADDR;
            DATAIN: 	IN std_logic_vector(nbit_data-1 downto 0);
            OUT1: 		OUT std_logic_vector(nbit_data-1 downto 0);
            OUT2: 		OUT std_logic_vector(nbit_data-1 downto 0);	
            --decoder
            CALL:	        In	std_logic;	
			RET:	        In	std_logic;
            SPILL:	        Out	std_logic;	
			FILL:	        Out	std_logic;
            ADD_to_STACK:   Out PHYSICAL_ADDR);
end DECODER;



architecture MIXED of DECODER is

    --LOCAL COUNTERS
    signal CWP, SWP : integer range 0 to F-1;
    signal used_windows : integer range 0 to F;
    signal spill_counter : integer range 0 to 2*N;
    
    --LOCAL ADDRESSES
    signal local_ADD_WR : PHYSICAL_ADDR;
    signal local_ADD_RD1 : PHYSICAL_ADDR;
    signal local_ADD_RD2 : PHYSICAL_ADDR;
    signal local_ADDR_Stack : PHYSICAL_ADDR; 
    
    --LOCAL FLAGS
    signal CANSAVE, CANRESTORE : std_logic;

    component registerfile
		generic(nbit_data : integer :=  NumBit_data;
	      nbit_addr : integer := NumBit_address);
        port ( CLK: 		IN std_logic;
                RESET: 	    IN std_logic;
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
	end component;

begin

    local_ADD_WR <= ((F * 2 * N) + N + ADD_WR) when (ADD_WR < M)    --Global registers
                    else ((CWP * 2 * N) + (ADD_WR - M));            --IN/LOCAL/OUT registers
                    
    local_ADD_RD1 <= ((F * 2 * N) + N + ADD_RD1) when (ADD_RD1 < M) 
                    else ((CWP * 2 * N) + (ADD_RD1 - M));
                    
    local_ADD_RD2 <= ((F * 2 * N) + N + ADD_RD2) when (ADD_RD2 < M) 
                    else ((CWP * 2 * N) + (ADD_RD2 - M));

    RF_inst: entity work.registerfile
     generic map(
        nbit_data => nbit_data,
        nbit_addr => nbit_addr
    )
     port map(
        CLK => CLK,         
        RESET => RESET,
        ENABLE => ENABLE,
        RD1 => RD1,         --reading1 enable
        RD2 => RD2,         --reading2 enable
        WR => WR,           --writing enable
        ADD_WR => local_ADD_WR,  --writing address
        ADD_RD1 => local_ADD_RD1,               --reading1 address
        ADD_RD2 => local_ADD_RD2,               --reading2 address
        DATAIN => DATAIN,   --writing input
        OUT1 => OUT1,       --reading1 output
        OUT2 => OUT2        --reading2 output
    );


POINTER_UPDATE: process(CLK)
begin
    -- The process is evaluated on any change to CLK.
    -- This condition restricts actions strictly to the rising edge.
    if rising_edge(CLK) then
        
        -- 1. Synchronous Reset 
        if Reset = '1' then
            CWP <= 0;
            SWP <= 0;
            spill_counter <= 0;
            used_windows <= 1;
            
        -- 2. Normal Synchronous Operation
        elsif Enable = '1' then
            
            -- Handle CALL instruction
            if CALL = '1' then
                
                --SPILL
                if CANSAVE = '0' then
                    SPILL <= '1';
                    
                    if spill_counter<2*N then
                        local_ADDR_Stack <= SWP*2*N + spill_counter; --per 2N instead of 3N because we want only the IN and LOCAL reg because the OUT are shared with the next window
                        spill_counter <= spill_counter +1;

                    else 
                        used_windows <= used_windows - 1;
                    
                        if SWP = (F - 1) then
                            SWP <= 0;
                        else
                            SWP <= SWP + 1;
                        end if;
                        SPILL <= '0';
                        spill_counter <= 0;

                    end if;

                else --NOT SPILL

                    if CWP = (F - 1) then
                        CWP <= 0;
                        
                    else
                        CWP <= CWP + 1;

                    end if;

                    used_windows <= used_windows + 1;

                end if;
                
            -- Handle RETURN instruction
            elsif RET = '1' then
                
                --FILL
                if CANRESTORE = '0' then
                    FILL <= '1';
                    
                    if spill_counter<2*N then
                        if SWP = 0 then
                            local_ADDR_Stack <= (F-1)*2*N + spill_counter;
                        else
                            local_ADDR_Stack <= (SWP-1)*2*N + spill_counter;
                        end if;
                        spill_counter <= spill_counter +1;
                    else 
                        used_windows <= used_windows + 1;     

                        if SWP = 0 then
                            SWP <= F-1;
                        else
                            SWP <= SWP - 1;
                        end if;
                        FILL <= '0';
                        spill_counter <= 0;
                    end if;
                
                else --NOT FILL

                    if CWP = 0 then
                        CWP <= (F - 1);
                    else
                        CWP <= CWP - 1;
                    end if;

                    used_windows <= used_windows - 1;
                end if;
            end if;

            
            
        end if;

    end if;
end process;

CANSAVE <= '1' when (used_windows < F) else '0';
CANRESTORE <= '1' when (used_windows > 1) else '0';

ADD_to_STACK <= local_ADDR_Stack;

end MIXED;


--configuration CFG_DECODER_MIXED of DECODER is
--	for MIXED
--				use configuration WORK.CFG_MUX21_BEHAVIORAL_2;
--	end for;
--end CFG_DECODER_MIXED;
