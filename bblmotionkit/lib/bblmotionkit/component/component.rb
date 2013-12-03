module ComponentClient

  # should call setup_components for each element in order.
  # should add component's event handlers to the handler chains, initialising if necessary.
  def setup_components( component_defs = self.components )
    component_defs.map do |component_def|
      try do
        component_class = component_def[:module]

        register component_class

        pe_log "assembled component #{component_class} into #{self}"
      end
    end
  end

  def register component_class
    @registered_components ||= []

    # TACTICAL naive implementation keeps instantiating new instances..
    defaults = default "#{self.class.name}.#{component_class.name}"
    instance = component_class.new( self )
    @registered_components << instance

    # set up event method chaining.
    instance.event_methods.map do |event_method|
      self.chain event_method, instance.method(event_method)
    end

    # one-time setup.
    instance.setup
  end

  def component component_class
    o = @registered_components.select { |e| e.is_a? component_class } [0]
    raise "no component #{component_class} found" if nil
    o
  end
  

  def chain method_name, method

    original_method = 
      if self.respond_to? method_name
        self.method method_name
      else
        # define a no-op method?

        pe_log "no method #{method_name} found on client."
        nil
      end
      return if original_method.nil?

    do_chain = proc {
      method.call
      original_method.call
    }

    self.define_singleton_method method_name do
      do_chain.call
    end

    pe_log "chained #{method} to #{method_name}"
  end

end


class BBLComponent
  attr_reader :client

  def initialize(client)
    @client = client
  end

  def setup
    pe_log "setting up #{self}"
    self.on_setup
  end
  
  def event_methods
    self.methods.grep /^on_/
  end

  #= defaults-related

  def defaults
    self.client.default :"#{self.class.name}"
  end

  def default key
    self.client.default full_key(key)
  end
  
  def update_default key, val
    self.client.set_default full_key(key), val

    default_def = self.defaults_spec[key]
    unless default_def.nil?
      postflight = default_def[:postflight]
      postflight.call(val) if postflight

      pe_log "called postflight #{postflight} for default '#{key}'"
    end
  end

  def full_key key
    :"#{self.class.name}.#{key}"
  end
end
