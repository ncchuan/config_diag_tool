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
set version "1.15"

package require Tk

source device_data.tcl

###### Global Variables ###########

set cables [list]
set devices [list]
set cable_count 0

set selected_cable 0
# selected_device contain IDCODE
set selected_device ""
# device_name store the name of selected_device, such as Stratix V
set device_name ""
# device_family sotre the selected_device family, such as 28nm, 20nm etc
set device_family ""

set preir 0
set predr 0
set postir 0
set postdr 0

set temp_config_status_jam "config_status.jam"
set temp_key_verify_jam "key_verify.jam"
set temp_emr_unload_jam "emr_unload.jam"
set temp_pulse_nconfig_jam "pulse_nconfig.jam"

########### Procedures ############
proc CB_Cable_OnSelect { } {
	global devices
	global selected_cable

	
	.frm_cabledevice.cb_device set ""
	.frm_cabledevice.cb_device configure -state readonly
	set cable_index [.frm_cabledevice.cb_cable current]
	.frm_cabledevice.cb_device configure -value [lindex $devices $cable_index]	
	
	set selected_cable [expr {$cable_index + 1}]
	if {![catch {exec jtagconfig --getparam $selected_cable JtagClock} freq]} {
		.frm_cable_frequency.btn_read configure -state normal
		.frm_cable_frequency.cb_frequency configure -state readonly
		.frm_cable_frequency.cb_frequency set $freq
		print_message "The selected cable has TCK frequency of $freq."
	} else {
		.frm_cable_frequency.btn_read configure -state disabled
		.frm_cable_frequency.cb_frequency configure -state disabled
		.frm_cable_frequency.cb_frequency set ""
		print_message "TCK frequency cannot be configured for the selected cable."
	}
	
	.frm_function.btn_config_pins_status configure -state disabled
	.frm_function.btn_key_verify configure -state disabled
	.frm_function.btn_edcrc configure -state disabled
	.frm_function.btn_pulse_nconfig configure -state disabled
}

proc CB_Cable_Frequency_OnSelect { } {
	global selected_cable
	
	set new_freq [.frm_cable_frequency.cb_frequency get]
	
	if {[catch {exec jtagconfig --setparam $selected_cable JtagClock $new_freq} errMsg]} {
		print_message "Fail to set $new_freq to cable $selected_cable, error message: $errMsg"
	} else {
		print_message "The TCK frequency of cable $selected_cable has been set to $new_freq."
	}
}

proc Read_Cable_Frequency { } {
	global selected_cable
	
	if {![catch {exec jtagconfig --getparam $selected_cable JtagClock} freq]} {
		.frm_cable_frequency.btn_read configure -state normal
		.frm_cable_frequency.cb_frequency configure -state readonly
		.frm_cable_frequency.cb_frequency set $freq
		print_message "The TCK frequency of cable $selected_cable is $freq."
	} else {
		.frm_cable_frequency.cb_frequency set ""
		print_message "Fail to read TCK frequency on cable $selected_cable."
	}
}

proc Compute_IR_DR { } {
	global devices

	global preir
	global predr
	global postir
	global postdr
	
	set preir 0
	set predr 0
	set postir 0
	set postdr 0

	set device_index [.frm_cabledevice.cb_device current]
	set devices_of_cable [lindex $devices [.frm_cabledevice.cb_cable current]]

	if {[llength $devices_of_cable] == 1} { return }
		
	for {set i 0} {$i < [llength $devices_of_cable]} {incr i 1} {
		set device [lindex $devices_of_cable $i]
		set ir [lindex $device 2]	
		if {$i < $device_index} {
			set postir [expr $postir + $ir]
			set postdr [expr $postdr + 1]
		} elseif {$i > $device_index } {
			set preir [expr $preir + $ir]
			set predr [expr $predr + 1]
		}
	}	
}

