create_clock -name CLOCK_50 -period 20.000 [get_ports {CLOCK_50}]
derive_clock_uncertainty
# KEY0 is async, its release is synced by reset_sync
set_false_path -from [get_ports {KEY0}]

# KEY1 and SW go through 2-FF synchronizers
set_false_path -from [get_ports {KEY1 SW[*]}]
