platform :osx, '10.13'

target 'NarodmonApp' do
  use_frameworks! :linkage => :static

  # Pods for MoyaTest
  pod 'Moya'
  pod 'PromiseKit'
  pod 'KeychainAccess'
  pod 'Cache'
  pod 'Charts'
  pod 'ProgressKit', :git => 'https://github.com/DimaRU/ProgressKit.git'

plugin 'cocoapods-keys', {
    :project => 'NarodmonApp',
    :keys => [
    'ApiKey'
  ]
}

end
