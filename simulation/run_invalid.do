# Invalid input waveform: 0 s and type 11
onerror {abort}
catch {quit -sim}
vlib work
vlog ../traffic_controller/traffic.v ../traffic_controller/time_config.v ../traffic_controller/traffic_timer.v ../traffic_controller/traffic_fsm.v ../traffic_controller/countdown.v ../traffic_controller/countdown_display.v ../traffic_controller/seven_seg_decoder.v traffic_invalid_tb.v
vsim work.traffic_invalid_tb
add wave sim:/traffic_invalid_tb/dut/custom_mode
add wave sim:/traffic_invalid_tb/key1
add wave -radix binary sim:/traffic_invalid_tb/selected_type
add wave -radix unsigned sim:/traffic_invalid_tb/input_seconds
add wave -radix unsigned sim:/traffic_invalid_tb/dut/green_setting
add wave -radix unsigned sim:/traffic_invalid_tb/dut/flash_setting
add wave -radix unsigned sim:/traffic_invalid_tb/dut/yellow_setting
add wave sim:/traffic_invalid_tb/dut/invalid_entry
add wave sim:/traffic_invalid_tb/dut/restart
add wave sim:/traffic_invalid_tb/dut/saved_toggle
run 4 us
configure wave -timelineunits us
wave zoom range 0us 3.5us
