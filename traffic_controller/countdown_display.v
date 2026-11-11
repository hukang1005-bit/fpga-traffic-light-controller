// Countdown to four digits (00XX), segments active high {a,b,c,d,e,f,g}
module countdown_display (
    input  wire [5:0] countdown,
    output wire [6:0] hex3, hex2, hex1, hex0
);

    wire       valid      = (countdown <= 31);
    wire [5:0] tens_value = countdown / 6'd10;
    wire [5:0] ones_value = countdown % 6'd10;
    wire [3:0] tens       = tens_value[3:0];
    wire [3:0] ones       = ones_value[3:0];

    seven_seg_decoder d3 (.countdown(valid ? 4'd0 : 4'd10), .seg(hex3));
    seven_seg_decoder d2 (.countdown(valid ? 4'd0 : 4'd10), .seg(hex2));
    seven_seg_decoder d1 (.countdown(valid ? tens : 4'd10), .seg(hex1));
    seven_seg_decoder d0 (.countdown(valid ? ones : 4'd10), .seg(hex0));

endmodule