proc Generate_Config_Status_JAM_Files_28nm { } {
	global selected_device
	global preir
	global predr
	global postir
	global postdr
	global temp_config_status_jam

	#get boundary scan length
	set bc_length [lindex [dict get $device_data::device_family $selected_device] 1]
	#get config pins bs cell location
	set msel4 [lindex [dict get $device_data::bsc $selected_device] 0]
	set msel3 [lindex [dict get $device_data::bsc $selected_device] 1]
	set msel2 [lindex [dict get $device_data::bsc $selected_device] 2]
	set msel1 [lindex [dict get $device_data::bsc $selected_device] 3]
	set msel0 [lindex [dict get $device_data::bsc $selected_device] 4]
	set conf_done [lindex [dict get $device_data::bsc $selected_device] 5]
	set nstatus [lindex [dict get $device_data::bsc $selected_device] 6]
	set nce [lindex [dict get $device_data::bsc $selected_device] 7]
	set nconfig [lindex [dict get $device_data::bsc $selected_device] 8]
	set dclk [lindex [dict get $device_data::bsc $selected_device] 9]	
	
	set jam_file [open "$temp_config_status_jam" w]
	puts $jam_file "ACTION UNLOAD_DR = EXECUTE;"
	puts $jam_file "DATA DR_DATA;"
	puts $jam_file "BOOLEAN out\[$bc_length\];"
	puts $jam_file "ENDDATA;"
	puts $jam_file "PROCEDURE EXECUTE USES DR_DATA;"
	puts $jam_file "DRSTOP IDLE;"
	puts $jam_file "IRSTOP IDLE;"
	puts $jam_file "STATE IDLE;"
	if { $preir != 0 } { puts $jam_file "PREIR $preir;" }
	if { $predr != 0 } { puts $jam_file "PREDR $predr;" }
	if { $postir != 0 } { puts $jam_file "POSTIR $postir;" }
	if { $postdr != 0 } { puts $jam_file "POSTDR $postdr;" }
	puts $jam_file {IRSCAN 10, $005;}
	puts $jam_file "WAIT IDLE, 10 CYCLES, 1 USEC, IDLE;"
	puts $jam_file [format {%s%s%s%s%s} "DRSCAN " $bc_length {, $0, CAPTURE out[} [expr {$bc_length-1}] {..0];}]
	puts $jam_file "WAIT IDLE, 10 CYCLES, 25 USEC, IDLE;"
	puts $jam_file "PRINT \"MSEL \", out\[$msel4\], out\[$msel3\], out\[$msel2\], out\[$msel1\], out\[$msel0\];"
	puts $jam_file "PRINT \"CONF_DONE \", out\[$conf_done\];"
	puts $jam_file "PRINT \"nSTATUS \", out\[$nstatus\];"
	puts $jam_file "PRINT \"nCE \", out\[$nce\];"
	puts $jam_file "PRINT \"nCONFIG \", out\[$nconfig\];"
	puts $jam_file "PRINT \"DCLK \", out\[$dclk\];"
	puts $jam_file "STATE IDLE;"
	puts $jam_file "EXIT 0;"
	puts $jam_file "ENDPROC;"
	close $jam_file
}

proc Generate_Config_Status_JAM_Files_20nm { } {
	global selected_device
	global preir
	global predr
	global postir
	global postdr
	global temp_config_status_jam
	
	#get boundary scan length
	set bc_length [lindex [dict get $device_data::device_family $selected_device] 1]
	#get config pins bs cell location
	set msel2 [lindex [dict get $device_data::bsc $selected_device] 0]
	set msel1 [lindex [dict get $device_data::bsc $selected_device] 1]
	set msel0 [lindex [dict get $device_data::bsc $selected_device] 2]
	set conf_done [lindex [dict get $device_data::bsc $selected_device] 3]
	set nstatus [lindex [dict get $device_data::bsc $selected_device] 4]
	set nce [lindex [dict get $device_data::bsc $selected_device] 5]
	set nconfig [lindex [dict get $device_data::bsc $selected_device] 6]
	set dclk [lindex [dict get $device_data::bsc $selected_device] 7]	
		
	set jam_file [open "$temp_config_status_jam" w]
	puts $jam_file "ACTION UNLOAD_DR = EXECUTE;"
	puts $jam_file "DATA DR_DATA;"
	puts $jam_file "BOOLEAN out\[$bc_length\];"
	puts $jam_file "ENDDATA;"
	puts $jam_file "PROCEDURE EXECUTE USES DR_DATA;"
	puts $jam_file "DRSTOP IDLE;"
	puts $jam_file "IRSTOP IDLE;"
	puts $jam_file "STATE IDLE;"
	if { $preir != 0 } { puts $jam_file "PREIR $preir;" }
	if { $predr != 0 } { puts $jam_file "PREDR $predr;" }
	if { $postir != 0 } { puts $jam_file "POSTIR $postir;" }
	if { $postdr != 0 } { puts $jam_file "POSTDR $postdr;" }
	puts $jam_file {IRSCAN 10, $005;}
	puts $jam_file "WAIT IDLE, 10 CYCLES, 1 USEC, IDLE;"
	puts $jam_file [format {%s%s%s%s%s} "DRSCAN " $bc_length {, $0, CAPTURE out[} [expr {$bc_length-1}] {..0];}]
	puts $jam_file "WAIT IDLE, 10 CYCLES, 25 USEC, IDLE;"
	puts $jam_file "PRINT \"MSEL \", out\[$msel2\], out\[$msel1\], out\[$msel0\];"
	puts $jam_file "PRINT \"CONF_DONE \", out\[$conf_done\];"
	puts $jam_file "PRINT \"nSTATUS \", out\[$nstatus\];"
	puts $jam_file "PRINT \"nCE \", out\[$nce\];"
	puts $jam_file "PRINT \"nCONFIG \", out\[$nconfig\];"
	puts $jam_file "PRINT \"DCLK \", out\[$dclk\];"
	puts $jam_file "STATE IDLE;"
	puts $jam_file "EXIT 0;"
	puts $jam_file "ENDPROC;"
	close $jam_file
}

proc Generate_Config_Status_JAM_Files { } {	
	global selected_device
	global device_family	
	
	if { $device_family == "28nm" } { Generate_Config_Status_JAM_Files_28nm }
	if { $device_family == "20nm" } { Generate_Config_Status_JAM_Files_20nm }	
}

