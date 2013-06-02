#!usr/bin/env ruby

require 'unimidi'

C  = Bs = 0
Cs = Df = 1
D  =      2
Ds = Ef = 3
E  = Ff = 4
Es = F  = 5
Fs = Gf = 6
G  =      7
Gs = Af = 8
A  =      9
As = Bf = 10
B  = Cf = 11
OCTAVE  = 12
R       = nil

BPM = 140

module Meter
  Q = (60/BPM.to_f) # quarter notes
  W = Q * 4         # whole notes
  H = W / 2         # half notes
  E = Q / 2         # eighth notes
  S = E / 2         # sixteenth notes
  T = S / 2         # thirty-second notes

  DH = H + Q        # Dotted notes
  DQ = Q + E
  DE = E + S
  DS = S + T

  HT = W / 3        # Triplets
  QT = H / 3
  ET = Q / 3
  ST = E / 3

  def method_missing(method, *opts, &block)
    if duration = method.to_s.match(/^(\w.?)$/)
    duration = duration[1].upcase

      if Meter.constants.include? duration.to_sym
        Note.new(duration, self)
      end
    end
  end
end

class Fixnum
  include Meter

  def [](octave)
    if octave.eql? :middle
      self + (OCTAVE * 4)
    else
      self + (OCTAVE * octave)
    end
  end
end

class NilClass
  include Meter   # This will allow nil to represent rests.
end

class Array
  include Meter   # Arrays use numbers as chords.
end

module ArrayContainer
  attr_accessor :container

  def method_missing(method,*opts, &block)
    if @container.respond_to? method
      @container.send(method, *opts, &block)
    end
  end
end

class Note
  VOLUME = 100    # min: 0 - max: 100
  ON  = 0x90
  OFF = 0x80

  include ArrayContainer

  attr_reader :duration
  attr_writer :voice

  def initialize(duration, pitches, voice = nil)
    @duration = Meter.const_get(duration)
    @container = [*pitches].flatten
    @voice = voice
  end

  def play
    start
    sleep duration
    stop
  end

  def start
    @container.each do |note|
      @voice.puts(ON, note, VOLUME) unless note.nil?
    end
  end

  def stop
    @container.each do |note|
      @voice.puts(OFF, note, VOLUME) unless note.nil?
    end
  end

  def dup
    note = super
    note.container = note.container.dup
    note
  end

  def key=(key)
    @container.map! {|pitch| pitch + key}
  end
end

class Sequence
  include ArrayContainer

  def initialize
    @container = []
    yield self if block_given?
  end

  def <<(sequence)
    @container.push *sequence
  end

  def key=(key)
    key.push(*key.dup) until key.count >= self.count

    self.zip(key).map do |note, key|
      note.key = key
    end
  end
end

class Instrument
  attr_accessor :voice, :key, :song

  def initialize(key)
    @song = Sequence.new
    @key = key

    @voice = UniMIDI::Output.use(:first)
  end

  def add(*notes)
    @song << Sequence.new do |sequence|
      notes = notes.shift if notes.first.is_a? Array

      sequence << notes.map do |note|
        note = note.dup
        note.key = @key
        note.voice = @voice
        note
      end

      sequence.key = yield if block_given?
    end
  end

  def clear
    @song.clear
  end

  def play
    @song.map(&:play)
  end
end

###################################
