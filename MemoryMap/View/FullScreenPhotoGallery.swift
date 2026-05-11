import SwiftUI
import UIKit

// MARK: - SwiftUI wrapper

struct FullScreenPhotoGallery: View {
    let photos: [PhotoEntity]
    let startIndex: Int

    @State private var currentIndex: Int
    @State private var showControls = true
    @State private var dragY: CGFloat = 0
    @Environment(\.dismiss) private var dismiss

    init(photos: [PhotoEntity], startIndex: Int) {
        self.photos = photos
        self.startIndex = startIndex
        _currentIndex = State(initialValue: startIndex)
    }

    private var backgroundOpacity: Double {
        max(0, 1.0 - Double(dragY) / 220)
    }

    var body: some View {
        ZStack {
            // Фон отдельно — тускнеет при свайпе вниз, не уезжает
            Color.black
                .ignoresSafeArea()
                .opacity(backgroundOpacity)

            // Всё содержимое уезжает вниз
            ZStack {
                PhotoPagerView(
                    photos: photos,
                    startIndex: startIndex,
                    currentIndex: $currentIndex,
                    onTap: {
                        withAnimation(.easeInOut(duration: 0.2)) { showControls.toggle() }
                    },
                    onDrag: { y in dragY = y },
                    onDismiss: { dismiss() },
                    onCancel: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { dragY = 0 }
                    }
                )
                .ignoresSafeArea()

                if showControls {
                    VStack {
                        HStack {
                            Spacer()
                            Button { dismiss() } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 34, height: 34)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            .padding(.top, 8)
                            .padding(.trailing, 16)
                        }

                        Spacer()

                        if photos.count > 1 {
                            Text("\(currentIndex + 1) / \(photos.count)")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                                .padding(.bottom, 48)
                        }
                    }
                    .transition(.opacity)
                }
            }
            .offset(y: dragY)
            .scaleEffect(dragY == 0 ? 1 : max(0.88, 1.0 - dragY / 1400))
        }
        .statusBarHidden(!showControls)
        .persistentSystemOverlays(showControls ? .automatic : .hidden)
    }
}

// MARK: - UIPageViewController wrapper

private struct PhotoPagerView: UIViewControllerRepresentable {
    let photos: [PhotoEntity]
    let startIndex: Int
    @Binding var currentIndex: Int
    let onTap: () -> Void
    let onDrag: (CGFloat) -> Void
    let onDismiss: () -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pager = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: [.interPageSpacing: 16]
        )
        pager.view.backgroundColor = .clear
        pager.dataSource = context.coordinator
        pager.delegate = context.coordinator

        // Жест для dismiss по свайпу вниз
        let pan = UIPanGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handleDismissPan(_:)))
        pan.delegate = context.coordinator
        pager.view.addGestureRecognizer(pan)
        context.coordinator.pagerVC = pager

        if let vc = context.coordinator.makePhotoVC(at: startIndex) {
            pager.setViewControllers([vc], direction: .forward, animated: false)
        }
        return pager
    }

    func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    // MARK: Coordinator

    final class Coordinator: NSObject,
                              UIPageViewControllerDataSource,
                              UIPageViewControllerDelegate,
                              UIGestureRecognizerDelegate {
        let parent: PhotoPagerView
        weak var pagerVC: UIPageViewController?

        init(_ parent: PhotoPagerView) { self.parent = parent }

        func makePhotoVC(at index: Int) -> PhotoZoomViewController? {
            guard parent.photos.indices.contains(index) else { return nil }
            let vc = PhotoZoomViewController()
            vc.configure(photo: parent.photos[index], index: index, onTap: parent.onTap)
            return vc
        }

        // MARK: Dismiss pan

        @objc func handleDismissPan(_ gr: UIPanGestureRecognizer) {
            let translation = gr.translation(in: gr.view)
            let velocity    = gr.velocity(in: gr.view)
            let y = max(0, translation.y)

            switch gr.state {
            case .changed:
                parent.onDrag(y)
            case .ended:
                if y > 110 || velocity.y > 900 {
                    parent.onDismiss()
                } else {
                    parent.onCancel()
                }
            case .cancelled, .failed:
                parent.onCancel()
            default:
                break
            }
        }

        // Разрешаем начало только при движении вниз и при 1× зуме
        func gestureRecognizerShouldBegin(_ gr: UIGestureRecognizer) -> Bool {
            guard let pan = gr as? UIPanGestureRecognizer,
                  let pagerVC else { return true }
            let vel = pan.velocity(in: pan.view)
            guard vel.y > 0, abs(vel.y) > abs(vel.x) else { return false }
            guard let photoVC = pagerVC.viewControllers?.first as? PhotoZoomViewController else { return false }
            return photoVC.isAtMinimumZoom
        }

        // Разрешаем работать одновременно с жестом UIPageViewController
        func gestureRecognizer(_ gr: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            return true
        }

        // MARK: UIPageViewControllerDataSource

        func pageViewController(_ pvc: UIPageViewController,
                                viewControllerBefore vc: UIViewController) -> UIViewController? {
            makePhotoVC(at: (vc as! PhotoZoomViewController).index - 1)
        }

        func pageViewController(_ pvc: UIPageViewController,
                                viewControllerAfter vc: UIViewController) -> UIViewController? {
            makePhotoVC(at: (vc as! PhotoZoomViewController).index + 1)
        }

        // MARK: UIPageViewControllerDelegate

        func pageViewController(_ pvc: UIPageViewController,
                                didFinishAnimating finished: Bool,
                                previousViewControllers: [UIViewController],
                                transitionCompleted completed: Bool) {
            guard completed,
                  let vc = pvc.viewControllers?.first as? PhotoZoomViewController else { return }
            parent.currentIndex = vc.index
        }
    }
}