proc Generate_Key_Verify_JAM_Files_20nm { } {
	global selected_device
	global preir
	global predr
	global postir
	global postdr
	global temp_key_verify_jam
	
	set jam_file [open "$temp_key_verify_jam" w]
	puts $jam_file "ACTION KEY_VERIFY = EXECUTE;"
	puts $jam_file "PROCEDURE EXECUTE;"
	puts $jam_file "BOOLEAN DATAOUT\[21\];"
	puts $jam_file "IRSTOP IDLE;"
	puts $jam_file "DRSTOP IDLE;"
	puts $jam_file "STATE RESET IDLE;"
	if { $preir != 0 } { puts $jam_file "PREIR $preir;" }
	if { $predr != 0 } { puts $jam_file "PREDR $predr;" }
	if { $postir != 0 } { puts $jam_file "POSTIR $postir;" }
	if { $postdr != 0 } { puts $jam_file "POSTDR $postdr;" }
	puts $jam_file {IRSCAN 10, $013;}
	puts $jam_file {WAIT 100 USEC;}
	puts $jam_file {DRSCAN 21, $0, CAPTURE DATAOUT[20..0];}
	puts $jam_file {PRINT "KEY_VERIFY_DATA ",}	
	for {set i 20} { $i >= 0 } { incr i -1 } {
		if { $i != 0 } {
			puts $jam_file "DATAOUT\[$i\],"
		} else {
			puts $jam_file "DATAOUT\[$i\];"
		}
	}
	puts $jam_file "STATE IDLE;"
	puts $jam_file "EXIT 0;"
	puts $jam_file "ENDPROC;"
	close $jam_file
}

proc Generate_Key_Verify_JAM_Files { } {	
	global selected_device
	global device_family	
	
	#if { $device_family == "28nm" } { Generate_EMR_Unload_JAM_Files_28nm }
	if { $device_family == "20nm" } { Generate_Key_Verify_JAM_Files_20nm }	
}

proc Generate_EMR_Unload_JAM_Files_20nm { } {
	global selected_device
	global preir
	global predr
	global postir
	global postdr
	global temp_emr_unload_jam
	
	set jam_file [open "$temp_emr_unload_jam" w]
	puts $jam_file "ACTION UNLOAD_EMR = EXECUTE;"
	puts $jam_file "DATA EMR_DATA;"
	puts $jam_file "BOOLEAN out\[78\];"
	puts $jam_file "ENDDATA;"
	puts $jam_file "PROCEDURE EXECUTE USES EMR_DATA;"
	puts $jam_file "DRSTOP IDLE;"
	puts $jam_file "IRSTOP IDLE;"
	puts $jam_file "STATE IDLE;"
	if { $preir != 0 } { puts $jam_file "PREIR $preir;" }
	if { $predr != 0 } { puts $jam_file "PREDR $predr;" }
	if { $postir != 0 } { puts $jam_file "POSTIR $postir;" }
	if { $postdr != 0 } { puts $jam_file "POSTDR $postdr;" }
	puts $jam_file {IRSCAN 10, $017;}
	puts $jam_file {WAIT IDLE, 10 CYCLES, 1 USEC, IDLE;}
	puts $jam_file {DRSCAN 78, $0, CAPTURE out[77..0];}
	puts $jam_file {WAIT IDLE, 10 CYCLES, 25 USEC, IDLE;}
	puts $jam_file {PRINT "EMR_DATA ",}	
	for {set i 77} { $i >= 0 } { incr i -1 } {
		if { $i != 0 } {
			puts $jam_file "out\[$i\],"
		} else {
			puts $jam_file "out\[$i\];"
		}
	}
	puts $jam_file "STATE IDLE;"
	puts $jam_file "EXIT 0;"
	puts $jam_file "ENDPROC;"
	close $jam_file
}

proc Generate_EMR_Unload_JAM_Files_28nm { } {
	global selected_device
	global preir
	global predr
	global postir
	global postdr
	global temp_emr_unload_jam
	
	set jam_file [open "$temp_emr_unload_jam" w]
	puts $jam_file "ACTION UNLOAD_EMR = EXECUTE;"
	puts $jam_file "DATA EMR_DATA;"
	puts $jam_file "BOOLEAN out\[78\];"
	puts $jam_file "ENDDATA;"
	puts $jam_file "PROCEDURE EXECUTE USES EMR_DATA;"
	puts $jam_file "DRSTOP IDLE;"
	puts $jam_file "IRSTOP IDLE;"
	puts $jam_file "STATE IDLE;"
	if { $preir != 0 } { puts $jam_file "PREIR $preir;" }
	if { $predr != 0 } { puts $jam_file "PREDR $predr;" }
	if { $postir != 0 } { puts $jam_file "POSTIR $postir;" }
	if { $postdr != 0 } { puts $jam_file "POSTDR $postdr;" }
	puts $jam_file {IRSCAN 10, $017;}
	puts $jam_file {WAIT IDLE, 10 CYCLES, 1 USEC, IDLE;}
	puts $jam_file {DRSCAN 67, $0, CAPTURE out[66..0];}
	puts $jam_file {WAIT IDLE, 10 CYCLES, 25 USEC, IDLE;}
	puts $jam_file {PRINT "EMR_DATA ",}	
	for {set i 66} { $i >= 0 } { incr i -1 } {
		if { $i != 0 } {
			puts $jam_file "out\[$i\],"
		} else {
			puts $jam_file "out\[$i\];"
		}
	}
	puts $jam_file "STATE IDLE;"
	puts $jam_file "EXIT 0;"
	puts $jam_file "ENDPROC;"
	close $jam_file
}

proc Generate_EMR_Unload_JAM_Files { } {	
	global selected_device
	global device_family	
	
	if { $device_family == "28nm" } { Generate_EMR_Unload_JAM_Files_28nm }
	if { $device_family == "20nm" } { Generate_EMR_Unload_JAM_Files_20nm }	
}

