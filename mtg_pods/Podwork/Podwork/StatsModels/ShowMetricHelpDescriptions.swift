
let helpJson = """
{
  "metrics_help": [
    {
      "title": "Turn Impact Score (TIP)",
      "subtitle": "How Much Did This Turn Change the Game?",
      "body": "Turn Impact Score measures how much raw damage a player dealt on their turn, including combat, commander, and partner damage. Higher scores indicate explosive or decisive moments.\\n\\nIt is normalized across the whole game:\\n\\n$TIP_t = \\\\frac{\\\\text{Damage}_t}{\\\\sum_{i=1}^{n} \\\\text{Damage}_i}$"
    },
    {
      "title": "Damage Entropy",
      "subtitle": "Sniper or Sweeper?",
      "body": "Damage Entropy measures how focused or spread a player’s damage is across opponents.\\n\\n- Low entropy (closer to 0): Player focused on a single target.\\n- High entropy (closer to 1): Damage spread across all opponents.\\n\\nCalculated using Shannon entropy:\\n\\n$H_t = -\\\\sum p_i \\\\log_2(p_i)$\\n\\nNormalized by max entropy for 3 targets:\\n\\n$\\\\text{NormalizedEntropy}_t = \\\\frac{H_t}{\\\\log_2(3)}$"
    },
    {
      "title": "Commander Cast Detection",
      "subtitle": "Track When Commanders Hit the Field",
      "body": "We infer whether a commander was cast on a turn by comparing the increase in commander tax. If it rises by 2 or more, we assume a cast occurred.\\n\\nThis helps flag tempo shifts and identifies when players are re-establishing board presence."
    },
    {
      "title": "Turn Duration",
      "subtitle": "Time Management Per Turn",
      "body": "Tracks how long each player spends on their turn. Can reveal pacing issues or highlight overthinkers.\\n\\nUseful to visualize player flow and help identify points of friction.\\n\\nNote: Results may be skewed if players forget to end their turn."
    },
    {
      "title": "Kill Detection",
      "subtitle": "Spot the Eliminations",
      "body": "If a player's life total drops from above 0 to 0 or below during a turn, that turn is flagged as an elimination turn.\\n\\nThese turns are often high-impact and can indicate critical power plays."
    }
  ]
}
"""


import SwiftUI
import WebKit

struct MetricHelp: Codable, Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let body: String
}

struct MetricsHelpPage: Codable {
    let metrics_help: [MetricHelp]
}

func loadHelp() -> [MetricHelp] {
    let data = Data(helpJson.utf8)
    if let decoded = try? JSONDecoder().decode(MetricsHelpPage.self, from: data) {
        return decoded.metrics_help
    }
    return []
}


struct MathJaxView: UIViewRepresentable {
    let latexString: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .clear
        webView.isOpaque = false
        return webView
    }
    
    //https://cdn.jsdelivr.net/npm/mathjax@3.2.2/es5/tex-mml-svg.js
    //https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js
    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = """
        <html>
        <head>
        <script src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
        <style> body { font-family: -apple-system; font-size: 47px; padding: 10px; background: transparent; } </style>
        </head>
        <body>
        \(latexString)
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}


struct MetricHelpView: View {
    let metric: MetricHelp
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(metric.title)
                .font(.title2)
                .bold()
                .foregroundColor(.blue)
            Text(metric.subtitle)
                .font(.headline)
                .foregroundColor(.purple)
            
            // Separate body paragraphs and inline math
            // We replace newlines with <br> and convert $...$ blocks to MathJax inline math
            // For simplicity, pass entire body as is to MathJaxView
            MathJaxView(latexString: metric.body
                .replacingOccurrences(of: "\n", with: "<br>")
                .replacingOccurrences(of: "$", with: "$$") )
            .frame(maxHeight: .infinity) // Adjust as needed
        }
        .padding()
    }
}


struct MetricsHelpListView: View {
    let metrics = loadHelp()
    
    var body: some View {
        NavigationView {
            List(metrics) { metric in
                NavigationLink(destination: MetricHelpView(metric: metric)) {
                    VStack(alignment: .leading) {
                        Text(metric.title)
                            .font(.headline)
                        Text(metric.subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Game Metrics Help")
        }
    }
}


#Preview{
    MetricsHelpListView()
}
