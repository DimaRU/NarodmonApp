# Uncomment the next line to define a global platform for your project
platform :osx, '10.11'

target 'NarodmonApp' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for MoyaTest
  pod 'Moya', '10.0.2'
  pod 'PromiseKit', '6.3.4'
  pod 'PromiseKit/Alamofire', '6.3.4'
  pod 'KeychainAccess', '3.1.1'
  pod 'SwiftyUserDefaults', '3.0.1'
  pod 'Cache', '4.1.2'
  pod 'Charts', :git => 'https://github.com/DimaRU/Charts.git'

plugin 'cocoapods-keys', {
    :project => 'NarodmonApp',
    :keys => [
    'ApiKey'
  ]
}

end
