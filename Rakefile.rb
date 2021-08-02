# -*- coding: utf-8 -*-

copyright = "copyright(c) 2015-2021 kuwata-lab.com all rights reserved"

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
    $ #rake release
    $ gem push pkg/rack-test_app-1.0.0.gem
    $ git tag rel-1.0.0
    $ git push -u origin rel-1.0
    $ git push --tags
END

end


desc "edit files (for release preparation)"
task :edit do
  rel = ENV['rel']  or
    raise "ERROR: 'rel' environment variable expected."
  filenames = Dir[*%w[lib/**/*.rb test/**/*_test.rb]]
  filenames.each do |fname|
    changed = edit_file(fname) {|s|
      s = s.gsub(/\$Release:.*?\$/, "$"+"Release: #{rel} $")
      #s = s.gsub(/\$Copyright:.*?\$/, "$"+"Copyright: #{copyright} $")
      s
    }
    puts "[changed] #{fname}" if changed
  end
end


def edit_file(fname, &b)
  File.open(fname, 'r+', encoding: 'utf-8') do |f|
    s1 = f.read()
    s2 = yield s1
    if s1 != s2
      f.rewind()
      f.truncate(0)
      f.write(s2)
      return true
    else
      return false
    end
  end
end
