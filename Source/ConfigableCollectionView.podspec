Pod::Spec.new do |spec|
	spec.name = "ConfigableCollectionView"
	spec.version = "1.0.0"
	spec.summary = "Create CollectionView in a similar way to iOS 13"
	spec.homepage = "https://github.com/miku1958/ConfigableCollectionView"
	spec.license = "Mozilla"
	spec.author = { "mikun" => "v.v1958@qq.com" }
	spec.source = { :git => "https://github.com/miku1958/ConfigableCollectionView.git", :tag => spec.version }

	spec.swift_version = '5.0'

	spec.ios.deployment_target = "9.0"
	spec.source_files = "Source/**/*.*"
end
