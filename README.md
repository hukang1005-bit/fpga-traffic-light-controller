# FPGA Traffic Light Controller

A two-road traffic light controller written in Verilog for the Altera DE1 (Cyclone II EP2C20F484C7). This project was developed for EEE339 Digital System Design with HDL and includes configurable phase timing, emergency overrides, and self-checking simulations.

## Design

The controller uses a Moore finite-state machine and a separate timer, driven from the board's 50 MHz clock. In the default cycle, each road receives 10 seconds of steady green, 6 seconds of flashing green (0.5 seconds on, 0.5 seconds off), and 3 seconds of yellow while the other road remains red. The cycle then repeats for the other road. A four-digit seven-segment display shows the seconds remaining in the current phase.

```text
Switches / buttons --> configuration and synchronizers --+
                                                        |
50 MHz clock -------> timer --> traffic FSM ------------+--> LEDs
                         |        |                      |
                         +--> countdown --> display -----+--> HEX displays
Emergency switches ------------------> output override --+
```

Features include debounced configuration input, independently configurable phase durations from 1 to 31 seconds, invalid-entry rejection, and an emergency override for either road or all-red. Leaving emergency mode restarts the normal cycle.

## Simulate

Install Icarus Verilog (`iverilog` and `vvp`), then run:

```sh
./simulation/run_tests.sh
```

The four self-checking testbenches cover complete cycles, timing configuration, invalid entries, reset, displays, and emergency behavior. The script reports failure if a test reports a failed check or does not reach its pass message. ModelSim `.do` files are also included for waveform inspection; run them from the `simulation` directory.

## FPGA project

Open `traffic_controller/traffic.qpf` in Quartus II 13.0 SP1, compile the project, and program the DE1 board. The project includes the board pin assignments and clock constraint. `KEY0` resets the controller; `SW7` selects custom timings; `SW[9:8]` selects the phase and `SW[4:0]` the value to save with `KEY1`. `SW[6:5]` selects emergency priority (01: road 1, 10: road 2, 11: all red). The LEDs show the traffic lights and configuration status.

## Repository layout

- `traffic_controller/`: Verilog modules and Quartus project and timing constraints.
- `simulation/`: testbenches, ModelSim wave scripts, and the Icarus test runner.
