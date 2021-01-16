-- Top level file for Kee Games Ultra Tank
-- (c) 2017 James Sweet
--
-- This is free software: you can redistribute
-- it and/or modify it under the terms of the GNU General
-- Public License as published by the Free Software
-- Foundation, either version 3 of the License, or (at your
-- option) any later version.
--
-- This is distributed in the hope that it will
-- be useful, but WITHOUT ANY WARRANTY; without even the
-- implied warranty of MERCHANTABILITY or FITNESS FOR A
-- PARTICULAR PURPOSE. See the GNU General Public License
-- for more details.

-- Targeted to EP2C5T144C8 mini board but porting to nearly any FPGA should be fairly simple
-- See Ultra Tank manual for video output details. Resistor values listed here have been scaled 
-- for 3.3V logic. 


library IEEE;
use IEEE.STD_LOGIC_1164.all;


entity ultra_tank is 
port(		
		Clk_50_I		: in	std_logic;	-- 50MHz input clock
		Reset_n		: in	std_logic;	-- Reset button (Active low)

		Video1_O		: out std_logic;  -- White video output (680 Ohm)
		Video2_O		: out std_logic;  -- Black video output (1.2k)
			White_O		: out std_logic; 
		Sync_O		: out std_logic;  -- Composite sync output (1.2k)
			Blank_O		: out std_logic;  -- Composite blank output
			CC3_n_O		: out std_logic;  -- Not sure what these are, color monitor? (not connected in real game)
		CC2_O			: out std_logic;
		CC1_O			: out std_logic;
		CC0_O			: out std_logic;
		Audio1_O			: out std_logic_vector(6 downto 0);
		Audio2_O			: out std_logic_vector(6 downto 0);

		Coin1_I		: in  std_logic;  -- Coin switches (Active low)
		Coin2_I		: in  std_logic;
		Start1_I		: in  std_logic;  -- Start buttons
		Start2_I		: in  std_logic;
		Invisible_I	: in	std_logic;	-- Invisible tanks switch
		Rebound_I	: in	std_logic;	-- Rebounding shells switch
		Barrier_I	: in  std_logic;	-- Barriers switch

		JoyW_Fw_I	: in	std_logic;	-- Joysticks, these are all active low
		JoyW_Bk_I	: in	std_logic;
		JoyY_Fw_I	: in  std_logic;
		JoyY_Bk_I	: in	std_logic;
		JoyX_Fw_I	: in	std_logic;
		JoyX_Bk_I	: in	std_logic;
		JoyZ_Fw_I	: in	std_logic;
		JoyZ_Bk_I	: in	std_logic;
		FireA_I		: in  std_logic; 	-- Fire buttons
		FireB_I		: in  std_logic;

		Test_I		: in  std_logic;  -- Self-test switch
		Slam_I		: in  std_logic;  -- Slam switch
		LED1_O		: out std_logic;	-- Player 1 and 2 start button LEDs
		LED2_O		: out std_logic;
			Lockout_O	: out std_logic;   -- Coin mech lockout coil

		SW1			: in std_logic_vector(7 downto 0);

		hs_O			: out std_logic;
		vs_O			: out std_logic;
		hblank_O		: out std_logic;
		vblank_O		: out std_logic;
			
		clk_12		: in std_logic;
		clk_6_O		: out std_logic;

		-- signals that carry the ROM data from the MiSTer disk
		dn_addr        : in  std_logic_vector(15 downto 0);
		dn_data        : in  std_logic_vector(7 downto 0);
		dn_wr          : in  std_logic
			
			);
end ultra_tank;

architecture rtl of ultra_tank is

--signal Clk_12				: std_logic;
signal Clk_6				: std_logic;
signal Phi1 				: std_logic;
signal Phi2					: std_logic;

