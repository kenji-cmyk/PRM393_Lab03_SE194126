# App layers

Organize Flutter code by MVVM responsibility:

- `data/`: Firebase and other data sources, models, and repository implementations.
- `domain/`: app entities and use cases.
- `presentation/`: screens/views and view models.

Place shared application setup in this folder as the app grows.
