import Foundation

class DOCXXMLParser: NSObject, XMLParserDelegate {
    private let parser: Foundation.XMLParser
    private var currentElement: String?
    private var currentText: String?
    private var documentContent: DocumentContent
    
    init(xmlString: String) throws {
        guard let data = xmlString.data(using: .utf8) else {
            throw ParserError.invalidXMLString
        }
        self.parser = Foundation.XMLParser(data: data)
        self.documentContent = DocumentContent()
        super.init()
        self.parser.delegate = self
    }
    
    func parse() throws -> DocumentContent {
        if parser.parse() {
            return documentContent
        } else if let error = parser.parserError {
            throw ParserError.parsingFailed(error)
        } else {
            throw ParserError.unknown
        }
    }
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        currentText = ""
        
        switch elementName {
        case "w:p": // Параграф
            documentContent.paragraphs.append(Paragraph(text: "", style: nil))
        case "w:tbl": // Таблица
            documentContent.tables.append(Table(rows: []))
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        guard let text = currentText else { return }
        
        switch elementName {
        case "w:t": // Текст
            if var lastParagraph = documentContent.paragraphs.last {
                lastParagraph.text += text
                documentContent.paragraphs[documentContent.paragraphs.count - 1] = lastParagraph
            }
        case "w:tr": // Строка таблицы
            if var lastTable = documentContent.tables.last {
                lastTable.rows.append([text])
                documentContent.tables[documentContent.tables.count - 1] = lastTable
            }
        default:
            break
        }
        
        currentText = nil
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText = (currentText ?? "") + string
    }
}

enum ParserError: Error {
    case invalidXMLString
    case parsingFailed(Error)
    case unknown
} 