signal Hcount		   	: std_logic_vector(8 downto 0);
signal Vcount  			: std_logic_vector(7 downto 0) := (others => '0');
signal H256_s				: std_logic;
signal Hsync				: std_logic;
signal Vsync				: std_logic;
signal Vblank				: std_logic;
signal Vblank_n_s			: std_logic;
signal HBlank				: std_logic;
signal CompBlank_s		: std_logic;
signal CompSync_n_s		: std_logic;

signal DMA					: std_logic_vector(7 downto 0);
signal DMA_n				: std_logic_vector(7 downto 0);
signal PRAM					: std_logic_vector(7 downto 0);
signal Load_n				: std_logic_vector(8 downto 1);
signal Object				: std_logic_vector(4 downto 1);
signal Object_n			: std_logic_vector(4 downto 1);
signal Playfield_n		: std_logic;

signal CPU_Din				: std_logic_vector(7 downto 0);
signal CPU_Dout			: std_logic_vector(7 downto 0);
signal DBus_n				: std_logic_vector(7 downto 0);
signal BA					: std_logic_vector(15 downto 0);

signal Barrier_Read_n	: std_logic;
signal Throttle_Read_n	: std_logic;
signal Coin_Read_n		: std_logic;
signal Collision_Read_n	: std_logic;
signal Collision_n		: std_logic;
signal CollisionReset_n	: std_logic_vector(4 downto 1);
signal Options_Read_n	: std_logic;
signal Wr_DA_Latch_n 	: std_logic;
signal Wr_Explosion_n	: std_logic;
signal Fire1				: std_logic;
signal Fire2				: std_logic;
signal Attract				: std_logic;
signal Attract_n			: std_logic;	

-- logic to load roms from disk
signal rom1_cs   			: std_logic;
signal rom2_cs   			: std_logic;
signal rom3_cs   			: std_logic;
signal rom4_cs   			: std_logic;
signal rom_mot_n6_cs      	: std_logic;
signal rom_mot_m6_cs   	    : std_logic;
signal rom_mot_l6_cs   	    : std_logic;
signal rom_mot_k6_cs   	    : std_logic;
signal rom_sync_prom_cs     : std_logic;
signal rom_LSB_cs   		: std_logic;
signal rom_MSB_cs   		: std_logic;
signal rom_32_cs   		    : std_logic;


begin
-- Configuration DIP switches, these can be brought out to external switches if desired
-- See Ultra Tank manual page 6 for complete information. Active low (0 = On, 1 = Off)
--    1 	2							Extended Play		(11 - 75pts, 01 - 50pts, 10 - 25pts, 00 - None)
--   			3	4					Game Length			(11 - 60sec, 10 - 90sec, 01 - 120sec, 00 - 150sec) 
--						5	6			Game Cost   		(10 - 1 Coin, 1 Play, 01 - 2 Plays, 1 Coin, 11 - 2 Coins, 1 Play)
--								7	8	Unused?
--SW1 <= "10010100"; -- Config dip switches
--                                      13 11 9 8
-- 2048		030180.n1	 cpu             00 000 0 0000 0000 0x0000
-- 2048		030181.k1	 cpu             00 100 0 0000 0000 0x0800
-- 2048		030182.m1	 cpu             01 000 0 0000 0000 0x1000
-- 2048		030183.l1	 cpu             01 100 0 0000 0000 0x1800
-- 1024 	30174-01.n6	 motion          10 000 0 0000 0000 0x2000
-- 1024 	30175-01.m6	 motion          10 010 0 0000 0000 0x2400
-- 1024 	30176-01.l6	 motion          10 100 0 0000 0000 0x2800
-- 1024 	30177-01.k6  motion          10 110 0 0000 0000 0x2C00
--  512		30024-01.p8  synchro         11 000 0 0000 0000 0x3000
--  512		30172-01.j6  playfield  LSB  11 001 0 0000 0000 0x3200
--  512		30173-01.h6  playfield  MSB  11 010 0 0000 0000 0x3400
--   32     30218-01.j10 playfield  32   11 011 0 0000 0000 0x3600

