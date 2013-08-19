module NibLoading
  def load_from_nib( nib_name )
    top_level_objs = NSBundle.mainBundle.loadNibNamed(nib_name, owner:nil, options:nil)
    top_level_objs.first
  end
end


class UIView
  def width
    self.frame.size.width
  end
  
  def height
    self.frame.size.height
  end

  def hidden
    self.isHidden
  end

#= radian

  def radian_for_point( p, q = self.center )
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
end


class CALayer
  # not working?
  def rotate( angles_rad )
    # self.transform = CATransform3DMakeRotation(angles_rad, 0, 0, 1)
    self.transform = CATransform3DRotate(self.transform, angles_rad, 0.0,0.0,0.0)
    self.setNeedsDisplay
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