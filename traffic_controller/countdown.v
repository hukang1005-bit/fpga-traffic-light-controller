// Seconds left in the current phase
module countdown (
    input  wire [4:0] elapsed, phase_seconds,
    output wire [5:0] countdown
);

    assign countdown = (elapsed < phase_seconds) ? ({1'b0, phase_seconds} - {1'b0, elapsed})
                                                 : 6'd0;

endmodule