proc Generate_Pulse_nCONFIG_JAM_Files { } {	
	global preir
	global predr
	global postir
	global postdr
	global temp_pulse_nconfig_jam
	
	if { [file exists "$temp_pulse_nconfig_jam"] } { file delete "$temp_pulse_nconfig_jam" }	
	set jam_file [open "$temp_pulse_nconfig_jam" w]
	puts $jam_file "ACTION RECONFIG = EXECUTE;"
	puts $jam_file "PROCEDURE EXECUTE;"
	puts $jam_file "DRSTOP IDLE;"
	puts $jam_file "IRSTOP IDLE;"
	puts $jam_file "STATE RESET IDLE;"
	if { $preir != 0 } { puts $jam_file "PREIR $preir;" }
	if { $predr != 0 } { puts $jam_file "PREDR $predr;" }
	if { $postir != 0 } { puts $jam_file "POSTIR $postir;" }
	if { $postdr != 0 } { puts $jam_file "POSTDR $postdr;" }
	puts $jam_file {IRSCAN 10, $001;}
	puts $jam_file "WAIT 100 USEC;"
	puts $jam_file "EXIT 0;"
	puts $jam_file "ENDPROC;"
	close $jam_file
}

proc Read_Config_Pins { } {
	global selected_cable
	global selected_device
	global device_family
	global temp_config_status_jam
	
	set config_pin [dict get $device_data::pin $device_family]
	
	set f [open "|quartus_jli -c $selected_cable -a UNLOAD_DR $temp_config_status_jam" r]
	
	while { ![eof $f] } {
		set line [gets $f]
		if {[dict exists $config_pin [lindex $line 0]]} {
			dict set config_pin [lindex $line 0] [lindex $line 1]
		}
	}

	if { [catch {close $f} err] } {
		tk_messageBox -title "Fail to execute JAM file" -message "$err" -icon error -type ok
		return 1
	}
	
	# update the read out pins state back to global dict
	dict set device_data::pin $device_family $config_pin
	
	# dict for {k v} [dict get $device_data::pin $device_family] {
		# puts "New dict with pins $k with state $v"
	# }
	return 0
}

proc Read_Key_20nm { } {
	global selected_cable
	global selected_device
	global device_family
	global temp_key_verify_jam
		
	set key_verify_reg [dict get $device_data::key_verify_reg $device_family]
	set key_verify_data ""
	
	set f [open "|quartus_jli -c $selected_cable -a KEY_VERIFY $temp_key_verify_jam" r]
	
	while { ![eof $f] } {
		set line [gets $f]
		if { [lindex $line 0] == "KEY_VERIFY_DATA" } {
			set key_verify_data [lindex $line 1]
		}
	}

	for { set i 0 } { $i <= 20 } { incr i 1 } {
		set bit_location [expr { 20 - $i }]
		dict set key_verify_reg $i [string range $key_verify_data $bit_location $bit_location]	
	}
	
	if { [catch {close $f} err] } {
		tk_messageBox -title "Fail to execute JAM file" -message "$err" -icon error -type ok
		return 1
	}
	
	# update the read out key verify back to global dict
	dict set device_data::key_verify_reg $device_family $key_verify_reg
	
	# dict for {k v} [dict get $device_data::key_verify_reg $device_family] {
		# puts "$k $v"
	# }
	return 0
}

proc Read_Key { } {
	global device_family
	if { $device_family == "20nm" } { Read_Key_20nm }
}

proc Read_EMR_20nm { } {
	global selected_cable
	global selected_device
	global device_family
	global temp_emr_unload_jam
		
	set emr [dict get $device_data::emr $device_family]
	set emr_data ""
	
	set f [open "|quartus_jli -c $selected_cable -a UNLOAD_EMR $temp_emr_unload_jam" r]
	
	while { ![eof $f] } {
		set line [gets $f]
		if { [lindex $line 0] == "EMR_DATA" } {
			set emr_data [lindex $line 1]
		}
	}
	
	# puts $emr_data
	set emr_table [dict get $device_data::emr_table $device_family]
	
	dict for {k v} $emr_table {
		set bit_location_from [expr { 77 - [lindex $v 0] }]
		set bit_location_to [expr { 77 - [lindex $v 1] }]
		dict set emr $k [format {0x%s} [Bin2Hex [string range $emr_data $bit_location_from $bit_location_to]]]
	}
	
	if { [catch {close $f} err] } {
		tk_messageBox -title "Fail to execute JAM file" -message "$err" -icon error -type ok
		return 1
	}
	
	# update the read out emr back to global dict
	dict set device_data::emr $device_family $emr
	
	# dict for {k v} [dict get $device_data::emr $device_family] {
		# puts "$k $v"
	# }
	return 0
}

