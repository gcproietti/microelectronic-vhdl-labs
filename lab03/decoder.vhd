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
            CALL:	        In	std_logic;          --call flag	
			RET:	        In	std_logic;          --return flag
            SPILL:	        Out	std_logic;	        --SPILL flag
			FILL:	        Out	std_logic;          --FILL flag
            ADD_to_STACK:   Out PHYSICAL_ADDR);     --address for the stack (for the FILL and SPILL operations)
end DECODER;



architecture MIXED of DECODER is

    --LOCAL COUNTERS
    signal CWP, SWP : integer range 0 to F-1;       
    signal used_windows : integer range 0 to F;     --counter for the used windows
    signal stack_counter : integer range 0 to 2*N;  --counter for counting the registers that is necessary to send to the stack 
    
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
    --Translating from the Virtual address (sended) in the real(physical) address for the registers file--
    local_ADD_WR <= ((F * 2 * N) + N + ADD_WR) when (ADD_WR < M)    --Global registers (we used F instead of CWP because they are always at the end of the RF)
                    else ((CWP * 2 * N) + (ADD_WR - M));            --IN/LOCAL/OUT registers (these depend on the value of CWP, the current window)
                    
    local_ADD_RD1 <= ((F * 2 * N) + N + ADD_RD1) when (ADD_RD1 < M) 
                    else ((CWP * 2 * N) + (ADD_RD1 - M));
                    
    local_ADD_RD2 <= ((F * 2 * N) + N + ADD_RD2) when (ADD_RD2 < M) 
                    else ((CWP * 2 * N) + (ADD_RD2 - M));
    -----------

    RF_inst: registerfile
     generic map(
        nbit_data => nbit_data,
        nbit_addr => nbit_addr
    )
     port map(
        CLK     => CLK,         
        RESET   => RESET,
        ENABLE  => ENABLE,
        RD1     => RD1,             --reading1 enable
        RD2     => RD2,             --reading2 enable
        WR      => WR,              --writing enable
        ADD_WR  => local_ADD_WR,    --writing address
        ADD_RD1 => local_ADD_RD1,   --reading1 address
        ADD_RD2 => local_ADD_RD2,   --reading2 address
        DATAIN  => DATAIN,          --writing input
        OUT1    => OUT1,            --reading1 output
        OUT2    => OUT2             --reading2 output
    );

--It's necessary to use a process synchronised with the clock (sensitivity list)
POINTER_UPDATE: process(CLK)
begin
    --The process is evaluated on any change to CLK.
    --This condition restricts actions strictly to the rising edge.
    if rising_edge(CLK) then
        
        -- Reset (all the counters and flags are reset to zero)
        if Reset = '1' then
            CWP <= 0;
            SWP <= 0;
            stack_counter <= 0;
            used_windows <= 1;
            SPILL <= '0';
            FILL <= '0';
            
        --Enable
        elsif Enable = '1' then
            
            --Handle CALL instruction
            if CALL = '1' then
                --At the beginning is necessary to check if there are windows available through CANSAVE

                --Handle SPILL instruction
                if CANSAVE = '0' then
                    --Any windows is available to save(call) operation
                    SPILL <= '1';   --tell the stack that is necessary to SPILL a window to the stack to empty it
                    
                    --This condition is necessary to tell to the RF to wait until all the registers (in the corresponding window) are sended to the stack
                    if stack_counter<2*N then
                        local_ADDR_Stack <= (SWP * 2 * N) + stack_counter; --by 2N instead of 3N because we want only the IN and LOCAL regs because the OUT is the IN of the next window
                        stack_counter <= stack_counter +1;

                    else 
                        --after the regs are sended to the stack a windows become free
                        used_windows <= used_windows - 1;
                        
                        --and the SWP is incremented by one
                        --this is the circular way to execute SWP++
                        if SWP = (F - 1) then
                            SWP <= 0;
                        else
                            SWP <= SWP + 1;
                        end if;
                        SPILL <= '0';       --SPILL is resetted because the operation is finished
                        stack_counter <= 0;

                    end if;

                else --Handle CALL (without SPILL) instruction
                    --the SWP is incremented by one
                    --this is the circular way to execute SWP++
                    if CWP = (F - 1) then
                        CWP <= 0;
                    else
                        CWP <= CWP + 1;
                    end if;

                    used_windows <= used_windows + 1;   --in this case a new window is used(occupied)

                end if;
                
            --Handle RETURN instruction
            elsif RET = '1' then
                
                --Handle FILL instruction
                if CANRESTORE = '0' then
                    --Any windows is available to restore operation
                    FILL <= '1';    --tell the stack that is necessary to FILL a window from the stack to restore it
                    
                    --This condition is necessary to tell to the RF to wait until all the registers (in the corresponding window) are received from the stack
                    if stack_counter<2*N then

                        --in this case is necessary to go back so we need to check if the SWP is zero ro not
                        if SWP = 0 then
                            local_ADDR_Stack <= ((F-1) * 2 *N) + stack_counter;
                        else
                            local_ADDR_Stack <= ((SWP-1) * 2 * N) + stack_counter;
                        end if;

                        stack_counter <= stack_counter +1;
                    else 
                        used_windows <= used_windows + 1;     

                        if SWP = 0 then
                            SWP <= F-1;
                        else
                            SWP <= SWP - 1;
                        end if;
                        FILL <= '0';
                        stack_counter <= 0;
                    end if;
                
                else --Handle RET (without FILL) instruction

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

--Mapping of the signal CANSAVE and CANRESTORE 
CANSAVE <= '1' when (used_windows < F) else '0';    --if there are windows empty -> CANSAVE=1 else CANSAVE=0
CANRESTORE <= '1' when (used_windows > 1) else '0'; --if there are windows available for restoring -> CANRESTORE=1 else CANRESTORE=0

ADD_to_STACK <= local_ADDR_Stack;   --local_ADDR_Stack is mapped to ADD_to_STACK, to connect the cables

end MIXED;
