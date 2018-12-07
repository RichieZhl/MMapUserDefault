#
# Be sure to run `pod lib lint MMapUserDefault.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MMapUserDefault'
  s.version          = '0.1.0'
  s.summary          = 'A short description of MMapUserDefault.'

  s.description      = <<-DESC
MMapUserDefault用来取代NSUserDefaults
                       DESC

  s.homepage         = 'https://github.com/RichieZhl/MMapUserDefault'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'RichieZhl' => 'lylaut@163.com' }
  s.source           = { :git => 'https://github.com/RichieZhl/MMapUserDefault.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'MMapUserDefault/Classes/**/*'
  s.public_header_files = 'MMapUserDefault/Classes/MMapUserDefault.h'

end
