# Rack::TestApp


Rack::TestApp is another testing helper library for Rack application.
IMO, it is more intuitive than Rack::Test.

Rack::TestApp requires Ruby >= 2.0.


## Installation

```console
$ gem install rack-test_app
```

Or:

```console
$ echo "gem 'rack-test_app'" >> Gemfile
$ bundle
```


## Example

```ruby
require 'rack'
require 'rack/lint'
require 'rack/test_app'

## sample Rack app
app = proc {|env|
  text = "{\"status\":\"OK\"}"
  headers = {"Content-Type"   => "application/json",
             "Content-Length" => text.bytesize.to_s}
  [200, headers, [text]]
}

## crate wrapper objects
http  = Rack::TestApp.wrap(Rack::Lint.new(app))
https = Rack::TestApp.wrap(Rack::Lint.new(app), env: {'HTTPS'=>'on'})

## simulates http request
result = http.GET('/api/hello', query: {'name'=>'World'})
    # or http.get(...) if you like.

## test result
r = result
assert_equal 200, r.status
assert_equal "application/json",    r.headers['Content-Type']
assert_equal "application/json",    r.content_type
assert_equal 15,                    r.content_length
assert_equal ({"status"=>"OK"}),    r.body_json
assert_equal "{\"status\":\"OK\"}", r.body_text
assert_equal "{\"status\":\"OK\"}", r.body_binary   # encoing: ASCII-8BIT
assert_equal nil,                   r.location

## (experimental) confirm environ object (if you want)
#p http.last_env
```

* You can call `http.get()`/`http.post()` instead of `http.GET()`/`http.POST()`
  if you prefer.
* `http.last_env` is an experimental feature (may be dropped in the future).


## More Examples

```ruby
## query string
r = http.GET('/api/hello', query: 'name=World')
r = http.GET('/api/hello', query: {'name'=>'World'})

## form parameters
r = http.POST('/api/hello', form: 'name=World')
r = http.POST('/api/hello', form: {'name'=>'World'})

## json
r = http.POST('/api/hello', json: {'name'=>'World'})

## multipart
mp = {
  "name1" => "value1",
  "file1" => File.open("data/example1.jpg", 'rb'),
}
r = http.POST('/api/hello', multipart: mp)

## multipart #2
boundary = "abcdefg1234567"   # or nil
mp = Rack::TestApp::MultipartBuilder.new(boundary)
mp.add("name1", "value1")
mp.add("file1", File.read('data/example1.jpg'), "example1.jpg", "image/jpeg")
r = http.POST('/api/hello', multipart: mp)

## input
r = http.POST('/api/hello', input: "x=1&y=2&z=3")

## headers
r = http.GET('/api/hello', headers: {"X-Requested-With"=>"XMLHttpRequest"})

## cookies
r = http.GET('/api/hello', cookies: "name1=value1")
r = http.GET('/api/hello', cookies: {"name1"=>"value1"})
r = http.GET('/api/hello', cookies: {"name1"=>{:name=>'name1', :value=>'value1'}})

## cookies #2
r1 = http.POST('/api/login')
r2 = http.GET('/api/hello', cookies: r1.cookies)
http.with(cookies: r1.cookies, headers: {}) do |http_|
  r3 = http_.GET('/api/hello')
end

## env
r = http.GET('/api/hello', env: {"HTTPS"=>"on"})
```


## Copyright and License

$Copyright: copyright(c) 2015 kuwata-lab.com all rights reserved $

$License: MIT-LICENSE $
