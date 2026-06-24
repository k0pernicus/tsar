import Foundation

func readFileAsBytes(atPath path: String) -> [UInt8]? {
    let fileURL = URL(fileURLWithPath: path)

    do {
        let data = try Data(contentsOf: fileURL)
        let bytes = Array(data)
        return bytes
    } catch {
        print("Error reading file: \(error.localizedDescription)")
        return nil
    }
}
