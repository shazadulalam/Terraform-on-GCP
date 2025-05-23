from fastapi import FastAPI, Depends
from api.core.models import IrisFeatures, Prediction
from api.services.prediction_service import PredictionService
from api.repositories.joblib_model_repository import JoblibModelRepository
from api.repositories.model_repository import ModelRepository

app = FastAPI()

# Dependency Injection Setup
def get_model_repository() -> ModelRepository:
    return JoblibModelRepository(model_path='model/iris_classifier.joblib')

def get_prediction_service(
    model_repo: ModelRepository = Depends(get_model_repository)
) -> PredictionService:
    return PredictionService(model_repository=model_repo)

@app.post("/predict", response_model=Prediction)
async def predict(
    features: IrisFeatures,
    service: PredictionService = Depends(get_prediction_service)
):
    return service.predict_iris(features)

@app.get("/health")
async def health_check():
    # Optionally, the health check could try to load the model
    # by resolving the service or repository to ensure they are operational.
    # For now, a simple health check.
    # A more thorough check could involve trying to load the model:
    try:
        repo = get_model_repository()
        model = repo.load_model() # Attempt to load model
        if model is None:
            raise ValueError("Model could not be loaded by repository.")
        # Optionally, make a dummy prediction
        # dummy_features = IrisFeatures(sepal_length=5.0, sepal_width=3.0, petal_length=1.0, petal_width=0.1)
        # service = get_prediction_service(repo)
        # service.predict_iris(dummy_features)
        return {"status": "healthy"}
    except Exception as e:
        # Log the exception e for debugging if necessary
        return {"status": "unhealthy", "detail": str(e)}

# Keep for local running if needed, but Cloud Run uses its own server.
# if __name__ == "__main__":
#     import uvicorn
#     # If running from 'api' directory: 'main:app'
#     # If running from repo root: 'api.main:app'
#     # uvicorn.run("main:app", host="0.0.0.0", port=8080, reload=True)
#     # The prompt example used uvicorn.run(app, ...) which is fine if this file is executed directly.
#     # For consistency with common practice:
#     uvicorn.run("api.main:app", host="0.0.0.0", port=8080, reload=True, app_dir="/app")