proc Read_EMR_28nm { } {
	global selected_cable
	global selected_device
	global device_family
	global temp_emr_unload_jam
		
	set emr [dict get $device_data::emr $device_family]
	set emr_data ""
	
	set f [open "|quartus_jli -c $selected_cable -a UNLOAD_EMR $temp_emr_unload_jam" r]
	
	while { ![eof $f] } {
		set line [gets $f]
		if { [lindex $line 0] == "EMR_DATA" } {
			set emr_data [lindex $line 1]
		}
	}
	
	# puts $emr_data
	set emr_table [dict get $device_data::emr_table $device_family]
	
	dict for {k v} $emr_table {
		set bit_location_from [expr { 66 - [lindex $v 0] }]
		set bit_location_to [expr { 66 - [lindex $v 1] }]
		dict set emr $k [format {0x%s} [Bin2Hex [string range $emr_data $bit_location_from $bit_location_to]]]
	}
	
	if { [catch {close $f} err] } {
		tk_messageBox -title "Fail to execute JAM file" -message "$err" -icon error -type ok
		return 1
	}
	
	# update the read out emr back to global dict
	dict set device_data::emr $device_family $emr
	
	# dict for {k v} [dict get $device_data::emr $device_family] {
		# puts "$k $v"
	# }
	return 0
}

proc Read_EMR { } {
	global device_family
	if { $device_family == "20nm" } { return [Read_EMR_20nm] }
	if { $device_family == "28nm" } { return [Read_EMR_28nm] }
}

proc CB_Device_OnSelect { } {
	global selected_device	
	global device_family
	global device_name
	
	#update preir,predr,postir,postdr
	Compute_IR_DR
		
	set selected_device [lindex [.frm_cabledevice.cb_device get] 0]
	
	
	if {[dict exists $device_data::device_family $selected_device]} {
		set device_family [lindex [dict get $device_data::device_family $selected_device] 0]
		set device_name [lindex [dict get $device_data::device_family $selected_device] 2]
		
		.frm_function.btn_config_pins_status configure -state normal
		.frm_function.btn_pulse_nconfig configure -state normal
		
		print_message "The selected device is $device_name."		
		if { $device_family == "20nm" } { .frm_function.btn_key_verify configure -state normal }
		if { $device_family == "20nm" || $device_family == "28nm"  } { .frm_function.btn_edcrc configure -state normal }
		
	} else {
		.frm_function.btn_config_pins_status configure -state disabled
		.frm_function.btn_key_verify configure -state disabled
		.frm_function.btn_edcrc configure -state disabled
		.frm_function.btn_pulse_nconfig configure -state disabled
		print_message "The selected device is not supported by this tool."
	}		
}

proc Read_Cables_Devices { arg_cables arg_devices arg_cable_count } {
	upvar $arg_cables cables
	upvar $arg_devices devices
	upvar $arg_cable_count cable_count
	
	set f [open "|jtagconfig --debug" r]
	set device_ir_list [list]
	
	while { ![eof $f ] } {
		set line [gets $f]
		if { [regexp {^\d+\)} $line] } {
			incr cable_count 1
			regsub {\d+\)\s+} $line "" cable
			lappend cables $cable
		}
	
		if { [regexp {^\s+\w{8}\s+\S+\s+\(IR=\d+\)$} $line] } {
			set device [lindex $line 0]
			set device_name [lindex $line 1]
			set ir [string trim [lindex $line 2] (IR=]
			set ir [string trim $ir )]
			set device_name_ir [list $device $device_name $ir]
			lappend device_ir_list $device_name_ir
		}
		
		if { [regexp {^\s+Captured DR} $line] } {
			lappend devices $device_ir_list
			set device_ir_list ""
		}
	}
	
	if { [catch {close $f} err] } {
		tk_messageBox -title "Error" -message "Fail to read cables, try to reopen this tool.\n\nDebug tips: remove all unused cables from your machine with below command:\n\n > jtagconfig --remove <cable_number>" -icon error -type ok
		return 1
	}
	
	return 0
}

proc foreground_win { w } {
   wm withdraw $w
   wm deiconify $w
}

proc Update_Config_Status { w f } {	
	global selected_device
	
	######## Testing only ####
	#dict set config_pin "CONF_DONE" 0
	#dict set config_pin "MSEL" 10010
	#dict set device_data::pin $device_family $config_pin	
	##########################
	
	if {[catch {Read_Config_Pins}]} {
		tk_messageBox -title "Unable to execute JAM file" -message "Fail to execute JAM file." -icon error -type ok
		return
	}
	
	set device_family [lindex [dict get $device_data::device_family $selected_device] 0]	
	set msel_table [dict get $device_data::msel_table $device_family]
	set config_pin [dict get $device_data::pin $device_family]
	
	set count 0
	dict for {k v} $config_pin {
		if {$k == "MSEL"} {
			$w$f.lbl_config_pin_$k configure -text \
			[format {%s (%s %s)} $v [lindex [dict get $msel_table $v] 0] [lindex [dict get $msel_table $v] 1]]
		} else {
			$w$f.lbl_config_pin_$k configure -text $v
			if {$v == 0} {
				$w$f.lbl_config_pin_$k configure -background red
			} elseif { $v == 1 } {
				$w$f.lbl_config_pin_$k configure -background green
			}
		}
	}

}

proc Update_Key { w f } {	
	global selected_device
	global device_family
	
	if {[catch {Read_Key}]} {
		tk_messageBox -title "Unable to execute JAM file" -message "Fail to execute JAM file." -icon error -type ok
		return
	}	

	set key_verify_reg [dict get $device_data::key_verify_reg $device_family]	
	set key_verify_table [dict get $device_data::key_verify_table $device_family]
		
	dict for {k v} $key_verify_table {
		set read_value [dict get $key_verify_reg $k]
		$w$f.lbl_col1_$k configure -text $read_value
		if {$read_value == 0} {
			$w$f.lbl_col1_$k configure -background red
		} elseif { $read_value == 1 } {
			$w$f.lbl_col1_$k configure -background green
		}	
	}
}

