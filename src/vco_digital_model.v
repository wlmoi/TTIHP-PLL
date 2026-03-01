`default_nettype none
`timescale 1ps/1ps

module vco_digital_model #(
    parameter CENTER_FREQ = 54_240_000,
    parameter KVCO = 50_000_000,
    parameter VDD = 18,
    parameter CTRL_WIDTH = 8,
    parameter CTRL_OFFSET = 0,
    parameter CALIB_NUM = 10000,
    parameter CALIB_DEN = 10000
)(
    input  wire                    enable,
    input  wire                    reset_n,
    input  wire [CTRL_WIDTH-1:0]   ctrl_voltage,
    output reg                     clk_out
);

`ifdef VCO_BEHAVIORAL
    reg [31:0] half_period_ps;
    reg [CTRL_WIDTH-1:0] ctrl_eff;
    localparam [CTRL_WIDTH-1:0] CTRL_OFFSET_V = CTRL_OFFSET;

    always @(*) begin
        if (ctrl_voltage > CTRL_OFFSET_V) begin
            ctrl_eff = ctrl_voltage - CTRL_OFFSET_V;
        end else begin
            ctrl_eff = {CTRL_WIDTH{1'b0}};
        end

        if (ctrl_eff == 0) begin
            half_period_ps = 18440;
        end else if (ctrl_eff == 8'd128) begin
            half_period_ps = 9220;
        end else if (ctrl_eff == {CTRL_WIDTH{1'b1}}) begin
            half_period_ps = 6147;
        end else if (ctrl_eff < 8'd128) begin
            half_period_ps = 18440 - ((ctrl_eff * 9220) / 128);
        end else begin
            half_period_ps = 9220 - (((ctrl_eff - 8'd128) * 3073) / 127);
        end

        if (CALIB_DEN != 0) begin
            half_period_ps = (half_period_ps * CALIB_NUM) / CALIB_DEN;
        end

        if (half_period_ps < 6000) half_period_ps = 6000;
        if (half_period_ps > 19000) half_period_ps = 19000;
    end

    initial clk_out = 1'b0;

    always begin
        if (!reset_n || !enable) begin
            clk_out = 1'b0;
            @(reset_n or enable);
            #1;
        end else begin
            #(half_period_ps);
            clk_out = ~clk_out;
        end
    end
`else
    always @(*) begin
        clk_out = 1'b0;
    end

    wire _unused = &{ctrl_voltage, CENTER_FREQ, KVCO, VDD, CALIB_NUM, CALIB_DEN, 1'b0};
`endif

endmodule
