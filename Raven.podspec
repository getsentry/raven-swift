Pod::Spec.new do |s|
  s.name         = "Raven-swift"
  s.version      = "0.1.0"
  s.summary      = "A client for Sentry (getsentry.com)."
  s.homepage     = "https://getsentry.com/"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "Tommy Mikalsen" => "tommymi@gmail.com" }
  s.source       = { :git => "https://github.com/timorzadir/raven-swift.git", :tag => s.version.to_s }
  s.source_files = ['Raven']
  s.requires_arc = true
end
