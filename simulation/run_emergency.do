# Emergency override waveform for the report
onerror {abort}
catch {quit -sim}
vlib work
vlog ../traffic_controller/traffic.v ../traffic_controller/time_config.v ../traffic_controller/traffic_timer.v ../traffic_controller/traffic_fsm.v ../traffic_controller/countdown.v ../traffic_controller/countdown_display.v ../traffic_controller/seven_seg_decoder.v traffic_emergency_tb.v
vsim work.traffic_emergency_tb
add wave -label SW5_Road1 {sim:/traffic_emergency_tb/sw[5]}
add wave -label SW6_Road2 {sim:/traffic_emergency_tb/sw[6]}
add wave sim:/traffic_emergency_tb/dut/emergency_active
add wave -radix binary sim:/traffic_emergency_tb/dut/board_lights
add wave -label G1 {sim:/traffic_emergency_tb/dut/board_lights[5]}
add wave -label Y1 {sim:/traffic_emergency_tb/dut/board_lights[4]}
add wave -label R1 {sim:/traffic_emergency_tb/dut/board_lights[3]}
add wave -label G2 {sim:/traffic_emergency_tb/dut/board_lights[2]}
add wave -label Y2 {sim:/traffic_emergency_tb/dut/board_lights[1]}
add wave -label R2 {sim:/traffic_emergency_tb/dut/board_lights[0]}
add wave -radix unsigned sim:/traffic_emergency_tb/dut/remaining
add wave -radix binary sim:/traffic_emergency_tb/h0
run 70 us
configure wave -timelineunits us
wave zoom range 19us 32us
