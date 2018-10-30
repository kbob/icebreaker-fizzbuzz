`default_nettype none

// enums.

`define Radix     [1:0]
`define r_decimal 2'd0
`define r_octal   2'd1
`define r_hex     2'd2
`define r_binary  2'd3

`define Override  [2:0]
`define o_blank   3'd0
`define o_decimal 3'd1
`define o_octal   3'd2
`define o_hex     3'd3
`define o_binary  3'd4
`define o_fi      3'd5
`define o_bu      3'd6
`define o_fibu    3'd7


module top(
           input  CLK,
           input  BTN1,
           input  BTN2,
           input  BTN3,
           output LED1,
           output LED2,
           output LED3,
           output LED4,
           output LED5,
           output LEDR_N,
           output LEDG_N,
           output P1A1,
           output P1A2,
           output P1A3,
           output P1A4,
           output P1A7,
           output P1A8,
           output P1A9,
           output P1A10
           );

   reg `Radix           radix;
   reg `Override        override;
   reg                  override_ena;
   reg                  hold_zero;
   reg                  btn1_press;
   reg                  btn2_press;
   reg                  btn3_press;
   reg                  btn1_release;
   reg                  btn2_release;
   reg                  btn3_release;
   reg   [3:0]          tens_digit, ones_digit;
   reg                  fi_active, bu_active;
   reg                  fi, bu;
   reg                  counter_inc;
   reg                  overflow;

   wire [7:0]           pmod_pins_n;
   wire [3:0]           led_ring_pins;
   assign {P1A10, P1A9, P1A8, P1A7, P1A4, P1A3, P1A2, P1A1} = pmod_pins_n;
   assign {LED5, LED4, LED3, LED2} = led_ring_pins;
   assign LEDR_N = ~bu_active;
   assign LEDG_N = ~fi_active;
   
   button_debouncer db1(
                        .clk(CLK),
                        .button_pin(BTN1),
                        .press_evt(btn1_press),
                        .release_evt(btn1_release),
                        );

   button_debouncer db2(
                        .clk(CLK),
                        .button_pin(BTN2),
                        .press_evt(btn2_press),
                        .release_evt(btn2_release),
                        );

   button_debouncer db3(
                        .clk(CLK),
                        .button_pin(BTN3),
                        .press_evt(btn3_press),
                        .release_evt(btn3_release),
                        );

   controller ctl(
                  .clk(CLK),
                  .btn1_press(btn1_press),
                  .btn1_release(btn1_release),
                  .btn2_press(btn2_press),
                  .btn2_release(btn2_release),
                  .btn3_press(btn3_press),
                  .btn3_release(btn3_release),
                  .radix(radix),
                  .override(override),
                  .override_ena(override_ena),
                  .hold_zero(hold_zero),
                  .fi_active(fi_active),
                  .bu_active(bu_active)
                  );

   hypercounter hc(
                   .clk(CLK),
                   .hold_zero(hold_zero),
                   .radix(radix),
                   .digit_msec(333),
                   .tens(tens_digit),
                   .ones(ones_digit),
                   .inc(counter_inc),
                   .overflow(overflow)
                   );

   zzer zz(
           .clk(CLK),
           .inc(counter_inc),
           .hold_zero(hold_zero | overflow),
           .fi(fi),
           .bu(bu)
           );

   wire                 display_fi;
   wire                 display_bu;
   wire                 display_fb;
   wire                 all_ovrd_ena;
   wire `Override       all_ovrd;
   assign display_fi = fi_active & fi;
   assign display_bu = bu_active & bu;
   assign display_fb = display_fi & display_bu;
   assign all_ovrd_ena = override_ena | display_fi | display_bu;
   assign all_ovrd = (display_fb ? `o_fibu :
                      display_fi ? `o_fi :
                      display_bu ? `o_bu :
                      override);

   display_driver dd(
                     .clk(CLK),
                     .tens_digit(tens_digit),
                     .ones_digit(ones_digit),
                     .override(all_ovrd),
                     .override_ena(all_ovrd_ena),
                     .bright(display_fi | display_bu),
                     .blink(display_fi | display_bu),
                     .blank_leading(radix == `r_decimal),
                     .pmod_pins_n(pmod_pins_n)
                     );

   led_anim la(
               .clk(CLK),
               .btn_press(btn1_press | btn2_press | btn3_press),
               .btn_release(btn1_release | btn2_release | btn3_release),
               .fi(fi),
               .bu(bu),
               .center_led_pin(LED1),
               .led_ring_pins(led_ring_pins)
               );

endmodule // top


