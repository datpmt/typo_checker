# frozen_string_literal: true

require 'csv'
require 'find'
require 'fileutils'

module TypoChecker
  class Checker
    attr_reader :typos, :excludes, :skips, :found_typos, :stdoutput

    def initialize(excludes = [], skips = [], stdoutput = true)
      @excludes = excludes
      @skips = skips.map(&:downcase)
      @typos = load_typos
      @found_typos = []
      @stdoutput = stdoutput
    end

    def scan_repo(repo_path = Dir.pwd)
      Find.find(repo_path) do |path|
        next if exclude_path?(path)

        scan_file(path) if File.file?(path) && text_file?(path)
      end

      @found_typos
    end

    private

    def exclude_path?(path)
      exclude_patterns.any? { |pattern| path.match?(pattern) }
    end

    def exclude_patterns
      @exclude_patterns ||= excludes + [
        %r{\.git/.*},        # Skip all files and directories inside .git
        %r{node_modules/.*}, # Skip all files and directories inside node_modules
        %r{vendor/.*},       # Skip all files and directories inside vendor
        %r{tmp/.*}           # Skip all files and directories inside tmp
      ]
    end

    def load_typos
      typos = {}
      csv_file = File.expand_path('data/typos.csv', __dir__)
      CSV.foreach(csv_file, headers: false) do |row|
        next if skips.include?(row[0])

        typos[row[0]] = row[1]
      end
      typos
    end

    def text_file?(path)
      excluded_extensions = %w[.log]

      return false if excluded_extensions.include?(File.extname(path))

      %w[
        .rb .txt .md .html .css .js .py .java .php .go .swift .ts .scala .c .cpp .csharp .h .lua .pl .rs .kt
        .d .r .m .sh .bash .bat .json .yaml .xml .scss .tsv .vb .ps1 .clj .elixir .f# .vhdl .verilog
        .ada .ml .lisp .prolog .tcl .rexx .awk .sed .coffee .groovy .dart .haxe .zig .nim .crystal .reason .ocaml
        .forth .v .xhtml .julia .racket .scheme .rust .graphql
      ].include? File.extname(path)
    end

    def scan_file(path)
      File.foreach(path).with_index do |line, line_number|
        words = line.split(/[^a-zA-Z0-9']+/)
        check_words = words.map { |word| split_function_name(word) }.flatten
        check_words.each do |word|
          clean_word = word.gsub(/^[^\w]+|[^\w]+$/, '')
          char_index = line.index(clean_word)
          check_word(clean_word, path, line_number, char_index)
        end
      end
    end

    def check_word(word, file, line_num, char_index)
      return unless typos.key?(word.downcase)

      corrected_word = corrected_word(word, typos[word.downcase])
      typo_path = "#{file}:#{line_num + 1}:#{char_index + 1}"
      typo_details = {
        path: file,
        line: line_num + 1,
        typos: {
          incorrect_word: word,
          correct_word: corrected_word
        }
      }

      @found_typos << typo_details

      stdout(typo_path, word, corrected_word) if stdoutput
    end

    def split_function_name(name)
      name.gsub(/([a-z])([A-Z])/, '\1 \2').split(/[\s_]+/)
    end

    def corrected_word(word, typo_correct_word)
      if word == word.capitalize
        typo_correct_word.capitalize
      elsif word == word.upcase
        typo_correct_word.upcase
      else
        typo_correct_word
      end
    end

    def stdout(typo_path, word, corrected_word)
      puts "Typo found in #{colorize_light_blue(typo_path)}: " \
            "#{colorize_red(word)} -> #{colorize_green(corrected_word)}"
    end

    def colorize_red(text)
      "\e[31m#{text}\e[0m"
    end

    def colorize_green(text)
      "\e[32m#{text}\e[0m"
    end

    def colorize_light_blue(text)
      "\e[94m#{text}\e[0m"
    end
  end
end
