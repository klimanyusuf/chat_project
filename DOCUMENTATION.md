\# Chat Application –Documentation



\## Live Application

The app is deployed on Render and accessible at:

 https://chat-project-s9uv.onrender.com



---



\## Repository Structure

chat\_project/

├── manage.py # Django CLI tool

├── requirements.txt # Python dependencies

├── .env.example # Template for environment variables

├── .gitignore # Files ignored by Git

├── Dockerfile # Container definition for production

├── docker-compose.yml # Local development orchestration

├── Procfile # Render start command

├── README.md # Project overview

├── DOCUMENTATION.md # This file – detailed manual

├── chat\_project/ # Main Django project configuration

│ ├── init.py

│ ├── settings.py # All settings (DB, apps, middleware, etc.)

│ ├── urls.py # Root URL routing

│ ├── asgi.py # ASGI entry point for WebSockets

│ ├── wsgi.py # WSGI entry point (fallback)

│ └── celery.py # Celery app configuration

├── apps/ # All Django applications

│ ├── accounts/ # User authentication \& profiles

│ │ ├── admin.py # Custom UserAdmin with email in add form

│ │ ├── models.py # Custom User model (email, online status, avatar)

│ │ ├── serializers.py # JWT serializers (login, register)

│ │ ├── views.py # Register, login, logout, session, forgot-password

│ │ └── urls.py # API endpoints for auth

│ ├── chat/ # Core chat functionality

│ │ ├── admin.py # Admin for rooms, messages, memberships

│ │ ├── models.py # ChatRoom, Message, RoomMembership, receipts

│ │ ├── serializers.py # Room and message serializers

│ │ ├── views.py # REST endpoints for rooms and messages

│ │ ├── consumers.py # WebSocket consumer for real‑time chat

│ │ ├── routing.py # WebSocket URL patterns

│ │ └── urls.py # REST API routes for chat

│ └── ai\_assistant/ # AI smart replies

│ ├── adapters.py # Gemini and DeepSeek API clients

│ ├── services.py # SmartReplyService with caching \& fallback

│ ├── consumers.py # WebSocket consumer for receiving suggestions

│ ├── routing.py # WebSocket URL patterns for AI

│ └── tasks.py # Celery task for generating suggestions

├── templates/ # Frontend HTML templates

│ ├── base.html # Base template

│ ├── index.html # Dashboard (login, rooms, users, group creation)

│ ├── auth/

│ │ ├── login.html # Login page

│ │ ├── signup.html # Signup page

│ │ ├── forgot\_password.html # Forgot password page

│ │ └── reset\_password.html # Password reset (token in URL)

│ ├── chat/

│ │ └── room.html # Chat interface with WebSockets and smart replies

│ └── group\_info.html # Group member list with admin badges

└── static/ # (Optional) Custom CSS/JS





---



\## How the Application Works



\### 1. Authentication Flow

\- Users sign up via `/signup/` (POST to `/api/auth/register/`).

\- Login via `/login/` (POST to `/api/auth/login/`) returns a JWT token.

\- Token is stored in `localStorage` and sent with every authenticated request.

\- Session check and token refresh endpoints available.

\- Forgot password sends a reset link (backend returns generic success; actual email requires SMTP config).



\### 2. Real‑Time Chat

\- WebSocket connection established to `wss://chat-project-s9uv.onrender.com/ws/chat/<room\\\_id>/` with JWT token.

\- Messages are broadcast to all participants via Django Channels (Redis channel layer).

\- Typing indicators, online/offline status, and read receipts are handled via WebSocket events.

\- Message history is loaded via REST API when entering a room.



\### 3. AI Smart Replies

\- When a user pauses typing, the frontend sends a `request\\\_suggestions` WebSocket event.

\- The `ChatConsumer` triggers a Celery task `generate\\\_smart\\\_replies`.

\- Celery worker calls the Gemini API (via `GeminiSmartReplyAdapter`) with recent conversation context.

\- Gemini returns three short suggestions; if API fails (e.g., no credits), fallback suggestions are used.

\- Suggestions are sent back to the user via a separate WebSocket (`smart-reply` consumer).



