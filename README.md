# Configuration Diagnostic Tool

Synopsis : Read Intel PSG FPGA configuration pins state, it supports majority of Intel PSG FPGA, refer revision history to understand what FPGA is currently supported

Syntax:  tclsh config_diag_tool.tcl

Associated package: device_data.tcl

Command line parameters:  N/A, this is a GUI tool

Description:

This tool is developed to read Intel PSG FPGA configuration pins state. Configuration is critical for the FPGA to function correctly, all the dedicated configuration pins are not tap-able by the Signal Tap as the Signal Tap require FPGA to be in user mode. Prior to user mode, this tool can be used to read the FPGA dedicated configuration pins and thus ease the debug significantly.

This tool allows users to modify the USB Blaster II frequency more handily, more features are support such as reading the KEY VERIFY register, reading EDCRC EMR register and execute a pulse nCONFIG instruction remotely to force the FPGA to exit user mode and to be reconfigured.
