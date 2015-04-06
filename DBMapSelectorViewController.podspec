Pod::Spec.new do |s|
  s.name         = 'DBMapSelectorViewController'
  s.version      = '1.1.0'
  s.authors = { 'Denis Bogatyrev' => 'denis.bogatyrev@gmail.com' }
  s.summary      = 'This component allows you to select circular map region from the MKMapView'
  s.homepage     = 'https://github.com/d0ping/DBMapSelectorViewController'
  s.license      = { :type => 'MIT' }
  s.requires_arc = true
  s.platform     = :ios, '6.0'
  s.source       = { :git => 'https://github.com/d0ping/DBMapSelectorViewController.git', :tag => "#{s.version}" }
  s.source_files = 'Source/**/*.{h,m}'
  s.public_header_files = 'Source/**/*.h'
end
