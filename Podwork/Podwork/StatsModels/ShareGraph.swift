import SwiftUI
import UniformTypeIdentifiers



public extension View {
    func asImage() -> UIImage {
        let controller = UIHostingController(rootView: self.ignoresSafeArea())
        let view = controller.view
        
        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear
        
        view?.layoutIfNeeded()
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view?.drawHierarchy(in: view!.bounds, afterScreenUpdates: true)
        }
    }
}



extension UIImage: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { image in
            image.pngData() ?? Data()
        }
    }
}




/*
struct DamageGraphView: View {
    var body: some View {
        VStack {
            Text("Turn by Turn Damage")
                .font(.title)
                .padding()
            
            // Example graph placeholder
            Rectangle()
                .fill(Color.red)
                .frame(width: 200, height: 100)
                .overlay(Text("Graph Here").foregroundColor(.white))
        }
        .padding()
        .background(Color.black.opacity(0.05))
    }
}
*/
/*
extension View {
    /// Converts any SwiftUI view into a UIImage
    func snapshot() -> UIImage {
        let controller = UIHostingController(rootView: self)
        let view = controller.view
        
        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view?.drawHierarchy(in: view!.bounds, afterScreenUpdates: true)
        }
    }
}
*/
/*
 
// Example usage: save as PNG or share
func saveGraphImage() {
    let graph = DamageGraphView()
    let image = graph.snapshot()
    
    // Convert to PNG
    if let pngData = image.pngData() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("damageGraph.png")
        try? pngData.write(to: url)
        print("Saved graph at: \(url)")
    }
    
    // Or present share sheet directly
    let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
    UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true, completion: nil)
}

*/

//////////////////////////////
///
///
///




@MainActor
public extension AnyView {
    func snapshot() -> UIImage {
        let controller = UIHostingController(rootView: self)
        let view = controller.view
        
        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view?.drawHierarchy(in: view!.bounds, afterScreenUpdates: true)
        }
    }
}




@MainActor
public extension View {
    func snapshot() -> UIImage {
        let controller = UIHostingController(rootView: self)
        let view = controller.view
        
        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view?.drawHierarchy(in: view!.bounds, afterScreenUpdates: true)
        }
    }
}

struct DamageGraphView: View {
    var body: some View {
        VStack {
            Text("Turn by Turn Damage")
                .font(.title)
                .padding()
            
            // Example graph placeholder
            Rectangle()
                .fill(Color.red)
                .frame(width: 200, height: 100)
                .overlay(Text("Graph Here").foregroundColor(.white))
        }
        .padding()
        .background(Color.black.opacity(0.05))
    }
}

struct ShareGraphView: View {
    var body: some View {
        let image = DamageGraphView().snapshot()
        
        VStack {
            DamageGraphView()
            
            // Share button
            ShareLink(
                item: Image(uiImage: image),
                preview: SharePreview("My Commander Damage Graph", image: Image(uiImage: image))
            ) {
                Label("Share Graph", systemImage: "square.and.arrow.up")
            }
            .padding()
        }
    }
}


#Preview {
    
    ShareGraphView()
}
