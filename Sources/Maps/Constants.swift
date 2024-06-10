//
//  Constants.swift
//  YMapTest
//
//  Created by Eduard Kanevskii on 23.05.2024.
//

import Foundation

struct Constants {
    
    struct Layout {
        static let commonHorizontal: CGFloat = 24
        static let commonVertical: CGFloat = 16
        static let mapButton: CGFloat = 50
        static let mapButtonsStackCenterYOffset: CGFloat = -30
        static let mapButtonsStackSpacing: CGFloat = 12
    }
    
    struct YMakpKit {
        static let zoom: Float = 18
        static let azimuth: Float = 0
        static let tilt: Float = 0
        static let duration: Float = 1
    }
    
    struct HardcodedTexts {
        static let alertLocationErrorTitle = "Вы не предоставили доступ к вашей геолокации"
        static let alertLocationErrorMessage = "Поэтому вызовем вам такси от Екатеринбург Арены"
    }
    
    struct Icons {
        static let backToLocationLight = "back_to_current_location_light"
        static let zoomInLight = "zoom_in_light"
        static let zoomOutLight = "zoom_out_light"
        static let userLocationIcon = "user_location_icon"
        static let locationPinLight = "location_pin_light"
    }
    
    enum MapButtons: CaseIterable {
        case zoomIn, zoomOut, backToCurrentLocation
       
        var iconName: String {
            switch self {
            case .zoomIn:
                return Constants.Icons.zoomInLight
            case .zoomOut:
                return Constants.Icons.zoomOutLight
            case .backToCurrentLocation:
                return Constants.Icons.backToLocationLight
            }
        }
        
        var tag: Int {
            switch self {
            case .zoomIn:
                return MapButtonTag.zoomIn.rawValue
            case .zoomOut:
                return MapButtonTag.zoomOut.rawValue
            case .backToCurrentLocation:
                return MapButtonTag.backToCurrentLocation.rawValue
            }
        }
        
        enum MapButtonTag: Int {
            case zoomIn, zoomOut, backToCurrentLocation
        }
    }
}
