# lib/typo_checker/cli.rb
require 'thor'
require 'typo_checker'

module TypoChecker
  class CLI < Thor
    desc 'scan REPO_PATH', 'Scan a repository for typos'

    def scan(repo_path)
      checker = TypoChecker::Checker.new
      checker.scan_repo(repo_path)
    end
  end
end
