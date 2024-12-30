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

  describe '#scan_repo' do
    let(:repo_path) { 'spec/fixtures/test_repo' }

    before do
      FileUtils.mkdir_p(repo_path)

      # Create language-specific files with typos
      create_ruby_file
      create_python_file
      create_javascript_file
      create_java_file
      create_php_file
    end

    after do
      FileUtils.remove_entry(repo_path)
    end

    it 'detects typos in Ruby files' do
      output = capture_stdout { checker.scan_repo(repo_path) }
      output = clean_output(output)
      expect(output).to match(%r{Typo found in #{repo_path}/example.rb:1:5: mumber -> number})
      expect(output).to match(%r{Typo found in #{repo_path}/example.rb:4:1: mumber -> number})
    end

    it 'detects typos in Python files' do
      output = capture_stdout { checker.scan_repo(repo_path) }
      output = clean_output(output)
      expect(output).to match(%r{Typo found in #{repo_path}/example.py:1:5: mumber -> number})
      expect(output).to match(%r{Typo found in #{repo_path}/example.py:4:1: mumber -> number})
    end

    it 'detects typos in JavaScript files' do
      output = capture_stdout { checker.scan_repo(repo_path) }
      output = clean_output(output)
      expect(output).to match(%r{Typo found in #{repo_path}/example.js:1:10: mumber -> number})
      expect(output).to match(%r{Typo found in #{repo_path}/example.js:4:1: mumber -> number})
    end

    it 'detects typos in Java files' do
      output = capture_stdout { checker.scan_repo(repo_path) }
      output = clean_output(output)
      expect(output).to match(%r{Typo found in #{repo_path}/Example.java:2:24: mumber -> number})
      expect(output).to match(%r{Typo found in #{repo_path}/Example.java:7:9: mumber -> number})
    end

    it 'detects typos in PHP files' do
      output = capture_stdout { checker.scan_repo(repo_path) }
      output = clean_output(output)
      expect(output).to match(%r{Typo found in #{repo_path}/example.php:2:10: mumber -> number})
      expect(output).to match(%r{Typo found in #{repo_path}/example.php:6:1: mumber -> number})
    end

    it '#found_typos' do
      found_typos = checker.scan_repo(repo_path)
      found_typos_expected = [
        {
          path: "#{repo_path}/Example.java",
          line: 2,
          typos: { incorrect_word: 'mumber', correct_word: 'number' }
        },
        {
          path: "#{repo_path}/Example.java",
          line: 7,
          typos: { incorrect_word: 'mumber', correct_word: 'number' }
        },
        {
          path: "#{repo_path}/example.js",
          line: 1,
          typos: { incorrect_word: 'mumber', correct_word: 'number' }
        },
        {
          path: "#{repo_path}/example.js",
          line: 4,
          typos: { incorrect_word: 'mumber', correct_word: 'number' }
        },
        {
          path: "#{repo_path}/example.php",
          line: 2,
          typos: { incorrect_word: 'mumber', correct_word: 'number' }
        },
        {
          path: "#{repo_path}/example.php",
          line: 6,
          typos: { incorrect_word: 'mumber', correct_word: 'number' }
        },
        {
          path: "#{repo_path}/example.py",
          line: 1,
          typos: { incorrect_word: 'mumber', correct_word: 'number' }
        },
        {
          path: "#{repo_path}/example.py",
          line: 4,
          typos: { incorrect_word: 'mumber', correct_word: 'number' }
        },
        {
          path: "#{repo_path}/example.rb",
          line: 1,
          typos: { incorrect_word: 'mumber', correct_word: 'number' }
        },
        {
          path: "#{repo_path}/example.rb",
          line: 4,
          typos: { incorrect_word: 'mumber', correct_word: 'number' }
        }
      ]
      expect(found_typos).to eq found_typos_expected
    end

    private

    def create_ruby_file
      File.write(File.join(repo_path, 'example.rb'), <<~RUBY)
        def mumber_sum
          puts "This is a test"
        end
        mumber_sum()
      RUBY
    end

    def create_python_file
      File.write(File.join(repo_path, 'example.py'), <<~PYTHON)
        def mumber_sum():
            print("This is a test")

        mumber_sum()
      PYTHON
    end

    def create_javascript_file
      File.write(File.join(repo_path, 'example.js'), <<~JAVASCRIPT)
        function mumber_sum() {
          console.log("This is a test");
        }
        mumber_sum();
      JAVASCRIPT
    end

    def create_java_file
      File.write(File.join(repo_path, 'Example.java'), <<~JAVA)
        public class Example {
            public static void mumber_sum() {
                System.out.println("This is a test");
            }

            public static void main(String[] args) {
                mumber_sum();
            }
        }
      JAVA
    end

    def create_php_file
      File.write(File.join(repo_path, 'example.php'), <<~PHP)
        <?php
        function mumber_sum() {
            echo "This is a test\n";
        }
        mumber_sum();
        ?>
      PHP
    end

    def clean_output(output)
      # Remove any ANSI escape codes (if present)
      output.gsub(/\e\[\d+([;\d+])*m/, '')
    end
  end
end
