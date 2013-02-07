Gem::Specification.new do |s|
  s.name = 'srscript'
  s.version = '0.1.4'
  s.summary = 'srscript'
    s.authors = ['James Robertson']
  s.files = Dir['lib/**/*.rb']
  s.add_dependency('sinatra')
  s.add_dependency('rscript') 
  s.signing_key = '../privatekeys/srscript.pem'
  s.cert_chain  = ['gem-public_cert.pem']
end
