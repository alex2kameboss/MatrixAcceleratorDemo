#!/usr/bin/tclsh

# Open the input HEX file and the output COE file
set hex_file "input.hex"
set coe_file "output.coe"
set hex_fd [open $hex_file r]
set coe_fd [open $coe_file w]

# Write COE file header
puts $coe_fd "memory_initialization_radix=16;"
puts $coe_fd "memory_initialization_vector="

proc endianness_swap {data} {
  set ret ""
  set length [string length $data]
  for {set i 0} {$i < $length} {incr i 2} {
    set ret "[string index $data $i][string index $data [expr $i + 1]]$ret"
  }
  return $ret
}

# Process the HEX file
set first_line 1
while {[gets $hex_fd line] >= 0} {
    if {[string length $line] == 0} continue
    
    # Parse the HEX line
    set byte_count [expr 0x[string range $line 1 2]]
    set address [format %04X [expr 0x[string range $line 3 6]]]
    set record_type [string range $line 7 8]
    set data [string range $line 9 [expr 8 + $byte_count * 2]]
    
    # Process data records (type 00)
    if {$record_type == "00"} {
		if {$first_line} {
			puts -nonewline $coe_fd "[endianness_swap $data]"
			set first_line 0
		} else {
			puts -nonewline $coe_fd ", [endianness_swap $data]"
		}
    } elseif {$record_type == "01"} {
        # End of file record (type 01)
        break
    }
}

# Close COE file with a semicolon
puts $coe_fd ";"

# Close file descriptors
close $hex_fd
close $coe_fd

puts "Conversion complete. Output written to $coe_file"
