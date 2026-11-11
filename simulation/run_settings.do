# Time setting waveform, fixed run time so no $finish pop-up
onerror {abort}
catch {quit -sim}
vlib work
vlog ../traffic_controller/traffic.v ../traffic_controller/time_config.v ../traffic_controller/traffic_timer.v ../traffic_controller/traffic_fsm.v ../traffic_controller/countdown.v ../traffic_controller/countdown_display.v ../traffic_controller/seven_seg_decoder.v traffic_settings_tb.v
vsim work.traffic_settings_tb
add wave sim:/traffic_settings_tb/key1
add wave -radix binary sim:/traffic_settings_tb/sw
add wave sim:/traffic_settings_tb/dut/custom_mode
add wave -radix unsigned sim:/traffic_settings_tb/dut/green_setting
add wave -radix unsigned sim:/traffic_settings_tb/dut/flash_setting
add wave -radix unsigned sim:/traffic_settings_tb/dut/yellow_setting
add wave sim:/traffic_settings_tb/dut/restart
add wave -radix unsigned sim:/traffic_settings_tb/dut/state
add wave -radix unsigned sim:/traffic_settings_tb/dut/remaining
add wave -radix binary sim:/traffic_settings_tb/dut/board_lights
run 35 us
configure wave -timelineunits us
wave zoom range 0us 3.5us