proc Update_EMR { w f } {	
	global selected_device
	global device_family
	
	if {[catch {Read_EMR}]} {
		tk_messageBox -title "Unable to execute JAM file" -message "Fail to execute JAM file." -icon error -type ok
		return
	}	

	set emr [dict get $device_data::emr $device_family]	
	set emr_table [dict get $device_data::emr_table $device_family]
		
	dict for {k v} $emr_table {
		$w$f.lbl_emr_$k configure -text [format {%s (%s bits)} [dict get $emr $k] [lindex $v 2]]
	}

}

proc OnClick_Config_Pins_Status_Window { } {
	global selected_device

	if {[catch {Generate_Config_Status_JAM_Files}]} {
		tk_messageBox -title "Unable to write JAM file" -message "Make sure you have write permission in this local folder" -icon error -type ok
		return
	}
	
	if { [Read_Config_Pins] } {	return }
	
	set w .dialog_window     
	catch { destroy $w }
	toplevel $w -padx 10 -pady 10
	wm resizable $w 0 0
	bind $ <ButtonPress> { raise $w }
	wm title $w "Configuration Pins Status"

	label $w.lbl_device -text "Intel FPGA" -font {-size 20}	

	if {[dict exists $device_data::device_family $selected_device]} {
		set device_name [lindex [dict get $device_data::device_family $selected_device] 2]
		$w.lbl_device configure -text $device_name
	} else {
		$w.lbl_device configure -text "Unknown Device"
	}
	pack $w.lbl_device
	
	set device_family [lindex [dict get $device_data::device_family $selected_device] 0]	
	set config_pin [dict get $device_data::pin $device_family]
		
	#############  Config Status Frame ##################
	set f .frm_config_status
	ttk::labelframe $w$f -text "Config Status" -padding 10
	
	set msel_table [dict get $device_data::msel_table $device_family]
	
	set count 0
	dict for {k v} $config_pin {	
		label $w$f.lbl_$k -text "$k:"
		if {$k == "MSEL"} {
			if { [dict exists $msel_table $v] } {
				set msel_desc [format {%s (%s %s)} $v [lindex [dict get $msel_table $v] 0] [lindex [dict get $msel_table $v] 1]]
			} else {
				set msel_desc [format {%s (%s)} $v "Invalid"]
			}
			label $w$f.lbl_config_pin_$k -text $msel_desc
		} else {
			label $w$f.lbl_config_pin_$k -text $v -width 15
			if {$v == 0} {
				$w$f.lbl_config_pin_$k configure -background red
			} elseif { $v == 1 } {
				$w$f.lbl_config_pin_$k configure -background green
			}
		}
		
		grid $w$f.lbl_$k -row $count -column 0 -sticky "e"
		grid $w$f.lbl_config_pin_$k -row $count -column 1 -pady 2
		incr count 1
	}

	pack $w$f

	##################################################################

	button $w.btn_read -text "Read Again" -command "Update_Config_Status $w $f"
	pack $w.btn_read -pady 2
	
	############### MSEL Table  #############################
	set f2 .frm_msel_table
	ttk::labelframe $w$f2 -text "MSEL Table" -padding 10

	set key_count 0

	dict for {k v} $msel_table {	
	label $w$f2.lbl_msel_key$key_count -text $k
	label $w$f2.lbl_msel_val$key_count -text $v
	incr key_count 1
	}

	for {set x 0} {$x < $key_count} {incr x 1} {
	grid $w$f2.lbl_msel_key$x -row $x -column 0 -sticky "w"
	grid $w$f2.lbl_msel_val$x -row $x -column 1 -sticky "w"
	}

	pack $w$f2

	#################################################################   
   
	catch {tkwait visibility $w}
	catch {grab $w}

	foreground_win $w
}

proc OnClick_Key_Verify_Window_20nm { } {
	global selected_device
	global device_name
	global device_family

	if {[catch {Generate_Key_Verify_JAM_Files}]} {
		tk_messageBox -title "Unable to write JAM file" -message "Make sure you have write permission in this local folder" -icon error -type ok
		return
	}
	
	if { [Read_Key] } {	return }
	
	set w .dialog_window     
	catch { destroy $w }
	toplevel $w -padx 10 -pady 10
	wm resizable $w 0 0
	bind $ <ButtonPress> { raise $w }
	wm title $w "Key Verify Register for $device_name"

	label $w.lbl_device -text "$device_name" -font {-size 20}	
	pack $w.lbl_device
	
	label $w.lbl_note -text "Note: Bits not specified in the table are don't care." -wraplength 380 -justify left
	pack $w.lbl_note -anchor sw -pady 10
	set key_verify_reg [dict get $device_data::key_verify_reg $device_family]
	set key_verify_table [dict get $device_data::key_verify_table $device_family]
	#############  Key Verify Frame ##################
	set f .frm_key_verify
	ttk::labelframe $w$f -text "Key Verify Register" -padding 10
	
	set count 0

	dict for {k v} $key_verify_table {
		label $w$f.lbl_col0_$k -text [format {%s [%s]:} [lindex $v 0] $k]
		set read_value [dict get $key_verify_reg $k]	
		label $w$f.lbl_col1_$k -text $read_value -width 15
		if {$read_value == 0} {
			$w$f.lbl_col1_$k configure -background red
		} elseif { $read_value == 1 } {
			$w$f.lbl_col1_$k configure -background green
		}		
		label $w$f.lbl_col2_$k -text [lindex $v 1] -wraplength 300 -justify left
		
		grid $w$f.lbl_col0_$k -row $count -column 0 -sticky "ne"
		grid $w$f.lbl_col1_$k -row $count -column 1 -sticky "n" -pady 2
		grid $w$f.lbl_col2_$k -row $count -column 2 -sticky "w" 

		incr count 1
	}

	pack $w$f

	##################################################################

	button $w.btn_read -text "Read Again" -command "Update_Key $w $f"
	pack $w.btn_read -pady 2
	
	#################################################################   
   
   
	catch {tkwait visibility $w}
	catch {grab $w}

	foreground_win $w
}

