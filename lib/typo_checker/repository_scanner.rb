require 'find'

module TypoChecker
  class RepositoryScanner
    def initialize(repo_path, configuration)
      @repo_path = repo_path
      @configuration = configuration
      @file_scanner = FileScanner.new(load_typos, configuration.stdoutput)
    end

    def scan
      cops = {}
      paths = @configuration.paths

      if paths.empty?
        # Find all files in the repository
        Find.find(@repo_path) do |path|
          next if exclude_path?(path)

          find_cops(cops, path)
        end
      else
        paths.each do |pattern|
          # Find files based on the pattern
          Dir.glob(File.join(@repo_path, pattern)) do |path|
            next if exclude_path?(path)

            find_cops(cops, path)
          end
        end
      end
      scan_result(cops)
    end

    private

    def scan_result(cops)
      cops.map do |path, data|
        data[:typos].map do |entry|
          { path: path, line: entry[:line], typos: entry[:typos] }
        end
      end.flatten
    end

    def find_cops(cops, path)
      @file_scanner.scan_file(path, cops) if valid_text_file?(path)
    end

    def valid_text_file?(path)
      File.file?(path) && text_file?(path)
    end

    def exclude_path?(path)
      exclude_patterns.any? { |pattern| path.match?(pattern) }
    end

    def exclude_patterns
      @exclude_patterns ||= @configuration.excludes + [
        %r{\.git/.*},        # Skip all files and directories inside .git
        %r{node_modules/.*}, # Skip all files and directories inside node_modules
        %r{vendor/.*},       # Skip all files and directories inside vendor
        %r{tmp/.*}           # Skip all files and directories inside tmp
      ]
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

    def load_typos
      csv_file = File.expand_path('../data/typos.csv', __dir__)
      TyposLoader.new(@configuration.skips).load_typos(csv_file)
    end
  end
end
