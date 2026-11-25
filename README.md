# DmChart iOS

Ứng dụng iOS dạng web container cho [DmChart](https://dmcharts.com/chart), viết bằng SwiftUI + `WKWebView`. Trang web được tải trực tiếp từ DmChart; các thao tác trên biểu đồ và tài khoản vẫn do website cung cấp.

## Tính năng

- Mở `https://dmcharts.com/chart` trong giao diện iOS, hỗ trợ cả dọc và ngang.
- Giữ cookie/lưu phiên đăng nhập trong kho dữ liệu web mặc định của iOS.
- Vuốt cạnh để quay lại/đi tiếp, kéo xuống để tải lại; menu nổi có quay lại, đi tiếp, tải lại, chia sẻ URL và mở trong trình duyệt.
- Liên kết `tel:`, `mailto:` và scheme ứng dụng khác được chuyển cho iOS xử lý.
- Hiển thị trạng thái tải và nút thử lại khi lần tải đầu bị lỗi.

## Tạo IPA bằng GitHub Actions

Workflow `.github/workflows/build-ios.yml` chạy khi push lên bất kỳ branch nào hoặc khi chạy thủ công. Trên GitHub:

1. Mở **Actions → Build iOS IPA**. Có thể chọn **Run workflow** để chạy thủ công trên branch hiện tại.
2. Mở lần chạy thành công, tải artifact **DmChart-unsigned-ipa**.
3. Giải nén artifact; bên trong có `DmChart-unsigned.ipa` và file checksum `.sha256`.
4. Import IPA vào eSign, chọn chứng chỉ/provisioning profile hợp lệ của bạn, ký rồi cài lên iPhone/iPad.

IPA do workflow tạo ra **chưa được ký**. iOS không cài trực tiếp IPA unsigned: eSign cần ký bằng chứng chỉ hợp lệ còn hạn và profile phù hợp với thiết bị. Không đưa file `.p12`, provisioning profile hay mật khẩu chứng chỉ vào source code/repository. Workflow chỉ build IPA unsigned để bạn tự ký trong eSign.

## Build bằng Xcode

Mở `DmChart.xcodeproj`, chọn scheme **DmChart**, sau đó build/run trên iPhone Simulator hoặc thiết bị. Target tối thiểu là iOS 16. Bundle identifier hiện tại là `com.dmcharts.ios`; đổi identifier nếu bạn cần dùng identifier riêng khi ký.

## Ghi chú

Đây là ứng dụng bao website, không phải bản native độc lập của TradingView hay một engine biểu đồ riêng. App cần internet và phụ thuộc vào giao diện, khả năng tương thích di động, đăng nhập, điều khoản sử dụng và tính sẵn sàng của `dmcharts.com`.
