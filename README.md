Project Overview

This repository contains an iOS application developed in Swift (UIKit) with Firebase as part of a coursework project at Monash University. The project was assessed positively and recognized for demonstrating a level of quality, structure, and completeness comparable to a production-ready mobile application rather than a basic academic prototype. The goal of the project was to design and implement a fully functional, secure, and scalable ios mobile app that reflects real-world development practices.

Application Description

The application functions as a professional networking and portfolio discovery platform. Users can explore other profiles through an interactive swipe-based interface, view detailed user information, browse personal portfolios, research market trends, personalyze profile by adding portfolios and projects and communicate through direct one-to-one messaging when mutual interest is established. The app is designed to simulate realistic user flows commonly found in modern mobile platforms, with an emphasis on usability, responsiveness, and data integrity.

Core Features

The main discovery flow allows users to swipe through profile cards displaying key information such as name, role, biography, and skills. Users can like or skip profiles, with likes being persisted to the backend and filtered to prevent duplicate interactions. A dedicated portfolios section displays users that have been liked, where each profile can be expanded to reveal detailed portfolio projects stored in Firestore. When two users have liked each other, a messaging option becomes available, allowing them to initiate or continue a private chat. The application also includes an ideas section designed to present curated content such as business or technology trends, structured in a way that allows easy integration with external APIs.

Technical Architecture

The project uses Firebase Authentication to manage user sessions and identity, Cloud Firestore for structured data storage, and Firebase Storage for handling user-uploaded media. Firestore data is organized into collections and subcollections for users, likes, portfolios, and chats, following a normalized and scalable schema. Access to all data is protected by custom Firestore and Storage security rules that enforce authentication, ownership, and role-based permissions. The codebase follows a modular architecture, separating view controllers, reusable UI components, models, and repository layers responsible for backend interaction.

User Interface and Experience

The UI is built entirely using UIKit and Auto Layout, with custom collection and table view cells to support dynamic, self-sizing content. Smooth animations are implemented for card expansion, portfolio transitions, and view changes to enhance user experience. Lazy image loading and caching are used to ensure efficient performance and fast image rendering on repeated views. The overall design emphasizes clarity, consistency, and responsiveness across different device sizes.

Academic Context

This project was developed as part of coursework at Monash University (course FIT3178), where it was commended for its clean architecture, secure backend integration, and professional, production-ready level implementation. The application demonstrates practical skills in mobile development, backend integration, and UI/UX design, aligning closely with industry standards and real-world application development workflows.
