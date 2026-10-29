import os
import json
import joblib
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression

class ScamClassifier:
    def __init__(self, model_path="data/scam_model.pkl", vectorizer_path="data/vectorizer.pkl"):
        self.model_path = model_path
        self.vectorizer_path = vectorizer_path
        self.model = None
        self.vectorizer = None
        self.load_or_train()

    def load_or_train(self):
        if os.path.exists(self.model_path) and os.path.exists(self.vectorizer_path):
            try:
                self.model = joblib.load(self.model_path)
                self.vectorizer = joblib.load(self.vectorizer_path)
                return
            except Exception:
                pass
        
        dataset_path = "data/demonstration_dataset.json"
        texts, labels = [], []
        if os.path.exists(dataset_path):
            with open(dataset_path, "r", encoding="utf-8") as f:
                data = json.load(f)
                for item in data:
                    texts.append(item["text"])
                    labels.append(item["label"])
        else:
            texts = ["Your account is locked click here to verify OTP", "Hey how are you doing today"]
            labels = [1, 0]

        self.vectorizer = TfidfVectorizer(stop_words='english', max_features=5000)
        X = self.vectorizer.fit_transform(texts)
        self.model = LogisticRegression()
        self.model.fit(X, labels)

        os.makedirs("data", exist_ok=True)
        joblib.dump(self.model, self.model_path)
        joblib.dump(self.vectorizer, self.vectorizer_path)

    def predict(self, text):
        if not text or not text.strip():
            return 0.0, 0
        X = self.vectorizer.transform([text])
        proba = self.model.predict_proba(X)[0]
        scam_prob = float(proba[1]) if len(proba) > 1 else 0.0
        pred_label = int(self.model.predict(X)[0])
        return scam_prob, pred_label

scam_classifier = ScamClassifier()