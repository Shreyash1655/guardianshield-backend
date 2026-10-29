import os
import pandas as pd
import joblib
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report

def train_model():
    dataset_path = "malicious_phish.csv"
    if not os.path.exists(dataset_path):
        print(f"Error: {dataset_path} not found in the root directory!")
        return

    print("Loading dataset (this may take a moment)...")
    df = pd.read_csv(dataset_path)
    
    # Dataset columns are usually 'url' and 'type'
    # Types: benign, phishing, malware, defacement
    print(f"Dataset loaded successfully. Total rows: {len(df)}")

    # Convert multi-class labels into binary: 0 = Safe (benign), 1 = Malicious (phishing/malware/defacement)
    df['label'] = df['type'].apply(lambda x: 0 if x == 'benign' else 1)

    # Optional: Sample subset if training is too slow on your local machine (e.g., 100,000 rows)
    # df = df.sample(n=100000, random_state=42)

    X = df['url']
    y = df['label']

    print("Splitting dataset into train and test sets...")
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)

    print("Extracting features using Character TF-IDF Vectorizer...")
    # Character n-grams (3 to 5 chars) excel at catching malicious URL string patterns
    vectorizer = TfidfVectorizer(analyzer='char', ngram_range=(3, 5), max_features=50000)
    X_train_vec = vectorizer.fit_transform(X_train)
    X_test_vec = vectorizer.transform(X_test)

    print("Training Logistic Regression classifier...")
    model = LogisticRegression(max_iter=1000, C=1.0, n_jobs=-1)
    model.fit(X_train_vec, y_train)

    print("Evaluating model performance...")
    predictions = model.predict(X_test_vec)
    print(classification_report(y_test, predictions, target_names=['Safe', 'Malicious']))

    # Ensure app/ml directory exists
    os.makedirs("app/ml", exist_ok=True)

    # Save model and vectorizer
    model_path = "app/ml/url_model.pkl"
    vectorizer_path = "app/ml/url_vectorizer.pkl"
    
    joblib.dump(model, model_path)
    joblib.dump(vectorizer, vectorizer_path)
    
    print(f"Model saved successfully to {model_path}!")
    print(f"Vectorizer saved successfully to {vectorizer_path}!")

if __name__ == "__main__":
    train_model()