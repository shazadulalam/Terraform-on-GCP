import pytest
from unittest.mock import MagicMock

from api.services.prediction_service import PredictionService, IRIS_TARGET_NAMES
from api.core.models import IrisFeatures, Prediction
from api.repositories.model_repository import ModelRepository

@pytest.fixture
def mock_model_repository(mocker): # mocker fixture from pytest-mock
    # Create a mock for the ModelRepository interface
    mock_repo = mocker.MagicMock(spec=ModelRepository)
    
    # The actual model object that load_model() would return
    # This also needs to be a mock if its methods (like predict) are called directly
    # by the service. However, in our PredictionService, the service calls
    # repository.predict(model, data), so the repository's predict method is mocked.
    # The 'model' object itself that is passed around can be a simple MagicMock.
    mock_loaded_model = mocker.MagicMock()
    mock_repo.load_model.return_value = mock_loaded_model
    
    # We will configure mock_repo.predict.return_value in each test
    return mock_repo

def test_predict_iris_setosa(mock_model_repository, mocker):
    # Configure the repository's predict method for this test case
    # It should return the raw prediction corresponding to Setosa (class_id 0)
    # The model.predict() typically returns a 1D array-like structure for scikit-learn, e.g., [0] or np.array([0])
    mock_model_repository.predict.return_value = [0] # Corrected: Raw prediction for Setosa

    # The model object that load_model() returns
    mock_loaded_model = mock_model_repository.load_model.return_value

    service = PredictionService(model_repository=mock_model_repository)
    features = IrisFeatures(sepal_length=5.1, sepal_width=3.5, petal_length=1.4, petal_width=0.2)
    
    expected_prediction = Prediction(class_id=0, class_name=IRIS_TARGET_NAMES[0]) # "Setosa"
    actual_prediction = service.predict_iris(features)

    assert actual_prediction == expected_prediction
    
    # Verify that load_model was called once during service initialization
    mock_model_repository.load_model.assert_called_once()
    
    # Verify that predict was called once with the loaded model and correct feature data
    mock_model_repository.predict.assert_called_once_with(mock_loaded_model, [[5.1, 3.5, 1.4, 0.2]])


def test_predict_iris_versicolor(mock_model_repository, mocker):
    # Configure mock for Versicolor (class_id 1)
    mock_model_repository.predict.return_value = [1] # Corrected: Raw prediction for Versicolor
    mock_loaded_model = mock_model_repository.load_model.return_value

    service = PredictionService(model_repository=mock_model_repository)
    features = IrisFeatures(sepal_length=6.0, sepal_width=2.2, petal_length=4.0, petal_width=1.0) # Example features
    
    expected_prediction = Prediction(class_id=1, class_name=IRIS_TARGET_NAMES[1]) # "Versicolor"
    actual_prediction = service.predict_iris(features)

    assert actual_prediction == expected_prediction
    mock_model_repository.load_model.assert_called_once()
    mock_model_repository.predict.assert_called_once_with(mock_loaded_model, [[6.0, 2.2, 4.0, 1.0]])

def test_predict_iris_virginica(mock_model_repository, mocker):
    # Configure mock for Virginica (class_id 2)
    mock_model_repository.predict.return_value = [2] # Corrected: Raw prediction for Virginica
    mock_loaded_model = mock_model_repository.load_model.return_value

    service = PredictionService(model_repository=mock_model_repository)
    features = IrisFeatures(sepal_length=7.3, sepal_width=2.9, petal_length=6.3, petal_width=1.8) # Example features
    
    expected_prediction = Prediction(class_id=2, class_name=IRIS_TARGET_NAMES[2]) # "Virginica"
    actual_prediction = service.predict_iris(features)

    assert actual_prediction == expected_prediction
    mock_model_repository.load_model.assert_called_once()
    mock_model_repository.predict.assert_called_once_with(mock_loaded_model, [[7.3, 2.9, 6.3, 1.8]])

def test_predict_iris_unknown_class_id(mock_model_repository, mocker):
    # Configure mock for an unknown class_id
    mock_model_repository.predict.return_value = [99] # Corrected: Raw prediction for an unknown class
    mock_loaded_model = mock_model_repository.load_model.return_value

    service = PredictionService(model_repository=mock_model_repository)
    features = IrisFeatures(sepal_length=1.0, sepal_width=1.0, petal_length=1.0, petal_width=1.0) # Example features
    
    # As per current PredictionService logic, unknown class_id maps to "Unknown Iris Species"
    expected_prediction = Prediction(class_id=99, class_name="Unknown Iris Species")
    actual_prediction = service.predict_iris(features)

    assert actual_prediction == expected_prediction
    mock_model_repository.load_model.assert_called_once()
    mock_model_repository.predict.assert_called_once_with(mock_loaded_model, [[1.0, 1.0, 1.0, 1.0]])
