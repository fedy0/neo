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

  signal xbridge: std_ulogic_vector(3 downto 0);
  signal sbridge: std_ulogic_vector(3 downto 0);
  signal spi_csn: std_ulogic_vector(7 downto 0);

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
    XIP_CACHE_EN      => true,      -- implements XIP cache
    
    IO_SPI_EN         => true,      -- implement serial peripheral interface (SPI)?
    IO_SPI_FIFO       => 2**15
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
    xip_csn_o  => xbridge(0), -- chip-select, low-active
    xip_clk_o  => xbridge(1), -- serial clock
    xip_dat_i  => xbridge(2), -- device data input
    xip_dat_o  => xbridge(3), -- controller data output
    
    spi_csn_o  => spi_csn, -- SPI CS
    spi_clk_o  => sbridge(1), -- SPI serial clock
    spi_dat_i  => sbridge(2), -- controller data in, peripheral data out
    spi_dat_o  => sbridge(3)  -- controller data out, peripheral data in
  );

  -- IO Connection --------------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  ULX3S_LED0 <= con_gpio_o(0);
  ULX3S_LED1 <= con_gpio_o(1);
  ULX3S_LED2 <= con_gpio_o(2);
  ULX3S_LED3 <= con_gpio_o(3);
  
  flash_csn  <= spi_csn(0) and xbridge(0);
  flash_clk  <= sbridge(1) when (spi_csn(0) = '0') else xbridge(1);
  flash_mosi <= sbridge(3)  when (spi_csn(0) = '0') else xbridge(3);
  xbridge(2) <= flash_miso;
  sbridge(2) <= flash_miso;

end architecture;
