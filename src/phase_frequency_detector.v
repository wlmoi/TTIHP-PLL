`default_nettype none

module phase_frequency_detector (
    input  wire ref_clk,
    input  wire fb_clk,
    input  wire reset_n,
    output reg  up,
    output reg  down
);

    reg up_ff, down_ff;
    wire rst_pfd_n;

    assign rst_pfd_n = reset_n & ~(up_ff & down_ff);

    always @(posedge ref_clk or negedge rst_pfd_n) begin
        if (!rst_pfd_n) begin
            up_ff <= 1'b0;
        end else begin
            up_ff <= 1'b1;
        end
    end

    always @(posedge fb_clk or negedge rst_pfd_n) begin
        if (!rst_pfd_n) begin
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
