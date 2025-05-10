from fastapi import FastAPI
from pydantic import BaseModel
from joblib import load
import os

app = FastAPI()

# Load trained model
model = load('model/iris_classifier.joblib')

class IrisFeatures(BaseModel):
    sepal_length: float
    sepal_width: float
    petal_length: float
    petal_width: float

@app.post("/predict")
async def predict(features: IrisFeatures):
    data = [[
        features.sepal_length,
        features.sepal_width,
        features.petal_length,
        features.petal_width
    ]]
    prediction = model.predict(data)
    return {
        "class": int(prediction[0]),
        "class_name": iris.target_names[prediction[0]].capitalize()
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)