`timescale 1ns/1ps
module traffic_emergency_tb;

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

    task select_emergency;
        input [1:0] request;
        begin
            @(negedge clk); sw[6:5] = request; cycles(5);
        end
    endtask

    task hold_emergency;
        input [5:0] expected;
        integer n;
        begin
            for (n = 0; n < 300; n = n + 1) begin
                check(leds[5:0] === expected, "emergency lights held");
                check(h0 == 7'b0111111 && h1 == 7'b0111111 && h2 == 7'b0111111 && h3 == 7'b0111111,
                      "four dashes");
                check(dut.u_timer.count == 0 && dut.u_timer.half_elapsed == 0, "timer held");
                cycles(1);
            end
        end
    endtask

    reg done = 0;

    initial begin
        reset_board;
        cycles(2000);
        check(leds[5:0] == 6'b001100, "normal Road 2 green before emergency");
        select_emergency(2'b01); hold_emergency(6'b100001);
        select_emergency(2'b10); hold_emergency(6'b001100);
        select_emergency(2'b11); hold_emergency(6'b001001);
        @(negedge clk); sw[6:5] = 0;
        wait (dut.emergency_active === 0); @(posedge clk); #1;
        check(dut.state == 0 && dut.remaining == 10 && dut.u_timer.count == 0,
              "exit restarts Road 1 at ten seconds");
        $display("EMERGENCY_EXIT_NS=%0t", $time);
        full_cycle(10, 6, 3);
        done = 1;
        if (errors == 0) $display("PASS: both emergency directions, stable outputs, conflict protection, dashes, exit and full recovered cycle");
        else             $display("FAILED: %0d checks", errors);
    end

endmodule
