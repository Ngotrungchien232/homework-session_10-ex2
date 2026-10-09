# Bài 3: Đóng gói ứng dụng Web Backend bằng Single-stage Dockerfile

## 1. Giới thiệu & Mục tiêu
Bài thực hành hướng dẫn đóng gói một ứng dụng REST API Web Backend (Node.js/Express) thành Docker Image chuẩn hóa bằng kỹ thuật **Single-stage Dockerfile** để phục vụ triển khai trên môi trường thử nghiệm và sản xuất.

---

## 2. Cấu trúc thư mục dự án

```text
SESSION10_BAI3_WEB_BACKEND/
├── .dockerignore        # Bỏ qua node_modules và các tệp không cần thiết khi build
├── Dockerfile           # Kịch bản đóng gói Single-stage Docker
├── package.json         # Cấu hình dự án và dependencies (Express)
├── server.js            # Mã nguồn REST API Node.js / Express
└── README.md            # Tài liệu hướng dẫn và báo cáo kết quả
```

---

## 3. Chi tiết mã nguồn ứng dụng

### 3.1. `package.json`
```json
{
  "name": "ex2-backend",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
```

### 3.2. `server.js`
```javascript
const express = require('express');
const app = express();

const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({
    status: 'success',
    message: 'Hello from Docker Single-stage!'
  });
});

app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});
```

### 3.3. `.dockerignore`
```text
node_modules
npm-debug.log
.git
.gitignore
README.md
```

---

## 4. Phân tích tệp `Dockerfile`

```dockerfile
# 1. Base Image: node:18-alpine gọn nhẹ, bảo mật, tối ưu dung lượng
FROM node:18-alpine

# 2. Thư mục làm việc bên trong container
WORKDIR /app

# 3. Biến môi trường PORT mặc định
ENV PORT=3000

# 4. Sao chép package.json trước để tận dụng Docker Layer Caching
COPY package*.json ./

# 5. Cài đặt các thư viện phụ thuộc cho môi trường production
RUN npm install --production

# 6. Sao chép toàn bộ mã nguồn vào thư mục làm việc
COPY . .

# 7. Khai báo cổng mà ứng dụng lắng nghe
EXPOSE 3000

# 8. Lệnh chạy container dưới dạng Exec Form
CMD ["node", "server.js"]
```

### Giải thích các chỉ thị theo chuẩn Dockerfile:
- **`FROM node:18-alpine`**: Sử dụng base image phiên bản Node.js 18 dựa trên Alpine Linux giúp image có kích thước nhỏ gọn (~47MB content size).
- **`WORKDIR /app`**: Đặt thư mục `/app` làm thư mục gốc cho mọi thao tác tiếp theo.
- **`ENV PORT=3000`**: Thiết lập biến môi trường `PORT` để ứng dụng linh hoạt cấu hình cổng.
- **`COPY package*.json ./` & `RUN npm install --production`**: Tách bước cài đặt dependencies khỏi việc copy mã nguồn. Khi mã nguồn thay đổi nhưng `package.json` không đổi, Docker sẽ tái sử dụng cache layer mà không cần tải lại thư viện.
- **`COPY . .`**: Sao chép mã nguồn ứng dụng (đã loại trừ `node_modules` nhờ `.dockerignore`).
- **`EXPOSE 3000`**: Tài liệu hóa cổng 3000 mà container cung cấp dịch vụ.
- **`CMD ["node", "server.js"]`**: Sử dụng dạng Exec Form (`["executable", "param1", ...]`) giúp tiến trình `node` chạy với PID 1, bắt các tín hiệu dừng (`SIGTERM`, `SIGINT`) một cách chuẩn xác từ Docker daemon.

---

## 5. Hướng dẫn thực thi & Kết quả kiểm tra

### Bước 1: Build Docker Image
Chạy lệnh build với tag `hw-backend:v1`:
```bash
docker build -t hw-backend:v1 .
```

### Bước 2: Khởi chạy container
Khởi chạy container ở chế độ detached (`-d`), đặt tên `app-single-stage` và ánh xạ cổng máy host `8080` vào cổng container `3000`:
```bash
docker run -d --name app-single-stage -p 8080:3000 hw-backend:v1
```

### Bước 3: Kiểm tra trạng thái container (`docker ps`)
```bash
docker ps
```
**Kết quả hiển thị:**
```text
CONTAINER ID   IMAGE           COMMAND                  CREATED          STATUS         PORTS                                         NAMES
b9c3e852302d   hw-backend:v1   "docker-entrypoint.s…"   10 seconds ago   Up 9 seconds   0.0.0.0:8080->3000/tcp, [::]:8080->3000/tcp   app-single-stage
```
> Trạng thái: `Up` (Container hoạt động bình thường, không bị thoát).

### Bước 4: Kiểm tra log của container (`docker logs`)
```bash
docker logs app-single-stage
```
**Kết quả hiển thị:**
```text
Server listening on port 3000
```

### Bước 5: Kiểm tra phản hồi API (`curl`)
Gửi yêu cầu HTTP GET đến cổng `8080`:
```bash
curl -i http://localhost:8080/
```
**Kết quả trả về:**
```http
HTTP/1.1 200 OK
X-Powered-By: Express
Content-Type: application/json; charset=utf-8
Content-Length: 64
ETag: W/"40-upZb7Fps+hszzRU9BoKtiCsmGCQ"
Date: Fri, 09 Oct 2026 08:04:32 GMT
Connection: keep-alive
Keep-Alive: timeout=5

{"status":"success","message":"Hello from Docker Single-stage!"}
```
- Mã trạng thái: `HTTP/1.1 200 OK`
- Dữ liệu trả về đúng định dạng JSON: `{"status":"success","message":"Hello from Docker Single-stage!"}`

---

## 6. Lệnh dọn dẹp môi trường (Cleanup)
Sau khi kiểm tra hoàn tất, dọn dẹp container và image nếu cần:
```bash
# Dừng và xóa container
docker stop app-single-stage
docker rm app-single-stage

# (Tùy chọn) Xóa image
docker rmi hw-backend:v1
```

---

## 7. Thông tin nộp bài
- **Đường dẫn trên GitHub:** `homework/session_10/ex2/`
- **Các tệp nộp:**
  1. `Dockerfile`
  2. `package.json`
  3. `server.js`
  4. `.dockerignore`
  5. `README.md`
