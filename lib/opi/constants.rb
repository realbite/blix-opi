module OPI

  ERROR_XML = 'missing XML'.freeze


  # define valid result values
  class Result
    [
      'Success' ,            # Complete Success.
      'PartialFailure' ,      # The PartialFailure is the case when the main operation (e.g. input) is succesful and the secondary operation fails (e.g. output).
      'Failure',              # Complete failure
      'DeviceUnavailable',    # Complete failure. No further request will be successful
      'Busy',                 # Complete failure. It is a temporary state and it is likely that a second attempt shortly will be successful
      'Aborted',              # Complete failure. The transaction was aborted by cashier or customer or an Abort Request.
      'TimedOut',             # Complete failure. No response from remote host.
      'CommunicationError',   # OverallResult-value on Diagnosis-request: host system not available.
      'FormatError',          # Complete failure. The request cannot be handled or is mistakenly (unknown) formatted
      'ParsingError',         # Complete failure. The request XML is not well formed
      'ValidationError',      # Complete failure. The request XML is not validated against the definition schema
      'MissingMandatoryData' # Complete failure. The request message is missing necessary data
    ].each{|v| const_set(v,v.freeze)}
  end # Result

  class Device
    [
      'CashierDisplay',   # A pop-up window (or a fixed window) on the POS cashier display
      'CustomerDisplay',  # customer display at the POS
      'Printer' ,         # Stand-alone printer for receipts/tickets.
      'PrinterReceipt',   # Stand-alone printer for receipts for customer, not shared for other purpose or application
      'ICCrw',            # Integrated circuit card reader/writer. Stand-alone
      'CardReader',       # Generic card reader, combining magstripe reader and ICCrw
      'PinEntryDeviceCardReader', # Generic card reader combined with a PinPad.
      'PinPad',           # Keypad (e.g. for PIN enter) and customer display.(e.g. 16*2 chars or wider 4 lines graphical)
      'PEDReaderPrinter', # Generic card reader combined with a PinPad and ticket printer.
      'MSR',              # Magnetic stripe reader stand alone.
      'RFID',             # Wireless chip reader/writer for contact less cards/tags
      'BarcodeScanner',   # Barcode scanne
      'CashierKeyboard',  # Cashier input device (keyboard or touch screen
      'CashierTerminal',  # Cashier input device (keyboard or touch screen) and A pop-up window (or a fixed window) on the POS cashier display,
      'CustomerKeyboard', #Customer input device (keyboard or touch screen or custom buttons)
      'CustomerTerminal', # Customer input/output device (keyboard and display/window-screen or touch screen) on the POS customer display, dedicated to these messages through the device proxy.
      'Log'              # Device logging the operations. 
    ].each{|v| const_set(v,v.freeze)}
  end
end
