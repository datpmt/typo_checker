require 'csv'

module TypoChecker
  class TyposLoader
    def initialize(skips)
      @skips = skips
    end

    def load_typos
      typos = {}
      csv_file = File.expand_path('../data/typos.csv', __dir__)
      CSV.foreach(csv_file, headers: false) do |row|
        next if @skips.include?(row[0])

        typos[row[0]] = row[1]
      end
      typos
    end
  end
end
