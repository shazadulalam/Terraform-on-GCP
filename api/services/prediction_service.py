from api.core.models import IrisFeatures, Prediction
from api.repositories.model_repository import ModelRepository
# This is a placeholder for actual Iris class names if available
# If not, the service can just return the raw prediction
IRIS_TARGET_NAMES = {0: "Setosa", 1: "Versicolor", 2: "Virginica"}


class PredictionService:
    def __init__(self, model_repository: ModelRepository):
        self.model_repository = model_repository
        self.model = self.model_repository.load_model()

    def predict_iris(self, features: IrisFeatures) -> Prediction:
        data = [[
            features.sepal_length,
            features.sepal_width,
            features.petal_length,
            features.petal_width
        ]]
        raw_prediction = self.model_repository.predict(self.model, data)
        class_id = int(raw_prediction[0])
        # Replace with actual target names if possible, otherwise use a placeholder
        class_name = IRIS_TARGET_NAMES.get(class_id, "Unknown Iris Species") # Updated placeholder
        return Prediction(class_id=class_id, class_name=class_name)
