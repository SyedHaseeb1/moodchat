# Private Secure Chat Application
### Experimental Vibe-Coded Project

## Core Idea

This project is an experiment in **vibe coding** — building a fully functional application with **minimal manual intervention** and observing how quickly and reliably it can be developed with near-zero bugs.

The goal is to test how far modern tools and AI-assisted development can go in building a **production-capable private communication platform**.

The application is a **private end-to-end encrypted chat system** combining ideas from messaging apps like WhatsApp and ephemeral media systems similar to Snapchat.

However, the main motivation is **privacy, control, and resilience**.

### Why This Exists

Modern messaging platforms:
- collect massive amounts of metadata
- store user media on centralized servers
- can experience outages
- rely heavily on cloud infrastructure
- may monetize user data

This project explores whether it is possible to build a **more private, resilient communication system**.

Example concern:

If a critical infrastructure failure occurs (or even something extreme like a war scenario destroying centralized services), most messaging platforms would immediately stop functioning.

This project aims to experiment with **more decentralized and resilient communication models**.

---

# Technology Stack

### Frontend
Flutter

### Backend
Supabase

Components used:

- Supabase Auth
- Supabase Realtime Database
- Supabase Storage
- Row Level Security
- Realtime subscriptions

---

# Current Development Progress

The following features are already implemented.

## Authentication

- Google login
- User session management
- Secure login flow

## Core UI

- Splash screen
- Login screen
- Home screen
- Personal profile screen

## Social System

Users can:

- Find other users
- Send friend requests
- Accept friend requests
- Reject friend requests
- Add friends via QR code

## Profile

Users can:

- View profile
- Edit profile information

## Chat System

Core chat functionality is implemented.

Features include:

- Real-time messaging
- Delivery status
- Online status indicators
- One-to-one chats
- Friend-only messaging

---

# Next Development Goals

Upcoming features planned for development:

## Push Notifications

Implement background notifications using:

- Firebase Cloud Messaging (FCM)

Goal:

Notifications must work even when the application is **not running**.

---

## Media Messaging

Add support for:

- Image attachments
- Video attachments

Requirements:

- Media can be downloaded from chat history
- Media storage should be temporary

---

## Voice / Video Calls

Future implementation of:

- Voice calls
- Video calls

---

# Privacy and Media Handling Concept

One of the main design goals is **minimizing permanent server storage of user media**.

### Media Lifecycle

1. Media is uploaded and shared.
2. Recipients can download the media.
3. Once downloaded, the server keeps it temporarily.
4. After **3 days**, the server automatically deletes the media.

If a user loses the file locally, it cannot be recovered.

This reduces:

- long-term server storage
- potential data breaches
- long-term privacy risks

---

# File Protection Concept

Media files are not stored in plain format.

The idea is to make files **unusable outside the application**.

Possible techniques:

- encryption
- byte fragmentation
- metadata mixing
- custom container format

Example idea:

Instead of a standard image file:

- part of the data exists in one file
- other parts exist elsewhere
- the file may appear as corrupted data

Only the application knows how to reconstruct the media.

To external tools, it would appear as:

- corrupted media
- meaningless binary
- mixed JSON-like data

---

# Dynamic Decryption Concept

Another idea under exploration:

The decryption mechanism may change periodically.

Possible methods:

- weekly key rotation
- device-based encryption
- chat-based encryption contexts

This would make:

- reverse engineering harder
- unauthorized file recovery nearly impossible

---

# Long-Term Vision

The long-term goal is to reduce reliance on the internet.

Future research area:

## Local Mesh Communication

Devices could potentially communicate directly without internet.

Concept:

- Devices within range form a **mesh network**
- Each device acts as a **relay / booster**
- Messages propagate through nearby devices

Target range goal:

Approximately **5 km radius** through device relays.

This would allow communication even when:

- internet is unavailable
- cellular networks fail
- centralized servers are unreachable

This is considered a **future research phase**, not a current implementation target.

---

# Comparison With Existing Apps

## WhatsApp

:contentReference[oaicite:2]{index=2} already uses:

- End-to-end encryption (Signal protocol)
- Message delivery receipts
- Online status
- Media sharing
- Push notifications
- Voice/video calls

However:

- media is stored on servers temporarily
- metadata collection exists
- fully offline mesh networking is not supported

---

## Snapchat

:contentReference[oaicite:3]{index=3} focuses on:

- ephemeral media
- disappearing messages
- temporary media storage

However:

- media is still processed on centralized servers
- encryption is not always full end-to-end

---

# What Is Actually Unique In This Project

These concepts are less common:

### Hybrid Ephemeral + Local Storage Model

Media stored:

- temporarily on server
- permanently on user device

---

### App-Specific Media Format

Designing files that:

- cannot be opened outside the app
- require the app to reconstruct data

---

### Dynamic Decryption Logic

Rotating or device-specific decryption layers.

---

### Future Mesh Networking

Local device-to-device communication without internet.

This concept exists in some experimental apps but is not widely implemented in mainstream messaging platforms.

---

# Experimental Nature

This project is intentionally experimental.

Goals include:

- exploring AI-assisted development speed
- testing privacy-focused architecture
- researching decentralized communication

The project prioritizes **learning, experimentation, and exploration** rather than immediate production deployment.
