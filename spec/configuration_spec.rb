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
        skips = ['WORD', 'OtherWord']
        stdoutput = false

        config = Configuration.new(excludes, skips, stdoutput)

        expect(config.excludes).to eq(excludes)
        expect(config.skips).to eq(['word', 'otherword']) # Skips should be downcased
        expect(config.stdoutput).to eq(stdoutput)
      end

      it 'defaults excludes to empty array when nil is passed' do
        skips = ['word', 'anotherWord']
        config = Configuration.new(nil, skips)

        expect(config.excludes).to eq([])
        expect(config.skips).to eq(['word', 'anotherword'])
      end

      it 'defaults skips to empty array when nil is passed' do
        excludes = ['file1.rb']
        config = Configuration.new(excludes, nil)

        expect(config.excludes).to eq(excludes)
        expect(config.skips).to eq([])
      end

      it 'defaults stdoutput to true when nil is passed' do
        config = Configuration.new([], [], nil)

        expect(config.stdoutput).to be(true)
      end

      it 'sets stdoutput correctly when a value is passed' do
        config = Configuration.new([], [], false)

        expect(config.stdoutput).to be(false)
      end
    end

    describe '#excludes' do
      it 'returns the excludes array' do
        excludes = ['file1.rb', 'file2.rb']
        config = Configuration.new(excludes)

        expect(config.excludes).to eq(excludes)
      end
    end

    describe '#skips' do
      it 'returns the skips array in lowercase' do
        skips = ['WORD', 'OtherWord']
        config = Configuration.new([], skips)

        expect(config.skips).to eq(['word', 'otherword'])
      end
    end

    describe '#stdoutput' do
      it 'returns true if stdoutput is not passed and is nil' do
        config = Configuration.new([], [], nil)

        expect(config.stdoutput).to be(true)
      end

      it 'returns the passed value of stdoutput' do
        config = Configuration.new([], [], false)

        expect(config.stdoutput).to be(false)
      end
    end
  end
end
