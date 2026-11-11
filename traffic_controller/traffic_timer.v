// Timer: tick_half every 0.5 s, tick_phase when the phase time is up
module traffic_timer #(parameter CLK_HZ = 50_000_000) (
    input  wire       clk, reset, restart,
    input  wire [4:0] phase_seconds,
    output wire       tick_half, tick_phase,
    output wire [4:0] elapsed
);

    localparam HALF_COUNT = CLK_HZ / 2;
    // Counter width
    localparam W = (HALF_COUNT <= 1) ? 1 : $clog2(HALF_COUNT);

    reg [W-1:0] count;
    reg [5:0]   half_elapsed;

    assign elapsed    = half_elapsed[5:1];
    assign tick_half  = !reset && !restart && (count == HALF_COUNT-1);
    assign tick_phase = tick_half && (half_elapsed == {phase_seconds, 1'b0} - 6'd1);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count        <= 0;
            half_elapsed <= 0;
        end
        else if (restart) begin
            count        <= 0;
            half_elapsed <= 0;
        end
        else if (tick_half) begin
            count <= 0;
            if (tick_phase) half_elapsed <= 0;
            else            half_elapsed <= half_elapsed + 1'b1;
        end
        else
            count <= count + 1'b1;
    end

endmodule
