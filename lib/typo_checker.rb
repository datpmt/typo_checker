# frozen_string_literal: true

require 'csv'
require 'find'
require 'fileutils'
require_relative 'typo_checker/configuration'
require_relative 'typo_checker/typos_loader'
require_relative 'typo_checker/file_scanner'
require_relative 'typo_checker/repository_scanner'

module TypoChecker
  class Checker
    def initialize(excludes = [], skips = [], stdoutput = true)
      @configuration = Configuration.new(excludes, skips, stdoutput)
    end

    def scan_repo(repo_path = Dir.pwd)
      repository_scanner = RepositoryScanner.new(repo_path, @configuration)
      repository_scanner.scan
    end
  end
end
