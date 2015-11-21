require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/*_test.rb']
end

task :default => :test


desc "show how to release"
task :help do
  puts <<END
How to release:

    $ git checkout dev
    $ git diff
    $ which ruby
    $ rake test                 # for confirmation
    $ git checkout -b rel-1.0   # or git checkout rel-1.0
    $ rake edit rel=1.0.0
    $ git diff
    $ git commit -a -m "release preparation for 1.0.0"
    $ rake build                # for confirmation
    $ rake install              # for confirmation
    $ rake release
    $ git push -u --tags origin rel-1.0
END

end


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
