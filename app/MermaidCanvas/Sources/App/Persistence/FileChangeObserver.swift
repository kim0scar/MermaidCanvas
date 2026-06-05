import Foundation

/// v61: iCloud-säker ändringsbevakning av den öppna canvas-filen.
/// Datum-polling missar iCloud-ändringar (känd begränsning) — NSFilePresenter
/// får riktiga notiser via filkoordinering när Claude Code eller iCloud-synken
/// skriver i filen. Pollingen i CanvasFileManager behålls som fallback.
final class FileChangeObserver: NSObject, NSFilePresenter {
    let presentedItemURL: URL?
    let presentedItemOperationQueue = OperationQueue()
    private let onChange: () -> Void

    init(url: URL, onChange: @escaping () -> Void) {
        self.presentedItemURL = url
        self.onChange = onChange
        super.init()
        presentedItemOperationQueue.maxConcurrentOperationCount = 1
        NSFileCoordinator.addFilePresenter(self)
    }

    /// Måste anropas när filen stängs — annars läcker presentern.
    func stop() {
        NSFileCoordinator.removeFilePresenter(self)
    }

    func presentedItemDidChange() {
        onChange()
    }
}
