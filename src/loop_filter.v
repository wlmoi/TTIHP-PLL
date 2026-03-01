`default_nettype none

module loop_filter #(
    parameter CTRL_WIDTH = 16,
    parameter PROP_GAIN = 8'd64,
    parameter INT_GAIN = 8'd16,
    parameter CTRL_BIAS = 0
)(
    input  wire                    clk,
    input  wire                    reset_n,
    input  wire                    cp_up,
    input  wire                    cp_down,
    input  wire [3:0]              cp_gain,
    output reg  [CTRL_WIDTH-1:0]   ctrl_voltage
);

    reg signed [CTRL_WIDTH+7:0] integrator;
    reg signed [CTRL_WIDTH+7:0] proportional;
    reg signed [CTRL_WIDTH+7:0] filter_output;
    wire signed [CTRL_WIDTH+7:0] mid_scale;
    assign mid_scale = (1 <<< (CTRL_WIDTH-1)) + CTRL_BIAS;

    wire signed [7:0] phase_error;
    assign phase_error = cp_up ? $signed(cp_gain) :
                        cp_down ? -$signed(cp_gain) : 8'sd0;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            integrator <= {(CTRL_WIDTH+8){1'b0}};
            proportional <= {(CTRL_WIDTH+8){1'b0}};
            filter_output <= mid_scale;
            ctrl_voltage <= mid_scale[CTRL_WIDTH-1:0];
        end else begin
            proportional <= phase_error * PROP_GAIN;

            if (integrator < ((1 << (CTRL_WIDTH+6)) - 1) &&
                integrator > -(1 << (CTRL_WIDTH+6))) begin
                integrator <= integrator + (phase_error * INT_GAIN);
            end else if (phase_error < 0 && integrator > 0) begin
                integrator <= integrator + (phase_error * INT_GAIN);
            end else if (phase_error > 0 && integrator < 0) begin
                integrator <= integrator + (phase_error * INT_GAIN);
            end

            filter_output <= mid_scale + proportional + (integrator >>> 6);

            if (filter_output < 0) begin
                ctrl_voltage <= {CTRL_WIDTH{1'b0}};
            end else if (filter_output >= (1 << CTRL_WIDTH)) begin
                ctrl_voltage <= {CTRL_WIDTH{1'b1}};
            end else begin
                ctrl_voltage <= filter_output[CTRL_WIDTH-1:0];
            end
        end
    end

endmodule
