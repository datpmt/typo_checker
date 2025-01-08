module TypoChecker
  class Configuration
    attr_reader :excludes, :skips, :stdoutput

    def initialize(excludes = nil, skips = nil, stdoutput = true)
      @excludes = excludes || []
      @skips = (skips || []).map(&:downcase)
      @stdoutput = stdoutput.nil? ? true : stdoutput
    end
  end
end
