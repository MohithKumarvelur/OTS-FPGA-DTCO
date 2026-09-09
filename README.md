# FPGA-Based Stochastic OTS Switching Model

This repository contains the Verilog RTL implementation,
probability lookup tables, FPGA constraints, simulation files,
and Python analysis scripts developed for the MSc project:

"FPGA-Based Design Technology Co-optimization of Stochastic
Time-to-Switch Behavior in Ovonic Threshold Switching Devices"

## Hardware Platform

- Digilent Basys 3
- AMD/Xilinx Artix-7 XC7A35T FPGA
- 100 MHz clock
- 10 ns clock period
- 9600 baud UART

## FPGA Architecture

The implementation consists of:

- Probability lookup table
- 16-bit LFSR
- Probability comparator
- Delay counter
- OTS finite-state machine
- 10 parallel OTS instances
- 100 trials per OTS instance
- Result memory
- UART data transmission

## Experimental Configuration

10 OTS devices × 100 trials = 1000 measurements
per voltage condition.

Applied voltages:

- 2.8 V
- 3.0 V
- 3.2 V
- 3.4 V

## Repository Structure

RTL/          - Verilog RTL source files
LUT/          - Probability lookup tables
Python/       - Statistical analysis scripts
Simulation/   - Simulation/testbench files
Constraints/  - FPGA XDC constraint file
Results/      - Experimental/analysis results

## Analysis

The Python scripts calculate:

- Mean switching delay
- Switching time
- Standard deviation
- Variance
- Empirical CDF
- Switching-delay distributions
- Switching-time reduction

## FPGA Results

The hardware implementation was evaluated using
10 parallel OTS instances and 100 trials per instance.
