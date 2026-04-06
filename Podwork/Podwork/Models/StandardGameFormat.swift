import Foundation

// MARK: - Standard Game Format (SGF) v2.0
// A refined, elegant structure designed to mimic the natural flow of a Commander game.
// Focuses on human-readability and semantic grouping of game phases.

/// The complete, serializable record of a game.
public struct GameRecord: Codable, Identifiable, Sendable {
    public let id: UUID
    public let version: String = "2.0.0"
    
    // MARK: 1. The Header
    /// Contextual information established before the game begins.
    public let header: GameHeader
    
    // MARK: 2. The Pod
    /// The players, their decks, and their seating arrangement.
    public let pod: [Seat]
    
    // MARK: 3. The Timeline
    /// The chronological unfolding of the game, turn by turn.
    public let history: [Turn_]
    
    // MARK: 4. The Summary
    /// The conclusion, results, and post-game feedback (Vibe Checks).
    public let summary: GameSummary
    
    public init(id: UUID = UUID(), header: GameHeader, pod: [Seat], timeline: [Turn_], summary: GameSummary) {
        self.id = id
        self.header = header
        self.pod = pod
        self.history = timeline
        self.summary = summary
    }
}

// MARK: - Components

/// High-level metadata about the match.
public struct GameHeader: Codable, Sendable {
    public let datePlayed: Date
    public let duration: TimeInterval
    public let gameType: String // e.g., "Standard", "Planchase"
    
    public init(datePlayed: Date, duration: TimeInterval, gameType: String = "Commander") {
        self.datePlayed = datePlayed
        self.duration = duration
        self.gameType = gameType
    }
}

/// Represents a single player's seat at the table.
public struct Seat: Codable, Identifiable, Sendable {
    public var id: Int { index }
    
    public let index: Int
    public let commanders: [String]
    
    /// The bracket (1-5) the player claimed their deck belonged to BEFORE the game.
    public let selfRatedBracket: Int
   // public let vibeCheck: [VibeCheck]
    
    
    public init(index: Int, commanders: [String], selfRatedBracket: Int){ //}, vibeCheck: [VibeCheck]) {
        self.index = index
        self.commanders = commanders
        self.selfRatedBracket = selfRatedBracket
        //self.vibeCheck = vibeCheck
    }
}

/// A single turn in the timeline.
public struct Turn_: Codable, Identifiable, Sendable {
    public var id: Int { number }
    
    public let number: Int
    public let round: Int
    public let activeSeatIndex: Int
    public let duration: TimeInterval
    
    /// The narrative log of what happened.
    public let log: [GameAction]
    
    /// The "Scoreboard" state at the END of this turn.
    public let scoreboard: Scoreboard
    
    public init(number: Int, round: Int, activeSeatIndex: Int, duration: TimeInterval, log: [GameAction], scoreboard: Scoreboard) {
        self.number = number
        self.round = round
        self.activeSeatIndex = activeSeatIndex
        self.duration = duration
        self.log = log
        self.scoreboard = scoreboard
    }
}

/// A discrete event or action that altered the game state.
public struct GameAction: Codable, Sendable {
    public let type: ActionType
    public let actorSeatIndex: Int
    public let targetSeatIndex: Int?
    public let value: Int?
    public let note: String?
    
    public init(type: ActionType, actorSeatIndex: Int, targetSeatIndex: Int? = nil, value: Int? = nil, note: String? = nil) {
        self.type = type
        self.actorSeatIndex = actorSeatIndex
        self.targetSeatIndex = targetSeatIndex
        self.value = value
        self.note = note
    }
}

public enum ActionType: String, Codable, Sendable {
    case lifeChange        // Net change in life total
    case poisonChange      // Infect counters added
    case castCommander     // Commander tax incremented
    case elimination       // Player removed from game
    case bombPod           // BombPod triggered N times
    case solRing           // Sol Ring cast
    case note              // Generic text note
}

/// A snapshot of all scores and counters.
public struct Scoreboard: Codable, Sendable {
    /// Life totals indexed by Seat Index.
    public let lifeTotals: [Int]
    
    /// Poison counters indexed by Seat Index.
    public let poisonTotals: [Int]
    
    /// Sparse record of Commander Damage. Only non-zero values are stored.
    /// Useful for readable JSON (avoids giant matrices of zeros).
    public let commanderDamage: [CommanderDamageRecord]
    
    /// Current Tax amount for each seat.
    public let commanderTax: [Int]
    
    public init(lifeTotals: [Int], poisonTotals: [Int], commanderDamage: [CommanderDamageRecord], commanderTax: [Int]) {
        self.lifeTotals = lifeTotals
        self.poisonTotals = poisonTotals
        self.commanderDamage = commanderDamage
        self.commanderTax = commanderTax
    }
}

public struct CommanderDamageRecord: Codable, Sendable {
    public let fromSeatIndex: Int
    public let toSeatIndex: Int
    public let amount: Int
    
    public init(fromSeatIndex: Int, toSeatIndex: Int, amount: Int) {
        self.fromSeatIndex = fromSeatIndex
        self.toSeatIndex = toSeatIndex
        self.amount = amount
    }
}

/// The Post-Game Analysis.
public struct GameSummary: Codable, Sendable {
    public let winningSeatIndex: Int? // Nil if draw
    public let winCondition: String   // "Combat", "Combo", "Concede"
    
    /// "Vibe Check": How players rated each other's decks AFTER the game.
    public let vibeChecks: [VibeCheck]
    
    public init(winningSeatIndex: Int?, winCondition: String, vibeChecks: [VibeCheck]) {
        self.winningSeatIndex = winningSeatIndex
        self.winCondition = winCondition
        self.vibeChecks = vibeChecks
    }
}



public struct VibeCheck: Codable, Sendable {
    public let checkerSeatIndex: Int
    public let bracketVibe: Int
    
    public init(checkerSeatIndex: Int, bracketVibe: Int) {
        self.checkerSeatIndex = checkerSeatIndex
        self.bracketVibe = bracketVibe
    }
}
