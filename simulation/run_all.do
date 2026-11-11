onerror {quit -code 1 -f}
vlib work
vlog ../traffic_controller/traffic.v ../traffic_controller/time_config.v ../traffic_controller/traffic_timer.v ../traffic_controller/traffic_fsm.v ../traffic_controller/countdown.v ../traffic_controller/countdown_display.v ../traffic_controller/seven_seg_decoder.v traffic_tb.v
vsim work.traffic_tb
add wave -r sim:/traffic_tb/*
run -all