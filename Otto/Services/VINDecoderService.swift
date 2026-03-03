import Foundation

enum VINValidationResult {
    case valid
    case invalidLength
    case invalidCharacters
    case invalidCheckDigit
}

struct VINInfo {
    let vin: String
    let countryOfOrigin: String
    let modelYear: String
}

enum VINDecoderService {
    private static let transliteration: [Character: Int] = [
        "A": 1, "B": 2, "C": 3, "D": 4, "E": 5, "F": 6, "G": 7, "H": 8,
        "J": 1, "K": 2, "L": 3, "M": 4, "N": 5, "P": 7, "R": 9,
        "S": 2, "T": 3, "U": 4, "V": 5, "W": 6, "X": 7, "Y": 8, "Z": 9,
        "0": 0, "1": 1, "2": 2, "3": 3, "4": 4,
        "5": 5, "6": 6, "7": 7, "8": 8, "9": 9
    ]

    private static let positionWeights = [8, 7, 6, 5, 4, 3, 2, 10, 0, 9, 8, 7, 6, 5, 4, 3, 2]

    private static let yearCodes: [Character: String] = [
        "N": "2022", "P": "2023", "R": "2024", "S": "2025", "T": "2026",
        "V": "2027", "W": "2028", "X": "2029", "Y": "2030",
        "A": "2010", "B": "2011", "C": "2012", "D": "2013", "E": "2014",
        "F": "2015", "G": "2016", "H": "2017", "J": "2018", "K": "2019",
        "L": "2020", "M": "2021",
        "1": "2001", "2": "2002", "3": "2003", "4": "2004", "5": "2005",
        "6": "2006", "7": "2007", "8": "2008", "9": "2009"
    ]

    private static let countryPrefixes: [Character: String] = [
        "1": "United States", "4": "United States", "5": "United States",
        "2": "Canada",
        "3": "Mexico",
        "J": "Japan",
        "K": "South Korea",
        "L": "China",
        "S": "United Kingdom",
        "V": "France/Spain",
        "W": "Germany",
        "Z": "Italy",
        "9": "Brazil"
    ]

    static func validate(_ vin: String) -> VINValidationResult {
        let uppercased = vin.uppercased()

        guard uppercased.count == 17 else { return .invalidLength }

        let disallowed: Set<Character> = ["I", "O", "Q"]
        for char in uppercased {
            if disallowed.contains(char) { return .invalidCharacters }
            if transliteration[char] == nil { return .invalidCharacters }
        }

        let chars = Array(uppercased)
        var sum = 0
        for (index, char) in chars.enumerated() {
            guard let value = transliteration[char] else { return .invalidCharacters }
            sum += value * positionWeights[index]
        }

        let remainder = sum % 11
        let checkChar = chars[8]
        let expectedCheck: Character = remainder == 10 ? "X" : Character(String(remainder))

        if checkChar != expectedCheck { return .invalidCheckDigit }

        return .valid
    }

    static func decode(_ vin: String) -> VINInfo? {
        let uppercased = vin.uppercased()
        guard uppercased.count == 17 else { return nil }

        let chars = Array(uppercased)
        let country = countryPrefixes[chars[0]] ?? "Unknown"
        let modelYear = yearCodes[chars[9]] ?? "Unknown"

        return VINInfo(vin: uppercased, countryOfOrigin: country, modelYear: modelYear)
    }
}