\### 4. Admin Panel

\- Accessible at `/admin/`.

\- Full CRUD for users, chat rooms, messages, memberships, and receipts.

\- Participant management via `filter\\\_horizontal` widget in room admin.



\### 5. Deployment (Render)

\- Dockerized app with `Dockerfile` and `docker-compose.yml`.

\- Render builds from GitHub and runs `daphne` as the ASGI server (supports WebSockets).

\- Environment variables: `DATABASE\\\_URL`, `REDIS\\\_URL`, `GEMINI\\\_API\\\_KEY`, `SECRET\\\_KEY`, `ALLOWED\\\_HOSTS`, etc.

\- PostgreSQL and Redis are managed Render instances.

\- A free cron job (e.g., cron-job.org) pings the app every 10 minutes to prevent idle spin‑down.



---



\## Environment Variables (`.env` example)

SECRET\_KEY=your-secret-key

DEBUG=False

ALLOWED\_HOSTS=chat-project-s9uv.onrender.com,localhost



Database

DB\_NAME=your\_db\_name

DB\_USER=db\_user\_name

DB\_PASSWORD=your\_db\_password

DB\_HOST=dpg-d6ixxxxxx

DB\_PORT=5432



Redis

REDIS\_URL=redis://red-d6xxxxxx



Gemini API

GEMINI\_API\_KEY=your\_gemini\_key







---



\##  Technologies Used



\- Backend: Python 3.11, Django 4.2, Django REST Framework, Django Channels

\- Database: PostgreSQL 15

\- Cache \& Broker: Redis 7

\- Task Queue: Celery

\- ASGI Server: Daphne

\- AI: Google Gemini API (with fallback)

\- Containerization\*\*: Docker, Docker Compose

\- Deployment: Render

\- Frontend: HTML5, CSS3, JavaScript (no frameworks)



---



\##  API Endpoints (Summary)



| Endpoint | Method | Description |

|----------|--------|-------------|

| `/api/auth/register/` | POST | Create new user |

| `/api/auth/login/` | POST | Login, returns JWT |

| `/api/auth/logout/` | POST | Logout (token blacklist) |

| `/api/auth/session/` | GET | Get current user |

| `/api/auth/users/` | GET | List all users |

| `/api/chat/rooms/` | GET | List rooms for current user |

| `/api/chat/rooms/create/` | POST | Create new room (private/group) |

| `/api/chat/rooms/<id>/` | GET | Room details |

| `/api/chat/rooms/<id>/messages/` | GET | Message history |

| `/api/chat/rooms/<id>/members/` | GET | List room members with roles |

| `/api/chat/rooms/<id>/mark-read/` | POST | Mark messages as read |



WebSocket endpoints:

\- `ws://localhost:8000/ws/chat/<room\\\_id>/` (or `wss://` on Render)

\- `ws://localhost:8000/ws/smart-reply/<room\\\_id>/`


---


Session check endpoint: GET /api/auth/session/

Code location: apps/accounts/views.py → SessionCheckView

URL defined in: apps/accounts/urls.py

Token refresh endpoint: POST /api/auth/refresh/

Code location: apps/accounts/views.py → RefreshSessionView (inherits from TokenRefreshView)

URL defined in: apps/accounts/urls.py


---


\##  Testing the App Locally



1\. Clone the repo.

2\. Copy `.env.example` to `.env` and fill in your local database credentials.

3\. Run `docker-compose up -d`.

4\. Access `http://localhost:8000`.



---



\## Key Features Demonstrated



\- JWT Authentication (login, signup, forgot password, session refresh)

\- Real‑time one‑to‑one and group chats with WebSockets

\- Online/offline status and typing indicators

\- Read receipts (single/double ticks)

\- Group creation and admin roles

\- AI‑powered smart replies (Gemini with fallback)

\- Full admin panel for all models

\- Clean, class‑based code architecture

\- Dockerized development and production

\- Deployed on Render with HTTPS and WebSocket support



---



\##  License \& Contributing



This project is for demonstration purposes. Feel free to adapt and extend. Pull requests are welcome.



---



Happy Chatting!



