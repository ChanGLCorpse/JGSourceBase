source 'https://mirrors.tuna.tsinghua.edu.cn/git/CocoaPods/Specs.git'
# source 'https://github.com/cocoapods/specs.git'
# source 'https://cdn.cocoapods.org/'

# 私有库B依赖了模块A，同时在主工程里 添加A到 development pod，cocoapods 重复生成相同库的uuid
# pod install 警告信息 [!] [Xcodeproj] Generated duplicate UUIDs
install! 'cocoapods', :deterministic_uuids => false

# 源码测试请屏蔽此选项，否则源码库内部调用出现的警告将不会提示
# inhibit_all_warnings!

# use_frameworks! 要求生成的是 .framework 而不是静态库 .a
# :linkage 指定使用动态(dynamic)/静态链接(static)，始终以podspec中设置的static_framework优先
# podspec中未设置static_framework，且不指定linkage，默认动态链接

# 调试 JGSourceFrameworkDemo: 
# Multiple targets match implicit dependency for product reference 'JGSourceBase.framework'. Consider adding an explicit dependency on the intended target to resolve this ambiguity. (in target 'JGSourceFrameworkDemo' from project 'JGSourceBaseDemo')

# 调试 JGSourceBaseDemo: 
# Multiple targets match implicit dependency for linker flags '-framework JGSourceBase'. Consider adding an explicit dependency on the intended target to resolve this ambiguity. (in target 'JGSourceBaseDemo' from project 'JGSourceBaseDemo')

# use_frameworks! # 使用默认，动态链接
# use_frameworks! :linkage => :dynamic # 使用动态链接
# 为便于查看header头文件，使用use_frameworks!且指定使用静态链接，以上调试警告可忽略
use_frameworks! :linkage => :static # 使用静态链接

# workspace
workspace "JGSourceBase"

# platform
platform :ios, 11.0

abstract_target "JGSBase" do
  
  # JGSHUD
  pod 'MBProgressHUD'
  
  # JGSourceBase
  target "JGSourceBase" do
    
    # project
    project "JGSourceBase.xcodeproj"
  end
  
  # JGSourceBaseDemo 测试 Pod 引用 JGSourceBase
  target "JGSourceBaseDemo" do
    
    pod 'IQKeyboardManager', '~> 6.5.9' #  https://github.com/hackiftekhar/IQKeyboardManager.git
    # pod 'SAMKeychain' # KeyChain 测试
    # pod 'FLAnimatedImage'
    
    #pod 'Masonry', '~> 1.1.0' # 该发布版本 mas_safeAreaLayoutGuide 有bug导致多条约束崩溃
    pod 'Masonry', :git => 'https://github.com/SnapKit/Masonry.git', :commit => '8bd77ea92bbe995e14c454f821200b222e5a8804' # https://github.com/cloudkite/Masonry.git
    
    JGSPodsScriptAfterCompile = <<-CMD

    echo "****** 编译结束后，执行Podfile自定义脚本 ******"
    
    echo "执行应用完整性校验资源文件Hash记录脚本"
    chmod +x ${PROJECT_DIR}/JGSScripts/JGSDemoIntegrityCheckAfterCompile.sh # sh执行权限
    ${PROJECT_DIR}/JGSScripts/JGSDemoIntegrityCheckAfterCompile.sh # 执行sh
    
    echo "****** 编译后Podfile自定义脚本执行完成 ******"
    
    CMD

    script_phase :name => "JGSPodsScriptAfterCompile", :script => JGSPodsScriptAfterCompile, :execution_position => :after_compile
    
    # project
    project "JGSourceBase.xcodeproj"
  end

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
      if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < 11.0
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = 11.0
      end
      # 编译架构
      config.build_settings['ARCHS'] = "$(ARCHS_STANDARD)"
      # 解决最新Mac系统编模拟器译报错：
      # building for iOS Simulator-x86_64 but attempting to link with file built for iOS Simulator-arm64
      config.build_settings['ONLY_ACTIVE_ARCH'] = false
      # Xcode 14适配
      config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ""
      config.build_settings['CODE_SIGNING_REQUIRED'] = "NO"
      config.build_settings['CODE_SIGNING_ALLOWED'] = "NO"
    end
  end
  
  puts "##### post_install end #####"
  puts ""
end
