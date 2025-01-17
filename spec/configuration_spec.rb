# frozen_string_literal: true

require 'spec_helper'
require 'csv'
require 'fileutils'
require_relative '../lib/typo_checker'

module TypoChecker
  RSpec.describe Configuration do
    describe '#initialize' do
      it 'initializes with default values when no arguments are passed' do
        config = Configuration.new

        expect(config.excludes).to eq([])
        expect(config.skips).to eq([])
        expect(config.stdoutput).to be(true)
      end

      it 'initializes with custom excludes, skips, and stdoutput' do
        excludes = ['file1.rb', 'file2.rb']
        skips = %w[WORD OtherWord]
        stdoutput = false

        config = Configuration.new(excludes: excludes, skips: skips, stdoutput: stdoutput)

        expect(config.excludes).to eq(excludes)
        expect(config.skips).to eq(%w[word otherword]) # Skips should be downcased
        expect(config.stdoutput).to eq(stdoutput)
      end

      it 'defaults excludes to empty array when nil is passed' do
        excludes = nil
        skips = %w[word anotherWord]
        config = Configuration.new(excludes: excludes, skips: skips)

        expect(config.excludes).to eq([])
        expect(config.skips).to eq(%w[word anotherword])
      end

      it 'defaults skips to empty array when nil is passed' do
        excludes = ['file1.rb']
        skips = nil
        config = Configuration.new(excludes: excludes, skips: skips)

        expect(config.excludes).to eq(excludes)
        expect(config.skips).to eq([])
      end

      it 'defaults stdoutput to true when nil is passed' do
        excludes = []
        skips = []
        config = Configuration.new(excludes: excludes, skips: skips)

        expect(config.stdoutput).to be(true)
      end

      it 'sets stdoutput correctly when a value is passed' do
        excludes = []
        skips = []
        stdoutput = false
        config = Configuration.new(excludes: excludes, skips: skips, stdoutput: stdoutput)

        expect(config.stdoutput).to be(false)
      end
    end

    describe '#excludes' do
      it 'returns the excludes array' do
        excludes = ['file1.rb', 'file2.rb']
        config = Configuration.new(excludes: excludes)

        expect(config.excludes).to eq(excludes)
      end
    end

    describe '#skips' do
      it 'returns the skips array in lowercase' do
        skips = %w[WORD OtherWord]
        config = Configuration.new(skips: skips)

        expect(config.skips).to eq(%w[word otherword])
      end
    end

    describe '#stdoutput' do
      it 'returns true if stdoutput is not passed and is nil' do
        stdoutput = nil
        config = Configuration.new(stdoutput: stdoutput)

        expect(config.stdoutput).to be(true)
      end

      it 'returns the passed value of stdoutput' do
        stdoutput = false
        config = Configuration.new(stdoutput: stdoutput)

        expect(config.stdoutput).to be(false)
      end

      it 'returns the passed value of stdoutput' do
        stdoutput = true
        config = Configuration.new(stdoutput: stdoutput)

        expect(config.stdoutput).to be(true)
      end
    end
  end
end
