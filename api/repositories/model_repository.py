from abc import ABC, abstractmethod
from typing import Any
# It's okay if the model type is 'Any' for now, or be more specific if possible
# For a joblib model, it's typically a scikit-learn estimator.
# from sklearn.base import BaseEstimator # Example if scikit-learn is a direct dep

class ModelRepository(ABC):
    @abstractmethod
    def load_model(self) -> Any: # Or BaseEstimator
        pass

    @abstractmethod
    def predict(self, model: Any, data: list[list[float]]) -> Any: # Or np.ndarray
        pass
