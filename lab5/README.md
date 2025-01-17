# ASIC Lab 5: Macros (SRAM Integration)

## Table of Contents
- [ASIC Lab 5: Macros (SRAM Integration)](#asic-lab-5-macros-sram-integration)
    - [Table of Contents](#table-of-contents)
    - [Overview](#overview)
    - [Background](#background)
    - [Macros](#macros)
        - [Support Files for Macros](#support-files-for-macros)
            - [Graphical Database System](#graphical-database-system)
            - [Liberty Timing Files](#liberty-timing-files)
            - [Library Exchange Format](#library-exchange-format)
            - [Data Exchange Format](#data-exchange-format)
    - [SRAM Example](#sram-example)
        - [Using SRAMs generated with SRAM22](#using-srams-generated-with-sram22)
    - [Dot Product](#dot-product)
    - [Place and Route Example](#place-and-route-example)
    - [Questions](#questions)
        - [Question 1: Understanding SRAMs](#question-1-understanding-SRAMs)
        - [Question 2: Performance and Area Optimization](#question-2-performance-and-area-optimization)


## Overview

**Setup:**
In case you haven't done the main lab [Setup](../README.md#setup) successfully, please do so before you continue in order to be able to follow this lab and submit your results. Also, please remember to regularly update (sync) your lab repo with the latest upstream changes, as well as the *digel* repo (with submodules!) in order to include the latest Hammer changes.

Prior to running any commands, you need to activate a Poetry virtual environment with a Hammer (*hammer-vlsi*) installation:

```shell
# Replace <hammer_path> with your Hammer installation path
source <hammer_path>/.venv/bin/activate
hammer-vlsi -h
```

Also, perform some text transformations to prepare the environment for the lab exercise:

```shell
cd lab5
# Replace <hammer_path> with your Hammer installation path
sed -i "s;HAMMER_PATH;<hammer_path>;g" Makefile
sed -i "s;HAMMER_PATH;<hammer_path>;g" cfg/sky130.yml
sed -i "s;~;$HOME;g" cfg/sky130.yml
sed -i "s;~;$HOME;g" cfg/sim-rtl.yml
```

**Objective:**
In this lab, we will cover how to integrate blocks beyond standard cells in VLSI designs while implementing an example design:
1. Vector dot product module.
2. PAR design with SRAM macros.


**Topics Covered**
- Place and Route
- Metal Layers
- Standard Cell
- CAD Tools (emphasis on *OpenROAD*)
- Hammer
- Skywater 130mm PDK
- Reading Reports

**Recommended Reading**
- [Verilog Primer](../lab2/doc/Verilog_Primer_Slides.pdf)
- [Ready-Valid Interface](../lab3/doc/ready_valid_interface.pdf)
- [Hammer-Flow](https://hammer-vlsi.readthedocs.io/en/latest/Hammer-Flow/index.html)


## Background

Designs include black-boxed circuits called *macros*. Macros are custom, pre-built logical circuits that have already gone through synthesis and PAR and are to be integrated directly into your design. The most common custom block is SRAM, which is a dense addressable memory block used in most VLSI designs.
The [Wikipedia article on SRAM](https://en.wikipedia.org/wiki/Static_random-access_memory) provides a good starting point for learning more about SRAM.

SRAM is treated as a hard macro block in VLSI flow.
It is created separately from the standard cell libraries.
The process for adding other custom, analog, or mixed-signal circuits will be similar to what we use for SRAMs.
It is important to know how to design a digital circuit and run a CAD flow with these hard macro blocks.
This lab exercise will help you get familiar with SRAM interfacing.
We will use an example design of computing a dot product of two vectors to walk you through how to use the SRAM blocks.


## Macros

A macro is a predefined, custom logic block that is usually an intellectual property (IP) from third parties. Examples of macros include SRAMs, PLLs, ADCs, SerDes, etc. Macros are integrated into a design to provide some (typically complex) capability. For example, SRAMs are optimized high-density blocks for storage (e.g., register files). Macros are categorized by two flavors:

- *Soft Macros* - configurable, synthesizable, RTL logic blocks that are technology-independent (portable between technology nodes). They are directly integrated into the RTL design, then synthesized and placed and routed together.

- *Hard Macros* - fixed (not configurable), technology-dependent, highly optimized blocks provided by a foundry or an IP manufacturing company that are already synthesized and run through place and route. Hard macros are essentially black boxes exposing only pins to the external design. Analog blocks are delivered as hard macros.


### Support Files for Macros

Hard macros are delivered as GDS and/or a collection of specific files containing information necessary to integrate them into a design. These files are collateral from the design flow (synthesis and PAR) of the individual macros themselves.

#### Graphical Database System

[GDS](https://www.artwork.com/gdsii/gdsii/) files (*.gds) encode the entire detailed layout of the macro. This file is an output product of PAR. A macro's GDS layout is integrated within the rest of the PAR'd layout to create the final layout of the design before running DRC, LVS, and sending the design off to the fabrication house.

#### Liberty Timing Files

[Liberty](https://courses.cs.umbc.edu/graduate/CMPE641/Fall08/cpatel2/slides/lect05_LIB.pdf) files (*.lib) must be generated for macros at every relevant process, voltage, and temperature (PVT) corner that you are using for setup and hold timing analysis.
These detailed models contain descriptions of what each pin does, the delays depending on the load and input slew given in tables, and power information.
There are 3 types of Liberty files: [CCS, ECSM, and NLDM](https://singularitykchen.github.io/blog/2023/04/03/Glean-Library-Format/), which trade off accuracy with tool runtime.

#### Library Exchange Format

[LEF](https://coriolis.lip6.fr/doc/lefdef/lefdefref/LEFSyntax.html) files (*.lef) must be generated for macros in order to denote where pins are located and encode any obstructions (places where the PAR tool cannot place other cells or routing). Incorrect or inaccurate LEFs can often confuse PAR tools, making them produce layouts with many errors.

#### Data Exchange Format

[DEF](https://teamvlsi.com/2020/08/def-file-in-vlsi-design-exchange.html) files (*.def) specify the exact placement information for all aspects of a physical layout. Common aspects listed in a DEF are the die area, IO placement, blockages, and nets.

#### Verilog Simulation Models

Macro databases (files) usually also include a non-synthesizable HDL model, which should be used for simulation of macro functionality and its role in the design. This is necessary for design verification, since engineers cannot rely on documentation only.

> **Note:** Let it be known these file types aren't only for macros. In fact, other aspects of a design can be represented using these files. For example, routing for a specific metal layer can be represented in a DEF file.


## SRAM Example

In this lab, an SRAM is a design component. Let's look at it to understand how a hard macro is integrated into a digital design.

The SKY130 PDK does not come with SRAMs by default, so an SRAM generator called [SRAM22](https://github.com/rahulk29/sram22) was develop at UC Berkeley to programmatically generate SRAMs of varying dimensions. These SRAMs are synchronous-write and synchronous-read; the read data is only available at the next rising edge, and the write data is only written at the next rising edge. Hard macros are instantiated as black boxes that are connected to the rest of the circuit as specified in your Verilog. For Synthesis and PAR, the SRAMs must be abstracted away from the tools, because the only things that the flow is concerned about at these stages are the timing characteristics and the outer layout geometry of the SRAM macros. For simulation purposes, Verilog behavioral models for the SRAMs from the Hammer repository are used.

Below is the instantiation of the SRAM from *src/dot_product.v*. This is the SRAM you will use for your design.

```v
sram22_64x32m4w8 sram (
  .clk(clk),
  .we(we),
  .wmask(4'b1111),
  .addr(addr),
  .din(din),
  .dout(dout)
);
```

The specifications for the SRAM are contained in the name: *sram22_64x32m4w8* (the *"64x32"* specifies the SRAM is 64 entries deep and each entry is 32 bits wide). This is a single-port read/write SRAM block, which is often written as 1RW SRAM. It is a single port because there is a single port to specify the read/write address; therefore, a single address is either written to or read from in a single cycle. This means there is a 6-bit address for selecting one 32-bit entry. To write to the SRAM, we must set the write enable `we` signal high. Otherwise, when `we` is low, `dout` will contain the data at the `wmask`. The write mask port `wmask` allows us to select which bytes we want to write. For example, if we want to write to bits `31:24` and `7:0`, we would set `wmask = 4'b1001`.


### Using SRAMs generated with SRAM22

During the setup of SKY130, a GitHub repository [sram22_sky130_macros](https://github.com/rahulk29/sram22_sky130_macros) (commit **1f20d16**) which contains SKY130 SRAM macros generated with SRAM22 was cloned to *~/sram22_sky130_macros*. It includes all relevant files (GDS, LIB, LEF, Verilog, etc.) for several SRAM macro instances.
Peruse the directory to see the dimensions of SRAMs available to you. The SRAMs that we have in this process only support single-port memories, but in other processes, you may be able to use SRAMs with different numbers of ports. The SRAM Verilog models are only intended for simulation. **Do not include these files in your configuration for Synthesis or PAR**, or else you will produce incorrect post-synthesis or post-PAR netlists.


## Dot Product

We will now implement a module that computes the [dot product](https://en.wikipedia.org/wiki/Dot_product) of two vectors. Look at the ports declared in `src/dot_product.v`.
In particular, note that:

- It has input and output ready-valid interfaces.
- The module expects to be fed with two input vectors (`a` and `b`) element by element.
- The `len` input indicates vector length. Vectors can be a maximum of `32` elements long (although this is parametrized through `WIDTH`).
- Elements from either vector can be fed concurrently.
- All elements from both vectors should be stored in the SRAM prior to computation.
- The SRAM is logically partitioned for each vector, with the vector `a` stored in the top half of the address range and the vector `b` stored in the bottom half of the address range. In other words, given that the vector index is zero-indexed, the i<sup>th</sup> entry of `a` should be stored at address `i` in the SRAM; the i<sup>th</sup> entry of `b` should be stored at address `32+i` in the SRAM.
- You should compute the dot product and provide it on the output ready-valid interface.

Note that the SRAM can only perform one operation per cycle. So if both `a` and `b` have data ready to be written, you would need to write `a` to the SRAM in one cycle, then write `b` the next cycle (or vice versa).

You should create a 3-state FSM to orchestrate the dot product:
- `RECV` - the idle state; the FSM should accept inputs from `a` and `b` and store them in the SRAM.
- `CALC` - your FSM should calculate the dot product with the data from SRAM.
- `SEND` - your module should sit idle until the dot product result is read.

**Your dot product should spend `2*(len+1)` cycles in the CALC state. You should not instantiate more than 1 SRAM.**

To run RTL simulation, run the following command:

```shell
make sim-rtl
```

Ensure all tests pass. To inspect the RTL simulation waveform, run the following commands:

```shell
cd build/sim-rundir
qhsim -do "vsim -view build/sim-rundir/vsim.wlf"
```

## Place and Route Example

We will now run synthesis and PAR on your design:

```shell
make syn
make syn-to-par
make redo-par HAMMER_EXTRA_ARGS="-p build/sram_generator-output.json --stop_after_step extraction"
make redo-par HAMMER_EXTRA_ARGS="-p build/sram_generator-output.json --start_before_step extraction"
```

After PAR finishes, you can open the floorplan of the design by running:

```shell
cd build/par-rundir
./generated-scripts/open_chip --timing
```

This will launch *OpenROAD* GUI and load your final design database.
This floorplan has one SRAM instance called `sram`.
The placement constraints for that SRAM were given in the file `design.yml`.
You can look at `build/par-rundir/floorplan.tcl` to see how Hammer translated these constraints into OpenROAD floorplanning commands.
Note that generally you should:

- Always generate a placement constraint for hard macros like SRAMs, because OpenROAD might not able to auto-place them in a valid location most of the time.
- Ensure that the hierarchical path to the macro instance is specified correctly; otherwise, OpenROAD will not know what to place.
- Pre-calculate valid locations for the macros. This could involve:
    - Looking at the LEF file to find out its width and height (e.g., 279.45um × 269.21um for `sram22_64x32m4w8`) to make sure it fits within the core boundary/desired area.
    - Legalizing the x and y coordinates. These generally need to be a multiple of a technology grid to avoid layout rule violations. The most conservative rule of thumb is a multiple of the site height (height of a standard cell row, which is 2.72um in this technology).
    - Ensuring that the macros receive power. You can see that the SRAMs in the layout above are placed beneath the met4 power straps. This because the SRAM's power pins are on met3.

You can play around with those constraints to change the SRAM placement to a geometry you like.
If you change the placement constraint only in `design.yml` and only want to redo PAR (skipping synthesis), you can run:

```shell
make redo-par HAMMER_EXTRA_ARGS='-p build/sram_generator-output.json -p cfg/design.yml --stop_after_step extraction'
make redo-par HAMMER_EXTRA_ARGS='-p build/sram_generator-output.json -p cfg/design.yml --start_before_step extraction'
```

Finally, we will perform post-PAR gate-level simulation.

```shell
make sim-gl-par
```

All tests should pass as in the case of RTL simulation. SDF annotation warnings for SDF instance is expected

Theoretically, if you don't have any setup/hold time violations, your post-PAR gate-level simulation should pass.
However, when you are pushing the timing constraints to the design's limit or not specifying them well enough, the gate-level simulation may not pass.


## Questions

Solutions for lab questions should be submitted electronically using **GitHub**. Submit your answers to the following questions by writing the corresponding answers to `ans/Q*/Q*.md` (use the `ans/Q*/` directory for additional files) files and performing a `git commit` and  `git push`. Feel free to use [Markdown](https://www.markdownguide.org/cheat-sheet/) for formatting. When you finish with the lab exercise, please `git tag` your last commit with the tag name *lab5* in order to mark the deliverable. **Otherwise, the last commit before the lab due date will be chosen as the deliverable.**

Also, remember to include a short explanation of each answer (2-4 sentences) with your responses to the lab questions. When asked to write Verilog, include the module definition. There is no single solution, so individual solutions will vary. **Collaboration is fine, but your solution should be your own.**


### Question 1: Understanding SRAMs

For this question, you may find it convenient to reference the `~/sram22_sky130_macros` directory, which, again, stores all the SRAM variants that should be directly supported in our tool flow.
The [SRAM22](https://github.com/rahulk29/sram22) documentation may also be helpful.

a) Open the `sram22_sky130_macros` directory. How many SRAM sizes are available?
Pick one size and describe what each number in the name of the macro means.

b) Look at one of the SRAM Verilog model (*.v) files.
Based on the model, what happens to the `dout` port when a write operation is performed?
Note that other SRAM designs may have different behavior.

c) Open one of the SRAM abstract (`*.lef`) files.
Where are the pins located? Which layer are t           hey on? What layer are the power straps on?
To verify, you can open LEFs in the KLayout GUI, by typing:

```shell
~/.conda-klayout/bin/klayout ~/sram22_sky130_macros/sram22_64x32m4w8/sram22_64x32m4w8.lef
```

d) *(Ungraded thought experiment #1)* SRAM libraries in real process technologies are much larger than the list you see in the build directory.
What features do you think are important for real SRAM libraries?
Think in terms of the number of ports, masking, improving yield, or anything else you can think of.
What would these features do to the size of the SRAM macros?

e) *(Ungraded thought experiment #2)* SRAMs should be integrated very densely in a circuit's layout.
To build large SRAM arrays, oftentimes many SRAM macros are tiled together, abutted on one or more sides.
Knowing this, take a guess at how SRAMs are laid out.

    i) In SKY130, there are only 5 metal layers, but realistically only 4 layers to route on in order to leave the top layer for power distribution, as you saw in Lab 4. How many layers should a well-designed SRAM macro use (i.e. block off from PAR routing), at maximum?

    ii) Where should the pins on SRAMs be located if you want to maximize the ability for them to abut together?


### Question 2: Performance and Area Optimization

a) Open your final design's floorplan.
Identify one or more locations where the SRAM is connected to power and ground, and submit a screenshot.

b) Find the maximum clock frequency that gives no timing violations for your design, to the nearest 0.2 ns (slack < 0.2 ns).
Report the final frequency and describe (in English or Serbian) the critical path.
Submit Questa transcript output from running `make sim-gl-par`, showing that you pass all tests using your post-PAR design.
Also commit the *rcx_sta.checks.max.setup.rpt*, *rcx_sta.checks.min.hold.rpt*, and *dot_product_route_drc.rpt* reports.
Note that you'll need to update the `CLOCK_PERIOD` in `sim-gl-par.yml` to match the frequency at which you ran synthesis/PAR.

c) The floorplan we've given you has lots of empty space.
Revert the `CLOCK_PERIOD` to its default value and adjust the SRAM position and design area bounds to reduce the overall area of your design by 1/4.
Make sure that your design is still passing timing, DRC check and post-layout simulation.
Report the final area used, the SRAM macro position, and submit a screenshot of your post-PAR layout with the *dot_product_route_drc.rpt* loaded in the DRC Viewer.

d) How many cycles does your dot product module take for each of the test cases?
Describe two ways to reduce the total cycle count.
You don't need to implement these changes.
You are free to make reasonable modifications to the structure of the problem (e.g., you can change the inputs to be something other than ready/valid interfaces).
