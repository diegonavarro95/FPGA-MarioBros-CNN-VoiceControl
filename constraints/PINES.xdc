## Reloj Maestro de la Placa (100 MHz)
## Pin R4 es una entrada MRCC en el banco 34[cite: 486].
set_property PACKAGE_PIN R4 [get_ports clk100MHz]
set_property IOSTANDARD LVCMOS33 [get_ports clk100MHz]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk100MHz]

## Salida HDMI (Conector J8 - Source) [cite: 896, 905]
set_property PACKAGE_PIN T1 [get_ports hdmi_out_clk_p]
set_property PACKAGE_PIN U1 [get_ports hdmi_out_clk_n]
set_property PACKAGE_PIN W1 [get_ports {hdmi_out_data_p[0]}]
set_property PACKAGE_PIN Y1 [get_ports {hdmi_out_data_n[0]}]
set_property PACKAGE_PIN AA1 [get_ports {hdmi_out_data_p[1]}]
set_property PACKAGE_PIN AB1 [get_ports {hdmi_out_data_n[1]}]
set_property PACKAGE_PIN AB3 [get_ports {hdmi_out_data_p[2]}]
set_property PACKAGE_PIN AB2 [get_ports {hdmi_out_data_n[2]}]
set_property PACKAGE_PIN R3 [get_ports hdmi_txen]

set_property IOSTANDARD TMDS_33 [get_ports hdmi_out_clk_p]
set_property IOSTANDARD TMDS_33 [get_ports hdmi_out_clk_n]
set_property IOSTANDARD TMDS_33 [get_ports hdmi_out_data_p*]
set_property IOSTANDARD TMDS_33 [get_ports hdmi_out_data_n*]
set_property IOSTANDARD LVCMOS33 [get_ports hdmi_txen]

## Audio Codec (ADAU1761) [cite: 1040, 1093, 1101]
## MCLK: Reloj maestro para que el chip funcione[cite: 1081, 1101].
set_property PACKAGE_PIN U6 [get_ports audio_mclk]
set_property IOSTANDARD LVCMOS33 [get_ports audio_mclk]

## I2C para Configuración (SDA/SCL) [cite: 1082, 1083, 1101]
set_property PACKAGE_PIN V5 [get_ports audio_sda]
set_property PACKAGE_PIN W5 [get_ports audio_scl]
set_property IOSTANDARD LVCMOS33 [get_ports audio_sda]
set_property IOSTANDARD LVCMOS33 [get_ports audio_scl]

## Interfaz de Datos I2S [cite: 1101]
set_property PACKAGE_PIN T5 [get_ports audio_bclk]
set_property PACKAGE_PIN U5 [get_ports audio_lrclk]
set_property PACKAGE_PIN W6 [get_ports audio_dac_sdata]
set_property PACKAGE_PIN T4 [get_ports audio_adc_sdata]
set_property IOSTANDARD LVCMOS33 [get_ports audio_bclk]
set_property IOSTANDARD LVCMOS33 [get_ports audio_lrclk]
set_property IOSTANDARD LVCMOS33 [get_ports audio_dac_sdata]
set_property IOSTANDARD LVCMOS33 [get_ports audio_adc_sdata]

## Botones y LEDs de Debug
## CPU Reset (G4) es activo bajo[cite: 786, 790, 1264].
set_property PACKAGE_PIN G4 [get_ports cpu_resetn]
set_property IOSTANDARD LVCMOS15 [get_ports cpu_resetn]

## LED 0 para verificar el "Locked" del PLL[cite: 768, 1264].
set_property PACKAGE_PIN T14 [get_ports {led_debug[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {led_debug[0]}]

## Configuración de Voltaje de la Placa
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]