module controller(
                  input                clk,
                  input                btn1_press,
                  input                btn1_release,
                  input                btn2_press,
                  input                btn2_release,
                  input                btn3_press,
                  input                btn3_release,
                  output reg `Radix    radix,
                  output reg `Override override,
                  output reg           override_ena,
                  output reg           hold_zero,
                  output reg           fi_active,
                  output reg           bu_active,
                  );

   always @(posedge clk) begin
      if (btn1_press) begin
         radix <= radix + 1;
         hold_zero <= 1;
         override_ena <= 1;
         case ((radix + 1) & 3)
           `r_decimal: override <= `o_decimal;
           `r_octal:   override <= `o_octal;
           `r_hex:     override <= `o_hex;
           `r_binary:  override <= `o_binary;
         endcase
      end
      if (btn1_release) begin
         override_ena <= 0;
         hold_zero <= 0;
      end
      if (btn2_press) begin
         fi_active <= ~fi_active;
         override_ena <= 1;
         hold_zero <= 1;
         override <= `o_blank;
      end
      if (btn2_release) begin
         override_ena <= 0;
         hold_zero <= 0;
      end
      if (btn3_press) begin
         bu_active <= ~bu_active;
         override_ena <= 1;
         hold_zero <= 1;
         override <= `o_blank;
      end
      if (btn3_release) begin
         override_ena <= 0;
         hold_zero <= 0;
      end
   end

endmodule // controller


module hypercounter(input            clk,
                    input            hold_zero,
                    input            `Radix radix,
                    input [10:0]     digit_msec,
                    output reg [3:0] tens,
                    output reg [3:0] ones,
                    output reg       inc,
                    output reg       overflow
                    );

   reg [14:0] fast_counter;
   wire       khz_tick;
   assign khz_tick = fast_counter[14];

   reg [10:0] msec_counter;

   reg [3:0] max;
   always @(*)
     case (radix)
       `r_decimal: max <= 9;
       `r_octal:   max <= 7;
       `r_hex:     max <= 'hF;
       `r_binary:  max <= 'b1;
     endcase

   always @(posedge clk) begin
      if (fast_counter[14])
        fast_counter <= 12000 - 1;
      else
        fast_counter <= fast_counter - 1;

      if (khz_tick) begin
         if (hold_zero) begin
            tens <= 0;
            ones <= 0;
            msec_counter <= 0;
            inc <= 0;
         end
         else begin
            if (msec_counter) begin
               msec_counter <= msec_counter - 1;
               inc <= 0;
               overflow <= 0;
            end
            else begin
               msec_counter <= digit_msec;
               inc <= 1;
               if (ones == max) begin
                  ones <= 0;
                  if (tens == max) begin
                     tens <= 0;
                     overflow <= 1;
                  end
                  else
                    tens <= tens + 1;
               end
               else
                 ones <= ones + 1;
            end
         end
      end // if (khz_tick)
      else
        inc <= 0;
   end

endmodule // hypercounter


module zzer(input clk,
            input inc,
            input hold_zero,
            output reg fi,
            output reg bu
            );

   reg [1:0] fcount;
   reg [2:0] bcount;

   always @(posedge clk) begin
      if (hold_zero) begin
         fcount <= 0;
         bcount <= 0;
         fi <= 0;
         bu <= 0;
      end
      else if (inc) begin
         if (fcount == 2) begin
            fcount <= 0;
            fi <= 1;
         end
         else begin
            fcount <= fcount + 1;
            fi <= 0;
         end
         if (bcount == 4) begin
            bcount <= 0;
            bu <= 1;
         end
         else begin
            bcount <= bcount + 1;
            bu <= 0;
         end
      end
   end

endmodule // zzer


module led_anim(input        clk,
                input        btn_press,
                input        btn_release,
                input        fi,
                input        bu,
                output       center_led_pin,
                output [3:0] led_ring_pins
                );

   reg                       center_led;
   reg [3:0]                 led_ring;
   reg [24:0]                duration;
   reg                       counting;
   
   assign center_led_pin = center_led;
   assign led_ring_pins = led_ring;

/* -----\/----- EXCLUDED -----\/-----
   always @(posedge clk)
     led_ring <= {4{fi}} & 4'b0011 | {4{bu}} & 4'b1100;
 -----/\----- EXCLUDED -----/\----- */

   always @(posedge clk) begin
      if (btn_press) begin
         duration <= 0;
         counting <= 1;
      end
      if (btn_release) begin
         counting <= 0;
      end
      if (counting) begin
         if (!duration[24])
           duration <= duration + 1;
         center_led <= 1;
         led_ring <= 4'b0000;
      end
      else begin
         center_led <= 0;
         if (duration) begin
            duration <= duration - 1;
            led_ring <= 4'b1111;
         end
         else
           led_ring <= {4{fi}} & 4'b0011 | {4{bu}} & 4'b1100;
      end
   end

endmodule // led_anim


module button_debouncer(input      clk,
                        input      button_pin,
                        output reg press_evt,
                        output reg release_evt
                        );

   localparam COUNT_BITS = 13;
   reg is_down;
   reg was_down;
   reg [COUNT_BITS-1:0]      counter = 0;

   always @(posedge clk)
     if (counter) begin
        counter <= counter + 1;
        press_evt = 0;
        release_evt = 0;
        was_down <= is_down;
     end
     else begin
        was_down <= is_down;
        is_down <= button_pin;
        if (is_down != was_down) begin
           counter <= 1;
           press_evt <= is_down;
           release_evt <= was_down;
        end
     end

endmodule // button_debouncer


module display_driver(input           clk,
                      input  [3:0]    tens_digit,
                      input  [3:0]    ones_digit,
                      input `Override override,
                      input           override_ena,
                      input           bright,
                      input           blink,
                      input           blank_leading,
                      output [7:0]    pmod_pins_n
                      );

   reg [20:0] counter;
   wire [3:0] state;
   wire       blinker;
   assign state = counter[3:0];
   assign blinker = (counter[20] | counter[19]) & blink;

   // {ones, tens}_segments active when displaying digits.
   // {left, right}_segments when displaying override.
   reg [6:0] ones_segments, tens_segments;
   reg [6:0] left_segments, right_segments;

   digit_to_segments d2s1(clk, ones_digit, ones_segments);
   digit_to_segments d2s10(clk, tens_digit, tens_segments);
   special_to_segments s(clk, override, left_segments, right_segments);

   reg [6:0] left_out;
   reg [6:0] right_out;

   reg [6:0] pmod_segments_n;
   reg       pmod_digit_sel;
   assign pmod_pins_n = {pmod_digit_sel, pmod_segments_n};

   always @(posedge clk) begin
      counter <= counter + 1;
      if (override_ena) begin
         left_out <= left_segments;
         right_out <= right_segments;
      end
      else begin
         right_out <= ones_segments;
         if (tens_digit == 0 && blank_leading)
           left_out <= 0;
         else
           left_out <= tens_segments;
      end
      case (state)
        0: pmod_digit_sel <= 0;
        1: pmod_segments_n <= ~left_out | {7{blinker}};
        4: pmod_segments_n <= ~left_out | {7{~bright | blinker}};
        7: pmod_segments_n <= ~0;
        8: pmod_digit_sel <= 1;
        9: pmod_segments_n <= ~right_out | {7{blinker}};
        12: pmod_segments_n <= ~right_out | {7{~bright | blinker}};
        15: pmod_segments_n <= ~0;
      endcase
   end

