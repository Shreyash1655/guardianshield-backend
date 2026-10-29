from app.services.url_intelligence import URLIntelligence

class EmailAnalyzer:
    @staticmethod
    def analyze(subject, body, sender, metadata=None):
        content = f"Subject: {subject}\nSender: {sender}\nBody: {body}"
        urls = URLIntelligence.extract_urls(content)
        url_results = [URLIntelligence.analyze_url(u) for u in urls]

        indicators = []
        if sender and ("support" in sender.lower() or "admin" in sender.lower() or "security" in sender.lower()):
            if not sender.endswith(("@officialbank.com", "@verifiedservice.com", "@company.com")):
                indicators.append("Suspicious sender domain mimicking official support")

        return {
            "urls_analyzed": url_results,
            "indicators": indicators
        } 