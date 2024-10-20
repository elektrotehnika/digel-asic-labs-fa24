# Digital electronics fall 2024 ASIC labs (asic-labs-fa24)

Welcome to the repository for Digital electronics fall 2024 ASIC labs! This repository will contain all the information you need to complete lab exercises. If you are just getting started make sure to see the [Setup](#Setup) section to create your environment.

## Lab Due Dates

All labs must be checked off **before** your next lab session.

| Lab |    Start Date     |    Due Date     |
|:---:|:-----------------:|:---------------:|
|  1  |  not after 10/25  | 11/04 (11:59pm) |
|  2  |  not after 11/05  | 11/18 (11:59pm) |
|  3  |  not after 11/19  | 12/02 (11:59pm) |
|  4  |  not after 12/03  | 12/16 (11:59pm) |
|  5  |  not after 12/17  | 12/30 (11:59pm) |


## Digital ASIC Design

A high-level digital design flow chart is shown below.

<!-- Design Flow image -->
<figure align="center">
  <img src="./figs/DesignAbstractions.png" style="width:80%">
  <!--<figcaption>Image borrowed from: https://www.vlsiuniverse.com/complete-asic-design-flow/</figcaption> -->
</figure>

Here is a more detailed physical design flow chart.

<!-- ASIC Design Flow image -->
<figure align="center">
  <img src="./figs/RTL_PhysicalDesign.png" style="width:80%">
  <!-- <figcaption>Image borrowed from: https://www.vlsiuniverse.com/complete-asic-design-flow/</figcaption> -->
</figure>

This flow chart shows many of the individual stages digital designers follow in industry. However, it does not show the cyclical nature between individual stages. For example, a bug discovered in *Post-P&R Sim* can provoke *RTL Design* modifications. In general, problems discovered in the **backend** (flow steps after *Synthesis*) sometimes require changes in the **frontend** (flow steps up to *Synthesis*) . Therefore, it is imperative that you are well-versed in the mechanics of simulating your designs before even designing anything!

Anyhow, the principal stages to pay attention for now are: *RTL Design*, *Synthesis*, *Place & Route*.


### (E)CAD Tools

Going through the design flow is quite labor intensive and intricate. In general, computer-aided design (CAD) software tools refer to programs used to reduce the burden of manually performing each stage of a design flow. Electronic design automation (EDA), or electronic computer-aided design (ECAD), tools are specifically created to aid in integrated circuit design flows.

The three major CAD companies for ASIC design are: *Cadence*, *Synopsys*, and *Siemens*. Each of these companies supplies tools for all stages of the Very Large-Scale Integration (VLSI) flow (VLSI refers to complex ICs with thousands or more trasistors). Also, over the last few years, open-source EDA tools are also being developed and they are becoming more and more powerful and can be utilized to create functional chips.

Commonly used EDA tools currently available for ASIC design can be found in the table below.

<style type="text/css">
.tg  {border-collapse:collapse;border-spacing:0;}
.tg td{border-color:black;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;
  overflow:hidden;padding:10px 5px;word-break:normal;}
.tg th{border-color:black;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;
  font-weight:normal;overflow:hidden;padding:10px 5px;word-break:normal;}
.tg .tg-c3ow{border-color:inherit;text-align:center;vertical-align:top}
</style>
<table class="tg", align="center">
<thead>
  <tr>
    <th class="tg-c3ow">**Vendor**</th>
    <th class="tg-c3ow">Synopsys</th>
    <th class="tg-c3ow">Cadence</th>
    <th class="tg-c3ow">Siemens</th>
    <th class="tg-c3ow">Open-source</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td class="tg-c3ow">**Simulation**</td>
    <td class="tg-c3ow"><span style="font-style:italic">VCS</span></td>
    <td class="tg-c3ow"><span style="font-style:italic">Xcelium Logic Simulator</span></td>
    <td class="tg-c3ow"><span style="font-style:italic">Model Sim/Questa Sim</span></td>
    <td class="tg-c3ow"><span style="font-style:italic">Verilator/Icarus</span></td>
  </tr>
  <tr>
    <td class="tg-c3ow">**Synthesis**</td>
    <td class="tg-c3ow"><span style="font-style:italic">FusionCompiler (Design Complier)</span></td>
    <td class="tg-c3ow"><span style="font-style:italic">Genus</span></td>
    <td class="tg-c3ow"><span style="font-style:italic">-</span></td>
    <td class="tg-c3ow"><span style="font-style:italic">Yosys</td>
  </tr>
  <tr>
    <td class="tg-c3ow">**Place and Route**</td>
    <td class="tg-c3ow"><span style="font-style:italic">FusionCompiler (IC Compiler II)</span></td>
    <td class="tg-c3ow"><span style="font-style:italic">Innovus</span></td>
    <td class="tg-c3ow"><span style="font-style:italic">-</span></td>
        <td class="tg-c3ow"><span style="font-style:italic">OpenROAD</td>
  </tr>
  <tr>
    <td class="tg-c3ow">**Physical Layout**</td>
    <td class="tg-c3ow"><span style="font-style:italic">Custom Compiler </span></td>
    <td class="tg-c3ow"><span style="font-style:italic">Virtuoso Layout Suite</span></td>
    <td class="tg-c3ow"><span style="font-style:italic">L-Edit</span></td>
    <td class="tg-c3ow"><span style="font-style:italic">Magic/Klayout</span></td>
  </tr>
  <tr>
    <td class="tg-c3ow">**DRC and LVS**</td>
    <td class="tg-c3ow"><span style="font-style:italic">IC Validator</span></td>
    <td class="tg-c3ow"><span style="font-style:italic">Virtuoso Layout Suite</span></td>
    <td class="tg-c3ow"><span style="font-style:italic">Calibre</span></td>
    <td class="tg-c3ow"><span style="font-style:italic">Magic/Klayout,Netgen</span></td>
  </tr>
  <tr>
    <td class="tg-c3ow">**Verification and Signoff**</td>
    <td class="tg-c3ow"><span style="font-style:italic">NanoTime</span></td>
    <td class="tg-c3ow"><span style="font-style:italic">Virtuoso Layout Suite</span></td>
    <td class="tg-c3ow"><span style="font-style:italic">Calibre</span></td>
    <td class="tg-c3ow"><span style="font-style:italic">Magic/Klayout</span></td>
  </tr>
  <tr>
    <td class="tg-c3ow">**Power**</td>
    <td class="tg-c3ow"><span style="font-style:italic">Prime Power</span></td>
    <td class="tg-c3ow"><span style="font-style:italic">Voltus</span></td>
    <td class="tg-c3ow"><span style="font-style:italic">-</span></td>
    <td class="tg-c3ow"><span style="font-style:italic">-</span></td>
  </tr>
</tbody>
</table>

It is common to utilize different tools for different stages of the design flow. This is possible because the tools typically write out common interchange file formats that can be consumed by other vendors’ tools, or they provide utilities such that files can be converted to different formats. For example, a design may use Synopsys *VCS* for simulation, Cadence *Genus* and *Innovus* for synthesis and place-and-route, respectively, and Mentor *Calibre* for DRC and LVS.

However, these tools are proprietary and the licenses for their usage can be quite expensive. The leading open-source alternative, the foundational application for semiconductor digital design is the [OpenROAD](https://theopenroadproject.org/) project. Its goal is: *"24-hour, No-Human-In-The-Loop layout design for SOC with no Power-Performance-Area (PPA) loss Tapeout-capable tools in source code form, with permissive licensing"*. It contains a set of tools capable of rapid design exploration and physical design implementation, covering most of the ASIC design flow.


### Process Design Kit (SkyWater SKY130 technology)

"*A PDK is a set of files used within the semiconductor industry to model a fabrication process for the design tools used to design an integrated circuit.  PDK’s are often specific to a foundry, and may be subject to a non-disclosure agreement.  While most PDK’s are proprietary to a foundry, certain PDKs are open-source and entirely within the public domain.*" (definition borrowed from [here](https://blink.ucsd.edu/sponsor/exportcontrol/pdkguidance.html)).

In this course we will use [SkyWater SKY130](https://skywater-pdk.readthedocs.io/en/main/), or SKY130, which is an open source process design kit (PDK) for a 130nm node. This is the PDK we will use for this lab. Right now, the details of the PDK are unnecessary as you will gain familiarity in future labs. All major companies like Intel, Samsung, Global Foundaries or TSMC have their own PDKs.


### Hammer

In this course we will use an ASIC design framework developed at Berkeley, called Hammer. Hammer abstracts away tool- (Cadence, Synopsys, Mentor, etc.) and technology- (TSMC, X-FAB, Intel, etc.) specific considerations away from ASIC design. The philosophy of Hammer aims to maximize reusability of design intent between projects that may have different underlying tool infrastructures and target different process technologies. Documentation about Hammer philosophy and usage is at Hammer [website](hammer-vlsi.readthedocs.io).

Hammer consumes serialized configuration files in YAML or JSON format, which are used as intermediate representation (IR) languages between higher-level physical design generators and the underlying scripts that the ASIC design flow tools require.

> **Note:** The version of Hammer used in this course may deviate from public or "main" Hammer. Please reference the public [repository](https://github.com/ucb-bar/hammer) if you are interested in the latest, consistent source.


## Setup

This section covers lab environment setup and installation. It goes without saying that a Linux machine is mandatory for these labs, since this is a requirement for all ASIC design CAD tools. Non-tested alternatives on Windows include WSL or using a hypervisor/virtualizer to run a Linux virtual machine on Linux. The lab content and tools were tested on a Kubuntu 24.04 machine.

### Getting an GitHub Account

In this course, we use GitHub to manage labs and the project, so in order to download lab content and submit your results, you are required to create a GitHub account. The instructions on how to do so can be found [here](https://docs.github.com/en/get-started/start-your-journey/creating-an-account-on-github).

This repository should be cloned along with its parent module, using the following commands:

```shell
git clone git@github.com:elektrotehnika/digel.git --recursive
git submodule update --recursive --remote --merge
```

and updated using the following commands:

```shell
git pull
git submodule update --recursive --remote --merge
```

### Hammer Setup

As already mentioned, the main tool needed for these labs is [Hammer](https://github.com/ucb-bar/hammer), the physical design framework which simplifies interaction with the ASIC design ECAD tools and specific technologies.

> **Note:** It will be assumed in this lab that all the tools and technologies used in this lab are installed in default path. Otherwise, some scripts might need manual adjustment!

In order to set up Hammer and its prerequisites, folow these steps:

0. Hammer depends on Python 3.9+, so a corresponding [Python](https://www.python.org/downloads/) version must be installed on your computer

1. First, clone Hammer with `git`

```shell
git clone git@github.com:ucb-bar/hammer.git
cd hammer
```

2. Install [poetry](https://python-poetry.org/docs/master/) (a tool for dependency management and packaging in Python) to manage the development virtualenv and dependencies (with the help of the *curl* command or manually from the URL))

```shell
curl -sSL https://install.python-poetry.org | python3 -
export PATH="$PATH:~/.local/bin" # poetry
```

3. Create a poetry-managed virtualenv using the dependencies from `pyproject.toml`

```shell
# create the virtualenv inside the project folder (in .venv)
poetry config virtualenvs.in-project true
poetry install
```

4. Activate the virtualenv. Within the virtualenv, Hammer is installed and you can access its scripts defined in `pyproject.toml` (in `[tool.poetry.scripts]`)

```shell
poetry shell
hammer-vlsi -h
```

This virtual environment needs to be activated each time you are about to run Hammer. But for now, exit the virtual env and let's do the rest of the setup.

### Install Anaconda

In this labs, we will mainly use open-source ASIC design tools and technologies. For that reason we will also download the needed techonolgy files and install required tools using *conda* (Anaconda).

1. Download the Anaconda installation [script](https://repo.anaconda.com/archive/Anaconda3-2024.06-1-Linux-x86_64.sh)
(from [here]([https://www.anaconda.com/download/success))

2. Install and setup Anaconda by running

```shell
chmod u+x Anaconda3-2024.06-1-Linux-x86_64.sh
bash Anaconda3-2024.06-1-Linux-x86_64.sh
eval "$(/home/dejanp/anaconda3/bin/conda shell.bash hook)"
conda init
```

Total Anaconda iInstallation size is ~7GB.

### Set up open-source tools/tech

Go inside the cloned hammer repostitory again.

```shell
cd hammer/e2e
./scripts/setup-sky130-openroad.sh
```
Total download/installation size is ~42GB.

### QuestaSim setup

Last but not least, we are going to install install a free proprietary EDA simulator (currently more useful for these education purposes), Questa Sim:

1. The Questa Sim can be downloaded from the following [link](https://www.intel.com/content/www/us/en/software-kit/795215/questa-intel-fpgas-standard-edition-software-version-23-1.html)

2. After downloading the executable, give it executable permissions, and run it. Select Intel FPGA Starter Edition, accept the license agreement and select the default installation directory. Total installation size is ~4.5GB.

3. Next, register for Intel FPGA Self-Service Licensing Center (SSLC) [here](https://fpgasupport.intel.com/Licensing/license/index.html)
(click *Enroll for Intel FPGA Self Service Licensing Center (SLLC)*)

4. Click on *Create an Account* and enter your details. Verify your email afterwards.

5. Continue the enrollment process by selecting the *FPGA Engineering* Profession and Submit

6. Now, go to [SSLC](https://fpgasupport.intel.com/Licensing/license/index.htm) again, sign in (click *Already enrolled ? - Sign In here*), and accept the Terms of Use:

7. Set up multi-factor authentification (MFA) by setting up the Authenticator app or your phone number details.

8. Once successfully signed into the Self-Service Licensing Center, click on *Sign up for Evaluation or No-Cost Licenses* and select *Questa*-Intel® FPGA Starter Edition (License: SW-QUESTA)*

9. Check the required checkboxes and add a new computer.

10. Get your hostname (*hostname* command) and MAC address from one of your network cards (*ip a* command) , and fill in as follows:
    - Computer Name <-> hostname
    - Computer Type <-> NIC IDs
    - License Type <_> Fixed
    - Primary Computer ID <-> MAC address (remove the colons (:))

11. Save this information and generate the license (click *Generate*)

12. Download the license file received via eamil and save it to *~/intelFPGA/license/license.dat*

13. Add the Questa executable path folder to PATH to make it easily accesible in the terminal (you can also add this command to *$HOME/.profile* or *~/.bashrc* make this automatic each time you open a terminal)

```shell
export PATH="$PATH:~/intelFPGA/23.1std/questa_fse/bin"
```

14. Point the LM_LICENSE_FILE environment variable to the license file location (best add this command  to *~/.bashrc* )

```shell
export LM_LICENSE_FILE="~/intelFPGA/license/license.dat"
```

15. Log out and log back in for the changes to take effect and check if the installation was successfull by running *qhsim*. The Questa Sim GUI should open.

For additional information, refer to the following [document](https://cdrdv2-public.intel.com/703091/ug-20352-703090-703091.pdf).

<!--
Typically, the Ethernet interface is used, named *ethN*, *enoN*, *enpNsM*, etc. In the absence of an Ethernet interface, you can use a WLAN interface as in the example above, typically named *wlanN*, *wlpNsM*, *wlpNsMfK*, etc.-->


### Clone this Repo

You are now ready to complete the lab exercises!

Other links worth visiting and investigating:

<!--https://www.siliconcompiler.com/
https://openlane2.readthedocs.io/en/latest/
https://mflowgen.readthedocs.io/en/latest/-->