endmodule // display_driver


module special_to_segments(input            clk,
                           input `Override  override,
                           output reg [6:0] left_segments,
                           output reg [6:0] right_segments
                           );

   always @(posedge clk)
     case (override)

       `o_blank:
         begin
            left_segments  <= 0;
            right_segments <= 0;
         end

       `o_decimal:
         begin
            left_segments  <= 7'b1011110;
            right_segments <= 0;
         end

       `o_octal:
         begin
            left_segments  <= 7'b1011100;
            right_segments <= 0;
         end

       `o_hex:
         begin
            left_segments  <= 7'b1110100;
            right_segments <= 0;
         end

       `o_binary:
         begin
            left_segments  <= 7'b1111100;
            right_segments <= 0;
         end

       `o_fi:
         begin
            left_segments  <= 7'b1110001;
            right_segments <= 7'b0010000;
         end

       `o_bu:
         begin
            left_segments  <= 7'b1111100;
            right_segments <= 7'b0011100;
         end

       `o_fibu:
         begin
            left_segments  <= 7'b1110001;
            right_segments <= 7'b1111100;
         end

     endcase

endmodule // special_to_segments


// Get the segments to illuminate to display a single hex digit.
// N.B., This is positive logic.  Display needs negative.
module digit_to_segments(input            clk,
                         input      [3:0] digit,
                         output reg [6:0] segments
                         );

   always @(posedge clk)
     case (digit)
       0: segments <= 7'b0111111;
       1: segments <= 7'b0000110;
       2: segments <= 7'b1011011;
       3: segments <= 7'b1001111;
       4: segments <= 7'b1100110;
       5: segments <= 7'b1101101;
       6: segments <= 7'b1111101;
       7: segments <= 7'b0000111;
       8: segments <= 7'b1111111;
       9: segments <= 7'b1101111;
       4'hA: segments <= 7'b1110111;
       4'hB: segments <= 7'b1111100;
       4'hC: segments <= 7'b0111001;
       4'hD: segments <= 7'b1011110;
       4'hE: segments <= 7'b1111001;
       4'hF: segments <= 7'b1110001;
     endcase

endmodule // digit_to_segments
