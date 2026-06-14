from flask import Flask, request, jsonify
from flask_cors import CORS
import joblib
import numpy as np
import os

app = Flask(__name__)
CORS(app)

MODEL_PATH = os.environ.get("MODEL_PATH", "fare_model.pkl")
model = joblib.load(MODEL_PATH)

TIME_OF_DAY_MAP = {"morning": 0, "afternoon": 1, "evening": 2, "night": 3}
ROUTE_TYPE_MAP = {"city": 0, "intercity": 1, "highway": 2}


@app.route("/", methods=["GET"])
def home():
    return jsonify({"status": "ok", "service": "Pakistan Transport Fare Prediction API"})


@app.route("/predict", methods=["POST"])
def predict():
    try:
        data = request.get_json(force=True)
        if not data:
            return jsonify({"error": "Request body must be JSON"}), 400

        required = ["distance_km", "time_of_day", "route_type", "passengers"]
        missing = [k for k in required if k not in data]
        if missing:
            return jsonify({"error": f"Missing fields: {missing}"}), 400

        try:
            distance_km = float(data["distance_km"])
            passengers = int(data["passengers"])
        except (TypeError, ValueError):
            return jsonify({"error": "distance_km must be number, passengers must be int"}), 400

        time_of_day = str(data["time_of_day"]).lower().strip()
        route_type = str(data["route_type"]).lower().strip()

        if time_of_day not in TIME_OF_DAY_MAP:
            return jsonify({"error": f"time_of_day must be one of {list(TIME_OF_DAY_MAP)}"}), 400
        if route_type not in ROUTE_TYPE_MAP:
            return jsonify({"error": f"route_type must be one of {list(ROUTE_TYPE_MAP)}"}), 400
        if distance_km <= 0 or distance_km > 2000:
            return jsonify({"error": "distance_km must be between 0 and 2000"}), 400
        if passengers < 1 or passengers > 60:
            return jsonify({"error": "passengers must be between 1 and 60"}), 400

        features = np.array([[
            distance_km,
            TIME_OF_DAY_MAP[time_of_day],
            ROUTE_TYPE_MAP[route_type],
            passengers,
        ]])

        predicted = float(model.predict(features)[0])
        predicted = max(0.0, round(predicted, 2))

        return jsonify({
            "predicted_fare_pkr": predicted,
            "input": {
                "distance_km": distance_km,
                "time_of_day": time_of_day,
                "route_type": route_type,
                "passengers": passengers,
            },
        })
    except Exception as e:
        return jsonify({"error": "Prediction failed", "details": str(e)}), 500


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 5000)))
