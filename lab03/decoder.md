
# Entity: DECODER 
- **File**: decoder.vhd

## Diagram
![Diagram](DECODER.svg "Diagram")
## Generics

| Generic name | Type    | Value                  | Description |
| ------------ | ------- | ---------------------- | ----------- |
| M            | integer | M_const                |             |
| N            | integer | N_const                |             |
| F            | integer | F_const                |             |
| nbit_data    | integer | (3*N+M)/NumBit_address |             |
| nbit_addr    | integer | NumBit_address         |             |

## Ports

| Port name    | Direction | Type                                   | Description |
| ------------ | --------- | -------------------------------------- | ----------- |
| CLK          | in        | std_logic                              |             |
| RESET        | in        | std_logic                              |             |
| ENABLE       | in        | std_logic                              |             |
| RD1          | in        | std_logic                              |             |
| RD2          | in        | std_logic                              |             |
| WR           | in        | std_logic                              |             |
| ADD_WR       | in        | PHYSICAL_ADDR                          |             |
| ADD_RD1      | in        | PHYSICAL_ADDR                          |             |
| ADD_RD2      | in        | PHYSICAL_ADDR                          |             |
| DATAIN       | in        | std_logic_vector(nbit_data-1 downto 0) |             |
| OUT1         | out       | std_logic_vector(nbit_data-1 downto 0) |             |
| OUT2         | out       | std_logic_vector(nbit_data-1 downto 0) |             |
| CALL         | in        | std_logic                              |             |
| RET          | in        | std_logic                              |             |
| SPILL        | out       | std_logic                              |             |
| FILL         | out       | std_logic                              |             |
| ADD_to_STACK | out       | PHYSICAL_ADDR                          |             |

## Signals

| Name             | Type                   | Description |
| ---------------- | ---------------------- | ----------- |
| CWP              | integer range 0 to F-1 |             |
| SWP              | integer range 0 to F-1 |             |
| used_windows     | integer range 0 to F   |             |
| stack_counter    | integer range 0 to 2*N |             |
| local_ADD_WR     | PHYSICAL_ADDR          |             |
| local_ADD_RD1    | PHYSICAL_ADDR          |             |
| local_ADD_RD2    | PHYSICAL_ADDR          |             |
| local_ADDR_Stack | PHYSICAL_ADDR          |             |
| CANSAVE          | std_logic              |             |
| CANRESTORE       | std_logic              |             |

## Processes
- POINTER_UPDATE: ( CLK )

## Instantiations

- RF_inst: registerfile
