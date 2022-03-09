#!/usr/bin/env ruby

# file: srscript.rb


require 'sinatra'
require 'rscript'



class SRScriptError < Exception
end

class SRScript < Sinatra::Base

  def initialize(pkg_src: nil, home_pg: nil)

    raise SRScriptError, 'pkg_src cannot be nil' unless pkg_src

    super()
    @home_pg = home_pg
    @url_base = pkg_src + '/'

    @rscript = RScriptRW.new pkg_src: pkg_src

  end

  get '/' do
    package, job = @home_pg.split('#',2)
    run_job("%s%s.rsf" % [@url_base, package], job, params)
  end

  get '/do/:package/:job/*' do

    raw_args = params['splat']
    args = raw_args.join.split('/')
    run_job("%s%s.rsf" % [@url_base, params['package']], params['job'],
      params, :get, args)

  end

  get '/do/:package/:job' do |package,job|
    run_job("%s%s.rsf" % [@url_base, package], job, params)
  end

  private

  def run_job(url, job, params={}, type=:get, *qargs)

    @rscript.type = type
    result, args = @rscript.read([url, '//job:' + job, qargs].flatten)
    r = eval result

  end

end