proc OnClick_Key_Verify_Window { } {
	global device_family
	
	if { $device_family == "20nm" } { OnClick_Key_Verify_Window_20nm }
}

proc OnClick_EDCRC_Window { } {
	global selected_device
	global device_name
	global device_family

	if {[catch {Generate_EMR_Unload_JAM_Files}]} {
		tk_messageBox -title "Unable to write JAM file" -message "Make sure you have write permission in this local folder" -icon error -type ok
		return
	}
	
	if { [Read_EMR] } {	return }
	
	set w .dialog_window     
	catch { destroy $w }
	toplevel $w -padx 10 -pady 10
	wm resizable $w 0 0
	bind $ <ButtonPress> { raise $w }
	wm title $w "Error Message Register for $device_name"

	label $w.lbl_device -text "$device_name" -font {-size 20}	
	pack $w.lbl_device
	
	label $w.lbl_note -text "Note: The EMR value may not be correct when the FPGA is unconfigured or the EDCRC is not turned on." -wraplength 380 -justify left
	pack $w.lbl_note -anchor sw -pady 10
	set emr [dict get $device_data::emr $device_family]
		
	#############  EMR Frame ##################
	set f .frm_emr
	ttk::labelframe $w$f -text "Error Message Register" -padding 10
	
	set count 0
	set emr_table [dict get $device_data::emr_table $device_family]
	dict for {k v} $emr {
		# puts "$k $v"
		set emr_table_elements [dict get $emr_table $k]
		label $w$f.lbl_$k -text [format {%s[%s:%s] :} [lindex $emr_table_elements 3] [lindex $emr_table_elements 0] [lindex $emr_table_elements 1]]
		label $w$f.lbl_emr_$k -text [format {%s (%s bits)} $v [lindex $emr_table_elements 2]]
		
		grid $w$f.lbl_$k -row $count -column 0 -sticky "e"
		grid $w$f.lbl_emr_$k -row $count -column 1 -pady 2 -sticky "w"
		incr count 1
	}

	pack $w$f

	##################################################################

	button $w.btn_read -text "Read Again" -command "Update_EMR $w $f"
	pack $w.btn_read -pady 2
	
	#################################################################   
   
	############### EMR Error Type Table  #############################
	set f2 .frm_err_type_table
	ttk::labelframe $w$f2 -text "Error Type Table" -padding 10

	set count 0

	set emr_error_type [dict get $device_data::emr_error_type $device_family]
	
	if { $device_family == "20nm" } {
		dict for {k v} $emr_error_type {	
			label $w$f2.lbl_err_type_val1$count -text [lindex $v 0]
			label $w$f2.lbl_err_type_val2$count -text [lindex $v 1]
			label $w$f2.lbl_err_type_val3$count -text [lindex $v 2]
			
			grid $w$f2.lbl_err_type_val1$count -row $count -column 0 -sticky "w"
			grid $w$f2.lbl_err_type_val2$count -row $count -column 1 -sticky "w" -padx 10
			grid $w$f2.lbl_err_type_val3$count -row $count -column 2 -sticky "w"
			
			incr count 1
		}
	} elseif { $device_family == "28nm" } { 

		dict for {k v} $emr_error_type {	
			label $w$f2.lbl_err_type_key$count -text $k
			label $w$f2.lbl_err_type_val$count -text $v
			
			grid $w$f2.lbl_err_type_key$count -row $count -column 0 -sticky "w"
			grid $w$f2.lbl_err_type_val$count -row $count -column 1 -sticky "w" -padx 10
			
			incr count 1
		}
	}

	pack $w$f2

	#################################################################   
   
	catch {tkwait visibility $w}
	catch {grab $w}

	foreground_win $w
}

proc OnClick_Pulse_nCONFIG { } {
	global selected_device
	global selected_cable
	global temp_pulse_nconfig_jam

	if {[catch {Generate_Pulse_nCONFIG_JAM_Files}]} {
		tk_messageBox -title "Unable to write JAM file" -message "Make sure you have write permission in this local folder" -icon error -type ok
		return
	}
	
	if {[catch {exec quartus_jli -c $selected_cable -a RECONFIG $temp_pulse_nconfig_jam} err] } {
		tk_messageBox -title "Fail to execute JAM file" -message "$err" -icon error -type ok
		return
	}
	
	print_message "Pulse nCONFIG executed, device forced to exit user mode and reconfiguration required."
}

proc print_message { msg } {
	.frm_msg_window.lbl_msg configure -text $msg
}

