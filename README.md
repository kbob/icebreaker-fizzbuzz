# icebreaker-fizzbuzz

I am teaching myself Verilog and digital design.  I thought I might
be able to write
[the classic FizzBuzz algorithm](https://imranontech.com/2007/01/24/using-fizzbuzz-to-find-developers-who-grok-coding/)
in Verilog.


## Video

Here's a quick demo of the finished program.

[![Demo on YouTube](https://img.youtube.com/vi/_z16ZLBM3ygE/0.jpg)](https://www.youtube.com/watch?v=_z16LBM3ygE)


## Hardware

I used Piotr Esden-Tempski's
[iCEBreaker](https://www.crowdsupply.com/1bitsquared/icebreaker-fpga)
dev board.  It has a Lattice iCE40 UltraPlus 5K FPGA, some
[PMOD ports](https://store.digilentinc.com/pmod-modules-connectors/),
and a handful of buttons and LEDs on a breakaway board.  When you
break away that board, another PMOD port is exposed.  You can solder a
connector onto it and reattach it via PMOD.  Or leave it attached
and avoid soldering.

There is also an FTDI USB-to-serial chip that is actually bigger than
the FPGA.  The FTDI chip has lots of I/O, but I haven't delved into
that yet.

Piotr also made a PMOD board with two seven segment displays.  There's
not much to say about that -- it's a pretty simple board.


## Toolchain

I am using Clifford Wolf's
[IceStorm](http://www.clifford.at/icestorm/) tools.  IceStorm is a
suite of open source tools that started out targeting the iCE40
line of FPGAs.  It is command line based (but see
[icestudio](https://github.com/FPGAwars/icestudio)).  It turns
a verilog program into a configuration file ready to be
downloaded onto an FPGA.  The whole process is somewhat mysterious to
me, but you know -- it's open source, so how hard could it be to
figure out?


## FizzBuzz

I'd already taught my FPGA to count in hex on the display, so I'd
figured out the I/O pins and how to cycle them.  Just adding FizzBuzz
to that would be too easy.  So I added some bells and whistles.

* Starts counting at one instead of zero because that's the problem
  description.

* Button 1 switches between decimal, octal, hexadecimal, and binary
  (and resets the counter).  The display shows "d", "o", "h", or "b"
  to indicate the new radix.

* Button 2 turns Fizz-replacement on and off (and resets the counter).

* Button 3 turns Buzz-replacement on and off (and resets the counter).

* "Fi" and "bu" are brighter (higher duty cycle) than the digits
  and they blink.  Those two kind of cancel each other out.

* The LEDs on the iCEBreaker board indicate whether Fizz-replacement
  and Buzz-replacement are active.
  
* The LEDs on the breakaway board animate when a button is pressed,
  and they also indicate which digits are fizzy and buzzy (whether
  F/B-replacement is active or not).
  
That's far too much detail for a simple amusement.  Just watch the
video and be simple-amused.  Or read the code -- that's what it's here
for.