--cpu 2k roms
rom1_cs <= '1' when dn_addr(13 downto 11) = "000"     else '0';
rom2_cs <= '1' when dn_addr(13 downto 11) = "001"     else '0';
rom3_cs <= '1' when dn_addr(13 downto 11) = "010"     else '0';
rom4_cs <= '1' when dn_addr(13 downto 11) = "011"     else '0';
--motion 1k roms
rom_mot_n6_cs <= '1' when dn_addr(13 downto 10) =  "1000"   else '0';
rom_mot_m6_cs <= '1' when dn_addr(13 downto 10) =  "1001"   else '0';
rom_mot_l6_cs <= '1' when dn_addr(13 downto 10) =  "1010"   else '0';
rom_mot_k6_cs <= '1' when dn_addr(13 downto 10) =  "1011"   else '0';
--syncro 512b
rom_sync_prom_cs <= '1' when dn_addr(13 downto 9) =  "11000"   else '0';
--playfield 512b roms + 32b rom
rom_LSB_cs <= '1' when dn_addr(13 downto 9) =  "11001"   else '0';
rom_MSB_cs <= '1' when dn_addr(13 downto 9) =  "11010"   else '0';
rom_32_cs  <= '1' when dn_addr(13 downto 8) =  "110110"   else '0';

-- PLL to generate 12.096 MHz clock
--PLL: entity work.clk_pll
--port map(
--		inclk0 => Clk_50_I,
--		c0 => clk_12
--		);
		
		
Vid_sync: entity work.synchronizer
port map(
		Clk_12 => Clk_12,
		Clk_6 => Clk_6,
		HCount => HCount,
		VCount => VCount,
		HSync => HSync,
		HBlank => HBlank,
		VBlank_n_s => VBlank_n_s,
		VBlank => VBlank,
		VSync => VSync,
		
		dn_wr => dn_wr,
		dn_addr=>dn_addr,
		dn_data=>dn_data,
		
		rom_sync_prom_cs=>rom_sync_prom_cs
		
		);


Background: entity work.playfield
port map( 
		Clk6 => Clk_6,
		clk12 => clk_12,
		DMA => DMA,
		PRAM => PRAM,
		Load_n => Load_n,
		Object => Object,
		HCount => HCount,
		VCount => VCount,
		HBlank => HBlank,
		VBlank => VBlank,
		VBlank_n_s => VBlank_n_s,
		HSync => Hsync,
		VSync => VSync,
		H256_s => H256_s,
		Playfield_n => Playfield_n,
		CC3_n => CC3_n_O,
		CC2 => CC2_O,
		CC1 => CC1_O,
		CC0 => CC0_O,
		White => White_O,
		PF_Vid1 => Video1_O,
		PF_Vid2 => Video2_O,

		dn_wr => dn_wr,
		dn_addr=>dn_addr,
		dn_data=>dn_data,
		
		rom_LSB_cs=>rom_LSB_cs,
		rom_MSB_cs=>rom_MSB_cs,
		rom_32_cs=>rom_32_cs
		
		);
			
		
Tank_Shells: entity work.motion
port map(
		CLK6 => Clk_6,
		CLK12 => clk_12,		
		PHI2 => Phi2,
		DMA_n => DMA_n,
      PRAM => PRAM,
		H256_s => H256_s,
		VCount => VCount,
		HCount => HCount,
		Load_n => Load_n,
		Object => Object,
		Object_n => Object_n,

		dn_wr => dn_wr,
		dn_addr=>dn_addr,
		dn_data=>dn_data,
		
		rom_mot_n6_cs=>rom_mot_n6_cs,
		rom_mot_m6_cs=>rom_mot_m6_cs,
		rom_mot_l6_cs=>rom_mot_l6_cs,
		rom_mot_k6_cs=>rom_mot_k6_cs
		
		);
		
		
