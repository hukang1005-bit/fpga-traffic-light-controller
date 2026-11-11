// Time settings: sync switches, debounce KEY1 (active low, 20 ms at 50 MHz)
module time_config #(parameter DEBOUNCE_CYCLES = 1_000_000) (
    input  wire       clk, reset, key1_n,
    input  wire [9:0] switches,
    output reg        custom_mode,
    output reg  [4:0] green_seconds, flash_seconds, yellow_seconds,
    output reg        restart, invalid_entry, saved_toggle,
    output wire       button_down
);

    localparam W = (DEBOUNCE_CYCLES <= 1) ? 1 : $clog2(DEBOUNCE_CYCLES);

    reg [W-1:0] count;
    reg         key_meta, key_sync, key_stable;
    reg [9:0]   sw_meta, sw_sync;

    wire press = key_stable && !key_sync && (count == DEBOUNCE_CYCLES-1);
    assign button_down = !key_stable;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            key_meta   <= 1;
            key_sync   <= 1;
            key_stable <= 1;
            sw_meta    <= 0;
            sw_sync    <= 0;
            count      <= 0;
        end else begin
            key_meta <= key1_n;
            key_sync <= key_meta;
            sw_meta  <= switches;
            sw_sync  <= sw_meta;
            if (key_sync == key_stable)
                count <= 0;
            else if (count == DEBOUNCE_CYCLES-1) begin
                key_stable <= key_sync;
                count      <= 0;
            end
            else
                count <= count + 1'b1;
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            custom_mode    <= 0;
            green_seconds  <= 10;
            flash_seconds  <= 6;
            yellow_seconds <= 3;
            restart        <= 0;
            invalid_entry  <= 0;
            saved_toggle   <= 0;
        end else begin
            restart <= 0;
            if (sw_sync[7] != custom_mode) begin
                custom_mode   <= sw_sync[7];
                restart       <= 1;
                invalid_entry <= 0;
            end
            else if (press && custom_mode) begin
                if (sw_sync[9:8] == 2'b11 || sw_sync[4:0] == 0)
                    invalid_entry <= 1;
                else begin
                    case (sw_sync[9:8])
                        2'b00: green_seconds  <= sw_sync[4:0];
                        2'b01: flash_seconds  <= sw_sync[4:0];
                        2'b10: yellow_seconds <= sw_sync[4:0];
                    endcase
                    restart       <= 1;
                    invalid_entry <= 0;
                    saved_toggle  <= ~saved_toggle;
                end
            end
        end
    end

endmodule
