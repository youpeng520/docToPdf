import Foundation
import PDFKit
import UIKit

public class PDFRenderer {
    private let pageRect: CGRect
    private let margin: CGFloat = 50
    private let contentWidth: CGFloat
    private let contentHeight: CGFloat
    
    public init(pageRect: CGRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)) { // A4 size
        self.pageRect = pageRect
        self.contentWidth = pageRect.width - 2 * margin
        self.contentHeight = pageRect.height - 2 * margin
    }
    
    public func render(content: DocumentContent) -> PDFDocument {
        let pdfDocument = PDFDocument()
        let data = NSMutableData()
        UIGraphicsBeginPDFContextToData(data, pageRect, nil)
        
        var currentY: CGFloat = margin
        let lineHeight: CGFloat = 20
        var currentPage = 0
        
        // Начинаем первую страницу
        UIGraphicsBeginPDFPage()
        guard let context = UIGraphicsGetCurrentContext() else {
            return pdfDocument
        }
        
        // Рендерим параграфы
        for paragraph in content.paragraphs {
            // Проверяем, нужна ли новая страница
            if currentY + lineHeight > pageRect.height - margin {
                UIGraphicsBeginPDFPage()
                currentY = margin
                currentPage += 1
            }
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12)
            ]
            
            let textRect = CGRect(x: margin, y: currentY, width: contentWidth, height: lineHeight)
            paragraph.text.draw(in: textRect, withAttributes: attributes)
            
            currentY += lineHeight
        }
        
        // Рендерим таблицы
        for table in content.tables {
            guard !table.rows.isEmpty else { continue }
            
            let cellWidth: CGFloat = contentWidth / CGFloat(table.rows[0].count)
            let cellHeight: CGFloat = 30
            let tableHeight = CGFloat(table.rows.count) * cellHeight
            
            // Проверяем, поместится ли таблица на текущей странице
            if currentY + tableHeight > pageRect.height - margin {
                UIGraphicsBeginPDFPage()
                currentY = margin
                currentPage += 1
            }
            
            for (rowIndex, row) in table.rows.enumerated() {
                for (colIndex, cell) in row.enumerated() {
                    let cellRect = CGRect(
                        x: margin + CGFloat(colIndex) * cellWidth,
                        y: currentY + CGFloat(rowIndex) * cellHeight,
                        width: cellWidth,
                        height: cellHeight
                    )
                    
                    context.stroke(cellRect)
                    
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 10)
                    ]
                    
                    let textRect = cellRect.insetBy(dx: 5, dy: 5)
                    cell.draw(in: textRect, withAttributes: attributes)
                }
            }
            
            currentY += tableHeight + lineHeight
        }
        
        UIGraphicsEndPDFContext()
        
        if let pdfData = data as Data?,
           let newPDFDocument = PDFDocument(data: pdfData) {
            return newPDFDocument
        }
        
        return pdfDocument
    }
}
