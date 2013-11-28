# RENAME bblviewcontroller
class MotionViewController < PlatformViewController
=begin
  def load_view nib_name
      views = NSBundle.mainBundle.loadNibNamed nib_name, owner:self, options:nil
      self.view = views[0]
  end
=end

  def init( nib_name = self.class.name.gsub(/Controller$/,'') )
    obj = self.initWithNibName(nib_name, bundle:nil)
    obj
  end

  extend IB
  outlet :frame_view

  # TODO reconcile later with pemacrubyinfra
  def awakeFromNib
    super

    @frame_view.addSubview self.view
  end
end


