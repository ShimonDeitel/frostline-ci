import XCTest

final class FrostlineUITests: XCTestCase {
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset"]
        app.launch()
        return app
    }

    func testLogTodayShowsInStatusCard() throws {
        let app = launchApp()
        let logButton = app.buttons["logTodayButton"]
        XCTAssertTrue(logButton.waitForExistence(timeout: 8))
        logButton.tap()

        let saveButton = app.buttons["logSaveButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.tap()

        let statusCard = app.otherElements["todayStatusCard"]
        XCTAssertTrue(statusCard.waitForExistence(timeout: 12))
    }

    func testMarkSkippedTodayShowsSkippedStatus() throws {
        let app = launchApp()
        app.buttons["logTodayButton"].tap()

        let toggle = app.switches["tookShowerToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))

        // A plain .tap() on this Form-embedded Toggle doesn't reliably land on
        // the actual switch control (its reported frame spans the whole row,
        // label included); tap the trailing edge where the switch knob is.
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()

        // Toggling off collapses the Duration section with an animation;
        // wait for it to actually leave the hierarchy before tapping Save,
        // otherwise Save can land on a still-settling layout. Retry the tap
        // once if the first one didn't register.
        let minutesField = app.textFields["durationMinutesField"]
        if minutesField.waitForExistence(timeout: 2) {
            toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        }
        let sectionGone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: minutesField, handler: nil)
        wait(for: [sectionGone], timeout: 5)

        app.buttons["logSaveButton"].tap()

        XCTAssertTrue(app.staticTexts["Marked as skipped today"].waitForExistence(timeout: 12))
    }

    func testDurationAndNoteFieldsAcceptInput() throws {
        let app = launchApp()
        app.buttons["logTodayButton"].tap()

        let minutesField = app.textFields["durationMinutesField"]
        XCTAssertTrue(minutesField.waitForExistence(timeout: 5))
        minutesField.tap()
        minutesField.typeText("2")

        let secondsField = app.textFields["durationSecondsField"]
        secondsField.tap()
        secondsField.typeText("30")

        let noteField = app.textFields["noteField"]
        noteField.tap()
        noteField.typeText("Felt great")

        app.buttons["logSaveButton"].tap()

        XCTAssertTrue(app.staticTexts["Cold shower logged today"].waitForExistence(timeout: 5))
    }

    func testSettingsButtonOpensSettings() throws {
        let app = launchApp()
        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 8))
        settingsButton.tap()

        XCTAssertTrue(app.navigationBars.element.waitForExistence(timeout: 5))
    }

    func testKeyboardDismissesOnTapOutsideInLogSheet() throws {
        let app = launchApp()
        app.buttons["logTodayButton"].tap()

        let noteField = app.textFields["noteField"]
        XCTAssertTrue(noteField.waitForExistence(timeout: 5))
        noteField.tap()
        noteField.typeText("Testing keyboard")
        XCTAssertTrue(app.keyboards.element.waitForExistence(timeout: 5), "Keyboard did not appear")

        let sectionHeader = app.staticTexts["Today"]
        XCTAssertTrue(sectionHeader.waitForExistence(timeout: 5))
        sectionHeader.tap()

        let keyboardGone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: app.keyboards.element, handler: nil)
        wait(for: [keyboardGone], timeout: 5)
    }
}
