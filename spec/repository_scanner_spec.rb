# frozen_string_literal: true

require 'spec_helper'
require 'csv'
require 'fileutils'
require_relative '../lib/typo_checker'

module TypoChecker
  RSpec.describe RepositoryScanner do
    let(:repo_path) { 'spec/fixtures/test_repo' }
    let(:paths) { [] }
    let(:excludes) { [] }
    let(:skips) { [] }
    let(:configuration) { double('Configuration', paths: paths, excludes: excludes, skips: skips, stdoutput: true) }
    let(:typos) { { 'mumber' => 'number', 'languege' => 'language' } }
    let(:file_scanner) { double('FileScanner') }
    let(:repository_scanner) { RepositoryScanner.new(repo_path, configuration) }

    before do
      allow(FileScanner).to receive(:new).and_return(file_scanner)
      allow(file_scanner).to receive(:scan_file)
      allow(repository_scanner).to receive(:load_typos).and_return(typos)
    end

    describe '#initialize' do
      it 'initializes with the correct repo_path and configuration' do
        expect(repository_scanner.instance_variable_get(:@repo_path)).to eq(repo_path)
        expect(repository_scanner.instance_variable_get(:@configuration)).to eq(configuration)
      end
    end

    describe '#scan' do
      let(:result) { {} }

      before do
        FileUtils.mkdir_p(repo_path)
        File.write(File.join(repo_path, 'example.rb'), "def mumber_sum\nputs 'languege'\nend")
        File.write(File.join(repo_path, 'example1.rb'), "def mumber_sum\nputs 'languege'\nend")
      end

      after do
        FileUtils.remove_entry(repo_path)
      end

      it 'finds files in the repo and scans them for typos' do
        allow(file_scanner).to receive(:scan_file) do |path, result|
          result[path] = { typos: [{ line: 2, typos: [{ incorrect_word: 'languege', correct_word: 'language' }] }] }
        end

        result = repository_scanner.scan

        expected_result = [
          { path: File.join(repo_path, 'example.rb'), line: 2, typos: [{ incorrect_word: 'languege', correct_word: 'language' }] },
          { path: File.join(repo_path, 'example1.rb'), line: 2, typos: [{ incorrect_word: 'languege', correct_word: 'language' }] }
        ]

        expect(result).to eq(expected_result)
      end

      it 'with paths specified, only scans those paths' do
        allow(configuration).to receive(:paths).and_return(['example.rb'])
        allow(file_scanner).to receive(:scan_file) do |path, result|
          result[path] = { typos: [{ line: 2, typos: [{ incorrect_word: 'languege', correct_word: 'language' }] }] }
        end

        result = repository_scanner.scan

        # Only the specified file should be scanned
        expected_result = [
          { path: File.join(repo_path, 'example.rb'), line: 2, typos: [{ incorrect_word: 'languege', correct_word: 'language' }] }
        ]

        expect(result).to eq(expected_result)
      end

      it 'does not process excluded paths' do
        allow(configuration).to receive(:excludes).and_return(['example.rb'])
        allow(file_scanner).to receive(:scan_file) do |path, result|
          result[path] = { typos: [{ line: 2, typos: [{ incorrect_word: 'languege', correct_word: 'language' }] }] }
        end

        result = repository_scanner.scan

        expected_result = [
          { path: File.join(repo_path, 'example1.rb'), line: 2, typos: [{ incorrect_word: 'languege', correct_word: 'language' }] }
        ]

        expect(result).to eq(expected_result)
      end

      it 'excludes specific directories like .git, node_modules, vendor, tmp' do
        excluded_paths = ['.git', 'node_modules', 'vendor', 'tmp']

        excluded_paths.each do |excluded_dir|
          allow(Find).to receive(:find).and_yield(File.join(repo_path, excluded_dir, 'file.rb'))
          result = repository_scanner.scan
          expect(result).to be_empty
        end
      end

      it 'processes only text files' do
        allow(repository_scanner).to receive(:text_file?).and_return(true)

        # Simulate an unsupported file type (e.g., .log file)
        allow(Find).to receive(:find).and_yield(File.join(repo_path, 'example.log'))
        result = repository_scanner.scan

        expect(result).to be_empty
      end

      it 'scans files matching the specified pattern' do
        allow(configuration).to receive(:paths).and_return(['*.rb'])
        allow(file_scanner).to receive(:scan_file) do |path, result|
          result[path] = { typos: [{ line: 2, typos: [{ incorrect_word: 'languege', correct_word: 'language' }] }] }
        end

        result = repository_scanner.scan

        expected_result = [
          { path: File.join(repo_path, 'example.rb'), line: 2, typos: [{ incorrect_word: 'languege', correct_word: 'language' }] },
          { path: File.join(repo_path, 'example1.rb'), line: 2, typos: [{ incorrect_word: 'languege', correct_word: 'language' }] }
        ]

        expect(result).to eq(expected_result)
      end
    end

    describe '#exclude_path?' do
      context 'when the path matches an exclude pattern from @configuration.excludes' do
        let(:excludes) { ['/path/to/exclude/file.rb'] }

        it 'returns true' do
          path = '/path/to/exclude/file.rb'
          expect(repository_scanner.send(:exclude_path?, path)).to be true
        end
      end

      context 'when the path matches a default exclude pattern' do
        let(:excludes) { [] }

        it 'returns true for .git directory' do
          path = '/path/to/repo/.git/somefile.rb'
          expect(repository_scanner.send(:exclude_path?, path)).to be true
        end

        it 'returns true for node_modules directory' do
          path = '/path/to/repo/node_modules/somefile.js'
          expect(repository_scanner.send(:exclude_path?, path)).to be true
        end

        it 'returns true for vendor directory' do
          path = '/path/to/repo/vendor/somefile.css'
          expect(repository_scanner.send(:exclude_path?, path)).to be true
        end

        it 'returns true for tmp directory' do
          path = '/path/to/repo/tmp/somefile.log'
          expect(repository_scanner.send(:exclude_path?, path)).to be true
        end
      end

      context 'when the path does not match any exclude pattern' do
        let(:excludes) { [] }

        it 'returns false' do
          path = '/path/to/repo/file.rb'
          expect(repository_scanner.send(:exclude_path?, path)).to be false
        end
      end

      context 'when the path matches a exclude pattern' do
        let(:excludes) { [] }

        it 'returns true for .git directory' do
          path = '/path/to/repo/.git/somefile.yml'
          expect(repository_scanner.send(:exclude_path?, path)).to be true
        end

        it 'returns true for vendor directory' do
          path = '/path/to/repo/vendor/somefile.yml'
          expect(repository_scanner.send(:exclude_path?, path)).to be true
        end

        it 'returns true for node_modules directory' do
          path = '/path/to/repo/node_modules/somefile.yml'
          expect(repository_scanner.send(:exclude_path?, path)).to be true
        end

        it 'returns true for tmp directory' do
          path = '/path/to/repo/tmp/somefile.yml'
          expect(repository_scanner.send(:exclude_path?, path)).to be true
        end

        it 'does not exclude files outside' do
          path = '/path/to/repo/src/somefile.yml'
          expect(repository_scanner.send(:exclude_path?, path)).to be false
        end
      end
    end

    describe '#exclude_path?' do
      it 'returns true for paths matching exclude patterns' do
        allow(repository_scanner).to receive(:exclude_patterns).and_return(['example.rb'])

        result = repository_scanner.send(:exclude_path?, File.join(repo_path, 'example.rb'))

        expect(result).to be(true)
      end

      it 'returns false for paths not matching exclude patterns' do
        allow(repository_scanner).to receive(:exclude_patterns).and_return(['example.rb'])

        result = repository_scanner.send(:exclude_path?, File.join(repo_path, 'another_file.rb'))

        expect(result).to be(false)
      end
    end

    describe '#text_file?' do
      it 'returns false for non-text files (e.g., .log files)' do
        result = repository_scanner.send(:text_file?, File.join(repo_path, 'example.log'))
        expect(result).to be(false)
      end

      it 'returns true for supported text files' do
        result = repository_scanner.send(:text_file?, File.join(repo_path, 'example.rb'))
        expect(result).to be(true)
      end
    end
  end
end
