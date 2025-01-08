require 'csv'

module TypoChecker
  class TyposLoader
    def initialize(skips)
      @skips = skips
    end

    def load_typos(file_path)
      typos = {}
      CSV.foreach(file_path, headers: false) do |row|
        next if @skips.include?(row[0])

        typos[row[0]] = row[1]
      end
      typos
    end
  end
end
