![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

# Tiny Tapeout - Smartcard PLL Clock Generator

- Top module: `tt_um_william_pll`
- Language: Verilog
- Target shuttle: SKY26a (`sky130A`, digital tile)
- Project docs: [docs/info.md](docs/info.md)

## Creator

- William Anthony
- Electrical Engineering, Bandung Institute of Technology (ITB)
- Built in 6th semester (admitted in 2023)
- LinkedIn: https://www.linkedin.com/in/wlmoi/
- GitHub: https://github.com/wlmoi
- Instagram: https://www.instagram.com/wlmoi/

## What is Tiny Tapeout?

Tiny Tapeout is an educational project that aims to make it easier and cheaper than ever to get your digital and analog designs manufactured on a real chip.

To learn more and get started, visit https://tinytapeout.com.

## Overview

This design wraps a smartcard-oriented PLL model into the Tiny Tapeout user module interface.
The reference input uses Tiny Tapeout `clk`, and the PLL is intentionally controlled by an explicit enable bit.

## How activation works

- `ena` must be high (project selected)
- `rst_n` must be high (reset released)
- `ui[0]` must be set to `1` to enable PLL operation

When `ui[0]` is set back to `0`, the PLL path is intentionally disabled and output clocks are expected to stop.

## Pin map summary

- Inputs (`ui_in`)
  - `ui[0]`: PLL enable
  - `ui[7:4]`: divider ratio config nibble
- Bidirectional (`uio`)
  - `uio[3:0]` input: charge pump gain config
  - `uio[7:4]` output: VCO monitor bits
- Outputs (`uo_out`)
  - `uo[0]`: lock
  - `uo[1]`: almost_lock
  - `uo[2]`: clk_div4
  - `uo[3]`: clk_div2
  - `uo[4]`: pll_clk_out
  - `uo[5]`: pfd_up
  - `uo[6]`: pfd_down
  - `uo[7]`: enable status

## Local test

From `test/` run:

```sh
make -B
```

The cocotb test verifies disabled state, enabled oscillation, and disabled-again behavior.

## Resources

- [FAQ](https://tinytapeout.com/faq/)
- [Digital design lessons](https://tinytapeout.com/digital_design/)
- [Learn how semiconductors work](https://tinytapeout.com/siliwiz/)
- [Join the community](https://tinytapeout.com/discord)
- [Build your design locally](https://www.tinytapeout.com/guides/local-hardening/)

## Credits

Project template and submission flow are based on the Tiny Tapeout project ecosystem and documentation.

## Submit your design

- [Submit your design to the next shuttle](https://app.tinytapeout.com/).

## Share your project

- LinkedIn [#tinytapeout](https://www.linkedin.com/search/results/content/?keywords=%23tinytapeout) [@TinyTapeout](https://www.linkedin.com/company/100708654/)
- Mastodon [#tinytapeout](https://chaos.social/tags/tinytapeout) [@matthewvenn](https://chaos.social/@matthewvenn)
- X (formerly Twitter) [#tinytapeout](https://twitter.com/hashtag/tinytapeout) [@tinytapeout](https://twitter.com/tinytapeout)
- Bluesky [@tinytapeout.com](https://bsky.app/profile/tinytapeout.com)
