# 🍽️ DineQR — Scan • Order • Enjoy

A modern QR-based restaurant ordering system built with **Flutter** (mobile) and **Django** (backend). Customers scan a table QR code, browse the menu, and place orders — all from their phone. Kitchen staff receive real-time order updates via WebSocket.

---

## ✨ Features

### Customer (Mobile App)
- QR code scanning to identify table
- Beautiful menu browsing with categories & search
- Cart management with notes per item
- Real-time order tracking (Pending → Cooking → Ready → Served)
- Call waiter functionality

### Kitchen Staff
- Real-time order dashboard via WebSocket
- Filter orders by status
- Accept, cook, and mark orders as ready
- Audio/visual alerts for new orders

### Admin
- Dashboard with revenue, orders, and table analytics
- Full menu CRUD (categories & items)
- Table management with QR code generation
- Staff management

---

## 🏗️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Mobile** | Flutter 3.x, Riverpod, GoRouter, Material 3 |
| **Backend** | Django 4.2, Django REST Framework |
| **Real-time** | Django Channels (WebSocket) |
| **Auth** | JWT (SimpleJWT) |
| **Database** | SQLite (dev) / PostgreSQL (prod) |
| **Cache** | Redis (for Channels layer) |
| **Deployment** | Docker, Nginx, Daphne |

---

## 🎨 Design System

**Black Luxury Theme** with gold accents:

| Token | Value |
|-------|-------|
| Background | `#0A0A0A` |
| Surface | `#141414` |
| Gold Accent | `#F4C430` |
| Gold Light | `#FFD966` |
| Text Primary | `#F5F5F5` |
| Text Secondary | `#B0B0B0` |

---

## 🚀 Getting Started

### Prerequisites

- Python 3.10+
- Flutter 3.x SDK
- Node.js (optional, for tooling)
- Docker & Docker Compose (for production)

### Backend Setup

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Linux/Mac
# venv\Scripts\activate   # Windows

# Install dependencies
pip install -r requirements.txt

# Run migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Run development server
python manage.py runserver 0.0.0.0:8000
```

### Frontend Setup

```bash
cd frontend

# Get Flutter dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Build APK
flutter build apk --release
```

### Docker (Production)

```bash
# From project root
docker-compose up -d

# Run migrations inside container
docker-compose exec backend python manage.py migrate
```

---

## 📁 Project Structure

```
DineQR/
├── frontend/                    # Flutter mobile app
│   ├── lib/
│   │   ├── core/
│   │   │   ├── theme/           # AppColors, AppTheme
│   │   │   ├── constants/       # API URLs, app constants
│   │   │   └── widgets/         # Shared reusable widgets
│   │   ├── models/              # Data models
│   │   ├── services/            # API & Socket services
│   │   ├── providers/           # Riverpod state management
│   │   ├── routes/              # GoRouter configuration
│   │   ├── features/
│   │   │   ├── splash/          # Splash screen
│   │   │   ├── onboarding/      # Onboarding pages
│   │   │   ├── auth/            # Staff login
│   │   │   ├── qr_scan/         # QR code scanner
│   │   │   ├── menu/            # Menu browsing
│   │   │   ├── cart/            # Shopping cart
│   │   │   ├── checkout/        # Order checkout
│   │   │   ├── order_tracking/  # Real-time tracking
│   │   │   ├── kitchen/         # Kitchen dashboard
│   │   │   └── admin/           # Admin panel
│   │   └── main.dart
│   └── pubspec.yaml
│
├── backend/                     # Django REST API
│   ├── backend/                 # Django project config
│   │   ├── settings.py
│   │   ├── urls.py
│   │   ├── asgi.py              # WebSocket routing
│   │   └── wsgi.py
│   ├── users/                   # User authentication app
│   ├── menu/                    # Menu & categories app
│   ├── orders/                  # Orders & tables app
│   │   ├── models.py            # Table, Order, OrderItem
│   │   ├── consumers.py         # WebSocket consumer
│   │   └── routing.py           # WebSocket URL patterns
│   ├── manage.py
│   ├── requirements.txt
│   └── Dockerfile
│
├── scripts/
│   ├── seed_data.py             # Database seeder
│   └── generate_qr_codes.py     # QR code image generator
│
├── nginx/
│   └── nginx.conf               # Nginx reverse proxy config
│
├── docker-compose.yml
└── README.md
```

---

## 🔌 API Endpoints

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/login/` | Staff login (JWT) |
| POST | `/api/auth/refresh/` | Refresh token |
| GET | `/api/auth/profile/` | Get user profile |

### Menu
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/menu/categories/` | List categories |
| POST | `/api/menu/categories/` | Create category |
| GET | `/api/menu/items/` | List menu items |
| POST | `/api/menu/items/` | Create menu item |
| GET | `/api/menu/items/?category=1` | Filter by category |
| GET | `/api/menu/items/?search=pizza` | Search items |

### Orders
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/orders/create/` | Create new order |
| GET | `/api/orders/<id>/` | Get order details |
| PATCH | `/api/orders/<id>/status/` | Update order status |
| GET | `/api/orders/table/<id>/` | Orders for table |
| GET | `/api/orders/kitchen/` | Kitchen orders |
| GET | `/api/orders/dashboard/` | Admin dashboard stats |

### Tables
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/orders/tables/` | List all tables |
| GET | `/api/orders/tables/number/<n>/` | Get table by number |
| POST | `/api/orders/tables/<id>/generate-qr/` | Generate QR code |

### WebSocket
| URL | Description |
|-----|-------------|
| `ws://host/ws/orders/` | Kitchen order stream |
| `ws://host/ws/orders/<table>/` | Table-specific updates |

---

## 📱 App Flow

```
Splash → Onboarding → QR Scan → Menu → Cart → Checkout → Order Tracking
                           ↓
                      Staff Login → Kitchen Dashboard
                                  → Admin Dashboard
```

---

## 🛠️ QR Code Generation

Generate printable QR codes for your restaurant tables:

```bash
cd scripts

# Generate QR codes for 15 tables
python generate_qr_codes.py --tables 15 --base-url http://your-server:8000

# Output goes to scripts/qr_codes/ directory
```

---

## 📄 License

This project is private and proprietary.

---

**DineQR** — *Scan • Order • Enjoy* 🍽️
