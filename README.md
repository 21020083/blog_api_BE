# Blog API

RESTful API được xây dựng bằng Ruby on Rails 8.0 để quản lý hệ thống blog với các tính năng: xác thực JWT, quản lý bài viết, bình luận, phân loại, thẻ, bookmark, analytics và thông báo.

## ✨ Tính năng chính

- **Xác thực**: JWT authentication với Devise
- **Blog**: CRUD bài viết, draft/published, friendly URLs
- **Tương tác**: Bình luận, upvote/downvote, bookmark
- **Phân loại**: Category phân cấp và tags
- **Analytics**: Thống kê views/likes với caching tối ưu
- **Thông báo**: Real-time notifications
- **Audit Logs**: Ghi log các hành động quan trọng

## 🛠 Công nghệ

- **Ruby** 3.4.5
- **Rails** 8.0.2
- **MySQL** 8.0+
- **Devise** + **Devise-JWT**: Authentication
- **JSONAPI::Serializer**: JSON responses
- **Kaminari**: Phân trang
- **Acts As Votable**: Voting system
- **FriendlyId**: Friendly URLs
- **Noticed**: Notifications
- **RSpec**: Testing

## 📦 Yêu cầu

- Ruby 3.4.5
- MySQL 8.0+
- Bundler

## 🚀 Cài đặt

### 1. Clone repository

```bash
git clone <repository-url>
cd blog_api
```

### 2. Cài đặt dependencies

```bash
bundle install
```

### 3. Cấu hình database

Tạo file `.env` từ `env.example`:

```bash
cp env.example .env
```

Chỉnh sửa file `.env`:

```env
MYSQL_ROOT_PASSWORD=your_password
MYSQL_DATABASE=blog_api_development
MYSQL_USER=blog_user
MYSQL_PASSWORD=your_password
DB_HOST=localhost
DB_PORT=3306
DEVISE_JWT_SECRET_KEY=your_jwt_secret_key_here
```

### 4. Tạo và migrate database

```bash
rails db:create
rails db:migrate
rails db:seed
```

## 🏃 Chạy ứng dụng

### Development Server

```bash
rails server
```

Hoặc:

```bash
bin/dev
```

Server chạy tại `http://localhost:3000`

### Console

```bash
rails console
```

## 📡 API Endpoints

### Authentication
- `POST /signup` - Đăng ký
- `POST /login` - Đăng nhập
- `DELETE /logout` - Đăng xuất

### Blogs
- `GET /blogs` - Danh sách blogs (có filter, pagination)
- `GET /blogs/:id` - Chi tiết blog
- `POST /blogs` - Tạo blog (yêu cầu auth)
- `PATCH /blogs/:id` - Cập nhật blog
- `DELETE /blogs/:id` - Xóa blog
- `POST /blogs/:id/upvote` - Upvote
- `POST /blogs/:id/downvote` - Downvote

### Comments, Categories, Tags, Bookmarks, Analytics
Xem file `config/routes.rb` để biết chi tiết các endpoints.

**Lưu ý**: Tất cả endpoints (trừ signup/login) yêu cầu JWT token trong header:
```
Authorization: Bearer <token>
```

## 🧪 Kiểm thử

```bash
bundle exec rspec
```

## 📝 Ghi chú

- API sử dụng JSONAPI format
- Friendly URLs: Blogs và Users có thể truy cập qua slug
---

