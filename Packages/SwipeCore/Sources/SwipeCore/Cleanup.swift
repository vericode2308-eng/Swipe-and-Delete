import Foundation

/// A photo the scanner may analyse. Videos and screenshots are never listed.
public struct ScanItem: Equatable, Hashable, Sendable {
    public let id: String
    public let created: Date
    public let modified: Date
    public init(id: String, created: Date, modified: Date) {
        self.id = id; self.created = created; self.modified = modified
    }
}

/// What Vision found in one photo, before it is tied to an id.
public struct PhotoAnalysis: Equatable, Sendable {
    public var hasPeople: Bool
    public var isUtility: Bool
    public var qualityScore: Float
    public var imageHash: UInt64
    /// Feature print as little-endian Float32 values (empty when unavailable).
    public var featurePrint: [Float]
    public init(hasPeople: Bool, isUtility: Bool, qualityScore: Float,
                imageHash: UInt64, featurePrint: [Float] = []) {
        self.hasPeople = hasPeople; self.isUtility = isUtility
        self.qualityScore = qualityScore; self.imageHash = imageHash
        self.featurePrint = featurePrint
    }
}

/// One analysed photo, as kept in the cache (D-21). Holds no swipe progress.
public struct PhotoTraits: Codable, Equatable, Sendable {
    public let id: String
    public let modified: Date
    public let created: Date
    public let hasPeople: Bool
    public let isUtility: Bool
    public let qualityScore: Float
    public let imageHash: UInt64
    public let featurePrint: [Float]
    public let visionRevision: Int
    public init(id: String, modified: Date, created: Date, hasPeople: Bool, isUtility: Bool,
                qualityScore: Float, imageHash: UInt64, featurePrint: [Float] = [], visionRevision: Int) {
        self.id = id; self.modified = modified; self.created = created
        self.hasPeople = hasPeople; self.isUtility = isUtility
        self.qualityScore = qualityScore; self.imageHash = imageHash
        self.featurePrint = featurePrint; self.visionRevision = visionRevision
    }
}

/// Looks at one photo's local thumbnail. The Vision version lives in the app target.
public protocol PhotoAnalyzer: Sendable {
    /// Changes when Vision's models change; cached entries with another value are redone.
    var revision: Int { get }
    /// nil when there is no local thumbnail (iCloud-only) or the photo vanished: skipped.
    func analyse(id: String) async -> PhotoAnalysis?
}

/// The filters' current answer, published while the scan runs.
public struct CleanupResult: Equatable, Sendable {
    public var duplicateSets: [[String]] = []
    public var pagesAndThings: [String] = []
    public var checked = 0
    public var total = 0
    public var isRunning = false
    public init() {}

    public var duplicateCount: Int { duplicateSets.reduce(0) { $0 + $1.count } }

    /// Results without photos that were just deleted; sets left with one photo disappear.
    public func removing(_ ids: [String]) -> CleanupResult {
        let gone = Set(ids)
        var r = self
        r.duplicateSets = duplicateSets.map { $0.filter { !gone.contains($0) } }.filter { $0.count > 1 }
        r.pagesAndThings = pagesAndThings.filter { !gone.contains($0) }
        return r
    }
}

/// Pure rules for the Quick clean-up filters. Thresholds are starting points (see BUILD_PLAN).
public struct CleanupIndex: Sendable {
    /// Two image hashes this close (bits) count as the same picture.
    public var hashDistance = 2
    /// Feature-print distance below this = near-identical shot.
    public var featureThreshold: Float = 0.35
    /// Shots further apart than this are never near-identical.
    public var burstWindow: TimeInterval = 60
    /// Pages & Things quality cut-off.
    public var lowQuality: Float = -0.3

    public init() {}

    /// Sets of two or more ids. Sets newest first; inside a set oldest first.
    public func duplicateSets(_ traits: [PhotoTraits]) -> [[String]] {
        let n = traits.count
        guard n > 1 else { return [] }
        var parent = Array(0..<n)
        func find(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { parent[x] = parent[parent[x]]; x = parent[x] }
            return x
        }
        func union(_ a: Int, _ b: Int) { let ra = find(a), rb = find(b); if ra != rb { parent[ra] = rb } }

        // (a) same picture anywhere: split the 64 bits in four 16-bit lanes; a pair within
        // 2 bits must agree on at least one lane, so only lane-mates are compared.
        var lanes = [[UInt64: [Int]]](repeating: [:], count: 4)
        for (i, t) in traits.enumerated() where Self.hasDetail(t.imageHash) {
            for lane in 0..<4 {
                let key = (t.imageHash >> UInt64(lane * 16)) & 0xFFFF
                lanes[lane][key, default: []].append(i)
            }
        }
        for lane in lanes {
            for (_, members) in lane where members.count > 1 {
                if members.count > 400 { continue }   // a flat-colour bucket, not a picture
                for a in 0..<members.count {
                    for b in (a + 1)..<members.count {
                        let x = traits[members[a]].imageHash ^ traits[members[b]].imageHash
                        if x.nonzeroBitCount <= hashDistance { union(members[a], members[b]) }
                    }
                }
            }
        }

        // (b) near-identical shots taken within the burst window.
        let byTime = traits.indices.sorted { traits[$0].created < traits[$1].created }
        for (pos, i) in byTime.enumerated() where !traits[i].featurePrint.isEmpty {
            var next = pos + 1
            while next < byTime.count,
                  traits[byTime[next]].created.timeIntervalSince(traits[i].created) <= burstWindow {
                let j = byTime[next]
                if !traits[j].featurePrint.isEmpty,
                   Self.distance(traits[i].featurePrint, traits[j].featurePrint) < featureThreshold {
                    union(i, j)
                }
                next += 1
            }
        }

        var groups: [Int: [Int]] = [:]
        for i in 0..<n { groups[find(i), default: []].append(i) }
        let sets = groups.values.filter { $0.count > 1 }.map { members in
            members.sorted { traits[$0].created < traits[$1].created }
        }
        let newestFirst = sets.sorted {
            traits[$0.last!].created > traits[$1.last!].created
        }
        return newestFirst.map { $0.map { traits[$0].id } }
    }

    /// Photos with no people that look like pages, notes or accidental shots. Newest first.
    public func pagesAndThings(_ traits: [PhotoTraits]) -> [String] {
        traits.filter { !$0.hasPeople && ($0.isUtility || $0.qualityScore < lowQuality) }
            .sorted { $0.created > $1.created }
            .map(\.id)
    }

    /// Flat or near-empty hashes match every other flat picture, so they never count.
    static func hasDetail(_ hash: UInt64) -> Bool {
        let bits = hash.nonzeroBitCount
        return bits >= 8 && bits <= 56
    }

    static func distance(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return .infinity }
        var sum: Float = 0
        for i in 0..<a.count { let d = a[i] - b[i]; sum += d * d }
        return sum.squareRoot()
    }
}
