import Testing
@testable import SwipeUI
@Test func dawnAndDuskDiffer() { #expect(Theme.dusk.base != Theme.dawn.base) }
