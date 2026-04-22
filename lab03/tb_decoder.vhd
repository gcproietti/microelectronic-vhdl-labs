library IEEE;
use IEEE.std_logic_1164.all; --  libreria IEEE con definizione tipi standard logic
use IEEE.numeric_std.all;
use WORK.constants.all; -- libreria WORK user-defined

entity tb_decoder is
end tb_decoder;

architecture tb of tb_decoder is

    component DECODER
        generic ( 
            M: integer := M_const;
            N: integer := N_const;
            F: integer := F_const;
            nbit_data : integer := NumBit_data;
            nbit_addr : integer := NumBit_address
        );
        Port (  
            CLK:            IN std_logic;
            RESET:          IN std_logic;
            ENABLE:         IN std_logic;
            RD1:            IN std_logic;
            RD2:            IN std_logic;
            WR:             IN std_logic;
            ADD_WR:         IN PHYSICAL_ADDR;
            ADD_RD1:        IN PHYSICAL_ADDR;
            ADD_RD2:        IN PHYSICAL_ADDR;
            DATAIN:         IN std_logic_vector(nbit_data-1 downto 0);
            OUT1:           OUT std_logic_vector(nbit_data-1 downto 0);
            OUT2:           OUT std_logic_vector(nbit_data-1 downto 0);	
            CALL:           IN std_logic;	
            RET:            IN std_logic;
            SPILL:          OUT std_logic;	
            FILL:           OUT std_logic;
            ADD_to_STACK:   OUT PHYSICAL_ADDR
        );
    end component;

    constant CLK_PERIOD : time := 10 ns;

    signal CLK_tb          : std_logic := '0';
    signal RESET_tb        : std_logic := '0';
    signal ENABLE_tb       : std_logic := '0';
    signal RD1_tb          : std_logic := '0';
    signal RD2_tb          : std_logic := '0';
    signal WR_tb           : std_logic := '0';
    
    -- Address inputs (using the custom PHYSICAL_ADDR subtype)
    signal ADD_WR_tb       : PHYSICAL_ADDR := 0;
    signal ADD_RD1_tb      : PHYSICAL_ADDR := 0;
    signal ADD_RD2_tb      : PHYSICAL_ADDR := 0;
    
    -- Data buses
    signal DATAIN_tb       : std_logic_vector(NumBit_data-1 downto 0) := (others => '0');
    signal OUT1_tb         : std_logic_vector(NumBit_data-1 downto 0);
    signal OUT2_tb         : std_logic_vector(NumBit_data-1 downto 0);
    
    -- Control and Status Signals
    signal CALL_tb         : std_logic := '0';
    signal RET_tb          : std_logic := '0';
    signal SPILL_tb        : std_logic;
    signal FILL_tb         : std_logic;
    signal ADD_to_STACK_tb : PHYSICAL_ADDR;

begin

    --Unit under test
    uut: DECODER 
        port map (
            CLK          => CLK_tb,
            RESET        => RESET_tb,
            ENABLE       => ENABLE_tb,
            RD1          => RD1_tb,
            RD2          => RD2_tb,
            WR           => WR_tb,
            ADD_WR       => ADD_WR_tb,
            ADD_RD1      => ADD_RD1_tb,
            ADD_RD2      => ADD_RD2_tb,
            DATAIN       => DATAIN_tb,
            OUT1         => OUT1_tb,
            OUT2         => OUT2_tb,
            CALL         => CALL_tb,
            RET          => RET_tb,
            SPILL        => SPILL_tb,
            FILL         => FILL_tb,
            ADD_to_STACK => ADD_to_STACK_tb
        );

    -- Clock Generation Process
    clk_process : process
    begin
        CLK_tb <= '0';
        wait for CLK_PERIOD/2;
        CLK_tb <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- Main Simulation Process
    sim_process: process
    begin
        ADD_WR_tb  <= 5;  -- Global register test
        ADD_RD1_tb <= 80; -- Window register test
        ADD_RD2_tb <= 85; -- Window register test


        -- 1. INITIALIZATION & RESET
        RESET_tb <= '1';
        wait for CLK_PERIOD * 2;
        RESET_tb <= '0';
        ENABLE_tb <= '1';
        wait for CLK_PERIOD;

        -- 2. CALLs
        CALL_tb <= '1';
        wait for CLK_PERIOD;
        CALL_tb <= '0';
        wait for CLK_PERIOD * 2; -- wait

        CALL_tb <= '1';
        wait for CLK_PERIOD;
        CALL_tb <= '0';
        wait for CLK_PERIOD * 2;

        -- 3. TRIGGERING A SPILL
        CALL_tb <= '1';
        wait for CLK_PERIOD; 
        
        -- The CPU must hold the CALL instruction while SPILL is active.
        -- This loop waits for the stack_counter to reach 2*N.
        while SPILL_tb = '1' loop
            wait for CLK_PERIOD;
        end loop;
        
        CALL_tb <= '0'; -- Instruction completes
        wait for CLK_PERIOD * 3;


        -- 4. RETs
        RET_tb <= '1';
        wait for CLK_PERIOD;
        RET_tb <= '0';
        wait for CLK_PERIOD * 2;


        -- 5. TRIGGERING A FILL
        RET_tb <= '1';
        wait for CLK_PERIOD;
        
        -- The CPU must hold the RET instruction while FILL is active.
        -- This loop waits for the stack_counter to reach 2*N.
        while FILL_tb = '1' loop
            wait for CLK_PERIOD;
        end loop;
        
        RET_tb <= '0'; -- Instruction completes
        wait for CLK_PERIOD * 3;

        wait;
    end process;

end tb;