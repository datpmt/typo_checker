require_relative 'lib/typo_checker/version'

Gem::Specification.new do |s|
  s.name        = 'typo_checker'
  s.version     = TypoChecker::VERSION
  s.summary     = 'TypoChecker is a tool for scanning source code files for common typographical errors.'
  s.description = 'TypoChecker is a tool for scanning source code files for common typographical errors. The tool checks through text-based files in a given repository to identify and suggest corrections for any matches found.'
  s.authors     = ['datpmt']
  s.email       = 'datpmt.2k@gmail.com'
  s.files       = Dir['CHANGELOG.md', 'LICENSE', 'README.md', 'lib/**/*', 'bin/*']
  s.required_ruby_version = '>= 2.6.0'
  s.homepage = 'https://rubygems.org/gems/typo_checker'
  s.license = 'MIT'
  s.metadata = {
    'source_code_uri' => 'https://github.com/datpmt/typo_checker',
    'changelog_uri' => 'https://github.com/datpmt/typo_checker/blob/main/CHANGELOG.md'
  }
  s.add_dependency 'thor', '~> 1.3.2'
  s.executables = %w[typo_checker]
  s.files.each do |file|
    next unless file.start_with?('bin/')

    File.chmod(0o755, file) unless File.executable?(file)
  end
end
