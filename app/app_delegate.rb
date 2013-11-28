class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
# motion_require '../ProMotion/lib/ProMotion.rb'

# class AppDelegate < ProMotion::Delegate
#   def on_load(application, launchOptions)
    
    setup_window 
    
    setup_root_vc
    
    # test out a repl.
    # r = repl self
    # puts "repl: #{r}"
    # puts r.evaluateExpression 'self'
    
    true
  end
  
  def setup_window
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    @window.makeKeyAndVisible
  end

  def setup_root_vc
    browser_vc = ConventionalBrowserViewController.alloc.init
    @window.rootViewController = browser_vc
    @window.rootViewController.wantsFullScreenLayout = true
    
    browser_vc.load_file 'testfile.html'
  end
  
  #=
  
  def root_vc
    @window.rootViewController
  end
end
