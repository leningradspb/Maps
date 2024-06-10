// The Swift Programming Language
// https://docs.swift.org/swift-book
//
import YandexMapsMobile
import UIKit
import SnapKit
import CoreLocation


protocol MapObjectTapListenerDelegate: AnyObject {
    func onMapObjectTap(with mapObject: YMKMapObject, point: YMKPoint)
}

final class MapObjectTapListener: NSObject, YMKMapObjectTapListener {
    
    private weak var delegate: MapObjectTapListenerDelegate?

    init(delegate: MapObjectTapListenerDelegate) {
        self.delegate = delegate
    }

    func onMapObjectTap(with mapObject: YMKMapObject, point: YMKPoint) -> Bool {
        delegate?.onMapObjectTap(with: mapObject, point: point)
        return true
    }
}

public class MapViewController: UIViewController {
    private let mapView = YMKMapView(frame: .zero)!
    /// стек в котором можно расположить кнопки + - локация и пауза (для паузы надо добавить пустое вью, чтобы соблюсти отступы)
    private let mapButtonsStack = VerticalStackView(spacing: Constants.Layout.mapButtonsStackSpacing)
    private let mapButtonsData = Constants.MapButtons.allCases
    /// mapView.mapWindow.map
    private lazy var map = mapView.mapWindow.map
    private let mapAnimation = YMKAnimation(type: .smooth, duration: 0.3)
    private var placemark: YMKPlacemarkMapObject!
    private var timer: Timer!
    private var repeats = 1000
    private var fraction = 0.01
    private let placemarkStyle = YMKIconStyle()
    private var userLocationDotPlacemark: YMKPlacemarkMapObject?
    private var userLocationPinPlacemark: YMKPlacemarkMapObject?
        
