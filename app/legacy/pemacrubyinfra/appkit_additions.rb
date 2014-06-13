# require 'CocoaHelper'
# require 'NSViewController_additions'
# require 'NSWindow_additions'

# macruby_framework 'AppKit'
# macruby_framework 'ExceptionHandling'

#=


def new_rect( x, y, w, h )
	NSMakeRect(x, y, w, h)
end

def new_view( rect_or_x = NSZeroRect, y = 0, w = 0, h = 0 )
	if rect_or_x.is_a? NSRect
		rect = rect_or_x
	else
		rect = new_rect rect_or_x, y, w, h
	end

	NSView.alloc.initWithFrame( rect )
end

def new_button( rect_or_x = 0, y = 0, w = 60, h = 20 )
  if rect_or_x.is_a? NSRect
  	rect = rect_or_x
  else
  	rect = new_rect rect_or_x, y, w, h
  end

  NSButton.new.tap do |b|
  	b.frame = rect
  end
end



#= dealing with the responder chain
class NSResponder

	# hacky.
	def first_responder?
		self.window.firstResponder == self
	end

	def responder_chain
		next_responder = case self
			when NSWindow
				self.firstResponder
			when NSApp
				self.keyWindow
			else
				self
			end

		responders = []
		while next_responder
			raise "responder chain loops" if responders.include? next_responder

			responders << next_responder

			next_responder = next_responder.nextResponder
		end
		responders
	end
	

	# insert responder between receiver and its current nextResponder.
	def insert_responder( responder )
		next_responder = self.nextResponder
		
		if responder == next_responder
			pe_warn "#{self} next responder already #{responder} - doing nothing."
			return
		end
		
		responder.setNextResponder(next_responder)
		self.setNextResponder(responder)
	end
	
	def make_first_responder
		case self
		when NSWindow
			raise "can't make the window the first responder."
		when NSViewController
			the_window = self.view.window
		when NSView, NSWindowController
			the_window = self.window
		else
			raise "unknown NSResponder type #{self.class}"
		end
		
		if the_window
			the_window.makeFirstResponder(self)
		else
			pe_log "window not set, ignoring request to make first responder."
		end
	end

	def send_to_responder( selector, sender )
		if self.is_a? NSApplication
			target = nil  # will search through responder chain
		else
			target = self
		end

		result = NSApp.sendAction(selector, to:target, from:sender)
		
		unless result
			responder_chain = target ? target.responder_chain : self.responder_chain
			pe_warn "no target found for #{selector}. target:#{target} responder_chain:#{responder_chain}"
		end
	end

end


#= animation

class NSResponder
		# TODO method signature sucks. 
		# consider animate( subject = self, animation_params = {}) with @param :completion_block (optional)
	def do_animate( animation_proc, completion_proc = nil )
		on_main {
			NSAnimationContext.beginGrouping

			NSAnimationContext.currentContext.setCompletionHandler( completion_proc ) if completion_proc
			
			animation_proc.call self.animator

			NSAnimationContext.endGrouping
		}
	end

	def animate_layer( layer_to_animate, duration, animation_block, completion_block = nil )
		self.layer.addSublayer(layer_to_animate)

		# CATransaction.commit
		
		CATransaction.begin
		CATransaction.setAnimationDuration(duration)
		
		CATransaction.setCompletionBlock( -> {
				begin
					completion_block.call(layer_to_animate) if completion_block
				rescue Exception => e
					pe_report e		
				end		
			})
		
		begin
			animation_block.call(layer_to_animate)
		rescue Exception => e
			pe_report e					
		end		

		CATransaction.commit
	end
end

def ca_immediately( &block )
	CATransaction.begin
	CATransaction.disableActions = true
	CATransaction.animationDuration = 0
	
	begin
		block.call
	rescue Exception => e
		pe_report e
	end
		
	CATransaction.commit
end


class NSImage
	def self.stub_image
		self.imageNamed NSImageNameMobileMe
	end

	def self.from_data_url(url)
		data = NSData.dataWithContentsOfURL(url)
		self.alloc.initWithData(data)
	end

	# resized image which is potentially cropped to fill width of new size.
	def resized_cropped_image(new_size)
		aspect_ratio = new_size.width / new_size.height

		new_height = self.size.width / aspect_ratio
		#crop if needed
		new_height = (new_height < self.size.height) ? new_height : self.size.height
		aspect_compliant_size = NSMakeSize(self.size.width, new_height)

		# make an image that has the right aspect ratio
		new_image = NSImage.alloc.initWithSize(aspect_compliant_size)
		new_image.lockFocus
		target_rect = NSMakeRect(0,0, aspect_compliant_size.width, aspect_compliant_size.height)
		source_rect = NSMakeRect(0, self.size.height - aspect_compliant_size.height, aspect_compliant_size.width, aspect_compliant_size.height)
		op = NSCompositeSourceOver
		self.drawInRect(target_rect, fromRect:source_rect, operation:op, fraction:1)
		new_image.unlockFocus

		# resize image
		new_image.size = new_size
		
		new_image
	end
end


class NSPoint
	def in_rect( rect )
		NSPointInRect( self, rect )
	end
end

