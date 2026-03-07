import XCTest
@testable import FourSixCoffee

final class TasteRatingsTests: XCTestCase {
    func testQuickFeedbackMappingKeepsExpectedSummary() {
        let ratings = TasteRatings(
            tasteFeedback: .sweet,
            strengthFeedback: .rich,
            overallFeedback: .excellent
        )

        XCTAssertEqual(ratings.tasteFeedbackSummary, .sweet)
        XCTAssertEqual(ratings.strengthFeedbackSummary, .rich)
        XCTAssertEqual(ratings.overallFeedbackSummary, .excellent)
    }

    func testNeutralRatingsResolveToBalancedSummaries() {
        let ratings = TasteRatings.neutral

        XCTAssertEqual(ratings.tasteFeedbackSummary, .balanced)
        XCTAssertEqual(ratings.strengthFeedbackSummary, .balanced)
        XCTAssertEqual(ratings.overallFeedbackSummary, .good)
    }
}
