// ABOUTME: Lean unit tests for ClockConfiguration business logic.
// ABOUTME: Tests cover save/load round-trip, computed properties, and font validation.

import XCTest
@testable import clockfloat

final class ClockConfigurationTests: XCTestCase {

    private var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: "com.clockfloat.tests.\(UUID().uuidString)")!
    }

    override func tearDown() {
        if let suite = testDefaults.volatileDomainNames.first {
            UserDefaults.standard.removeSuite(named: suite)
        }
        testDefaults.removePersistentDomain(forName: testDefaults.description)
        testDefaults = nil
        super.tearDown()
    }

    // MARK: - Defaults

    func test_load_returnsDefaults() {
        let config = ClockConfiguration.load(userDefaults: testDefaults)

        XCTAssertEqual(config.fontName, "White Rabbit")
        XCTAssertEqual(config.timeFontSize, 14.0, accuracy: 0.001)
        XCTAssertEqual(config.dateFontSize, 10.0, accuracy: 0.001)
        XCTAssertEqual(config.initialCorner, .bottomRight)
        XCTAssertEqual(config.hoverBehavior, .none)
        XCTAssertEqual(config.timeFormat, "HH:mm")
        XCTAssertEqual(config.dateFormat, "E d")
        XCTAssertEqual(config.lateEnabled, true)
        XCTAssertEqual(config.lateOffsetMinutes, 3)
        XCTAssertEqual(config.opacity, 0.75, accuracy: 0.001)
    }

    // MARK: - Round-trip

    func test_saveAndLoad_roundtrips() {
        let config = ClockConfiguration(
            fontName: "Helvetica",
            dateFontSize: 16.0,
            timeFontSize: 24.0,
            initialCorner: .centerTop,
            hoverBehavior: .hide,
            timeFormat: "h:mm a",
            dateFormat: "EEEE",
            lateEnabled: false,
            lateOffsetMinutes: 10,
            opacity: 0.5
        )
        config.save(to: testDefaults, notify: false)

        let reloaded = ClockConfiguration.load(userDefaults: testDefaults)

        XCTAssertEqual(reloaded.fontName, "Helvetica")
        XCTAssertEqual(reloaded.dateFontSize, 16.0, accuracy: 0.001)
        XCTAssertEqual(reloaded.timeFontSize, 24.0, accuracy: 0.001)
        XCTAssertEqual(reloaded.initialCorner, .centerTop)
        XCTAssertEqual(reloaded.hoverBehavior, .hide)
        XCTAssertEqual(reloaded.timeFormat, "h:mm a")
        XCTAssertEqual(reloaded.dateFormat, "EEEE")
        XCTAssertEqual(reloaded.lateEnabled, false)
        XCTAssertEqual(reloaded.lateOffsetMinutes, 10)
        XCTAssertEqual(reloaded.opacity, 0.5, accuracy: 0.001)
    }

    // MARK: - Late offset

    func test_lateOffsetSeconds_enabledConvertsMinutesToSeconds() {
        var config = ClockConfiguration.load(userDefaults: testDefaults)
        config.lateEnabled = true
        config.lateOffsetMinutes = 5

        XCTAssertEqual(config.lateOffsetSeconds, 300.0, accuracy: 0.001)
    }

    func test_lateOffsetSeconds_disabledReturnsZero() {
        var config = ClockConfiguration.load(userDefaults: testDefaults)
        config.lateEnabled = false
        config.lateOffsetMinutes = 5

        XCTAssertEqual(config.lateOffsetSeconds, 0.0, accuracy: 0.001)
    }

    // MARK: - Text alpha

    func test_textAlpha_isTwoThirdsOfOpacity() {
        var config = ClockConfiguration.load(userDefaults: testDefaults)
        config.opacity = 0.75

        XCTAssertEqual(config.textAlpha, 0.75 * 0.67, accuracy: 0.01)
    }

    // MARK: - Font validation

    func test_validatedFontName_validFont_returnsAsIs() {
        XCTAssertEqual(ClockConfiguration.validatedFontName("Helvetica"), "Helvetica")
    }

    func test_validatedFontName_invalidFont_returnsDefault() {
        XCTAssertEqual(ClockConfiguration.validatedFontName("NotARealFont"), "White Rabbit")
    }

    func test_validatedFontName_emptyString_returnsDefault() {
        XCTAssertEqual(ClockConfiguration.validatedFontName(""), "White Rabbit")
    }

    // MARK: - Corner orientation

    func test_cornerOrientationValues_areUnique() {
        let values = ClockConfiguration.Corner.allCases.map { $0.orientationValue }
        XCTAssertEqual(Set(values).count, values.count)
    }

    // MARK: - Notification

    func test_save_withNotify_postsNotification() {
        let config = ClockConfiguration.load(userDefaults: testDefaults)
        let expectation = expectation(forNotification: .clockConfigurationDidChange, object: nil)
        config.save(to: testDefaults, notify: true)
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Font size floor

    func test_load_tinyFontSize_resetsToDefault() {
        testDefaults.set(0.01, forKey: ClockConfiguration.Keys.dateFontSize)
        testDefaults.set(0.014, forKey: ClockConfiguration.Keys.timeFontSize)

        let config = ClockConfiguration.load(userDefaults: testDefaults)

        XCTAssertEqual(config.dateFontSize, 10.0, accuracy: 0.001)
        XCTAssertEqual(config.timeFontSize, 14.0, accuracy: 0.001)
    }
}
