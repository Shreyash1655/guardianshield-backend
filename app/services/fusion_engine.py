from app.ml.classifier import scam_classifier
from app.services.url_intelligence import URLIntelligence
from app.services.email_analyzer import EmailAnalyzer

class ThreatFusionEngine:
    @staticmethod
    def evaluate(channel, content, metadata=None):
        explanation_items = []
        base_score = 0.0

        ml_score, ml_label = scam_classifier.predict(content)
        base_score += ml_score * 0.5
        if ml_label == 1:
            explanation_items.append(f"ML classifier flagged potential scam patterns (confidence: {ml_score:.2f}).")

        urls = URLIntelligence.extract_urls(content)
        url_analyses = [URLIntelligence.analyze_url(u) for u in urls]
        max_url_score = 0.0
        for ua in url_analyses:
            if ua["risk_score"] > max_url_score:
                max_url_score = ua["risk_score"]
            for ind in ua["indicators"]:
                explanation_items.append(f"URL indicator [{ua['url']}]: {ind}")

        base_score += max_url_score * 0.3

        content_lower = content.lower()
        fraud_keywords = ['otp', 'digital arrest', 'lock', 'verify', 'urgent', 'suspend', 'police', 'gift card', 'transfer', 'kyc']
        matched_keywords = [kw for kw in fraud_keywords if kw in content_lower]
        if matched_keywords:
            keyword_boost = min(len(matched_keywords) * 0.1, 0.3)
            base_score += keyword_boost
            explanation_items.append(f"High-risk scam keywords detected: {', '.join(matched_keywords)}")

        if channel == 'email' and metadata and isinstance(metadata, dict):
            email_res = EmailAnalyzer.analyze(metadata.get('subject', ''), content, metadata.get('sender', ''), metadata)
            for ind in email_res['indicators']:
                explanation_items.append(f"Email indicator: {ind}")
                base_score += 0.2

        final_score = min(round(base_score, 2), 1.0)
        risk_level = "SAFE"
        if final_score >= 0.7:
            risk_level = "HIGH_RISK"
        elif final_score >= 0.35:
            risk_level = "SUSPICIOUS"

        if not explanation_items:
            explanation_items.append("No high-risk indicators or malicious patterns detected.")

        return {
            "risk_score": final_score,
            "risk_level": risk_level,
            "explanation": " | ".join(explanation_items),
            "urls_analyzed": url_analyses
        } 