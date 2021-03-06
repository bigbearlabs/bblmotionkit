def app
  UIApplication.sharedApplication
end


class UIApplication

  def window
    self.windows[0]
  end

  def controller
    self.window.rootViewController
  end

  #= fairly static properties

  def app_support_path
    NSFileManager.defaultManager.privateDataPath
  end

  def resource_url
    NSBundle.mainBundle.resourceURL
  end

  def app_group_url
    group_id = self.delegate.group_id
    url = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier(group_id)
    raise "container URL for '#{group_id}' is nil." if url.nil?
    url
  end
  

  def stage_resource( filename, 
    destination:dest 
  )
    # copy to the app's writable area.

    # this is highly implementation-specific. we default to the app group dir.
    dest ||= app.app_group_url.URLByAppendingPathComponent(filename)
    
    src = app.resource_url.URLByAppendingPathComponent(filename)
    copy_url src, dest

    pe_log "staged #{src} to #{dest}"
  end

  def copy_url src, dest
    dest_path = dest.is_a?(NSURL) ? dest.path : dest
    Motion::FileUtils.cp src.path, dest_path  # assuming local paths.
  end

end


class UIView

#= radian

  def radian_for_point( p, q = self.bounds.center )
    deltaVector = CGPointMake(p.x - q.x, p.y - q.y)
    angle = Math.atan(deltaVector.y / deltaVector.x) + (deltaVector.x < 0 ? Math::PI : 0)
  end
  
#= convenience

  def fit_superview
    if self.superview
      self.frame = self.superview.bounds
    end
  end
  
  def rotate( angle_rad)
    transform = CGAffineTransformMakeRotation(angle_rad)
    self.transform = transform
  end

  # geometry changes - until we figure out the deal with flippedness, leave this here.

  def set_height height, anchor = :bottom
    case anchor
    when :bottom
      diff = self.height - height  # -ve if growing.
      new_y = self.y + diff 
      self.frame = CGRectMake( x, new_y, self.width, height )
    else
      raise "unknown anchor #{anchor}"
    end
  end

#= animations

  # FIXME when called even number of tiems (e.g. 2), pulse_off doesn't work.
  def pulse
    # @full_circle_view.hidden = false
    
    # if self.alpha == 0.0
    #   target_alpha = 1.0
    # else
    #   target_alpha = 0.0
    # end
    
    # duration = 1
    # delay = 0
    # options = UIViewAnimationOptionRepeat|UIViewAnimationOptionAutoreverse
    # animations = -> {
    #     self.alpha = target_alpha
    #     nil
    #   }
    # completion = nil
    # UIView.animateWithDuration(duration, delay:delay, options:options, animations:animations, completion:completion)

    @pulsing = true

    do_animate = -> {    
      UIView.animateWithDuration(1, 
        delay:0, 
        options:0, 
        animations: -> {
          # change alpha.
          self.alpha = (self.alpha == 0.0) ? 1.0 : 0.0
        },
        completion: -> finished {
          if finished
            if @pulsing
              do_animate.call
            end
          end
          nil
        }
      )
    }

    do_animate.call
  end

  def pulse_off( end_alpha = 0.0)
    duration = 1
    delay = 0
    options = UIViewAnimationOptionBeginFromCurrentState
    animations = -> {
        self.alpha = end_alpha
        nil
      }
    completion = nil
    UIView.animateWithDuration(duration, delay:delay, options:options, animations:animations, completion:completion)

    @pulsing = false
  end



end


class CALayer

  def self.new_layer( frame )
    CALayer.layer.tap do |obj|
      obj.frame = frame
      # obj.position = frame.center
    end
  end
  

  def new_sublayer( frame = self.bounds )
    layer = CALayer.new_layer frame
    self.add_layer layer
    layer
  end
  
  def add_layer layer
    if layer.bounds == CGRectZero
      layer.bounds = self.bounds
    end

    self.addSublayer layer
    layer.position = self.bounds.center
    layer
  end


  # not working?
  def rotate( angles_rad )
    # self.transform = CATransform3DMakeRotation(angles_rad, 0, 0, 1)
    self.transform = CATransform3DRotate(self.transform, angles_rad, 0.0,0.0,0.0)
    self.setNeedsDisplay
  end


  def add_circle( radius, args = nil )
    args[:width] ||= 1
    args[:stroke] ||= :red
    args[:fill] ||= :clear

    CAShapeLayer.layer.tap do |layer|
      path = UIBezierPath.bezierPathWithArcCenter(self.center, radius:radius, startAngle:0, endAngle:2*Math::PI, clockwise:true)

      layer.path = path.CGPath

      layer.lineWidth = args[:width]
      layer.strokeColor = args[:stroke].to_s.dup.to_color.CGColor
      layer.fillColor = args[:fill].to_s.dup.to_color.CGColor
  
      self.add_layer layer
    end
  end
  
  def colour( colour = :yellow )
    the_colour = 
      case colour
      when :yellow
        UIColor.yellowColor
      when :red
        UIColor.redColor
      when :blue
        UIColor.blueColor
      when :purple
        UIColor.purpleColor
      else
        raise "unknown colour #{colour}"
      end

    self.backgroundColor = the_colour.CGColor
  end
  
  def center
    self.bounds.center
  end
end


class CIImage
  def blurred_image( filter_options = {} )
    blur_filter = CIFilter.filterWithName('CIGaussianBlur')
    raise Exception.new("Filter not found: #{filter_name}") unless blur_filter

    blur_filter.setDefaults
    blur_filter.setValue(self, forKey:'inputImage')
    filter_options.each_pair do |key, value|
      blur_filter.setValue(value, forKey:key)
    end
    output = blur_filter.valueForKey('outputImage')

    context = CIContext.contextWithOptions(nil)
    cg_output_image = context.createCGImage(output, fromRect:output.extent)
    output_image = CIImage.imageWithCGImage(cg_output_image)
  end
end


def new_blur_filter
  blur_filter = CIFilter.filterWithName('CIGaussianBlur')
  raise Exception.new("Filter not found: #{filter_name}") unless blur_filter

  blur_filter.setDefaults

  blur_filter
end


class UIImageView

  attr_accessor :image_name

  def setImage_name(image_name)
    @image_name = image_name
    self.image = UIImage.imageNamed(@image_name)
  end

end
