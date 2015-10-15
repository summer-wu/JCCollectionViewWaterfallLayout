#
# Be sure to run `pod lib lint JCCollectionViewWaterfallLayout.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "JCCollectionViewWaterfallLayout"
  s.version          = "0.0.2"
  s.summary          = "Support multiple section, and can add headerView and footerView."
  s.homepage         = "http://lijingcheng.github.io/"
  s.license          = 'MIT'
  s.author           = { "lijingcheng" => "bj_lijingcheng@163.com" }
  s.source           = { :git => "https://github.com/lijingcheng/JCCollectionViewWaterfallLayout.git", :tag => s.version.to_s }
  s.social_media_url = 'http://weibo.com/lijingcheng1984'
  s.platform     = :ios, '7.0'
  s.requires_arc = true
  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'JCCollectionViewWaterfallLayout' => ['Pod/Assets/*.png']
  }
  s.dependency 'AFNetworking', '~> 2.6.0'
end
