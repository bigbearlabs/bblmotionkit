Display_tags_by_modes = { 
  Display_enquiry: 7001, 
  Display_url: 7002, 
  Display_filter: 7003 
}

class InputFieldComponent < BBLComponent
  include Reactive

  def on_setup

    @input_field_vc.setup

    react_to 'client.browser_vc.url' do |url|
      @input_field_vc.current_url = url
    end

    react_to 'client.stack.name' do |name|
      @input_field_vc.current_enquiry = name
    end

    react_to 'client.input_field_shown' do |shown|
      # view model -> view
      if shown
        if client.default :handle_focus_input_field
          @input_field_vc.show
        end

        # bar must be visible
        client.bar_shown = true
      else
        @input_field_vc.hide
      end
    end

    client.input_field_shown = client.default :handle_focus_input_field

    # client.extend ClientMethods

    watch_notification :Input_field_focused_notification, @input_field_vc
    watch_notification :Input_field_unfocused_notification, @input_field_vc
    watch_notification :Input_field_cancelled_notification, @input_field_vc
  end


  def handle_Input_field_focused_notification( notification )
    # self.show_popover(@nav_buttons_view)
  
    client.bar_shown = true

    # disable the overlay for now.    
=begin
    case @input_field_vc.mode 
    when :Filter
      self.show_filter_overlay
    else
      self.show_navigation_overlay
    end
=end
  end

  def handle_Input_field_unfocused_notification( notification )
    # self.hide_overlay
  end
  
  def handle_Input_field_cancelled_notification( notification )
    # self.handle_transition_to_browser
    # self.hide_overlay
  end

end


class BrowserWindowController < NSWindowController

  # WORKAROUND add traits to client.
  def focus_input_field
    self.handle_focus_input_field self
  end
  
  def handle_hide_input_field(sender)
    self.input_field_shown = false
  end
  
  def handle_focus_input_field(sender)
    send_notification :Input_field_focused_notification

    self.input_field_shown = true

    @input_field_vc.focus_input_field
  end

  
#= 

  def handle_show_location(sender)
    # self.page_details_vc.display_mode = :url
    # self.handle_show_page_detail self

    @input_field_vc.display_mode = :Display_url
    @input_field_vc.focus_input_field
  end

  def handle_show_search(sender)
    # self.page_details_vc.display_mode = :query
    # self.handle_show_page_detail self   

    @input_field_vc.display_mode = :Display_enquiry
    @input_field_vc.focus_input_field
  end

end