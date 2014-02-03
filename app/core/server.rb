# deps: 
# pod RoutingHTTPServer

module DynamicServer
  def start( port = 59123 )
    @server = RoutingHTTPServer.alloc.init
    @server.interface = 'loopback'
    @server.port = port


    err = Pointer.new '@'
    @server.start err
    if err[0]
      raise err[0]
    else
      pe_log "#{@server} started serving."
    end
  end

  def on_request( request, response )
    # for view to fetch data. TEMP
    response.setHeader 'Access-Control-Allow-Origin', value:'*'

    pe_log "http request received: #{request.method} #{request.url.inspect}"
  end

  # TODO redundant given routinghttpserver. register directly
  def add_handler( path, method, &handler)
    case method
    when :GET
      @server.get path, withBlock: proc {|request, response|
        self.on_request request, response
        handler.call request, response
      }
    when :PUT
      @server.put path, withBlock: proc {|request, response|
        self.on_request request, response
        handler.call request, response
      }
    end      
  end
  
end


class ServerComponent < BBLComponent
  include DynamicServer

  def on_setup
    self.start 59123
  end

end