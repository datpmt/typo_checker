module TypoChecker
  class FileScanner
    def initialize(typos, stdoutput)
      @typos = typos
      @stdoutput = stdoutput
    end

    def scan_file(path, result)
      File.foreach(path).with_index do |line, line_number|
        words = line.split(/[^a-zA-Z0-9']+/)
        check_words = words.map { |word| split_function_name(word) }.flatten
        check_words.each do |word|
          clean_word = word.gsub(/^[^\w]+|[^\w]+$/, '')
          char_index = line.index(clean_word)
          check_word(clean_word, path, line_number, char_index, result)
        end
      end
    end

    private

    def check_word(word, file, line_num, char_index, result)
      return unless @typos.key?(word.downcase)

      corrected_word = corrected_word(word, @typos[word.downcase])
      typo_details = { incorrect_word: word, correct_word: corrected_word }
      typo_path = "#{file}:#{line_num + 1}:#{char_index + 1}"
      path = file.sub(%r{^./}, '')

      result[path] ||= {}
      result[path][:typos] ||= []
      line_entry = result[path][:typos].find { |entry| entry[:line] == line_num + 1 }

      if line_entry
        line_entry[:typos] << typo_details
      else
        result[path][:typos] << { line: line_num + 1, typos: [typo_details] }
      end

      stdout(typo_path, word, corrected_word) if @stdoutput
    end

    def split_function_name(name)
      name.gsub(/([a-z])([A-Z])/, '\1 \2').split(/[\s_]+/)
    end

    def corrected_word(word, typo_correct_word)
      if word == word.capitalize
        typo_correct_word.capitalize
      elsif word == word.upcase
        typo_correct_word.upcase
      else
        typo_correct_word
      end
    end

    def stdout(typo_path, word, corrected_word)
      puts "Typo found in #{colorize_light_blue(typo_path)}: " \
            "#{colorize_red(word)} -> #{colorize_green(corrected_word)}"
    end

    def colorize_red(text)
      "\e[31m#{text}\e[0m"
    end

    def colorize_green(text)
      "\e[32m#{text}\e[0m"
    end

    def colorize_light_blue(text)
      "\e[94m#{text}\e[0m"
    end
  end
end
