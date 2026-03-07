import XCTest
@testable import FourSixCoffee

final class BrewSessionLiveActivityPresentationTests: XCTestCase {
    func testInitBuildsExpectedLabelsAndProgress() {
        let presentation = BrewSessionLiveActivityPresentation(
            attributes: BrewSessionActivityAttributes(totalWaterGrams: 240, totalSteps: 6),
            state: .init(
                stepNumber: 2,
                stepGrams: 40,
                cumulativeGrams: 80,
                nextStepNumber: 3,
                nextStepGrams: 40,
                remainingToNextStep: 40,
                remainingTotalSeconds: 130,
                nextStepDate: nil,
                isRunning: true
            )
        )

        XCTAssertEqual(presentation.currentStepTitle, "第2投")
        XCTAssertEqual(presentation.currentStepCompactText, "2")
        XCTAssertEqual(presentation.nextStepText, "次は第3投")
        XCTAssertEqual(presentation.nextAmountLabel, "次に注ぐ量")
        XCTAssertEqual(presentation.nextAmountValue, "40g")
        XCTAssertEqual(presentation.nextAmountCompactText, "次 40g")
        XCTAssertEqual(presentation.remainingClockText, "0:40")
        XCTAssertNil(presentation.statusLabel)
    }

    func testInitBuildsFinishedFallbackWhenNoNextStepExists() {
        let presentation = BrewSessionLiveActivityPresentation(
            attributes: BrewSessionActivityAttributes(totalWaterGrams: 240, totalSteps: 6),
            state: .init(
                stepNumber: 6,
                stepGrams: 50,
                cumulativeGrams: 320,
                nextStepNumber: 0,
                nextStepGrams: 0,
                remainingToNextStep: 0,
                remainingTotalSeconds: 0,
                nextStepDate: nil,
                isRunning: false
            )
        )

        XCTAssertEqual(presentation.currentStepTitle, "第6投")
        XCTAssertEqual(presentation.currentStepCompactText, "6")
        XCTAssertEqual(presentation.nextStepText, "仕上がり")
        XCTAssertEqual(presentation.nextAmountLabel, "状態")
        XCTAssertEqual(presentation.nextAmountValue, "完了")
        XCTAssertEqual(presentation.nextAmountCompactText, "完了")
        XCTAssertEqual(presentation.statusLabel, "停止中")
    }

    func testInitSanitizesNegativeValuesToSafeFallbacks() {
        let presentation = BrewSessionLiveActivityPresentation(
            attributes: BrewSessionActivityAttributes(totalWaterGrams: -10, totalSteps: 6),
            state: .init(
                stepNumber: -1,
                stepGrams: -20,
                cumulativeGrams: -5,
                nextStepNumber: -3,
                nextStepGrams: -20,
                remainingToNextStep: -30,
                remainingTotalSeconds: -90,
                nextStepDate: nil,
                isRunning: false
            )
        )

        XCTAssertEqual(presentation.currentStepTitle, "準備中")
        XCTAssertEqual(presentation.currentStepCompactText, "0")
        XCTAssertEqual(presentation.nextStepText, "次の注湯")
        XCTAssertEqual(presentation.nextAmountLabel, "次に注ぐ量")
        XCTAssertEqual(presentation.nextAmountValue, "0g")
        XCTAssertEqual(presentation.nextAmountCompactText, "次 0g")
        XCTAssertEqual(presentation.remainingClockText, "0:00")
        XCTAssertEqual(presentation.statusLabel, "停止中")
    }
}
