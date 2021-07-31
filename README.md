# config_diag_tool
#*********************************************************************
#  Program:  Configuration Diagnostic Tool
#   Author:  Ng, Chin Chuan
# Synopsis:  Read Intel PSG FPGA configuration pins state, it supports
#			 majority of Intel PSG FPGA, refer revision history to 
#			 understand what FPGA is currently supported
#
#   Syntax:  tclsh config_diag_tool.tcl
#
# Associated package: device_data.tcl
#
# Command line parameters:  N/A, this is a GUI tool
#
# ------------------------
# Files Modified:  none
#
#    Input files:  none
#
#   Output files:  none
#
# Non-zero exits:  on error
#
# Description:
# ------------
# This tool is developed to read Intel PSG FPGA configuration pins state.
# Configuration is critical for the FPGA to function correctly, all the
# dedicated configuration pins are not tap-able by the Signal Tap as the
# Signal Tap require FPGA to be in user mode. Prior to user mode, this 
# tool can be used to read the FPGA dedicated configuration pins and thus
# ease the debug significantly.
#
# This tool allows users to modify the USB Blaster II frequency more
# handily, more features are support such as reading the KEY VERIFY
# register, reading EDCRC EMR register and execute a pulse nCONFIG
# instruction remotely to force the FPGA to exit user mode and to be
# reconfigured.
#
# The tool owner is Chin Chuan Ng, feel free to write an email to
# chin.chuan.ng@intel.com to ask for clarification or provide feedback
# for the improvement of the tool.
#
#************************************************************************
#
# Revision History:
# -----------------
# Version   Date    Who  Comments
#			YYMMDD
# ------------------------------------------------------------------------
# 1.0		170604	CCNg First release to support Cyclone V, Arria V,
#					Stratix V and Arria 10 devices.
#					Pending development: EDCRC, Key Verify, Pulse nCONFIG
# 1.1		170710	CCNg Added 28nm EDCRC feature. Pending 28nm Key_Verify
# 1.15		170731	CCNg Fix minor bug introduced in v1.1. The bug is
#						 causing Arria 10 EDCRC feature broken.
# ------------------------------------------------------------------------
#
# Program notes:
# --------------
# 
#*********************************************************************
