import Foundation

extension URLRequest {
    init(
        url: URL,
        method: HTTPMethod,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil
    ) throws {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }

        self.init(url: url)

        httpMethod = method.rawValue

        if let parameters = parameters {
            switch method {
            case .GET:
                encodeParametersInURL(parameters, components: components)
            case .POST:
                try encodeParametersInBody(parameters)
            }
        }

        if let headers = headers {
            for (key, value) in headers {
                setValue(value, forHTTPHeaderField: key)
            }
        }
    }

    private mutating func encodeParametersInURL(
        _ parameters: [String: Any],
        components: URLComponents
    ) {
        var components = components
        components.queryItems = parameters
            .map { ($0, "\($1)") }
            .map { URLQueryItem(name: $0, value: $1) }
        url = components.url
    }

    private mutating func encodeParametersInBody(
        _ parameters: [String: Any]
    ) throws {
        setValue("application/json", forHTTPHeaderField: "Content-Type")
        httpBody = try JSONSerialization.data(
            withJSONObject: parameters,
            options: .prettyPrinted
        )
    }
}
