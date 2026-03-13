import SwiftUI
import UIKit
import WebKit

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
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text("Embalmer's Report")
                        .font(AppStyle.Typography.headline)
                    if !viewModel.reports.isEmpty {
                        Text("\(viewModel.reports.count) report\(viewModel.reports.count == 1 ? "" : "s")")
                            .font(AppStyle.Typography.caption)
                            .foregroundColor(AppStyle.secondaryTextColor)
                    }
                }
            }
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

    // MARK: - HTML template for print (letter, 2-page design; used with UIPrintPageRenderer)
    private static let embalmerReportHTMLTemplate: String = """
    <!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=612, initial-scale=1.0"><title>Embalmer's Report</title>
    <style>
    @page { size: letter; margin: 1in 0.75in 0.75in 0.75in; }
    body { font-family: Arial, Helvetica, sans-serif; font-size: 11pt; margin: 0; padding: 0; color: #111; background: #fff; line-height: 1.5; }
    .page { width: 100%; min-height: calc(11in - 1in - 0.75in); page-break-after: always; position: relative; }
    .page-inner { padding: 0.5in 0.25in; box-sizing: border-box; }
    .page-footer { position: absolute; bottom: 0.2in; left: 0; right: 0; text-align: center; font-size: 9pt; color: #777; border-top: 1px solid #eee; padding-top: 6px; }
    h1 { text-align: center; font-size: 14pt; font-weight: bold; margin: 0 0 16px 0; color: #222; border-bottom: 2px solid #444; padding-bottom: 8px; }
    .page-header { text-align: center; margin-bottom: 28px; padding-bottom: 12px; border-bottom: 1px solid #ddd; }
    .decedent-info { font-size: 11pt; font-weight: bold; color: #333; }
    h2 { font-size: 12pt; font-weight: bold; margin: 24px 0 10px 0; color: #222; border-bottom: 1px solid #bbb; padding-bottom: 4px; }
    .section { background: #fdfdfd; padding: 14px 16px; border: 1px solid #e8e8e8; border-radius: 6px; margin-bottom: 20px; box-shadow: 0 1px 4px rgba(0,0,0,0.04); }
    .full-width { width: 100%; border-collapse: collapse; margin-bottom: 12px; font-size: 11pt; }
    td { padding: 7px 9px; vertical-align: top; border-bottom: 1px solid #f0f0f0; }
    td.label { width: 32%; font-weight: bold; color: #222; }
    .inline-group { display: flex; flex-wrap: wrap; gap: 24px; margin-bottom: 12px; }
    .inline-item { flex: 1 1 30%; min-width: 220px; }
    .inline-item .label { font-weight: bold; display: block; margin-bottom: 3px; color: #333; }
    .closure-group { display: flex; gap: 32px; margin-bottom: 12px; }
    .closure-item { flex: 1; }
    .body-outlines-row { display: flex; justify-content: space-between; gap: 0.5in; margin: 20px 0 12px 0; }
    .body-placeholder { flex: 1; height: 6in; border: 2px dashed #aaa; background: #fefefe; position: relative; text-align: center; border-radius: 6px; }
    .body-image-wrap { position: relative; display: inline-block; width: 100%; }
    .body-image-wrap img { display: block; width: 100%; height: auto; max-height: 6in; object-fit: contain; }
    .body-mark { position: absolute; transform: translate(-50%,-50%); width: 22px; height: 22px; border-radius: 11px; background: rgba(255,165,0,0.65); text-align: center; line-height: 22px; font-size: 10px; font-weight: bold; }
    .marks-note { font-size: 9.5pt; color: #666; text-align: center; margin-top: 10px; font-style: italic; }
    </style></head><body>
    <div class="page" id="page1">
    <div class="page-inner">
    <h1>Embalmer's Report</h1>
    <div class="section"><h2>Decedent & Death</h2>
    <div class="inline-item" style="margin-bottom:12px;"><span class="label">Decedent Name:</span> [decedentName]</div>
    <div class="inline-group"><div class="inline-item"><span class="label">Gender:</span> [gender]</div><div class="inline-item"><span class="label">Age:</span> [age]</div><div class="inline-item"><span class="label">Race:</span> [race]</div></div>
    <div class="inline-group"><div class="inline-item"><span class="label">Date of Death:</span> [dateOfDeath]</div><div class="inline-item"><span class="label">Place of Death:</span> [placeOfDeath]</div></div>
    </div>
    <div class="section"><h2>Facility & Embalmer</h2>
    <div class="inline-group"><div class="inline-item"><span class="label">Facility Name:</span> [facilityName]</div><div class="inline-item"><span class="label">Embalmer Name:</span> [embalmerName]</div></div>
    <div class="inline-group"><div class="inline-item"><span class="label">Date of Embalming:</span> [dateOfEmbalming]</div><div class="inline-item"><span class="label">Embalming Completed:</span> [embalmingTimeFinish]</div></div>
    </div>
    <div class="section"><h2>Body & Condition</h2>
    <table class="full-width"><tr><td class="label">Body Weight:</td><td>[bodyWeight]</td></tr><tr><td class="label">Body Type / Build:</td><td>[bodyType]</td></tr><tr><td class="label">Condition Summary on Receipt:</td><td>[conditionSummary]</td></tr></table>
    </div>
    <div class="section"><h2>Fluids & Solution</h2>
    <table class="full-width"><tr><td class="label">Arterial Fluid Used:</td><td>[arterialFluidUsed]</td></tr><tr><td class="label">Co-injection / Additives:</td><td>[coInjection]</td></tr><tr><td class="label">Cavity Chemical:</td><td>[cavityChemical]</td></tr><tr><td class="label">Solution Details / Index:</td><td>[solutionDetails]</td></tr><tr><td class="label">Disinfectant / Topical:</td><td>[disinfectant]</td></tr></table>
    </div>
    <div class="section"><h2>Closure & Technique</h2>
    <div class="closure-group"><div class="closure-item"><span class="label">Mouth Closure:</span> [mouthClosure]</div><div class="closure-item"><span class="label">Eye Closure:</span> [eyeClosure]</div></div>
    <table class="full-width"><tr><td class="label">Arteries Injected:</td><td>[arteriesInjected]</td></tr><tr><td class="label">Veins Drained:</td><td>[veinsDrained]</td></tr><tr><td class="label">Drainage Method:</td><td>[drainageMethod]</td></tr><tr><td class="label">Aspiration Performed:</td><td>[aspiration]</td></tr></table>
    </div>
    </div>
    <div class="page-footer">Confidential Embalmer's Report — Page 1 of 2</div>
    </div>
    <div class="page" id="page2">
    <div class="page-inner">
    <div class="page-header"><h1>Embalmer's Report — Continued</h1><p class="decedent-info">Decedent: [decedentName] &nbsp;&nbsp;&nbsp;&nbsp; Date of Death: [dateOfDeath]</p></div>
    <div class="section"><h2>After Embalming & Notes</h2>
    <table class="full-width"><tr><td class="label">Condition After Embalming:</td><td>[conditionAfterEmbalming]</td></tr><tr><td class="label">Additional Notes:</td><td>[notes]</td></tr></table>
    </div>
    <div class="section"><h2>Condition When Received</h2>
    <p style="margin:10px 0 24px 0;min-height:5em;white-space:pre-wrap;">[conditionOfRemainsWhenReceived]</p>
    <div class="body-outlines-row">
    <div style="text-align:center;flex:1;"><h2 style="margin:0 0 8px 0;font-size:12pt;">Body – Front</h2><div class="body-placeholder body-front">[bodyFrontImageWithMarks]</div><div class="marks-note">Front view with numbered marks</div></div>
    <div style="text-align:center;flex:1;"><h2 style="margin:0 0 8px 0;font-size:12pt;">Body – Back</h2><div class="body-placeholder body-back">[bodyBackImageWithMarks]</div><div class="marks-note">Back view with numbered marks</div></div>
    </div>
    </div>
    <div class="page-footer">Confidential Embalmer's Report — Page 2 of 2</div>
    </div>
    </body></html>
    """

    private static func bodyImageWithMarksHTML(report: CaseLogReport, side: String, base64: String) -> String {
        let marks = CaseLogReport.decodeBodyMarks(report.bodyMarks).filter { $0.side == side }
        guard !base64.isEmpty else { return "<span style=\"color:#888;\">No image</span>" }
        let markDivs = marks.map { m in "<div class=\"body-mark\" style=\"left:\(m.x * 100)%;top:\(m.y * 100)%;\">\(m.number)</div>" }.joined()
        return "<div class=\"body-image-wrap\"><img src=\"\(base64)\" alt=\"Body \(side)\"/>\(markDivs)</div>"
    }

    private static func filledHTMLForOneReport(_ report: CaseLogReport, frontBase64: String, backBase64: String) -> String {
        func v(_ s: String) -> String { let t = s.trimmingCharacters(in: .whitespacesAndNewlines); return t.isEmpty ? "—" : t.htmlEscaped }
        let frontBody = bodyImageWithMarksHTML(report: report, side: "front", base64: frontBase64)
        let backBody = bodyImageWithMarksHTML(report: report, side: "back", base64: backBase64)
        return embalmerReportHTMLTemplate
            .replacingOccurrences(of: "[decedentName]", with: v(report.decedentName))
            .replacingOccurrences(of: "[gender]", with: v(report.gender))
            .replacingOccurrences(of: "[age]", with: v(report.age))
            .replacingOccurrences(of: "[race]", with: v(report.race))
            .replacingOccurrences(of: "[dateOfDeath]", with: v(report.dateOfDeath))
            .replacingOccurrences(of: "[placeOfDeath]", with: v(report.placeOfDeath))
            .replacingOccurrences(of: "[facilityName]", with: v(report.facilityName))
            .replacingOccurrences(of: "[embalmerName]", with: v(report.embalmerName))
            .replacingOccurrences(of: "[dateOfEmbalming]", with: v(report.dateOfEmbalming))
            .replacingOccurrences(of: "[embalmingTimeFinish]", with: v(report.embalmingTimeFinish))
            .replacingOccurrences(of: "[bodyWeight]", with: v(report.bodyWeight))
            .replacingOccurrences(of: "[bodyType]", with: v(report.bodyType))
            .replacingOccurrences(of: "[conditionSummary]", with: v(report.conditionSummary))
            .replacingOccurrences(of: "[arterialFluidUsed]", with: v(report.arterialFluidUsed))
            .replacingOccurrences(of: "[coInjection]", with: v(report.coInjection))
            .replacingOccurrences(of: "[cavityChemical]", with: v(report.cavityChemical))
            .replacingOccurrences(of: "[solutionDetails]", with: v(report.solutionDetails))
            .replacingOccurrences(of: "[disinfectant]", with: v(report.disinfectant))
            .replacingOccurrences(of: "[mouthClosure]", with: v(report.mouthClosure))
            .replacingOccurrences(of: "[eyeClosure]", with: v(report.eyeClosure))
            .replacingOccurrences(of: "[arteriesInjected]", with: v(report.arteriesInjected))
            .replacingOccurrences(of: "[veinsDrained]", with: v(report.veinsDrained))
            .replacingOccurrences(of: "[drainageMethod]", with: v(report.drainageMethod))
            .replacingOccurrences(of: "[aspiration]", with: v(report.aspiration))
            .replacingOccurrences(of: "[conditionAfterEmbalming]", with: v(report.conditionAfterEmbalming))
            .replacingOccurrences(of: "[notes]", with: v(report.notes))
            .replacingOccurrences(of: "[conditionOfRemainsWhenReceived]", with: v(report.conditionOfRemainsWhenReceived))
            .replacingOccurrences(of: "[bodyFrontImageWithMarks]", with: frontBody)
            .replacingOccurrences(of: "[bodyBackImageWithMarks]", with: backBody)
    }

    private static func fullHTMLForPrint(reports: [CaseLogReport]) -> String {
        let frontB64 = bodyImageDataURL(named: "BodyFront")
        let backB64 = bodyImageDataURL(named: "BodyBack")
        guard let first = reports.first else { return "" }
        let firstFull = filledHTMLForOneReport(first, frontBase64: frontB64, backBase64: backB64)
        guard let headEnd = firstFull.range(of: "</head>")?.upperBound else { return firstFull }
        let head = String(firstFull[..<headEnd])
        let bodyParts = reports.enumerated().map { index, report in
            let html = filledHTMLForOneReport(report, frontBase64: frontB64, backBase64: backB64)
            guard let bodyStart = html.range(of: "<body>"), let bodyEnd = html.range(of: "</body>", options: .backwards) else { return html }
            let inner = String(html[bodyStart.upperBound..<bodyEnd.lowerBound])
            if index == 0 { return inner }
            return "<div style=\"page-break-before:always\">\(inner)</div>"
        }
        return head + "\n<body>\n\(bodyParts.joined())\n</body>\n</html>"
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

    /// Renders reports to PDF: 2 pages per case (form, then condition + body drawings side-by-side).
    static func renderToPDFData(reports: [CaseLogReport]) -> Data? {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        // Margins: 1" left, 0.75" top/right/bottom
        let marginLeft: CGFloat = 72
        let marginTop: CGFloat = 54
        let marginRight: CGFloat = 54
        let marginBottom: CGFloat = 54
        let contentWidth = pageWidth - marginLeft - marginRight
        let contentHeight = pageHeight - marginTop - marginBottom
        let paperRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let contentRect = CGRect(x: marginLeft, y: marginTop, width: contentWidth, height: contentHeight)

        let titleFont = UIFont.boldSystemFont(ofSize: 14)
        let sectionFont = UIFont.boldSystemFont(ofSize: 12)
        let labelFont = UIFont.systemFont(ofSize: 10)
        let valueFont = UIFont.systemFont(ofSize: 11)
        let rowLineHeight: CGFloat = 14
        let sectionLineHeight: CGFloat = 14
        let labelSuffix = ":  "  // colon then 2 spaces

        func val(_ s: String) -> String {
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? "—" : t
        }

        let rowAttrs: [NSAttributedString.Key: Any] = [.font: valueFont, .foregroundColor: UIColor.black]
        let labelAttrs: [NSAttributedString.Key: Any] = [.font: labelFont, .foregroundColor: UIColor.darkGray]
        let sectionContentIndent: CGFloat = 14

        let renderer = UIGraphicsPDFRenderer(bounds: paperRect)
        let tipFont = UIFont.systemFont(ofSize: 9)
        let data = renderer.pdfData { ctx in
            var isFirstPage = true
            for report in reports {
                ctx.beginPage(withBounds: paperRect, pageInfo: [:])
                var y = contentRect.minY
                // Page 1: centered title "Embalmer's Report"
                let titleString = "Embalmer's Report" as NSString
                let titleSize = titleString.size(withAttributes: [.font: titleFont])
                let titleX = contentRect.minX + (contentWidth - titleSize.width) / 2
                titleString.draw(at: CGPoint(x: titleX, y: y), withAttributes: [.font: titleFont, .foregroundColor: UIColor.black])
                y += titleFont.lineHeight + 8

                func wrapHeight(_ str: String, width: CGFloat) -> CGFloat {
                    let s = val(str)
                    guard !s.isEmpty else { return rowLineHeight }
                    let b = (s as NSString).boundingRect(with: CGSize(width: width, height: 800), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: rowAttrs, context: nil)
                    return max(rowLineHeight, ceil(b.height))
                }

                func drawSection(_ title: String) {
                    guard y + sectionLineHeight <= contentRect.maxY else { return }
                    // Draw section header: light gray background full width (no outer border).
                    let headerHeight = sectionLineHeight + 4
                    let headerRect = CGRect(x: contentRect.minX,
                                            y: y,
                                            width: contentWidth,
                                            height: headerHeight)
                    UIColor(white: 0.95, alpha: 1.0).setFill()
                    UIBezierPath(rect: headerRect).fill()
                    (title as NSString).draw(at: CGPoint(x: headerRect.minX + 8, y: y + 3),
                                             withAttributes: [.font: sectionFont, .foregroundColor: UIColor.darkGray])
                    y += headerHeight
                }
                /// One field per row: "Label:  " then value (wraps to multiple lines as needed).
                func drawRow(label: String, value: String) {
                    let labelText = val(label) + labelSuffix
                    let valueStr = val(value)
                    let labelW = (labelText as NSString).size(withAttributes: labelAttrs).width
                    let x = contentRect.minX + sectionContentIndent
                    let valueW = contentRect.maxX - (x + labelW)
                    let valueH = wrapHeight(value, width: valueW)
                    guard y + valueH <= contentRect.maxY else { return }
                    (labelText as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: labelAttrs)
                    (valueStr as NSString).draw(in: CGRect(x: x + labelW, y: y, width: valueW, height: valueH), withAttributes: rowAttrs)
                    y += valueH + 3
                }
                // Draw two fields on a single line (label1/value1, label2/value2)
                func drawRowPair(label1: String, value1: String, label2: String, value2: String) {
                    let labelText1 = val(label1) + labelSuffix
                    let labelText2 = val(label2) + labelSuffix
                    let labelW1 = (labelText1 as NSString).size(withAttributes: labelAttrs).width
                    let labelW2 = (labelText2 as NSString).size(withAttributes: labelAttrs).width
                    let halfWidth = contentWidth / 2
                    let xBase = contentRect.minX + sectionContentIndent
                    let valueW1 = halfWidth - sectionContentIndent - labelW1 - 4
                    let valueW2 = halfWidth - sectionContentIndent - labelW2 - 4
                    let valueH1 = wrapHeight(value1, width: valueW1)
                    let valueH2 = wrapHeight(value2, width: valueW2)
                    let rowH = max(valueH1, valueH2)
                    guard y + rowH <= contentRect.maxY else { return }

                    // Left field
                    let x1 = xBase
                    (labelText1 as NSString).draw(at: CGPoint(x: x1, y: y), withAttributes: labelAttrs)
                    (val(value1) as NSString).draw(in: CGRect(x: x1 + labelW1,
                                                              y: y,
                                                              width: valueW1,
                                                              height: rowH),
                                                   withAttributes: rowAttrs)

                    // Right field
                    let x2 = contentRect.minX + halfWidth
                    (labelText2 as NSString).draw(at: CGPoint(x: x2, y: y), withAttributes: labelAttrs)
                    (val(value2) as NSString).draw(in: CGRect(x: x2 + labelW2,
                                                              y: y,
                                                              width: valueW2,
                                                              height: rowH),
                                                   withAttributes: rowAttrs)
                    y += rowH + 3
                }

                // Multiline field: title line, then value spanning full width on next line(s)
                func drawMultilineField(title: String, value: String) {
                    let titleText = val(title)
                    let x = contentRect.minX + sectionContentIndent
                    (titleText as NSString).draw(at: CGPoint(x: x, y: y),
                                                 withAttributes: labelAttrs)
                    y += rowLineHeight
                    let v = val(value)
                    let h = wrapHeight(v, width: contentWidth)
                    (v as NSString).draw(in: CGRect(x: x,
                                                    y: y,
                                                    width: contentWidth - sectionContentIndent,
                                                    height: h),
                                         withAttributes: rowAttrs)
                    y += h + 4
                }

                // 1. Decedent & death
                drawSection("Decedent & death")
                // Line 1: Decedent name + Gender
                drawRowPair(label1: "Decedent name", value1: report.decedentName,
                            label2: "Gender", value2: report.gender)
                // Line 2: Age + Race
                drawRowPair(label1: "Age", value1: report.age,
                            label2: "Race", value2: report.race)
                drawRow(label: "Date of death", value: report.dateOfDeath)
                // Line 3: Body weight + Body type
                drawRowPair(label1: "Body weight", value1: report.bodyWeight,
                            label2: "Body type", value2: report.bodyType)
                // Condition summary side-by-side like other fields
                drawRow(label: "Condition / case type summary", value: report.conditionSummary)
                y += 8

                // 2. Facility & embalmer
                drawSection("Facility & embalmer")
                drawRow(label: "Facility name", value: report.facilityName)
                drawRow(label: "Embalmer name", value: report.embalmerName)
                drawRow(label: "Embalming date", value: report.dateOfEmbalming)
                drawRow(label: "Embalming time / finish", value: report.embalmingTimeFinish)
                y += 8

                // 3. Fluids & solution
                drawSection("Fluids & solution")
                drawRow(label: "Arterial fluid used", value: report.arterialFluidUsed)
                drawRow(label: "Co-injection", value: report.coInjection)
                drawRow(label: "Cavity chemical", value: report.cavityChemical)
                drawRow(label: "Solution details", value: report.solutionDetails)
                drawRow(label: "Disinfectant", value: report.disinfectant)
                y += 8

                // 4. Closure & technique
                drawSection("Closure & technique")
                drawRow(label: "Mouth closure", value: report.mouthClosure)
                drawRow(label: "Eye closure", value: report.eyeClosure)
                drawRow(label: "Arteries injected", value: report.arteriesInjected)
                drawRow(label: "Veins drained", value: report.veinsDrained)
                drawRow(label: "Aspiration", value: report.aspiration)
                drawRow(label: "Drainage method", value: report.drainageMethod)
                y += 8

                // 5. After embalming & notes (multiline fields)
                drawSection("After embalming & notes")
                drawMultilineField(title: "Condition after embalming", value: report.conditionAfterEmbalming)
                drawMultilineField(title: "Embalmer notes", value: report.notes)

                if isFirstPage {
                    ("If content is cut off, use your printer's \"Fit to page\" or \"Shrink to fit\" option." as NSString).draw(at: CGPoint(x: contentRect.minX, y: pageHeight - marginBottom - 14), withAttributes: [.font: tipFont, .foregroundColor: UIColor.gray])
                    isFirstPage = false
                }

                // ——— Page 2: Decedent & death summary + condition when received + body front & back ———
                ctx.beginPage(withBounds: paperRect, pageInfo: [:])
                y = contentRect.minY
                // Page 2 title: centered "Embalmer's Report — Continued"
                let page2Title = "Embalmer's Report — Continued" as NSString
                let page2TitleSize = page2Title.size(withAttributes: [.font: titleFont])
                let page2TitleX = contentRect.minX + (contentWidth - page2TitleSize.width) / 2
                page2Title.draw(at: CGPoint(x: page2TitleX, y: y),
                                withAttributes: [.font: titleFont, .foregroundColor: UIColor.black])
                y += titleFont.lineHeight + 4

                // Single header line: Decedent name and date of death on one line under the title
                let headerLine = "Decedent: \(val(report.decedentName))    Date of death: \(val(report.dateOfDeath))" as NSString
                let headerAttrs: [NSAttributedString.Key: Any] = [.font: labelFont, .foregroundColor: UIColor.darkGray]
                headerLine.draw(in: CGRect(x: contentRect.minX,
                                           y: y,
                                           width: contentWidth,
                                           height: rowLineHeight * 2),
                                withAttributes: headerAttrs)
                y += rowLineHeight + 10

                // Condition when received section header with shading
                let condHeaderHeight = sectionLineHeight + 4
                let condHeaderRect = CGRect(x: contentRect.minX,
                                            y: y,
                                            width: contentWidth,
                                            height: condHeaderHeight)
                UIColor(white: 0.95, alpha: 1.0).setFill()
                UIBezierPath(rect: condHeaderRect).fill()
                ("Condition when received" as NSString).draw(at: CGPoint(x: condHeaderRect.minX + 8, y: y + 3),
                                                             withAttributes: [.font: sectionFont, .foregroundColor: UIColor.darkGray])
                y += condHeaderHeight + 2

                let conditionText = val(report.conditionOfRemainsWhenReceived)
                if !conditionText.isEmpty {
                    let condHeight: CGFloat = 90
                    let condRect = CGRect(x: contentRect.minX + sectionContentIndent,
                                          y: y,
                                          width: contentWidth - sectionContentIndent,
                                          height: condHeight)
                    (conditionText as NSString).draw(in: condRect, withAttributes: rowAttrs)
                    y += condHeight + 8
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
                // Make images slightly smaller (reduce available height by ~0.25")
                let spaceForBodies = contentRect.maxY - y - bodyLabelHeight - 18
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
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.jobName = "Embalmer's Report"
        printController.printInfo = printInfo
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

// MARK: - Letter-size print renderer for multi-page PDF from HTML
private final class LetterPrintRenderer: UIPrintPageRenderer {
    private static let pageWidth: CGFloat = 8.5 * 72
    private static let pageHeight: CGFloat = 11 * 72
    override var paperRect: CGRect { CGRect(origin: .zero, size: CGSize(width: Self.pageWidth, height: Self.pageHeight)) }
    override var printableRect: CGRect { paperRect }
}

// MARK: - Load HTML in WKWebView, then generate multi-page PDF via UIPrintPageRenderer
private final class WebViewPrintPDFLoader: NSObject, WKNavigationDelegate {
    private let html: String
    private let maxPages: Int?
    private let completion: (Data?) -> Void
    private var webView: WKWebView!
    private var offscreenWindow: UIWindow?
    private static var activeLoader: WebViewPrintPDFLoader?

    init(html: String, maxPages: Int? = nil, completion: @escaping (Data?) -> Void) {
        self.html = html
        self.maxPages = maxPages
        self.completion = completion
        super.init()
    }

    func load() {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = false
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight * 4), configuration: config)
        webView.navigationDelegate = self
        webView.isHidden = true
        webView.backgroundColor = .white
        offscreenWindow = UIWindow(frame: CGRect(x: -pageWidth * 2, y: 0, width: pageWidth, height: pageHeight * 4))
        offscreenWindow?.addSubview(webView)
        offscreenWindow?.isHidden = false
        WebViewPrintPDFLoader.activeLoader = self
        webView.loadHTMLString(html, baseURL: nil)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.generatePDF(from: webView)
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        cleanup()
        completion(nil)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        cleanup()
        completion(nil)
    }

    private func generatePDF(from webView: WKWebView) {
        let formatter = webView.viewPrintFormatter()
        let renderer = LetterPrintRenderer()
        renderer.addPrintFormatter(formatter, startingAtPageAt: 0)
        renderer.headerHeight = 0
        renderer.footerHeight = 0
        var pageCount = renderer.numberOfPages
        if pageCount <= 0 { pageCount = 1 }
        if let maxPages = maxPages {
            pageCount = min(pageCount, maxPages)
        }
        let pageSize = CGSize(width: 8.5 * 72, height: 11 * 72)
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, CGRect(origin: .zero, size: pageSize), nil)
        for page in 0..<pageCount {
            UIGraphicsBeginPDFPageWithInfo(CGRect(origin: .zero, size: pageSize), nil)
            renderer.prepare(forDrawingPages: NSRange(location: page, length: 1))
            // Use renderer.paperRect / printableRect; there is no paperRect(for:) API.
            renderer.drawPage(at: page, in: renderer.paperRect)
        }
        UIGraphicsEndPDFContext()
        cleanup()
        completion(pdfData as Data)
    }

    private func cleanup() {
        offscreenWindow?.isHidden = true
        offscreenWindow?.removeFromSuperview()
        offscreenWindow = nil
        webView?.removeFromSuperview()
        webView = nil
        WebViewPrintPDFLoader.activeLoader = nil
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