proc Bin2Hex { bin } {
	set hex ""
	set remainder [expr { [string length $bin] % 4 }]
	set padding_bit ""
	if { $remainder != 0 } { set padding_bit [string repeat 0 [expr {4 - $remainder}]] }
	set rounded_data [format {%s%s} $padding_bit $bin]
	while {[string length $rounded_data] > 0} {
		set hex [append hex [dict get $helper::bin2hex_table [string range $rounded_data 0 3]]]
		set rounded_data [string range $rounded_data 4 end]	
	}	
	return $hex
}

######## MAIN #####################

# confirm Quartus is installed properly in the system
if { [auto_execok "jtagconfig"] == ""} {
	tk_messageBox -title "Quartus not found!" -message "Look like you do not have Quartus installed in your system" -icon error -type ok
	exit
}

if {[Read_Cables_Devices cables devices cable_count]} {	exit }

########################################
######## Draw GUI ######################
########################################

wm title . "Configuration Diagnostic Tool v$version"
#wm geometry . 450x480
wm resizable . 0 0
wm protocol . WM_DELETE_WINDOW { 
	if { [file exists "$temp_config_status_jam"] } { file delete "$temp_config_status_jam" }
	if { [file exists "$temp_pulse_nconfig_jam"] } { file delete "$temp_pulse_nconfig_jam" }
	if { [file exists "$temp_emr_unload_jam"] } { file delete "$temp_emr_unload_jam" }	
	if { [file exists "$temp_key_verify_jam"] } { file delete "$temp_key_verify_jam" }	
	destroy .
}

######### Select cable and device ##################
ttk::labelframe .frm_cabledevice -text "Select cable and device" -padding 10

ttk::combobox .frm_cabledevice.cb_cable -state readonly -width 40
.frm_cabledevice.cb_cable configure -value $cables
bind .frm_cabledevice.cb_cable <<ComboboxSelected>> CB_Cable_OnSelect

label .frm_cabledevice.lbl_cable -text "Cable:"
label .frm_cabledevice.lbl_device -text "Device:"

ttk::combobox .frm_cabledevice.cb_device -state disabled -width 40
bind .frm_cabledevice.cb_device <<ComboboxSelected>> CB_Device_OnSelect

grid .frm_cabledevice.lbl_cable -row 0 -column 0 -sticky "e"
grid .frm_cabledevice.lbl_device -row 1 -column 0 -sticky "e"
grid .frm_cabledevice.cb_cable -row 0 -column 1
grid .frm_cabledevice.cb_device -row 1 -column 1

######################################################

######### Cable Frequency ##################
ttk::labelframe .frm_cable_frequency -text "Set and Read Cable Frequency" -padding 10

set frequencies [list 24M 16M 6M 3M 1M 500k 100k 50k 10k]
ttk::combobox .frm_cable_frequency.cb_frequency -state disabled -width 10
.frm_cable_frequency.cb_frequency configure -value $frequencies
bind .frm_cable_frequency.cb_frequency <<ComboboxSelected>> CB_Cable_Frequency_OnSelect

label .frm_cable_frequency.lbl_freqency -text "Frequency:"
button .frm_cable_frequency.btn_read -text "Read" -state disabled -command { Read_Cable_Frequency }

grid .frm_cable_frequency.lbl_freqency -row 0 -column 0
grid .frm_cable_frequency.cb_frequency -row 0 -column 1
grid .frm_cable_frequency.btn_read -row 0 -column 2 -padx 10

######################################################

######### Functions Buttons ##################
ttk::labelframe .frm_function -text "Functions" -padding 10

button .frm_function.btn_config_pins_status -text "Config Pins Status" -state disabled -command { OnClick_Config_Pins_Status_Window }
button .frm_function.btn_key_verify -text "Key Verify" -state disabled -command { OnClick_Key_Verify_Window }
button .frm_function.btn_edcrc -text "EDCRC" -state disabled -command { OnClick_EDCRC_Window }
button .frm_function.btn_pulse_nconfig -text "Pulse nCONFIG" -state disabled -command { OnClick_Pulse_nCONFIG }

grid .frm_function.btn_config_pins_status -row 0 -column 0
grid .frm_function.btn_key_verify -row 0 -column 1
grid .frm_function.btn_edcrc -row 0 -column 2
grid .frm_function.btn_pulse_nconfig -row 0 -column 3

######################################################

######### Message Window #############################
ttk::labelframe .frm_msg_window -text "Message window" -padding 10
label .frm_msg_window.lbl_msg -borderwidth 3 -height 10 -width 50 -wraplength 350 -anchor nw -justify left -background white -relief groove
pack .frm_msg_window.lbl_msg


if { [llength $cables] == 0 } {
	print_message "No programming cable is detected, please connect the cable and reopen this tool."
} else {
	print_message [format {Total of %d cable(s) detected, please select cable and device to begin.} [llength $cables]]
}

######################################################

#place .frm_cabledevice -x 10 -y 10
pack .frm_cabledevice -anchor w -padx 10 -pady 10
# place .frm_cable_frequency -x 10 -y 100
pack .frm_cable_frequency -anchor w -padx 10 -pady 10
# place .frm_function -x 10 -y 180
pack .frm_function -anchor center -padx 10 -pady 10
# place .frm_msg_window -x 10 -y 260
pack .frm_msg_window -anchor center -padx 10 -pady 10

foreground_win .