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
            ADD_WR: 	IN std_logic_vector(nbit_addr-1 downto 0);
            ADD_RD1: 	IN std_logic_vector(nbit_addr-1 downto 0);
            ADD_RD2: 	IN std_logic_vector(nbit_addr-1 downto 0);
            DATAIN: 	IN std_logic_vector(nbit_data-1 downto 0);
            OUT1: 		OUT std_logic_vector(nbit_data-1 downto 0);
            OUT2: 		OUT std_logic_vector(nbit_data-1 downto 0);	
            --decoder
            CALL:	In	std_logic;	
			RET:	In	std_logic;
            SPILL:	Out	std_logic;	
			FILL:	Out	std_logic;
            ADD_to_STACK: Out std_logic_vector(nbit_data-1 downto 0));
end DECODER;



architecture MIXED of DECODER is

    -- Assuming nbit_addr is a generic (e.g., 5 bits for 32 registers)
    subtype VIRTUAL_ADDR is natural range 0 to (2**nbit_addr) - 1; 

    -- For the internal hardware array (Physical)
    subtype PHYSICAL_ADDR is natural range 0 to (F * 2 * N) + N + M - 1;

    --type REG_ARRAY is array(PHYSICAL_ADDR) of std_logic_vector(nbit_data-1 downto 0); 

    --LOCAL COUNTERS
    signal CWP, SWP : integer range 0 to F-1;
    signal used_windows : integer range 0 to F;
    signal spill_counter : integer range 0 to 2*N;
    
    --LOCAL ADDRESSES
    signal local_ADD_WR : PHYSICAL_ADDR;
    signal local_ADD_RD1 : PHYSICAL_ADDR;
    signal local_ADD_RD2 : PHYSICAL_ADDR;
    signal local_ADD_toStack : PHYSICAL_ADDR; 
    
    --LOCAL FLAGS
    signal CANSAVE, CANRESTORE : std_logic;

    component registerfile
		generic(nbit_data : integer :=  (3*N+M)/NumBit_address;
	            nbit_addr : integer := NumBit_address);
        port (  CLK: 		IN std_logic;
                RESET: 	    IN std_logic;
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
	end component;

begin
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
        ADD_WR => local_ADD_WR,         --writing address
        ADD_RD1 => R_ADD_RD1,        --reading1 address
        ADD_RD2 => R_ADD_RD2,        --reading2 address
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
            
        -- 2. Normal Synchronous Operation
        elsif Enable = '1' then
            
            -- Handle CALL instruction
            if CALL = '1' then
                -- Circular increment logic for modulo F
                if CWP = (F - 1) then
                    CWP <= 0;
                    
                else
                    CWP <= CWP + 1;

                end if;

                used_windows <= used_windows + 1;

                --SPILL
                if CANSAVE = '0' then
                    SPILL <= '1';
                    
                    if spill_counter<2*N then
                        local_ADD_toStack <= SWP*2*N + spill_counter;
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

                end if;
                
            -- Handle RETURN instruction
            elsif RET = '1' then
                -- Circular decrement logic for modulo F
                if CWP = 0 then
                    CWP <= (F - 1);
                else
                    CWP <= CWP - 1;
                end if;

                used_windows <= used_windows - 1;
                --FILL
                if CANRESTORE = '0' then
                    FILL <= '1';
                    
                    if SWP = (F - 1) then
                        SWP <= 0;
                    else
                        SWP <= SWP - 1;
                    end if;

                end if;
            end if;

            
            
        end if;

    end if;
end process;

CANSAVE <= '1' when (used_windows < F) else '0';
CANRESTORE <= '1' when (used_windows > 1) else '0';



end MIXED;


configuration CFG_DECODER_MIXED of DECODER is
	for MIXED
		for mux51_loop	
			for all : MUX21
				use configuration WORK.CFG_MUX21_BEHAVIORAL_2;
			end for;
		end for;
	end for;
end CFG_DECODER_MIXED;
