class ConversionSettings {
    var sourceFormat: EbookFormat
    var targetFormat: EbookFormat
    var includeAudio: Bool
    
    init(sourceFormat: EbookFormat, targetFormat: EbookFormat, includeAudio: Bool = false) {
        self.sourceFormat = sourceFormat
        self.targetFormat = targetFormat
        self.includeAudio = includeAudio
    }
}