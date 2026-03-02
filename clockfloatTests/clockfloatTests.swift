// ABOUTME: Unit tests for ClockConfiguration, HoverBehavior, and Corner enums.
// ABOUTME: Uses isolated UserDefaults suites to avoid polluting real preferences.

import XCTest
@testable import clockfloat

final class ClockConfigurationTests: XCTestCase {

    private var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: "com.clockfloat.tests.\(UUID().uuidString)")!
    }

    override func tearDown() {
        if let suiteName = testDefaults.volatileDomainNames.first {
            UserDefaults.standard.removeSuite(named: suiteName)
        }
        testDefaults.removePersistentDomain(forName: testDefaults.description)
        testDefaults = nil
        super.tearDown()
    }

    // MARK: - Defaults

    func test_ClockConfiguration_load_returnsDefaults() {
        let config = ClockConfiguration.load(userDefaults: testDefaults)

        XCTAssertEqual(config.fontName, "White Rabbit")
        XCTAssertEqual(config.initialCorner, .bottomRight)
        XCTAssertEqual(config.hoverBehavior, .dodge)
        XCTAssertEqual(config.timeFormat, "HH:mm")
        XCTAssertEqual(config.dateFormat, "E d")
        XCTAssertEqual(config.lateEnabled, true)
        XCTAssertEqual(config.lateOffsetMinutes, 3)
        XCTAssertEqual(config.opacity, 0.75, accuracy: 0.001)
    }

    // MARK: - Save / Load round-trip

    func test_ClockConfiguration_save_roundtrips() {
        var config = ClockConfiguration.load(userDefaults: testDefaults)
        config.fontName = "Helvetica"
        config.dateFontSize = 14.0
        config.timeFontSize = 18.0
        config.initialCorner = .centerTop
        config.hoverBehavior = .hide
        config.timeFormat = "h:mm a"
        config.dateFormat = "EEEE"
        config.lateEnabled = false
        config.lateOffsetMinutes = 10
        config.opacity = 0.5

        config.save(to: testDefaults)

        let reloaded = ClockConfiguration.load(userDefaults: testDefaults)

        XCTAssertEqual(reloaded.fontName, "Helvetica")
        XCTAssertEqual(reloaded.dateFontSize, 14.0, accuracy: 0.001)
        XCTAssertEqual(reloaded.timeFontSize, 18.0, accuracy: 0.001)
        XCTAssertEqual(reloaded.initialCorner, .centerTop)
        XCTAssertEqual(reloaded.hoverBehavior, .hide)
        XCTAssertEqual(reloaded.timeFormat, "h:mm a")
        XCTAssertEqual(reloaded.dateFormat, "EEEE")
        XCTAssertEqual(reloaded.lateEnabled, false)
        XCTAssertEqual(reloaded.lateOffsetMinutes, 10)
        XCTAssertEqual(reloaded.opacity, 0.5, accuracy: 0.001)
    }

    // MARK: - Notification

    func test_ClockConfiguration_save_postsNotification() {
        var config = ClockConfiguration.load(userDefaults: testDefaults)

        let expectation = expectation(forNotification: .clockConfigurationDidChange, object: nil)

        config.save(to: testDefaults)

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Migration

    func test_ClockConfiguration_migration_convertsRatioToPointSize() {
        // Simulate pre-migration state: ratio-based font sizes
        testDefaults.set(0.01, forKey: "ClockDateFontSize")
        testDefaults.set(0.014, forKey: "ClockTimeFontSize")
        testDefaults.set(false, forKey: "ClockFontSizeMigrated")

        let config = ClockConfiguration.load(userDefaults: testDefaults)

        // After migration, sizes should be absolute point sizes (> 1.0)
        XCTAssertGreaterThan(config.dateFontSize, 1.0,
                             "Date font size should be migrated to absolute points")
        XCTAssertGreaterThan(config.timeFontSize, 1.0,
                             "Time font size should be migrated to absolute points")

        // Migration flag should be set
        XCTAssertTrue(testDefaults.bool(forKey: "ClockFontSizeMigrated"))
    }

    func test_ClockConfiguration_migration_skipsAlreadyMigrated() {
        testDefaults.set(true, forKey: "ClockFontSizeMigrated")
        testDefaults.set(16.0, forKey: "ClockDateFontSize")
        testDefaults.set(20.0, forKey: "ClockTimeFontSize")

        let config = ClockConfiguration.load(userDefaults: testDefaults)

        XCTAssertEqual(config.dateFontSize, 16.0, accuracy: 0.001)
        XCTAssertEqual(config.timeFontSize, 20.0, accuracy: 0.001)
    }
}

// MARK: - HoverBehavior Tests

final class HoverBehaviorTests: XCTestCase {

    func test_HoverBehavior_rawValue_roundtrips() {
        for behavior in [HoverBehavior.dodge, .hide, .none] {
            let raw = behavior.rawValue
            let restored = HoverBehavior(rawValue: raw)
            XCTAssertEqual(restored, behavior,
                           "HoverBehavior.\(behavior) should round-trip via rawValue")
        }
    }
}

// MARK: - Corner Tests

final class CornerTests: XCTestCase {

    func test_Corner_allSixCases_haveUniqueOrientationValues() {
        let allCorners: [ClockConfiguration.Corner] = [
            .topLeft, .topRight, .bottomRight, .bottomLeft,
            .centerTop, .centerBottom
        ]

        let values = allCorners.map { $0.orientationValue }
        let uniqueValues = Set(values)

        XCTAssertEqual(values.count, uniqueValues.count,
                       "All corners must have unique orientation values")
        XCTAssertEqual(allCorners.count, 6, "There should be exactly 6 corner positions")
    }

    func test_Corner_rawValue_roundtrips() {
        let allCorners: [ClockConfiguration.Corner] = [
            .topLeft, .topRight, .bottomRight, .bottomLeft,
            .centerTop, .centerBottom
        ]

        for corner in allCorners {
            let raw = corner.rawValue
            let restored = ClockConfiguration.Corner(rawValue: raw)
            XCTAssertEqual(restored, corner,
                           "Corner.\(corner) should round-trip via rawValue")
        }
    }
}

// MARK: - Late Offset Tests

final class LateOffsetTests: XCTestCase {

    func test_lateOffset_convertsMinutesToSeconds() {
        var config = ClockConfiguration.load(
            userDefaults: UserDefaults(suiteName: "com.clockfloat.tests.\(UUID().uuidString)")!
        )
        config.lateEnabled = true
        config.lateOffsetMinutes = 5

        XCTAssertEqual(config.lateOffsetSeconds, 300.0, accuracy: 0.001)
    }

    func test_lateOffset_zeroWhenDisabled() {
        var config = ClockConfiguration.load(
            userDefaults: UserDefaults(suiteName: "com.clockfloat.tests.\(UUID().uuidString)")!
        )
        config.lateEnabled = false
        config.lateOffsetMinutes = 5

        XCTAssertEqual(config.lateOffsetSeconds, 0.0, accuracy: 0.001)
    }
}

// MARK: - Opacity Tests

final class OpacityTests: XCTestCase {

    func test_opacity_textAlpha_isTwoThirdsOfBackground() {
        var config = ClockConfiguration.load(
            userDefaults: UserDefaults(suiteName: "com.clockfloat.tests.\(UUID().uuidString)")!
        )
        config.opacity = 0.75

        let expectedTextAlpha = 0.75 * 0.67
        XCTAssertEqual(config.textAlpha, expectedTextAlpha, accuracy: 0.01)
    }
}
