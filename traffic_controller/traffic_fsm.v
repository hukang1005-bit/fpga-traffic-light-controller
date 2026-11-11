module traffic_fsm (
    input  wire       clk,
    input  wire       reset,

    // 1-cycle pulses from traffic_timer
    input  wire       tick_half,
    input  wire       tick_phase,
    input  wire       restart,

    // {G1,Y1,R1,G2,Y2,R2}, 1 = on
    output reg [5:0]  lights,

    // Current state, top level uses it to pick the phase time
    output reg [2:0]  state
);

    // State codes

    localparam [2:0]
        S1_GREEN     = 3'b000,
        S1_FLASH_ON  = 3'b001,
        S1_FLASH_OFF = 3'b010,
        S1_YELLOW    = 3'b011,
        S2_GREEN     = 3'b100,
        S2_FLASH_ON  = 3'b101,
        S2_FLASH_OFF = 3'b110,
        S2_YELLOW    = 3'b111;

    reg [2:0] next_state;

    // State register

    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= S1_GREEN;
        else if (restart)
            state <= S1_GREEN;
        else
            state <= next_state;
    end

    // Next state logic

    always @(*) begin
        // Stay by default
        next_state = state;

        case (state)

            // Road 1 green
            S1_GREEN: begin
                if (tick_phase)
                    next_state = S1_FLASH_ON;
            end

            // Road 1 flashing, light on
            S1_FLASH_ON: begin
                // tick_phase wins over tick_half
                if (tick_phase)
                    next_state = S1_YELLOW;
                else if (tick_half)
                    next_state = S1_FLASH_OFF;
            end

            // Road 1 flashing, light off
            S1_FLASH_OFF: begin
                if (tick_phase)
                    next_state = S1_YELLOW;
                else if (tick_half)
                    next_state = S1_FLASH_ON;
            end

            // Road 1 yellow
            S1_YELLOW: begin
                if (tick_phase)
                    next_state = S2_GREEN;
            end

            // Road 2 green
            S2_GREEN: begin
                if (tick_phase)
                    next_state = S2_FLASH_ON;
            end

            // Road 2 flashing, light on
            S2_FLASH_ON: begin
                if (tick_phase)
                    next_state = S2_YELLOW;
                else if (tick_half)
                    next_state = S2_FLASH_OFF;
            end

            // Road 2 flashing, light off
            S2_FLASH_OFF: begin
                if (tick_phase)
                    next_state = S2_YELLOW;
                else if (tick_half)
                    next_state = S2_FLASH_ON;
            end

            // Road 2 yellow
            S2_YELLOW: begin
                if (tick_phase)
                    next_state = S1_GREEN;
            end

            // Illegal state, go back to S1_GREEN
            default: begin
                next_state = S1_GREEN;
            end

        endcase
    end

    // Moore outputs

    always @(*) begin
        case (state)
            S1_GREEN:     lights = 6'b100001;
            S1_FLASH_ON:  lights = 6'b100001;
            S1_FLASH_OFF: lights = 6'b000001;
            S1_YELLOW:    lights = 6'b010001;

            S2_GREEN:     lights = 6'b001100;
            S2_FLASH_ON:  lights = 6'b001100;
            S2_FLASH_OFF: lights = 6'b001000;
            S2_YELLOW:    lights = 6'b001010;

            // Illegal state, same as S1_GREEN
            default:      lights = 6'b100001;
        endcase
    end

endmodule