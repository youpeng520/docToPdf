import Foundation
import PDFKit
internal import ZIPFoundation

public class DOCXConverter {
    private let fileManager = FileManager.default
    private let pdfRenderer: PDFRenderer
    
    public init() {
        self.pdfRenderer = PDFRenderer()
    }
    
    public func convertToPDF(inputURL: URL, outputURL: URL) throws {
        // Создаем временную директорию для распаковки DOCX
        let tempDir = try createTempDirectory()
        defer { try? fileManager.removeItem(at: tempDir) }
        
        // Распаковываем DOCX
        try unzipDOCX(at: inputURL, to: tempDir)
        
        // Читаем document.xml
        let documentXML = try readDocumentXML(from: tempDir)
        
        // Парсим содержимое
        let content = try parseDocumentContent(documentXML)
        
        // Создаем PDF
        try createPDF(from: content, outputURL: outputURL)
    }
    
    private func createTempDirectory() throws -> URL {
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }
    
    private func unzipDOCX(at inputURL: URL, to outputURL: URL) throws {
        do {
            try fileManager.unzipItem(at: inputURL, to: outputURL)
        } catch {
            throw ConversionError.unzipFailed
        }
    }
    
    private func readDocumentXML(from directory: URL) throws -> String {
        let documentPath = directory.appendingPathComponent("word/document.xml")
        return try String(contentsOf: documentPath, encoding: .utf8)
    }
    
    private func parseDocumentContent(_ xml: String) throws -> DocumentContent {
        let parser = try DOCXXMLParser(xmlString: xml)
        return try parser.parse()
    }
    
    private func createPDF(from content: DocumentContent, outputURL: URL) throws {
        let pdfDocument = pdfRenderer.render(content: content)
        
        guard pdfDocument.write(to: outputURL) else {
            throw ConversionError.pdfCreationFailed
        }
    }
}

public enum ConversionError: Error {
    case unzipFailed
    case pdfCreationFailed
}

public struct DocumentContent {
    public var paragraphs: [Paragraph]
    public var tables: [Table]
    
    public init(paragraphs: [Paragraph] = [], tables: [Table] = []) {
        self.paragraphs = paragraphs
        self.tables = tables
    }
}

public struct Paragraph {
    public var text: String
    public var style: String?
    
    public init(text: String, style: String? = nil) {
        self.text = text
        self.style = style
    }
}

public struct Table {
    public var rows: [[String]]
    
    public init(rows: [[String]] = []) {
        self.rows = rows
    }
} 
