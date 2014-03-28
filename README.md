# Introducing the srscript (alpha) gem

    require 'srscript'

    SRScript.run!

This gem is for my own personal use only however it might be of interest to you.  The srscript gem combines Sinatra + Rscript to allow the execution of Ruby Scripting File (RSF) jobs from a web server.

The Sinatra application itself is dumb, other than being able to boot-up an RSF job from a remote web server to get it started.

*installation*
sudo gem1.9.1 install srscript 

*server.xml*
`
    <server>
      <summary>
        <name>lucia</name>
        <registry>http://127.0.0.1:4567/</registry>
        <localhost>http://127.0.0.1:4567/</localhost>
      </summary>
      <records/>
    </server>
`
The server.xml (which is located in the same directory as where the script is executed) provides the application with just enough configuration information as to facilitate the boot-up process.

The boot-up process is launched from Sinatra's config after 8 seconds, then it makes an external web request to itself on route '/bootstrap' to continue loading the web services.

*testing: requesting the time*
http://127.0.0.1:4567/do/utility/time
#=> 
`<result><summary><to_s>2011-02-21 12:49:20 +0000</to_s></summary><records/></result>`

Resources:
 - <a href="https://github.com/jrobertson/srscript">jrobertson/srscript - GitHub</a> [github.com] 

Note: The original Sinatra-Rscript (for Sinatra < 1.0) on Github is no longer maintained.

