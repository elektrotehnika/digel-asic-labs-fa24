# ASIC Lab 3: Logic Synthesis


## Table of Contents
- [ASIC Lab 3: Logic Synthesis](#asic-lab-3-logic-synthesis)
    - [Table of Contents](#table-of-contents)
    - [Overview](#overview)
    - [What is Synthesis?](#what-is-synthesis)
        - [Introduction to Static Timing Analysis](#introduction-to-static-timing-analysis)
            - [Yosys Disadvantages](#yosys-disadvantages)
    - [Synthesis Environment](#synthesis-environment)
        - [Interpreting the YAML files](#interpreting-the-yaml-files)
            - [Interpreting the YAML: *design.yml*](#interpreting-the-yaml-designyml)
            - [Interpreting the YAML: *sim-rtl.yml*](#interpreting-the-yaml-sim-rtlyml)
    - [Handshaking](#handshaking)
    - [The Example Design: GCD](#the-example-design-gcd)
    - [RTL-Simulation](#rtl-simulation)
    - [Synthesize An Example Design: GCD](#synthesize-an-example-design-gcd)
        - [Hammer and Genus Relationship](#hammer-and-genus-relationship)
        - [TCL?](#tcl)
        - [Reports](#reports)
    - [Post-Synthesis Simulation](#post-synthesis-simulation)
    - [Build A Parameterized Divider](#build-a-parameterized-divider)
        - [Write the Design](#write-the-design)
        - [Verify Functionality with an RTL simulation](#verify-functionality-with-an-rtl-simulation)
        - [Synthesize Your Design](#synthesize-your-design)
    - [Questions](#questions)
        - [Question 1: Understanding the Algorithm](#question-1-understanding-the-algorithm)
        - [Question 2: GCD Reports Questions](#question-2-gcd-reports-questions)
        - [Question 3: GCD Synthesis Questions](#question-3-gcd-synthesis-questions)
        - [Question 4: Delay Questions](#question-4-delay-questions)
        - [Question 5: Synthesized Divider](#question-5-synthesized-divider)


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
cd lab3
# Replace <hammer_path> with your Hammer installation path
sed -i "s;HAMMER_PATH;<hammer_path>;g" Makefile
sed -i "s;HAMMER_PATH;<hammer_path>;g" cfg/sky130.yml
sed -i "s;~;$HOME;g" cfg/sky130.yml
```
**Objective:** 
This lab will cover logic synthesis. You were briefly introduced to the concept in lab 2 but were given all the output products and asked to analyze them. In this lab, you will complete synthesis yourself for two small designs: (1) an example design provided to you and (2) a design you create yourself. The steps and skills learned to synthesize these designs can be applied to larger, more complex designs (i.e., accelerators or full SoCs).

**Topics Covered:**

- Logic Synthesis
- CAD Tools (emphasis on *Yosys*)
- Hammer
- Skywater 130nm PDK
- Behavioral RTL Simulation
- Reading Reports

**Recommended Reading:**

- [Verilog Primer](../lab2/doc/Verilog_Primer_Slides.pdf)
- [Hammer-Flow](https://hammer-vlsi.readthedocs.io/en/latest/Hammer-Flow/index.html)
- [Ready-Valid Interface](./doc/ready_valid_interface.pdf)


## What is Synthesis?

Synthesis is the transformation of RTL, typically Verilog or VHDL, into a gate-level netlist. A synthesized gate-level Verilog netlist only contains cells! These cells are from the PDK, which provides for each cell: a transistor-level schematic with transistor sizes provided, a physical layout containing information necessary for fabrication, timing libraries providing performance specifications, HDL simulation models, etc.

*Yosys* is the tool used to perform synthesis in this class.
The first step in this process is the compilation and elaboration of RTL [1].
From [IEEE Std 1800-2017](https://ieeexplore.ieee.org/document/8299595), **compilation** is the process of reading RTL and analyzing it for syntax and semantic errors.
**Elaboration** is the subsequent process of expanding instantiations and hierarchies, parsing parameter values, and establishing netlist connectivity.
Elaboration, followed by generic synthesis, returns a generic netlist formed from generic gates.
"Generic" in this context means that the design is represented structurally in terms of gates such as `\$_SDFF_PP0_` and `\$_NOR_` and that these gates have no physical correlation to the gates provided in the standard cell library associated with a technology (or PDK).


### Introduction to Static Timing Analysis

**Static Timing Analysis (STA)** is the validation of timing performance through the analysis of timing arcs for violations.
Broadly, this involves identifying timing arcs, calculating propagation delays, and checking for setup and hold time violations.
In this section, basic delay considerations are discussed through the inspection of file fragments, and rudimentary timing analysis is introduced in accompanying exercises.
We will be analyzing two sections of a [Liberty](https://wiki.f-si.org/index.php/Standard-cell_characterization#Liberty_File_Format) (or *.lib*) file, taken from the [ASAP7](https://github.com/The-OpenROAD-Project/asap7) instructional PDK timing library.

Now, two classes of delays, **cell delays** and **net delays**, are presented.
First, consider a fragment of the **cell delay** model for a simple buffer (`A` is the input, `Y` is the output).
Inspect the fragment starting from `pin(Y)`. Examining the `timing()` relation reveals a table detailing the `cell_rise` based on a template `delay_template_7x7_x1`.
That is to say, the **cell rise time** (delay through a cell) is given by a 2D lookup of **input net transition** and cell **output capacitance**.
Additionally, observe that the `timing_sense` is defined as **positive unate**.
That is, the timing arc is defined from rising input to rising (or nonchanging) output.
While it is impossible to describe the complete capabilities of timing libraries short of copying entire standards, readers should be able to perform inspection and analysis on such files as needed.

    lu_table_template (delay_template_7x7_x1) {
      variable_1 : input_net_transition;
      variable_2 : total_output_net_capacitance;
      index_1 ("5, 10, 20, 40, 80, 160, 320");
      index_2 ("0.72, 1.44, 2.88, 5.76, 11.52, 23.04, 46.08");
    }

    ....
      pin (Y) {
        direction : output;
        function : "A";
        power_down_function : "(!VDD) + (VSS)";
        related_ground_pin : VSS;
        related_power_pin : VDD;
        max_capacitance : 368.64;
        output_voltage : default_VDD_VSS_output;
        timing () {
          related_pin : "A";
          timing_sense : positive_unate;
          timing_type : combinational;
          cell_rise (delay_template_7x7_x1) {
            index_1 ("5, 10, 20, 40, 80, 160, 320");
            index_2 ("5.76, 11.52, 23.04, 46.08, 92.16, 184.32, 368.64");
            values ( \
              "16.3122, 18.9302, 23.4928, 31.8294, 47.9742, 80.0606, 144.088", \
              "17.7082, 20.3463, 24.858, 33.2468, 49.3778, 81.4822, 145.567", \
              "20.3545, 22.9433, 27.4932, 35.8118, 51.9385, 84.0089, 148.036", \
              "24.3952, 27.0398, 31.6149, 39.9636, 56.036, 88.0888, 152.111", \
              "29.3454, 32.0006, 36.6138, 45.0047, 61.1147, 93.221, 156.998", \
              "35.5151, 38.3592, 43.2204, 51.6798, 67.7266, 99.5716, 163.503", \
              "41.9998, 45.0837, 50.305, 59.1205, 75.1338, 107.432, 171.049" \
            );
          }

Now consider **wire (net) delays**.
The following fragment is fabricated for instructional purposes.
Despite being fictional, this model is in fact instructive.
Based on the enclosure area of a net, a `wire_load` macro model is chosen.
Multipliers from the macro model are used to scale resistance values (ohms) and capacitance values (fF) based on cell fanout.
Combining this information allows RC delays to be determined.
Because wireload modeling is statistically driven, use of such models often yields pessimistic results.
To improve results, some companies have replaced wireload models from the foundry with wireload models derived from their own designs and observed activities.

    wire_load(10X10) {
      resistance : 6.00 ;
      capacitance : 1.30 ;
      area : 0.08 ;
      slope : 0.05 ;
      fanout_length(1, 2.0000);
      fanout_length(2, 3.2000);
      fanout_length(3, 3.4000);
      fanout_length(4, 4.1000);
      fanout_length(5, 4.6000);
      fanout_length(6, 5.1000);
    }
    default_wire_load_mode : enclosed ;


Beyond this, there are a slew of other STA topics, including correlated clocks, jitter, insertion delays, etc., but these are ignored for now.


#### Yosys Disadvantages

Unfortunately, unlike its proprietary alternatives, the tool we use for synthesis, Yosys, currently lacks the support for STA and SDF generation, which is a requirement for timing-annotated gate-level simulation. That is why, in this lab, we are going to be using OpenROAD for the generation of the post-synthesis SDF file and additional useful reports.


## Synthesis Environment

To perform synthesis, we will be using *Yosys*. However, we will not be interfacing with *Yosys* directly; we will rather use Hammer. Just like in lab 2, we have set up the basic Hammer flow for your lab exercises using a Makefile.

In this lab repository, you will see two sets of input files for Hammer:
1. Source code in the *src* directory, explored in the next section
2. YAML files used for Hammer inputs in the *cfg* directory
    - *sky130.yml* - Configures technology and tool settings for design flow
    - *design.yml* - Settings for this particular design
    - *sim-rtl.yml* - Settings for simulating an RTL simulation of this design
    - *sim-gl-syn.yml* - Settings for simulating a gate-level simulation of this design


### Interpreting the YAML files

For this lab, it is important to realize the differences and similarities between the YAML files supporting synthesis and simulation, *design.yml* and *sim-rtl.yml*, respectively.

#### Interpreting the YAML: *design.yml*
---
Let's examine the details of the *design.yml* file.

When you synthesize a design, you tell the tools the expected clock frequency at which you anticipate the design will be run, or the *target frequency*. The line below creates the variable `CLK_PERIOD` to be used within the YAML file and assigns to it the target clock period (which indirectly specifies the frequency) for our design (20 ns).

```yaml
gcd.clockPeriod: &CLK_PERIOD "20ns"
```

The target clock frequency directly impacts the effort of the synthesis tools. Targeting higher clock frequencies will make the tool work harder and force it to use higher-power gates to meet the constraints. A lower target clock frequency allows the tool to focus on reducing area and/or power.

Next, we create the variable `VERILOG_SRC` for all the source files that contain the design.

```yaml
gcd.verilogSrc: &VERILOG_SRC
  - "src/gcd.v"
  - "src/gcd_datapath.v"
  - "src/gcd_control.v"
  - "src/EECS151.v"
```

This is where we specify to Hammer that we intend to use the `CLK_PERIOD` we defined earlier, as the constraint for our design. We will see more detailed constraints in later labs.

```yaml
vlsi.inputs.clocks: [
  {name: "clk", period: *CLK_PERIOD, uncertainty: "0.1ns"}
]
```

#### Interpreting the YAML: *sim-rtl.yml*
---
The *sim-rtl.yml* is used only for simulation. However, it provides similar settings as *design.yml* did for synthesis.

The snippet below sets the target frequency only for simulation. It is generally useful to separate the two, as you might want to see how the circuit performs under different clock frequencies without changing
the design constraints.

```yaml
defines:
  - "CLOCK_PERIOD=20.00"
```

The snippet below shows where we list the input files for simulation. What's different between this list and the list in *design.yml*?

```yaml
sim.inputs:
  input_files:
    - "src/gcd.v"
    - "src/gcd_datapath.v"
    - "src/gcd_control.v"
    - "src/gcd_testbench.v"
    - "src/EECS151.v"
```


## Handshaking

A critical aspect of designing complex circuits with Verilog is the inter-module synchronization between a producer and a consumer.
"Handshaking" describes the negotiation process between two modules to exchange information; one module (producer) initiates a transaction, and the other module (consumer) agrees to continue with it or indicates it's not ready to continue with another transaction. Handshake protocols have varying levels of complexity; however, the most in digital logic design is a ready-valid interface. Below we describe the simplest ready-valid interface:

<center> 

| Signal  | Description                                                                                               |
|:-------:|-----------------------------------------------------------------------------------------------------------|
| *ready* | signal asserted by the consumer indicating it is '*ready*' to receive data on the *data* signal           |
| *valid* | signal asserted by the producer indicating data on the *data* signal is '*valid*' and should be consumed  |
| *data*  | the data being exchanged between the two modules                                                          |

</center> 

The exact implementation of a ready-valid interface may vary; however, the key idea is that data is only exchanged when both *ready* and *valid* are asserted. This condition specifies an agreement, or the "handshake." **A module can be both a producer and a consumer.** It is important to note that no exchange happens unless both *ready* and *valid* are asserted. Look at *doc/ready_valid_interface.pdf* for more background.


## The Example Design: GCD

We have provided a circuit described in Verilog that computes the greatest common divisor (GCD) of two numbers. The implementation consists of the three modules presented in the table below:

<center> 

| Module          | Description                                                                                |
|:---------------:|--------------------------------------------------------------------------------------------|
| *gcd*           | The top-level module that instantiates *gcd_control* and *gcd_datapath*                    |
| *gcd_control*   | An FSM that handles the ready-valid interface and controls the mux selects in the datapath |
| *gcd_datapath*  | All logic to perform computation (subtraction and comparison)                              |

</center> 

Separating files and logic into control and datapath is generally a good idea due to various reasons:
- Modularity and scalability: Focusing on the data operations and control logic independently simplifies the design process and makes maintaining, updating, verification, and debugging much easier.
- Reusability and parallelism: Datapath components can be reused across different designs and also designed to exploit parallelism, which enhances efficiency and improves performance.
- Optimization and efficiency: Synthesis can apply different optimizations to the datapath (say, for speed and area) and control logic (say, for state minimization) and map RTL code into target technology more efficiently.

Unlike the FIR filter from the last lab, in which the testbench constantly provided stimuli, the GCD algorithm has a variable latency. In other words, the number of cycles for the module to compute the output is **not** constant. This is common for many modules; therefore, they must indicate when the output is valid and when they are ready to receive new inputs. This is accomplished through a ready-valid interface. A block diagram and module declaration of the GCD top level are presented below:

<p align="center">
<img src="figs/block-diagram.png" width="600" />
</p>

```Verilog
module gcd#( parameter W = 16 )
(
  input clk, reset,
  input [W-1:0] operands_bits_A,    // Operand A
  input [W-1:0] operands_bits_B,    // Operand B
  input operands_val,               // Are operands valid?
  output operands_rdy,              // ready to take operands

  output [W-1:0] result_bits_data,  // GCD
  output result_val,                // Is the result valid?
  input result_rdy                  // ready to take the result
);
```


<details markdown='block'>
<summary>GCD Functionality Details</summary>

On the `operands` boundary, nothing will happen until GCD is ready to receive data (`operands_rdy`).
When this happens, the testbench will place data on the operands (`operands_bits_A` and `operands_bits_B`), but GCD will not start until the testbench declares that these operands are valid (`operands_val`).
Then GCD will start.

The testbench needs to know that GCD is not done. This will be true as long as `result_val` is 0 (the results are not valid).
Also, even if GCD is finished, it will hold the result until the testbench is prepared to receive the data (`result_rdy`).
The testbench will check the data when GCD declares the results are valid by setting `result_val` to 1.

The contract is that if the interface declares it is ready while the other side declares it is valid, the information must be transferred.

</details>

## RTL-Simulation

Now simulate the design by running `make sim-rtl`. The waveform is located under `build/sim-rundir/`.
Open the waveform in Questa (`qhsim -do "vsim -view build/sim-rundir/vsim.wlf; add wave * &`).
You may need to open the testbench in the *Source* pane and try to understand how the code works by comparing the waveforms with the Verilog code.
It might help to sketch out a state machine diagram and draw the datapath.

> ### Checkoff 1: Understanding Ready-Valid Handshake
> 1. Explain how the testbench uses the `operands_rdy` and `operands_val` signals to orchestrate the simulation.
> 2. How does *gcd_control* interact with *gcd_datapath*?
> &nbsp;


## Synthesize An Example Design: GCD

In this section, we will look at the steps Hammer takes to get from RTL Verilog to all the outputs we saw in the last section. By default, Hammer places output products of VLSI flow in the *build* subdirectory. 


### Hammer and Yosys Relationship

Hammer abstracts some details of the synthesis process. Let's examine step by step what each step Hammer takes does to gain an intuition of what steps *Yosys* performs:

|    Hammer Steps    | Description                                                                                                                                                                                                                                                                                                                                                                                                                                            |
|:------------------:|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| _init_environment_ | Provides *Yosys* with the technology libraries from the PDK, constraints for the synthesis process (from *cfg/design.yml*), and the source code for our design. Lastly, and critically, this step always commands *Yosys* to elaborate our design.                                                                                                                                                                                                     |
|    _syn_generic_   | This step is the **generic synthesis** step. In this step, *Yosys* converts our RTL read in the previous step into an intermediate format, made up of technology-independent generic gates. These gates are purely for gate-level functional representation of the RTL we have coded and are going to be used as an input to the next step. This step also performs logical optimizations on our design to eliminate any redundant/unused operations.  |
|      _syn_map_     | This step is the **mapping** step. *Yosys* takes its own generic gate-level output and converts it to our SKY130-specific gates. This step further optimizes the design given the gates in our technology. That being said, this step can also increase the number of gates from the previous step, as not all gates in the generic gate-level Verilog may be available for our use, and they may need to be constructed using several, simpler gates. |
|    _add_tieoffs_   | In some designs, the pins in certain cells are hardwired to 0 or 1, which requires a tie-off cell. This step adds these cells.                                                                                                                                                                                                                                                                                                                         |
| _generate_reports_ | Generates post-synthesis reports on area, design hierarchy and statistics, etc.                                                                                                                                                                                                                                                                                                                                                                           |
|   _write_outputs_  | This step writes the outputs of the synthesis flow. This includes the gate-level Verilog file we looked at earlier in the lab. Other outputs include the design constraints (such as clock frequencies, output loads etc., in *.sdc* format) and delays between cells (in *.sdf* format).                                                                                                                                                              |

<!--_write_regs_    | This step is purely for the benefit of the designer. For some designs, we may need to have a list of all the registers in our design. In this lab, the list of regs is used in post-synthesis simulation to generate the `force_regs.ucli`, which sets initial states of registers.-->

Each step listed in the table is a separate step executed when `make syn` is run and represents a step or sequence of steps *Yosys* takes for the full synthesis process. Now, synthesize the design:

1. Generate the *hammer.d* supplement Makefile (you might not have to do this step if you already ran `make sim-rtl`). This was also the first step in lab 2, but in this lab we'll learn what this file is. The *hammer.d* file contains a list of design-specific targets based upon the constraints we have provided inside the YAML files, in our case the GCD. Any of these targets can be run to execute different stages of the VLSI flow (we will take advantage of more targets in future labs). Visit the Hammer Read-The-Docs for more information on the [Hammer-Flow](https://hammer-vlsi.readthedocs.io/en/latest/Hammer-Flow/index.html).

    ```
    make buildfile
    ```

    Running the target also copies and extracts a tarball of the SKY130 PDK to your local workspace. It will take a while to finish if you run this command for the first time. The extracted PDK is not deleted when you do `make clean` to avoid unnecessarily rebuilding the PDK. To explicitly remove it, you need to remove the build folder (and you should do it once you finish the lab to save your allocated disk space since the PDK is huge).

    > **Note**: Currently, Hammer's generation of *build/tech-sky130-cache/* seems a bit buggy and that is why we have a few `cp --update ...` commands present in our Makefile.

2. To synthesize the GCD, call `make` using the synthesis target:

    ```
    make syn
    ```

    This runs through all the steps of synthesis. The generated netlist is located at *build/syn-rundir/gcd.yosys.v*. In the file, there will be instantiation of cells from the PDK. It should look very different from the behavioral Verilog in the source files, but it functions the same. Attempt to follow an input through these gates to see the path it takes until the output. These files can be useful for debugging and evaluating your design.

    > **Note**: You can run each step individually using the following command: `make redo-syn HAMMER_EXTRA_ARGS="--stop_after_step <hammer_step>"`. Substitute `<hammer_step>` with one of the steps listed in the table above.

3. Generate additional STA reports and post-synthesis SDF file by running:

    ```
    make timing-syn
    ```

    This loads the post-synthesis design into OpenROAD, which then generates a basic set of physical design reports (about area, timing, power, etc.) as well as a new but logically equivalent netlist with a corresponding SDF file, all of which can be found at *build/timing-syn-rundir/*. The netlist and the SDF file are also saved at _build/syn-rundir/gcd.mapped.*_.


### TCL?

It should be apparent by now that Hammer isn't a tool itself, but a layer of abstraction that makes utilizing the tools easier. But how does Hammer instruct the tool what to do? It does this by generating a TCL file that contains explicit and verbose commands *Yosys* understands. This is how Hammer operates with all CAD tools: through scripts!

Feel free to see what's behind the curtain and analyze the TCL script Hammer generated for synthesis with *Yosys*. Open the TCL file located at *build/syn-rundir/syn.tcl*. You should see some TCL commands and commands for the steps listed in the section above.


### Reports

The following reports generated as output products of synthesis:
- in *build/syn-rundir*:
    - *gcd.synth_check.rpt*
    - *gcd.synth_stat.txt*
- in *build/timing-syn-rundir/reports*:
    - *gcd_sta.checks.max.setup.rpt*
    - *gcd_sta.checks.min.hold.rpt*
    - *gcd_sta.checks.unconstrained.rpt*
    - *gcd_sta.check_types.delay_skew.rpt*
    - *gcd_sta.check_types.slew_cap_fanout.rpt*
    - *gcd_sta.floating_nets.rpt*
    - *gcd_sta.power.rpt*
    - *gcd_sta.summary.rpt*
    - *gcd_sta.util.rpt*

Go through these files and familiarize yourself with the information these reports provide.

One report of particular note is `gcd_sta.checks.max.setup.rpt`. The name of this file represents that it is a timing report that contains the setup timing checks in maximum delay corner, that is with the Process Voltage Temperature corner of ss(slow-slow) corner, 1.60 V and 100 degrees C. This corner represents the worse operating conditions for a circuit, and provides a quick worse case analysis. Open the `gcd_sta.checks.max.setup.rpt` file and look at the first block of text you see. It should look similar to this:

```text
Startpoint: GCDdpath0/B_register/_70_
            (rising edge-triggered flip-flop clocked by clk)
Endpoint: GCDdpath0/A_register/_73_
          (rising edge-triggered flip-flop clocked by clk)
Path Group: clk
Path Type: max
Corner: setup

Fanout     Cap    Slew   Delay    Time   Description
-----------------------------------------------------------------------------
                  0.00    0.00    0.00   clock clk (rise edge)
                          0.00    0.00   clock network delay (ideal)
                  0.00    0.00    0.00 ^ GCDdpath0/B_register/_70_/CLK (sky130_fd_sc_hd__dfxtp_1)
                  0.10    0.59    0.59 v GCDdpath0/B_register/_70_/Q (sky130_fd_sc_hd__dfxtp_1)
     5    0.01                           GCDdpath0/B_reg[0] (net)
                  0.10    0.00    0.59 v GCDdpath0/_264_/A_N (sky130_fd_sc_hd__nand2b_1)
                  0.11    0.32    0.91 v GCDdpath0/_264_/Y (sky130_fd_sc_hd__nand2b_1)
     2    0.00                           GCDdpath0/_093_ (net)
                  0.11    0.00    0.91 v GCDdpath0/_273_/C (sky130_fd_sc_hd__maj3_1)
                  0.13    0.76    1.68 v GCDdpath0/_273_/X (sky130_fd_sc_hd__maj3_1)
     1    0.00                           GCDdpath0/_102_ (net)
                  0.13    0.00    1.68 v GCDdpath0/_274_/A2 (sky130_fd_sc_hd__a21o_1)
                  0.06    0.33    2.01 v GCDdpath0/_274_/X (sky130_fd_sc_hd__a21o_1)
     1    0.00                           GCDdpath0/_103_ (net)
                  0.06    0.00    2.01 v GCDdpath0/_275_/A2 (sky130_fd_sc_hd__a21oi_1)
                  0.16    0.21    2.22 ^ GCDdpath0/_275_/Y (sky130_fd_sc_hd__a21oi_1)
     1    0.00                           GCDdpath0/_104_ (net)
                  0.16    0.00    2.22 ^ GCDdpath0/_276_/A2 (sky130_fd_sc_hd__o211ai_1)
                  0.15    0.20    2.42 v GCDdpath0/_276_/Y (sky130_fd_sc_hd__o211ai_1)
     1    0.00                           GCDdpath0/_105_ (net)
                  0.15    0.00    2.42 v GCDdpath0/_278_/A2 (sky130_fd_sc_hd__a31oi_1)
                  0.19    0.28    2.71 ^ GCDdpath0/_278_/Y (sky130_fd_sc_hd__a31oi_1)
     1    0.00                           GCDdpath0/_107_ (net)
                  0.19    0.00    2.71 ^ GCDdpath0/_280_/B1 (sky130_fd_sc_hd__o22ai_1)
                  0.11    0.19    2.90 v GCDdpath0/_280_/Y (sky130_fd_sc_hd__o22ai_1)
     1    0.00                           GCDdpath0/_109_ (net)
                  0.11    0.00    2.90 v GCDdpath0/_281_/B (sky130_fd_sc_hd__nand2_1)
                  0.07    0.11    3.01 ^ GCDdpath0/_281_/Y (sky130_fd_sc_hd__nand2_1)
     1    0.00                           GCDdpath0/_110_ (net)
                  0.07    0.00    3.01 ^ GCDdpath0/_283_/A2 (sky130_fd_sc_hd__a21oi_1)
                  0.09    0.12    3.13 v GCDdpath0/_283_/Y (sky130_fd_sc_hd__a21oi_1)
     1    0.00                           GCDdpath0/_112_ (net)
                  0.09    0.00    3.13 v GCDdpath0/_284_/C1 (sky130_fd_sc_hd__a211oi_1)
                  0.29    0.28    3.41 ^ GCDdpath0/_284_/Y (sky130_fd_sc_hd__a211oi_1)
     1    0.00                           GCDdpath0/_113_ (net)
                  0.29    0.00    3.41 ^ GCDdpath0/_285_/B1 (sky130_fd_sc_hd__a41oi_1)
                  0.32    0.18    3.59 v GCDdpath0/_285_/Y (sky130_fd_sc_hd__a41oi_1)
     3    0.01                           A_lt_B (net)
                  0.32    0.00    3.59 v GCDctrl0/_09_/C (sky130_fd_sc_hd__nor4_1)
                  1.45    1.31    4.90 ^ GCDctrl0/_09_/Y (sky130_fd_sc_hd__nor4_1)
     9    0.02                           A_mux_sel[1] (net)
                  1.45    0.00    4.90 ^ GCDdpath0/_186_/SLEEP (sky130_fd_sc_hd__lpflow_isobufsrc_1)
                  0.31    0.52    5.42 v GCDdpath0/_186_/X (sky130_fd_sc_hd__lpflow_isobufsrc_1)
     4    0.01                           GCDdpath0/_036_ (net)
                  0.31    0.00    5.42 v GCDdpath0/_212_/A (sky130_fd_sc_hd__lpflow_clkbufkapwr_1)
                  0.26    0.43    5.85 v GCDdpath0/_212_/X (sky130_fd_sc_hd__lpflow_clkbufkapwr_1)
    10    0.02                           GCDdpath0/_060_ (net)
                  0.26    0.00    5.85 v GCDdpath0/_303_/A2 (sky130_fd_sc_hd__a222oi_1)
                  0.40    0.60    6.45 ^ GCDdpath0/_303_/Y (sky130_fd_sc_hd__a222oi_1)
     1    0.00                           GCDdpath0/_127_ (net)
                  0.40    0.00    6.45 ^ GCDdpath0/_304_/A (sky130_fd_sc_hd__inv_1)
                  0.09    0.16    6.61 v GCDdpath0/_304_/Y (sky130_fd_sc_hd__inv_1)
     1    0.00                           GCDdpath0/A_next[3] (net)
                  0.09    0.00    6.61 v GCDdpath0/A_register/_44_/A1 (sky130_fd_sc_hd__mux2i_1)
                  0.18    0.21    6.82 ^ GCDdpath0/A_register/_44_/Y (sky130_fd_sc_hd__mux2i_1)
     1    0.00                           GCDdpath0/A_register/_22_ (net)
                  0.18    0.00    6.82 ^ GCDdpath0/A_register/_45_/B (sky130_fd_sc_hd__nor2_1)
                  0.10    0.10    6.92 v GCDdpath0/A_register/_45_/Y (sky130_fd_sc_hd__nor2_1)
     1    0.00                           GCDdpath0/A_register/_03_ (net)
                  0.10    0.00    6.92 v GCDdpath0/A_register/_73_/D (sky130_fd_sc_hd__dfxtp_1)
                                  6.92   data arrival time

                  0.00   20.00   20.00   clock clk (rise edge)
                          0.00   20.00   clock network delay (ideal)
                         -0.10   19.90   clock uncertainty
                          0.00   19.90   clock reconvergence pessimism
                                 19.90 ^ GCDdpath0/A_register/_73_/CLK (sky130_fd_sc_hd__dfxtp_1)
                         -0.30   19.60   library setup time
                                 19.60   data required time
-----------------------------------------------------------------------------
                                 19.60   data required time
                                 -6.92   data arrival time
-----------------------------------------------------------------------------
                                 12.68   slack (MET)
```

This is one of the most common ways to assess the critical paths in your circuit.
The setup timing report lists each timing path's **slack**, which is the extra delay the signal can have before a setup violation occurs, in ascending order.
The first block indicates the critical path of the design.
Each three rows represent a timing path from a gate to the next (with wiring in between), and the whole block is the **timing arc** from *Startpoint* to *Endpoint* (usually between two flip-flops, or in some cases latches, ports or a mix of the former).
The `MET` at the bottom of the block indicates that the timing requirements have been met and there is no violation. If there was a violation, this indicator would have read `VIOLATED`.
Since our critical path meets the timing requirements with a 12.68 ns of slack, this means we can run this synthesized design with a period equal to clock period (20000 ps) minus the critical path slack (12680 ps), which is 7320 ps.


> ###  Checkoff 2: Synthesis Understanding 
> Demonstrate that your synthesis flow works correctly, and be prepared to explain the synthesis steps at a high level.
> 1. Describe the process of logic synthesis at a high level.
> 2. Where do the cells/gates used for synthesis process come from?
> 3. What are the sub-steps elaboration and syn_generic?
> 4. What is the output of synthesis?
> 5. What is slack?
> &nbsp;


## Post-Synthesis Simulation

From the *lab3* folder, type the following command:

    ```
    make sim-gl-syn
    ```

This will run a post-synthesis simulation using annotated delays from the `gcd.mapped.sdf` file.


## Build A Parameterized Divider

In this section, you will build a parameterized divider of unsigned integers. You have two goals:

1. Write the RTL for the design.
2. Verify functionality with an RTL simulation.
3. Synthesize your design.


### Write the Design

Some initial code in the *src* directory (*divider.v* and *divider_testbench.v*) has been provided to help you get started. To keep the control logic simple, we provide the following specification for you to follow:

- Inputs:
    - `start` - a 1-bit input that, when asserted, begins computation on the ***next*** clock cycle
    - `dividend` - the dividend with a parameterized bit width
    - `divisor` - the divisor with a parameterized bit width
- Outputs:
    - `done` - a 1-bit output asserted when the division result is valid
- The `dividend` and `divisor` inputs should be registered when `start` is HIGH.
- Extras:
    - You are not required to handle corner cases such as dividing by 0.
    - You are free to modify the skeleton code to implement a ready/valid interface instead, but it is not required.

It is suggested that you implement the divide algorithm described [here](doc/divider_algorithms.pdf). You can choose to use **Divider Algorithm 1** (slide 4) or **Divider Algorithm 2** (slide 9). Note: The diagram for **Divider Algorithm 2** is slightly incorrect (the box labeled **1.** should be ignored). It may help to go through the algorithms by hand first and then implement them in hardware.


### Verify Functionality with an RTL Simulation

A simple testbench skeleton is also provided to you. You should change it to add more test vectors or test your divider with different bit widths. You need to change the file *sim-rtl.yml* to use your divider instead of the GCD module when testing.


### Synthesize Your Design

To exercise your skills understanding synthesis and how to interact with *Yosys* using Hammer, synthesize your design at two separate design points:

1. Instantiate your divider to be a 4-bit divider and synthesize it. Copy all post-syntesis reports to `ans/Q5/rpt4` directory.
2. Instantiate your divider to be a 32-bit divider and synthesize it. Copy all post-syntesis reports to `ans/Q5/rpt32` directory.

Refer to the YAML files and general flow from the GCD example design.


## Questions

Solutions for lab questions should be submitted electronically using **GitHub**. Submit your answers to the following questions by writing the corresponding answers to `ans/Q*/Q*.md` (use the `ans/Q*/` directory for additional files) files and performing a `git commit` and  `git push`. Feel free to use [Markdown](https://www.markdownguide.org/cheat-sheet/) for formatting. When you finish with the lab exercise, please `git tag` your last commit with the tag name *lab3* in order to mark the deliverable. **Otherwise, the last commit before the lab due date will be chosen as the deliverable.**

Also, remember to include a short explanation of each answer (2-4 sentences) with your responses to the lab questions. When asked to write Verilog, include the module definition. There is no single solution, so individual solutions will vary. **Collaboration is fine, but your solution should be your own.**


### Question 1: Understanding the Algorithm

Hint: Look up the Euclidean algorithm for calculating GCD if you're stuck.

By reading the provided Verilog code and/or viewing the RTL simulations, demonstrate that you understand the provided code.

1. Draw a table with 5 columns (cycle number, value of A_reg, value of B_reg, A_next, B_next) and fill in all of the rows for the first test vector (GCD of 27 and 15). Count the cycle number from 0 when `operands_rdy` and `operands_val` are 1. Fill in the table until the first test vector is done and upload a screenshot of the table. Use decimal numbers instead of binary or hex. Hint: It might be easier to view the waveforms instead of tracing the code. Hint: Take a look starting at 140 ns.

    | Cycle number | A_reg | B_reg | A_next | B_next |
    |:------------:|:-----:|:-----:|:------:|:------:|
    | 0            | 0     | 0     | 27     | 15     |
    | 1            |       |       |        |        |
    | 2            |       |       |        |        |
    | 3            |       |       |        |        |
    | ...          |       |       |        |        |

2. In `src/gcd_testbench.v`, the inputs are changed on the negative edge of the clock to prevent hold time violations. Is the output checked on the positive edge of the clock or the negative edge of the clock? Why?

3. In `src/gcd_testbench.v`, what will happen if you change `result_rdy = 1;` to `result_rdy = 0;`? What state will the `gcd_control.v` state machine be in?


### Question 2: GCD Reports Questions

1. Which report would you look at to find the total number of each different standard cell that the design contains?
   
2. Which report contains area breakdowns by modules in the design?

3. What is the total power consumption of the design? Which types of power are reported?

4. Open `build/syn-rundir/gcd.yosys.v`. What standard cell is used for `A_register/q_reg[7]`? Commit the entire instantiated cell.

5. *(optional)* Can you find the exact same cell instantiated in `build/syn-rundir/gcd.mapped.v`?


### Question 3: GCD Synthesis Questions

1. Reduce the clock period (in `design.yml`) by the amount of slack in the timing report. Now run the synthesis flow again. Does it still meet timing? Why or why not? Does the critical path stay the same? If not, what changed?

2. *(optional)* Looking at the total number of instances of sequential cells synthesized and the number of `reg` definitions in the Verilog files, are they consistent? If not, why? What is the total number of flip-flops in the design?


### Question 4: Delay Questions

Load the post-synthesis simulation waveforms in Questa.

1. Report the clk-q delay of `state[0]` in `GCDctrl0` at 350 ns and submit a screenshot of the waveform(s) showing how you found this delay.

2. Which line in the SDF file specifies this delay, and what is the delay? Commit the line, CELLTYPE, INSTANCE and DELAY description.

3. Is the delay from the waveform the same as from the SDF file? Why or why not?


### Question 5: Synthesized Divider

1. From the reports of your 4-bit synthesized divider, determine its:
   - critical path and the slack
   - total cell area
   - maximum operating frequency in MHz from the reports (you might need to rerun synthesis multiple times to determine the maximum achievable frequency)

2. From the reports of your 32-bit synthesized divider, determine its:
   - critical path and the slack
   - total cell area
   - maximum operating frequency in MHz from the reports (you might need to rerun synthesis multiple times to determine the maximum achievable frequency)

3. Commit your divider code and testbench to `ans/Q5/src` and all relevant YAML files to `ans/Q5/cfg`. Add comments to explain your testbench and why it provides sufficient coverage for your divider module. You don't have to run post-synthesis simulation for Question 5. That is, run `make sim-rtl` to verify your testbench. For this question, points will be given not only for design functionality but also for code/comment clarity and conciseness.

