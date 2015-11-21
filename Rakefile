require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/*_test.rb']
end

task :default => :test


desc "edit files (for release preparation)"
task :edit do
  rel = ENV['rel']  or
    raise "ERROR: 'rel' environment variable expected."
  filenames = Dir[*%w[lib/**/*.rb test/**/*_test.rb]]
  filenames.each do |fname|
    File.open(fname, 'r+', encoding: 'utf-8') do |f|
      content = f.read()
      x = content.gsub!(/\$Release:.*?\$/, "$Release: #{rel} $")
      f.rewind()
      f.truncate(0)
      f.write(content)
    end
  end
end
