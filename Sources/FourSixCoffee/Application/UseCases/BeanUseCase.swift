import Foundation

enum BeanUseCaseError: LocalizedError {
    case invalidReferenceURL

    var errorDescription: String? {
        switch self {
        case .invalidReferenceURL:
            "URL形式が正しくありません"
        }
    }
}

@MainActor
struct BeanUseCase {
    private let repository: any BeanRepository

    init(repository: any BeanRepository) {
        self.repository = repository
    }

    func fetchBeans() throws -> [Bean] {
        try repository.fetchBeans()
    }

    func createBean(
        name: String,
        shopName: String,
        purchasedAt: Date,
        origin: String = "",
        process: String = "",
        roastLevel: RoastLevel,
        notes: String = "",
        roastDate: Date? = nil,
        referenceURL: String = ""
    ) throws -> Bean {
        let normalizedReferenceURL = try normalize(referenceURL: referenceURL)

        let bean = Bean(
            name: name,
            shopName: shopName,
            purchasedAt: purchasedAt,
            origin: origin,
            process: process,
            roastLevel: roastLevel,
            notes: notes,
            roastDate: roastDate,
            referenceURL: normalizedReferenceURL
        )
        try repository.save(bean: bean)
        return bean
    }

    func save(bean: Bean) throws {
        var validatedBean = bean
        validatedBean.referenceURL = try normalize(referenceURL: bean.referenceURL)
        try repository.save(bean: validatedBean)
    }

    func deleteBeans(ids: [UUID]) throws {
        for id in ids {
            try repository.delete(beanID: id)
        }
    }

    private func normalize(referenceURL: String) throws -> String {
        let trimmedURL = referenceURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURL.isEmpty else { return "" }
        guard let components = URLComponents(string: trimmedURL),
              let scheme = components.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              let host = components.host,
              !host.isEmpty
        else {
            throw BeanUseCaseError.invalidReferenceURL
        }
        return trimmedURL
    }
}
