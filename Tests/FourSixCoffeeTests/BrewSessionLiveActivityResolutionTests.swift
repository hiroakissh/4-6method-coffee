import XCTest
@testable import FourSixCoffee

final class BrewSessionLiveActivityResolutionTests: XCTestCase {
    func testResolveSyncActionUpdatesCurrentWhenCurrentExists() {
        let action = BrewSessionLiveActivityResolution.resolveSyncAction(
            currentActivityID: "current",
            existingActivityIDs: ["current", "other"]
        )

        XCTAssertEqual(action, .updateCurrent)
    }

    func testResolveSyncActionAttachesLatestExistingWhenCurrentMissing() {
        let action = BrewSessionLiveActivityResolution.resolveSyncAction(
            currentActivityID: nil,
            existingActivityIDs: ["older", "latest"]
        )

        XCTAssertEqual(action, .attachExisting(id: "latest"))
    }

    func testResolveSyncActionRequestsNewWhenNoExistingActivity() {
        let action = BrewSessionLiveActivityResolution.resolveSyncAction(
            currentActivityID: nil,
            existingActivityIDs: []
        )

        XCTAssertEqual(action, .requestNew)
    }

    func testResolveEndTargetIDsIncludesExistingEvenWithoutCurrentReference() {
        let targetIDs = BrewSessionLiveActivityResolution.resolveEndTargetIDs(
            currentActivityID: nil,
            existingActivityIDs: ["existing"]
        )

        XCTAssertEqual(targetIDs, ["existing"])
    }

    func testResolveEndTargetIDsIncludesCurrentWhenNotInExisting() {
        let targetIDs = BrewSessionLiveActivityResolution.resolveEndTargetIDs(
            currentActivityID: "current",
            existingActivityIDs: ["existing"]
        )

        XCTAssertEqual(targetIDs, ["existing", "current"])
    }

    func testResolveEndTargetIDsRemovesDuplicateIDs() {
        let targetIDs = BrewSessionLiveActivityResolution.resolveEndTargetIDs(
            currentActivityID: "second",
            existingActivityIDs: ["first", "first", "second", "second"]
        )

        XCTAssertEqual(targetIDs, ["first", "second"])
    }
}
