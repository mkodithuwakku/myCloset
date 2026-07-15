import CoreLocation
import Foundation

@MainActor
final class WeatherService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var context: WeatherContext = .seasonalFallback
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published var cityQuery = ""

    private let manager = CLLocationManager()
    private var requestedSource: WeatherContext.Source = .currentLocation

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    }

    func requestCurrentWeather() {
        errorMessage = nil
        requestedSource = .currentLocation
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            isLoading = true
            manager.requestLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            errorMessage = "Location is off. Enter a city or keep using the season."
        @unknown default:
            errorMessage = "Location is unavailable."
        }
    }

    func useCity() {
        let query = cityQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            errorMessage = "Enter a city name first."
            return
        }
        requestedSource = .city
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let placemarks = try await CLGeocoder().geocodeAddressString(query)
                guard let location = placemarks.first?.location else {
                    throw WeatherFailure.locationNotFound
                }
                await fetch(location: location, source: .city, suppliedName: query)
            } catch {
                isLoading = false
                errorMessage = "That city could not be found. Try a more specific name."
            }
        }
    }

    func useSeasonOnly() {
        context = .seasonalFallback
        errorMessage = nil
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
                requestCurrentWeather()
            } else if manager.authorizationStatus == .denied {
                errorMessage = "Location is off. Enter a city or keep using the season."
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            await fetch(location: location, source: requestedSource, suppliedName: nil)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            isLoading = false
            errorMessage = "Current weather is unavailable. Season-based matching is still active."
        }
    }

    private func fetch(location: CLLocation, source: WeatherContext.Source, suppliedName: String?) async {
        do {
            var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
            components.queryItems = [
                .init(name: "latitude", value: String(location.coordinate.latitude)),
                .init(name: "longitude", value: String(location.coordinate.longitude)),
                .init(name: "current", value: "temperature_2m,apparent_temperature,weather_code"),
                .init(name: "temperature_unit", value: "celsius")
            ]
            let (data, response) = try await URLSession.shared.data(from: components.url!)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw WeatherFailure.badResponse }
            let result = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)

            var locationName = suppliedName
            if locationName == nil,
               let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first {
                locationName = placemark.locality ?? placemark.administrativeArea
            }

            context = .init(
                temperatureCelsius: result.current.temperature,
                apparentTemperatureCelsius: result.current.apparentTemperature,
                summary: Self.summary(for: result.current.weatherCode),
                locationName: locationName,
                season: .current(latitude: location.coordinate.latitude),
                source: source
            )
            isLoading = false
            errorMessage = nil
        } catch {
            isLoading = false
            errorMessage = "Weather could not be refreshed. Season-based matching is still active."
        }
    }

    private static func summary(for code: Int) -> String {
        switch code {
        case 0: "Clear"
        case 1...3: "Partly cloudy"
        case 45, 48: "Foggy"
        case 51...67, 80...82: "Rainy"
        case 71...77, 85, 86: "Snowy"
        case 95...99: "Stormy"
        default: "Current conditions"
        }
    }
}

private enum WeatherFailure: Error {
    case locationNotFound
    case badResponse
}

private struct OpenMeteoResponse: Decodable {
    let current: Current

    struct Current: Decodable {
        let temperature: Double
        let apparentTemperature: Double
        let weatherCode: Int

        enum CodingKeys: String, CodingKey {
            case temperature = "temperature_2m"
            case apparentTemperature = "apparent_temperature"
            case weatherCode = "weather_code"
        }
    }
}