Tank_Shell_Comparator: entity work.collision_detect
port map(	
		Clk6 => Clk_6,
		Adr => BA(2 downto 0),
		Object_n	=> Object_n,
		Playfield_n => Playfield_n,
		CollisionReset_n => CollisionReset_n,
		Slam_n => Slam_I,
		Collision_n	=> Collision_n
		);
	
	
CPU: entity work.cpu_mem
port map(
		Clk12 => clk_12,
		Clk6 => clk_6,
		Reset_n => reset_n,
		VCount => VCount,
		HCount => HCount,
		Vblank_n_s => Vblank_n_s,
		Test_n => Test_I,
		Collision_n => Collision_n,
		DB_in => CPU_Din,
		DBus => CPU_Dout,
		DBus_n => DBus_n,
		PRAM => PRAM,
		ABus => BA,
		Attract => Attract,
		Attract_n => Attract_n,
		CollReset_n => CollisionReset_n,
		Barrier_Read_n => Barrier_Read_n,
		Throttle_Read_n => Throttle_Read_n,
		Coin_Read_n => Coin_Read_n,
		Options_Read_n => Options_Read_n,
		Wr_DA_Latch_n => Wr_DA_Latch_n,
		Wr_Explosion_n => Wr_Explosion_n,
		Fire1 => Fire1,
		Fire2 => Fire2,
		LED1 => LED1_O,
		LED2 => LED2_O,
		Lockout_n => Lockout_O,
		Phi1_o => Phi1,
		Phi2_o => Phi2,
		DMA => DMA,
		DMA_n => DMA_n,
		
		dn_wr => dn_wr,
		dn_addr=>dn_addr,
		dn_data=>dn_data,
		
		rom1_cs=>rom1_cs,
		rom2_cs=>rom2_cs,
		rom3_cs=>rom3_cs,
		rom4_cs=>rom4_cs

		);
		
		
Input: entity work.Control_Inputs
port map(
		Clk6 => Clk_6,
		DipSw => SW1, -- DIP switches
		Coin1_n => Coin1_I,
		Coin2_n => Coin2_I,
		Start1_n => Start1_I,
		Start2_n => Start2_I,
		Invisible_n => Invisible_I,
		Rebound_n => Rebound_I,
		Barrier_n => Barrier_I,
		JoyW_Fw => JoyW_Fw_I,
		JoyW_Bk => JoyW_Bk_I,
		JoyY_Fw => JoyY_Fw_I,
		JoyY_Bk => JoyY_Bk_I,
		JoyX_Fw => JoyX_Fw_I,
		JoyX_Bk => JoyX_Bk_I,
		JoyZ_Fw => JoyZ_Fw_I,
		JoyZ_Bk => JoyZ_Bk_I,
		FireA_n => FireA_I,
		FireB_n => FireB_I,
	   Throttle_Read_n => Throttle_Read_n,
		Coin_Read_n => Coin_Read_n,
		Options_Read_n => Options_Read_n,
		Barrier_Read_n => Barrier_Read_n,
		Wr_DA_Latch_n => Wr_DA_Latch_n,
		Adr => BA(2 downto 0),
		DBus => CPU_Dout(3 downto 0),
		Dout => CPU_Din
	);	

	
Sound: entity work.audio
port map( 
		Clk_50 => Clk_50_I,
		Clk_6 => Clk_6,
		Reset_n => Reset_n,
		Load_n => Load_n,
		Fire1 => Fire1,
		Fire2 => Fire2,
		Write_Explosion_n => Wr_Explosion_n,
		Attract => Attract,
		Attract_n => Attract_n,
		PRAM => PRAM,
		DBus_n => not CPU_Dout,
		HCount => HCount,
		VCount => VCount,
		Audio1 => Audio1_O,
		Audio2 => Audio2_O
		);

Sync_O <= HSync nor VSync;
Blank_O <= HBlank nor VBlank;
hblank_O <= HBlank;
vblank_O <= VBlank;
hs_O<= hsync;
vs_O <=vsync;
clk_6_O<=clk_6;



end rtl;