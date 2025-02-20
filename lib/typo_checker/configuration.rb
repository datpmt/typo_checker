module TypoChecker
  class Configuration
    attr_reader :paths, :excludes, :skips, :stdoutput

    def initialize(paths: [], excludes: [], skips: [], stdoutput: true)
      @paths = paths || []
      @excludes = excludes || []
      @skips = (skips || []).map(&:downcase)
      @stdoutput = stdoutput.nil? || stdoutput
    end
  end
end
