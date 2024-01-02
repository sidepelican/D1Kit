extension String {
    var isASCII: Bool {
        self.utf8.allSatisfy { $0 & 0x80 == 0 }
    }
}
