`default_nettype none

module frequency_divider #(
    parameter DIV_WIDTH = 8,
    parameter DEFAULT_DIV = 8'd4
)(
    input  wire                 clk_in,
    input  wire                 reset_n,
    input  wire [DIV_WIDTH-1:0] div_ratio,
    input  wire                 enable,
    output reg                  clk_out
);

    reg [DIV_WIDTH-1:0] counter;
    reg [DIV_WIDTH-1:0] div_value;
    reg                 phase;
    reg [DIV_WIDTH-1:0] high_count;
    reg [DIV_WIDTH-1:0] low_count;

    always @(posedge clk_in or negedge reset_n) begin
        if (!reset_n) begin
            counter   <= {DIV_WIDTH{1'b0}};
            clk_out   <= 1'b0;
            div_value <= DEFAULT_DIV;
            phase     <= 1'b0;
            high_count <= DEFAULT_DIV >> 1;
            low_count  <= (DEFAULT_DIV + 1) >> 1;
        end else if (enable) begin
            if (counter == 0 && phase == 0) begin
                div_value <= (div_ratio == 0) ? DEFAULT_DIV : div_ratio;
                low_count  <= (((div_ratio == 0) ? DEFAULT_DIV : div_ratio)) >> 1;
                high_count <= (((div_ratio == 0) ? DEFAULT_DIV : div_ratio) + 1'b1) >> 1;
                if (((div_ratio == 0) ? DEFAULT_DIV : div_ratio) == 1) begin
                    high_count <= 1;
                    low_count  <= 0;
                end
            end

            if (div_value == 1) begin
                clk_out <= clk_in;
                counter <= 0;
                phase   <= 0;
            end else if (div_value == 2) begin
                clk_out <= ~clk_out;
                counter <= 0;
                phase   <= 0;
            end else begin
                if (!phase) begin
                    if (low_count == 0) begin
                        phase   <= 1'b1;
                        clk_out <= 1'b1;
                        counter <= 0;
                    end else if (counter == (low_count - 1)) begin
                        phase   <= 1'b1;
                        clk_out <= 1'b1;
                        counter <= 0;
                    end else begin
                        counter <= counter + 1'b1;
                    end
                end else begin
                    if (counter == (high_count - 1)) begin
                        phase   <= 1'b0;
                        clk_out <= 1'b0;
                        counter <= 0;
                    end else begin
                        counter <= counter + 1'b1;
                    end
                end
            end
        end else begin
            counter <= {DIV_WIDTH{1'b0}};
            clk_out <= 1'b0;
            phase   <= 1'b0;
        end
    end

endmodule
