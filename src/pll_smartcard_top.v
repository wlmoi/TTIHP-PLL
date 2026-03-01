`default_nettype none

module pll_smartcard_top #(
    parameter REF_FREQ_HZ = 13_560_000,
    parameter OUT_FREQ_HZ = 54_240_000,
    parameter DIV_RATIO = 4,
    parameter CTRL_WIDTH = 16,
    parameter DIV_WIDTH = 8,
    parameter LOCK_THRESHOLD = 16,
    parameter PROP_GAIN = 64,
    parameter INT_GAIN = 16
)(
    input  wire                     ref_clk_in,
    input  wire                     reset_n,
    input  wire                     enable,
    input  wire [DIV_WIDTH-1:0]     div_ratio_cfg,
    input  wire [3:0]               cp_gain_cfg,
    output wire                     clk_out,
    output wire                     clk_div2,
    output wire                     clk_div4,
    output wire                     lock,
    output wire                     almost_lock,
    output wire [CTRL_WIDTH-1:0]    vco_ctrl_mon,
    output wire                     pfd_up_mon,
    output wire                     pfd_down_mon
);

    wire pfd_up, pfd_down;
    wire cp_up, cp_down;
    wire [3:0] cp_gain;
    wire [CTRL_WIDTH-1:0] ctrl_voltage;
    wire vco_clk;
    wire [7:0] vco_ctrl_scaled;
    wire fb_clk;
    wire div_enable;
    wire ref_clk_buf;
    wire vco_clk_buf;

    assign ref_clk_buf = ref_clk_in;

    phase_frequency_detector u_pfd (
        .ref_clk    (ref_clk_buf),
        .fb_clk     (fb_clk),
        .reset_n    (reset_n & enable),
        .up         (pfd_up),
        .down       (pfd_down)
    );

    digital_charge_pump_ctrl u_cp_ctrl (
        .clk        (ref_clk_buf),
        .reset_n    (reset_n & enable),
        .up         (pfd_up),
        .down       (pfd_down),
        .cp_up      (cp_up),
        .cp_down    (cp_down),
        .cp_gain    (cp_gain)
    );

    loop_filter #(
        .CTRL_WIDTH (CTRL_WIDTH),
        .PROP_GAIN  (PROP_GAIN),
        .INT_GAIN   (INT_GAIN),
        .CTRL_BIAS  (-8)
    ) u_loop_filter (
        .clk            (ref_clk_buf),
        .reset_n        (reset_n & enable),
        .cp_up          (cp_up),
        .cp_down        (cp_down),
        .cp_gain        (cp_gain),
        .ctrl_voltage   (ctrl_voltage)
    );

    assign vco_ctrl_scaled = ctrl_voltage[CTRL_WIDTH-1:CTRL_WIDTH-8];

    vco_digital_model #(
        .CENTER_FREQ    (OUT_FREQ_HZ),
        .KVCO           (50_000_000),
        .VDD            (18),
        .CTRL_WIDTH     (8),
        .CTRL_OFFSET    (0),
        .CALIB_NUM      (10058),
        .CALIB_DEN      (10000)
    ) u_vco (
        .enable         (enable),
        .reset_n        (reset_n),
        .ctrl_voltage   (vco_ctrl_scaled),
        .clk_out        (vco_clk)
    );

    assign vco_clk_buf = vco_clk;
    assign div_enable = enable & reset_n;

    frequency_divider #(
        .DIV_WIDTH      (DIV_WIDTH),
        .DEFAULT_DIV    (DIV_RATIO)
    ) u_feedback_divider (
        .clk_in         (vco_clk_buf),
        .reset_n        (reset_n),
        .div_ratio      (div_ratio_cfg),
        .enable         (div_enable),
        .clk_out        (fb_clk)
    );

    assign clk_out = vco_clk_buf;

    frequency_divider #(
        .DIV_WIDTH      (8),
        .DEFAULT_DIV    (2)
    ) u_div2 (
        .clk_in         (vco_clk_buf),
        .reset_n        (reset_n),
        .div_ratio      (8'd2),
        .enable         (div_enable),
        .clk_out        (clk_div2)
    );

    frequency_divider #(
        .DIV_WIDTH      (8),
        .DEFAULT_DIV    (4)
    ) u_div4 (
        .clk_in         (vco_clk_buf),
        .reset_n        (reset_n),
        .div_ratio      (8'd4),
        .enable         (div_enable),
        .clk_out        (clk_div4)
    );

    lock_detector #(
        .LOCK_THRESHOLD     (LOCK_THRESHOLD),
        .UNLOCK_THRESHOLD   (4)
    ) u_lock_detector (
        .clk            (ref_clk_buf),
        .reset_n        (reset_n & enable),
        .up             (pfd_up),
        .down           (pfd_down),
        .ref_clk        (ref_clk_buf),
        .fb_clk         (fb_clk),
        .lock           (lock),
        .almost_lock    (almost_lock)
    );

    assign vco_ctrl_mon = ctrl_voltage;
    assign pfd_up_mon = pfd_up;
    assign pfd_down_mon = pfd_down;

    wire _unused = &{cp_gain_cfg, 1'b0};

endmodule
