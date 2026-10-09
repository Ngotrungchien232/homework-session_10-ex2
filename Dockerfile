# Sử dụng Base Image node:18-alpine nhẹ và tối ưu
FROM node:18-alpine

# Thiết lập thư mục làm việc bên trong container
WORKDIR /app

# Thiết lập biến môi trường PORT mặc định là 3000
ENV PORT=3000

# Copy file cấu hình package để tận dụng bộ nhớ đệm (caching) của Docker layer
COPY package*.json ./

# Cài đặt dependencies cho ứng dụng
RUN npm install --production

# Copy toàn bộ mã nguồn ứng dụng vào container
COPY . .

# Khai báo cổng ứng dụng lắng nghe
EXPOSE 3000

# Lệnh khởi chạy ứng dụng dạng exec form
CMD ["node", "server.js"]
