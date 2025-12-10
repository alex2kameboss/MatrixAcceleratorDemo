puts "Start flashing"
load_image runs/build/app.bin 0x400000000 bin
reset
puts "Flashing done"
exit