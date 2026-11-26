# MM Material Management – Shift Tâm (V1)

## Chức năng có trong bộ khởi tạo
- Đăng nhập bằng Supabase Auth (email/password).
- BOM: thêm, sửa, xóa, tìm kiếm, lọc Model, Import/Export Excel.
- GIÁ: thêm, sửa, xóa, tìm kiếm, lọc, Import/Export Excel.
- OVER: nhập dữ liệu tiêu hao qua Supabase; màn hình đọc dữ liệu đã tính định mức, lượng vượt, đơn giá và chi phí vượt từ view.
- Code dùng chung nhiều Model: nhập ở cột Model bằng dấu chấm, ví dụ `S958.S960.S961`.

## 1. Tạo Supabase
1. Tạo project Supabase.
2. Mở SQL Editor, chạy toàn bộ file `supabase.sql`.
3. Vào Project Settings > API, sao chép Project URL và Publishable key (hoặc anon key).
4. Mở `index.html`, thay:
   - `YOUR_SUPABASE_URL`
   - `YOUR_SUPABASE_PUBLISHABLE_OR_ANON_KEY`
5. Vào Authentication > Users, tạo tài khoản đăng nhập cho người sử dụng.

## 2. Chạy website
- Có thể mở `index.html` qua local web server để kiểm tra.
- Để xuất bản, đưa `index.html` lên GitHub repository và bật GitHub Pages.
- GitHub Pages chỉ host giao diện; dữ liệu vẫn lưu trên Supabase.

## 3. Mẫu cột Excel

### BOM
`Model | Code | Remark | Định mức | Đơn vị`

Ví dụ:
`S958.S960.S961 | GH02-27748A | Dùng chung | 1 | PCS`

### GIÁ
`Code | Đơn giá | Tiền tệ | Nhà cung cấp | Ngày áp dụng`

### OVER
Dữ liệu ghi nhận cần có:
`Ngày | Model | Code | Thực tế | Ghi chú`

## Lưu ý nghiệp vụ V1
- OVER được tính theo công thức: Số lượng vượt = max(Thực tế - Định mức, 0).
- Chi phí vượt = Số lượng vượt × đơn giá có ngày áp dụng gần nhất nhưng không sau ngày ghi nhận.
- Giá được lưu theo lịch sử; thêm một dòng giá mới thay vì sửa giá cũ khi giá thay đổi.
- View OVER ghép BOM theo Model chính xác hoặc Model nằm trong chuỗi phân tách bằng dấu chấm.
- Đây là bộ khởi tạo V1. Trước khi dùng dữ liệu sản xuất thật, cần xác nhận đơn vị tính, quy tắc chọn BOM khi một Code có nhiều định mức, và mẫu Excel thực tế.

## Bảo mật
- Không đưa Supabase `service_role` key vào website.
- Chỉ dùng Publishable/anon key ở trình duyệt và bật RLS như file SQL.
- Tài khoản người dùng phải được tạo trong Supabase Auth.


## Quy tắc nghiệp vụ đã xác nhận cho MM V1
1. OVER = `max(Thực tế - Định mức BOM, 0)`. Không nhân định mức với sản lượng sản xuất.
2. Định mức được tra theo cặp `Model + Code`. Một dòng BOM dùng chung có thể liệt kê nhiều Model bằng dấu chấm, ví dụ `S958.S960.S961`; việc khớp Model phải là khớp toàn bộ tên Model, không khớp một phần chuỗi.
3. Giá áp dụng là bản ghi có `effective_date` mới nhất nhưng không vượt quá ngày ghi nhận OVER.
4. Nếu không tìm thấy BOM đúng Model + Code, hệ thống để trống định mức/số lượng vượt/chi phí vượt và hiển thị `Chưa có BOM`, không tự xem định mức bằng 0.
5. Nếu không tìm thấy giá phù hợp theo ngày, chi phí vượt để trống và hiển thị `Chưa có giá`.
6. Nếu có nhiều dòng BOM cùng Model + Code, view hiện lấy bản ghi tạo gần nhất. Nên tránh tạo BOM trùng cặp Model + Code; có thể bổ sung ràng buộc dữ liệu sau khi xác nhận quy tắc phiên bản BOM.
