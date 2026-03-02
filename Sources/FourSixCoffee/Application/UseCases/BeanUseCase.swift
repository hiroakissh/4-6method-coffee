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
        try validate(referenceURL: referenceURL)

        let bean = Bean(
            name: name,
            shopName: shopName,
            purchasedAt: purchasedAt,
            origin: origin,
            process: process,
            roastLevel: roastLevel,
            notes: notes,
            roastDate: roastDate,
            referenceURL: referenceURL
        )
        try repository.save(bean: bean)
        return bean
    }

    func save(bean: Bean) throws {
        try validate(referenceURL: bean.referenceURL)
        try repository.save(bean: bean)
    }

    func deleteBeans(ids: [UUID]) throws {
        for id in ids {
            try repository.delete(beanID: id)
        }
    }

    private func validate(referenceURL: String) throws {
        guard !referenceURL.isEmpty else { return }
        guard URL(string: referenceURL) != nil else {
            throw BeanUseCaseError.invalidReferenceURL
        }
    }
}
