# frozen_string_literal: true

require 'spec_helper'
require 'csv'
require 'fileutils'
require 'pry'
require_relative '../lib/typo_checker'

RSpec.describe TypoChecker::Checker do
  let(:checker) { described_class.new(excludes) }
  let(:excludes) { [] }

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

    context 'with skips' do
      context 'downcase' do
        let(:checker) { described_class.new([], ['realiable']) }

        it 'does not include skipped typos in the typos hash' do
          expect(checker.typos['mispell']).to eq('misspell')
          expect(checker.typos).not_to have_key('realiable')
        end
      end

      context 'upcase' do
        let(:checker) { described_class.new([], ['Realiable']) }

        it 'does not include skipped typos in the typos hash' do
          expect(checker.typos['mispell']).to eq('misspell')
          expect(checker.typos).not_to have_key('realiable')
        end
      end
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

  describe '#exclude_path?' do
    let(:repo_path) { '/path/to/repo' }

    context 'when excludes is empty' do
      it 'excludes files inside node_modules' do
        expect(checker.send(:exclude_path?, "#{repo_path}/node_modules/file.js")).to be true
      end

      it 'excludes files inside vendor' do
        expect(checker.send(:exclude_path?, "#{repo_path}/vendor/file.rb")).to be true
      end

      it 'does not exclude files outside of node_modules or vendor' do
        expect(checker.send(:exclude_path?, "#{repo_path}/src/file.rb")).to be false
      end

      it 'excludes .git directories' do
        expect(checker.send(:exclude_path?, "#{repo_path}/.git/file.rb")).to be true
      end

      it 'does not exclude regular files' do
        expect(checker.send(:exclude_path?, "#{repo_path}/file.rb")).to be false
      end
    end

    context 'when excludes is not empty' do
      let(:excludes) { ['example.rb', 'folder_name/*'] }
      it 'excludes example.rb' do
        expect(checker.send(:exclude_path?, "#{repo_path}/example.rb")).to be true
      end

      it 'excludes files in folder_name' do
        expect(checker.send(:exclude_path?, "#{repo_path}/folder_name/example.rb")).to be true
      end
    end
  end

  describe 'text_file?' do
    let(:repo_path) { '/path/to/repo' }

    it 'excludes log files' do
      expect(checker.send(:text_file?, "#{repo_path}/file.log")).to be false
    end
  end

  describe '#load_typos' do
    context 'when no skips are provided' do
      it 'loads typos from a CSV file' do
        checker = TypoChecker::Checker.new

        typos = checker.send(:load_typos)

        expect(typos['mispell']).to eq('misspell')
        expect(typos['realiable']).to eq('reliable')
      end
    end

    context 'when skips are provided' do
      it 'skips the typos in the skips list' do
        checker = TypoChecker::Checker.new([], ['mispell'])

        typos = checker.send(:load_typos)

        expect(typos['mispell']).to eq(nil)
        expect(typos['realiable']).to eq('reliable')
      end
    end
  end
end
