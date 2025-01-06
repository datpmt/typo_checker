module TypoChecker
  class Configuration
    attr_reader :excludes, :skips, :stdoutput

    def initialize(excludes = [], skips = [], stdoutput = true)
      @excludes = excludes
      @skips = skips.map(&:downcase)
      @stdoutput = stdoutput
    end
  end
end
