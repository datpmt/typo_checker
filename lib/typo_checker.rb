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
    def initialize(paths: [], excludes: [], skips: [], stdoutput: true)
      raise ArgumentError, '`paths` must be an Array' unless paths.instance_of?(Array)
      raise ArgumentError, '`excludes` must be an Array' unless excludes.instance_of?(Array)
      raise ArgumentError, '`skips` must be an Array' unless skips.instance_of?(Array)
      raise ArgumentError, '`stdoutput` must be a Boolean' unless [TrueClass, FalseClass].include?(stdoutput.class)

      @configuration = Configuration.new(paths: paths, excludes: excludes, skips: skips, stdoutput: stdoutput)
    end

    def scan_repo(repo_path = Dir.pwd)
      repository_scanner = RepositoryScanner.new(repo_path, @configuration)
      repository_scanner.scan
    end
  end
end
