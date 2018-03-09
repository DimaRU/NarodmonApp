    # Uncomment the next line to define a global platform for your project
platform :osx, '10.11'

target 'NarodmonApp' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for MoyaTest
  pod 'Moya', '~> 10.0'
  pod 'PromiseKit'
  pod 'PromiseKit/Alamofire'
  pod 'KeychainAccess'
  pod 'SwiftyUserDefaults'
  pod 'Charts', :git => 'https://github.com/DimaRU/Charts.git'

plugin 'cocoapods-keys', {
    :project => 'NarodmonApp',
    :keys => [
    'ApiKey'
  ]
}

end
