module traffic #(
    parameter CLK_HZ          = 50_000_000,
    parameter DEBOUNCE_CYCLES = CLK_HZ / 50
)(
    input  wire       CLOCK_50, KEY0, KEY1,
    input  wire [9:0] SW,
    output wire [9:0] LEDR,
    output wire [6:0] HEX0, HEX1, HEX2, HEX3
);

    reg [1:0] reset_sync = 2'b11;

    always @(posedge CLOCK_50 or negedge KEY0) begin
        if (!KEY0) reset_sync <= 2'b11;
        else       reset_sync <= {reset_sync[0], 1'b0};
    end

    wire reset = reset_sync[1];

    wire       custom_mode, restart, invalid_entry, saved_toggle, button_down;
    wire [4:0] green_setting, flash_setting, yellow_setting;
    wire [4:0] green_seconds  = custom_mode ? green_setting  : 5'd10;
    wire [4:0] flash_seconds  = custom_mode ? flash_setting  : 5'd6;
    wire [4:0] yellow_seconds = custom_mode ? yellow_setting : 5'd3;

    time_config #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) u_config (
        .clk           (CLOCK_50),
        .reset         (reset),
        .key1_n        (KEY1),
        .switches      (SW),
        .custom_mode   (custom_mode),
        .green_seconds (green_setting),
        .flash_seconds (flash_setting),
        .yellow_seconds(yellow_setting),
        .restart       (restart),
        .invalid_entry (invalid_entry),
        .saved_toggle  (saved_toggle),
        .button_down   (button_down)
    );

    // Emergency switches, 2-FF synchronizer
    // {SW6,SW5}: 01 road 1 green, 10 road 2 green, 11 all red
    reg [1:0] emergency_meta, emergency_sync;
    reg       emergency_previous;
    wire      emergency_active = !reset && (|emergency_sync);

    always @(posedge CLOCK_50 or posedge reset) begin
        if (reset) begin
            emergency_meta     <= 0;
            emergency_sync     <= 0;
            emergency_previous <= 0;
        end else begin
            emergency_meta     <= SW[6:5];
            emergency_sync     <= emergency_meta;
            emergency_previous <= emergency_active;
        end
    end

    // Hold FSM and timer at start during emergency, plus one cycle after exit
    wire controller_restart = restart || emergency_active || emergency_previous;

    wire [2:0] state;
    reg  [4:0] phase_seconds;

    always @(*) begin
        case (state)
            3'd0, 3'd4:             phase_seconds = green_seconds;
            3'd1, 3'd2, 3'd5, 3'd6: phase_seconds = flash_seconds;
            default:                phase_seconds = yellow_seconds;
        endcase
    end

    wire       tick_half, tick_phase;
    wire [4:0] elapsed;
    wire [5:0] lights, remaining;
    wire [6:0] seg0, seg1, seg2, seg3;

    traffic_timer #(.CLK_HZ(CLK_HZ)) u_timer (
        .clk          (CLOCK_50),
        .reset        (reset),
        .restart      (controller_restart),
        .phase_seconds(phase_seconds),
        .tick_half    (tick_half),
        .tick_phase   (tick_phase),
        .elapsed      (elapsed)
    );

    traffic_fsm u_fsm (
        .clk       (CLOCK_50),
        .reset     (reset),
        .restart   (controller_restart),
        .tick_half (tick_half),
        .tick_phase(tick_phase),
        .lights    (lights),
        .state     (state)
    );

    countdown u_countdown (
        .elapsed      (elapsed),
        .phase_seconds(phase_seconds),
        .countdown    (remaining)
    );

    countdown_display u_display (
        .countdown(remaining),
        .hex0     (seg0),
        .hex1     (seg1),
        .hex2     (seg2),
        .hex3     (seg3)
    );

    // LEDR9 save toggle, LEDR8 custom mode, LEDR7 KEY1 pressed, LEDR6 invalid input
    // LEDR[5:0] = {G1,Y1,R1,G2,Y2,R2}, active high
    reg [5:0] board_lights;

    always @(*) begin
        board_lights = lights;
        if (emergency_active) begin
            case (emergency_sync)
                2'b01:   board_lights = 6'b100001;
                2'b10:   board_lights = 6'b001100;
                default: board_lights = 6'b001001;
            endcase
        end
    end

    assign LEDR = {saved_toggle, custom_mode, button_down, invalid_entry, board_lights};

    function [6:0] to_de1_hex;
        input [6:0] seg;
        begin
            to_de1_hex = ~{seg[0], seg[1], seg[2], seg[3], seg[4], seg[5], seg[6]};
        end
    endfunction

    assign HEX0 = emergency_active ? 7'b0111111 : to_de1_hex(seg0);
    assign HEX1 = emergency_active ? 7'b0111111 : to_de1_hex(seg1);
    assign HEX2 = emergency_active ? 7'b0111111 : to_de1_hex(seg2);
    assign HEX3 = emergency_active ? 7'b0111111 : to_de1_hex(seg3);

endmodule
