# application logic for handling text input.
# NOTE filtering input not handled here.
# TODO resolve with repl.rb
class InputHandler < BBLComponent
  include Reactive

  def setup
    # watch for submitted text.
    react_to 'client.input_field_vc.submitted_text' do |val|
      self.process_input val
    end
  end
  
  def process_input( input )
    input = input.dup
    type = input.pe_type
    pe_log "input type for '#{input}': #{type}"
    case type
    when :cmd
      self.process_command input

    when :url
      self.client.load_url input

    when :search
      self.client.load_url input.to_search_url_string, stack_id: input

    else
      self.client.load_url [
        input,
        input.to_search_url_string
      ], stack_id: input
    end
  end


  #= command processing.  REFACTOR move to a plugin.

  attr_accessor :command_output

  def process_command( input )
    command = input.gsub /^>/, ''

    self.command_output = eval command

    pe_log "command result: #{self.command_output}"

    # HACK put output into an html and load.
    output_file = "#{NSApp.app_support_dir}/plugin/output/data/output.json"
    FileUtils.mkdir_p( File.dirname output_file) unless Dir.exist? File.dirname( output_file )
    File.open output_file, 'w' do |f|
      f << %Q(
        {
          "output": "#{self.command_output}"
        }
      )
    end

    # TODO pull out.
    NSApp.delegate.wc.browser_vc.load_module :output
  end
end


class String
  def valid_url?
    # NOTE this is probably incomplete.
    self =~ %r{^(\w+)://}
  end
  
  def pe_type
    if self =~ /^>/
      :cmd
    
    elsif self.valid_url?
      :url

    # catch some obvious hints for an enquiry
    elsif self.include? ' '
      :search

    else
      :other
    end
  end
end

