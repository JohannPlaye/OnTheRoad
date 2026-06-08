import Foundation

/// Minimal pure-Swift XLSX writer — no external dependencies.
/// Uses STORED (uncompressed) ZIP entries and inline strings.
struct XLSXWriter {

    // MARK: - Public API

    /// Builds an .xlsx file and writes it to a temporary URL.
    /// - Parameters:
    ///   - filename: Target filename (include .xlsx extension).
    ///   - sheetName: Name of the worksheet tab.
    ///   - headers: Column headers (displayed bold in row 1).
    ///   - rows: Data rows, each array matching the headers count.
    /// - Returns: URL of the written file, or nil on failure.
    static func fileURL(filename: String,
                        sheetName: String = "Trajets",
                        headers: [String],
                        rows: [[String]]) -> URL? {
        let entries: [(name: String, xml: String)] = [
            ("[Content_Types].xml",            contentTypesXML()),
            ("_rels/.rels",                    relsXML()),
            ("xl/workbook.xml",                workbookXML(sheetName: sheetName)),
            ("xl/_rels/workbook.xml.rels",     workbookRelsXML()),
            ("xl/worksheets/sheet1.xml",       sheetXML(headers: headers, rows: rows)),
            ("xl/styles.xml",                  stylesXML()),
        ]

        let dataEntries: [(name: String, data: Data)] = entries.compactMap { name, xml in
            guard let data = xml.data(using: .utf8) else { return nil }
            return (name, data)
        }
        guard dataEntries.count == entries.count else { return nil }

        guard let zip = buildZip(entries: dataEntries) else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? zip.write(to: url)
        return url
    }

    // MARK: - XML builders

    private static func contentTypesXML() -> String {
        """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
          <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
          <Default Extension="xml"  ContentType="application/xml"/>
          <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
          <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
          <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
        </Types>
        """
    }

    private static func relsXML() -> String {
        """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
        </Relationships>
        """
    }

    private static func workbookXML(sheetName: String) -> String {
        let escapedName = xmlEscape(sheetName)
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
          <sheets>
            <sheet name="\(escapedName)" sheetId="1" r:id="rId1"/>
          </sheets>
        </workbook>
        """
    }

    private static func workbookRelsXML() -> String {
        """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
          <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
        </Relationships>
        """
    }

    private static func sheetXML(headers: [String], rows: [[String]]) -> String {
        var xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
          <sheetData>

        """
        xml += makeRow(index: 1, values: headers, bold: true)
        for (i, row) in rows.enumerated() {
            xml += makeRow(index: i + 2, values: row, bold: false)
        }
        xml += """
          </sheetData>
        </worksheet>
        """
        return xml
    }

    private static func makeRow(index: Int, values: [String], bold: Bool) -> String {
        var row = "    <row r=\"\(index)\">"
        let styleAttr = bold ? " s=\"1\"" : ""
        for (col, value) in values.enumerated() {
            let ref = "\(columnLetter(col))\(index)"
            let escaped = xmlEscape(value)
            row += "<c r=\"\(ref)\" t=\"inlineStr\"\(styleAttr)><is><t>\(escaped)</t></is></c>"
        }
        row += "</row>\n"
        return row
    }

    /// Minimal styles: index 0 = normal, index 1 = bold header.
    private static func stylesXML() -> String {
        """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
          <fonts count="2">
            <font><sz val="11"/><name val="Calibri"/></font>
            <font><b/><sz val="11"/><name val="Calibri"/></font>
          </fonts>
          <fills count="2">
            <fill><patternFill patternType="none"/></fill>
            <fill><patternFill patternType="gray125"/></fill>
          </fills>
          <borders count="1">
            <border><left/><right/><top/><bottom/><diagonal/></border>
          </borders>
          <cellStyleXfs count="1">
            <xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>
          </cellStyleXfs>
          <cellXfs count="2">
            <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
            <xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/>
          </cellXfs>
        </styleSheet>
        """
    }

    // MARK: - Helpers

    private static func columnLetter(_ index: Int) -> String {
        var result = ""
        var i = index
        repeat {
            result = String(UnicodeScalar(UInt32(65 + (i % 26)))!) + result
            i = i / 26 - 1
        } while i >= 0
        return result
    }

    private static func xmlEscape(_ s: String) -> String {
        s.replacingOccurrences(of: "&",  with: "&amp;")
         .replacingOccurrences(of: "<",  with: "&lt;")
         .replacingOccurrences(of: ">",  with: "&gt;")
         .replacingOccurrences(of: "\"", with: "&quot;")
         .replacingOccurrences(of: "'",  with: "&apos;")
    }

    // MARK: - Minimal ZIP (STORED, no compression)

    private static func buildZip(entries: [(name: String, data: Data)]) -> Data? {
        var zip = Data()
        var centralDirectory = Data()
        var offsets: [UInt32] = []

        for entry in entries {
            guard let nameData = entry.name.data(using: .utf8) else { return nil }
            offsets.append(UInt32(zip.count))

            let checksum = crc32(entry.data)
            let size = UInt32(entry.data.count)

            // Local file header
            zip += le32(0x04034b50)
            zip += le16(20)                       // version needed
            zip += le16(0)                        // flags
            zip += le16(0)                        // STORED
            zip += le16(0); zip += le16(0)        // mod time, date
            zip += le32(checksum)
            zip += le32(size); zip += le32(size)  // compressed == uncompressed
            zip += le16(UInt16(nameData.count))
            zip += le16(0)                        // extra field length
            zip += nameData
            zip += entry.data

            // Central directory entry
            centralDirectory += le32(0x02014b50)
            centralDirectory += le16(20); centralDirectory += le16(20)  // version made / needed
            centralDirectory += le16(0); centralDirectory += le16(0)    // flags, STORED
            centralDirectory += le16(0); centralDirectory += le16(0)    // mod time, date
            centralDirectory += le32(checksum)
            centralDirectory += le32(size); centralDirectory += le32(size)
            centralDirectory += le16(UInt16(nameData.count))
            centralDirectory += le16(0); centralDirectory += le16(0)    // extra, comment
            centralDirectory += le16(0); centralDirectory += le16(0)    // disk start, int attr
            centralDirectory += le32(0)                                 // ext attr
            centralDirectory += le32(offsets.last!)
            centralDirectory += nameData
        }

        let centralDirOffset = UInt32(zip.count)
        let centralDirSize   = UInt32(centralDirectory.count)
        zip += centralDirectory

        // End of central directory
        zip += le32(0x06054b50)
        zip += le16(0); zip += le16(0)               // disk numbers
        zip += le16(UInt16(entries.count))
        zip += le16(UInt16(entries.count))
        zip += le32(centralDirSize)
        zip += le32(centralDirOffset)
        zip += le16(0)                               // comment length

        return zip
    }

    private static func le16(_ v: UInt16) -> Data { withUnsafeBytes(of: v.littleEndian) { Data($0) } }
    private static func le32(_ v: UInt32) -> Data { withUnsafeBytes(of: v.littleEndian) { Data($0) } }

    // CRC-32 (ISO 3309)
    private static let crcTable: [UInt32] = (0..<256).map { n -> UInt32 in
        var c = UInt32(n)
        for _ in 0..<8 { c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1 }
        return c
    }

    private static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFFFFFF
        for byte in data { crc = crcTable[Int((crc ^ UInt32(byte)) & 0xFF)] ^ (crc >> 8) }
        return crc ^ 0xFFFFFFFF
    }
}
