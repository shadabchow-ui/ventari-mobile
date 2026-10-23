# assets/ml

`pubspec.yaml` declares this directory as an asset directory, so it must exist for the app to build.

Upstream Bagisto bundles `mobilenet_v2.tflite` here for on-device image search (`lib/features/search/data/services/mlkit_vision_service.dart`). The model is not distributed in this repository. Without it, the custom-model load error is caught in `recognizeImage` and image search returns only what the remaining ML Kit steps find.

Image search is classified DEFER in `docs/ventari/VENTARI_BAGISTO_TO_VENTARI_API_MAPPING.md`. Licensing and size of any model added here go through VJ-172.
