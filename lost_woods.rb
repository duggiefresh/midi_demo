#!/usr/bin/env ruby

require 'unimidi'

# s = sharp and f = flat
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
  include Meter
end

class Array
  include Meter
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

############################################

# Create some instruments.
sop = Instrument.new C[6]
alt = Instrument.new C[5]
ten = Instrument.new C[:middle]
bas = Instrument.new C[3]

# Lost Woods from Zelda 64
sop.add R.w,                                    R.w
alt.add F.e, A.e, B.q,      F.e, A.e, B.q,      F.e, A.e, B.e, E.e, D.q,      B.e, C.e
ten.add R.e, C.e, C.e, C.e, R.e, C.e, C.e, C.e, R.e, C.e, C.e, C.e, R.e, C.e, C.e, C.e
bas.add F.e, A.e, A.e, A.e, F.e, A.e, A.e, A.e, F.e, A.e, A.e, A.e, F.e, A.e, A.e, A.e

sop.add R.w,                                    R.w
alt.add B.e, G.e, E.h,                R.e, D.e, E.e, G.e, E.h,                R.q
ten.add R.e, C.e, C.e, C.e, R.e, C.e, C.e, C.e, R.e, C.e, C.e, C.e, R.e, C.e, C.e, C.e
bas.add E.e, G.e, G.e, G.e, E.e, G.e, G.e, C.e, E.e, G.e, G.e, G.e, E.e, G.e, G.e, C.e
# Measure 5
sop.add R.w,                                    R.w
alt.add F.e, A.e, B.q,      F.e, A.e, B.q,      F.e, A.e, B.e, E.e, D.q,      B.e, C.e
ten.add R.e, C.e, C.e, C.e, R.e, C.e, C.e, C.e, R.e, C.e, C.e, C.e, R.e, C.e, C.e, C.e
bas.add F.e, A.e, A.e, A.e, F.e, A.e, A.e, A.e, F.e, A.e, A.e, A.e, F.e, A.e, A.e, A.e

sop.add R.w,                                    R.w
alt.add E.e, B.e, G.h,                R.e, B.e, G.e, D.e, E.h,                R.q
ten.add R.e, C.e, C.e, C.e, R.e, C.e, C.e, C.e, R.e, C.e, C.e, C.e, R.e, C.e, C.e, C.e
bas.add E.e, G.e, G.e, G.e, E.e, G.e, G.e, C.e, E.e, G.e, G.e, G.e, E.e, G.e, G.e, E.e
# Measure 9
sop.add R.w,                                    R.w
alt.add D.e, E.e, F.q,      G.e, A.e, B.q,      C.e, B.e, E.h,                R.q
ten.add R.e, A.e, R.e, A.e, R.e, G.e, R.e, G.e, R.e, C.e, R.e, C.e, R.e, A.e, R.e, A.e
bas.add D.e, F.e, D.e, F.e, G.e, D.e, G.e, D.e, C.e, E.e, C.e, E.e, A.e, E.e, A.e, E.e

sop.add F.e, G.e, A.q,      B.e, C[1].e,        D[1].q,   E[1].e,   F[1].e,   G[1].h, R.q
alt.add D.e, E.e, F.q,      G.e, A.e, B.q,      C[1].e,   D[1].e,   E[1].h,   R.q
ten.add R.e, A.e, R.e, A.e, R.e, G.e, R.e, G.e, R.e, C.e, R.e, C.e, R.e, A.e, R.e, A.e
bas.add D.e, F.e, D.e, F.e, G.e, D.e, G.e, D.e, C.e, E.e, C.e, E.e, A.e, E.e, A.e, E.e

# Measure 13
sop.add R.w,                                    R.w
alt.add D.e, E.e, F.q,      G.e, A.e, B.q,      C.e, B.e, E.h,                R.q
ten.add R.e, A.e, R.e, A.e, R.e, G.e, R.e, G.e, R.e, C.e, R.e, C.e, R.e, A.e, R.e, A.e
bas.add D.e, F.e, D.e, F.e, G.e, D.e, G.e, D.e, C.e, E.e, C.e, E.e, A.e, E.e, A.e, E.e

sop.add F.e, E.e, A.e, G.e, B.e, A.e, C[1].e, B.e,
  D[1].e, C[1].e, E[1].e, D[1].e, F[1].e, E[1].e, E[1].s, F[1].e, D[1].s
alt.add D.e, C.e, F.e, E.e, G.e, F.e, A.e, G.e,
  B.e, A.e, C[1].e,   B.e, D[1].e,   C[1].e, B.s, C[1].e, A.s
ten.add R.e, A.e, A.e, R.e, R.e, A.e, A.e, R.e, R.e, B.e, B.e, R.e, R.e, B.e, B.e, R.e
bas.add D.e, F.e, F.e, R.e, D.e, F.e, F.e, R.e, C.e, G.e, G.e, R.e, C.e, G.e, G.e, R.e

# Measure 17
sop.add E.w,                                    R.h,                R.q,     B[1].e, R.e
alt.add B.w,                                    R.h,                R.q,     E[1].e, R.e
ten.add R.e, B.e, R.e, B.e, R.e, B.e, R.e, B.e, R.e, B.e,  B.e,  B.e,  B.e,  R.e, E[1].e, R.e
bas.add E.e, A.e, R.e, A.e, E.e, A.e, R.e, A.e, E.e, Gs.e, Gs.e, Gs.e, Gs.e, R.e, E.e, R.e

song = [bas, ten, alt, sop]

song.map {|song| Thread.new {song.play} }.map(&:join)
