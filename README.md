# 🌸 BloomWell — Your Space to Feel Better

**BloomWell is a women's wellness and self-care application designed to support emotional well-being, menstrual health, stress management, and meaningful connections.**

Our mission is to create a safe and supportive space where women can understand their emotions, build healthy habits, manage difficult days, and feel less alone.

## 💡 Problem Statement

Academic pressure, emotional stress, menstrual discomfort, and loneliness can affect women's daily lives. Many struggle to find a private, judgment-free space where they can track their well-being and access reliable guidance.

**BloomWell brings wellness tracking, personalized self-care, AI-powered support, and community connection together in one platform.**

## ✨ Key Features

### 🧠 Mood Tracking & Insights
- Record daily moods and emotions.
- Identify personal emotional patterns over time.
- Explore possible relationships between mood, sleep, stress, and daily activities.

### 📔 Private Journal
- Write personal thoughts and feelings in a private space.
- Reflect on emotional experiences.
- Receive optional AI-powered reflections with explicit consent.

### 🌷 CycleCare — Menstrual Wellness
- Log period dates, symptoms, mood, and energy levels.
- View cycle history and estimated upcoming periods.
- Explore personal patterns between cycle stages and well-being.
- Receive optional, discreet period reminders.

### 🤗 AI Self-Care Companion
- Receive personalized self-care suggestions.
- Choose the support you need: encouragement, advice, distraction, or simply a space to express yourself.
- Get gentle guidance during stressful or emotionally difficult days.

### 🌼 Comfort Mode
- Discover relaxing activities for period discomfort or overwhelming days.
- Create personal comfort routines.
- Access gentle reminders to rest, hydrate, and take breaks.

### 🎯 Personalized Routines & Challenges
- Build daily wellness routines.
- Track habits and activity completion.
- Participate in small, achievable self-care challenges.

### 💗 Peer-Support Community
- Connect with others experiencing similar challenges.
- Participate in moderated discussions about periods, college stress, body confidence, and emotional well-being.
- Use privacy-conscious community features without being required to share menstrual information.

### 📚 Wellness & Support Resources
- Access educational content about menstrual and emotional wellness.
- Discover verified support resources.
- Find guidance on when to seek professional help.

### 🔐 Privacy & Safety
- Keep personal journals and cycle information private by default.
- Control consent for AI processing.
- Access data-management and deletion options.
- Report inappropriate community content.

## 🛠️ Technology Stack

| Component | Technology |
|---|---|
| Mobile Application | Flutter, Dart |
| State Management | Riverpod |
| Navigation | GoRouter |
| Backend API | Python, FastAPI |
| Database | PostgreSQL |
| ORM & Migrations | SQLAlchemy, Alembic |
| AI Integration | LLM API through backend |
| Deployment | Docker, AWS |
| Version Control | Git, GitHub |

## 🏗️ System Architecture

```text
       Flutter Mobile App
                |
           HTTPS / REST
                |
         FastAPI Backend
          /     |      \
         /      |       \
 PostgreSQL   AI API   Resources
   Database             & Content
```

The backend manages authentication, user data, wellness insights, and secure communication with the AI provider.

## 🚀 Getting Started

### Prerequisites
- Flutter SDK
- Dart SDK
- Python 3.11+
- PostgreSQL
- Git

### Installation

**1. Clone the repository**

```bash
git clone <YOUR_REPOSITORY_URL>
cd BloomWell
```

**2. Install Flutter dependencies**

```bash
flutter pub get
```

**3. Configure the backend**

Set up the Python environment, install backend dependencies, configure environment variables, and connect PostgreSQL according to the project setup.

**4. Run the application**

```bash
flutter run
```

*Note: Backend setup commands may vary depending on the repository structure.*

## 🗺️ Development Roadmap

- [ ] Project setup and authentication
- [ ] Mood tracking and private journaling
- [ ] Menstrual cycle and symptom tracking
- [ ] Personalized routines and wellness insights
- [ ] AI self-care companion
- [ ] Wellness education and support resources
- [ ] Peer-support community and moderation
- [ ] Privacy controls and data deletion
- [ ] Testing and cloud deployment

## 🌱 Future Enhancements

- Optional notifications and wellness reminders
- Accessibility and multilingual support
- More personalized self-care recommendations
- Improved analytics for personal wellness patterns
- Expanded verified support resources

## 🔒 Privacy Disclaimer

BloomWell is intended for general wellness and self-care. It does not provide medical diagnoses, replace professional healthcare, or guarantee menstrual cycle predictions. Users should consult qualified healthcare professionals for medical concerns.

## 🤝 Contributing

Contributions, ideas, and feedback are welcome!

1. Fork the repository.
2. Create a feature branch.
3. Commit your changes.
4. Open a pull request.

## 💖 Our Mission

**No woman should have to navigate her difficult days feeling alone.**

BloomWell aims to make self-care more accessible, menstrual wellness easier to understand, and emotional support easier to find.

---

*Built with care, empathy, and technology. 🌸*
