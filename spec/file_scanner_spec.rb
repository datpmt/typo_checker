# frozen_string_literal: true

require 'spec_helper'
require 'csv'
require 'fileutils'
require_relative '../lib/typo_checker'

module TypoChecker
  RSpec.describe FileScanner do
    let(:typos) { { 'mumber' => 'number', 'languege' => 'language', 'knowlege' => 'knowledge' } }
    let(:stdoutput) { true }
    let(:file_scanner) { FileScanner.new(typos, stdoutput) }
    let(:repo_path) { 'spec/fixtures/test_repo' }
    let(:result) { {} }
    let(:line_number) { 1 }
    let(:char_index) { 5 }

    def create_ruby_file
      File.write(File.join(repo_path, 'example.rb'), <<~RUBY)
        def mumber_sum
          puts "This is a test"
          puts 'languege'
          puts 'knowlege: languege' # typo
        end
        mumber_sum()
      RUBY
    end

    describe '#initialize' do
      it 'initializes with typos and stdoutput' do
        expect(file_scanner.instance_variable_get(:@typos)).to eq(typos)
        expect(file_scanner.instance_variable_get(:@stdoutput)).to be(true)
      end
    end

    describe '#scan_file' do
      let(:result) { {} }

      before do
        FileUtils.mkdir_p(repo_path)
        create_ruby_file
      end

      after do
        FileUtils.remove_entry(repo_path)
      end

      it 'processes the file and identifies typos' do
        file_scanner.scan_file(File.join(repo_path, 'example.rb'), result)
        found_typos = result[File.join(repo_path, 'example.rb')]
        found_typos_expected = {
          typos: [
            { line: 1, typos: [{ incorrect_word: 'mumber', correct_word: 'number' }] },
            { line: 3, typos: [{ incorrect_word: 'languege', correct_word: 'language' }] },
            { line: 4,
              typos: [
                { incorrect_word: 'knowlege', correct_word: 'knowledge' },
                { incorrect_word: 'languege', correct_word: 'language' }
              ] },
            { line: 6, typos: [{ incorrect_word: 'mumber', correct_word: 'number' }] }
          ]
        }

        expect(found_typos).to eq(found_typos_expected)
      end

      it 'does not add typos if there are none' do
        File.write(File.join(repo_path, 'example_no_typos.rb'), <<~RUBY)
          def sum
            puts "This is a correct line."
          end
          sum()
        RUBY

        file_scanner.scan_file(File.join(repo_path, 'example_no_typos.rb'), result)
        found_typos = result[File.join(repo_path, 'example_no_typos.rb')]

        expect(found_typos).to be_nil
      end
    end

    describe '#check_word' do
      let(:file_path) { File.join(repo_path, 'example.rb') }
      context 'when the word is in the typos hash' do
        it 'adds the typo to the result with the correct details' do
          file_scanner.send(:check_word, 'mumber', file_path, line_number, char_index, result)

          expect(result[file_path][:typos]).to eq([
            { line: line_number + 1, typos: [{ incorrect_word: 'mumber', correct_word: 'number' }] }
          ])
        end

        it 'handles capitalization correctly' do
          file_scanner.send(:check_word, 'Mumber', file_path, line_number, char_index, result)

          expect(result[file_path][:typos]).to eq([
            { line: line_number + 1, typos: [{ incorrect_word: 'Mumber', correct_word: 'Number' }] }
          ])
        end

        it 'adds multiple typos to the same line' do
          file_scanner.send(:check_word, 'mumber', file_path, line_number, char_index, result)
          file_scanner.send(:check_word, 'languege', file_path, line_number, char_index + 10, result)

          expect(result[file_path][:typos]).to eq([
            { line: line_number + 1, typos: [
              { incorrect_word: 'mumber', correct_word: 'number' },
              { incorrect_word: 'languege', correct_word: 'language' }
            ]}
          ])
        end
      end

      context 'when the word is not in the typos hash' do
        it 'does not add anything to the result' do
          file_scanner.send(:check_word, 'correct', file_path, line_number, char_index, result)

          expect(result[file_path]).to be_nil
        end
      end

      context 'when stdoutput is true' do
        it 'prints the correct output' do
          expect { file_scanner.send(:stdout, 'file.rb:1:6', 'mumber', 'number') }.to output(
            "Typo found in \e[94mfile.rb:1:6\e[0m: \e[31mmumber\e[0m -> \e[32mnumber\e[0m\n"
          ).to_stdout
        end
      end

      context 'when stdoutput is false' do
        let(:stdoutput) { false }
        let(:file_scanner) { FileScanner.new(typos, stdoutput) }

        it 'does not print output' do
          expect { file_scanner.send(:stdout, 'file.rb:1:6', 'mumber', 'number') }.not_to output.to_stdout
        end
      end
    end

    describe '#stdout' do
      let(:typo_path) { 'file.rb:1:6' }
      let(:word) { 'misteak' }
      let(:corrected_word) { 'mistake' }

      it 'prints the correct output when stdoutput is true' do
        expect { file_scanner.send(:stdout, typo_path, word, corrected_word) }.to output(
          "Typo found in \e[94mfile.rb:1:6\e[0m: \e[31mmisteak\e[0m -> \e[32mmistake\e[0m\n"
        ).to_stdout
      end

      it 'does not print output when stdoutput is false' do
        file_scanner = FileScanner.new(typos, false)

        expect { file_scanner.send(:stdout, typo_path, word, corrected_word) }.not_to output.to_stdout
      end
    end

    describe '#split_function_name' do
      it 'splits camelCase to separate words' do
        result = file_scanner.send(:split_function_name, 'mumberSum')

        expect(result).to eq(['mumber', 'Sum'])
      end

      it 'splits PascalCase to separate words' do
        result = file_scanner.send(:split_function_name, 'MumberSum')

        expect(result).to eq(['Mumber', 'Sum'])
      end

      it 'splits snake_case to separate words' do
        result = file_scanner.send(:split_function_name, 'mumber_sum')

        expect(result).to eq(['mumber', 'sum'])
      end

      it 'handles mixed snake_case and camelCase' do
        result = file_scanner.send(:split_function_name, 'mumber_Sum')

        expect(result).to eq(['mumber', 'Sum'])
      end

      it 'returns the same word if it is a single word' do
        result = file_scanner.send(:split_function_name, 'sum')

        expect(result).to eq(['sum'])
      end

      it 'splits words with digits correctly' do
        result = file_scanner.send(:split_function_name, 'mumber3Sum')

        expect(result).to eq(['mumber', '3', 'Sum'])
      end

      it 'returns an empty array for empty input' do
        result = file_scanner.send(:split_function_name, '')

        expect(result).to eq([])
      end

      it 'splits camelCase function names' do
        expect(file_scanner.send(:split_function_name, 'camelCaseFunction')).to eq(%w[camel Case Function])
      end

      it 'splits snake_case function names' do
        expect(file_scanner.send(:split_function_name, 'snake_case_function')).to eq(%w[snake case function])
      end

      it 'splits words in mixed cases correctly' do
        expect(file_scanner.send(:split_function_name,
                            'CamelAndSnake_caseFunction')).to eq(%w[Camel And Snake case Function])
      end
    end

    describe '#corrected_word' do
      context 'when the original word is capitalized' do
        it 'capitalizes the corrected word' do
          corrected = file_scanner.send(:corrected_word, 'Mumber', 'number')
          expect(corrected).to eq('Number')
        end
      end

      context 'when the original word is uppercase' do
        it 'returns the corrected word in uppercase' do
          corrected = file_scanner.send(:corrected_word, 'MUMBER', 'number')
          expect(corrected).to eq('NUMBER')
        end
      end

      context 'when the original word is lowercase' do
        it 'returns the corrected word in lowercase' do
          corrected = file_scanner.send(:corrected_word, 'mumber', 'number')
          expect(corrected).to eq('number')
        end
      end

      context 'when the original word has mixed case' do
        it 'preserves the case of the corrected word' do
          corrected = file_scanner.send(:corrected_word, 'mUMber', 'number')
          expect(corrected).to eq('number')
        end
      end

      context 'when the corrected word is the same as the original word' do
        it 'returns the corrected word as is' do
          corrected = file_scanner.send(:corrected_word, 'number', 'number')
          expect(corrected).to eq('number')
        end
      end
    end
  end
end
