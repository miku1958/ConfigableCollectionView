/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Examples of custom configurations that can be used with any cell.
*/

import UIKit

#if OfficialDemo
struct CustomBackgroundConfiguration {
    static func configuration(for state: UICellConfigurationState) -> UIBackgroundConfiguration {
        var background = UIBackgroundConfiguration.clear()
        background.cornerRadius = 10
        if state.isHighlighted || state.isSelected {
            // Set nil to use the inherited tint color of the cell when highlighted or selected
            background.backgroundColor = nil
            
            if state.isHighlighted {
                // Reduce the alpha of the tint color to 30% when highlighted
                background.backgroundColorTransformer = .init { $0.withAlphaComponent(0.3) }
            }
        }
        return background
    }
}

struct CustomContentConfiguration: UIContentConfiguration, Hashable {
    var image: UIImage? = nil
    var tintColor: UIColor? = nil
    
    func makeContentView() -> UIView & UIContentView {
        return CustomContentView(configuration: self)
    }
    
    func updated(for state: UIConfigurationState) -> Self {
        guard let state = state as? UICellConfigurationState else { return self }
        var updatedConfig = self
        if state.isSelected || state.isHighlighted {
            updatedConfig.tintColor = .white
        }
        return updatedConfig
    }
}

class CustomContentView: UIView, UIContentView {
    init(configuration: CustomContentConfiguration) {
        super.init(frame: .zero)
        setupInternalViews()
        apply(configuration: configuration)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var configuration: UIContentConfiguration {
        get { appliedConfiguration }
        set {
            guard let newConfig = newValue as? CustomContentConfiguration else { return }
            apply(configuration: newConfig)
        }
    }
    
    private let imageView = UIImageView()
    
    private func setupInternalViews() {
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])
        imageView.preferredSymbolConfiguration = .init(font: .preferredFont(forTextStyle: .body), scale: .large)
        imageView.isHidden = true
    }
    
    private var appliedConfiguration: CustomContentConfiguration!
    
    private func apply(configuration: CustomContentConfiguration) {
        guard appliedConfiguration != configuration else { return }
        appliedConfiguration = configuration
        
        imageView.isHidden = configuration.image == nil
        imageView.image = configuration.image
        imageView.tintColor = configuration.tintColor
    }
}
#else
struct CustomContentConfiguration: Equatable {
    var image: UIImage? = nil
    var tintColor: UIColor? = nil
    var backgroundColor: UIColor?
    
    mutating func updated(for state: UICellConfigurationState) {
        if state.isSelected || state.isHighlighted {
            self.tintColor = .white
        } else {
            self.tintColor = nil
        }
        backgroundColor = nil
        
        if state.isHighlighted {
            backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
        }
        if state.isSelected {
            backgroundColor = UIColor.systemBlue
        }
    }
}
class CustomContentView: UIView {
    convenience init() {
        self.init(frame: .zero)
        setupInternalViews()
    }
    private let imageView = UIImageView()
    
    private func setupInternalViews() {
        addSubview(imageView)
        layer.cornerRadius = 10
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])
        imageView.preferredSymbolConfiguration = .init(font: .preferredFont(forTextStyle: .body), scale: .large)
        imageView.isHidden = true
    }
    
    var configuration = CustomContentConfiguration() {
        didSet {
            guard configuration != oldValue else { return }
            
            imageView.isHidden = configuration.image == nil
            imageView.image = configuration.image
            imageView.tintColor = configuration.tintColor
            
            backgroundColor = configuration.backgroundColor
        }
    }
}
#endif
