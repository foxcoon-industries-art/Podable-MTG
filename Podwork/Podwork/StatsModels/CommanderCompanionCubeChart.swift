import SwiftUI
import Podwork


/// Represents the data for all 4 players
public struct PlayerChartData : Identifiable {
    public let id = UUID()
    /// Matrix of damage dealt: [attackerIndex][defenderIndex] = damage
    public let damageMatrix: [[Double]]
    
    public init(damageMatrix: [[Double]]) {
        self.damageMatrix = damageMatrix
    }
}

public struct CommanderCompanionCube: View {
    let data: PlayerChartData
    
    public init(data: PlayerChartData) {
        self.data = data
    }
    
    public var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let rect = CGRect(x: 0, y: 0, width: size, height: size)
            
            ZStack(alignment:.center) {
                Rectangle()
                    .fill(Color.brown.gradient)
                
                drawPartitions(in: rect)
                
                Rectangle()
                    .fill(Color.clear)
                    .stroke(Color.black, lineWidth: 3)
                
                // overlay labels (adjacent/outside and self-corner labels)
                drawLabels(in: rect)
            }
        }
        .frame(maxWidth: 200, maxHeight: 200, alignment: .bottom)
        .aspectRatio(1, contentMode: .fit)
    }
    
    
    // MARK: - Color helpers and mappings
    
    /// Colors for players 0..3
    private func getColor(for player: Int) -> Color {
        let colors: [Color] = [.green, .orange, .blue, .purple]
        return colors[player % colors.count]
    }
    
    /// We want player 0 to occupy the bottom-left quadrant.
    /// We'll define the ordering of positions (clockwise) as:
    /// positions: 0 = top-left, 1 = top-right, 2 = bottom-right, 3 = bottom-left
    /// and map them to players so that player 0 => bottom-left (position 3).
    /// The mapping we use here: position -> player  = [1, 2, 3, 0]
    /// So top-left = player1, top-right = player2, bottom-right = player3, bottom-left = player0
    private let positionToPlayer: [Int] = [1, 2, 3, 0]
    private func player(atPosition pos: Int) -> Int {
        positionToPlayer[(pos % 4 + 4) % 4]
    }
    private func position(ofPlayer player: Int) -> Int? {
        positionToPlayer.firstIndex(of: player)
    }
    
    
    // small safe value helper (the old "if zero or one then 1" logic in various places)
    private func safeForPartition(_ v: Double) -> Double {
        //(v == 0.0 || v == 1.0) ? 1.0 : v
        v
    }
    
    
    // MARK: - Labels (adjacent outside labels + self-corner labels)
    @ViewBuilder
    private func drawLabels(in rect: CGRect) -> some View {
        // We'll draw:
        // 1) adjacent pair labels (outside the square, one label per direction showing both directions stacked)
        // 2) self-interaction numeric in each corner inside the quadrant
        
        // Adjacent labels: iterate over positions 0..3 where edge i is between position i and (i+1)
        ForEach(0..<4, id: \.self) { side in
            // attacker = player at position `side`
            let attacker = player(atPosition: side)
            let defender = player(atPosition: (side + 1) % 4)
            
            // Decide ordering so attacker is closest to its quadrant.
            // We'll compare the quadrant centers' x (for horizontal sides) or y (for vertical).
            let posAtt = position(ofPlayer: attacker) ?? 0
            let posDef = position(ofPlayer: defender) ?? 0
            let attCorner = cornerLabelPosition(forPosition: posAtt, in: rect, inset: rect.width * 0.08)
            let defCorner = cornerLabelPosition(forPosition: posDef, in: rect, inset: rect.width * 0.08)
            
            
            // raw values
            let rawAtoB = data.damageMatrix[attacker][defender]
            let rawBtoA = data.damageMatrix[defender][attacker]
            
            // "normalization" used to compute where along side to place outside labels
            let aVal = safeForPartition(rawAtoB)
            let bVal = safeForPartition(rawBtoA)
            let total = aVal + bVal
            var ratio = total == 0 ? 0.5 : aVal / total
            
            
            
            // Build outside stacked label (horizontal for top/bottom sides, vertical for left/right)
            // Use attacker color for its number, defender color for the other number.
            Group {
                if side == 0 || side == 2 { // top or bottom -> HStack outside
                    HStack(spacing: 4) {
                        if attCorner.x < defCorner.x {
                            // attacker is on left
                            Text("\(Int(rawAtoB))").foregroundStyle(getColor(for: attacker))
                            Text("\(Int(rawBtoA))").foregroundStyle(getColor(for: defender))
                        } else {
                            // attacker is on right -> place attacker last
                            Text("\(Int(rawBtoA))").foregroundStyle(getColor(for: defender))
                            Text("\(Int(rawAtoB))").foregroundStyle(getColor(for: attacker))
                        }
                    }
                } else { // left/right -> VStack
                    VStack(spacing: 2) {
                        if attCorner.y < defCorner.y {
                            // attacker is more towards top -> draw attacker first
                            Text("\(Int(rawAtoB))").foregroundStyle(getColor(for: attacker))
                            Text("\(Int(rawBtoA))").foregroundStyle(getColor(for: defender))
                        } else {
                            Text("\(Int(rawBtoA))").foregroundStyle(getColor(for: defender))
                            Text("\(Int(rawAtoB))").foregroundStyle(getColor(for: attacker))
                        }
                    }
                }
            }
            //.customStroke(color: Color.black, width: 0.5)
            .bold()
            .font(.footnote)
            .lineLimit(1)
            .minimumScaleFactor(0.15)
            .position(whereToPlace(d1: aVal, d2: bVal, total: total, in: rect, side: side))
        }
        
        // Self-interaction labels: draw each player's self damage in their quadrant corner (inset).
        ForEach(0..<4, id: \.self) { pos in
            let player = player(atPosition: pos)
            let selfDamage = Int(data.damageMatrix[player][player])
            
            // Compute corner position for the quadrant (we have topLeft, topRight, bottomRight, bottomLeft in drawPartitions)
            // Reuse same geometry calculations: produce a small inset point in the corner.
            let cornerPoint = cornerLabelPosition(forPosition: pos, in: rect, inset: rect.width * 0.08)
            
            Text("\(selfDamage)")
                .font(.caption)
                .fontWeight(.bold)
                //.foregroundStyle(getColor(for: player))
                .foregroundStyle(Color.black)
                //.customStroke(color: Color.black, width: 0.25)
                //.padding(2)
                //.background(.white.opacity(0.85))
                //.clipShape(RoundedRectangle(cornerRadius: 3))
                .position(cornerPoint)
        }
    }
    
    /// Where to place adjacent labels (kept the same logic but parameter renamed to `side`).
    func whereToPlace(d1: Double, d2: Double, total: Double, in rect: CGRect, side: Int) -> CGPoint {
        //let ratio = total == 0 ? 0.50 : d1 / total
        let ratio = self.ratio(a: d1, b: d2)
        
        let w = rect.width
        let h = rect.height
        let offset = 8.0 // slightly larger offset so outside labels don't overlap stroke
        
        var pos: CGPoint
        switch side {
        case 0: // top: x between left->right
            pos = CGPoint(x: rect.minX + w * ratio, y: rect.minY - offset)
        case 1: // right: y between top->bottom
            pos = CGPoint(x: rect.maxX + offset, y: rect.minY + h * ratio)
        case 2: // bottom: x between right->left (we keep original mirrored behavior)
            pos = CGPoint(x: rect.maxX - w * ratio, y: rect.maxY + offset)
        case 3: // left
            pos = CGPoint(x: rect.minX - offset, y: rect.maxY - h * ratio)
        default:
            pos = .zero
        }
        return pos
    }
    
    /// small helper to compute corner interior position for self interaction label
    private func cornerLabelPosition(forPosition pos: Int, in rect: CGRect, inset: CGFloat) -> CGPoint {
        switch pos {
        case 0: // top-left
            return CGPoint(x: rect.minX + inset, y: rect.minY + inset)
        case 1: // top-right
            return CGPoint(x: rect.maxX - inset, y: rect.minY + inset)
        case 2: // bottom-right
            return CGPoint(x: rect.maxX - inset, y: rect.maxY - inset)
        case 3: // bottom-left
            return CGPoint(x: rect.minX + inset, y: rect.maxY - inset)
        default:
            return CGPoint(x: rect.midX, y: rect.midY)
        }
    }
    

    
    // MARK: - Partitions & diamond drawing (Canvas)

    @ViewBuilder
    private func drawPartitions(in rect: CGRect) -> some View {
        Canvas { context, size in
            let w = rect.width
            let h = rect.height
            
            // Partition point along a side (side: 0 top, 1 right, 2 bottom, 3 left)
            // Use attacker/defender mapping by positions -> players
            @MainActor
            func partitionPoint(side: Int) -> CGPoint {
                let left = rect.minX, top = rect.minY, right = rect.maxX, bottom = rect.maxY
                // players on that side: attacker at position `side`, defender at position `side+1`
                let attacker = player(atPosition: side)
                let defender = player(atPosition: (side + 1) % 4)
                
                let d1_ = safeForPartition(data.damageMatrix[attacker][defender])
                let d2_ = safeForPartition(data.damageMatrix[defender][attacker])
                let total = d1_ + d2_
                let ratio = self.ratio(a: d1_, b: d2_)
                //let ratio = total == 0 ? 0.5 : d1_ / total
                
                switch side {
                case 0: // top edge from left->right
                    return CGPoint(x: left + w * ratio, y: top)
                case 1: // right edge from top->bottom
                    return CGPoint(x: right, y: top + h * ratio)
                case 2: // bottom edge from right->left (so reflect)
                    return CGPoint(x: right - w * ratio, y: bottom)
                case 3: // left edge from bottom->top
                    return CGPoint(x: left, y: bottom - h * ratio)
                default:
                    return CGPoint(x: rect.midX, y: rect.midY)
                }
            }
            
            let topPoint = partitionPoint(side: 0)
            let rightPoint = partitionPoint(side: 1)
            let bottomPoint = partitionPoint(side: 2)
            let leftPoint = partitionPoint(side: 3)
            
            // corners where adjacent walls intersect
            let topLeft     = CGPoint(x: leftPoint.x,  y: topPoint.y)
            let topRight    = CGPoint(x: rightPoint.x, y: topPoint.y)
            let bottomRight = CGPoint(x: rightPoint.x, y: bottomPoint.y)
            let bottomLeft  = CGPoint(x: leftPoint.x,  y: bottomPoint.y)
            
            func midpoint(_ a: CGPoint, _ b: CGPoint, _ c : Double = 0.50) -> CGPoint {
                CGPoint(x: c*(a.x + b.x), y: c*(a.y + b.y))
            }
            
            // diagonal/ opposite totals (players at positions 0 & 2, 1 & 3)
            let playerTopLeft = player(atPosition: 0)
            let playerTopRight = player(atPosition: 1)
            let playerBottomRight = player(atPosition: 2)
            let playerBottomLeft = player(atPosition: 3)
            
            // Opposite pairs: (top-left <-> bottom-right) and (top-right <-> bottom-left)
            let topLeftOppTotal = data.damageMatrix[playerTopLeft][playerBottomRight] + data.damageMatrix[playerBottomRight][playerTopLeft]
            let topRightOppTotal = data.damageMatrix[playerTopRight][playerBottomLeft] + data.damageMatrix[playerBottomLeft][playerTopRight]
            
      
            let topLeftRatio = self.ratio(a: data.damageMatrix[playerBottomRight][playerTopLeft], b: data.damageMatrix[playerTopLeft][playerBottomRight])
            
            let bottomRightRatio = self.ratio(a: topLeftOppTotal, b: data.damageMatrix[playerBottomRight][playerTopLeft])
            
            let topRightRatio = self.ratio (a: data.damageMatrix[playerBottomLeft][playerTopRight], b: data.damageMatrix[playerTopRight][playerBottomLeft])
            
            let bottomLeftRatio = self.ratio(a: data.damageMatrix[playerTopRight][playerBottomLeft], b: data.damageMatrix[playerBottomLeft][playerTopRight] )
            
            // Diamond points — keep original intent: near the partition walls, proportional to damage
            // Note: a few formulas reworked to use the partition points we computed
            // diamondTop lies somewhere along the top-partition vertical (x = topPoint.x)
            // We'll compute using mixing of y between topPoint.y and leftPoint.y/rightPoint.y — keep proportions simple.
            let diamondTop = CGPoint(x: topPoint.x,
                                     y: topPoint.y + (leftPoint.y - topPoint.y) * topRightRatio) // an interpolation - preserves relative behavior
            
            let diamondLeft = CGPoint(x: leftPoint.x + (bottomPoint.x - leftPoint.x) * topLeftRatio,
                                      y: leftPoint.y)
            
            let diamondBottom = CGPoint(x: bottomPoint.x,
                                        y: bottomPoint.y - (bottomPoint.y - leftPoint.y) * bottomLeftRatio)
            
            let diamondRight = CGPoint(x: rightPoint.x - (rightPoint.x - topPoint.x) * bottomRightRatio,
                                       y: rightPoint.y)
            
            var diamond = Path()
            diamond.move(to: diamondTop)
            diamond.addLine(to: diamondRight)
            diamond.addLine(to: diamondBottom)
            diamond.addLine(to: diamondLeft)
            diamond.closeSubpath()
            
            context.stroke(diamond, with: .color(.black), lineWidth: 2)
            
            // Helper to fill triangular corner regions. Corners are:
            // top-left (rect.origin .. topPoint .. diamondTop .. diamondLeft .. leftPoint)
            // top-right, bottom-right, bottom-left accordingly.
            func fillRegion(_ points: [CGPoint], color: Color) {
                var path = Path()
                guard let first = points.first else { return }
                path.move(to: first)
                for p in points.dropFirst() {
                    path.addLine(to: p)
                }
                path.closeSubpath()
                context.fill(path, with: .color(color))
                context.stroke(path, with: .color(.black), lineWidth: 2)
            }
            
            // Determine color and self-damage opacity per player at each corner:
            // cornerPositions: 0 = top-left, 1 = top-right, 2 = bottom-right, 3 = bottom-left
            let cornerPlayers = [ player(atPosition: 0), player(atPosition: 1), player(atPosition: 2), player(atPosition: 3) ]
            
            // Build and fill regions using the same geometry as earlier but with corrected player references
            // Top-left region
            fillRegion([CGPoint(x: rect.minX, y: rect.minY), topPoint, diamondTop, diamondLeft, leftPoint],
                       color: getColor(for: cornerPlayers[0]).opacity((21 - data.damageMatrix[cornerPlayers[0]][cornerPlayers[0]]) / 21))
            
            // Top-right region
            fillRegion([CGPoint(x: rect.maxX, y: rect.minY), rightPoint, diamondRight, diamondTop, topPoint],
                       color: getColor(for: cornerPlayers[1]).opacity((21 - data.damageMatrix[cornerPlayers[1]][cornerPlayers[1]]) / 21))
            
            // Bottom-right region
            fillRegion([CGPoint(x: rect.maxX, y: rect.maxY), bottomPoint, diamondBottom, diamondRight, rightPoint],
                       color: getColor(for: cornerPlayers[2]).opacity((21 - data.damageMatrix[cornerPlayers[2]][cornerPlayers[2]]) / 21))
            
            // Bottom-left region
            fillRegion([CGPoint(x: rect.minX, y: rect.maxY), leftPoint, diamondLeft, diamondBottom, bottomPoint],
                       color: getColor(for: cornerPlayers[3]).opacity((21 - data.damageMatrix[cornerPlayers[3]][cornerPlayers[3]]) / 21))
            
            // Compute midpoints along diamond edges for drawing diagonal labels
            let topLeadingMidLBL = midpoint( topPoint, leftPoint, 0.5 )
            let topLeadingMid = midpoint(diamondTop, diamondLeft )  // edge between top and left corners
            let topTrailingMidLBL = midpoint( topPoint, rightPoint, 0.5 )
            let topTrailingMid = midpoint(diamondTop, diamondRight)  // edge between top and right corners
            let bottomLeadingMidLBL = midpoint(bottomPoint, leftPoint, 0.5 )
            let bottomLeadingMid = midpoint(diamondBottom, diamondLeft)
            let bottomTrailingMidLBL = midpoint(bottomPoint, rightPoint, 0.5 )
            let bottomTrailingMid = midpoint(diamondBottom, diamondRight)
            
            // Helper to draw label on canvas with a white backdrop for readability
            func drawLabel(_ context: inout GraphicsContext, text: String, at point: CGPoint, color: Color = .black) {
                
                let bgRadius = max(0.0, min(w, h) * 0.07)
                let bgRect = CGRect(x: point.x - bgRadius, y: point.y - bgRadius, width: bgRadius*2, height: bgRadius*2)
                context.fill(Path(roundedRect: bgRect, cornerSize: CGSize(width: bgRadius*0.35, height: bgRadius*0.35)), with: .color(.white.opacity(0.9)))
                let resolved = Text(text).font(.caption).fontWeight(.bold).foregroundStyle(color)
                
                context.draw(resolved, at: point)
                
                /*
                // draw white rounded rect behind text to emulate stroke/background
                let resolvedText = Text(text)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
                
                // measure bounding box to place a small background rectangle
                let resolvedTextForBG = Text(text)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.white)
                
                // First draw the white text to give contrast (similar to your previous approach)
                context.draw(resolvedTextForBG, at: point)
                // then draw colored text
                context.draw(resolvedText, at: point)
                */
            }
            
            // Diagonal / internal edge labels: ensure attacker color is used for each number.
            // Edge topLeadingMid sits along edge between top-left (position 0) and top-left's adjacent left or top?
            // We'll map them to interactions between opposite corners (top-left <-> bottom-right) and (top-right <-> bottom-left).
            
            // For the diagonal joining top-left <-> bottom-right:
            // topLeadingMid is on the top-left side of diamond -> we'll show damage from top-left -> bottom-right here
            let tl = playerTopLeft
            let br = playerBottomRight
            drawLabel(&context, text: "\(Int(data.damageMatrix[tl][br]))", at: topLeadingMidLBL, color: getColor(for: tl))
            // and the reverse (bottom-right -> top-left) on the opposite diamond edge
            drawLabel(&context, text: "\(Int(data.damageMatrix[br][tl]))", at: bottomTrailingMidLBL, color: getColor(for: br))
            
            // For the diagonal joining top-right <-> bottom-left:
            let tr = playerTopRight
            let bl = playerBottomLeft
            drawLabel(&context, text: "\(Int(data.damageMatrix[tr][bl]))", at: topTrailingMidLBL, color: getColor(for: tr))
            drawLabel(&context, text: "\(Int(data.damageMatrix[bl][tr]))", at: bottomLeadingMidLBL, color: getColor(for: bl))
            
            // (Optional) internal partition guide lines useful for debugging; left commented
            /*
             var walls = Path()
             walls.move(to: topPoint); walls.addLine(to: CGPoint(x: topPoint.x, y: bottomPoint.y))
             walls.move(to: bottomPoint); walls.addLine(to: CGPoint(x: bottomPoint.x, y: topPoint.y))
             walls.move(to: leftPoint); walls.addLine(to: CGPoint(x: rightPoint.x, y: leftPoint.y))
             walls.move(to: rightPoint); walls.addLine(to: CGPoint(x: leftPoint.x, y: rightPoint.y))
             context.stroke(walls, with: .color(.red), lineWidth: 1)
             */
        }
    }
    private func ratio(a: Double, b: Double) -> Double {

        switch (a, b) {
        case (0,0):  return 0.500
        case (1,0):  return 0.666 /// 2 / (2 +1)
        case (0,1):  return 0.333 /// 1 / (1 + 2)
        case (1,1):  return 0.5 /// 1 / (1 + 2)
        default:
            if a == 0 {return  Double(1) / (1+Double(b))  }
            if b == 0 {return Double(a) / (Double(a)+1) }
            return  Double(a) / (Double(a)+Double(b))
        }
    }
}


/// example matix for players A, B, C, D.
/// notation is: damage FROM player A ONTO player b =  Ab
/// the diagonal is the self interaction
///
/// matrix  = [[ Aa, Ab, Ac, Ad], [Ba, Bb, Bc, Bd], [Ca, Cb, Cc, Cd], [Da, Db, Dc, Dd]]
/// colors = [.green, .orange, .blue, .purple]
/// assume that getColor(for: _ ) =  colors[ _ ]

struct CommanderCompanionCube_Previews: PreviewProvider {
    static var previews: some View {
        
        /// Example where player 0 (green) should be bottom-left
        let damage: [[Double]] = [
            [0, 4, 0, 0], // player 0 (green)
            [2, 0, 0, 1],  // player 1 (orange)
            [0, 0, 0, 2],  // player 2 (blue)
            [1, 0, 0, 0]   // player 3 (purple)
        ]
        
        let chartData = PlayerChartData(damageMatrix: damage)
        
        VStack {
            CommanderCompanionCube(data: chartData)
                .border(.red)
                .frame(width: 100, height: 100)
                .padding()
            
            CommanderCompanionCube(data: chartData)
                .frame(width: 200, height: 200)
                .padding()
        }
    }
}
