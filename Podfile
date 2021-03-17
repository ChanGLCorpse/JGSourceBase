#source 'https://github.com/cocoaPods/specs.git'
source 'https://mirrors.tuna.tsinghua.edu.cn/git/CocoaPods/Specs.git'

# 私有库B依赖了模块A，同时在主工程里 添加A到 development pod，cocoapods 重复生成相同库的uuid
# pod install 警告信息 [!] [Xcodeproj] Generated duplicate UUIDs
install!'cocoapods', :deterministic_uuids => false

# 源码测试请屏蔽此选项，否则源码库内部调用出现的警告将不会提示
#inhibit_all_warnings!
#use_frameworks!

# workspace
workspace "JGSourceBase"

# platform
platform :ios, 10.0

# JGSourceBaseDemo
target "JGSourceBaseDemo" do
  
  pod 'IQKeyboardManager', '~> 6.5.6' #  https://github.com/hackiftekhar/IQKeyboardManager.git
  
  # Local
  pod 'JGSourceBase', :path => "."
  
  #pod 'Masonry', '~> 1.1.0' # 该发布版本 mas_safeAreaLayoutGuide 有bug导致多条约束崩溃
  pod 'Masonry', :git => 'https://github.com/SnapKit/Masonry.git', :commit => '8bd77ea92bbe995e14c454f821200b222e5a8804' # https://github.com/cloudkite/Masonry.git
  
  # project
  project "JGSourceBaseDemo/JGSourceBaseDemo.xcodeproj"
end

# Hooks: pre_install 在Pods被下载后但是还未安装前对Pods做一些改变
pre_install do |installer|
  puts ""
  puts "##### pre_install start #####"
  
  # target has transitive dependencies that include statically linked  解决pod install失败
  # workaround for https://github.com/CocoaPods/CocoaPods/issues/3289
  # Pod::Installer::Xcode::TargetValidator.send(:define_method, :verify_no_static_framework_transitive_dependencies) {}
  
  puts "##### pre_install end #####"
  puts ""
end

# Hooks: post_install 在生成的Xcode project写入硬盘前做最后的改动
post_install do |installer|
  puts ""
  puts "##### post_install start #####"
  
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # 设置Pods最低版本
      if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < 10.0
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = 10.0
      end
    end
  end
  
  puts "##### post_install end #####"
  puts ""
end
