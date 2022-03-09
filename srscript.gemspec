Gem::Specification.new do |s|
  s.name = 'srscript'
  s.version = '0.2.0'
  s.summary = 'A Sinatra based web server used as a rscript proxy.'
    s.authors = ['James Robertson']
  s.files = Dir['lib/srscript.rb']
  s.add_runtime_dependency('sinatra', '~> 2.2', '>=2.2.0')
  s.add_runtime_dependency('rscript', '~> 0.9', '>=0.9.0')
  s.signing_key = '../privatekeys/srscript.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'digital.robertson@gmail.com'
  s.homepage = 'https://github.com/jrobertson/srscript'
  s.required_ruby_version = '>= 2.1.2'
end