// MARK: - Per-photo UIViewController with UIScrollView

private final class PhotoZoomViewController: UIViewController, UIScrollViewDelegate {
    private(set) var index: Int = 0
    private var onTap: (() -> Void)?

    private let scrollView = UIScrollView()
    private let imageView  = UIImageView()

    var isAtMinimumZoom: Bool {
        scrollView.zoomScale <= scrollView.minimumZoomScale + 0.001
    }

    func configure(photo: PhotoEntity, index: Int, onTap: @escaping () -> Void) {
        self.index = index
        self.onTap = onTap
        if let data = photo.imageData {
            imageView.image = UIImage(data: data)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupScrollView()
        setupGestures()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        fitImage()
    }

    // MARK: Setup

    private func setupScrollView() {
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 6.0
        scrollView.showsVerticalScrollIndicator   = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.bouncesZoom      = true
        scrollView.backgroundColor  = .clear
        scrollView.decelerationRate = .fast
        view.addSubview(scrollView)

        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        scrollView.addSubview(imageView)
    }

    private func setupGestures() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)

        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap))
        singleTap.require(toFail: doubleTap)
        scrollView.addGestureRecognizer(singleTap)
    }

    // MARK: Image layout

    private func fitImage() {
        guard let image = imageView.image else { return }
        let bounds = scrollView.bounds
        guard bounds.width > 0, bounds.height > 0 else { return }

        let scale = min(bounds.width / image.size.width, bounds.height / image.size.height)
        imageView.frame = CGRect(x: 0, y: 0,
                                 width:  image.size.width  * scale,
                                 height: image.size.height * scale)
        scrollView.contentSize = imageView.frame.size
        centerImageInScrollView()
    }

    private func centerImageInScrollView() {
        let bounds = scrollView.bounds
        let cx = max(0, (bounds.width  - imageView.frame.width)  / 2)
        let cy = max(0, (bounds.height - imageView.frame.height) / 2)
        scrollView.contentInset = UIEdgeInsets(top: cy, left: cx, bottom: cy, right: cx)
    }

    // MARK: Gestures

    @objc private func handleDoubleTap(_ gr: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            let targetScale: CGFloat = 3.0
            let loc = gr.location(in: imageView)
            let w   = scrollView.bounds.width  / targetScale
            let h   = scrollView.bounds.height / targetScale
            scrollView.zoom(to: CGRect(x: loc.x - w / 2, y: loc.y - h / 2,
                                       width: w, height: h), animated: true)
        }
    }

    @objc private func handleSingleTap() { onTap?() }

    // MARK: UIScrollViewDelegate

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }
    func scrollViewDidZoom(_ scrollView: UIScrollView) { centerImageInScrollView() }
}