class NSSize
	def pretty_description
		"#{self.width.to_i}x#{self.height.to_i}"
	end
	
	def self.from_pretty_description( desc )
		x, y = desc.split('x')
		NSSize.new(x, y)
	end
end

class NSRect
	def self.rect_with_center(center, width, height)
		# center.x = origin.x + mid(width), center.y = origin.y + mid(height)
		x = center.x - (width / 2)
		y = center.y - (height / 2)
		
		NSMakeRect(x, y, width, height)
	end
	
	def center
		NSMakePoint( NSMidX(self), NSMidY(self) )
	end
	
	def top_and_middle
		NSMakePoint( NSMidX(self), NSMaxY(self) )
	end
	
	def x
		self.origin.x
	end

	def y
		self.origin.y
	end

	def width
		self.size.width
	end
	
	def height
		self.size.height
	end

	def right_x
		self.x + self.height
	end

	def top_y
		self.y + self.height
	end

#= resizing

	# e.g. modified_frame(current_length - 10, :Top) will shorten the rect by 10 from the bottom.
	# TODO implement the horizontal cases - consult #modified_frame_horizontal
	def modified_frame(target_length, anchored_edge)
		# vertical cases
		case anchored_edge
		when :Top
			x = self.origin.x
			y = self.origin.y + (self.size.height - target_length)
			width = self.size.width
			height = target_length

		when :Bottom
			x = self.origin.x
			y = self.origin.y
			width = self.size.width
			height = target_length
		end

		pe_warn "ASSERT FAIL: #{x}, #{y}, #{width}, #{height} not nil" if ( x && y && width && height ) == nil

		NSMakeRect(x, y, width, height)
	end

	def modified_frame_horizontal( new_width )
		width_diff = self.size.width - new_width  # >0 if new width smaller
		new_x = self.origin.x + (width_diff / 2)
		NSMakeRect( new_x, self.origin.y, new_width, self.size.height )
	end
	
#= serialisation to/from arrays

	def to_array
		self.to_a.collect { |e| e.to_a }
	end
	
	def self.from_array( data_array )
		self.new(data_array[0], data_array[1])
	end
	
end


class NSCollectionView
	def selected_items
		items = []
		self.selectionIndexes.enumerateIndexesUsingBlock( -> index, stop_pointer {
			item = self.itemAtIndex(index)
			items << item
		})
		
		items
	end

	def items
		items = []
		self.subviews.size.times do |i|
			items << self.itemAtIndex(i)
		end
		items
	end
end
	
																										 
class NSCollectionViewItem
	def item_index
		self.collectionView.content.index self.representedObject
	end
	
	def item_frame
		self.collectionView.frameForItemAtIndex item_index
	end
end


class NSArrayController
	def empty!
	 range = NSMakeRange(0, self.arrangedObjects.count)
	 self.removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange(range))
	end
end


# this was written when codebase had wrong call to make input field first responder - check if complicated logic is still necessary.
module NSTextFieldResponderHandling
	attr_accessor :on_responder_handler
	attr_accessor :resign_responder_handler
	
	def becomeFirstResponder
		result = super 
		
		on_main {
			pe_debug "#{self} becomeFirstResponder"
			
			# select all text
			delayed 0, -> {
				@on_responder_handler.call if @on_responder_handler
			}
		}
		
		# add handling to field editor.
		if self.class.method_defined?(:currentEditor) && self.currentEditor

			text_field = self
			text_view = self.currentEditor
			text_view.def_method_once :resignFirstResponder do
				resign_result = super
				
				on_main { 
					if text_field.window
						pe_debug "#{self} resignFirstResponder to #{text_field.window.firstResponder}"
					
						if text_field.window.firstResponder != self && text_field.window.firstResponder != text_field
							pe_debug "#{self} really resigned"
							
							text_field.resign_responder_handler.call if text_field.resign_responder_handler
						end
					else
						pe_warn "#{self} resignedFirstResponder without window."
					end
				}
				
				resign_result
			end
			
		end
		
		result
	end
	
end



#=

class NSSplitView
	def collapse_view_at( view_index )
		subview = self.subviews[view_index]
		subview.visible = false
		self.adjustSubviews
	end

	def uncollapse_view_at( view_index )
		subview = self.subviews[view_index]
		subview.visible = true
		self.adjustSubviews
	end
end


class NSEvent
	
	# true for both the mod down and mod up events.
	def modifier_down?(modifier_symbol)
		case modifier_symbol.intern
		when :cmd
			key_mask = NSCommandKeyMask
		when :alt
			key_mask = NSAlternateKeyMask
		else
			# TODO finish implementing.

			return false
		end

		# test for strict matching (cf. masking.)
		return (self.modifierFlags & NSDeviceIndependentModifierFlagsMask) == key_mask
	end

	def match_mask?(mask)
		(NSEventMaskFromType(self.type) & mask ) != 0
	end


	def self.modifiers_down?( flags )		
		self.modifiers & flags != 0
	end
	
	def self.modifiers
		self.modifierFlags
	end

end



# special case for making an NSTextField the first responder.
class NSTextField
  def field_editor
    currentEditor
  end
  
  def make_first_responder
    if (field_editor = self.field_editor)
      self.window.makeFirstResponder(field_editor)
    else
      super
    end
  end
end
