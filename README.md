\# Real‑Time Chat Application with AI Smart Replies



A fully functional real‑time chat application built with Django, Django Channels, and Django REST Framework.  

It supports private 1‑on‑1 chats, group conversations, online status, typing indicators, message read receipts, and AI‑powered smart reply suggestions (with fallback when API credits are exhausted).



##  Features

### Core Backend Functionalities

- User Authentication  – JWT‑based registration, login, logout, session check, token refresh.

- Private Messaging – Real‑time one‑to‑one chats with WebSockets.

- Group Chats – Create groups, add members, automatic admin role for creator.

- Message Persistence – All messages stored in PostgreSQL, history loaded on room entry.

- Read & Delivery Receipts  – Single/double ticks for sent, delivered, read (via database models).

- Online / Offline Status – Live user presence displayed in chat headers.

- Typing Indicators – See when the other person is typing.

- Smart Reply Suggestions – AI‑generated contextual replies (DeepSeek API) with fallback suggestions.

- Group Info Page – Click group name to view member list with admin badges.

- REST API – Full CRUD for rooms, messages, user list.

- Admin Interface – Django admin for managing users, rooms, messages.

### Admin Panel features:
- Chat Rooms- Manage participants easily with a multi‑select widget (`filter_horizontal`).
- Messages- Search, view, and delete messages directly from the admin.
- User Management- Full CRUD for users, including email on the add form



### Frontend (Minimal, Functional)

- Dashboard with conversations list and other users.

- Chat view with WhatsApp‑like message bubbles, timestamps, online status, and smart reply buttons.

- Group creation modal.

- Responsive design (pure HTML/CSS/JS, no frameworks).



##  Architecture

<img width="5377" height="5773" alt="image" src="https://github.com/user-attachments/assets/ab44007e-8352-4b3f-96d0-c8b383274651" />











Tech Stack

Backend: Python 3.11, Django 4.2, Django REST Framework, Django Channels



Database: PostgreSQL 15



Cache \& Message Broker: Redis 7



Task Queue: Celery



ASGI Server: Daphne



AI Integration: DeepSeek/GEMINI API (with fallback suggestions)



Containerization: Docker, Docker Compose



Frontend: Pure HTML5, CSS3, JavaScript (no frameworks)



 Getting Started

Prerequisites

Docker and Docker Compose



(Optional) A DeepSeek API key – if you want real AI suggestions.



Installation

Clone the repository



bash code: run on you server

git clone https://github.com/yourusername/chat-app.git

cd chat-app

Set up environment variables

Copy the example file and edit it with your values:



bash code: run on you server

cp .env.example .env

At minimum, set DEEPSEEK\_API\_KEY if you have one; otherwise, the app will use fallback suggestions.



Run with Docker Compose



bash code: run on you server

docker-compose up -d --build

This starts PostgreSQL, Redis, the Django web server (with Daphne), and a Celery worker.



Apply database migrations



bash code: run on you server

docker-compose exec web python manage.py migrate

Create a superuser (admin)



bash code: run on you server

docker-compose exec web python manage.py createsuperuser

(Optional) Create test users Alice and Bob



bash code: run on you server

docker-compose exec web python manage.py shell

Then run:



python

from apps.accounts.models import User

for email, username in \[('alice@example.com','alice'), ('bob@example.com','bob')]:

&nbsp;   user, created = User.objects.get\_or\_create(email=email, username=username)

&nbsp;   user.set\_password('password123')

&nbsp;   user.save()

Access the application



Dashboard: http://localhost:8000



Admin panel: http://localhost:8000/admin



Configuration

Key environment variables (.env):



Variable	Description	Default

SECRET\_KEY	Django secret key	django-insecure-...

DEBUG	Enable debug mode	True

DB\_NAME	PostgreSQL database name	chat\_db

DB\_USER	Database user	postgres

DB\_PASSWORD	Database password	postgres

DB\_HOST	Database host	localhost

REDIS\_URL	Redis connection string	redis://localhost:6379/0

DEEPSEEK\_API\_KEY	Your DeepSeek API key	(empty)


 API Endpoints

All REST endpoints are prefixed with /api/. Authentication is via JWT (Bearer token).



Authentication

POST /api/auth/register/ – Register new user (expects username, email, password, password2)



POST /api/auth/login/ – Login (expects email, password), returns access and refresh tokens.



POST /api/auth/logout/ – Logout (requires token)



GET /api/auth/session/ – Get current user info



POST /api/auth/refresh/ – Refresh access token



GET /api/auth/users/ – List all active users



Chat

GET /api/chat/rooms/ – List rooms for authenticated user



POST /api/chat/rooms/create/ – Create a new room (room\_type: private or group, participant\_ids: list of user IDs)



GET /api/chat/rooms/<uuid:room\_id>/ – Room details



GET /api/chat/rooms/<uuid:room\_id>/messages/ – Message history



GET /api/chat/rooms/<uuid:room\_id>/members/ – List room members with roles (for groups)



POST /api/chat/rooms/<uuid:room\_id>/mark-read/ – Mark messages as read



WebSocket Endpoints

WebSocket connections use the same token as HTTP (?token=...).



ws://localhost:8000/ws/chat/<room\_id>/ – Real‑time chat (send/receive messages, typing, online status)



ws://localhost:8000/ws/smart-reply/<room\_id>/ – Receive smart reply suggestions



AI Smart Replies

When a user sends a message, the backend triggers a Celery task that:



Fetches recent conversation history.



Calls the DeepSeek API (if an API key is set) to generate three short, contextual reply options.



If the API call fails or no key is provided, returns fallback suggestions (\["OK", "Thanks!", "👍", ...]).



Sends the suggestions via WebSocket to the other participant(s).





Deployment on Render

Push your code to a GitHub repository.



On Render, create a New Web Service and connect your repo.



Choose Docker as the environment (Render will auto‑detect the Dockerfile).



Add the following environment variables in the Render dashboard:



SECRET\_KEY (generate a random string)



DEEPSEEK\_API\_KEY (optional)



DATABASE\_URL (Render will provide this after adding a PostgreSQL database)



REDIS\_URL (Render will provide this after adding a Redis instance)



Create a PostgreSQL and a Redis instance from the Render dashboard and link them to your web service.



Deploy! Your app will be available at https://your-app.onrender.com.





📁 Project Structure

text

chat\_project/

├── apps/

│   ├── accounts/          # User authentication, profiles

│   ├── chat/              # Chat rooms, messages, consumers

│   └── ai\_assistant/      # Smart reply logic, Celery tasks

├── chat\_project/           # Django project settings, asgi, urls

├── templates/              # HTML templates (dashboard, chat room, group info)

├── static/                 # (optional) CSS, JS

├── manage.py

├── docker-compose.yml

├── Dockerfile

├── requirements.txt

├── .env.example

└── README.md



Testing

Run the test suite (if available) with



bash code:

docker-compose exec web python manage.py test

&nbsp;License

This project is for demonstration purposes. Feel free to adapt and extend.



&nbsp;Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.



Happy Chatting! 





