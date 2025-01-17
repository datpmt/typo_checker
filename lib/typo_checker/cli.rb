# lib/typo_checker/cli.rb
require 'thor'
require 'typo_checker'

module TypoChecker
  class CLI < Thor
    desc 'scan REPO_PATH', 'Scan a repository for typos'

    method_option :paths, type: :array, default: [], aliases: '-p', desc: 'Only scan the specified paths'
    method_option :excludes, type: :array, default: [], aliases: '-e', desc: 'Skip the directories'
    method_option :skips, type: :array, default: [], aliases: '-s', desc: 'Skip the typos'

    def scan(repo_path)
      checker = TypoChecker::Checker.new(paths: options[:paths], excludes: options[:excludes], skips: options[:skips])
      checker.scan_repo(repo_path)
    end

    def self.exit_on_failure?
      true
    end
  end
end
