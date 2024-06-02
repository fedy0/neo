-- #################################################################################################
-- # << NEORV32 - Example setup including the bootloader, for the ULX3S (c) Board >>               #
-- # ********************************************************************************************* #
-- # BSD 3-Clause License                                                                          #
-- #                                                                                               #
-- # Copyright (c) 2023, Stephan Nolting. All rights reserved.                                     #
-- #                                                                                               #
-- # Redistribution and use in source and binary forms, with or without modification, are          #
-- # permitted provided that the following conditions are met:                                     #
-- #                                                                                               #
-- # 1. Redistributions of source code must retain the above copyright notice, this list of        #
-- #    conditions and the following disclaimer.                                                   #
-- #                                                                                               #
-- # 2. Redistributions in binary form must reproduce the above copyright notice, this list of     #
-- #    conditions and the following disclaimer in the documentation and/or other materials        #
-- #    provided with the distribution.                                                            #
-- #                                                                                               #
-- # 3. Neither the name of the copyright holder nor the names of its contributors may be used to  #
-- #    endorse or promote products derived from this software without specific prior written      #
-- #    permission.                                                                                #
-- #                                                                                               #
-- # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS   #
-- # OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF               #
-- # MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE    #
-- # COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,     #
-- # EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE #
-- # GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED    #
-- # AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING     #
-- # NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED  #
-- # OF THE POSSIBILITY OF SUCH DAMAGE.                                                            #
-- # ********************************************************************************************* #
-- # The NEORV32 Processor - https://github.com/stnolting/neorv32              (c) Stephan Nolting #
-- #################################################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library neorv32;
use neorv32.components.all; -- for device primitives and macros

entity neorv32_ULX3S_xip is
  port (
    -- Clock and Reset inputs
    ULX3S_CLK : in std_logic;
    ULX3S_RST_N : in std_logic;
    -- LED outputs
    ULX3S_LED0 : out std_logic;
    ULX3S_LED1 : out std_logic;
    ULX3S_LED2 : out std_logic;
    ULX3S_LED3 : out std_logic;
    -- UART0
    ULX3S_RX : in  std_logic;
    ULX3S_TX : out std_logic;
    -- XIP Flash
    flash_csn : out std_logic;
    --sflash_clk : out std_logic;
    flash_mosi: out std_logic;
    flash_miso: in std_logic
  );
end entity;

architecture neorv32_ULX3S_xip_rtl of neorv32_ULX3S_xip is

    -- Component Declaration for USRMCLK
    component USRMCLK is
      port (
        USRMCLKI  : in  std_logic;
        USRMCLKTS : in  std_logic
      );
    end component;

  -- configuration --
  constant f_clock_c : natural := 25000000; -- clock frequency in Hz

  -- internal IO connection --
  signal con_gpio_o : std_ulogic_vector(63 downto 0);
  signal spi_con : std_logic := '1';
  signal flash_clk : std_logic;

begin
  -- Component Instantiation of USRMCLK
  u1: USRMCLK
    port map (
      USRMCLKI  => flash_clk,
      USRMCLKTS => spi_con
    );
  -- The core of the problem ----------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  neorv32_inst: entity neorv32.neorv32_top
  generic map (
    CLOCK_FREQUENCY   => f_clock_c, -- clock frequency of clk_i in Hz
    INT_BOOTLOADER_EN => true,      -- boot configuration: true = boot explicit bootloader; false = boot from int/ext (I)MEM
    -- Internal Instruction memory --
    MEM_INT_IMEM_EN   => true,      -- implement processor-internal instruction memory
    MEM_INT_IMEM_SIZE => 16*1024,   -- size of processor-internal instruction memory in bytes
    -- Internal Data memory --
    MEM_INT_DMEM_EN   => true,      -- implement processor-internal data memory
    MEM_INT_DMEM_SIZE => 8*1024,    -- size of processor-internal data memory in bytes
    -- Processor peripherals --
    IO_GPIO_NUM       => 4,         -- number of GPIO input/output pairs (0..64)
    IO_MTIME_EN       => true,      -- implement machine system timer (MTIME)?
    IO_UART0_EN       => true,      -- implement primary universal asynchronous receiver/transmitter (UART0)?
    
    XIP_EN            => true,      -- implements execute in place module (XIP)
    XIP_CACHE_EN      => true       -- implements XIP cache
  )
  port map (
    -- Global control --
    clk_i      => std_ulogic(ULX3S_CLK),
    rstn_i     => std_ulogic(ULX3S_RST_N),
	
    -- GPIO --
    gpio_o     => con_gpio_o,

    -- primary UART --
    uart0_txd_o => ULX3S_TX, -- UART0 send data
    uart0_rxd_i => ULX3S_RX, -- UART0 receive data

    -- XIP (execute in place via SPI) signals (available if XIP_EN = true) --
    xip_csn_o  => flash_csn,  -- chip-select, low-active
    xip_clk_o  => flash_clk,  -- serial clock
    xip_dat_i  => flash_miso, -- device data input
    xip_dat_o  => flash_mosi  -- controller data output

  );

  -- IO Connection --------------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  ULX3S_LED0 <= con_gpio_o(0);
  ULX3S_LED1 <= con_gpio_o(1);
  ULX3S_LED2 <= con_gpio_o(2);
  ULX3S_LED3 <= con_gpio_o(3);

  --spi_con <= std_ulogic(1);

end architecture;
