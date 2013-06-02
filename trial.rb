#!/usr/bin/env ruby

require 'unimidi'

notes = [ 60, 64, 70, 72]
duration = 0.5

UniMIDI::Output.use(:first) do |output|
  2.times do
    notes.each do |note|
      output.puts(0x90, note, 100)
      sleep(duration)
    end
  end
end
