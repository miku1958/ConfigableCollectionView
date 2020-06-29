Pod::Spec.new do |spec|
	spec.name = "ConfigableCollectionView"
	spec.version = "1.0.0"
	spec.summary = "Create CollectionView in a similar way to iOS 14"
	spec.homepage = "http://apple.com"
	spec.license = { :"type" => "Copyright", :"text" => " Copyright 2020 mikun \n"} 
	spec.author = { "mikun" => "v.v1958@qq.com" }
	spec.source = { :git => './', :tag => "1.0.0" }

	spec.swift_version = '5.0'

	spec.ios.deployment_target = "10.0"
	spec.source_files = "**/*.*"
end
