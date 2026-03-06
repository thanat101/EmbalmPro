import SwiftUI
import UIKit

// MARK: - Case Log View Model
@MainActor
class CaseLogViewModel: ObservableObject {
    @Published var reports: [CaseLogReport] = []
    @Published var isLoading = false

    func loadReports() {
        isLoading = true
        reports = DatabaseManager.shared.fetchAllCaseLogReports()
        isLoading = false
    }

    func deleteReport(_ report: CaseLogReport) {
        _ = DatabaseManager.shared.deleteCaseLogReport(id: report.id)
        loadReports()
    }
}

// MARK: - Case Log List View
struct CaseLogView: View {
    @StateObject private var viewModel = CaseLogViewModel()
    @State private var showingNewReport = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.reports.isEmpty {
                emptyState
            } else {
                listContent
            }
        }
        .navigationTitle("Case Log")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: CaseLogReport.self) { report in
            CaseLogDetailView(report: report) {
                viewModel.loadReports()
            }
        }
        .sheet(isPresented: $showingNewReport) {
            NavigationStack {
                CaseLogDetailView(report: nil) {
                    viewModel.loadReports()
                    showingNewReport = false
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewReport = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    CaseLogPrintPDF.print(reports: viewModel.reports)
                } label: {
                    Label("Print", systemImage: "printer")
                }
                .disabled(viewModel.reports.isEmpty)
            }
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    CaseLogPrintPDF.saveAsPDF(reports: viewModel.reports)
                } label: {
                    Label("Save as PDF", systemImage: "square.and.arrow.down")
                }
                .disabled(viewModel.reports.isEmpty)
            }
        }
        .onAppear {
            viewModel.loadReports()
        }
    }

    private func dateAndPlaceLine(for report: CaseLogReport) -> String {
        let date = report.listSubtitle
        let place = report.placeOfDeath.trimmingCharacters(in: .whitespacesAndNewlines)
        if place.isEmpty { return date }
        return "\(date) · \(place)"
    }

    private var emptyState: some View {
        VStack(spacing: AppStyle.Spacing.medium) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(AppStyle.secondaryTextColor)
            Text("No case logs yet")
                .font(AppStyle.Typography.headline)
                .foregroundColor(AppStyle.textColor)
            Text("Tap + to add an Embalmer's Report")
                .font(AppStyle.Typography.subheadline)
                .foregroundColor(AppStyle.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var listContent: some View {
        List {
            ForEach(viewModel.reports) { report in
                NavigationLink(value: report) {
                    VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
                        HStack {
                            Text(report.listTitle)
                                .font(AppStyle.Typography.headline)
                                .foregroundColor(AppStyle.textColor)
                            Spacer()
                            if report.caseNumber > 0 {
                                Text("\(report.caseNumber)")
                                    .font(AppStyle.Typography.caption)
                                    .foregroundColor(AppStyle.secondaryTextColor)
                            }
                        }
                        Text(dateAndPlaceLine(for: report))
                            .font(AppStyle.Typography.subheadline)
                            .foregroundColor(AppStyle.secondaryTextColor)
                        if !report.listConditionSummary.isEmpty {
                            Text(report.listConditionSummary)
                                .font(AppStyle.Typography.subheadline)
                                .foregroundColor(AppStyle.textColor)
                                .lineLimit(2)
                        }
                    }
                    .padding(.vertical, AppStyle.Spacing.small)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .padding(.vertical, 4)
            }
            .onDelete { indexSet in
                for index in indexSet where index < viewModel.reports.count {
                    viewModel.deleteReport(viewModel.reports[index])
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Print / PDF helpers (full report content; shared with CaseLogDetailView)
enum CaseLogPrintPDF {
    private static func row(_ label: String, _ value: String) -> String {
        let v = value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "—" : value.htmlEscaped
        return "<tr><td class=\"label\">\(label.htmlEscaped)</td><td>\(v)</td></tr>"
    }

    private static func bodyImageDataURL(named name: String) -> String {
        guard let img = UIImage(named: name), let data = img.pngData() else { return "" }
        return "data:image/png;base64,\(data.base64EncodedString())"
    }

    private static func bodyOutlinesHTML(report: CaseLogReport, conditionWhenReceived: String, frontBase64: String, backBase64: String) -> String {
        let marks = CaseLogReport.decodeBodyMarks(report.bodyMarks)
        let frontMarks = marks.filter { $0.side == "front" }
        let backMarks = marks.filter { $0.side == "back" }
        let markDiv: (BodyMark) -> String = { m in
            "<div class=\"body-mark\" style=\"left:\(m.x * 100)%;top:\(m.y * 100)%;\">\(m.number)</div>"
        }
        let frontMarkDivs = frontMarks.map(markDiv).joined()
        let backMarkDivs = backMarks.map(markDiv).joined()
        let frontImg = frontBase64.isEmpty ? "" : "<div class=\"body-image-wrap\"><img src=\"\(frontBase64)\" class=\"body-img\" alt=\"Body front\"/>\(frontMarkDivs)</div>"
        let backImg = backBase64.isEmpty ? "" : "<div class=\"body-image-wrap\"><img src=\"\(backBase64)\" class=\"body-img\" alt=\"Body back\"/>\(backMarkDivs)</div>"
        let conditionText = conditionWhenReceived.trimmingCharacters(in: .whitespacesAndNewlines)
        let conditionBlock = conditionText.isEmpty ? "" : "<div class=\"condition-block\"><h3>Condition when received</h3><p class=\"condition-text\">\(conditionText.htmlEscaped)</p></div>"
        return """
        <div class="body-outlines">
        \(conditionBlock)
        <div class="body-drawings">
        <h3>Body – front</h3>
        \(frontImg)
        <h3>Body – back</h3>
        \(backImg)
        </div>
        </div>
        """
    }

    /// One full report as HTML: page 1 = all form fields; page 2 = condition when received + body front & back.
    static func fullReportHTML(for report: CaseLogReport, bodyFrontBase64: String, bodyBackBase64: String) -> String {
        let bodySection = bodyOutlinesHTML(report: report, conditionWhenReceived: report.conditionOfRemainsWhenReceived, frontBase64: bodyFrontBase64, backBase64: bodyBackBase64)
        return """
        <div class="report-block">
        <div class="report-page">
        <h2>\(report.listTitle.htmlEscaped)</h2>
        <p class="subtitle">\(report.listSubtitle.htmlEscaped)</p>
        <table class="section"><tbody>
        <tr><th colspan="2">Decedent & death</th></tr>
        \(row("Decedent name", report.decedentName))
        \(row("Gender", report.gender))
        \(row("Age", report.age))
        \(row("Race", report.race))
        \(row("Date of death", report.dateOfDeath))
        \(row("Place of death", report.placeOfDeath))
        <tr><th colspan="2">Facility & embalmer</th></tr>
        \(row("Facility name", report.facilityName))
        \(row("Embalmer name", report.embalmerName))
        \(row("Embalming date", report.dateOfEmbalming))
        \(row("Embalming time / finish", report.embalmingTimeFinish))
        <tr><th colspan="2">Body & condition</th></tr>
        \(row("Body weight", report.bodyWeight))
        \(row("Body type", report.bodyType))
        \(row("Condition / case type summary", report.conditionSummary))
        <tr><th colspan="2">Fluids & solution</th></tr>
        \(row("Arterial fluid used", report.arterialFluidUsed))
        \(row("Co-injection", report.coInjection))
        \(row("Cavity chemical", report.cavityChemical))
        \(row("Solution details", report.solutionDetails))
        \(row("Disinfectant", report.disinfectant))
        <tr><th colspan="2">Closure & technique</th></tr>
        \(row("Mouth closure", report.mouthClosure))
        \(row("Eye closure", report.eyeClosure))
        \(row("Arteries injected", report.arteriesInjected))
        \(row("Veins drained", report.veinsDrained))
        \(row("Drainage method", report.drainageMethod))
        \(row("Aspiration", report.aspiration))
        <tr><th colspan="2">After embalming & notes</th></tr>
        \(row("Condition after embalming", report.conditionAfterEmbalming))
        \(row("Embalmer notes", report.notes))
        </tbody></table>
        </div>
        \(bodySection)
        </div>
        """
    }

    static func html(for reports: [CaseLogReport]) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let generated = dateFormatter.string(from: Date())
        let frontB64 = bodyImageDataURL(named: "BodyFront")
        let backB64 = bodyImageDataURL(named: "BodyBack")
        let reportsBody = reports.map { r in
            "<div class=\"case-break\">\(fullReportHTML(for: r, bodyFrontBase64: frontB64, bodyBackBase64: backB64))</div>"
        }.joined()
        return """
        <!DOCTYPE html><html><head><meta charset="utf-8"><style>
        body { font-family: -apple-system, sans-serif; padding: 12px; margin: 0; font-size: 9pt; }
        .case-break { page-break-after: always; }
        .case-break:last-child { page-break-after: auto; }
        .report-page { margin-bottom: 0; page-break-after: always; page-break-inside: avoid; }
        .report-page h2 { font-size: 12pt; margin: 0 0 2px 0; }
        .subtitle { color: #666; margin: 0 0 8px 0; font-size: 9pt; }
        table.section { width: 100%; border-collapse: collapse; margin-bottom: 8px; font-size: 9pt; }
        table.section th { text-align: left; padding: 3px 6px; background: #f0f0f0; font-size: 9pt; }
        table.section td { padding: 2px 6px; border-bottom: 1px solid #eee; vertical-align: top; }
        table.section td.label { width: 38%; color: #555; }
        table.section tr { page-break-inside: avoid; }
        .body-outlines { page-break-inside: avoid; padding-top: 4px; }
        .condition-block { margin-bottom: 10px; }
        .condition-block h3 { font-size: 10pt; margin: 0 0 4px 0; }
        .condition-text { margin: 0; font-size: 9pt; white-space: pre-wrap; }
        .body-drawings { margin-top: 8px; }
        .body-outlines h3 { font-size: 10pt; margin: 8px 0 4px 0; }
        .body-image-wrap { position: relative; display: inline-block; margin: 4px 12px 12px 0; page-break-inside: avoid; }
        .body-img { display: block; width: 180px; height: auto; }
        .body-mark { position: absolute; transform: translate(-50%,-50%); width: 22px; height: 22px; border-radius: 11px; background: rgba(255,165,0,0.65); text-align: center; line-height: 22px; font-size: 10px; font-weight: bold; }
        @page { size: letter; margin: 1in; }
        @media print {
            body { padding: 1in; margin: 0; }
            .case-break { page-break-after: always; }
            .case-break:last-child { page-break-after: auto; }
            .report-page { page-break-after: always; page-break-inside: avoid; }
            .body-outlines { page-break-inside: avoid; }
        }
        </style></head><body>
        <h1 style="font-size:14pt;margin:0 0 4px 0;">Case Log / Embalmer's Reports</h1>
        <p class="meta" style="color:#666;margin:0 0 4px 0;font-size:9pt;">Generated \(generated) · \(reports.count) report(s)</p>
        <p class="print-tip" style="color:#888;margin:0 0 12px 0;font-size:8pt;">If content is cut off, use your printer's &quot;Fit to page&quot; or &quot;Shrink to fit&quot; option.</p>
        \(reportsBody)
        </body></html>
        """
    }

    /// Renders reports to PDF: 2 pages per case (form, then condition + body drawings side-by-side). 1" margins.
    static func renderToPDFData(reports: [CaseLogReport]) -> Data? {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 72
        let contentWidth = pageWidth - margin * 2
        let contentHeight = pageHeight - margin * 2
        let paperRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let contentRect = CGRect(x: margin, y: margin, width: contentWidth, height: contentHeight)

        let titleFont = UIFont.boldSystemFont(ofSize: 11)
        let sectionFont = UIFont.boldSystemFont(ofSize: 9)
        let rowFont = UIFont.systemFont(ofSize: 8)
        let rowLineHeight: CGFloat = 10
        let sectionLineHeight: CGFloat = 11
        let labelSuffix = ":  "  // colon then 2 spaces

        func val(_ s: String) -> String {
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? "—" : t
        }

        let rowAttrs: [NSAttributedString.Key: Any] = [.font: rowFont, .foregroundColor: UIColor.black]
        let labelAttrs: [NSAttributedString.Key: Any] = [.font: rowFont, .foregroundColor: UIColor.darkGray]

        let renderer = UIGraphicsPDFRenderer(bounds: paperRect)
        let tipFont = UIFont.systemFont(ofSize: 7)
        let data = renderer.pdfData { ctx in
            var isFirstPage = true
            for report in reports {
                ctx.beginPage(withBounds: paperRect, pageInfo: [:])
                var y = contentRect.minY

                // Page 1: "Embalmer's Report" (left), "Case Number" (right)
                ("Embalmer's Report" as NSString).draw(at: CGPoint(x: contentRect.minX, y: y), withAttributes: [.font: titleFont])
                let caseNumStr = report.caseNumber > 0 ? "Case Number \(report.caseNumber)" : "Case Number \(val(String(report.id.prefix(8))))"
                (caseNumStr as NSString).draw(at: CGPoint(x: contentRect.maxX - (caseNumStr as NSString).size(withAttributes: [.font: rowFont]).width, y: y + 1), withAttributes: [.font: rowFont, .foregroundColor: UIColor.darkGray])
                y += titleFont.lineHeight + 4

                func wrapHeight(_ str: String, width: CGFloat) -> CGFloat {
                    let s = val(str)
                    guard !s.isEmpty else { return rowLineHeight }
                    let b = (s as NSString).boundingRect(with: CGSize(width: width, height: 800), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: rowAttrs, context: nil)
                    return max(rowLineHeight, ceil(b.height))
                }

                func drawSection(_ title: String) {
                    guard y + sectionLineHeight <= contentRect.maxY else { return }
                    (title as NSString).draw(at: CGPoint(x: contentRect.minX, y: y), withAttributes: [.font: sectionFont, .foregroundColor: UIColor.darkGray])
                    y += sectionLineHeight
                }
                /// One field per row: "Label:  " then value (wraps to multiple lines as needed).
                func drawRow(label: String, value: String) {
                    let labelText = val(label) + labelSuffix
                    let valueStr = val(value)
                    let labelW = (labelText as NSString).size(withAttributes: labelAttrs).width
                    let valueW = contentRect.maxX - (contentRect.minX + labelW)
                    let valueH = wrapHeight(value, width: valueW)
                    guard y + valueH <= contentRect.maxY else { return }
                    (labelText as NSString).draw(at: CGPoint(x: contentRect.minX, y: y), withAttributes: labelAttrs)
                    (valueStr as NSString).draw(in: CGRect(x: contentRect.minX + labelW, y: y, width: valueW, height: valueH), withAttributes: rowAttrs)
                    y += valueH + 1
                }

                // 1. Facility & embalmer
                drawSection("Facility & embalmer:")
                drawRow(label: "Facility name", value: report.facilityName)
                drawRow(label: "Embalmer name", value: report.embalmerName)
                drawRow(label: "Embalming date", value: report.dateOfEmbalming)
                drawRow(label: "Embalming time / finish", value: report.embalmingTimeFinish)
                y += 2

                // 2. Decedent & death
                drawSection("Decedent & death:")
                drawRow(label: "Decedent name", value: report.decedentName)
                drawRow(label: "Gender", value: report.gender)
                drawRow(label: "Age", value: report.age)
                drawRow(label: "Race", value: report.race)
                drawRow(label: "Date of death", value: report.dateOfDeath)
                drawRow(label: "Place of death", value: report.placeOfDeath)
                drawRow(label: "Body weight", value: report.bodyWeight)
                drawRow(label: "Body type", value: report.bodyType)
                drawRow(label: "Condition / case type summary", value: report.conditionSummary)
                y += 2

                // 3. Fluids & solution
                drawSection("Fluids & solution:")
                drawRow(label: "Arterial fluid used", value: report.arterialFluidUsed)
                drawRow(label: "Co-injection", value: report.coInjection)
                drawRow(label: "Cavity chemical", value: report.cavityChemical)
                drawRow(label: "Solution details", value: report.solutionDetails)
                drawRow(label: "Disinfectant", value: report.disinfectant)
                y += 2

                // 4. Closure & technique
                drawSection("Closure & technique:")
                drawRow(label: "Mouth closure", value: report.mouthClosure)
                drawRow(label: "Eye closure", value: report.eyeClosure)
                drawRow(label: "Arteries injected", value: report.arteriesInjected)
                drawRow(label: "Veins drained", value: report.veinsDrained)
                drawRow(label: "Aspiration", value: report.aspiration)
                drawRow(label: "Drainage method", value: report.drainageMethod)
                y += 2

                // 5. After embalming & notes (multiline fields)
                drawSection("After embalming & notes:")
                drawRow(label: "Condition after embalming", value: report.conditionAfterEmbalming)
                drawRow(label: "Embalmer notes", value: report.notes)

                if isFirstPage {
                    ("If content is cut off, use your printer's \"Fit to page\" or \"Shrink to fit\" option." as NSString).draw(at: CGPoint(x: contentRect.minX, y: pageHeight - margin - 14), withAttributes: [.font: tipFont, .foregroundColor: UIColor.gray])
                    isFirstPage = false
                }

                // ——— Page 2: Condition when received + body front & back (side-by-side) ———
                ctx.beginPage(withBounds: paperRect, pageInfo: [:])
                y = contentRect.minY
                let page2HeaderFont = UIFont.systemFont(ofSize: 7)
                let page2Header = "\(val(report.decedentName)) · \(val(report.dateOfDeath))"
                (page2Header as NSString).draw(at: CGPoint(x: contentRect.minX, y: y), withAttributes: [.font: page2HeaderFont, .foregroundColor: UIColor.gray])
                y += page2HeaderFont.lineHeight + 4
                ("Condition when received:" as NSString).draw(at: CGPoint(x: contentRect.minX, y: y), withAttributes: [.font: sectionFont])
                y += sectionLineHeight + 2
                let conditionText = val(report.conditionOfRemainsWhenReceived)
                if !conditionText.isEmpty {
                    let condRect = CGRect(x: contentRect.minX, y: y, width: contentWidth, height: 80)
                    (conditionText as NSString).draw(in: condRect, withAttributes: [.font: rowFont])
                    y += 84
                } else {
                    y += 4
                }

                let marks = CaseLogReport.decodeBodyMarks(report.bodyMarks)
                guard let frontImg = UIImage(named: "BodyFront"), let backImg = UIImage(named: "BodyBack") else {
                    y += 20
                    continue
                }
                let frontAspect = frontImg.size.width / frontImg.size.height
                let backAspect = backImg.size.width / backImg.size.height
                let bodyLabelHeight: CGFloat = 14
                let spaceForBodies = contentRect.maxY - y - bodyLabelHeight
                let colGap: CGFloat = 20
                let halfWidth = (contentWidth - colGap) / 2
                let frontHeight = min(halfWidth / frontAspect, spaceForBodies)
                let frontWidth = frontHeight * frontAspect
                let backHeight = min(halfWidth / backAspect, spaceForBodies)
                let backWidth = backHeight * backAspect
                let leftColX = contentRect.minX
                let rightColX = contentRect.minX + halfWidth + colGap
                let frontRect = CGRect(x: leftColX, y: y, width: frontWidth, height: frontHeight)
                let backRect = CGRect(x: rightColX, y: y, width: backWidth, height: backHeight)
                ("Body – front" as NSString).draw(at: CGPoint(x: leftColX, y: y - 2), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 9)])
                frontImg.draw(in: frontRect)
                for m in marks where m.side == "front" {
                    let mx = frontRect.minX + CGFloat(m.x) * frontRect.width
                    let my = frontRect.minY + CGFloat(m.y) * frontRect.height
                    let circleRect = CGRect(x: mx - 11, y: my - 11, width: 22, height: 22)
                    UIColor.orange.withAlphaComponent(0.65).setFill()
                    UIBezierPath(ovalIn: circleRect).fill()
                    ("\(m.number)" as NSString).draw(at: CGPoint(x: mx - 5, y: my - 7), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 10)])
                }
                ("Body – back" as NSString).draw(at: CGPoint(x: rightColX, y: y - 2), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 9)])
                backImg.draw(in: backRect)
                for m in marks where m.side == "back" {
                    let mx = backRect.minX + CGFloat(m.x) * backRect.width
                    let my = backRect.minY + CGFloat(m.y) * backRect.height
                    let circleRect = CGRect(x: mx - 11, y: my - 11, width: 22, height: 22)
                    UIColor.orange.withAlphaComponent(0.65).setFill()
                    UIBezierPath(ovalIn: circleRect).fill()
                    ("\(m.number)" as NSString).draw(at: CGPoint(x: mx - 5, y: my - 7), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 10)])
                }
            }
        }
        return data
    }

    static func print(reports: [CaseLogReport]) {
        guard !reports.isEmpty, topViewController() != nil else { return }
        guard let pdfData = renderToPDFData(reports: reports) else { return }
        let printController = UIPrintInteractionController.shared
        printController.printingItem = pdfData
        printController.present(animated: true)
    }

    static func saveAsPDF(reports: [CaseLogReport]) {
        guard !reports.isEmpty, let vc = topViewController() else { return }
        guard let pdfData = renderToPDFData(reports: reports) else { return }
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("CaseLog_\(Date().timeIntervalSince1970).pdf")
        do {
            try pdfData.write(to: tempURL)
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            if let pop = activityVC.popoverPresentationController {
                pop.sourceView = vc.view
                pop.sourceRect = CGRect(x: vc.view.bounds.midX, y: vc.view.bounds.midY, width: 0, height: 0)
                pop.permittedArrowDirections = []
            }
            vc.present(activityVC, animated: true)
        } catch {
            Swift.print("PDF write failed: \(error)")
        }
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        guard let window = scene?.windows.first(where: { $0.isKeyWindow }) else { return nil }
        var vc = window.rootViewController
        while let presented = vc?.presentedViewController { vc = presented }
        return vc
    }
}

private extension String {
    var htmlEscaped: String {
        self
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}

#Preview {
    NavigationStack {
        CaseLogView()
    }
}
