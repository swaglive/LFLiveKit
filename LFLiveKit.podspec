
Pod::Spec.new do |s|

  s.name         = "LFLiveKit"
  s.version      = "2.8.29"
  s.summary      = "LaiFeng ios Live. LFLiveKit."
  s.homepage     = "https://github.com/chenliming777"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "chenliming" => "chenliming777@qq.com" }
  s.platform     = :ios, "13.0"
  s.ios.deployment_target = "13.0"
  s.source       = { :git => "https://github.com/LaiFengiOS/LFLiveKit.git", :tag => "#{s.version}" }
  s.source_files  = "LFLiveKit/**/*.{h,m,mm,cpp,c,swift,metal}"
  s.public_header_files = ['LFLiveKit/*.h', 'LFLiveKit/objects/*.h', 'LFLiveKit/configuration/*.h']

  s.frameworks = "VideoToolbox", "AudioToolbox","AVFoundation","Foundation","UIKit"
  s.libraries = "c++", "z"

  s.requires_arc = true
end
