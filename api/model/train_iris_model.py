from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression
from joblib import dump

# Load and prepare data
iris = load_iris()
X, y = iris.data, iris.target

# Train model
model = LogisticRegression(max_iter=1000)
model.fit(X, y)

# Save model
dump(model, 'iris_classifier.joblib')
print("Model trained and saved successfully")