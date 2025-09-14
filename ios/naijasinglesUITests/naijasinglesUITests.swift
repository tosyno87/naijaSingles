import XCTest

@MainActor
class naijasinglesUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        Task {
            await setupSnapshot(app)
        }
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testScreenshots() async throws {
        // Wait for app to load
        sleep(3)
        
        // Screenshot 1: Welcome/Splash Screen
        await snapshot("01-Welcome")
        
        // Navigate through onboarding if present
        if app.buttons["Get Started"].exists {
            app.buttons["Get Started"].tap()
            sleep(2)
            await snapshot("02-Onboarding")
        }
        
        // Screenshot 2: Main Navigation/Home Screen
        sleep(2)
        await snapshot("03-Home")
        
        // Navigate to Communities Hub
        if app.tabBars.buttons["Communities"].exists {
            app.tabBars.buttons["Communities"].tap()
            sleep(2)
            await snapshot("04-Communities")
        }
        
        // Navigate to Connect/Explore
        if app.tabBars.buttons["Connect"].exists {
            app.tabBars.buttons["Connect"].tap()
            sleep(2)
            await snapshot("05-Connect")
        }
        
        // Navigate to Events
        if app.tabBars.buttons["Events"].exists {
            app.tabBars.buttons["Events"].tap()
            sleep(2)
            await snapshot("06-Events")
        }
        
        // Navigate to Profile
        if app.tabBars.buttons["Profile"].exists {
            app.tabBars.buttons["Profile"].tap()
            sleep(2)
            await snapshot("07-Profile")
        }
        
        // Navigate to Groups (if accessible from Communities)
        if app.buttons["Groups"].exists {
            app.buttons["Groups"].tap()
            sleep(2)
            await snapshot("08-Groups")
            app.navigationBars.buttons.element(boundBy: 0).tap() // Back button
        }
        
        // Navigate to Cultural Profile
        if app.buttons["Cultural Profile"].exists {
            app.buttons["Cultural Profile"].tap()
            sleep(2)
            await snapshot("09-Cultural-Profile")
            app.navigationBars.buttons.element(boundBy: 0).tap() // Back button
        }
        
        // Navigate to Settings
        if app.buttons["Settings"].exists {
            app.buttons["Settings"].tap()
            sleep(2)
            await snapshot("10-Settings")
        }
    }
    
    func testCreateEventFlow() async throws {
        // Navigate to Events
        if app.tabBars.buttons["Events"].exists {
            app.tabBars.buttons["Events"].tap()
            sleep(2)
        }
        
        // Tap Create Event button
        if app.buttons["Create Event"].exists {
            app.buttons["Create Event"].tap()
            sleep(2)
            await snapshot("11-Create-Event")
        }
    }
    
    func testCreateGroupFlow() async throws {
        // Navigate to Communities
        if app.tabBars.buttons["Communities"].exists {
            app.tabBars.buttons["Communities"].tap()
            sleep(2)
        }
        
        // Tap Groups button
        if app.buttons["Groups"].exists {
            app.buttons["Groups"].tap()
            sleep(2)
        }
        
        // Tap Create Group button
        if app.buttons["Create Group"].exists {
            app.buttons["Create Group"].tap()
            sleep(2)
            await snapshot("12-Create-Group")
        }
    }
}

