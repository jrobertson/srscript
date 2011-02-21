#!/usr/bin/ruby

# file: srscript.rb


require 'sinatra/base'
require 'rscript'

class SRScript < Sinatra::Base


  URL_BASE = 'http://rorbuilder.info/r/heroku/' #

  @@count = 0
  @@rscript = RScript.new()
  @@url_base = 'http://rorbuilder.info/r/heroku/' #
  @@get_routes = {}; @@post_routes = {}
  @@services = {}
  @@templates = {}
  @@app = nil
  @content_type = 'text/html'

  puts 'ready'

  def initialize()
    super
    puts 'initialized at ' + Time.now.to_s
  end

  get '/bootstrap' do

    doc = Document.new(File.open('server.xml','r').read)
    server_name, url_base = XPath.match(doc.root, 'summary/*/text()').map(&:to_s)

    url = URL_BASE + 'startup-level1.rsf'
    run_script(url, '//job:bootstrap', server_name, url_base)
  end


  get '/' do
    uri, @content_type = @@app.run_projectx('registry', 'get-key', :path => 'system/homepage/uri/text()')
    redirect(uri.to_s)  
  end


  configure do
    puts 'bootstrapping ... '
    doc = Document.new(File.open('server.xml','r').read)
    localhost = XPath.first(doc.root, 'summary/localhost/text()').to_s
    Thread.new {sleep 8; open(localhost + 'bootstrap', 'UserAgent' => 'srscript')}
  end

  def run_rcscript(rsf_url, jobs, raw_args=[])
    @@rscript.read([rsf_url, jobs.split(/\s/), raw_args].flatten)
  end

  def run_script(url, jobs, *qargs)
    result, args = run_rcscript(url, jobs, qargs)
    eval(result)
  end

  def display_url_run(url, jobs, opts)
    h = {'.xml' => 'text/xml','.html' => 'text/html','.txt' => 'text/plain'}
    @content_type = h[opts[:extension]]    
    out = run_script(url, jobs, opts[:args])

    content_type @content_type, :charset => 'utf-8' if defined? content_type
    out
  end

  def check_url(url)
    url = URI.parse(url)
    Net::HTTP.start(url.host, url.port) do |http|
      return http.head(url.request_uri).code
    end
  end

  def package_run(package_id, job, opts={})
    o = {
      :extension => '.html',
      :args => []
    }.merge(opts)
    jobs = "//job:" + job

    url, @content_type = @@app.run_projectx('registry', 'get-key', :path => "system/packages/*[name='#{package_id}']/url/text()").map(&:to_s)

    url = @@url_base + url[1..-1] if url[/^\//]

    if url then
      display_url_run(url.to_s.sub(/^#{@@url_base}/,'\0s/open/'),jobs, o)
    else

      code = check_url(url)

      if code == '200' then
        url = "%s%s.rsf" % [@@url_base, package_id] 
        display_url_run(url,jobs, o)
      else
        # 404
        url = url_base + 'open-uri-error.rsf'
        run_script(url, '//job:with-code', code)
      end
    end

  end

  get '/' do
    uri, @content_type = @@app.run_projectx('registry', 'get-key', :path => 'system/homepage/uri/text()')
    redirect(uri.to_s)  
  end

  get %r{^\/([a-zA-Z0-9\-]+)$} do 
    raw_url, @content_type = @@app.run_projectx('registry', 'get-key', :path => 'system/uri_aliases/url/text()')
    url = raw_url.to_s.clone
    
    #url.sub!('http://rscript.rorbuilder.info/','\0s/open/')
    doc = Document.new(open(url, "UserAgent" => "Sinatra-Rscript").read)
    
    #url = @@url_base + "alias.xml?passthru=1"
    #doc = Document.new(open(url, "UserAgent" => "Sinatra-Rscript").read)
    node = XPath.first(doc.root, "records/alias[name='#{params[:captures][0]}' and type='r']")

    if node.nil? and not @@get_routes.has_key? params[:captures][0] then
      url = "%s%s/index.xml" % [@@url_base, params[:captures][0]]
      status = check_url url

      redirect params[:captures][0] + '/' if status == '200'
      # url = ...
      # redirect url if check_url ""params[:alias] == '200'
      pass
    else
      pass
    end
    uri = node.text('uri').to_s

    redirect uri
  end

  get '/:directory/' do  
    open("%s%s/index.xml" % [@@url_base, params[:directory]] , 'UserAgent' => 'S-Rscript').read
  end

  get '/css/:css' do

    css = params[:css]
    key = 'css/' + css

    if @@get_routes.has_key? key then
      out, @content_type = @@get_routes[key].call(params)
      @content_type ||= 'text/css'
      content_type @content_type, :charset => 'utf-8'
      out
    else
      rsf_job, @content_type = @@app.run_projectx('registry', 'get-key', :path => "system/css/*[name='css/#{css}']/rsf_job/text()")
      if rsf_job then
        redirect rsf_job.to_s 
      else
        # 404
      end
    end
  end

  get '/:form/form' do

    form = params[:form]
    key = form + '/form'

    if @@get_routes.has_key? key then
      out, @content_type = @@get_routes[key].call(params)
      @content_type ||= 'text/html'
      content_type @content_type, :charset => 'utf-8'
      out
    else
      rsf_job, @content_type = @@app.run_projectx('registry', 'get-key', :path => "system/forms/*[name='#{form}/form']/rsf_job/text()")
      if rsf_job then
        puts 'job found'
        redirect rsf_job.to_s 
      else
        # 404
      end
    end
  end

  get '/:form/form/*' do

    form = params[:form]
    key = form + '/form'
    args = params[:splat]

    if @@get_routes.has_key? key then
      out, @content_type = @@get_routes[key].call(params, args)
      @content_type ||= 'text/html'
      content_type @content_type, :charset => 'utf-8'
      out
    else
      rsf_job, @content_type = @@app.run_projectx('registry', 'get-key', :path => "system/forms/*[name='#{form}/form']/rsf_job/text()")
      if rsf_job then
        file_path = args.length > 0 ? '/' + args.join('/') : ''
        puts 'form file_path : ' + file_path.to_s
        redirect rsf_job.to_s  + file_path
      else
        # 404
      end
    end
  end

  get '/do/:package_id/:job' do
    package_id = params[:package_id] #
    job, extension = params[:job][/\.\w{3}$/] ? [$`, $&] : [params[:job], '.html']
    package_run(package_id, job, {:extension => extension})
  end

  get '/view-source/:package_id/:job' do
    package_id = params[:package_id] #
    *jobs = params[:job] 

    #url = "%s%s.rsf" % [url_base, package_id]
    url, @content_type = @@app.run_projectx('registry', 'get-key', :path => "system/packages/*[name='#{package_id}']/url/text()")
    if url then

      #redirect rsf_job.to_s 
      buffer = open(url.to_s.sub(/^http:\/\/rscript.rorbuilder.info\//,'\0s/open/'), "UserAgent" => 'Sinatra-Rscript').read
      content_type 'text/plain', :charset => 'utf-8'
      doc = Document.new(buffer)

      jobs.map!{|x| "@id='%s'" % x}
      doc.root.elements.to_a("//job[#{jobs.join(' or ')}]").map do |job|
        job.to_s
      end
    end


  end

  get '/do/:package_id/:job/*' do
    h = {'.xml' => 'text/xml','.html' => 'text/html','.txt' => 'text/plain'}
    package_id = params[:package_id] #
    job, extension = params[:job][/\.\w{3}$/] ? [$`, $&] : [params[:job], '.html']
    jobs = "//job:" + job
    raw_args = params[:splat]
    args = raw_args.join.split('/')

    package_run(package_id, job, {:extension => extension, :args => args})

  end

  get '/view-source/:package_id' do
    package_id = params[:package_id] #
    #url = "%s%s.rsf" % [url_base, package_id]
    url, @content_type = @@app.run_projectx('registry', 'get-key', :path => "system/packages/*[name='#{package_id}']/url/text()")
    if url then
      buffer = open(url.to_s.sub(/^http:\/\/rscript.rorbuilder.info\//,'\0s/open/'), "UserAgent" => 'Sinatra-Rscript').read
      content_type 'text/plain', :charset => 'utf-8'
      buffer
    end
  end

  get '/do/:package_id/' do
    redirect "/do/r/p/" + params[:package_id]
  end


  # projectx request
  get '/p/:project_name/:method_name' do
    project_name = params[:project_name]
    method_name = params[:method_name]
    r, @content_type = @@app.run_projectx(project_name, method_name, request.params)  
    
    @content_type ||= 'text/html'
    content_type @content_type, :charset => 'utf-8'
    # todo: implement a filter to check for rexml objects to be converted to a string
    r
  end


  # projectx request
  get '/p/projectx' do
    xml_project = request.params.to_a[0][1]
    projectx_handler(xml_project)
  end

  get '/load/:package_id/:job' do

    package_id = params[:package_id] #
    job, extension = params[:job][/\.\w{3}$/] ? [$`, $&] : [params[:job], '.html']
    load_rsf_job2(package_id, job, route=package_id + '/' + job, extension)
  end



  def follow_route(routes, key)
    if routes.has_key? key then      
      routes[key].call(params)
      
    else
      route = routes.detect {|k,v| key[/#{k}/]}

      if route then
        remaining = $'
        if remaining then
          args = remaining.split('/')
          args.shift
        else
          args = []
        end

        route[1].call( params, args)

      else
        puts '@@app is ' + @@app.inspect
        out, @content_type = @@app.run_projectx('dir', 'view', {:file_path => key, :passthru => params[:passthru]})
        [out, @content_type]
        #puts "no match"
      end
    end
  end

  # custom routes
  get '/*' do
    key = params[:splat].join

    if params.has_key? 'edit' and params[:edit] = '1' then
      # fetch the editor
      # we first need to know the file type
      # open the xml file
      url = @@url_base + key
      buffer = open(url.to_s.sub(/^http:\/\/rscript.rorbuilder.info\//,'\0s/open/'), "UserAgent" => 'Sinatra-Rscript').read
      doc = Document.new(buffer)
      recordx_type = XPath.first(doc.root, 'summary/recordx_type/text()').to_s
      uri, @content_type = @@app.run_projectx('registry', 'get-key', :path => "system/recordx_editor/#{recordx_type}/uri/text()")
      editor_url = @@url_base + uri.to_s + '/' + key

      redirect editor_url
    else
    
      out, content_type = follow_route(@@get_routes, key)  
      #puts out
      puts 'Content type : ' + content_type unless content_type.nil?
      content_type ||= 'text/html'
      content_type        content_type, :charset => 'utf-8'
      out
    end
  end

  post '/*' do
    key = params[:splat].join
    out, content_type = follow_route(@@post_routes, key)
    #puts 'sss' + out.to_s
    #out = follow_route(@@post_routes, key)
    content_type ||= 'text/html'
    content_type  content_type, :charset => 'utf-8'  
    out
  end

end