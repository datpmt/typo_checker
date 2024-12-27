# lib/typo_checker/cli.rb
require 'thor'
require 'typo_checker'

module TypoChecker
  class CLI < Thor
    desc 'scan REPO_PATH', 'Scan a repository for typos'

    method_option :excludes, type: :array, default: [], aliases: '-e', desc: 'Skip the directories'

    def scan(repo_path)
      checker = TypoChecker::Checker.new(options[:excludes])
      checker.scan_repo(repo_path)
    end

    def self.exit_on_failure?
      true
    end
  end
end
