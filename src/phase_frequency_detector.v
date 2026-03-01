`default_nettype none

module phase_frequency_detector (
    input  wire ref_clk,
    input  wire fb_clk,
    input  wire reset_n,
    output reg  up,
    output reg  down
);

    reg up_ff, down_ff;

    always @(posedge ref_clk or negedge reset_n) begin
        if (!reset_n) begin
            up_ff <= 1'b0;
        end else if (down_ff) begin
            up_ff <= 1'b0;
        end else begin
            up_ff <= 1'b1;
        end
    end

    always @(posedge fb_clk or negedge reset_n) begin
        if (!reset_n) begin
            down_ff <= 1'b0;
        end else if (up_ff) begin
            down_ff <= 1'b0;
        end else begin
            down_ff <= 1'b1;
        end
    end

    always @(*) begin
        up = up_ff;
        down = down_ff;
    end

endmodule
