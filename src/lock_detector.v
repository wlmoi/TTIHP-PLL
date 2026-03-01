`default_nettype none

module lock_detector #(
    parameter LOCK_THRESHOLD = 8'd16,
    parameter UNLOCK_THRESHOLD = 8'd4
)(
    input  wire clk,
    input  wire reset_n,
    input  wire up,
    input  wire down,
    input  wire ref_clk,
    input  wire fb_clk,
    output reg  lock,
    output reg  almost_lock
);

    reg [7:0] stable_count;
    reg [7:0] error_count;
    reg [3:0] phase_error;

    localparam UNLOCKED      = 2'b00;
    localparam ACQUIRING     = 2'b01;
    localparam ALMOST_LOCKED = 2'b10;
    localparam LOCKED        = 2'b11;

    reg [1:0] lock_state;

    reg up_d, down_d;
    wire up_edge, down_edge;

    assign up_edge = up && !up_d;
    assign down_edge = down && !down_d;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            up_d <= 1'b0;
            down_d <= 1'b0;
        end else begin
            up_d <= up;
            down_d <= down;
        end
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            phase_error <= 4'b0;
        end else begin
            if (up_edge || down_edge) begin
                if (phase_error < 4'd15)
                    phase_error <= phase_error + 1'b1;
            end else begin
                if (phase_error > 0)
                    phase_error <= phase_error - 1'b1;
            end
        end
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            lock_state <= UNLOCKED;
            stable_count <= 8'b0;
            error_count <= 8'b0;
            lock <= 1'b0;
            almost_lock <= 1'b0;
        end else begin
            case (lock_state)
                UNLOCKED: begin
                    lock <= 1'b0;
                    almost_lock <= 1'b0;
                    if (phase_error < 4'd2) begin
                        stable_count <= stable_count + 1'b1;
                        if (stable_count >= (LOCK_THRESHOLD >> 2)) begin
                            lock_state <= ACQUIRING;
                            stable_count <= 8'b0;
                        end
                    end else begin
                        stable_count <= 8'b0;
                    end
                end

                ACQUIRING: begin
                    almost_lock <= 1'b0;
                    if (phase_error < 4'd2) begin
                        stable_count <= stable_count + 1'b1;
                        error_count <= 8'b0;
                        if (stable_count >= (LOCK_THRESHOLD >> 1)) begin
                            lock_state <= ALMOST_LOCKED;
                            stable_count <= 8'b0;
                        end
                    end else begin
                        error_count <= error_count + 1'b1;
                        if (error_count >= UNLOCK_THRESHOLD) begin
                            lock_state <= UNLOCKED;
                            error_count <= 8'b0;
                            stable_count <= 8'b0;
                        end
                    end
                end

                ALMOST_LOCKED: begin
                    almost_lock <= 1'b1;
                    if (phase_error < 4'd1) begin
                        stable_count <= stable_count + 1'b1;
                        error_count <= 8'b0;
                        if (stable_count >= LOCK_THRESHOLD) begin
                            lock_state <= LOCKED;
                            stable_count <= 8'b0;
                        end
                    end else if (phase_error > 4'd3) begin
                        error_count <= error_count + 1'b1;
                        if (error_count >= UNLOCK_THRESHOLD) begin
                            lock_state <= ACQUIRING;
                            error_count <= 8'b0;
                            stable_count <= 8'b0;
                        end
                    end
                end

                LOCKED: begin
                    lock <= 1'b1;
                    almost_lock <= 1'b1;
                    if (phase_error > 4'd2) begin
                        error_count <= error_count + 1'b1;
                        if (error_count >= UNLOCK_THRESHOLD) begin
                            lock_state <= ALMOST_LOCKED;
                            lock <= 1'b0;
                            error_count <= 8'b0;
                        end
                    end else begin
                        error_count <= 8'b0;
                    end
                end

                default: lock_state <= UNLOCKED;
            endcase
        end
    end

    wire _unused = &{ref_clk, fb_clk, 1'b0};

endmodule
