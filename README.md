# Pakistan Transport Fare Prediction

A machine learning project that predicts transport fares (in PKR) across Pakistan based on distance, time of day, route type, and passenger count. Includes a trained model, a Flask REST API, and a Flutter integration module.

## Description

This project generates a synthetic Pakistan transport dataset, trains regression models (Linear Regression and Random Forest), and serves the best-performing model via a REST API. A Flutter client function is provided so the API can be consumed directly from mobile apps.

## Tech Stack

- **Machine Learning:** Python, scikit-learn, pandas, numpy, matplotlib, seaborn, joblib
- **API:** Flask, Flask-CORS, Gunicorn
- **Mobile:** Flutter (Dart), `http` package
- **Deployment:** Render.com
- **Notebook:** Google Colab / Jupyter

## Project Structure

```
fare_prediction/
├── fare_prediction.ipynb      # Data generation, training, evaluation
├── fare_model.pkl             # Trained model (produced by the notebook)
├── app.py                     # Flask REST API
├── requirements.txt           # Python dependencies
├── flutter_integration.dart   # Dart client + sample UI
└── README.md
```

## How to Run Locally

### 1. Train the model

Open `fare_prediction.ipynb` in Google Colab or Jupyter and run all cells. This produces `fare_model.pkl`.

### 2. Set up the API

```bash
git clone <https://github.com/hasnainkhan499/pakistan-fare-predictor>
cd fare_prediction
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
python app.py
```

The API will be available at `http://localhost:5000`.

### 3. Test the endpoint

```bash
curl -X POST http://localhost:5000/predict \
  -H "Content-Type: application/json" \
  -d '{"distance_km": 12.5, "time_of_day": "morning", "route_type": "city", "passengers": 2}'
```

Example response:

```json
{
  "predicted_fare_pkr": 345.78,
  "input": {
    "distance_km": 12.5,
    "time_of_day": "morning",
    "route_type": "city",
    "passengers": 2
  }
}
```

## API Reference

### `POST /predict`

| Field         | Type   | Allowed values                                  |
| ------------- | ------ | ----------------------------------------------- |
| distance_km   | number | 0 – 2000                                        |
| time_of_day   | string | `morning`, `afternoon`, `evening`, `night`      |
| route_type    | string | `city`, `intercity`, `highway`                  |
| passengers    | int    | 1 – 60                                          |

## How to Deploy on Render.com

1. Push this project (including `fare_model.pkl`) to a GitHub repository.
2. Sign in at [render.com](https://render.com) and click **New → Web Service**.
3. Connect your GitHub repository.
4. Configure the service:
   - **Environment:** Python 3
   - **Build Command:** `pip install -r requirements.txt`
   - **Start Command:** `gunicorn app:app --bind 0.0.0.0:$PORT`
   - **Instance Type:** Free (or higher)
5. Click **Create Web Service**. Render will build and deploy automatically.
6. After deployment you'll receive a public URL like `https://your-app.onrender.com`. Update `FareApi.baseUrl` in `flutter_integration.dart` with this URL.

## Flutter Integration

Add to your Flutter app's `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.2.0
```

Then use:

```dart
final fare = await FareApi.predictFare(
  distanceKm: 12.5,
  timeOfDay: 'morning',
  routeType: 'city',
  passengers: 2,
);
```

## License

MIT
