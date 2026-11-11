`timescale 1ns/1ps
module traffic_tb;

    reg        clk = 0, key0 = 0, key1 = 1;
    reg  [9:0] sw = 0;
    wire [9:0] leds;
    wire [6:0] h0, h1, h2, h3;
    integer    errors = 0;

    traffic #(.CLK_HZ(100), .DEBOUNCE_CYCLES(4)) dut (
        .CLOCK_50(clk), .KEY0(key0), .KEY1(key1), .SW(sw), .LEDR(leds),
        .HEX0(h0), .HEX1(h1), .HEX2(h2), .HEX3(h3)
    );

    always #5 clk = ~clk;

    task cycles;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1) begin
                @(posedge clk); #1;
            end
        end
    endtask

    task check;
        input condition;
        input [511:0] message;
        begin
            if (condition !== 1'b1) begin
                $display("FAIL: %0s at %0t", message, $time);
                errors = errors + 1;
            end
        end
    endtask

    task reset_board;
        begin
            @(negedge clk); key0 = 0; key1 = 1; cycles(4);
            @(negedge clk); key0 = 1; wait (dut.reset === 0); #1;
        end
    endtask

    task phase;
        input integer code, duration;
        input flashing;
        integer half;
        reg [5:0] expected;
        begin
            for (half = 0; half < duration*2; half = half + 1) begin
                if (flashing) begin
                    check(dut.state == code + (half%2), "flash state starts ON");
                    if (code == 1) expected = (half%2) ? 6'b000001 : 6'b100001;
                    else           expected = (half%2) ? 6'b001000 : 6'b001100;
                end else begin
                    check(dut.state == code, "steady phase state");
                    case (code)
                        0: expected = 6'b100001;
                        3: expected = 6'b010001;
                        4: expected = 6'b001100;
                        7: expected = 6'b001010;
                    endcase
                end
                check(leds[5:0] === expected, "all six light outputs");
                check(dut.remaining == duration - half/2, "whole-second countdown");
                cycles(50);
            end
        end
    endtask

    task full_cycle;
        input integer g, f, y;
        begin
            phase(0, g, 0); phase(1, f, 1); phase(3, y, 0);
            phase(4, g, 0); phase(5, f, 1); phase(7, y, 0);
            check(dut.state == 0 && dut.remaining == g, "cycle returns to Road 1");
        end
    endtask

    task set_mode;
        input value;
        begin
            @(negedge clk); sw[7] = value;
            wait (dut.restart === 1); @(posedge clk); #1;
        end
    endtask

    task save;
        input [1:0] kind;
        input [4:0] value;
        begin
            @(negedge clk); key1 = 1; sw[9:8] = kind; sw[4:0] = value; cycles(8);
            @(negedge clk); key1 = 0;
            wait (dut.restart === 1); @(posedge clk); #1; key1 = 1;
            check(dut.state == 0 && dut.u_timer.half_elapsed == 0 && dut.u_timer.count == 0,
                  "save restarts FSM and timer");
        end
    endtask

    reg     old_toggle;
    integer reset_stage;
    integer emergency_stage, emergency_road;

    task enter_emergency;
        input [1:0] selection;
        begin
            @(negedge clk); sw[6:5] = selection; cycles(5);
        end
    endtask

    task leave_emergency;
        begin
            @(negedge clk); sw[6:5] = 0;
            wait (dut.emergency_active === 0);
            @(posedge clk); #1;
            check(dut.state == 0 && dut.u_timer.count == 0 && dut.u_timer.half_elapsed == 0,
                  "emergency exit restarts normal timing");
        end
    endtask

    task check_emergency;
        input [5:0] expected;
        integer hold_tick;
        begin
            for (hold_tick = 0; hold_tick < 1000; hold_tick = hold_tick + 1) begin
                check(leds[5:0] === expected, "emergency stable light outputs");
                check(h0 == 7'b0111111 && h1 == 7'b0111111 && h2 == 7'b0111111 && h3 == 7'b0111111,
                      "emergency displays dashes");
                check(dut.u_timer.count == 0 && dut.u_timer.half_elapsed == 0,
                      "normal timer held during emergency");
                cycles(1);
            end
        end
    endtask

    initial begin
        $dumpfile("traffic_tb.vcd"); $dumpvars(0, traffic_tb);
        reset_board;
        full_cycle(10, 6, 3); full_cycle(10, 6, 3);
        set_mode(1); check(leds[8], "custom mode LED");
        save(0, 31); check(dut.green_setting == 31, "save green 31");
        check(h1 == 7'b0110000 && h0 == 7'b1111001, "display 0031");
        full_cycle(31, 6, 3);
        save(1, 1); check(dut.flash_setting == 1, "save flash minimum"); full_cycle(31, 1, 3);
        save(2, 31); check(dut.yellow_setting == 31, "save yellow maximum");
        save(1, 31); full_cycle(31, 31, 31);
        save(0, 1); save(1, 1); save(2, 1); full_cycle(1, 1, 1);
        save(0, 8); cycles(8); @(negedge clk); key1 = 0;
        wait (dut.restart === 1); @(posedge clk); #1; old_toggle = dut.saved_toggle;
        sw[4:0] = 9; cycles(30);
        check(dut.saved_toggle === old_toggle && dut.green_setting == 8, "held key saves only once");
        key1 = 1; cycles(8);
        @(negedge clk); key1 = 0; cycles(1); @(negedge clk); key1 = 1; cycles(8);
        check(dut.saved_toggle === old_toggle, "short key bounce rejected");
        @(negedge clk); sw[9:8] = 0; sw[4:0] = 0; cycles(8); key1 = 0; cycles(10);
        check(dut.invalid_entry && dut.green_setting == 8 && dut.saved_toggle === old_toggle,
              "zero rejected");
        key1 = 1; cycles(8); sw[9:8] = 3; sw[4:0] = 12; cycles(8); key1 = 0; cycles(10);
        check(dut.invalid_entry && dut.green_setting == 8 && dut.saved_toggle === old_toggle,
              "reserved code rejected");
        key1 = 1; cycles(8);
        set_mode(0); full_cycle(10, 6, 3);
        sw[9:8] = 0; sw[4:0] = 12; cycles(8); key1 = 0; cycles(10); key1 = 1; cycles(8);
        check(dut.green_setting == 8, "basic mode ignores saves");
        set_mode(1); check(dut.remaining == 8, "custom settings survive mode changes");
        reset_board; cycles(5);
        check(dut.green_setting == 10 && dut.flash_setting == 6 && dut.yellow_setting == 3,
              "reset restores defaults");
        check(dut.state == 0 && leds[5:0] == 6'b100001, "reset lights");

        // Reset during flash, yellow and road 2 green
        sw = 0;
        for (reset_stage = 0; reset_stage < 5; reset_stage = reset_stage + 1) begin
            reset_board;
            case (reset_stage)
                0: cycles(1050);
                1: cycles(1650);
                2: cycles(1950);
                3: cycles(2950);
                4: cycles(3550);
            endcase
            reset_board;
            check(dut.state == 0 && dut.remaining == 10 && leds[5:0] == 6'b100001,
                  "reset from other phases");
        end

        // Emergency on each road, from every normal phase
        for (emergency_road = 1; emergency_road <= 2; emergency_road = emergency_road + 1) begin
            for (emergency_stage = 0; emergency_stage < 6; emergency_stage = emergency_stage + 1) begin
                reset_board;
                case (emergency_stage)
                    0: cycles(100);
                    1: cycles(1050);
                    2: cycles(1650);
                    3: cycles(1950);
                    4: cycles(2950);
                    5: cycles(3550);
                endcase
                enter_emergency(emergency_road);
                if (emergency_road == 1) check_emergency(6'b100001);
                else                     check_emergency(6'b001100);
                leave_emergency;
                check(dut.remaining == 10, "default countdown after emergency");
            end
        end
        enter_emergency(1); enter_emergency(3); check_emergency(6'b001001);
        enter_emergency(2); check_emergency(6'b001100);

        // Emergency switch is still on after reset
        reset_board; cycles(6); check(leds[5:0] == 6'b001100, "emergency reapplied after reset");
        leave_emergency; full_cycle(10, 6, 3);
        set_mode(1); save(0, 8); enter_emergency(2);
        save(1, 4); check(leds[5:0] == 6'b001100, "save cannot override emergency");
        check_emergency(6'b001100);
        set_mode(0); check_emergency(6'b001100);
        set_mode(1); check_emergency(6'b001100);
        leave_emergency; full_cycle(8, 4, 3);

        if (errors == 0) $display("PASS: full cycles, 1..31 timings, display, all lights, save, debounce, invalid inputs, modes, reset, emergency overrides, conflict, exit and custom settings");
        else             $display("FAILED: %0d checks", errors);
        $finish;
    end

    initial begin
        #5000000; $display("FAIL: timeout"); $finish;
    end

endmodule
