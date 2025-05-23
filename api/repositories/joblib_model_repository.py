from typing import Any # Or BaseEstimator, np.ndarray
from joblib import load
import os
from .model_repository import ModelRepository
# from sklearn.base import BaseEstimator # if using BaseEstimator
# import numpy as np # if using np.ndarray

class JoblibModelRepository(ModelRepository):
    def __init__(self, model_path: str = 'model/iris_classifier.joblib'):
        # model_path is 'model/iris_classifier.joblib'
        # This file is in api/repositories/
        # So, os.path.dirname(__file__) is api/repositories/
        # Then, os.path.join(os.path.dirname(__file__), '..', model_path)
        # becomes api/repositories/../model/iris_classifier.joblib
        # which resolves to api/model/iris_classifier.joblib
        self._model_file_path = os.path.abspath(
            os.path.join(os.path.dirname(__file__), '..', model_path)
        )
        self._model = None # Lazy load

    def load_model(self) -> Any: # Or BaseEstimator
        if self._model is None:
            if not os.path.exists(self._model_file_path):
                # Try an alternative path assuming CWD is the repo root /app
                # and model_path was 'api/model/iris_classifier.joblib'
                # This case is less likely given the default init parameter.
                # For the default 'model/iris_classifier.joblib', this check is not what we want.

                # A more robust check if the initial path fails:
                # What if the CWD is /app, and model_path='model/iris_classifier.joblib' was intended
                # to be relative to 'api/'? Then we'd look for 'api/model/iris_classifier.joblib'
                alt_path_from_repo_root = os.path.abspath(os.path.join("api", self._model_path))
                # This is only relevant if self._model_path was passed as something like "model/iris..."
                # and CWD is /app.
                # The current self._model_file_path is already absolute: /app/api/model/iris_classifier.joblib

                # Let's test the original simple path from the prompt again, as it was simpler.
                # The prompt used:
                # model_file_path = os.path.join(os.path.dirname(__file__), '..', self._model_path)
                # This is what I have above for self._model_file_path.
                # The key is that self._model_path is 'model/iris_classifier.joblib'
                
                # The prompt's version:
                # self._model_path = model_path
                # ...
                # model_file_path = os.path.join(os.path.dirname(__file__), '..', self._model_path)

                # My current self._model_file_path is already this.
                # The issue might be if the file doesn't exist there.
                raise FileNotFoundError(f"Model file not found at {self._model_file_path}")

            self._model = load(self._model_file_path)
        return self._model

    def predict(self, model: Any, data: list[list[float]]) -> Any: # Or np.ndarray
        # The model passed here is the one loaded by load_model(), so it's self._model
        if model is None: # Should not happen if load_model was called
            raise ValueError("Model not loaded.")
        return model.predict(data)
