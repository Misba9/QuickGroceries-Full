/// Invoice (priced) vs packing slip (no prices).
enum ReceiptMode {
  invoice,
  packingSlip,
}

/// Thermal / PDF paper targets.
enum ReceiptPaperSize {
  mm58,
  mm80,
  a4,
}

extension ReceiptPaperSizeExt on ReceiptPaperSize {
  double get widthMm => switch (this) {
        ReceiptPaperSize.mm58 => 58,
        ReceiptPaperSize.mm80 => 80,
        ReceiptPaperSize.a4 => 210,
      };

  /// Usable content width inside margins.
  double get contentWidthMm => switch (this) {
        ReceiptPaperSize.mm58 => 52,
        ReceiptPaperSize.mm80 => 72,
        ReceiptPaperSize.a4 => 190,
      };

  String get label => switch (this) {
        ReceiptPaperSize.mm58 => '58mm thermal',
        ReceiptPaperSize.mm80 => '80mm thermal',
        ReceiptPaperSize.a4 => 'A4 PDF',
      };
}