    private let locationService = LocationService.shared
    /// 59.961075, 30.260612
    let userLocation = CLLocation(latitude: 59.961075, longitude: 30.260612)
    private var currentZoom: Float = Constants.YMakpKit.zoom
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupLocationService()
    }

    private func setupUI() {
        view.backgroundColor = .black
        setupMap()
    }
    
    private func setupLocationService() {
        locationService.locationErrorCompletion = { [weak self] in
            guard let self = self else { return }
            self.updateMap(by: self.locationService.defaultUserLocation)
            self.showUserLocationError()
        }
        
        locationService.locationUpdatedCompletion = { [weak self] location in
            self?.updateMap(by: location)
        }
    }
    
    private func setupMap() {
        view.addSubview(mapView)
        mapView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        mapView.mapWindow.map.addCameraListener(with: self)

        let style = """
        [
            {
                "elements": "geometry.fill.pattern",
                        "stylers": {
                                        "saturation": -0.75
                                    }
            },
            {
                "elements": "geometry.outline",
                        "stylers": {
                                        "saturation": -0.75
                                    }
            },
            {
                "elements": "geometry.fill",
                        "stylers": {
                                        "saturation": -0.95,
                                "lightness": 0.55
                                    }
            },
            {
                "elements": "label.text.fill",
                        "stylers": {
                                        "saturation": -0.75
                                    }
            },
            {
                "elements": "label.icon",
                    "stylers": {
                                    "saturation": -0.75
                                }
        }
        ]
"""
        mapView.mapWindow.map.setMapStyleWithStyle(style)
        setupMapStackView()
    }
    
    private func setupMapStackView() {
        view.addSubview(mapButtonsStack)
        
        for index in 0..<mapButtonsData.count {
            let button = UIButton()
            let mapButtonData = mapButtonsData[index]
            let iconName = mapButtonData.iconName
            let tag = mapButtonData.tag
            button.setImage(UIImage(named: iconName), for: .normal)
            button.tag = tag
            button.snp.makeConstraints {
                $0.width.height.equalTo(Constants.Layout.mapButton)
            }
            button.addTarget(self, action: #selector(mapButtonTapped), for: .touchUpInside)
            mapButtonsStack.addArrangedSubview(button)
        }
        
        mapButtonsStack.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-Constants.Layout.commonHorizontal)
            $0.centerY.equalToSuperview().offset(Constants.Layout.mapButtonsStackCenterYOffset)
        }
    }
    
    private func updateMap(by location: CLLocation) {
        let startLatitude = location.coordinate.latitude
        let startLongitude = location.coordinate.longitude
        
        DispatchQueue.main.async {

            self.addUserLocationOnMap(by: location)
            self.mapView.mapWindow.map.move(
                    with: YMKCameraPosition(
                        target: YMKPoint(latitude: startLatitude, longitude: startLongitude),
                        zoom: Constants.YMakpKit.zoom,
                        azimuth: Constants.YMakpKit.azimuth,
                        tilt: Constants.YMakpKit.tilt
                    ),
                    animation: YMKAnimation(type: YMKAnimationType.smooth, duration: Constants.YMakpKit.duration),
                    cameraCallback: nil)
        }
    }
    
    func move(to geometry: YMKGeometry, zoom: Float? = nil) {
        //        YMKCameraPosition(
        //        mapView.mapWindow.map.position
        var cameraPosition = map.cameraPosition(with: geometry)
        cameraPosition = YMKCameraPosition(
            target: cameraPosition.target,
            zoom: zoom ?? cameraPosition.zoom,
            azimuth: cameraPosition.azimuth,
            tilt: cameraPosition.tilt
        )
        currentZoom = cameraPosition.zoom
        map.move(with: cameraPosition, animation: mapAnimation)
    }
    
    private func addUserLocationOnMap(by startLocation: CLLocation) {
        if let userLocationDotPlacemark = userLocationDotPlacemark {
            mapView.mapWindow.map.mapObjects.remove(with: userLocationDotPlacemark)
        }
        
        let startLatitude = startLocation.coordinate.latitude
        let startLongitude = startLocation.coordinate.longitude
        
        // Задание координат точки
        let startPoint = YMKPoint(latitude: startLatitude, longitude: startLongitude)
        let viewStartPlacemark: YMKPlacemarkMapObject = mapView.mapWindow.map.mapObjects.addPlacemark(with: startPoint)
          
        // Настройка и добавление иконки
        viewStartPlacemark.setIconWith(
            UIImage(named: Constants.Icons.userLocationIcon)!, // Убедитесь, что у вас есть иконка для точки
              style: YMKIconStyle(
                  anchor: CGPoint(x: 0.5, y: 0.5) as NSValue,
                  rotationType: YMKRotationType.rotate.rawValue as NSNumber,
                  zIndex: 0,
                  flat: true,
                  visible: true,
                  scale: 0.1,
                  tappableArea: nil
              )
          )
        userLocationDotPlacemark = viewStartPlacemark
    }
    
    private func movePinOnMap(by point: YMKPoint) {
        if let userLocationPinPlacemark = userLocationPinPlacemark {
            self.userLocationPinPlacemark?.geometry = point
            print(self.userLocationPinPlacemark?.direction)
            return
        }
        
        let viewStartPlacemark: YMKPlacemarkMapObject = mapView.mapWindow.map.mapObjects.addPlacemark(with: point)
        // Настройка и добавление иконки
        viewStartPlacemark.setIconWith(
            UIImage(named: Constants.Icons.locationPinLight)!, // Убедитесь, что у вас есть иконка для точки
              style: YMKIconStyle(
                  anchor: CGPoint(x: 0.5, y: 0.5) as NSValue,
                  rotationType: YMKRotationType.rotate.rawValue as NSNumber,
                  zIndex: 0,
                  flat: true,
                  visible: true,
                  scale: 1,
                  tappableArea: nil
              )
          )
        userLocationPinPlacemark = viewStartPlacemark
    }
    
    private func drivingRouteHandler(drivingRoutes: [YMKDrivingRoute]?, error: Error?) {
        if let error {
            // Handle request routes error
            return
        }

        guard let drivingRoutes else {
            return
        }

        let mapObjects = mapView.mapWindow.map.mapObjects
        for route in drivingRoutes {
            mapObjects.addPolyline(with: route.geometry)
        }
    }
    
    private func showUserLocationError() {
//        NotificationBanner.shared.show(.info(text: "Вы не предоставили доступ к геолокации. Пожалуйста, перейдите в настройки"))
//
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { [weak self] in
            guard let self = self else { return }
            
            self.showAlert(title: Constants.HardcodedTexts.alertLocationErrorTitle, message: Constants.HardcodedTexts.alertLocationErrorMessage)
        })
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alert.addAction(action)
        self.present(alert, animated: true)
    }
    
    private func changeZoom(by amount: Float) {
        map.move(
            with: YMKCameraPosition(
                target: map.cameraPosition.target,
                zoom: map.cameraPosition.zoom + amount,
                azimuth: map.cameraPosition.azimuth,
                tilt: map.cameraPosition.tilt
            ),
            animation: YMKAnimation(type: .smooth, duration: 1.0)
        )
    }
    
    @objc private func mapButtonTapped(sender: UIButton) {
        print(sender.tag)
        switch sender.tag {
        case Constants.MapButtons.MapButtonTag.zoomIn.rawValue:
            print("zoomIn")
            changeZoom(by: 1)
        case Constants.MapButtons.MapButtonTag.zoomOut.rawValue:
            print("zoomOut")
            changeZoom(by: -1)
        case Constants.MapButtons.MapButtonTag.backToCurrentLocation.rawValue:
            print("backToCurrentLocation")
            if let target = userLocationDotPlacemark?.geometry {
                map.move(
                    with: YMKCameraPosition(
                        target: target,
                        zoom: map.cameraPosition.zoom,
                        azimuth: map.cameraPosition.azimuth,
                        tilt: map.cameraPosition.tilt
                    ),
                    animation: YMKAnimation(type: .smooth, duration: 1.0)
                )
            }
        default:
            print("Нет тэга для mapButton")
            break
        }
    }
}

extension MapViewController: YMKMapCameraListener {
    public func onCameraPositionChanged(with map: YMKMap, cameraPosition: YMKCameraPosition, cameraUpdateReason: YMKCameraUpdateReason, finished: Bool) {
        movePinOnMap(by: cameraPosition.target)
    }
}
