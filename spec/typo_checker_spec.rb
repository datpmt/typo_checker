# frozen_string_literal: true

require 'spec_helper'
require 'csv'
require 'fileutils'
require 'pry'
require_relative '../lib/typo_checker'

RSpec.describe TypoChecker::Checker do
  let(:checker) { described_class.new }

  def capture_stdout(&block)
    original_stdout = $stdout
    $stdout = StringIO.new
    block.call
    $stdout.string
  ensure
    $stdout = original_stdout
  end

  describe '#initialize' do
    it 'loads the typos from the CSV file' do
      expect(checker.typos['mispell']).to eq('misspell')
      expect(checker.typos['realiable']).to eq('reliable')
    end
  end

  describe '#text_file?' do
    it 'returns true for valid text file extensions' do
      valid_files = ['file.rb', 'file.txt', 'file.md', 'file.html', 'file.css', 'file.js']
      valid_files.each do |file|
        expect(checker.send(:text_file?, file)).to be true
      end
    end

    it 'returns false for non-text file extensions' do
      invalid_files = ['file.pdf', 'file.jpg', 'file.exe']
      invalid_files.each do |file|
        expect(checker.send(:text_file?, file)).to be false
      end
    end
  end

  describe '#split_function_name' do
    it 'splits camelCase function names' do
      expect(checker.send(:split_function_name, 'camelCaseFunction')).to eq(%w[camel Case Function])
    end

    it 'splits snake_case function names' do
      expect(checker.send(:split_function_name, 'snake_case_function')).to eq(%w[snake case function])
    end

    it 'splits words in mixed cases correctly' do
      expect(checker.send(:split_function_name,
                          'CamelAndSnake_caseFunction')).to eq(%w[Camel And Snake case Function])
    end
  end

  describe '#corrected_word' do
    it 'returns the corrected word with proper case' do
      expect(checker.send(:corrected_word, 'mispell', 'misspell')).to eq('misspell')
      expect(checker.send(:corrected_word, 'Mispell', 'misspell')).to eq('Misspell')
      expect(checker.send(:corrected_word, 'MISPELL', 'misspell')).to eq('MISSPELL')
    end
  end
end